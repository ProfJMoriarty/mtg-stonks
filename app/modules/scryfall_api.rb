require 'httparty'
require 'json'
require 'cgi'

module ScryfallApi
  class Client
    def initialize
      @base_url = 'https://api.scryfall.com'
    end

    def exact_name_search(card_name)
      query = CGI.escape(card_name)
      response = HTTParty.get("#{@base_url}/cards/named?exact=#{query}")

      JSON.parse(response.body)
    end

    def image_url(card_name)
      exact_name_search(card_name)['image_uris']['normal']
    end
  end
end
