require 'json'

class ManualClassifier
  def self.draw_big_line
    puts '////////////////////////////////////////////////////////////////////////////////////////'
  end

  def self.draw_line
    puts '________________________________________________________________________________________'
  end

  def self.print_content(item)
    draw_big_line
    puts "Title: " + item["title"]
    draw_line
    puts "Description: " + item["desc"]
    draw_line
    puts "Keywords: "
    puts item["keywords"]
    draw_line
    puts "Please select category: "
  end

  def self.classify()
    file = File.read('output_new.json')
    data = JSON.parse(file)

    if data.size == 0
      puts "END"
      exit(1)
    end
    puts "Remaining: " +data.size.to_s

    item = data.first
    print_content(item)
      category = gets.chomp
      category = category.split(' ')
      puts "\n\n\n\n\n"

    final_output = []
    if !File.zero?('final_output.json')
      file2 = File.read('final_output.json')
      final_output = JSON.parse(file2)
    end
      final_output << {:title => item["title"], :desc => item["desc"], :url => item["url"], :keywords => item["keywords"], :category => category}

      File.open('final_output.json','w') do |file|
        file.write(JSON.pretty_generate(final_output))
      end

    new_data = data[1..-1]
    File.open('output_new.json','w') do |file|
      file.write(JSON.pretty_generate(new_data))
    end

    classify()
  end
end

ManualClassifier.classify()