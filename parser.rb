require_relative File.dirname(__FILE__) + '/csfd_downloader.rb'
require_relative File.dirname(__FILE__) + '/csfd_parser.rb'

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
  site = Csfd_Downloader.download_site(CHANNELS_LIST[channel],DAY);
  # site = File.read("site_file.txt")
  # File.open("site_file.txt", 'w') { |file| file.write(site) }

  #parse program for specific channel and day
  program = Csfd_Downloader.parse_program_content(site)

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
      extend_content = Csfd_Parser.parse_item_content(item[:url].to_s)
    end

    print_extended_content(extend_content)

    #break
  end
end


