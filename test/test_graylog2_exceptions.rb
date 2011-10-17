require 'helper'
require 'logger'

class TestGraylog2Exceptions < Test::Unit::TestCase

  # Exceptions raised in the app should be thrown back
  # to the app after handling. Simulating this by giving
  # a nil app and expecting the caused exceptions.
  def test_should_rethrow_exception
    c = Graylog2Exceptions.new(nil, {})
    assert_raise NoMethodError do
      c.call nil
    end
  end

  def test_correct_parameters_when_custom_set
    c = Graylog2Exceptions.new(nil, {:host => "localhost", :port => 1337, :max_chunk_size => 'WAN', :local_app_name => "yomama", :level => 1})
    
    assert_equal "yomama", c.args[:local_app_name]
    assert_equal "localhost", c.args[:hostname]
    assert_equal 1337, c.args[:port]
    assert_equal 'WAN', c.args[:max_chunk_size]
    assert_equal 1, c.args[:level]
  end
  
  def test_correct_parameters_when_not_custom_set
    c = Graylog2Exceptions.new(nil, {})
    
    assert_equal Socket.gethostname, c.args[:local_app_name]
    assert_equal "localhost", c.args[:hostname]
    assert_equal 12201, c.args[:port]
    assert_equal 'LAN', c.args[:max_chunk_size]
    assert_equal 3, c.args[:level]
  end

  def test_send_exception_to_graylog2_without_custom_parameters
    ex = build_exception
    c = Graylog2Exceptions.new(nil, {})
    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex).join)
    json = JSON.parse(sent)

    assert json["short_message"].include?('undefined method `klopfer!')
    assert json["full_message"].include?('in `build_exception')
    assert_equal 'gelf_exceptions', json["facility"]
    assert_equal 4, json["level"]
    assert_equal Socket.gethostname, json["host"]
    assert_equal ex.backtrace[0].split(":")[1], json["line"]
    assert_equal ex.backtrace[0].split(":")[0], json["file"]
  end
  
  def test_send_exception_to_graylog2_with_custom_parameters
    ex = build_exception

    c = Graylog2Exceptions.new(nil, {:local_app_name => "machinexx", :level => 4, :facility => 'myfacility'})
    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex).join)
    json = JSON.parse(sent)

    assert json["short_message"].include?('undefined method `klopfer!')
    assert json["full_message"].include?('in `build_exception')
    assert_equal 'myfacility', json["facility"]
    assert_equal 3, json["level"]
    assert_equal "machinexx", json["host"]
    assert_equal ex.backtrace[0].split(":")[1], json["line"]
    assert_equal ex.backtrace[0].split(":")[0], json["file"]
  end

  def test_send_backtraceless_exception_to_graylog2
    ex = Exception.new("bad")
    c = Graylog2Exceptions.new(nil, {})
    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex).join)
    json = JSON.parse(sent)

    assert json["short_message"].include?('bad')
    assert json["full_message"].nil?
  end

  def test_send_rack_environment_to_graylog2
    ex = build_exception
    c = Graylog2Exceptions.new(nil, {})

    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex).join)
    json = JSON.parse(sent)
    assert_nil json["_environment"]

    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex, {}).join)
    json = JSON.parse(sent)
    assert_nil json["_environment"]

    sent = Zlib::Inflate.inflate(c.send_to_graylog2(ex, {"foo" => "bar"}).join)
    json = JSON.parse(sent)
    assert_equal({"foo"=>"bar"}, json["_environment"])
  end

  def test_clean_val
    c = Graylog2Exceptions.new(nil, {})
    assert_equal "", c.clean_val(nil)
    assert_equal "foo", c.clean_val("foo")
    assert_equal ["a", "2"], c.clean_val(["a", 2])

    o = Object.new
    def o.to_s; "obj"; end
    assert_equal "obj", c.clean_val(o)

    o = Object.new
    def o.to_s; raise "bad"; end
    assert_equal "Bad value: bad", c.clean_val(o)
  end

  def test_clean_hash
    c = Graylog2Exceptions.new(nil, {})
    assert_equal({}, c.clean_val({}))
    assert_equal({"foo" => "1", "bar" => "2"}, c.clean_val({:foo => 1, "bar" => 2}))
  end

  def test_invalid_port_detection
    ex = build_exception

    c = Graylog2Exceptions.new(nil, {:port => 0})

    # send_to_graylog2 returns nil when nothing was sent
    # the test is fine when the message is just not sent
    # and there are no exceptions. the method informs
    # the user via puts
    assert_nil c.send_to_graylog2(ex)
  end

  private

  # Returns a self-caused exception we can send.
  def build_exception
    begin
      klopfer!
    rescue => e
      return e
    end
  end

end
