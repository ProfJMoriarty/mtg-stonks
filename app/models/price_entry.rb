# == Schema Information
#
# Table name: price_entries
#
#  id         :bigint           not null, primary key
#  usd        :float
#  eur        :float
#  tix        :float
#  card_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class PriceEntry < ApplicationRecord
  belongs_to :card
end
