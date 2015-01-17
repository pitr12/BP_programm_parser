require 'nokogiri'

class Csfd_Parser
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
end