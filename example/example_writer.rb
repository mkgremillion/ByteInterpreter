require_relative "../lib/byteinterpreter.rb"

# Open the file. Mode "wb" means we're only opening it for writing, and we're
# opening it for binary writing specifically.
bin_file = File.open("SPELL.BIN", "wb")

# We create our interpreter. SPELL.BIN is in little endian.
bi = ByteInterpreter.new(endian: :little, stream: bin_file)

# Let's write our first byte, which is the element of the first spell.
# Remember, ByteInterpreter will write to whatever position the iostream is at,
# and will move the position by however many bytes are written.
bi.encode_bytes(value: 1, size: 1, signed: false)

# The next field is the name of the spell, a string.
# Even though the string is shorter than the size given, ByteInterpreter will
# make an attempt to have the string fit. In this case, it'll pad the name with
# spaces until it reaches the appropriate size.
bi.encode_string(value: "Fireball", size: 20)

# Let's finish writing the spell.
bi.encode_bytes(value: 20, size: 2, signed: false)
bi.encode_string(value: "Tosses a fireball at your foes", size: 50)
bi.encode_bytes(value: -10, size: 1, signed: true)

# Now that we've used the individual writing methods, let's dive into using
# instructions. We'll load the instructions from our JSON file.
bi.load_instructions(type: :json, filename: "./spell_instructions.json")

# Here's a hash that represents one of our spells. When writing with
# instructions, it is *absolutely vital* that your hash contains every
# expected field name. 
new_spell = {element: 2, power: 15, speed: 20,  name: "Thunderclap", description: "A quick strike of lightning"}

# Now we write the hash to our file.
bi.encode_from_instructions(values: new_spell)

# And if we want to write multiple spells at once, it's not too difficult.
spells = [
{element: 3, power: 40, speed: -20, name: "Zero K", description: "The ultimate ice spell"},
{element: 1, power: 50, speed: 0,   name: "Melt", description: "For when you need something gone, now."}
]

spells.each do |spell|
  bi.encode_from_instructions(values: spell)
end

# Not specific to ByteInterpreter, but don't forget to close your file! =)
bin_file.close

# If you want to see the fruits of your labor, you can use example_reader.rb to
# read your SPELL.BIN file, or open it with a hex editor.