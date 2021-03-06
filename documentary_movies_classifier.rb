require 'json'
require 'fast-stemmer'
require 'libsvm'
require 'yaml'

class DocumentaryMoviesClassifier
  @debug = 1
  @training = 1
  @training_vec = 0

  CATEGORIES = {0 => 1,	1=>6,	2=>8,	3=>9,	4=>23, 5=>29,	6=>21,	7=>30,	8=>3,	9=>25,	10=>12,
                11=>20,	12=>24,	13=>19,	14=>14,	15=>10,	16=>16,	17=>26,	18=>18,	19=>27,	20=>28,
                21=>2,	22=>13,	23=>17,	24=>7, 25=>22,	26=>11,	27=>5,	28=>15,	29=>4}

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

  def self.get_training_result(index, prediction)
      categories = @training_data[index]["categories"]

      categories.each_with_index do |item,index|
        categories[index] = item.to_i
      end
      return (@training_data[index]["categories"] & prediction).any?
  end

  def self.get_test_result(categories, prediction)
    return (categories & prediction).any?
  end

  # ------------    MY DATA   ------------------------------------------------------------

  @global_dictionary = []
  File.readlines('global_dictionary_200k').each do |line|
    @global_dictionary << line.chomp
  end
  @global_dictionary_hash = Hash[@global_dictionary.map.with_index.to_a]

  @stop_words = []
  File.readlines('english-stop-words').each do |line|
    @stop_words << line.chomp
  end

  # @training_data = JSON.parse(File.read('classifier_input/training_data.json'))
  # @test_data = JSON.parse(File.read('classifier_input/test_data.json'))

    puts "Global dictionary created! \n\n" if @debug == 1

  # if @training_vec == 1
  #   puts "Creating vectors for training set..." if @debug == 1
  #   feature_vectors = []
  #   labels = []
  #   JSON.parse(File.read('classifier_input/training_data.json')).each do |movie|
  #     movie["categories"].each_with_index do |item, index|
  #     vector = convert_movie_to_vector(movie)
  #     feature_vectors << vector
  #     labels << movie["categories"][index].to_i
  #     end
  #   end
  #   puts "Vectors and labels for training set created! \n\n" if @debug == 1
  #
  #
  #   puts "Creating vectors for training-test set..." if @debug == 1
  #   training_test_vectors = []
  #   JSON.parse(File.read('classifier_input/training_data.json')).each do |movie|
  #       vector = convert_movie_to_vector(movie)
  #       training_test_vectors << vector
  #   end
  #   puts "Vectors and labels for training-test set created! \n\n" if @debug == 1
  #
  #   # training_test_vectors.each_with_index do |vector,index|
  #   #   File.open("classifier_input/vectors/vector_#{index}",'w') do |file|
  #   #     file.puts(vector)
  #   #   end
  #   # end
  # end

  # puts "Loading vectors for training-test set..." if @debug == 1
  # training_test_vectors = []
  # (0..334).each do |index|
  #   vector = []
  #   File.readlines("classifier_input/vectors/vector_#{index}").each do |line|
  #     vector << line
  #   end
  #   training_test_vectors << vector
  # end
  # puts "Vectors for training-test set loaded! \n\n" if @debug == 1

  # puts "Creating vectors for testing set..." if @debug == 1
  # test_vectors = []
  # JSON.parse(File.read('classifier_input/test_data.json')).each do |movie|
  #   vector = convert_movie_to_vector(movie)
  #   test_vectors << vector
  # end
  # puts "Vectors and labels for testing set created! \n\n" if @debug == 1

  if @training == 1
    puts "Loading training vectors..." if @debug == 1
    training_vectors = []
    training_labels = []
    (1..140).each do |index|
      vector = []
      File.readlines("classifier_input/vectors/#{index}").each do |line|
        vector << line
      end

      File.readlines("classifier_input/labels/#{index}").each do |category|
        training_vectors << vector
        training_labels << category.chomp.to_i
      end
    end

    (171..350).each do |index|
      vector = []
      File.readlines("classifier_input/vectors/#{index}").each do |line|
        vector << line
      end

      File.readlines("classifier_input/labels/#{index}").each do |category|
        training_vectors << vector
        training_labels << category.chomp.to_i
      end
    end
    puts "Vectors for training-test set loaded! \n\n" if @debug == 1

    puts "number of labels:"
    puts training_labels.size

    puts "\n\n"
  end

  puts "Loading test vectors..." if @debug == 1
  test_vectors = []
  test_labels = []
  (141..170).each do |index|
    vector = []
    File.readlines("classifier_input/vectors/#{index}").each do |line|
      vector << line
    end

    test_vectors << vector

    categories = []
    File.readlines("classifier_input/labels/#{index}").each do |category|
      categories << category.chomp.to_i
    end

    test_labels << categories
  end
  puts "Vectors for test set loaded! \n\n" if @debug == 1

  puts "test labels:"
  puts test_labels.inspect
  puts "\n\n"


  if @training == 1
    # Define kernel parameters
    pa = Libsvm::SvmParameter.new
    pa.c = 100
    pa.svm_type = Libsvm::SvmType::C_SVC
    pa.degree = 1
    pa.coef0 = 0
    pa.eps= 0.001
    pa.cache_size = 100 # MB
    pa.probability = 1
    #pa.nu = 1.5

    sp = Libsvm::Problem.new

    # Add documents to the training set
    puts "Creating examples..." if @debug == 1
    ec = 0
    examples = training_vectors.map {|ary|
      puts "Example: " +ec.to_s
      ec += 1
      Libsvm::Node.features(ary)
    }
    puts "Examples created! \n\n" if @debug == 1
    puts "Setting examples..." if @debug == 1
    sp.set_examples(training_labels, examples)
    puts "Examples set! \n\n" if @debug == 1
  end

  # exit(1)

  # We're not sure which Kernel will perform best, so let's give each a try
  kernels = [ Libsvm::KernelType::LINEAR, Libsvm::KernelType::POLY, Libsvm::KernelType::RBF, Libsvm::KernelType::SIGMOID ]
  kernel_names = [ 'Linear', 'Polynomial', 'Radial basis function', 'Sigmoid' ]
  m = nil

  kernels.each_index { |j|
    # Iterate and over each kernel type

    if @training == 1
      pa.kernel_type = kernels[j]
      puts "Training model..." if @debug == 1
      m = Libsvm::Model.train(sp, pa)
      puts "Training finished! \n\n" if @debug == 1
      puts "Saving model! \n\n" if @debug == 1
      m.save('cross_validation_7.model') # save model
      puts "Model saved! \n\n" if @debug == 1
    else
      puts "Loading model!" if @debug == 1
      m = Libsvm::Model.load('cross_validation_7.model') #load model
      puts "Model loaded! \n\n" if @debug == 1
    end

    # correct_count = 0
    # puts "Predicting on training data..." if @debug == 1
    # # Test kernel performance on the training set
    # training_test_vectors.each_with_index { |item,i|
    #   pred, probs = m.predict_probability(Libsvm::Node.features(item))
    #
    #   pred = []
    #   probs_sorted = probs.sort
    #   pred << CATEGORIES[probs.index(probs_sorted[-1])]
    #   pred << CATEGORIES[probs.index(probs_sorted[-2])]
    #   pred << CATEGORIES[probs.index(probs_sorted[-3])]
    #
    #
    #    puts "Index: #{i}, Prediction: #{pred}"
    #    result = get_training_result(i,pred)
    #    puts result
    #    correct_count += 1 if result == true
    # }
    #
    # puts "CORRECT: " +correct_count.to_s + " / " +@training_data.size.to_s

    correct_count = 0
    puts "Predicting on testing data..." if @debug == 1
    # Test kernel performance on the training set
    test_vectors.each_with_index { |item,i|
      pred, probs = m.predict_probability(Libsvm::Node.features(item))

      pred = []
      probs_sorted = probs.sort
      pred << CATEGORIES[probs.index(probs_sorted[-1])]
      pred << CATEGORIES[probs.index(probs_sorted[-2])]
      pred << CATEGORIES[probs.index(probs_sorted[-3])]


      puts "Index: #{i}, Prediction: #{pred}, True_labels: #{test_labels[i]}"


      result = get_test_result(test_labels[i],pred)
      puts result
      correct_count += 1 if result == true
    }

    puts "CORRECT: " +correct_count.to_s + " / 30"
    break
  }
end