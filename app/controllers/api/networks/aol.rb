class Api::Networks::Aol
  require 'net/https'
  require 'open-uri'

  USERNAME     = "dan.ha@dashbid.com"
  PASSWORD     = "Dashbid123!"

  def initialize(options={})
    @options = options
    connect
  end

  def connect
    response = `curl -X POST -H 'Content-Type: x-www-form-urlencoded' --insecure "#{initialize_url}"`
    pp response
  end

  private

  def initialize_url
    "https://onevideo.aol.com"
  end

  def login_url
    "#{initialize_url}/sessions/login"
  end
end