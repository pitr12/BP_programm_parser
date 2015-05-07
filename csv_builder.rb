require 'json'
require 'fast-stemmer'

class CSVBuilder
  def self.remove_stop_words(text)
    text = text.split.delete_if{|x| @stop_words.include?(x.downcase)}.join(' ') #remove stop words
    text = text.gsub(/[^A-Za-z0-9\s]/i, '')  #remove punctuation
    return text
  end

  def self.convert_movie_to_vector(movie)
    size = @global_dictionary.size
    vector = Array.new(size,0)

    features = remove_stop_words(movie["imdb_desc"]).split
    features.each do |keyword|
      if @global_dictionary.include? keyword
        vector[@global_dictionary_hash[keyword]] = 1
      else
        if @global_dictionary.include? keyword.stem
          vector[@global_dictionary_hash[keyword.stem]] = 1
        end
      end
    end

    return vector
  end

  def self.run
    @global_dictionary = []
    File.readlines('global_dictionary_200k').each do |line|
      @global_dictionary << line.chomp
    end
    @global_dictionary_hash = Hash[@global_dictionary.map.with_index.to_a]

    @stop_words = []
    File.readlines('english-stop-words').each do |line|
      @stop_words << line.chomp
    end

    data = JSON.parse(File.read('classifier_input/training_data.json'))

    categories = []
    (1..30).each do |index|
      categories << "category_#{index}"
    end

    #build CSV header
    File.open('classifier_input/training_data.csv','w') do |file|
      file.write("id,movieID,#{@global_dictionary.join(",")},#{categories.join(",")}\n")

      data.each_with_index do |item,index|
        movieID = item["id"]
        id = index + 1
        vector = convert_movie_to_vector(item)

        m_categories = Array.new(30,0)
        item["categories"].each do |category|
          category = category.to_i - 1
          m_categories[category] += 1
        end

        file.write("#{id},#{movieID},#{vector.join(",")},#{m_categories.join(",")}\n")
      end
    end

  end

  run()
end