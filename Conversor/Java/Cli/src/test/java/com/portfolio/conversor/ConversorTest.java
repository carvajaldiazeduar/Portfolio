package com.portfolio.conversor;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class ConversorTest {

    @Test
    void lengthConversion() {
        assertEquals(100, Conversor.convert(1, "m", "cm"), 1e-9);
        assertEquals(0.621371, Conversor.convert(1, "km", "mi"), 1e-9);
        assertEquals(1, Conversor.convert(100, "cm", "m"), 1e-9);
    }

    @Test
    void weightConversion() {
        assertEquals(1000, Conversor.convert(1, "kg", "g"), 1e-9);
        assertEquals(16, Conversor.convert(1, "lb", "oz"), 0.01);
        assertEquals(1, Conversor.convert(1000, "g", "kg"), 1e-9);
    }

    @Test
    void temperatureCtoF() {
        assertEquals(32, Conversor.convert(0, "C", "F"), 1e-9);
        assertEquals(212, Conversor.convert(100, "C", "F"), 1e-9);
    }

    @Test
    void temperatureCtoK() {
        assertEquals(273.15, Conversor.convert(0, "C", "K"), 1e-9);
    }

    @Test
    void temperatureFtoC() {
        assertEquals(0, Conversor.convert(32, "F", "C"), 1e-9);
    }

    @Test
    void temperatureFtoK() {
        assertEquals(273.15, Conversor.convert(32, "F", "K"), 1e-9);
    }

    @Test
    void temperatureKtoC() {
        assertEquals(0, Conversor.convert(273.15, "K", "C"), 1e-9);
    }

    @Test
    void temperatureKtoF() {
        assertEquals(32, Conversor.convert(273.15, "K", "F"), 1e-9);
    }

    @Test
    void temperatureIdentity() {
        assertEquals(100, Conversor.convert(100, "C", "C"), 1e-9);
    }

    @Test
    void incompatibleUnitsThrows() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> Conversor.convert(1, "m", "kg"));
        assertEquals("Incompatible units: m -> kg", ex.getMessage());
    }

    @Test
    void incompatibleTemperatureUnitsThrows() {
        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class,
                () -> Conversor.convert(1, "C", "m"));
        assertEquals("Incompatible units: C -> m", ex.getMessage());
    }

    @Test
    void categoriesListed() {
        String[] cats = Conversor.categories();
        assertEquals(3, cats.length);
        assertEquals("length", cats[0]);
        assertEquals("weight", cats[1]);
        assertEquals("temperature", cats[2]);
    }

    @Test
    void unitsPerCategory() {
        String[] length = Conversor.unitsFor("length");
        assertEquals(6, length.length);
        assertEquals("m", length[0]);
        assertEquals("cm", length[5]);
        String[] temperature = Conversor.unitsFor("temperature");
        assertEquals(3, temperature.length);
        assertEquals("K", temperature[2]);
    }
}
