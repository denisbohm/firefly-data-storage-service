require 'mongo'
require 'uri'

class Storage

  def get_connection
    return @db_connection if @db_connection
    db = URI.parse(ENV['MONGOHQ_URL'])
    db_name = db.path.gsub(/^\//, '')
    @db_connection = Mongo::Connection.new(db.host, db.port).db(db_name)
    @db_connection.authenticate(db.user, db.password) unless (db.user.nil? || db.password.nil?)
    @db_connection
  end

  def get_day(time)
    utc_time = time.getutc()
    Time::utc(utc_time.year, utc_time.month, utc_time.day)
  end

  def get_sync_document_id(device_hardware_id, day)
    device_hardware_id + ' ' + day.strftime('%Y-%m-%d')
  end

  def sync(device_hardware_id, time, type, data)
    day = get_day(time)
    id = get_sync_document_id(device_hardware_id, day)
    document = {
        _id: id,
        hwid: device_hardware_id,
        day: day
    }
    operation = {
        '$push' => {type => data}
    }
    db = get_connection()
    db.collection('syncs').update(document, operation, {upsert: true})
  end

  def query(type, span)
    db = get_connection()
    db.collection('syncs').find({type => {"$exists" => true}}, fields: {type => 1}).to_a
  end

end