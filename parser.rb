# encoding: utf-8

require 'json'
require 'nokogiri'
require 'faraday'
require 'roo'

def self.parse_content()
  document = Roo::Excelx.new("program.xlsx")
  document.default_sheet = document.sheets.first

(document.first_row..document.last_row).each do |row_number|
  #process all rows except first row which represent sheet header
  if row_number != 1
    row = document.row(row_number)
    id = row[0]
    television = row[1]
    date = row[2]
    start_time = convert_time(row[3])
    name = row[4]
    info1 = row[5]
    info2 = row[6]

    director = parse_direcotor_name(info1,1)
    if director.nil?
      director = parse_direcotor_name(info2,2)
    end


    puts "ID: " +id.to_s
    # puts "Stanica: " + television
    # puts "Datum: " + date.to_s
    # puts "Začiatočný čas: " + start_time.to_s
    # puts "Nazov: " + name.to_s
    # puts "Info1: " + info1.to_s
    # puts "Info2: " + info2.to_s
    puts "Režisér: " + director.to_s
    puts ""
  end
end

end

#convert time from 29h format to 24h format
def self.convert_time(time)
  if(time > 24)
    time = (time -24).round(2)
  end
  time
end

#parse name of director
def self.parse_direcotor_name(info,id)
    if id == 1
     director = info.to_s[/[rR].{0,1}ži[ea]:* .*/]
    else
      director = info.to_s[/[rR].{0,1}ži[ea]: [^<]*/]
    end

    if !director.nil?
      director = director.gsub("Režie","")
      director = director.gsub("režie","")
      director = director.gsub(":","").strip

      if director[-1] == "."
        director = director[0..-2]
      end
    end
  director
end

#calling main funcion to process data input
parse_content()