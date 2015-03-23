require 'json'
require 'fast-stemmer'
require 'libsvm'

class DocumentaryMoviesClassifier
  @debug = 1
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

  puts "Creating vectors for training set..." if @debug == 1
  feature_vectors = []
  labels = []
  JSON.parse(File.read('final_output.json')).each do |movie|
    vector = convert_movie_to_vector(movie)
    feature_vectors << vector

    labels << movie["category"].first.to_i
  end
  puts "Vectors and labels for training set created! \n\n" if @debug == 1

  #---------------------------------------------------------------------------------------

  # # Sample training set ...
  # # ----------------------------------------------------------
  # # Labels for each document in the training set
  # #    1 = Spam, 0 = Not-Spam
  # labels = [1, 1, 0, 1, 1, 0, 0]
  #
  # documents = [
  #     %w[FREE NATIONAL TREASURE],      # Spam
  #     %w[FREE TV for EVERY visitor],   # Spam
  #     %w[Peter and Stewie are hilarious], # OK
  #     %w[AS SEEN ON NATIONAL TV],      # SPAM
  #     %w[FREE drugs],          # SPAM
  #     %w[New episode rocks, Peter and Stewie are hilarious], # OK
  #     %w[Peter is my fav!]        # OK
  # # ...
  # ]
  #
  # # Test set ...
  # # ----------------------------------------------------------
  # test_labels = [1, 0, 0]
  #
  # test_documents = [
  #     %w[FREE lotterry for the NATIONAL TREASURE !!!], # Spam
  #     %w[Stewie is hilarious],     # OK
  #     %w[Poor Peter ... hilarious],    # OK
  # # ...
  # ]
  #
  # # Build a global dictionary of all possible words
  # dictionary = (documents+test_documents).flatten.uniq
  # puts "Global dictionary: \n #{dictionary.inspect}\n\n"
  #
  # # Build binary feature vectors for each document
  # #  - If a word is present in document, it is marked as '1', otherwise '0'
  # #  - Each word has a unique ID as defined by 'dictionary'
  # feature_vectors = documents.map { |doc| dictionary.map{|x| doc.include?(x) ? 1 : 0} }
  # test_vectors = test_documents.map { |doc| dictionary.map{|x| doc.include?(x) ? 1 : 0} }
  #
  # puts "First training vector: #{feature_vectors.first.inspect}\n"
  # puts "First test vector: #{test_vectors.first.inspect}\n"

  # Define kernel parameters -- we'll stick with the defaults
  pa = Libsvm::SvmParameter.new
  pa.c = 100
  pa.svm_type = Libsvm::SvmType::C_SVC
  pa.degree = 1
  pa.coef0 = 0
  pa.eps= 0.001
  pa.cache_size = 1 # MB
  #pa.nu = 1.5 # (Not sure about this)

  sp = Libsvm::Problem.new

  # Add documents to the training set
  puts "Creating examples..." if @debug == 1
  examples = feature_vectors.map {|ary| Libsvm::Node.features(ary) }
  puts "Examples created! \n\n" if @debug == 1

  sp.set_examples(labels, examples)


  # We're not sure which Kernel will perform best, so let's give each a try
  kernels = [ Libsvm::KernelType::LINEAR, Libsvm::KernelType::POLY, Libsvm::KernelType::RBF, Libsvm::KernelType::SIGMOID ]
  kernel_names = [ 'Linear', 'Polynomial', 'Radial basis function', 'Sigmoid' ]
  m = nil

  kernels.each_index { |j|
    # Iterate and over each kernel type
    pa.kernel_type = kernels[j]
    puts "Training model..." if @debug == 1
    m = Libsvm::Model.train(sp, pa)
    puts "Training finished! \n\n"
    ec = 0

    # Test kernel performance on the training set
    labels.each_index { |i|
      pred, probs = m.predict_probability(Libsvm::Node.features(feature_vectors[i]))
      puts "Index: #{i}, Prediction: #{pred}, True label: #{labels[i]}, Kernel: #{kernel_names[j]}"
      ec += 1 if labels[i] != pred
    }
    puts "Kernel #{kernel_names[j]} made #{ec} errors on the training set"

    # # Test kernel performance on the test set
    # ec = 0
    # test_labels.each_index { |i|
    #   pred, probs = m.predict_probability(Libsvm::Node.features(test_vectors[i]))
    #   puts "\t Prediction: #{pred}, True label: #{test_labels[i]}, Probs: #{probs}"
    #   ec += 1 if test_labels[i] != pred
    # }
    #
    # puts "Kernel #{kernel_names[j]} made #{ec} errors on the test set \n\n"
  }
end