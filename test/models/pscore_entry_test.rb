# == Schema Information
#
# Table name: pscore_entries
#
#  id         :bigint           not null, primary key
#  standard   :float
#  legacy     :float
#  modern     :float
#  pauper     :float
#  pioneer    :float
#  card_id    :bigint
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'test_helper'

class PscoreEntryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
