# frozen_string_literal: true

require 'httparty'
require 'open-uri'

namespace :import do
  desc 'Import json bulk data'
  task bulk_data: :environment do
    Rails.logger.info "=== Importing from json dump ==="

    res = HTTParty.get('https://api.scryfall.com/bulk-data')
    dumps = JSON.parse(res.body)['data']
    file_path = dumps.filter { |d| d['type'] == 'oracle_cards' }.first['download_uri']

    file = File.read URI.open(file_path) # rubocop:disable Security/Open

    batch_size = 2_000
    start_time = Time.now

    json_cards = JSON.parse file
    Rails.logger.info "Parsed #{json_cards.count} cards. Importing new ones..."

    shortened_cards = json_cards.map{|c| {oracle_id: c['oracle_id'], name: c['name']}}
    price_json = json_cards.map{|c| {oracle_id: c['oracle_id'], prices: c['prices']}}
    Card.upsert_all(
      shortened_cards
    )
    Rails.logger.info "Imported #{shortened_cards.count} cards"

    Rails.logger.info "Updating prices for cards"
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

  # TODO: add tasks to this namespace that do this with the scryfall api and not a fixture
end
