require_relative '../lib/byteinterpreter.rb'

describe ByteInterpreter do
  let(:ostream) do
    io = StringIO.new("\x90\xA0Byte Test", "r+b")
    #In hex: 90 A0 42 79 74 65 20 54 65 73 74
    io.set_encoding(Encoding::UTF_8)
    io
  end

  context "when endianness is little, " do
    let(:bi) {ByteInterpreter.new(endian: :little, stream: ostream)}

    it "reads an unsigned 8-bit integer" do
      expect(bi.interpret_bytes(size: 1, signed: false)).to eq(144)
    end

    it "reads an unsigned 16-bit integer" do
      expect(bi.interpret_bytes(size: 2, signed: false)).to eq(41_104)
    end

    it "reads an unsigned 32-bit integer" do
      expect(bi.interpret_bytes(size: 4, signed: false)).to eq(2_034_409_616)
    end

    it "reads an unsigned 64-bit integer" do
      expect(bi.interpret_bytes(size: 8, signed: false)).to eq(6_061_956_649_365_708_944)
    end

    it "reads a signed 8-bit integer" do
      expect(bi.interpret_bytes(size: 1, signed: true)).to eq(-112)
    end

    it "reads a signed 16-bit integer" do
      expect(bi.interpret_bytes(size: 2, signed: true)).to eq(-24_432)
    end

    it "reads a signed 32-bit integer" do
      expect(bi.interpret_bytes(size: 4, signed: true)).to eq(2_034_409_616)
    end

    it "reads a signed 64-bit integer" do
      expect(bi.interpret_bytes(size: 8, signed: true)).to eq(6_061_956_649_365_708_944)
    end

    it "writes an unsigned 8-bit integer" do
      bi.encode_bytes(value: 0xA0, size: 1, signed: false)
      expect(ostream.string.byteslice(0)).to eq("\xA0")
    end

    it "writes an unsigned 16-bit integer" do
      bi.encode_bytes(value: 0xA0B4, size: 2, signed: false)
      expect(ostream.string.byteslice(0, 2)).to eq("\xB4\xA0")
    end

    it "writes an unsigned 32-bit integer" do
      bi.encode_bytes(value: 0xA0B462FF, size: 4, signed: false)
      expect(ostream.string.byteslice(0, 4)).to eq("\xFF\x62\xB4\xA0")
    end

    it "writes an unsigned 64-bit integer" do
      bi.encode_bytes(value: 0xA0B462FF8830C0FE, size: 8, signed: false)
      expect(ostream.string.byteslice(0, 8)).to eq("\xFE\xC0\x30\x88\xFF\x62\xB4\xA0")
    end

    it "writes a signed 8-bit integer" do
      bi.encode_bytes(value: -90, size: 1, signed: true)
      expect(ostream.string.byteslice(0)).to eq("\xA6")
    end

    it "writes a signed 16-bit integer" do
      bi.encode_bytes(value: -2_530, size: 2, signed: true)
      expect(ostream.string.byteslice(0,2)).to eq("\x1E\xF6")
    end

    it "writes a signed 32-bit integer" do
      bi.encode_bytes(value: -1_524_396, size: 4, signed: true)
      expect(ostream.string.byteslice(0,4)).to eq("\x54\xBD\xE8\xFF")
    end

    it "writes a signed 64-bit integer" do
      bi.encode_bytes(value: -4_013_984_306, size: 8, signed: true)
      expect(ostream.string.byteslice(0,8)).to eq("\xCE\x75\xBF\x10\xFF\xFF\xFF\xFF")
    end

  end

  context "when endianness is big, " do
    let(:bi) {ByteInterpreter.new(endian: :big, stream: ostream)}

    it "reads an unsigned 8-bit integer" do
      expect(bi.interpret_bytes(size: 1, signed: false)).to eq(144)
    end

    it "reads an unsigned 16-bit integer" do
      expect(bi.interpret_bytes(size: 2, signed: false)).to eq(37_024)
    end

    it "reads an unsigned 32-bit integer" do
      expect(bi.interpret_bytes(size: 4, signed: false)).to eq(2_426_421_881)
    end

    it "reads an unsigned 64-bit integer" do
      expect(bi.interpret_bytes(size: 8, signed: false)).to eq(10_421_402_627_146_588_244)
    end

    it "reads a signed 8-bit integer" do
      expect(bi.interpret_bytes(size: 1, signed: true)).to eq(-112)
    end

    it "reads a signed 16-bit integer" do
      expect(bi.interpret_bytes(size: 2, signed: true)).to eq(-28_512)
    end

    it "reads a signed 32-bit integer" do
      expect(bi.interpret_bytes(size: 4, signed: true)).to eq(-1_868_545_415)
    end

    it "reads a signed 64-bit integer" do
      expect(bi.interpret_bytes(size: 8, signed: true)).to eq(-8_025_341_446_562_963_372)
    end

    it "writes an unsigned 8-bit integer" do
      bi.encode_bytes(value: 200, size: 1, signed: false)
      expect(ostream.string.byteslice(0)).to eq("\xC8")
    end

    it "writes an unsigned 16-bit integer" do
      bi.encode_bytes(value: 1_500, size: 2, signed: false)
      expect(ostream.string.byteslice(0,2)).to eq("\x05\xDC")
    end

    it "writes an unsigned 32-bit integer" do
      bi.encode_bytes(value: 500_000, size: 4, signed: false)
      expect(ostream.string.byteslice(0,4)).to eq("\x00\x07\xA1\x20")
    end

    it "writes an unsigned 64-bit integer" do
      bi.encode_bytes(value: 13_000_000_000_000_000_000, size: 8, signed: false)
      expect(ostream.string.byteslice(0,8)).to eq("\xB4\x69\x47\x1F\x80\x14\x00\x00")
    end

    it "writes a signed 8-bit integer" do
      bi.encode_bytes(value: -56, size: 1, signed: true)
      expect(ostream.string.byteslice(0)).to eq("\xC8")
    end

    it "writes a signed 16-bit integer" do
      bi.encode_bytes(value: -1_500, size: 2, signed: true)
      expect(ostream.string.byteslice(0,2)).to eq("\xFA\x24")
    end

    it "writes a signed 32-bit integer" do
      bi.encode_bytes(value: -500_000, size: 4, signed: true)
      expect(ostream.string.byteslice(0,4)).to eq("\xFF\xF8\x5E\xE0")
    end

    it "writes a signed 64-bit integer" do
      bi.encode_bytes(value: -5_000_000_000_000_000, size: 8, signed: true)
      expect(ostream.string.byteslice(0,8)).to eq("\xFF\xEE\x3C\x86\xC8\x1F\x80\x00")
    end

  end

  it "reads a string of given length (6 bytes)" do
    bi = ByteInterpreter.new(stream: ostream)
    test_string = "Byte T"
    ostream.seek(2)
    expect(bi.interpret_string(size: 6)).to eq(test_string)
  end

  it "writes a string of given length when passed appropriate-length string" do
    bi = ByteInterpreter.new(stream:ostream)
    test_string = "Length"
    bi.encode_string(value: test_string, size: 6)
    expect(ostream.string.byteslice(0,6)).to eq(test_string)
  end

  it "writes a string of given length when passed smaller-length string" do
    bi = ByteInterpreter.new(stream:ostream)
    test_string = "smol"
    bi.encode_string(value: test_string, size: 6)
    expect(ostream.string.byteslice(0,6)).to eq("smol  ")
  end

  it "writes a string of given length when passed larger-length string" do
    bi = ByteInterpreter.new(stream:ostream)
    test_string = "largerstring"
    bi.encode_string(value: test_string, size: 6)
    expect(ostream.string.byteslice(0,6)).to eq("larger")
    expect(ostream.string.byteslice(0,12)).not_to eq("largerstring")
  end

end
