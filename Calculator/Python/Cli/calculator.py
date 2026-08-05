def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
    if b == 0:
        return "Error: Cannot divide by zero"
    return a / b


def show_menu():
    print("\n=== Simple Calculator ===")
    print("1. Add")
    print("2. Subtract")
    print("3. Multiply")
    print("4. Divide")
    print("5. Exit")


def get_number(prompt):
    while True:
        try:
            return float(input(prompt))
        except ValueError:
            print("Invalid input. Please enter a number.")


def main():
    operations = {
        "1": ("add", add, "+"),
        "2": ("subtract", subtract, "-"),
        "3": ("multiply", multiply, "*"),
        "4": ("divide", divide, "/"),
    }

    while True:
        show_menu()
        choice = input("Choose an option (1-5): ")

        if choice == "5":
            print("Goodbye!")
            break

        if choice not in operations:
            print("Invalid option. Please try again.")
            continue

        num1 = get_number("Enter first number: ")
        num2 = get_number("Enter second number: ")

        _, func, operation = operations[choice]
        result = func(num1, num2)

        print(f"\n{num1} {operation} {num2} = {result}")


if __name__ == "__main__":
    main()
