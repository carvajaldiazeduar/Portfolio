const CONVERSION = {
  length: {
    m: 1.0,
    km: 0.001,
    mi: 0.000621371,
    ft: 3.28084,
    in: 39.3701,
    cm: 100.0,
  },
  weight: {
    kg: 1.0,
    g: 1000.0,
    lb: 2.20462,
    oz: 35.274,
    mg: 1000000.0,
  },
  temperature: {
    C: 'celsius',
    F: 'fahrenheit',
    K: 'kelvin',
  },
};

const CATEGORY_UNITS = {
  length: ['m', 'km', 'mi', 'ft', 'in', 'cm'],
  weight: ['kg', 'g', 'lb', 'oz', 'mg'],
  temperature: ['C', 'F', 'K'],
};

function listCategories() {
  return Object.keys(CONVERSION);
}

function convertTemperature(value, fromUnit, toUnit) {
  if (fromUnit === toUnit) return value;
  if (fromUnit === 'C') {
    if (toUnit === 'F') return value * 9.0 / 5.0 + 32;
    if (toUnit === 'K') return value + 273.15;
  }
  if (fromUnit === 'F') {
    if (toUnit === 'C') return (value - 32) * 5.0 / 9.0;
    if (toUnit === 'K') return (value - 32) * 5.0 / 9.0 + 273.15;
  }
  if (fromUnit === 'K') {
    if (toUnit === 'C') return value - 273.15;
    if (toUnit === 'F') return (value - 273.15) * 9.0 / 5.0 + 32;
  }
  throw new Error(`Invalid temperature conversion: ${fromUnit} -> ${toUnit}`);
}

function convert(value, fromUnit, toUnit) {
  for (const [category, units] of Object.entries(CONVERSION)) {
    if (fromUnit in units && toUnit in units) {
      if (category === 'temperature') {
        return convertTemperature(value, fromUnit, toUnit);
      }
      const factorFrom = units[fromUnit];
      const factorTo = units[toUnit];
      return value / factorFrom * factorTo;
    }
  }
  throw new Error(`Incompatible units: ${fromUnit} -> ${toUnit}`);
}

const readline = require('readline');

function main() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

  function ask(q) {
    return new Promise(resolve => rl.question(q, resolve));
  }

  (async () => {
    console.log('=== Unit Converter ===');
    while (true) {
      console.log('\nCategories:');
      const cats = listCategories();
      cats.forEach((c, i) => console.log(`  ${i + 1}. ${c}`));
      console.log('  0. Exit');
      const choice = parseInt(await ask('Select category: '));
      if (choice === 0) { console.log('Goodbye!'); rl.close(); break; }
      if (isNaN(choice) || choice < 1 || choice > cats.length) {
        console.log('Invalid choice'); continue;
      }
      const category = cats[choice - 1];
      const units = CATEGORY_UNITS[category];

      console.log(`\nUnits (${category}):`);
      units.forEach((u, i) => console.log(`  ${i + 1}. ${u}`));

      const fromIdx = parseInt(await ask('Select from unit: ')) - 1;
      const toIdx = parseInt(await ask('Select to unit: ')) - 1;
      if (!units[fromIdx] || !units[toIdx]) {
        console.log('Invalid unit selection'); continue;
      }
      const value = parseFloat(await ask('Enter value: '));
      try {
        const result = convert(value, units[fromIdx], units[toIdx]);
        console.log(`\nResult: ${value} ${units[fromIdx]} = ${result} ${units[toIdx]}`);
      } catch (e) {
        console.log(`Error: ${e.message}`);
      }
    }
  })();
}

if (require.main === module) {
  main();
}

module.exports = { convert, listCategories, CONVERSION, CATEGORY_UNITS };
