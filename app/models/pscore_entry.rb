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

  def aggregated_pscore
    standard_score = standard || 0.0
    pioneer_score = pioneer || 0.0
    modern_score = modern || 0.0
    pauper_score = pauper || 0.0
    legacy_score = legacy || 0.0
    all_scores = [standard_score, pioneer_score, modern_score, pauper_score, legacy_score].sort
    sum = all_scores.sum
    mean = sum / 5
    median = all_scores[3]

    (mean + median) / 2
  end

  def format_pscore(format:)
    read_attribute(format) || 0.0
  end
end
