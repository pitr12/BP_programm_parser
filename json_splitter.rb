require 'json'

class JsonSplitter
  COUNT = 15

  def self.main
    file = File.read('experiment_small_dataset.json')
    data = JSON.parse(file)

    output = []
    count = 1

    data.each_with_index do |item,index|
      output << item
      if (index + 1) % 15 == 0
        File.open("#{count}_15.json",'w') do |file|
          file.write(JSON.pretty_generate(output))
        end
        count += 1
        output = []
      end
    end
  end

  main()
end