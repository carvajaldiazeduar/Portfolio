package com.portfolio.apigateway.auth;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.InvalidKeyException;
import java.util.Base64;
import java.util.Map;

public class JwtUtil {
    private static final String ALGORITHM = "HS256";
    private static final String MAC = "HmacSHA256";

    public static String base64UrlEncode(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public static String sign(Map<String, Object> payload, String secret) {
        String header = "{\"alg\":\"" + ALGORITHM + "\",\"typ\":\"JWT\"}";
        String body = toJson(payload);
        String signingInput = base64UrlEncode(header.getBytes(StandardCharsets.UTF_8))
                + "." + base64UrlEncode(body.getBytes(StandardCharsets.UTF_8));
        String signature = hmac(signingInput, secret);
        return signingInput + "." + signature;
    }

    public static Map<String, Object> verify(String token, String secret) {
        String[] parts = token.split("\\.");
        if (parts.length != 3) {
            return null;
        }
        String signingInput = parts[0] + "." + parts[1];
        String expectedSig = hmac(signingInput, secret);
        if (!constantTimeEquals(expectedSig, parts[2])) {
            return null;
        }
        String body = new String(Base64.getUrlDecoder().decode(parts[1]), StandardCharsets.UTF_8);
        try {
            Map<String, Object> payload = parseJson(body);
            Number exp = (Number) payload.get("exp");
            if (exp != null && System.currentTimeMillis() > exp.longValue() * 1000) {
                return null;
            }
            return payload;
        } catch (Exception e) {
            return null;
        }
    }

    private static String hmac(String data, String secret) {
        try {
            Mac mac = Mac.getInstance(MAC);
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), MAC));
            return base64UrlEncode(mac.doFinal(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static boolean constantTimeEquals(String a, String b) {
        if (a.length() != b.length()) {
            return false;
        }
        int result = 0;
        for (int i = 0; i < a.length(); i++) {
            result |= a.charAt(i) ^ b.charAt(i);
        }
        return result == 0;
    }

    private static String toJson(Map<String, Object> payload) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (Map.Entry<String, Object> e : payload.entrySet()) {
            if (!first) sb.append(",");
            first = false;
            sb.append("\"").append(e.getKey()).append("\":");
            Object v = e.getValue();
            if (v instanceof String s) {
                sb.append("\"").append(s).append("\"");
            } else if (v instanceof Number n) {
                sb.append(n);
            } else if (v instanceof java.util.List<?> list) {
                sb.append("[");
                boolean f = true;
                for (Object item : list) {
                    if (!f) sb.append(",");
                    f = false;
                    sb.append("\"").append(item).append("\"");
                }
                sb.append("]");
            }
        }
        sb.append("}");
        return sb.toString();
    }

    private static Map<String, Object> parseJson(String body) {
        Map<String, Object> map = new java.util.LinkedHashMap<>();
        String inner = body.trim();
        if (inner.startsWith("{")) inner = inner.substring(1);
        if (inner.endsWith("}")) inner = inner.substring(0, inner.length() - 1);
        for (String pair : splitTopLevel(inner)) {
            int colon = pair.indexOf(':');
            if (colon < 0) continue;
            String key = unquote(pair.substring(0, colon).trim());
            String value = pair.substring(colon + 1).trim();
            map.put(key, parseValue(value));
        }
        return map;
    }

    private static java.util.List<String> splitTopLevel(String s) {
        java.util.List<String> parts = new java.util.ArrayList<>();
        int depth = 0;
        boolean inStr = false;
        int start = 0;
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            if (c == '"' && (i == 0 || s.charAt(i - 1) != '\\')) {
                inStr = !inStr;
            } else if (!inStr) {
                if (c == '{' || c == '[') depth++;
                else if (c == '}' || c == ']') depth--;
                else if (c == ',' && depth == 0) {
                    parts.add(s.substring(start, i));
                    start = i + 1;
                }
            }
        }
        if (start < s.length()) parts.add(s.substring(start));
        return parts;
    }

    private static Object parseValue(String value) {
        if (value.startsWith("\"")) {
            return unquote(value);
        }
        if (value.startsWith("[")) {
            String inner = value.substring(1, value.length() - 1).trim();
            if (inner.isEmpty()) return new java.util.ArrayList<>();
            java.util.List<String> items = new java.util.ArrayList<>();
            for (String pair : splitTopLevel(inner)) {
                items.add(unquote(pair.trim()));
            }
            return items;
        }
        return new java.math.BigDecimal(value);
    }

    private static String unquote(String s) {
        if (s.startsWith("\"") && s.endsWith("\"")) {
            return s.substring(1, s.length() - 1);
        }
        return s;
    }
}
