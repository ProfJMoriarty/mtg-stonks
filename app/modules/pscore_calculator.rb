# frozen_string_literal: true

module PscoreCalculator
  class Calculator
    def initialize; end

    def calculate
      start_time = Time.now
      all_cards_with_pscore_entries = Card.with_pscore_entries
      Rails.logger.info "Calculating pscores for #{all_cards_with_pscore_entries.count} cards..."
      all_cards_with_pscore_entries.each_slice(500) do |sliced_cards|
        pscore_calculations = []
        sliced_cards.each do |card|
          pscore_calculations << {
            card_id: card.id,
            overall7: avg_pscore(card:),
            overall7_trend: avg_pscore_trend(card:),
            overall30: avg_pscore(card:, num: 30),
            overall30_trend: avg_pscore_trend(card:, num: 30),
            standard7: avg_pscore(card:, format: :standard),
            standard7_trend: avg_pscore_trend(card:, format: :standard),
            standard30: avg_pscore(card:, format: :standard, num: 30),
            standard30_trend: avg_pscore_trend(card:, format: :standard, num: 30),
            pioneer7: avg_pscore(card:, format: :pioneer),
            pioneer7_trend: avg_pscore_trend(card:, format: :pioneer),
            pioneer30: avg_pscore(card:, format: :pioneer, num: 30),
            pioneer30_trend: avg_pscore_trend(card:, format: :pioneer, num: 30),
            modern7: avg_pscore(card:, format: :modern),
            modern7_trend: avg_pscore_trend(card:, format: :modern),
            modern30: avg_pscore(card:, format: :modern, num: 30),
            modern30_trend: avg_pscore_trend(card:, format: :modern, num: 30),
            pauper7: avg_pscore(card:, format: :pauper),
            pauper7_trend: avg_pscore_trend(card:, format: :pauper),
            pauper30: avg_pscore(card:, format: :pauper, num: 30),
            pauper30_trend: avg_pscore_trend(card:, format: :pauper, num: 30),
            legacy7: avg_pscore(card:, format: :legacy),
            legacy7_trend: avg_pscore_trend(card:, format: :legacy),
            legacy30: avg_pscore(card:, format: :legacy, num: 30),
            legacy30_trend: avg_pscore_trend(card:, format: :legacy, num: 30),
            created_at: card.latest_pscores.created_at
          }
        end
        PscoreCalculation.insert_all(pscore_calculations)
        Rails.logger.info "calculated pscores for batch of #{pscore_calculations.count} cards"
      end

      Rails.logger.info "Done in #{Time.now - start_time}s"
    end

    private

    def avg_pscore(card:, format: :all, num: 7)
      scores = card.last_n_pscores(num:)
      return scores.map(&:aggregated_pscore).sum / scores.size if format == :all

      scores.map { |score| score.pscore_of_format(format:) }.sum / scores.size
    end

    def avg_pscore_trend(card:, format: :all, num: 7)
      num = num.positive? ? num : 1
      newest_score = card.latest_pscores&.pscore_of_format(format:)
      old_score = if format == :all
                    card.n_days_ago_pscore(num:)&.aggregated_pscore
                  else
                    card.n_days_ago_pscore(num:)&.pscore_of_format(format:)
                  end
      newest_score - old_score
    end
  end
end
