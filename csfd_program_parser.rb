require 'nokogiri'
require 'faraday'

#list of channels to be parsed
PARSE_LIST = ['Markíza', 'HBO']

#specify day for which should be program parsed (0 today, 1 tomorrow ....)
DAY = 1

#list of all available channels
CHANNELS_LIST = {
    'HBO' => 1, 'Nova' => 2, 'Prima' => 3, 'ČT1' => 4, 'ČT2' => 5, 'Markíza' => 6, 'JOJ' => 7, 'HBO2' => 8, 'Jednotka' => 9, 'Dvojka' => 10,
    'AXN' => 12, 'Cinemax' => 13, 'FilmBox' => 14, 'Film+' => 15, 'CSfilm' => 16, 'MGM' => 17, 'HBO Comedy' => 18, 'Nova Cinema' => 19, 'FilmBox Plus' => 20,
    'FilmBox HD' => 21, 'Cinemax2' => 22, 'Barrandov' => 24, 'Plus' => 25, 'Prima Cool' => 26, 'Doma' => 27, 'Universal Channel' => 28, 'Disney Channel' => 30,
    'Kino CS' => 31, 'Doku CS' => 32, 'Prima Love' => 33, 'Minimax' => 34, 'Discovery Channel' => 37, 'History Channel' => 38, 'Spektrum' => 39, 'Animal Planet' => 40,
    'Filmbox Family' => 41, 'Viasat Nature' => 42, 'Viasat Explorer' => 43, 'Viasat History' => 44, 'Viasat HD' => 45, 'Film Europe Channel' => 46, 'Fanda' => 48,
    'Discovery Science' => 50, 'Discovery World' => 51, 'JimJam' => 52, 'Spektrum Home' => 53, 'Dajto' => 54, 'National Geographic' => 55, 'National Geographic Wild' => 56,
    'CBS Drama' => 57, 'Smíchov' =>58, 'Prima ZOOM' => 60, 'Telka' => 61, 'Wau' => 63, 'ČT :D' => 64, 'ČT art' => 65, 'AXN Black' => 66, 'AXN White' => 67,
    'Megamax' => 68, 'CBS Reality' => 69, 'Horor Film' => 70, 'National Geographic HD' => 71, 'Travel Channel' => 72, 'Nickelodeon' => 73, 'MTV CZ' => 74,
    'Filmbox Extra' => 75, 'Kino Svět' => 76, 'ID Xtra' => 77, 'AMC' => 78
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

  countries = origin[0].split('/')
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
  end

  return {:countries => countries, :year => year, :duration => duration}

end

#parse item creators (director, scriptwriter, camera, music, actors)
def self.parse_item_creators(creators)
  directors = []
  scriptwriters = []
  camera = []
  music = []
  actors = []
  artwork = []

  divs = creators.css('div')

  divs[1..-1].each do |div|
    type = div.css('h4').text.to_s
    links = div.css('a')

    links.each do |link|
      case type
        when 'Režie:'
          directors << link.text
        when 'Scénář:'
          scriptwriters << link.text
        when 'Kamera:'
          camera << link.text
        when 'Hudba:'
          music << link.text
        when 'Hrají:'
          actors << link.text
        when 'Předloha:'
          artwork << link.text
      end
    end
  end

  return {:directors => directors, :scriptwriters => scriptwriters, :camera => camera, :music => music, :actors => actors, :artwork => artwork}
end

#parse original title
def self.parse_item_original_title(names_li)
  original_title = ""
  if(!names_li.empty?)
    names_li.each do |li|
      original_title = li.css('h3').text
      break;
    end
  end
  return original_title
end

#parse item description
def self.parse_item_description(desc)
  description = desc.css('div.content').css('div')[1].text.strip!
  return description
end

#Parse extended content from item URL
def self.parse_item_content(url)
  site = Faraday.get(url)
  # site = File.read("noviny.txt")
  body = Nokogiri::HTML(site.body)

  #parse item type
    type = parse_item_type(body.css('h1'))


  #parse item genres
    genres = body.css('.genre').text.split('/')
    genres.each do |item|
     item.strip!
    end

  #parse item origin (county, year, duration)
    origin = parse_item_origin(body.css('.origin').text)

  #parse item creators (director, scriptwriter, camera, music, actors)
    creators = parse_item_creators(body.css('.creators'))

  #parse item rating
    rating = body.css('h2.average').text
    rating.gsub!(/[^\d]/,'')

  #parse IMDB url
    imdb_url = body.css('a[title="profil na IMDb.com"]')
    if(!imdb_url.empty?)
      imdb_url = imdb_url[0]["href"].to_s
    end

  #parse original title
    original_title = parse_item_original_title(body.css('ul.names li'))

   #parse item description
    description = parse_item_description(body.css('div#plots'))

  content = {:type => type, :genres => genres, :countries => origin[:countries], :year => origin[:year], :duration => origin[:duration], :directors => creators[:directors],
             :scriptwriters => creators[:scriptwriters], :camera => creators[:camera], :music => creators[:music], :actors => creators[:actors], :artwork => creators[:artwork],
             :csfd_rating => rating, :imdb_url => imdb_url, :original_title => original_title, :description => description}

  return content
end

def self.print_extended_content(content)
  puts "Type: " + content[:type].to_s
  puts "Genres: " + content[:genres].to_s
  puts "Countries: " + content[:countries].to_s
  puts "Year: " + content[:year].to_s
  puts "Duration: " + content[:duration].to_s
  puts "Directors: " + content[:directors].to_s
  puts "Scriptwriters: " + content[:scriptwriters].to_s
  puts "Camera: " + content[:camera].to_s
  puts "Music: " + content[:music].to_s
  puts "Actors: " + content[:actors].to_s
  puts "Artwork: " + content[:artwork].to_s
  puts "CSFD rating: " + content[:csfd_rating].to_s
  puts "IMDB url: " + content[:imdb_url].to_s
  puts "Original title: " + content[:original_title].to_s
  puts "Description: " + content[:description].to_s
  puts "\n\n\n\n\n"
end


PARSE_LIST.each do |channel|
  #calling function to download site for set day and channel
    site = download_site(CHANNELS_LIST[channel],DAY);
    # site = File.read("site_file.txt")
    # File.open("site_file.txt", 'w') { |file| file.write(site) }

  #parse program for specific channel and day
  program = parse_program_content(site)

  puts "\n\n\n\n\n"
  puts "///////////// CHANNEL: #{channel} //////////////////"

  program.each do |item|
    #print item attributes
    puts "Time: " + item[:time].to_s
    puts "Name: " + item[:name].to_s
    puts "URL: " + item[:url].to_s
    puts "Season: " + item[:season].to_s
    puts "Episode: " + item[:episode].to_s
    puts "\n"

    #find item in Database - if item is not in database parse more content from item URL and save it to DB
      #item is not present in DB
      extend_content = {}
      if(!item[:url].to_s.empty?)
        extend_content = parse_item_content(item[:url].to_s)
      end

      print_extended_content(extend_content)

       break
  end
end


