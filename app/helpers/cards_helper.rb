# frozen_string_literal: true

module CardsHelper
  def pricetag(price)
    return '-' if price.nil?

    price.to_s
  end

  def price_delta_tag(delta)
    return '-' if delta.nil?
    return '±0.0' if delta.round(1) == 0.0

    "#{'+' if delta.round(1).positive?}#{delta.round(1)}"
  end

  def scoretag(score)
    return '-' if score.nil?

    score.round(1).to_s
  end

  def score_delta_tag(delta)
    return '-' if delta.nil?
    return '±0.0' if delta.round(1) == 0.0

    "#{'+' if delta.round(1).positive?}#{delta.round(1)}"
  end

  def delta_color(delta)
    return if ['-', '±0.0'].include?(delta.to_s)

    delta.to_s.start_with?('-') ? 'stink' : 'stonk'
  end
end
