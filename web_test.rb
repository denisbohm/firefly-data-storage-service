require 'web'
require 'test/unit'
require 'rack/test'

set :environment, :test

class MockStorage
  include Test::Unit::Assertions

  def initialize
    @calls = []
  end

  def sync(device_hardware_id, time, sync)
    assert_equal 'Firefly Ice 3.4 0102030405060708', device_hardware_id
    exp_time = Time.parse('2013-04-14 19:55:00.001000000 UTC', '%Y-%m-%d %H:%M:%S.%9N %Z')
    exp_time
    assert_equal exp_time, time
    exp_sync = {:log=>{:time=>exp_time, :message=>'az'}}
    assert_equal exp_sync, sync
    @calls << 'sync'
  end

  def verify
    assert_equal @calls.count, 1
  end

end

class WebTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index_returns_hello
    get '/'

    assert last_response.ok?
    assert_equal 'hello', last_response.body
  end

  def ascii_to_hex(*s)
    [s.join].pack('H*')
  end

  def test_sync_log
    request = ascii_to_hex(
      '02', # command code (FD_SYNC_DATA)\
      '0100', # hardware id - vendor (1)
      '0200', # hardware id - product (2)
      '0300', # hardware id - version - major (3)
      '0400', # hardware id - version - minor (4)
      '0102030405060708', # hardware id - unique id
      '01000000', # page
      '0a00', # length (10)
      '5aa5', # hash
      '46444c4f', # type - FDLO
      '94096b51', # time - seconds (2013-04-14 19:55:00)
      'e8030000', # time - milliseconds (1000)
      '617a' # message (az)
    )

    response = ascii_to_hex(
      '03', # command code (FD_SYNC_ACK)
      '01000000', # page
      '0a00', # length (10)
      '5aa5', # hash
      '46444c4f' # type - FDLO
    )

    $storage = MockStorage.new
    post '/sync', request, 'CONTENT_TYPE' => 'application\/octet-stream'

    assert last_response.ok?
    assert_equal response, last_response.body
  end

end
