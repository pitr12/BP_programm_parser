require 'nokogiri'
require 'faraday'

class Imdb_Parser

    #download main page for specified entry
    def self.download_main_page(id)

      conn = Faraday.new(:url => 'http://www.imdb.com') do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      response = conn.get do |req|
        req.url "/title/#{id}/"
        req.headers['Accept-Language'] = 'en-US,en;q=0.8'
      end

      return response.body
    end

    def self.parse_site_content(site)
      body = Nokogiri::HTML(site)

        title = body.search('.itemprop[itemprop="name"]')
            title = title[0].text if(!title.empty?)

        year = body.search('.nobr') || ""
            year = year[0].text[1..4] if(!year.empty?)

        description = body.search('p[itemprop="description"]')
          description = description[0].text.strip! if(!description.empty?)
          if(description == "Add a Plot")
            description = ""
          end

        rating = body.search('.star-box-giga-star')
          rating = rating[0].text.strip! if(!rating.empty?)

        director = body.search('.txt-block[itemprop="director"]')
          director = director.css('a')[0].text  if(!director.empty?)

        cast = []
        cast_list = body.search('div#titleCast')
        cast_list = cast_list.css('td.itemprop[itemprop="actor"]') if(!cast_list.empty?)
        cast_list.each do |actor|
          cast << actor.text.strip!
        end

        storyline = body.search('div#titleStoryLine')
          if(!storyline.empty?)
            storyline = storyline.css('.inline[itemprop="description"]')
            if(!storyline.empty?)
              storyline = storyline[0].text.strip!
              storyline.gsub!(/Written by\s*\S*/, "").strip!
            end
          end

      genres = []
      genres_list = body.search('div#titleStoryLine')
      if(!genres_list.empty?)
        genres_list = genres_list.css('.inline[itemprop="genre"]')
        genres_list = genres_list.css('a') if(!genres_list.empty?)
        if(!genres_list.empty?)
          genres_list.each do |genre|
            genres << genre.text.strip!
          end
        end
      end

      countries = []
      country = body.search('div#titleDetails')
      if(!country.empty?)
        links = country.css('a[itemprop="url"]')
        if(!links.empty?)
          links.each do |link|
            countries << link.text if link["href"].match(/\/country\//)
          end
        end
      end

        imdb_data = {:title => title, :year => year, :description => description, :rating => rating, :director => director, :cast => cast, :storyline => storyline, :genres => genres, :countries => countries}
        return imdb_data

    end

    def self.print_data(data)
      puts "/////IMDB DATA//////"
      puts "Title: " + data[:title] if(!data[:title].empty?)
      puts "Description: " + data[:description] if(!data[:description].empty?)
      puts "Rating: " + data[:rating] if(!data[:rating].empty?)
      puts "Year: " + data[:year] if(!data[:year].empty?)
      puts "Director: " + data[:director] if(!data[:director].empty?)
      puts "Cast: " + data[:cast].inspect if(!data[:cast].empty?)
      puts "Storyline: " + data[:storyline] if(!data[:storyline].empty?)
      puts "Genres: " + data[:genres].inspect if(!data[:genres].empty?)
      puts "Countries: " + data[:countries].inspect if(!data[:countries].empty?)
    end

  # site = download_main_page("tt1874735")

  #Working Offline
     site = File.read("imdb_HP1.txt")

     imdb_data = parse_site_content(site)
     print_data(imdb_data)
end

