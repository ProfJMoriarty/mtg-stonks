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
require 'test_helper'

class PriceEntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
