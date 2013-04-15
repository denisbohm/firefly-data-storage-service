require 'float-formats'

class Binary

  def initialize(data=''.encode(Encoding.find('BINARY')))
    @data = data
    @get_index = 0
  end

  def to_bytes
    @data
  end

  def remaining_length
    @data.bytesize - @get_index
  end

  def get_bytes(length)
    value = @data.byteslice(@get_index, length)
    @get_index += length
    value
  end

  def get_unpack(format, length)
    value = @data.byteslice(@get_index, length).unpack(format).first
    @get_index += length
    value
  end

  def get_uint8
    get_unpack('C', 1)
  end

  def get_uint16
    get_unpack('S<', 2)
  end

  def get_uint32
    get_unpack('L<', 4)
  end

  def get_uint64
    get_unpack('Q<', 8)
  end

  def get_float16
    Flt::IEEE_HALF.from_bytes(get_bytes(2)).convert_to(Float)
  end

  def get_float32
    get_unpack('e', 4)
  end

  def get_float64
    get_unpack('E', 8)
  end

  def get_time32
    Time.at(get_uint32).getutc()
  end

  def get_time
    seconds = get_uint32
    microseconds = get_uint32
    Time.at(seconds, microseconds).getutc()
  end

  def put_bytes(bytes)
    @data.concat(bytes)
  end

  def put_pack(value, format)
    @data.concat([value].pack(format))
  end

  def put_uint8(value)
    put_pack(value, 'C')
  end

  def put_uint16(value)
    put_pack(value, 'S<')
  end

  def put_uint32(value)
    put_pack(value, 'L<')
  end

  def put_uint64(value)
    put_pack(value, 'Q<')
  end

  def put_float16(value)
    put_bytes(Flt::IEEE_HALF.from_number(value).to_bytes)
  end

  def put_float32(value)
    put_pack(value, 'e')
  end

  def put_float64(value)
    put_pack(value, 'E')
  end

  def put_time32(value)
    put_uint32(value.to_i)
  end

  def put_time(value)
    put_uint32(value.to_i)
    put_uint32(value.usec)
  end

end