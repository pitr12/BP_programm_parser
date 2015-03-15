require 'json'
require 'fast-stemmer'

class DocumentaryMoviesClassifier
  def self.convert_movie_to_vector(movie)
    size = @global_dictionary.size
    vector = Array.new(size,0)

    movie["keywords"].each do |keyword|
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

  JSON.parse(File.read('final_output.json')).each do |movie|
    vector = convert_movie_to_vector(movie)
    break
  end
end