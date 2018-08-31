#frozen_string_literal: true

require 'json'

class ByteInterpreter

  ##
  # The Instructions class represents a collection of ordered operations to
  # perform on an IO stream. This class is used by ByteInterpreter to either
  # interpret or encode bytes in a rigid, structured way.
  #
  # At the most basic level, Instructions are just an Array filled with Hashes,
  # each Hash having exactly four keys -- :key, :type, :size, and :signed. Each
  # key has requirements for its value:
  # - :key -- Must be a value easily convertible to a Symbol object.
  # - :type -- Must match one of the elements in the constant VALID_TYPES.
  # - :size -- For binary types ("bin"), must match one of the elements in the
  #   constant VALID_BIN_SIZES. String types ("str") must be a
  #   positive Integer.
  # - :signed -- For binary types ("bin"), must be the +true+ or +false+
  #   literals. String types ("str") ignore this value completely.
  #
  # Writing your own method for loading instructions is fairly simple. The
  # method must call #add_field in the desired order of instruction execution,
  # passing to it a Hash that conforms to the requirements above. The method
  # must also be named +load_from_type+, where +type+ is what will be
  # passed into ByteInterpreter#load_instructions. See #load_from_json for an
  # example of this.
  class Instructions

    ##
    # Raised by instruction validation methods.
    class ValidationError < StandardError
    end

    ##
    # Valid values for the :type key in the instructions Hash.
    VALID_TYPES = ["bin", "str"]

    ##
    # Valid values for binary types for the :size key in the instructions Hash.
    VALID_BIN_SIZES = [1, 2, 4, 8]

    ##
    # Keys that are in every properly-formatted instructions Hash.
    FIELD_NAMES = [:key, :type, :size, :signed]

    ##
    # Creates a blank Instructions object.
    def initialize
      @data = []
    end

    ##
    # Passes the given block to the internal Array's #each method.
    def each(&block)
      @data.each(&block)
    end

    ##
    # Clears all loaded instructions.
    def clear
      @data.clear
    end

    ##
    # Adds the given Hash to the end of the list of instructions, and validates
    # it.
    # @param field [Hash] A properly-formatted instructions Hash. See the
    #   documentation for this class on the appropriate format for this Hash.
    # @return [void]
    def add_field(field:)
      @data.push(field.select {|k,v| FIELD_NAMES.include? k})
      validate_field(field: @data.last)
    end

    ##
    # Loads instructions from a JSON file. The JSON file should contain a
    # top-level array, with each element being an object with the appropriate
    # keys and values. Keys are automatically converted from strings to
    # symbols, but boolean values are not converted from strings to literals.
    # @param filename [String] The filename of the JSON file to load,
    #   **including** the filetype extension, if any.
    # @return [void]
    def load_from_json(filename:)
      json_fields = JSON.parse(File.open(filename, "rt") {|file| file.read}, {:symbolize_names => true})
      json_fields.each do |field|
        add_field(field: field)
      end
    end

    ##
    # Validates a given Hash to ensure it conforms to the instruction format.
    # @param field [Hash] The Hash object to evaluate.
    # @return [Boolean]
    # @raise [ValidationError] if the Hash does not conform to the instruction
    #   format
    def validate_field(field:)
      unless VALID_TYPES.include? field[:type]
        raise ValidationError, "Illegal type defined at key \"#{field[:key]}\": #{field[:type]}. Valid types are #{VALID_TYPES}."
        return false
      end

      if (field[:type] == "bin") && (!VALID_BIN_SIZES.include? (field[:size]))
        raise ValidationError, "Illegal size defined for binary field at key \"#{field[:key]}\": #{field[:size]}. Valid sizes for binary values are #{VALID_BIN_SIZES}."
        return false
      end

      return true
    end

  end


end
