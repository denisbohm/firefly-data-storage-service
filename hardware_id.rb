require_relative 'binary'

class HardwareId

  def initialize(bytes)
    binary = Binary.new(bytes)
    @vendor = binary.get_uint16
    @product = binary.get_uint16
    @version_major = binary.get_uint16
    @version_minor = binary.get_uint16
    @unique_id = binary.get_bytes(8)

    # need a vendor & product registry with fallback to numbers... -denis
    vendor_name = 'Firefly'
    product_name = 'Ice'
    id = @unique_id.unpack('H*').first
    @description = "#{vendor_name} #{product_name} #{@version_major}.#{@version_minor} #{id}"
  end

  def to_s
    @description
  end

end