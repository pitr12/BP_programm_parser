require 'nokogiri'
require 'faraday'

def self.parse_program(channel, day)

  conn = Faraday.new(:url => 'http://www.csfd.cz') do |faraday|
    faraday.request  :url_encoded
    faraday.response :logger
    faraday.adapter  Faraday.default_adapter
  end

  response = conn.get "/televize?day=#{day}"
  cookie = response.headers['set-cookie']
  cookie.gsub!(/tv_stations=[^;]*/,"tv_stations=#{channel}")

  response2 = conn.post do |req|
    req.url "/televize?day=#{day}"
    req.headers['Cookie'] = cookie
  end

  npage = Nokogiri::HTML(response2.body)
  puts npage

end

#calling function to parse program for set day and channel
day = 1 #tomorrow
channel = 6 #markiza
parse_program(channel,day);

