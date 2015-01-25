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

    def self.parse_story_line(storyline)
      storyline = storyline.css('.inline[itemprop="description"]')
      if(!storyline.empty?)
        storyline = storyline[0].text.strip!
        storyline.gsub!(/Written by\s*\S*/, "").strip!
      end
      return storyline
    end

    def self.parse_genres(genres_list)
      genres = []
      genres_list = genres_list.css('.inline[itemprop="genre"]')
      genres_list = genres_list.css('a') if(!genres_list.empty?)
      if(!genres_list.empty?)
        genres_list.each do |genre|
          genres << genre.text.strip!
        end
      end
      return genres
    end

    def self.parse_cast(body)
      cast = []
      cast_list = body.search('div#titleCast')
      cast_list = cast_list.css('td.itemprop[itemprop="actor"]') if(!cast_list.empty?)
      cast_list.each do |actor|
        cast << actor.text.strip!
      end
      return cast
    end

    def self.parse_countries(country)
      countries = []
      links = country.css('a[itemprop="url"]')
      if(!links.empty?)
        links.each do |link|
          countries << link.text if link["href"].match(/\/country\//)
        end
      end
      return countries
    end

    def self.parse_runtime(runtime)
      runtime = runtime.css('time[itemprop="duration"]')
      if(!runtime.empty?)
        runtime = runtime[0].text
        runtime.gsub!(/\D/, "").strip!
      end
      return runtime
    end

    def self.parse_site_content(site)
      body = Nokogiri::HTML(site)

      #parse title
        title = body.search('.itemprop[itemprop="name"]')
            title = title[0].text if(!title.empty?)

      #parse production year
        year = body.search('.nobr') || ""
            year = year[0].text[1..4] if(!year.empty?)

      #parse description
        description = body.search('p[itemprop="description"]')
          description = description[0].text.strip! if(!description.empty?)
          if(description == "Add a Plot")
            description = ""
          end

      #parse rating
        rating = body.search('.star-box-giga-star')
          rating = rating[0].text.strip! if(!rating.empty?)

      #parse director
        director = body.search('.txt-block[itemprop="director"]')
          director = director.css('a')[0].text  if(!director.empty?)

      #parse cast
        cast = parse_cast(body)

      #parse StoryLine and Genres
      storyline = ""
      genres = []
        titleStoryLine = body.search('div#titleStoryLine')
        if(!titleStoryLine.empty?)
          storyline = parse_story_line(titleStoryLine)
          genres = parse_genres(titleStoryLine)
        end

      #parse countries of origin and runtime
      countries = []
      runtime = ""
      titleDetails = body.search('div#titleDetails')
      if(!titleDetails.empty?)
        countries = parse_countries(titleDetails)
        runtime = parse_runtime(titleDetails)
      end

      imdb_data = {:title => title, :year => year, :description => description, :rating => rating, :director => director, :cast => cast, :storyline => storyline,
                     :genres => genres, :countries => countries, :runtime => runtime}

      return imdb_data

    end

    def self.print_data(data)
      puts "\n/////IMDB DATA//////"
      puts "Title: " + data[:title] if(!data[:title].empty?)
      puts "Description: " + data[:description] if(!data[:description].empty?)
      puts "Rating: " + data[:rating] if(!data[:rating].empty?)
      puts "Year: " + data[:year] if(!data[:year].empty?)
      puts "Director: " + data[:director] if(!data[:director].empty?)
      puts "Cast: " + data[:cast].inspect if(!data[:cast].empty?)
      puts "Storyline: " + data[:storyline] if(!data[:storyline].empty?)
      puts "Genres: " + data[:genres].inspect if(!data[:genres].empty?)
      puts "Countries: " + data[:countries].inspect if(!data[:countries].empty?)
      puts "Runtime: " + data[:runtime] if(!data[:runtime].empty?)
      puts "\n\n"
    end

  # site = download_main_page("tt1874735")

  #Working Offline
      site = File.read("imdb_HP1.txt")
     #
      imdb_data = parse_site_content(site)
      print_data(imdb_data)
end

