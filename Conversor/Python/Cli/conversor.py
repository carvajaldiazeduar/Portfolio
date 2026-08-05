import sys

CONVERSION = {
    "length": {
        "m": 1.0,
        "km": 0.001,
        "mi": 0.000621371,
        "ft": 3.28084,
        "in": 39.3701,
        "cm": 100.0,
    },
    "weight": {
        "kg": 1.0,
        "g": 1000.0,
        "lb": 2.20462,
        "oz": 35.274,
        "mg": 1000000.0,
    },
    "temperature": {
        "C": "celsius",
        "F": "fahrenheit",
        "K": "kelvin",
    },
}

CATEGORY_UNITS = {
    "length": ["m", "km", "mi", "ft", "in", "cm"],
    "weight": ["kg", "g", "lb", "oz", "mg"],
    "temperature": ["C", "F", "K"],
}

def list_categories():
    return list(CONVERSION.keys())

def convert(value, from_unit, to_unit):
    for category, units in CONVERSION.items():
        if from_unit in units and to_unit in units:
            if category == "temperature":
                return _convert_temperature(value, from_unit, to_unit)
            factor_from = units[from_unit]
            factor_to = units[to_unit]
            return value / factor_from * factor_to
    raise ValueError(f"Incompatible units: {from_unit} -> {to_unit}")

def _convert_temperature(value, from_unit, to_unit):
    if from_unit == to_unit:
        return value
    if from_unit == "C":
        if to_unit == "F":
            return value * 9.0 / 5.0 + 32
        if to_unit == "K":
            return value + 273.15
    if from_unit == "F":
        if to_unit == "C":
            return (value - 32) * 5.0 / 9.0
        if to_unit == "K":
            return (value - 32) * 5.0 / 9.0 + 273.15
    if from_unit == "K":
        if to_unit == "C":
            return value - 273.15
        if to_unit == "F":
            return (value - 273.15) * 9.0 / 5.0 + 32
    raise ValueError(f"Invalid temperature conversion: {from_unit} -> {to_unit}")

def _get_unit_category(unit):
    for category, units in CONVERSION.items():
        if unit in units:
            return category
    return None

def _find_units(category):
    return list(CONVERSION[category].keys())

def main():
    print("=== Unit Converter ===")
    while True:
        print("\nCategories:")
        cats = list_categories()
        for i, cat in enumerate(cats, 1):
            print(f"  {i}. {cat}")
        print("  0. Exit")
        try:
            choice = int(input("Select category: "))
            if choice == 0:
                print("Goodbye!")
                break
            if choice < 1 or choice > len(cats):
                print("Invalid choice")
                continue
            category = cats[choice - 1]
        except ValueError:
            print("Invalid input")
            continue

        units = CATEGORY_UNITS[category]
        print(f"\nUnits ({category}):")
        for i, u in enumerate(units, 1):
            print(f"  {i}. {u}")

        try:
            from_idx = int(input("Select from unit: ")) - 1
            to_idx = int(input("Select to unit: ")) - 1
            if from_idx < 0 or from_idx >= len(units) or to_idx < 0 or to_idx >= len(units):
                print("Invalid unit selection")
                continue
            value = float(input("Enter value: "))
            result = convert(value, units[from_idx], units[to_idx])
            print(f"\nResult: {value} {units[from_idx]} = {result} {units[to_idx]}")
        except ValueError as e:
            print(f"Error: {e}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == "__main__":
    main()
