# frozen_string_literal: true

# == Schema Information
#
# Table name: pscore_calculations
#
#  id               :bigint           not null, primary key
#  overall7         :float
#  overall7_trend   :float
#  overall30        :float
#  overall30_trend  :float
#  standard7        :float
#  standard7_trend  :float
#  standard30       :float
#  standard30_trend :float
#  pioneer7         :float
#  pioneer7_trend   :float
#  pioneer30        :float
#  pioneer30_trend  :float
#  modern7          :float
#  modern7_trend    :float
#  modern30         :float
#  modern30_trend   :float
#  pauper7          :float
#  pauper7_trend    :float
#  pauper30         :float
#  pauper30_trend   :float
#  legacy7          :float
#  legacy7_trend    :float
#  legacy30         :float
#  legacy30_trend   :float
#  card_id          :bigint
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class PscoreCalculation < ApplicationRecord
  belongs_to :card, foreign_key: :card_id

  def pscore_avg7_of_format(format: :overall)
    read_attribute("#{format}7")
  end

  def pscore_avg7_trend_of_format(format: :overall)
    read_attribute("#{format}7_trend")
  end

  def pscore_avg30_of_format(format: :overall)
    read_attribute("#{format}30")
  end

  def pscore_avg30_trend_of_format(format: :overall)
    read_attribute("#{format}30_trend")
  end
end
