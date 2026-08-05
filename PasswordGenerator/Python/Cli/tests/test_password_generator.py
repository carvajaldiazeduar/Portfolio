import pytest
import string
from password_generator import generate_password, UPPERCASE, LOWERCASE, DIGITS, SYMBOLS


class TestGeneratePassword:
    def test_default_length(self):
        pw = generate_password()
        assert len(pw) == 16

    def test_custom_length(self):
        pw = generate_password(length=24)
        assert len(pw) == 24

    def test_min_length(self):
        pw = generate_password(length=1, use_upper=True, use_lower=False, use_digits=False, use_symbols=False)
        assert len(pw) == 1

    def test_uppercase_present(self):
        pw = generate_password(use_upper=True, use_lower=False, use_digits=False, use_symbols=False)
        assert any(c in UPPERCASE for c in pw)

    def test_lowercase_present(self):
        pw = generate_password(use_upper=False, use_lower=True, use_digits=False, use_symbols=False)
        assert any(c in LOWERCASE for c in pw)

    def test_digits_present(self):
        pw = generate_password(use_upper=False, use_lower=False, use_digits=True, use_symbols=False)
        assert any(c in DIGITS for c in pw)

    def test_symbols_present(self):
        pw = generate_password(use_upper=False, use_lower=False, use_digits=False, use_symbols=True)
        assert any(c in SYMBOLS for c in pw)

    def test_no_uppercase(self):
        pw = generate_password(use_upper=False)
        assert not any(c in UPPERCASE for c in pw)

    def test_no_symbols(self):
        pw = generate_password(use_symbols=False)
        assert not any(c in SYMBOLS for c in pw)

    def test_no_lowercase(self):
        pw = generate_password(use_lower=False)
        assert not any(c in LOWERCASE for c in pw)

    def test_no_digits(self):
        pw = generate_password(use_digits=False)
        assert not any(c in DIGITS for c in pw)

    def test_all_disabled_raises(self):
        with pytest.raises(ValueError, match="At least one character category must be enabled"):
            generate_password(use_upper=False, use_lower=False, use_digits=False, use_symbols=False)

    def test_length_zero_raises(self):
        with pytest.raises(ValueError, match="Password length must be at least 1"):
            generate_password(length=0)

    def test_negative_length_raises(self):
        with pytest.raises(ValueError, match="Password length must be at least 1"):
            generate_password(length=-5)

    def test_length_too_short_for_categories(self):
        with pytest.raises(ValueError):
            generate_password(length=2, use_upper=True, use_lower=True, use_digits=True, use_symbols=True)

    def test_at_least_one_from_each_enabled(self):
        pw = generate_password(length=20, use_upper=True, use_lower=True, use_digits=True, use_symbols=True)
        assert any(c in UPPERCASE for c in pw)
        assert any(c in LOWERCASE for c in pw)
        assert any(c in DIGITS for c in pw)
        assert any(c in SYMBOLS for c in pw)

    def test_only_uppercase_and_digits(self):
        pw = generate_password(length=12, use_upper=True, use_lower=False, use_digits=True, use_symbols=False)
        assert any(c in UPPERCASE for c in pw)
        assert any(c in DIGITS for c in pw)
        assert not any(c in LOWERCASE for c in pw)
        assert not any(c in SYMBOLS for c in pw)

    def test_shuffled_not_sequential(self):
        passwords = [generate_password() for _ in range(5)]
        unique = len(set(passwords))
        assert unique > 1, "Passwords should be randomly shuffled, not sequential"
