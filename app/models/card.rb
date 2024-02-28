# == Schema Information
#
# Table name: cards
#
#  id                :bigint           not null, primary key
#  name              :string
#  oracle_id         :string
#  prices            :json
#  playability_index :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
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
end
