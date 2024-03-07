# frozen_string_literal: true

module TournamentImporter
  class Importer
    attr_reader :cards_to_import

    def initialize(tournaments:, date:)
      @tournaments = tournaments
      @date = date
      @cards_to_import = parse_data
    end

    def parse_data
      Rails.logger.info 'parsing crawled data...'
      all_cards = []
      @tournaments.each do |tournament|
        tournament_cards = []
        tournament.decks.each do |deck|
          deck.cards.each do |card|
            card_in_all_cards = all_cards.filter { |c| c.name == card.name }&.first

            card_entry = if card_in_all_cards.nil?
                           new_card_entry = CardEntry.new(name: card.name)
                           new_card_entry
                         else
                           card_in_all_cards
                         end

            card_in_tournament_cards = tournament_cards.filter { |c| c.name == card.name }&.first

            if card_in_tournament_cards.nil?
              card_entry.update_deck_count(format: tournament.format, amount: tournament.decks.count)
              tournament_cards << card_entry
            end

            card_entry.update_format_count(format: tournament.format, amount: card.amount)
            all_cards << card_entry if card_in_all_cards.nil?
          end
        end
      end

      all_cards
    end

    def import
      Rails.logger.info "Updating #{@cards_to_import.count} unique cards with new scores..."
      start_time = Time.now
      @cards_to_import.each do |card|
        db_card = Card.find_by(name: card.name)

        db_card = Card.where('name like ?', "%#{card.name}%").first if db_card.nil?
        Rails.logger.warn "Card '#{card.name}' not found!" if db_card.nil?
        next if db_card.nil?

        PscoreEntry.create(
          card: db_card,
          standard: card.pscore(format: :standard),
          pioneer: card.pscore(format: :pioneer),
          modern: card.pscore(format: :modern),
          pauper: card.pscore(format: :pauper),
          legacy: card.pscore(format: :legacy),
          created_at: @date
        )
      end
      Rails.logger.info "Done in #{Time.now - start_time}s."
    end
  end

  class CardEntry
    attr_reader :name

    def initialize(name:)
      @name = name
      @standard_c_count = 0
      @standard_d_count = 0
      @pioneer_c_count = 0
      @pioneer_d_count = 0
      @modern_c_count = 0
      @modern_d_count = 0
      @pauper_c_count = 0
      @pauper_d_count = 0
      @legacy_c_count = 0
      @legacy_d_count = 0
    end

    def update_format_count(format:, amount:)
      instance_var = "@#{format}_c_count".to_sym
      instance_variable_set(instance_var, instance_variable_get(instance_var) + amount)
    end

    def update_deck_count(format:, amount:)
      instance_var = "@#{format}_d_count".to_sym
      instance_variable_set(instance_var, instance_variable_get(instance_var) + amount)
    end

    def pscore(format:)
      format_cards = "@#{format}_c_count".to_sym
      format_decks = "@#{format}_d_count".to_sym

      return 0.0 if instance_variable_get(format_decks).zero?

      pscore = instance_variable_get(format_cards) / (instance_variable_get(format_decks).to_f * 4.0)

      (pscore * 100).round(4)
    end
  end

  class Tournament
    attr_reader :url, :format, :date
    attr_accessor :decks

    def initialize(url:, format:, date:)
      @url = url
      @format = format
      @date = date
      @decks = []
    end
  end

  class Deck
    attr_accessor :cards

    def initialize
      @cards = []
    end
  end

  class TournamentCard
    attr_reader :name, :amount

    def initialize(name:, amount:)
      @name = name
      @amount = amount
    end
  end
end
