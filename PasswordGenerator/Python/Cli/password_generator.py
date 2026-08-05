import random
import string
import sys

UPPERCASE = string.ascii_uppercase
LOWERCASE = string.ascii_lowercase
DIGITS = string.digits
SYMBOLS = "!@#$%^&*()_+-=[]{}|;:,.<>?"

ALL_CHARS = {
    "upper": UPPERCASE,
    "lower": LOWERCASE,
    "digits": DIGITS,
    "symbols": SYMBOLS,
}


def generate_password(length=16, use_upper=True, use_lower=True, use_digits=True, use_symbols=True):
    if length < 1:
        raise ValueError("Password length must be at least 1")

    categories = []
    if use_upper:
        categories.append(UPPERCASE)
    if use_lower:
        categories.append(LOWERCASE)
    if use_digits:
        categories.append(DIGITS)
    if use_symbols:
        categories.append(SYMBOLS)

    if not categories:
        raise ValueError("At least one character category must be enabled")

    if length < len(categories):
        raise ValueError(
            f"Password length must be at least {len(categories)} "
            f"when {len(categories)} categories are enabled"
        )

    password = [random.choice(cat) for cat in categories]

    all_chars = "".join(categories)
    password.extend(random.choice(all_chars) for _ in range(length - len(categories)))

    random.shuffle(password)

    return "".join(password)


def show_menu():
    print("=== Password Generator ===")
    try:
        length = int(input(f"Length (default 16): ").strip() or "16")
    except ValueError:
        length = 16

    use_upper = input("Include uppercase? (Y/n): ").strip().lower() != "n"
    use_lower = input("Include lowercase? (Y/n): ").strip().lower() != "n"
    use_digits = input("Include digits? (Y/n): ").strip().lower() != "n"
    use_symbols = input("Include symbols? (Y/n): ").strip().lower() != "n"

    try:
        password = generate_password(length, use_upper, use_lower, use_digits, use_symbols)
        print(f"\nGenerated password: {password}")
    except ValueError as e:
        print(f"Error: {e}")


def parse_args():
    import argparse
    parser = argparse.ArgumentParser(description="Generate secure passwords")
    parser.add_argument("-l", "--length", type=int, default=16, help="Password length")
    parser.add_argument("--no-upper", action="store_false", dest="use_upper", help="Disable uppercase letters")
    parser.add_argument("--no-lower", action="store_false", dest="use_lower", help="Disable lowercase letters")
    parser.add_argument("--no-digits", action="store_false", dest="use_digits", help="Disable digits")
    parser.add_argument("--no-symbols", action="store_false", dest="use_symbols", help="Disable symbols")
    return parser.parse_args()


if __name__ == "__main__":
    if len(sys.argv) > 1:
        args = parse_args()
        try:
            password = generate_password(
                args.length, args.use_upper, args.use_lower, args.use_digits, args.use_symbols
            )
            print(password)
        except ValueError as e:
            print(f"Error: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        show_menu()
