# frozen_string_literal: true

require './byte_interpreter/instructions.rb'

##
# The ByteInterpreter is a tool used to extract bytes and strings from a binary
# file, and also to encode bytes and strings into a binary file. It can also
# take a series of instructions to extract or encode data in an ordinal manner,
# suitable for writing binary files with rigid structure size requirements.
class ByteInterpreter

  ##
  # Reads the endian mode being used by the interpreter.
  attr_reader :endian_mode

  ##
  # Creates and sets up a new ByteInterpreter.
  # @param endian [:little, :big, nil] Default for this value is nil. The
  #   endian mode that will be used by the interpreter for reading/writing
  #   bytes. If nil is specified, the interpreter will assume machine-native
  #   endianness.
  # @param stream [#read, #write] The IO stream, or IO-like object, that the
  #   interpreter will perform operations on. The interpreter will not open or
  #   close the stream for you, and assumes you have already changed the
  #   position to the appropriate offset for its operations. The interpreter
  #   also assumes you have opened the stream as binary (as opposed to text),
  #   and for the appropriate operations (read/write).
  def initialize(endian: nil, stream:)
    @endian_mode = endian.to_sym
    @instructions = nil
    iostream = stream
  end

  ##
  # Changes the stream being used by the interpreter for operations.
  # @param new_stream [#read, #write] The IO stream, or IO-like object, that
  #   the interpreter will perform operations on. See #new for what is expected
  #   of this stream.
  # @return [ByteInterpreter] self
  def iostream=(new_stream)
    if stream_like?(obj: new_stream)
      @iostream = new_stream if stream_like?(obj: new_stream)
    else
      raise ArgumentError.new("Object given is not stream-like.")
    end

    self
  end

  ##
  # Reads a set number of bytes, interprets them into an integer, and returns
  # the result.
  # @param size [1, 2, 4, 8] The number of bytes to read from the stream.
  #   ByteInterpreter can only interpret 8-, 16-, 32-, and 64-bit values at
  #   this time, so this parameter is limited to just a few numbers.
  # @param signed [Boolean] Default for this value is false. Set this to
  #   true if the bytes being read can be negative or positive.
  # @return [Integer] the interpreted byte
  def interpret_bytes(size: 2, signed: false)
    bytes = @iostream.read(size)
    directive = build_directive(size: size, signed: signed)

    bytes.unpack(directive).first
  end

  ##
  # Reads a set number of bytes, interprets them into a string, and returns the
  # result.
  # @param size [Integer] The number of bytes to read from the stream. Unlike
  #   #interpret_bytes, this size can be any positive integer.
  # @return [String] the interpreted string
  def interpret_string(size: )
    @iostream.read(size)
  end

  ##
  # Writes a set number of bytes, encoded from the given value.
  # @param value [Integer] The value to encode and write.
  # @param size [1,2,4,8] The size of the value in bytes.
  # @param signed [Boolean] Set this to true if the bytes being written can be
  #   negative and positive, false otherwise.
  # @return [void]
  # @note The interpreter makes no attempt to ensure that your +value+ fits
  #   into +size+ bytes. To avoid unintended behavior, you should validate your
  #   input into this method.
  def encode_bytes(value:, size:, signed:)
    unless value.respond_to? :pack
      value = Array(value)
    end
    @iostream.write(value.pack(build_directive(size: size, signed: signed)))
  end

  ##
  # Writes a string into a given number of bytes.
  # @param value [String] The value to write to the stream.
  # @param size [Integer] The size of the value in bytes. Unlike
  #   #encode_bytes, this size can be any positive integer.
  # @return [void]
  # @note If +value+ is smaller than +size+, the interpreter will pad +value+
  #   with 0x20 to fill the remaining space. Even so, care should be taken to
  #   validate your input to this method, especially if you want to handle
  #   strings that are larger than +size+, or want to handle size differences
  #   differently than this method.
  def encode_string(value:, size:)
    @iostream.write(value.ljust(size, "\x20"))
  end

  ##
  # Loads instructions from a file for structured, ordinal operations.
  # @param type [Symbol] The type of the file that holds the instructions.
  #   This argument **must** have a corresponding method in the
  #   ByteInterpreter::Instructions class, named +load_from_type+, replacing
  #   +type+ with the actual name of the filetype.
  # @param filename [String] The filename of the instructions to load.
  # @return [void]
  # @note ByteInterpreter comes with only one +type+ built-in: JSON.
  def load_instructions(type:, filename:)
    @instructions = Instructions.new if @instructions.nil?
    @instructions.clear
    @instructions.send("load_from_" + type.to_s, filename: filename)
  end

  ##
  # Uses the loaded instructions (you did call #load_instructions first,
  # right?) to interpret bytes and strings from the stream, passing them as
  # arguments to the given block.
  # @yieldparam key [Symbol] The key of the interpreted data. Typically used to
  #   set variables in the calling object.
  # @yieldparam value [Integer, String] The value of the interpreted data.
  # @return [Integer] the combined size, in bytes, of the operation
  def interpret_from_instructions
    struct_size = 0
    @instructions.each do |field|
      if field[:type] == "bin"
        value = interpret_bytes(size: field[:size], signed: field[:signed])
      elsif field[:type] == "str"
        value = interpret_string(size: field[:size])
      end

      struct_size = struct_size + field[:size]

      yield field[:key], value
    end

    return struct_size
  end

  ##
  # Uses the loaded instructions (you did call #load_instructions first,
  # right?) to encode the given values into bytes and strings, and write them
  # to the stream.
  #
  # This method encodes and writes bytes in the order of the loaded
  # instructions; this means it will seek each key from the given Hash, instead
  # of seeking around the file and writing in whatever order the Hash may be
  # in.
  # @param values [Hash] The values to read and encode. This Hash **must**
  #   have keys that match *all* keys from the loaded instructions.
  # @return [Integer] the combined size, in bytes, of the operation
  def encode_from_instructions(values:)
    struct_size = 0
    @instructions.each do |field|
      key = field[:key].to_sym

      if field[:type] == "bin"
        encode_bytes(value: values[key], size: field[:size], signed: field[:signed])
      elsif field[:type] == "str"
        encode_string(value: values[key],size: field[:size])
      end

      struct_size = struct_size + field[:size]
    end

    return struct_size
  end


  private

  ##
  # This constant maps byte lengths to their respective Strings for the
  # directives in Array#pack and String#unpack.
  DIRECTIVE_SIZES = {1 => "C", 2 => "S", 4 => "L", 8 => "Q"}

  ##
  # Uses DIRECTIVE_SIZES to translate a byte length to a usable String.
  # @param size [1,2,4,8] The byte length to translate.
  # @raise [ArgumentError] if +size+ is not 1, 2, 4, or 8.
  # @return [String] the translated directive String.
  def determine_directive_letter(size:)
    if DIRECTIVE_SIZES.has_key?(size)
      return DIRECTIVE_SIZES[size].dup
    else
      raise ArgumentError.new("Invalid size argument (#{size}). See documentation for valid sizes.")
    end
  end

  ##
  # Returns the glyph for the set endianness, for use in building the directive
  # String.
  # @return [String] if endian_mode is non-nil
  # @return [nil] if endian_mode is nil
  def determine_endian_glyph
    case endian_mode
    when :little
      return "<"
    when :big
      return ">"
    end
  end

  ##
  # Builds a directive String, fit for use in Array#pack and String#unpack.
  # @param size [1,2,4,8] The size to translate into a directive String.
  # @param signed [Boolean] Set this to true if the bytes being written can be
  #   negative and positive, false otherwise.
  # @return [String] the built directive String
  def build_directive(size: , signed:)
    directive = determine_directive_letter(size: size)
    directive.downcase! if signed

    if "SsLlQqJjIi".include?(directive)
      directive += determine_endian_glyph
    end

    directive
  end

  ##
  # Checks if the given object is stream-like -- that is, responds to #read
  # and #write.
  # @param obj [Object] The object to test.
  # @return [Boolean]
  # @note For fun, consider making an inverse of this method named
  #   "illiterate?"
  def stream_like?(obj:)
    return obj.respond_to?(:read) && obj.respond_to?(:write)
  end

end
