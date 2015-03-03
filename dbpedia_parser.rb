require 'nokogiri'
require 'sparql/client'

class DbpediaParser
  def self.run_query(name)
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query("SELECT DISTINCT ?film
                            WHERE  {
                               ?film a dbpedia-owl:Work ;
                                     rdfs:label ?label .
                               filter contains( ?label, \"#{name}\" )
                            }
                          LIMIT 50")


    puts "////DBpedia Results:////"
    result.each do |line|
      puts line[:film]
    end
  end
end