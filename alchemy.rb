require_relative File.dirname(__FILE__) + '/alchemyapi_ruby/alchemyapi.rb'

class Alchemy
  def self.extract_keywords(text)
    alchemyapi = AlchemyAPI.new()

    # AlchemyAPI text categorization
    category = []
    response = alchemyapi.category('text', text)

    if response['status'] == 'OK'
      if response['score'].to_f > 0.3
        category = response['category'].split('_')
      end
    else
      puts 'Error in text categorization call: ' + response['statusInfo']
    end

    #AlchemyAPI keyword extraction
    keywords = category.join(' ') + ' '
    response = alchemyapi.keywords('text', text, { 'sentiment'=>0 })

    if response['status'] == 'OK'
      for keyword in response['keywords']
        if keyword['relevance'].to_f > 0.3
          keywords += keyword['text'] + ' '
        end
      end
    else
      puts 'Error in keyword extraction call: ' + response['statusInfo']
    end

    keyword_list = keywords.split(' ')
    return keyword_list
  end
end