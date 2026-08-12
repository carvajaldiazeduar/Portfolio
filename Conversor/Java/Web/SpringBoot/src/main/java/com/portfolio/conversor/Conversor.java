package com.portfolio.conversor;

import java.util.LinkedHashMap;
import java.util.Map;

public final class Conversor {
    private static final Map<String, Map<String, Double>> CONVERSION = new LinkedHashMap<>();

    static {
        Map<String, Double> length = new LinkedHashMap<>();
        length.put("m", 1.0);
        length.put("km", 0.001);
        length.put("mi", 0.000621371);
        length.put("ft", 3.28084);
        length.put("in", 39.3701);
        length.put("cm", 100.0);
        CONVERSION.put("length", length);

        Map<String, Double> weight = new LinkedHashMap<>();
        weight.put("kg", 1.0);
        weight.put("g", 1000.0);
        weight.put("lb", 2.20462);
        weight.put("oz", 35.274);
        weight.put("mg", 1000000.0);
        CONVERSION.put("weight", weight);

        Map<String, Double> temperature = new LinkedHashMap<>();
        temperature.put("C", 0.0);
        temperature.put("F", 0.0);
        temperature.put("K", 0.0);
        CONVERSION.put("temperature", temperature);
    }

    public static final Map<String, String[]> CATEGORY_UNITS = new LinkedHashMap<>();

    static {
        CATEGORY_UNITS.put("length", new String[]{"m", "km", "mi", "ft", "in", "cm"});
        CATEGORY_UNITS.put("weight", new String[]{"kg", "g", "lb", "oz", "mg"});
        CATEGORY_UNITS.put("temperature", new String[]{"C", "F", "K"});
    }

    private Conversor() {
    }

    public static String[] listCategories() {
        return CONVERSION.keySet().toArray(new String[0]);
    }

    public static double convert(double value, String from, String to) {
        for (Map.Entry<String, Map<String, Double>> entry : CONVERSION.entrySet()) {
            String category = entry.getKey();
            Map<String, Double> units = entry.getValue();
            if (!units.containsKey(from) || !units.containsKey(to)) {
                continue;
            }
            if ("temperature".equals(category)) {
                return convertTemperature(value, from, to);
            }
            return value / units.get(from) * units.get(to);
        }
        throw new IllegalArgumentException("Incompatible units: " + from + " -> " + to);
    }

    private static double convertTemperature(double value, String from, String to) {
        if (from.equals(to)) {
            return value;
        }
        switch (from) {
            case "C":
                if ("F".equals(to)) {
                    return value * 9.0 / 5.0 + 32;
                }
                if ("K".equals(to)) {
                    return value + 273.15;
                }
                break;
            case "F":
                if ("C".equals(to)) {
                    return (value - 32) * 5.0 / 9.0;
                }
                if ("K".equals(to)) {
                    return (value - 32) * 5.0 / 9.0 + 273.15;
                }
                break;
            case "K":
                if ("C".equals(to)) {
                    return value - 273.15;
                }
                if ("F".equals(to)) {
                    return (value - 273.15) * 9.0 / 5.0 + 32;
                }
                break;
            default:
                break;
        }
        throw new IllegalArgumentException("Invalid temperature conversion: " + from + " -> " + to);
    }
}
