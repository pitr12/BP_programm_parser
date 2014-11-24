require 'nokogiri'
require 'faraday'

CHANNELS_LIST = {
    1 => 'HBO', 2 => 'Nova', 3 => 'Prima', 4 => 'ČT1', 5 => 'ČT2', 6 => 'Markíza', 7 => 'JOJ', 8 => 'HBO2', 9 => 'Jednotka', 10 => 'Dvojka',
    12 => 'AXN', 13 => 'Cinemax', 14 => 'FilmBox', 15 => 'Film+', 16 => 'CSfilm'
}

def self.download_site(channel, day)

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

  return response2.body
end

def self.parse_content(site)
  body = Nokogiri::HTML(site)

  body.search('.box').each do |box|
    time = box.search('.time')
    puts "Time: " + time.text

    content = box.search('.name')
    name = content.css('a').text
    # link = content.css('a')
    # puts link[0]["href"]

    if(name.empty?)
      name = content.text
    end

    puts name
    # puts link
    puts ""
  end


end

#calling function to download site for set day and channel
  # day = 1 #tomorrow
  # channel = 6 #markiza
  # site = download_site(channel,day);
  # File.open("site_file.txt", 'w') { |file| file.write(site) }

site = File.read("site_file.txt")


parse_content(site)


