require_relative "../test_helper"

describe Committee::Middleware::ResponseValidation do
  include Rack::Test::Methods

  def app
    @app
  end

  it "passes through a valid response" do
    @app = new_rack_app(MultiJson.encode(ValidApp))
    get "/apps"
    assert_equal 200, last_response.status
  end

  it "detects an invalid response Content-Type" do
    @app = new_rack_app(MultiJson.encode(ValidApp), {})
    get "/apps"
    assert_equal 500, last_response.status
    assert_match /response header must be set to/i, last_response.body
  end

  it "detects an invalid response" do
    @app = new_rack_app("")
    get "/apps"
    assert_equal 500, last_response.status
    assert_match /valid JSON/i, last_response.body
  end

  it "detects missing keys in response" do
    data = ValidApp.dup
    data.delete("name")
    @app = new_rack_app(MultiJson.encode(data))
    get "/apps"
    assert_equal 500, last_response.status
    assert_match /missing keys/i, last_response.body
  end

  it "detects extra keys in response" do
    data = ValidApp.dup
    data.merge!("tier" => "important")
    @app = new_rack_app(MultiJson.encode(data))
    get "/apps"
    assert_equal 500, last_response.status
    assert_match /extra keys/i, last_response.body
  end

  it "rescues JSON errors" do
    @app = new_rack_app("{x:y}")
    get "/apps"
    assert_equal 500, last_response.status
    assert_match /valid json/i, last_response.body
  end

  def new_rack_app(response, headers={ "Content-Type" => "application/json" })
    Rack::Builder.new {
      use Committee::Middleware::ResponseValidation,
        schema: File.read("./test/data/schema.json")
      run lambda { |_|
        [200, headers, [response]]
      }
    }
  end
end
