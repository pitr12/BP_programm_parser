require 'roo'

def self.parse_content()
  document = Roo::Excelx.new("program.xlsx")
  document.default_sheet = document.sheets.first

  count = 0;

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

    #parse director name
    director = parse_direcotor_name(info2,2)
    if director.nil?
      director = parse_direcotor_name(info1,1)
    end

    #parse production year
    year = parse_year(info2,2)
    if year.nil?
      year = parse_year(info1,1)
    end

    #parse actors
    actors = parse_actors(info2,2)
    if actors.nil?
      actors = parse_actors(info1,1)
    end

    #parse country
    country = parse_country(info2)


    if !country.nil?
      count = count+1
    end

     puts count


    #print some outputs
    # puts "ID: " +id.to_s
    # puts "Stanica: " + television
    # puts "Datum: " + date.to_s
    # puts "Začiatočný čas: " + start_time.to_s
    # puts "Nazov: " + name.to_s
    # puts "Info1: " + info1.to_s
    # puts "Info2: " + info2.to_s
    # puts "Režisér: " + director.to_s
    # puts "Rok výroby: " +year.to_s
    # puts "Herci: " +actors.to_s
    puts "Krajina pôvodu: " +country.to_s
    # puts ""

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
     director = info.to_s[/[rR].{0,1}ži[ea]:? .*/]
    else
      director = info.to_s[/[rR].{0,1}ži[ea]:? [^<]*/]
    end

    if !director.nil?
      director = director.gsub("Režie","")
      director = director.gsub("režie","")
      director = director.gsub(":","").strip
      director = director.gsub(/[\(\)\d]/,"")

      if director[-1] == "."
        director = director[0..-2]
      end
    end
  director
end

#parse production year
def self.parse_year(info, id)
  if id == 1
    year = info.to_s[/\(\d{4}.?/]
  else
    year = info.to_s[/Rok výroby: \d{4}/]
  end

  if !year.nil?
    year = year.gsub(/[^\d]/,"")
  end
  year
end

#parse actors
def self.parse_actors(info,id)
  if id == 1
    actors = info.to_s[/[hH]rají:? .*/]
  else
    actors = info.to_s[/[hH]rají:? [^<]*/]
  end

  if !actors.nil?
    actors = actors.gsub("Hrají: ","")
    actors = actors.gsub(/[rR].{0,1}ži[ea]:? .*/,"")
    actors = actors.gsub(/ a další\.?/,"")
  end
  actors
end

#parse country
def self.parse_country(info)
  country = info.to_s[/[zZ]emě: [^<]*/]

  if !country.nil?
    country = country.gsub(/[zZ]emě: /,"")
  end
end

#calling main funcion to process data input
parse_content()