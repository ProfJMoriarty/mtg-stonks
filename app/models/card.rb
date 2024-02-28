# frozen_string_literal: true

# == Schema Information
#
# Table name: cards
#
#  id          :bigint           not null, primary key
#  name        :string
#  oracle_id   :string
#  prices      :json
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  playability :json
#
class Card < ApplicationRecord
  def usd
    prices['usd']
  end

  def eur
    prices['eur']
  end

  def tix
    prices['tix']
  end

  def stonks(format)
    # smth like this but with more data science
    eur / playability[format.to_s]
  end
end
