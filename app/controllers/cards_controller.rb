class CardsController < ApplicationController
  before_action :set_scryfall_client, only: :show

  def index
    @cards = Card.with_pscore_entries
    standard_cards = Card.with_format(:standard)
    pioneer_cards = Card.with_format(:pioneer)
    modern_cards = Card.with_format(:modern)
    pauper_cards = Card.with_format(:pauper)
    legacy_cards = Card.with_format(:legacy)

    @most_played_cards = {
      all: @cards.sort { |a, b| b.average_pscore <=> a.average_pscore }.take(10),
      standard: sort_for_format(:standard, standard_cards),
      pioneer: sort_for_format(:pioneer, pioneer_cards),
      modern: sort_for_format(:modern, modern_cards),
      pauper: sort_for_format(:pauper, pauper_cards),
      legacy: sort_for_format(:legacy, legacy_cards)
    }
  end

  # GET /cards/stonks
  def stonks
    @cards = Card.with_pscore_entries.sort do |a, b|
      b.overall_stonks <=> a.overall_stonks
    end

    @stonkiest_cards = @cards.take(10)
    @stinkiest_cards = @cards.reverse.take(10)
  end

  # GET /card/:id
  def show
    @card = Card.find(params[:id])
    @image_link = @scryfall_client.image_url(@card.name)
    @pscore_graph_data = prepare_pscore_graph_data(@card)
    @stonks_graph_data = prepare_stonks_graph_data(@card)
  end

  # POST /card/:query
  def search
    @query = params[:query]
    card = Card.find_by(name: @query)
    redirect_to card_path(card)
  end

  private

  def sort_for_format(format, cards)
    cards.sort do |a, b|
      b.format_pscore(format:) <=> a.format_pscore(format:)
    end.take(10)
  end

  def set_scryfall_client
    @scryfall_client = ScryfallApi::Client.new
  end

  def prepare_pscore_graph_data(card)
    all_format_pscore_data = []
    standard_data = []
    pioneer_data = []
    modern_data = []
    pauper_data = []
    legacy_data = []

    card.last_n_pscores(num: 30).map do |se|
      all_format_pscore_data << [se.created_at, se.aggregated_pscore.round(1)]
      standard_data << [se.created_at, se.pscore_of_format(format: :standard).round(1)]
      pioneer_data << [se.created_at, se.pscore_of_format(format: :pioneer).round(1)]
      modern_data << [se.created_at, se.pscore_of_format(format: :modern).round(1)]
      pauper_data << [se.created_at, se.pscore_of_format(format: :pauper).round(1)]
      legacy_data << [se.created_at, se.pscore_of_format(format: :legacy).round(1)]
    end

    graph_data = []

    graph_data << { name: 'Standard', data: standard_data } if standard_data.map(&:last).sum.positive?
    graph_data << { name: 'Pioneer', data: pioneer_data } if pioneer_data.map(&:last).sum.positive?
    graph_data << { name: 'Modern', data: modern_data } if modern_data.map(&:last).sum.positive?
    graph_data << { name: 'Pauper', data: pauper_data } if pauper_data.map(&:last).sum.positive?
    graph_data << { name: 'Legacy', data: legacy_data } if legacy_data.map(&:last).sum.positive?
    graph_data << { name: 'All formats', data: all_format_pscore_data }

    graph_data
  end

  def prepare_stonks_graph_data(card)
    # TODO
  end
end
