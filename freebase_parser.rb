require 'faraday'
require 'faraday_middleware'

class FreebaseParser
  def self.run_query(name)
    connection = Faraday.new 'https://www.googleapis.com/' do |conn|
      conn.response :json, :content_type => /\bjson$/
      conn.adapter Faraday.default_adapter
    end

    json_response = connection.get("freebase/v1/mqlread?query=[{\"id\": null,\"name\": \"#{name}\",\"limit\": 100}]")
    result = json_response.body

    puts result

    puts "\n\n\n/////Freebase Results:////"
    if !result["result"].nil?
      result["result"].each do |result|
        puts result["id"]
      end
    end

  end
end