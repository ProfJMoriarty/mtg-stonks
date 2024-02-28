namespace :import do
  desc 'Import json bulk data'
  task bulk_data: :environment do
    puts '=== Importing from json dump ==='
    file = File.read 'db/scryfall-test-data/test-dump.json'
    # TODO: Loading the whole ~ 145MB into mem is a bad idea, find smth else.
    cards = JSON.parse file

    puts "Parsed #{cards.count} cards. Importing new ones..."
    start_time = Time.now

    new_cards = 0
    cards.each do |card|
      # Also very slow... ~130s for no new cards, ~155s for all new cards.
      Card.where(oracle_id: card['oracle_id']).first_or_create do |nc|
        nc.name = card['name']
        nc.prices = card['prices']
        new_cards += 1
      end
    end

    puts "Done in #{Time.now - start_time}s. Imported #{new_cards} new cards."
  end

  # TODO: add tasks to this namespace that do this with the scryfall api and not a fixture
end
