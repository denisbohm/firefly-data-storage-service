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

  def span_times(s)
    time = s['time']
    {time: time , end: time + s['values'].count * s['interval']}
  end

  def spans_overlap?(a, b)
    at = span_times(a)
    bt = span_times(b)
    (at[:time] <= bt[:end]) && (at[:end] >= bt[:time])
  end

  def merge_two_spans(a, b)
    av = a['values']
    ai = a['interval']
    ae = a['time'] + av.count * ai
    bt = b['time']
    i = (ae - bt) / ai
    bv = b['values']
    values = bv[i .. bv.count]
    av.concat(values) if values
  end

  def merge_all_spans(spans)
    spans = spans.sort {|a, b|
      a['time'] <=> b['time']
    }
    index = 0
    while index < spans.count - 1
      a = spans[index]
      b = spans[index + 1]
      if spans_overlap?(a, b)
        merge_two_spans(a, b)
        spans.delete_at(index + 1)
      else
        index += 1
      end
    end
    spans
  end

  def query(type, span)
    result = []
    db = get_connection()
    db.collection('syncs').find({type => {'$exists' => true}}, fields: {type => 1}).each {|document|
      result.concat(document[type])
    }
    {type => merge_all_spans(result)}
  end

end