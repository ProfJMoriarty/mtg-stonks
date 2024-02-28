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
require "test_helper"

class CardTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
