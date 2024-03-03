# frozen_string_literal: true

# == Schema Information
#
# Table name: cards
#
#  id         :bigint           not null, primary key
#  name       :string
#  oracle_id  :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Card < ApplicationRecord
  has_many :price_entries, dependent: :destroy
  has_many :pscore_entries, dependent: :destroy

  scope :with_pscore_entries, -> { joins(:pscore_entries).distinct }
  scope :with_format, ->(format) { with_pscore_entries.where.not("pscore_entries.#{format}" => nil).distinct }

  def rank
    scores = last_n_pscores(num: 10)
    scores.map(&:aggregated_pscore).sum / scores.size
  end

  def latest_pscores
    pscore_entries.order(created_at: :desc).first
  end

  def n_to_last_pscore(num: 2)
    num = num.positive? ? num : 1
    pscore_entries.order(created_at: :desc).take(num).last
  end

  def last_n_pscores(num: 5)
    num = num.positive? ? num : 1
    pscore_entries.order(created_at: :desc).take(num)
  end

  def format_pscore(format:)
    scores = last_n_pscores(num: 10)
    scores.map { |score| score.pscore_of_format(format:) }.sum / scores.size
  end

  def format_pscore_trend(format:, num: 5)
    num = num.positive? ? num : 1
    old_score = n_to_last_pscore(num:).read_attribute(format) || 0.0
    newest_score = latest_pscores.read_attribute(format) || 0.0
    old_score - newest_score
  end

  def overall_pscore_trend
    %i[standard pioneer modern pauper legacy].map do |format|
      format_pscore_trend(format:)
    end.sum / 5
  end

  def latest_prices
    price_entries.order(created_at: :desc).first
  end

  def n_to_last_price(num: 2)
    num = num.positive? ? num : 1
    price_entries.order(created_at: :desc).take(num).last
  end

  def last_n_prices(num: 5)
    num = num.positive? ? num : 1
    price_entries.order(created_at: :desc).take(num)
  end

  def currency_price_trend(currency:, num: 5)
    num = num.positive? ? num : 1
    old_price = n_to_last_price(num:).read_attribute(currency) || 0.0
    newest_price = latest_prices.read_attribute(currency) || 0.0
    old_price - newest_price
  end

  def overall_price_trend
    %i[eur usd tix].map do |currency|
      currency_price_trend(currency:)
    end.sum / 3
  end

  def format_stonks(format:, num: 5)
    num = num.positive? ? num : 1
    return 0.0 if overall_price_trend.zero?

    format_pscore_trend(format:, num:) * overall_price_trend
  end

  def format_stonks_trend(format:, num: 5); end

  # stonk score over all formats
  def overall_stonks
    return 0.0 if overall_price_trend.zero?

    overall_pscore_trend * overall_price_trend
  end
end
