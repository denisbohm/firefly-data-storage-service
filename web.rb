require 'sinatra'
require 'json'
require 'binary'
require 'hardware_id'
require 'storage'

FD_SYNC_START = 1
FD_SYNC_DATA = 2
FD_SYNC_ACK = 3

$storage = Storage.new

def self.storage_type(s)
  s.encode(Encoding.find('ASCII-8BIT')).unpack('L<').first
end

FD_LOG_TYPE = storage_type('FDLO')
FD_ACTIVITY_TYPE = storage_type('FDAC')

def sync_log(hardware_id, binary)
  time = binary.get_time
  length = binary.remaining_length
  message = binary.get_bytes(length)

  $storage.sync(hardware_id.to_s, time, {log: {time: time, message: message}})
end

def sync_activity(hardware_id, binary)
  time = binary.get_time32
  interval = binary.get_uint16
  n = binary.remaining_length / 2 # 2 == sizeof(float16)
  values = n.times.collect { binary.get_float16 }

  $storage.sync(hardware_id.to_s, time, {activity: {time: time, interval: interval, values: values}})
end

def sync_data(binary)
  hardware_id = HardwareId.new(binary.get_bytes(16))
  page = binary.get_uint32
  length = binary.get_uint16
  hash = binary.get_uint16
  type = binary.get_uint32

  case type
    when FD_LOG_TYPE
      sync_log(hardware_id, binary)
    when FD_ACTIVITY_TYPE
      sync_activity(hardware_id, binary)
    else
      return "unknown type #{type}"
  end

  content_type 'application\/octet-stream'

  response = Binary.new('')
  response.put_uint8(FD_SYNC_ACK)
  response.put_uint32(page)
  response.put_uint16(length)
  response.put_uint16(hash)
  response.put_uint32(type)
  response.to_bytes
end

post '/sync' do
  binary = Binary.new(request.env['rack.input'].read)
  code = binary.get_uint8
  case code
    when FD_SYNC_DATA
      response = sync_data(binary)
    else
      response = "unexpected code #{code}"
  end
  response
end

post '/echo' do
  json_object = JSON.parse(request.env['rack.input'].read)
  content_type :json
  json_object.to_json
end

get '/' do
  'hello'
end