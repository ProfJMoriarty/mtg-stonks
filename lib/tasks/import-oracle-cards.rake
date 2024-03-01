# frozen_string_literal: true

require 'httparty'
require 'open-uri'

namespace :import do
  desc 'Import json bulk data'
  task bulk_data: :environment do
    puts '=== Importing from json dump ==='

    res = HTTParty.get('https://api.scryfall.com/bulk-data')
    dumps = JSON.parse(res.body)['data']
    file_path = dumps.filter { |d| d['type'] == 'oracle_cards' }.first['download_uri']

    file = File.read URI.open(file_path) # rubocop:disable Security/Open

    # TODO: Loading the whole ~ 145MB into mem is a medium/bad idea, find smth else.
    parsed_cards = JSON.parse file

    puts "Parsed #{parsed_cards.count} cards. Importing new ones..."
    start_time = Time.now

    new_cards = 0
    parsed_cards.each do |parsed_card|
      # Also very slow... ~350s
      card_obj = Card.where(oracle_id: parsed_card['oracle_id']).first_or_create do |nc|
        nc.name = parsed_card['name']
        new_cards += 1
      end

      prices = parsed_card['prices']
      PriceEntry.create(card: card_obj, eur: prices['eur'], usd: prices['usd'], tix: prices['tix'])
    end

    puts "Done in #{Time.now - start_time}s. Imported #{new_cards} new cards."
  end

  # TODO: add tasks to this namespace that do this with the scryfall api and not a fixture
end
