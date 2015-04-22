require 'json'

class DictionaryCreator
  @stop_words = []
  File.readlines('english-stop-words').each do |line|
    @stop_words << line.chomp
  end

  def self.remove_stop_words(text)
    text = text.split.delete_if{|x| @stop_words.include?(x.downcase)}.join(' ') #remove stop words
    text = text.gsub(/[^A-Za-z0-9\s]/i, '')  #remove punctuation
    return text
  end

  def self.create
    dictionary = []
    data = JSON.parse(File.read('classifier_input/experiment_dataset_all_containing_imdb_desc.json'))

    data.each do |item|
      desc = remove_stop_words(item["imdb_desc"])
      dictionary += desc.split
    end

    puts "size before uniq: " + dictionary.size.to_s
    dictionary = dictionary.uniq
    puts "size after uniq: " + dictionary.size.to_s

    File.open('my_dict','w') do |file|
      file.puts(dictionary)
    end
  end

  create()
end