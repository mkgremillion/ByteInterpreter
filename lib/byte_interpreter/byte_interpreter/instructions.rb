#frozen_string_literal: true

class ByteInterpreter

  class Instructions

    class ValidationError < StandardError
    end

    VALID_TYPES = ["bin", "str"]
    VALID_BIN_SIZES = [1, 2, 4, 8]
    FIELD_NAMES = [:key, :type, :size, :signed]

    def initialize
      @data = []
    end

    def each(&block)
      @data.each(&block)
    end

    def clear
      @data.clear
    end

    def add_field(field:)
      @data.push(field.select {|k,v| FIELD_NAMES.include? k})
      validate_field(field: @data.last)
    end

    def load_from_json(filename:)
      json_fields = JSON.parse(File.open(filename, "rt") {|file| file.read}, {:symbolize_names => true})
      json_fields.each do |field|
        add_field(field: field)
      end
    end

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
