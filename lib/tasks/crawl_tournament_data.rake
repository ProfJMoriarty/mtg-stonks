# frozen_string_literal: true

require 'selenium-webdriver'
require 'httparty'
require 'nokogiri'
require 'pry'

MTGO_BASE_URL = 'https://www.mtgo.com'
MTGO_DECKLISTS = "#{MTGO_BASE_URL}/decklists".freeze
FORMATS = %w[Modern Pioneer Standard Pauper Legacy].freeze
BASIC_LAND_NAMES = %w[Plains Island Swamp Mountain Forest].freeze
# dummy tournament for debugging
# MTGO_TOURNAMENT_URL = "#{MTGO_BASE_URL}/standard-challenge-32-2024-02-2412615346".freeze

namespace :crawl do
  desc 'Import json bulk data'
  task tournament_data: :environment do
    puts '=== Crawling for tournament data... ==='

    todays_day = DateTime.now.strftime('%d')
    puts "fetching todays (#{todays_day}) tournaments"
    todays_tournaments = []

    response = HTTParty.get(MTGO_DECKLISTS)
    document = Nokogiri::HTML(response.body)
    document.css('.decklists-item > a').each do |dt|
      dt_date_info = dt.css('time').first.attribute('datetime').value
      tournament_date = DateTime.parse(dt_date_info).strftime('%d')

      next unless tournament_date == todays_day
      next unless FORMATS.map { |f| dt.text.include? f }.any?

      todays_tournaments << dt if tournament_date == todays_day
    end

    todays_tournaments_metadata = todays_tournaments.map do |dt|
      tournament_format = FORMATS.map do |f|
        next unless dt.text.include? f

        f
      end.join

      {
        'format': tournament_format,
        'href': dt.attribute('href').value
      }
    end

    puts "found #{todays_tournaments_metadata.count} tournaments."

    all_of_todays_data = {}
    todays_tournaments_metadata.each do |tournament_metadata|
      tournament_format = tournament_metadata[:format]
      tournament_cards = crawl_tournament(tournament_metadata[:href])

      if all_of_todays_data[tournament_format].nil?
        # no tourney yet with that format
        all_of_todays_data[tournament_format] = tournament_cards
      else
        # merge same format tourneys
        merged_tournament_data = additive_merge(all_of_todays_data[tournament_format], tournament_cards)
        all_of_todays_data[tournament_format] = merged_tournament_data
      end

      sleep 3 # as to not get our IP banned
    end

    # well done

    pscore_data = calculate_pscore(all_of_todays_data.deep_symbolize_keys)
    import_pscore(pscore_data)
  end
end

def crawl_tournament(tournament_url)
  puts "crawling #{tournament_url}"

  # Setup Selenium
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  driver = Selenium::WebDriver.for(:chrome, options:)
  driver.get "#{MTGO_BASE_URL}/#{tournament_url}"

  # Wait for the dynamic content to load
  wait = Selenium::WebDriver::Wait.new(timeout: 60) # Timeout after 30 seconds
  wait.until { driver.find_element(css: 'button.decklist-action.decklist-download') }

  decklists_wrapper = driver.find_element(css: 'div#decklistDecks')
  scraped_decks = decklists_wrapper.find_elements(css: 'section.decklist')

  parsed_cards = {}

  scraped_decks.each do |scraped_deck|
    # the decks are ordered by rank already, maybe add "deck-relevance" here?

    # a.decklist-card-link
    scraped_cards = scraped_deck.find_elements(css: 'a.decklist-card-link').map(&:text).filter { |c| !c.empty? }
    scraped_cards.each do |scraped_card|
      # split string into amount and card name
      text = scraped_card.split
      amount = text.first.to_i
      card_name = text[1..].join(' ')

      # exceptions
      card_name = card_name.gsub('"Name Sticker"', '_____') if card_name.include? '"Name Sticker"'
      card_name = card_name.gsub('/', ' // ') if card_name.include? '/'

      # add to hash unless its a basic land
      next if BASIC_LAND_NAMES.map { |basic| basic == card_name }.any?

      parsed_cards[card_name] = parsed_cards[card_name].nil? ? amount : parsed_cards[card_name] + amount
    end
  end

  # close browser
  driver.quit

  parsed_cards
end

def calculate_pscore(data)
  pscore_data = {}

  data.each do |format, cards|
    cards.each do |card_name, amount|
      total_cards_of_format = cards.map { |_cn, card_count| card_count }.sum
      pscore = amount / total_cards_of_format.to_f

      if pscore_data[card_name.to_s].nil?
        pscore_data[card_name.to_s] = { format => pscore }
      else
        pscore_data[card_name.to_s].merge!({ format => pscore })
      end
    end
  end

  pscore_data
end

def import_pscore(score_data)
  puts "importing #{score_data.count} scores..."

  score_data.map do |card_name, scores|
    # card = Card.find_by(name: card_name)
    card = Card.where('name like ?', "%#{card_name}%").first
    standard = scores[:Standard]
    legacy = scores[:Legacy]
    pauper = scores[:Pauper]
    modern = scores[:Modern]
    pioneer = scores[:Pioneer]

    puts "#{card_name} not found!" if card.nil?
    next if card.nil?

    PscoreEntry.create(card:, standard:, legacy:, pauper:, modern:, pioneer:)
  end
end

def additive_merge(hash1, hash2)
  new_hash = {}
  hash1.each do |card_name, amount|
    new_hash[card_name] = new_hash[card_name].nil? ? amount : new_hash[card_name] + amount
  end

  hash2.each do |card_name, amount|
    new_hash[card_name] = new_hash[card_name].nil? ? amount : new_hash[card_name] + amount
  end

  new_hash
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/BlockLength
