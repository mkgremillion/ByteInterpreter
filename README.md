ByteInterpreter is a tool to interpret binary data in a fixed-length data
structure into another format, or to encode data from another format into that
same fixed-length data structure.

## Introduction
ByteInterpreter was made to assist with modifying an old Dreamcast-era RPG, by
translating some of its content (spells, abilities, etc) from binary data into
a human-readable format. Since the potential applications for this tool are more
broad than just making mods for a singular videogame, I decided to spin it off
into its own little tool for others to use.

## Scope
ByteInterpreter isn't overly-ambitious -- it's just there to read and write
bytes for *fixed-length* data structures. That "fixed-length" bit is important
-- there are no plans for ByteInterpreter to support data structures with
variable length values. In the future I may expand ByteInterpreter's ability to
cope with variable-length data structures, but only once it works the best it
can with fixed-length structures.

Right now, it can interpret binary data in four sizes - 8-bit, 16-bit, 32-bit,
and 64-bit. It can also read strings in any arbitrary size. In the near future,
I'd like to support reading bit fields and to handle pointers appropriately.

## Installation
ByteInterpreter can be installed with the following command -
```
gem install byteinterpreter
```
Afterwards, it's just a matter of requiring it in your code -
```ruby
require 'byteinterpreter'
```

## Examples
In this example, we're trying to mod an old RPG named *Last Illusion VII*. We
have the binary file that contains the game's spells, and we know the format
for those spells is something like:
1. Unsigned 8-bit integer - Spell element
2. String, 20 characters - Spell name
3. Unsigned 16-bit integer - Spell damage
4. String, 50 characters - Spell description
5. Signed 8-bit integer - Spell speed

So how do we extract the information from this binary file?

### Reading bit by bit
The simplest way is to make a new instance of ByteInterpreter, load the binary
file, and read the information bit by bit with `#interpret_bytes` and
`#interpret_string`.
```ruby
require 'byteinterpreter'

f = File.open("SPELLS.BIN", "rb")
bi = ByteInterpreter.new(stream: f)

# Interpret the first spell's element
element = bi.interpret_bytes(size: 1, signed: false)
# => 1

# Interpret the first spell's name
name = bi.interpret_string(size: 20)
# => "Fireball           "
```
These two methods can read most simple structures in binary files. Take care
to read values as `signed` when appropriate! For instance, in our example format,
spell speed is signed, so we'd read it thus:
```ruby
bi.interpret_bytes(size: 1, signed: true)
# => -50
```
Technically speaking, nothing truly horrid will happen if you forget, but your
data will be inaccurate.

The other method of reading bytes from a binary file is to use Instructions.

### Using Instructions
In order to use Instructions, you must first load them. As of writing this
README, ByteInterpreter only knows how to load Instructions from JSON. You can
load JSON instructions with the `#load_instructions` method:
```ruby
bi.load_instructions(type: :json, filename: "spell_instructions.json")
```
The expected format of a JSON file for Instructions is an array containing
objects, one object for each field we'll be reading. The objects should each
have the following attributes: `"key"`, `"type"`, `"size"`, and `"signed"`.
* `key` - The name of the field we're reading (e.g. "Element" or "Name")
* `type` - The type of the field, either "bin" for binary values or "str" for
  strings.
* `size` - How many bytes the field is. Binary values can only be 1, 2, 4, or
  8 bytes, but string values can be as short or long as you wish.
* `signed` - For binary values, if the resulting integer is signed or not.
  Totally ignored for strings.

So a JSON Instructions file for our example might look like this:
```json
[
  {
    "key": "element", "type": "bin", "size": 1, "signed": false
  },
  {
    "key": "name", "type": "str", "size": 20, "signed": false
  },
  {
    "key": "power", "type": "bin", "size": 2, "signed": false
  },
  {
    "key": "description", "type": "str", "size": 50, "signed": false
  },
  {
    "key": "speed", "type": "bin", "size": 1, "signed": true
  }
]
```
If your Instructions are incorrectly formatted, never fear: ByteInterpreter
will raise a `ValidationError` and let you know what you did wrong. Also note:
it's very important that the objects in the array are in the same order as the
fields in the structure you're reading, as it will read the binary file in the
exact same order as specified in the JSON array. The validation methods won't
catch this, as ByteInterpreter has no idea what format your file is supposed to
be in.

Once you load these instructions, using them is very easy. We use the
`#interpret_from_instructions` method, which takes a block and passes the
key and interpreted value of each individual instruction to the given block.
```ruby
spell = {}
bi.load_instructions(type: :json, filename: "spell_instructions.json")
bi.interpret_from_instructions do |key, value|
  spell[key] = value
end

spell.inspect
# => {:element => 1, :name => "Fireball           ", etc.
```
_**Note:** You may have noticed in the examples, but ByteInterpreter will
preserve any whitespace given in strings. It makes no assumptions about what
you want to do with the interpreted string, so if you want to remove any
whitespace you will have to call `#chomp` yourself._

Reading the entire spell file would just involve wrapping your call to
`#interpret_from_instructions` inside a loop of some sort:
```ruby
spellbook = Array.new
30.times do
  spell = {}
  bi.interpret_from_instructions do |key, value|
    spell[key] = value
  end
  spellbook.push(spell)
end
```

### Writing bytes
Writing bytes is almost as easy as reading them.
```ruby
f = File.new("NEW_SPELLS.BIN", "wb")
bi = ByteInterpreter.new(stream: f)

bi.encode_bytes(value: 1, size: 1, signed: false)
bi.encode_string(value: "Fireball", size: 20)
```
These methods work about how you expect them to. `#encode_bytes` makes no
attempt to ensure the value you're passing to it actually fits into the given
size in bytes, so you should probably do some checking before encoding.
Thankfully, `#encode_strings` is friendlier and will either pad or truncate
your string to fit the appropriate size.

And of course, encoding works with instructions as well.
```ruby
new_spell = {element: 1, name: "Fireball", etc.}
bi.encode_from_instructions(values: new_spell)
```
`#encode_from_instructions` takes only one argument, a `Hash` with keys
matching each field key in the Instructions file, and values paired with those
keys that match the type for that field in the Instructions file. It is
**very** important that your given `Hash` contains one key for each field;
otherwise `#encode_from_instructions` will attempt to read a nonexistant key.

If you'd like to write your own Instructions, see the
[instructions.rb file](./lib/byte_interpreter/instructions.rb), it has a fairly
in-depth explanation on doing so.
