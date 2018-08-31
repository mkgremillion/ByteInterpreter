# frozen_string_literal: true

require './Instructions.rb'

##
# The ByteInterpreter is a tool used to extract bytes and strings from a binary
# file, and also to encode bytes and strings into a binary file. It can also
# take a series of instructions to extract or encode data in an ordinal manner,
# suitable for writing binary files with strict structure size requirements.
class ByteInterpreter

  attr_reader :endian_mode

  def initialize(endian: nil, iostream:)
    @endian_mode = endian.to_sym
    @iostream = iostream
    @instructions = nil
  end

  def interpret_bytes(size: 2, signed: false)
    bytes = @iostream.read(size)
    directive = build_directive(size: size, signed: signed)

    bytes.unpack(directive).first
  end

  def interpret_string(size: )
    @iostream.read(size)
  end

  def encode_bytes(value:, size:, signed:)
    unless value.respond_to? :pack
      value = Array(value)
    end
    @iostream.write(value.pack(build_directive(size: size, signed: signed)))
  end

  def encode_string(value:, size:)
    @iostream.write(value.ljust(size, "\x20"))
  end

  def load_instructions(type:, filename:)
    @instructions = Instructions.new if @instructions.nil?
    @instructions.clear
    @instructions.send("load_from_" + type.to_s, filename: filename)
  end

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

  DIRECTIVE_SIZES = {1 => "C", 2 => "S", 4 => "L", 8 => "Q"}

  def determine_directive_letter(size:)
    if DIRECTIVE_SIZES.has_key?(size)
      return DIRECTIVE_SIZES[size]
    else
      raise ArgumentError.new("Invalid size argument (#{size}). See documentation for valid sizes.")
    end
  end

  def determine_endian_glyph
    case endian_mode
    when :little
      return "<"
    when :big
      return ">"
    end
  end

  def build_directive(size: , signed:)
    directive = determine_directive_letter(size: size)
    directive.downcase! if signed

    if "SsLlQqJjIi".include?(directive)
      directive += determine_endian_glyph
    end

    directive
  end

end
