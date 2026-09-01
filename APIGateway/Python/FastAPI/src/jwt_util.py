import base64
import hashlib
import hmac
import json
import time

import config


def _base64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode("ascii")


def _base64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode(data + padding)


def _hmac(data: str, secret: str) -> str:
    digest = hmac.new(
        secret.encode("utf-8"), data.encode("utf-8"), hashlib.sha256
    ).digest()
    return _base64url_encode(digest)


def sign(payload: dict, secret: str) -> str:
    header = {"alg": "HS256", "typ": "JWT"}
    signing_input = (
        _base64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
        + "."
        + _base64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
    )
    return signing_input + "." + _hmac(signing_input, secret)


def verify(token: str, secret: str):
    parts = token.split(".")
    if len(parts) != 3:
        return None
    signing_input = parts[0] + "." + parts[1]
    expected = _hmac(signing_input, secret)
    if not hmac.compare_digest(expected, parts[2]):
        return None
    try:
        body = json.loads(_base64url_decode(parts[1]).decode("utf-8"))
    except Exception:
        return None
    exp = body.get("exp")
    if exp is not None and time.time() > float(exp):
        return None
    return body