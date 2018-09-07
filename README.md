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
