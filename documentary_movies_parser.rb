require_relative File.dirname(__FILE__) + '/csfd_downloader.rb'
require_relative File.dirname(__FILE__) + '/alchemy.rb'
require 'json'

class DocumentaryMoviesParser

  @debug = 1 #enable debug
  @csfd_program_parser = 0 #enable parsing of CSFD urls
  @imdb_filter = 0 #enable filterng of items
  @imdb_parser = 0 #enable IMDB parsing
  @alchemy = 0 #enable AlchemyAPI keyword extraction
  @hist = 0 #enable histogram creation
  @csfd_parser = 0 #parse all csfd documentary movies
  @csfd_filter = 1 #filter links containing csfd description

#specify day for which should be program parsed (0 today, 1 tomorrow ....)
  DAYS = [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17]

#list of all available channels to be downloaded
  PARSE_LIST = ['HBO','Nova','Prima','ČT1','ČT2','Markíza','JOJ','HBO2','Jednotka','Dvojka','AXN','Cinemax','FilmBox','Film+','CSfilm','MGM','HBO Comedy','Nova Cinema',
                'FilmBox Plus','FilmBox HD','Cinemax2','Barrandov','Plus','Prima Cool','Doma','Universal Channel','Disney Channel','Kino CS','Doku CS','Prima Love',
                'Minimax','Discovery Channel','History Channel','Spektrum','Animal Planet','Filmbox Family','Viasat Nature','Viasat Explorer','Viasat History','Viasat HD',
                'Film Europe Channel','Fanda','Discovery Science','Discovery World','JimJam','Spektrum Home','Dajto','National Geographic','National Geographic Wild',
                'CBS Drama','Smíchov','Prima ZOOM','Telka','Wau','ČT :D','ČT art','AXN Black','AXN White','Megamax','CBS Reality','Horor Film','National Geographic HD',
                'Travel Channel','Nickelodeon','MTV CZ','Filmbox Extra','Kino Svět','ID Xtra','AMC']

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

  def self.parse_program_content(site)
    body = Nokogiri::HTML(site)
    program = []

    body.search('.box').each do |box|
      #parse URL
      url = ""
      link = box.css('.name a')
      if !link.empty?
        url = "http://www.csfd.cz" + link[0]["href"].to_s
      end

      #parse genres
      genres = box.css('div.genres').text

      if(genres.include? "Dokumentární")
        program << url
      end
    end

    program = program.uniq
    puts program if @debug == 1
    return program
  end

  #parse IMDB link if present
  def self.parse_imd_link(url)
    puts "GET " + url.to_s if @debug == 1
    response = Faraday.get(url)

    site = Nokogiri::HTML(response.body)

    imdb_url = site.css('a[title="profil na IMDb.com"]')
    if !imdb_url.empty?
      imdb_url = imdb_url[0]["href"].to_s
    end

    return imdb_url
  end

  def self.parse_story_line(storyline)
    storyline = storyline.css('.inline[itemprop="description"]')
    if !storyline.empty?
      storyline = storyline[0].text.strip!
      storyline.gsub!(/Written by\s*\S*/, '')
    end
    return storyline
  end


  def self.parse_imdb_content_from_url(url)
    response = Faraday.get(url)

    body = Nokogiri::HTML(response.body)

    #parse title
    title = body.search('.itemprop[itemprop="name"]')
    title = title[0].text if(!title.empty?)

    #parse StoryLine and Genres
    storyline = ""
    titlestoryline = body.search('div#titleStoryLine')
    if !titlestoryline.empty?
      storyline = parse_story_line(titlestoryline)
    end


    item = {:title => title, :desc => storyline, :url => url}

    if storyline.empty?
      return nil
    else
      puts "Storyline"
      return item
    end

  end

  def self.parse_csfd_links
    global_list = []
    DAYS.each do |day|
      puts "///////////////////////////////// DAY: " + day.to_s + " ////////////////////////////////"
      PARSE_LIST.each do |channel|
        puts "/////// Channel: " + channel
        site = Csfd_Downloader.download_site(CHANNELS_LIST[channel],day)
        global_list.concat parse_program_content(site)
        puts "\n"

        sleep(2)
      end
      sleep(5)
    end

    File.open('documentary_movies_list.txt', 'a') do |file|
      file.puts(global_list.uniq)
    end
  end

  def self.filter_imdb_links
    imdb_list = []
    File.readlines('documentary_movies_list.txt').each do |line|
      imdb_url = parse_imd_link(line)

      if !imdb_url.nil?
        imdb_list << imdb_url
      end
    end

    File.open('documentary_movies_imdb_list.txt', 'a') do |file|
      file.puts(imdb_list.uniq)
    end
  end

  def self.parse_imdb_content
    full_list = []

    File.readlines('documentary_movies_imdb_list.txt').each_with_index do |line,index|
      puts index.to_s + " GET " + line.to_s if @debug == 1
      item = parse_imdb_content_from_url(line)

      if !item.nil?
        full_list << item
      end
    end

    File.open("imdb_content.json",'w') do |file|
      file.write(full_list.to_json)
    end
  end

  def self.extract_keywords
    file = File.read('imdb_content.json')
    data = JSON.parse(file)
    output = []

    data.each do |item|
      puts "Processing: " + item["title"] if @debug == 1
      keywords = Alchemy.extract_keywords(item["desc"])
      new_item = {:title => item["title"], :desc => item["desc"], :url => item["url"], :keywords => keywords}
      output << new_item
    end

    File.open("output.json",'w') do |file|
      file.write(output.to_json)
    end
  end

  def self.create_histogram
    data = JSON.parse(File.read('final_output.json'))
    hist = []
    30.times do
     hist << 0
    end

    # data.each do |item|
    #   item["category"].each do |category|
    #     category = category.to_i
    #     category -=1
    #     hist[category.to_i] += 1
    #   end
    # end

    #consider only first category
    data.each do |item|
      category = item["category"].first.to_i
      category -=1
      hist[category.to_i] += 1
    end

    puts hist
  end

  def self.parse_csfd_all
    # (2..10).each do |num|
      response = Faraday.get("http://www.csfd.cz/podrobne-vyhledavani/?type%5B0%5D=0&type%5B1%5D=1&type%5B2%5D=2&type%5B3%5D=3&type%5B4%5D=4&type%5B5%5D=5&type%5B6%5D=6&type%5B7%5D=7&type%5B8%5D=8&type%5B9%5D=9&genre%5Btype%5D=2&genre%5Binclude%5D%5B0%5D=13&genre%5Binclude%5D%5B1%5D=&genre%5Bexclude%5D%5B0%5D=&origin%5Btype%5D=3&origin%5Binclude%5D%5B0%5D=&origin%5Bexclude%5D%5B0%5D=&year_from=2015&year_to=2020&rating_from=&rating_to=&actor=&director=&composer=&screenwriter=&author=&cinematographer=&tag=&ok=Hledat&_form_=film")
      site = Nokogiri::HTML(response.body)

      arr = []
      site.css('table.striped.films tbody tr td.name a').each do |a|
        link = "http://www.csfd.cz" + a["href"]
        arr << link
      end

      File.open('all_csfd_documents','a') do |file|
        file.puts(arr)
      end
    # end
  end

  def self.parse_csfd_descripton_and_imd_link(url)
    puts "GET " +url.to_s
    response = Faraday.get(url)
    site = Nokogiri::HTML(response.body)
    # site = Nokogiri::HTML(File.open('./downloaded_pages/csfd_prijezd.txt'))

    title=""
    title_h1 = site.css('div#main div.content div.info h1')
    if !title_h1.empty?
      title = title_h1.text.strip
    end

    desc = ""
    desc_div = site.css('div#main div.content ul li div')
    if !desc_div.empty?
      desc_div = desc_div.first
      desc = desc_div.text.strip
      desc = desc.gsub(/(\(.*\))/,"")
    end

    imdb_url = ""
    imdb_a = site.css('div#sidebar div#share ul.links li a[title="profil na IMDb.com"]')
    if !imdb_a.empty?
      imdb_url = imdb_a.first["href"]
    end

    item = {:csfd_title => title, :csfd_desc=> desc, :csfd_url => url, :imdb_url => imdb_url}
    return item
  end

  def self.filter_csfd_links
    arr = []
    File.readlines('all_csfd_documents_processed').each do |line|
      arr << line
    end

    if arr.size == 0
      exit 1
    end

    url = arr.first
    item = parse_csfd_descripton_and_imd_link(url)

    final_output = []
    if !File.zero?('all_documents_csfd_output.json')
      file2 = File.read('all_documents_csfd_output.json')
      final_output = JSON.parse(file2)
    end
    final_output << item

    File.open('all_documents_csfd_output.json','w') do |file|
      file.write(JSON.pretty_generate(final_output))
    end

    new_arr = arr[1..-1]

    File.open('all_csfd_documents_processed','w') do |file|
      file.puts(new_arr)
    end

    filter_csfd_links()

  end

  parse_csfd_links() if @csfd_program_parser == 1
  filter_imdb_links() if @imdb_filter == 1
  parse_imdb_content() if @imdb_parser == 1
  extract_keywords() if @alchemy == 1
  create_histogram() if @hist == 1
  parse_csfd_all() if @csfd_parser == 1
  filter_csfd_links() if @csfd_filter == 1
end
