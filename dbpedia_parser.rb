require 'nokogiri'
require 'sparql/client'

class DbpediaParser
  def self.run_query
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query("SELECT DISTINCT ?film
                            WHERE  {
                               ?film a dbpedia-owl:Work ;
                                     rdfs:label ?label .
                               filter contains( ?label, 'Hamlet' )
                            }
                          LIMIT 20")

    result.each do |line|
      puts line[:film]
    end
  end

  run_query()
end