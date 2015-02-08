require_relative File.dirname(__FILE__) + '/csfd_downloader.rb'
require_relative File.dirname(__FILE__) + '/csfd_parser.rb'
require_relative File.dirname(__FILE__) + '/imdb_parser.rb'

class Parser
  #list of channels to be parsed
  PARSE_LIST = ['JOJ']

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

  def self.print_extended_content(content)
    puts "Type: " + content[:type].to_s if !content[:type].empty?
    puts "Genres: " + content[:genres].to_s if !content[:genres].empty?
    puts "Countries: " + content[:countries].to_s if !content[:countries].empty?
    puts "Year: " + content[:year].to_s if !content[:year].empty?
    puts "Duration: " + content[:duration].to_s if !content[:duration].empty?
    puts "Directors: " + content[:directors].to_s if !content[:directors].empty?
    puts "Scriptwriters: " + content[:scriptwriters].to_s if !content[:scriptwriters].empty?
    puts "Camera: " + content[:camera].to_s if !content[:camera].empty?
    puts "Music: " + content[:music].to_s if !content[:music].empty?
    puts "Actors: " + content[:actors].to_s if !content[:actors].empty?
    puts "Artwork: " + content[:artwork].to_s if !content[:artwork].empty?
    puts "CSFD rating: " + content[:csfd_rating].to_s if !content[:csfd_rating].empty?
    puts "IMDB id: " + content[:imdb_id].to_s if !content[:imdb_id].empty?
    puts "Original title: " + content[:original_title].to_s if !content[:original_title].empty?
    puts "Description: " + content[:description].to_s if !content[:description].empty?
  end

  def self.print_item_attributes(item)
    puts "Time: " + item[:time].to_s if !item[:time].empty?
    puts "Name: " + item[:name].to_s if !item[:name].empty?
    puts "URL: " + item[:url].to_s if !item[:url].empty?
    puts "Season: " + item[:season].to_s if !item[:season].empty?
    puts "Episode: " + item[:episode].to_s if !item[:episode].empty?
    puts "\n"
  end

  PARSE_LIST.each do |channel|
    #calling function to download site for set day and channel
    site = Csfd_Downloader.download_site(CHANNELS_LIST[channel],DAY);
    # site = File.read("site_file.txt")
    # File.open("site_file.txt", 'w') { |file| file.write(site) }

    #parse program for specific channel and day
    program = Csfd_Downloader.parse_program_content(site)

    puts "\n\n\n\n\n"
    puts "///////////// CHANNEL: #{channel} //////////////////"

    program.each do |item|
      #print item attributes
      print_item_attributes(item)

      extend_csfd_content = {}
      imdb_content = {}

      #if CSFD link to item is present parse CSFD item data
      if(!item[:url].to_s.empty?)
        extend_csfd_content = Csfd_Parser.parse_item_content(item[:url].to_s)

        #if IMDB link is present parse IMDB item data
        imdb_id = extend_csfd_content[:imdb_id].to_s
        if(!imdb_id.empty?)
          imdb_site = Imdb_Parser.download_main_page(imdb_id)
          imdb_content = Imdb_Parser.parse_site_content(imdb_site, imdb_id)
        end
      end

      #print parsed data to output
      print_extended_content(extend_csfd_content) if (!extend_csfd_content.empty?)
      Imdb_Parser.print_data(imdb_content) if(!imdb_content.empty?)

      puts "\n\n\n\n\n"
      puts "-------------------------------------------------------------------------------------\n"
    end
  end
end


