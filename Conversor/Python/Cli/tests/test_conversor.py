import pytest
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from conversor import convert, list_categories

def test_length_conversion():
    result = convert(1, "m", "cm")
    assert abs(result - 100) < 0.001

def test_weight_conversion():
    result = convert(1, "kg", "g")
    assert abs(result - 1000) < 0.001

def test_temperature_c_to_f():
    result = convert(0, "C", "F")
    assert abs(result - 32) < 0.001

def test_temperature_c_to_k():
    result = convert(0, "C", "K")
    assert abs(result - 273.15) < 0.001

def test_temperature_f_to_c():
    result = convert(32, "F", "C")
    assert abs(result - 0) < 0.001

def test_temperature_f_to_k():
    result = convert(32, "F", "K")
    assert abs(result - 273.15) < 0.001

def test_temperature_k_to_c():
    result = convert(273.15, "K", "C")
    assert abs(result - 0) < 0.001

def test_temperature_k_to_f():
    result = convert(273.15, "K", "F")
    assert abs(result - 32) < 0.001

def test_invalid_unit():
    with pytest.raises(ValueError):
        convert(1, "m", "kg")

def test_incompatible_categories():
    with pytest.raises(ValueError):
        convert(1, "m", "kg")

def test_list_categories():
    cats = list_categories()
    assert "length" in cats
    assert "weight" in cats
    assert "temperature" in cats

def test_km_to_mi():
    result = convert(1, "km", "mi")
    assert abs(result - 0.621371) < 0.001

def test_ft_to_in():
    result = convert(1, "ft", "in")
    assert abs(result - 12) < 0.001

def test_lb_to_oz():
    result = convert(1, "lb", "oz")
    assert abs(result - 16) < 0.001

def test_kg_to_mg():
    result = convert(1, "kg", "mg")
    assert abs(result - 1000000) < 0.001

def test_identity():
    result = convert(100, "cm", "cm")
    assert abs(result - 100) < 0.001
