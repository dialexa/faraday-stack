require 'test_helper'
require 'forwardable'

class CachingTest < Test::Unit::TestCase
  class TestCache < Hash
    def read(key)
      if cached = self[key]
        Marshal.load(cached)
      end
    end
    
    def write(key, data)
      self[key] = Marshal.dump(data)
    end
    
    def fetch(key)
      read(key) || yield.tap { |data| write(key, data) }
    end
  end
  
  def setup
    @cache = TestCache.new
    
    request_count = 0
    response = lambda { |env|
      [200, {'Content-Type' => 'text/plain'}, "request:#{request_count+=1}"]
    }
    
    @conn = Faraday.new do |b|
      b.use FaradayStack::Caching, @cache
      b.adapter :test do |stub|
        stub.get('/', &response)
        stub.get('/?foo=bar', &response)
        stub.post('/', &response)
        stub.get('/other', &response)
      end
    end
  end

  extend Forwardable
  def_delegators :@conn, :get, :post
  
  def test_cache_get
    assert_equal 'request:1', get('/').body
    assert_equal 'request:1', get('/').body
    assert_equal 'request:2', get('/other').body
    assert_equal 'request:2', get('/other').body
  end
  
  def test_response_has_request_params
    get('/') # make cache
    response = get('/')
    assert_equal :get, response.env[:method]
    assert_equal '/', response.env[:url].to_s
  end
  
  def test_cache_query_params
    assert_equal 'request:1', get('/').body
    assert_equal 'request:2', get('/?foo=bar').body
    assert_equal 'request:2', get('/?foo=bar').body
    assert_equal 'request:1', get('/').body
  end
  
  def test_doesnt_cache_post
    assert_equal 'request:1', post('/').body
    assert_equal 'request:2', post('/').body
    assert_equal 'request:3', post('/').body
  end
end
