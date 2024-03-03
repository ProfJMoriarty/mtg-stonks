class CardsController < ApplicationController
  def index
    # only 100 # for ui testing
    @cards = Card.with_pscore_entries.take(100)
    standard_cards = Card.with_format(:standard)
    pioneer_cards = Card.with_format(:pioneer)
    modern_cards = Card.with_format(:modern)
    pauper_cards = Card.with_format(:pauper)
    legacy_cards = Card.with_format(:legacy)
    # most played cards across formats

    @most_played_cards = {
      all: @cards.sort { |a, b| b.rank <=> a.rank }.take(10),
      standard: sort_for_format(:standard, standard_cards),
      pioneer: sort_for_format(:pioneer, pioneer_cards),
      modern: sort_for_format(:modern, modern_cards),
      pauper: sort_for_format(:pauper, pauper_cards),
      legacy: sort_for_format(:legacy, legacy_cards)
    }
  end

  # GET /cards/stonks
  def stonks
    # only 100 # for ui testing
    @cards = Card.with_pscore_entries.take(100).sort do |a, b|
      b.overall_stonks <=> a.overall_stonks
    end
    # top risers and fallers

    @stonkiest_cards = @cards.take(10)
    @stinkiest_cards = @cards.reverse.take(10)
  end

  # GET /card/:id
  def show
    @card = Card.find(params[:id])
  end

  private

  def sort_for_format(format, cards)
    cards.sort do |a, b|
      b.format_pscore(format:) <=> a.format_pscore(format:)
    end.take(10)
  end
end
