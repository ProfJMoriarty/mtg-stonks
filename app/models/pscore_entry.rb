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
class PscoreEntry < ApplicationRecord
  belongs_to :card, foreign_key: :card_id
end
