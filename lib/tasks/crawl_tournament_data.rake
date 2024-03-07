# frozen_string_literal: true

require 'selenium-webdriver'
require 'httparty'
require 'nokogiri'
require 'pry'

MTGO_BASE_URL = 'https://www.mtgo.com'
MTGO_DECKLISTS = "#{MTGO_BASE_URL}/decklists".freeze

FORMATS_TO_CRAWL = %w[Modern Pioneer Standard Pauper Legacy].freeze
BASIC_LAND_NAMES = %w[Plains Island Swamp Mountain Forest].freeze
# dummy tournament for debugging
# MTGO_TOURNAMENT_URL = "#{MTGO_BASE_URL}/standard-challenge-32-2024-02-2412615346".freeze

namespace :crawl do
  desc 'Import json bulk data'
  task :tournament_data, %i[y m d] => :environment do |_task, args|
    crawl_yesterday = false
    crawl_day = false
    crawl_month = false

    task_start_time = Time.now

    if args.count.zero?
      crawl_yesterday = true
      date_to_crawl = Date.today
    elsif args.count == 2
      crawl_month = true
    elsif args.count == 3
      crawl_day = true
      date_to_crawl = Date.new(args[:y].to_i, args[:m].to_i, args[:d].to_i)
    else
      Rails.logger.warn = 'Invalid params'
      exit 1
    end

    crawl_source = if crawl_yesterday
                     MTGO_DECKLISTS
                   else
                     month = args[:m].to_i < 10 ? "0#{args[:m]}" : args[:m]
                     "#{MTGO_DECKLISTS}/#{args[:y]}/#{month}"
                   end

    Rails.logger.info '=== Crawling for tournament data... ==='
    Rails.logger.info "Crawling tournaments from: #{crawl_source}"

    tournament_crawl_date = date_to_crawl unless crawl_month
    tournaments_to_crawl = []

    response = HTTParty.get(crawl_source)
    document = Nokogiri::HTML(response.body)
    document.css('.decklists-item > a').each do |tournament_dom_elem|
      tournament_url = tournament_dom_elem.attribute('href').value
      tournament_date_info = tournament_dom_elem.css('time').first.attribute('datetime').value
      tournament_date = Date.parse(tournament_date_info)

      next if (crawl_day || crawl_yesterday) && tournament_date != tournament_crawl_date
      next unless FORMATS_TO_CRAWL.map { |f| tournament_dom_elem.text.include? f }.any?

      tournament_format = FORMATS_TO_CRAWL.filter { |f| tournament_dom_elem.text.include? f }.first

      tournaments_to_crawl << [tournament_url, tournament_format, tournament_date]
    end

    Rails.logger.info "Found #{tournaments_to_crawl.count} tournaments."

    tournament_objects = []

    # Setup Selenium
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument('--headless')
    driver = Selenium::WebDriver.for(:chrome, options:)

    tournaments_to_crawl.each.with_index do |tournament, index|
      url, format, date = tournament
      start_time = Time.now
      Rails.logger.info "crawling tournament #{index + 1} of #{tournaments_to_crawl.size} at #{url}"
      tounrament_obj = crawl_tournament(url:, format: format.downcase.to_sym, driver:, date:)
      crawled_deck_count = tounrament_obj.decks.count
      crawled_cards_count = tounrament_obj.decks.map { |deck| deck.cards.count }.sum
      Rails.logger.info "crawled #{crawled_cards_count} uniqe cards from #{crawled_deck_count} decks in #{Time.now - start_time}s"
      tournament_objects << tounrament_obj

      sleep 1 # as to not get our IP banned
    end

    # close browser
    driver.quit

    tournament_objects.group_by(&:date).each do |date, tournaments|
      TournamentImporter::Importer.new(tournaments:, date:).import
    end

    total_decks = tournament_objects.map { |tournament| tournament.decks.count }.sum
    total_cards = tournament_objects.map { |tournament| tournament.decks.map { |deck| deck.cards.count }.sum }.sum
    Rails.logger.info "Imported #{tournament_objects.count} tournaments (#{total_decks} decks, #{total_cards} cards) in #{Time.now - task_start_time}s"
  end
end

def crawl_tournament(url:, format:, driver:, date:)
  tournament = TournamentImporter::Tournament.new(url:, format:, date:)

  driver.get "#{MTGO_BASE_URL}/#{url}"

  # Wait for the dynamic content to load
  wait = Selenium::WebDriver::Wait.new(timeout: 300) # Timeout after 5min
  begin
    wait.until { driver.find_element(css: '.decklist-category-columns') }
  rescue Selenium::WebDriver::Error::TimeoutError
    Rails.logger.warn 'Skipped because of timeout'
    return tournament
  end

  decklists_wrapper = driver.find_element(css: 'div#decklistDecks')
  crawled_decks = decklists_wrapper.find_elements(css: 'section.decklist')

  crawled_decks.each do |crawled_deck|
    deck = TournamentImporter::Deck.new

    # the decks are ordered by rank already, maybe add "deck-relevance" here?
    # a.decklist-card-link
    crawled_cards = crawled_deck.find_elements(css: 'a.decklist-card-link').map(&:text).filter { |c| !c.empty? }
    crawled_cards.each do |crawled_card|
      # split string into amount and card name
      text = crawled_card.split
      amount = text.first.to_i
      name = text[1..].join(' ')

      # exceptions
      name = name.gsub('"Name Sticker"', '_____') if name.include? '"Name Sticker"'
      name = name.gsub('/', ' // ') if name.include? '/'

      # add to hash unless its a basic land
      next if BASIC_LAND_NAMES.map { |basic| basic == name }.any?

      deck.cards << TournamentImporter::TournamentCard.new(name:, amount:)
    end

    tournament.decks << deck
  end

  tournament
end
