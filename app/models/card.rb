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
  has_one :pscore_calculation

  scope :with_pscore_entries, -> { joins(:pscore_entries).distinct }
  scope :with_format, ->(format) { with_pscore_entries.where.not("pscore_entries.#{format}" => nil).distinct }

  # pscore_entries accessors

  def latest_pscores
    yesterday = Date.today - 1
    newest_score = pscore_entries.order(created_at: :desc).first
    return newest_score if newest_score.created_at == yesterday

    dummy_pscore_entry
  end

  def n_days_ago_pscore(num: 2)
    num = num.positive? ? num : 1
    today = Date.today
    n_days_ago = today - num
    n_days_old_entry = pscore_entries.where(created_at: n_days_ago.all_day).first
    return n_days_old_entry unless n_days_old_entry.nil?

    dummy_pscore_entry(date: n_days_ago)
  end

  def last_n_pscores(num: 7)
    num = num.positive? ? num : 1
    (1..num).map do |days_ago|
      n_days_ago_pscore(num: days_ago)
    end
  end

  # price accessors

  def latest_prices
    price_entries.order(created_at: :desc).first
  end

  def n_to_last_price(num: 2)
    num = num.positive? ? num : 1
    price_entries.order(created_at: :desc).take(num).last
  end

  def last_n_prices(num: 7)
    num = num.positive? ? num : 1
    price_entries.order(created_at: :desc).take(num)
  end

  # price trend calculation

  def currency_price_trend(currency:, num: 7)
    num = num.positive? ? num : 1
    old_price = n_to_last_price(num:).value_of_currency(currency:)
    newest_price = latest_prices.value_of_currency(currency:)
    newest_price - old_price
  end

  def overall_price_trend
    %i[eur usd tix].map do |currency|
      currency_price_trend(currency:)
    end.sum / 3
  end

  # stonks calculations

  def format_stonks(format:)
    avg_format_pscore(format:) * overall_price_trend
  end

  def overall_stonks
    overall_pscore_trend * overall_price_trend
  end

  private

  def dummy_pscore_entry(date: Date.today - 1)
    PscoreEntry.build(card_id: id, created_at: date, standard: 0.0, pioneer: 0.0, modern: 0.0, pauper: 0.0, legacy: 0.0)
  end
end
