# frozen_string_literal: true

require 'httparty'
require 'open-uri'

namespace :import do
  desc 'Import json bulk data'
  task bulk_data: :environment do

    res = HTTParty.get('https://api.scryfall.com/bulk-data')
    dumps = JSON.parse(res.body)['data']
    file_path = dumps.filter { |d| d['type'] == 'oracle_cards' }.first['download_uri']

    file = File.read URI.open(file_path) # rubocop:disable Security/Open

    create_entries(JSON.parse file)

  end

  desc 'Import json bulk data'
  task :file, [:file_path] => :environment do |_task, args|
    Rails.logger.info '=== Importing from json dump ==='

    file = File.read args[:file_path]
    create_entries(JSON.parse file)
  end

  def create_entries(json_cards)
    batch_size = 2_000
    start_time = Time.now
    # TODO is legal in any of the 5 formats
    # TODO is token type_line starts with 'Token'?

    Rails.logger.info "Parsed #{json_cards.count} cards. Importing new ones..."

    shortened_cards = json_cards.map{|c| {oracle_id: c['oracle_id'], name: c['name']}}
    price_json = json_cards.map{|c| {oracle_id: c['oracle_id'], prices: c['prices']}}
    shortened_cards.each do |shortened_card|
      Card.find_or_create_by(oracle_id: shortened_card[:oracle_id]) do |card|
        card.name = shortened_card[:name]
      end
    end
    Rails.logger.info "Imported #{shortened_cards.count} cards"

    Rails.logger.info 'Updating prices for cards'
    price_json.each_slice(batch_size) do |parsed_cards|
      price_count = 0
      card_prices = []
      parsed_cards.each do |parsed_card|
        card_obj = Card.find_by(oracle_id: parsed_card[:oracle_id])

        prices = parsed_card[:prices]
        card_prices << {card_id: card_obj.id, eur: prices['eur'], usd: prices['usd'], tix: prices['tix']}
        price_count +=1
      end
      PriceEntry.insert_all(card_prices)
      Rails.logger.info "Imported prices for batch of #{price_count} cards"
    end
    Rails.logger.info "Done in #{Time.now - start_time}s. Imported #{shortened_cards.count} new cards in total."
  end
end
