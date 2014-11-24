require 'nokogiri'
require 'faraday'

CHANNELS_LIST = {
    1 => 'HBO', 2 => 'Nova', 3 => 'Prima', 4 => 'ČT1', 5 => 'ČT2', 6 => 'Markíza', 7 => 'JOJ', 8 => 'HBO2', 9 => 'Jednotka', 10 => 'Dvojka',
    12 => 'AXN', 13 => 'Cinemax', 14 => 'FilmBox', 15 => 'Film+', 16 => 'CSfilm'
}

#Download site for specific Channel and day
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

#Parse basic content from program site
def self.parse_program_content(site)
  body = Nokogiri::HTML(site)
  program = []

  body.search('.box').each do |box|
    #parse start time
    time = box.search('.time').text

    #parse name
    content = box.search('.name')
    name = content.css('a').text
    if(name.empty?)
      name = content.text
    end

    #parse URL
    url = ""
    link = content.css('a')
    if(!link.empty?)
      url = "http://www.csfd.cz" + link[0]["href"].to_s
    end

    #if TV show than parse season and episode number
    series = box.search('.series').text[1..-2]
    season = ""
    episode = ""
    if(!series.nil?)
      season = series.match(/S\d*/).to_s
      episode = series.match(/E\d*/).to_s
    end

    hash = {:time => time, :name => name, :url => url, :season => season, :episode => episode}
    program << hash
  end

  return program
end

#parse item type
def self.parse_item_type(h1)
  type = h1.search('.film-type')
  if(!type.empty?)
    type = type[0].text[1..-2].to_s
  else
    type = "TV film"
  end

  return type
end

#parse item origin (county, year, duration)
def self.parse_item_origin(origin)
  origin = origin.split(',')

  countries = origin[0]
  countries = countries.split('/')
  countries.each do |item|
    item.strip!
  end

  year = ""
  if(origin.size > 1)
    year = origin[1].to_s.strip
  end

  duration = ""
  if(origin.size > 2)
    duration = origin[2].to_s.strip
    duration = duration.match(/\d*/).to_s
  end

  return {:countries => countries, :year => year, :duration => duration}

end

#Parse extended content from item URL
def self.parse_item_content(url)
   # site = Faraday.get(url)
  site = File.read("terminator.txt")
  body = Nokogiri::HTML(site)

  #parse item type
    h1 = body.css('h1')
    type = parse_item_type(h1)


  #parse item genres
    genres = body.css('.genre').text
    genres = genres.split('/')
    genres.each do |item|
     item.strip!
    end

  #parse item origin (county, year, duration)
    origin = body.css('.origin').text
    origin = parse_item_origin(origin)

  #parse item creators (director, scriptwriter, camera, music, actors)
    creators = body.css('.creators')
    # puts creators



  content = {:type => type, :genres => genres, :countries => origin[:countries], :year => origin[:year], :duration => origin[:duration]}

  return content
end

#calling function to download site for set day and channel
  # day = 1 #tomorrow
  # channel = 6 #markiza
  # site = download_site(channel,day);
  site = File.read("site_file.txt")
  # File.open("site_file.txt", 'w') { |file| file.write(site) }

program = parse_program_content(site)

program.each do |item|
  #print item attributes
  puts "Time: " + item[:time].to_s
  puts "Name: " + item[:name].to_s
  puts "URL: " + item[:url].to_s
  puts "Season: " + item[:season].to_s
  puts "Episode: " + item[:episode].to_s
  puts ""

  #find item in Database - if item is not in database parse more content from item URL and save it to DB
    #item is not present in DB
    extend_content = parse_item_content(item[:url].to_s)
    puts "Extended parsing:"
    puts extend_content
  break
end


