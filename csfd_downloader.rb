require 'nokogiri'
require 'faraday'

class Csfd_Downloader
  #Download site for specific Channel and day
  def self.download_site(channel, day)

    conn = Faraday.new(:url => 'http://www.csfd.cz') do |faraday|
      faraday.request  :retry, max: 4
      # faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    response = conn.get "/televize?day=#{day}"
    cookie = response.headers['set-cookie']
    cookie.gsub!(/tv_stations=[^;]*/,"tv_stations=#{channel}")

    response2 = conn.post do |req|
      req.url "/televize?day=#{day}"
      req.headers['Cookie'] = cookie
    end

    return response2.body
  end

  #Parse basic content from program site
  def self.parse_program_content(site)
    body = Nokogiri::HTML(site)
    program = []

    body.search('.box').each do |box|
      #parse start time
      time = box.search('.time').text

      #parse name
      content = box.search('.name')
      name = content.css('a').text
      if name.empty?
        name = content.text
      end

      #parse URL
      url = ""
      link = content.css('a')
      if !link.empty?
        url = "http://www.csfd.cz" + link[0]["href"].to_s
      end

      #if TV show than parse season and episode number
      series = box.search('.series').text[1..-2]
      season = ""
      episode = ""
      if !series.nil?
        season = series.match(/S\d*/).to_s
        episode = series.match(/E\d*/).to_s
      end

      hash = {:time => time, :name => name, :url => url, :season => season, :episode => episode}
      program << hash
    end

    return program
  end
end