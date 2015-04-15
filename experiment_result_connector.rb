require 'json'

class ExperimentResultConnector
  def self.get_input_files
    input_names = gets.chomp.split(' ')
    return input_names
  end

  def self.parse_data(input_files)
    parsed_data = []
    input_files.each do |file|
      data = JSON.parse(File.read(File.dirname(__FILE__) + '/experiment/' + file))
      parsed_data << data
    end
    parsed_data
  end

  def self.find_best_result(categories)
    categories.uniq.each do |category|
      if categories.count(category) > 1
        return category
      end
    end
    return nil
  end

  def self.find_result
    input_data = []
    get_input_files.each do |file|
      data = JSON.parse(File.read(File.dirname(__FILE__) + '/experiment/' + file))
      input_data << data
    end

    different = 0

    (0..14).each do |index|
      puts "---------------------------------------------------------------------------------------------\n"
      parsed_categories_primary = []
      parsed_categories_secondary = []
      input_data.each do |data|
        parsed_categories_primary << data[index]["primary_category"]
        parsed_categories_secondary << data[index]["secondary_category"]
      end
      puts "Priamry categories: " +parsed_categories_primary.inspect
      puts "Secondary categories: " +parsed_categories_secondary.inspect

      primary_category = find_best_result(parsed_categories_primary)

      if !primary_category.nil?
        puts primary_category
        next
      end

      #if match is not found connetc primary and secondary category
      connected_categories = parsed_categories_primary + parsed_categories_secondary
      best_category = find_best_result(connected_categories)
      if !best_category.nil?
        puts best_category
        next
      end

      puts "NO MATCH\n"
      puts "---------------------------------------------------------------------------------------------\n"
      different += 1
    end
    puts different
  end

  find_result()
end