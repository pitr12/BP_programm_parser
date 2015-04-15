require 'json'
require 'fast-stemmer'
require 'libsvm'
require 'yaml'

class DocumentaryMoviesClassifier
  @debug = 1
  @training = 0
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

  # ------------    MY DATA   ------------------------------------------------------------

  @global_dictionary = []
  File.readlines('global_dictionary_200k').each do |line|
    @global_dictionary << line.chomp
  end
  @global_dictionary_hash = Hash[@global_dictionary.map.with_index.to_a]

  puts "Global dictionary created! \n\n" if @debug == 1

  if @training == 1
    puts "Creating vectors for training set..." if @debug == 1
    feature_vectors = []
    labels = []
    JSON.parse(File.read('final_output.json')).each do |movie|
      vector = convert_movie_to_vector(movie)
      feature_vectors << vector

      labels << movie["category"].first.to_i
    end
    puts "Vectors and labels for training set created! \n\n" if @debug == 1
  end

  puts "Creating vectors for testing set..." if @debug == 1
  test_vectors = []
  JSON.parse(File.read('test_data.json')).each do |movie|
    vector = convert_movie_to_vector(movie)
    test_vectors << vector
  end
  puts "Vectors and labels for testing set created! \n\n" if @debug == 1

  if @training == 1
    # Define kernel parameters
    pa = Libsvm::SvmParameter.new
    pa.c = 100
    pa.svm_type = Libsvm::SvmType::C_SVC
    pa.degree = 1
    pa.coef0 = 0
    pa.eps= 0.001
    pa.cache_size = 10 # MB
    pa.probability = 1
    #pa.nu = 1.5

    sp = Libsvm::Problem.new

    # Add documents to the training set
    puts "Creating examples..." if @debug == 1
    examples = feature_vectors.map {|ary| Libsvm::Node.features(ary) }
    puts "Examples created! \n\n" if @debug == 1

    sp.set_examples(labels, examples)
  end


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
      # m.save('smv_train.model') # save model
      puts "Training finished! \n\n" if @debug == 1
    end

     m = Libsvm::Model.load('smv_train.model') #load model
    ec = 0

    # puts "Predicting on training data..." if @debug == 1
    # # Test kernel performance on the training set
    # labels.each_index { |i|
    #   pred, probs = m.predict_probability(Libsvm::Node.features(feature_vectors[i]))
    #   # puts "Index: #{i}, Prediction: #{pred}, True label: #{labels[i]}, Kernel: #{kernel_names[j]}"
    #   ec += 1 if labels[i] != pred
    # }
    # # puts "Kernel #{kernel_names[j]} made #{ec} errors on the training set \n\n"

    puts "Predicting on testing data..." if @debug == 1
    # Test kernel performance on the test set
    ec = 0
    test_vectors.each_with_index { |vector,i|
      pred, probs = m.predict_probability(Libsvm::Node.features(vector))
      puts "Index: #{i}, \t Prediction: #{pred}, Probs: #{probs}"
    }
    #puts "Kernel #{kernel_names[j]} made #{ec} errors on the test set \n\n"
    puts "Test data prediction finished!" if @debug == 1

    break
  }
end