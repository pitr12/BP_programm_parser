require 'json'

class ClassifierInputBuilder
  CATEGORIES = {"Technology" => 21, "Mystery" => 16, "Science" => 20, "Catastrophic" => 24, "Nature" => 12, "Animals" => 30, "Geography" => 29,
                "Adventure" => 26, "Environment" => 11, "Traveling" => 23, "Health" => 13, "Drugs" => 7, "Economics" => 18 ,"Crime" => 6,
                "Politics" => 9, "Biography" => 3, "Society" => 14, "Religion" => 17, "Culture" => 27, "Psychology" => 10, "Philosophy" => 15,
                "Art and Artists" => 1, "History" => 19, "Conspiracy" => 5, "Military and War" => 8, "Media" => 2, "Comedy" => 4,
                "Housing" => 28, "Sports" => 22, "I can't do this" => 25}

  def self.covert_my_classification_file
    input_data = JSON.parse(File.read('final_output.json'))
    all_data = JSON.parse(File.read('experiment_dataset_all_containing_imdb_desc.json'))

    titles=[]
    input_data.each do |item|
      titles << item["title"]
    end

    output = []
    input_data.each do |item|
      all_data.each do |all|
        if all["imdb_title"] ==item["title"]
          all["categories"] = item["category"]
          output << all
        end
      end
    end
    puts output.size

    File.open('my_classification_data.json','w') do |file|
      file.write(JSON.pretty_generate(output))
    end

  end

  def self.converrt_categories(categories)
    num_categories = []
    categories.each do |category|
      num_categories << CATEGORIES[category]
    end
    return num_categories
  end

  def self.construct_input_json
   pairs = [["experiment/JozoStanoPretty.json","experiment/AndrejSevcPretty.json"],
            ["experiment/MiroSimekPretty.json","experiment/OndrejKassakPretty.json"],
            ["experiment/PeterUherekPretty.json","experiment/JakubSenkoPretty.json"],
            ["experiment/romanrostarPretty.json","experiment/PeterZimenPretty.json"],
            ["experiment/MatusCimermanPretty.json","experiment/MonikaFilipcikovaPretty.json"],
            ["experiment/PeterKratkyPretty.json","experiment/MatejLeskoPretty.json"],
            ["experiment/MariusPretty.json","experiment/MartinBorakPretty.json"],
            ["experiment/JakubDadoPretty.json","experiment/JakubMacinaPretty.json"],
            ["experiment/DominikaPretty.json","experiment/VeronikaPretty.json"]]

   output = []
    pairs.each do |pair|
      data0 = JSON.parse(File.read(pair[0]))
      data1 = JSON.parse(File.read(pair[1]))
      small_output = []
      (0..14).each do |index|
        categories = []
        categories << data0[index]["primary_category"]
        categories << data0[index]["secondary_category"]
        categories << data1[index]["primary_category"]
        categories << data1[index]["secondary_category"]
        categories = categories.uniq.reject(&:nil?)

        new_categories = converrt_categories(categories)

        new_item = {"id" => data0[index]["id"], "imdb_title" => data0[index]["imdb_title"], "csfd_title" => data0[index]["csfd_title"],
                    "imdb_desc" => data0[index]["imdb_desc"], "csfd_desc" => data0[index]["csfd_desc"], "imdb_url" => data0[index]["imdb_url"],
                    "csfd_url" => data0[index]["csfd_url"], "categories" => new_categories}

        small_output << new_item
      end
      output += small_output
    end

   File.open('experiment_classification_data.json','w') do |file|
     file.write(JSON.pretty_generate(output))
   end
  end

  construct_input_json
end