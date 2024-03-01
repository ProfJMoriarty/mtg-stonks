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
  self.primary_key = :oracle_id
  has_many :price_entries, dependent: :destroy
  has_many :pscore_entries, dependent: :destroy

  def stonks(format)
    # smth like this but with more data science
  end
end
