require_relative "../lib/byteinterpreter.rb"

# Open the file. Mode "rb" means we're only opening it for reading, and we're
# opening it for binary reading.
bin_file = File.open("SPELL.BIN", "rb")

# We create our interpreter. SPELL.BIN is in little endian.
bi = ByteInterpreter.new(endian: :little, stream: bin_file)

# Let's read the first byte, which should be the element of the first spell.
# Remember, ByteInterpreter will read from whatever position the iostream is
# at, and will move the position by however many bytes are read.
puts "Reading the first byte: #{bi.interpret_bytes(size: 1)}"

# The next set of bytes should be the name of the spell, a string.
puts "Reading the spell name: #{bi.interpret_string(size: 20)}"

# Let's read the rest of the spell entry.
puts "Reading the spell power: #{bi.interpret_bytes(size: 2)}"
puts "Reading the spell description: #{bi.interpret_string(size: 50)}"
puts "Reading the spell speed: #{bi.interpret_bytes(size: 1, signed: true)}"

# Now that we've used the individual reading methods, let's dive into using
# instructions. We'll load the instructions from our JSON file.
bi.load_instructions(type: :json, filename: "./spell_instructions.json")

# Let's read one whole spell from our binary file. This will be the second
# spell entry.
puts "\nReading spell entry 2: "
puts "==========================================="
bi.interpret_from_instructions do |key, value|
  puts "Field name:  #{key}"
  puts "Field value: #{value}"
  puts "-------------------------------"
end

# And of course, if you want to read multiple entries, it's not too difficult.
2.times do |i|
  puts "\nReading spell entry #{i + 3}: "
  puts "==========================================="
  bi.interpret_from_instructions do |key, value|
    puts "Field name:  #{key}"
    puts "Field value: #{value}"
    puts "-------------------------------"
  end
end

# Not specific to ByteInterpreter, but don't forget to close your file! =)
bin_file.close