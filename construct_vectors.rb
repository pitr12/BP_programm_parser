require 'json'
require 'fast-stemmer'

class ConstructVectors

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

  @global_dictionary = []
  File.readlines('global_dictionary_200k').each do |line|
    @global_dictionary << line.chomp
  end
  @global_dictionary_hash = Hash[@global_dictionary.map.with_index.to_a]

  @stop_words = []
  File.readlines('english-stop-words').each do |line|
    @stop_words << line.chomp
  end

puts "Creating vectors and labels..."
  JSON.parse(File.read('classifier_input/all_data.json')).each_with_index do |movie,index|
    name = index + 1
    vector = convert_movie_to_vector(movie)
    labels = movie["categories"]

    File.open("classifier_input/vectors/#{name}",'w') do |file|
      file.puts(vector)
    end

    File.open("classifier_input/labels/#{name}",'w') do |file|
      file.puts(labels)
    end

    puts name
  end


end