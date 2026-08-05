CONVERSION = {
  'length' => {
    'm' => 1.0,
    'km' => 0.001,
    'mi' => 0.000621371,
    'ft' => 3.28084,
    'in' => 39.3701,
    'cm' => 100.0
  },
  'weight' => {
    'kg' => 1.0,
    'g' => 1000.0,
    'lb' => 2.20462,
    'oz' => 35.274,
    'mg' => 1_000_000.0
  },
  'temperature' => {
    'C' => 'celsius',
    'F' => 'fahrenheit',
    'K' => 'kelvin'
  }
}.freeze

CATEGORY_UNITS = {
  'length' => %w[m km mi ft in cm],
  'weight' => %w[kg g lb oz mg],
  'temperature' => %w[C F K]
}.freeze

def list_categories
  CONVERSION.keys
end

def convert(value, from_unit, to_unit)
  CONVERSION.each do |category, units|
    next unless units.key?(from_unit) && units.key?(to_unit)

    return convert_temperature(value, from_unit, to_unit) if category == 'temperature'

    factor_from = units[from_unit]
    factor_to = units[to_unit]
    return value / factor_from * factor_to
  end
  raise ArgumentError, "Incompatible units: #{from_unit} -> #{to_unit}"
end

def convert_temperature(value, from_unit, to_unit)
  return value if from_unit == to_unit

  if from_unit == 'C'
    return value * 9.0 / 5.0 + 32 if to_unit == 'F'
    return value + 273.15 if to_unit == 'K'
  end
  if from_unit == 'F'
    return (value - 32) * 5.0 / 9.0 if to_unit == 'C'
    return (value - 32) * 5.0 / 9.0 + 273.15 if to_unit == 'K'
  end
  if from_unit == 'K'
    return value - 273.15 if to_unit == 'C'
    return (value - 273.15) * 9.0 / 5.0 + 32 if to_unit == 'F'
  end
  raise ArgumentError, "Invalid temperature conversion: #{from_unit} -> #{to_unit}"
end

def main
  puts '=== Unit Converter ==='
  loop do
    puts "\nCategories:"
    cats = list_categories
    cats.each_with_index { |cat, i| puts "  #{i + 1}. #{cat}" }
    puts '  0. Exit'
    print 'Select category: '
    line = gets.to_s.strip
    break puts('Goodbye!') if line == '0'

    idx = line.to_i - 1
    if idx < 0 || idx >= cats.length
      puts 'Invalid choice'
      next
    end
    category = cats[idx]

    units = CATEGORY_UNITS[category]
    puts "\nUnits (#{category}):"
    units.each_with_index { |u, i| puts "  #{i + 1}. #{u}" }

    print 'Select from unit: '
    from_idx = gets.to_i - 1
    print 'Select to unit: '
    to_idx = gets.to_i - 1
    if from_idx < 0 || from_idx >= units.length || to_idx < 0 || to_idx >= units.length
      puts 'Invalid unit selection'
      next
    end

    print 'Enter value: '
    value = Float(gets.to_s.strip)
    begin
      result = convert(value, units[from_idx], units[to_idx])
      puts "\nResult: #{value} #{units[from_idx]} = #{result} #{units[to_idx]}"
    rescue ArgumentError => e
      puts "Error: #{e.message}"
    end
  end
end

main if __FILE__ == $PROGRAM_NAME