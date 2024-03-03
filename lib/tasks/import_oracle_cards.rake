# frozen_string_literal: true

require 'httparty'
require 'open-uri'

BATCH_SIZE = 2_000
FORMATS = %w[Modern Pioneer Standard Pauper Legacy].freeze

namespace :import do
  desc 'Import json bulk data'
  task bulk_data: :environment do
    Rails.logger.info '=== Importing from API ==='

    res = HTTParty.get('https://api.scryfall.com/bulk-data')
    dumps = JSON.parse(res.body)['data']
    file_path = dumps.filter { |d| d['type'] == 'oracle_cards' }.first['download_uri']

    file = File.read URI.open(file_path) # rubocop:disable Security/Open

    import_cards_and_prices_for(JSON.parse file)

  end

  desc 'Import json bulk data from file'
  task :file, [:file_path] => :environment do |_task, args|
    Rails.logger.info '=== Importing from json dump files ==='

    file = File.read args[:file_path]
    import_cards_and_prices_for(JSON.parse file)
  end

  def remove_non_legal_cards(json_cards)
    legal_cards = []
    json_cards.each do |card|
      legalities = []
      # add legality to array for each format for card
      FORMATS.each do |format|
        legalities << card['legalities'][format.to_s.downcase]
      end
      legalities.include?('legal') ? legal_cards << card : next
    end
    legal_cards
  end

  # Batching prices and inserting them in steps of 2000 entries
  def update_prices(shortened_prices)
    shortened_prices.each_slice(BATCH_SIZE) do |parsed_cards|
      price_count = 0
      card_prices = []
      parsed_cards.each do |parsed_card|
        card_obj = Card.find_by(oracle_id: parsed_card[:oracle_id])

        prices = parsed_card[:prices]
        card_prices << { card_id: card_obj.id, eur: prices['eur'], usd: prices['usd'], tix: prices['tix'] }
        price_count += 1
      end
      PriceEntry.insert_all(card_prices)
      Rails.logger.info "Imported prices for batch of #{price_count} cards"
    end
  end

  def update_cards(shortened_cards)
    shortened_cards.each do |shortened_card|
      Card.find_or_create_by(oracle_id: shortened_card[:oracle_id]) do |card|
        card.name = shortened_card[:name]
      end
    end
    Rails.logger.info "Imported #{shortened_cards.count} cards"
  end

  def import_cards_and_prices_for(json_cards)
    start_time = Time.now
    Rails.logger.info "Parsed #{json_cards.count} cards. Importing new ones..."

    # Validations
    # 1. remove all Tokens
    # 2. remove all non-legal cards for defined formats (this would also remove tokens since they are never "legal")
    json_cards = json_cards.select { |card| !card['type_line'].start_with?('Token') }
    json_cards = remove_non_legal_cards(json_cards)

    # Only use oracle_id and name
    shortened_cards = json_cards.map { |c| { oracle_id: c['oracle_id'], name: c['name'] } }

    # Only use oracle_id and prices for batch_insert
    shortened_prices = json_cards.map { |c| { oracle_id: c['oracle_id'], prices: c['prices'] } }

    update_cards(shortened_cards)

    Rails.logger.info 'Updating prices for cards'
    update_prices(shortened_prices)

    Rails.logger.info "Done in #{Time.now - start_time}s. Imported #{shortened_cards.count} new cards in total."
  end
end
