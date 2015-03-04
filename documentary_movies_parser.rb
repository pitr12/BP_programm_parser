require_relative File.dirname(__FILE__) + '/csfd_downloader.rb'

class DocumentaryMoviesParser

  @debug = 1

#specify day for which should be program parsed (0 today, 1 tomorrow ....)
  DAYS = [4,5,6,7,8,9,10,11,12,13,14,15,16,17]

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
    puts program if @debug
    return program
  end

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
