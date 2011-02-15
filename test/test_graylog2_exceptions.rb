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
    c = Graylog2Exceptions.new(nil, {:host => "localhost", :port => 1337, :local_app_name => "yomama", :level => 1})
    
    assert_equal "yomama", c.args[:local_app_name]
    assert_equal "localhost", c.args[:hostname]
    assert_equal 1337, c.args[:port]
    assert_equal 1, c.args[:level]
  end
  
  def test_correct_parameters_when_not_custom_set
    c = Graylog2Exceptions.new(nil, {})
    
    assert_equal Socket.gethostname, c.args[:local_app_name]
    assert_equal "localhost", c.args[:hostname]
    assert_equal 12201, c.args[:port]
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
