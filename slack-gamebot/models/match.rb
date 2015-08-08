class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at']

  field :scores, type: Array
  belongs_to :challenge, index: true
  before_create :calculate_elo!
  validate :validate_scores

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  def to_s
    "#{winners.map(&:user_name).join(' and ')} #{score_verb} #{losers.map(&:user_name).join(' and ')}"
  end

  private

  def validate_scores
    return unless scores
    return if scores.select { |score| score[0] < score[1] }.count > scores.count / 2
    errors.add(:scores, 'Loser scores must come first.')
  end

  def score_verb
    return 'defeated' unless scores
    lose, win = score_points
    ratio = lose.to_f / win
    if ratio > 0.9
      'narrowly defeated'
    elsif ratio > 0.4
      'defeated'
    else
      'crushed'
    end
  end

  def score_points
    winning_score = 0
    losing_score = 0
    scores.each do |score|
      losing_score += score[0]
      winning_score += score[1]
    end
    [losing_score, winning_score]
  end

  def calculate_elo!
    winners_elo = Elo.team_elo(winners)
    losers_elo = Elo.team_elo(losers)

    winners.each do |winner|
      e = 100 - 1.0 / (1.0 + (10.0**((losers_elo - winner.elo) / 400.0))) * 100
      winner.tau += 0.5
      winner.elo += e * (Elo::DELTA_TAU**winner.tau)
      winner.save!
    end

    losers.each do |loser|
      e = 100 - 1.0 / (1.0 + (10.0**((loser.elo - winners_elo) / 400.0))) * 100
      loser.tau += 0.5
      loser.elo -= e * (Elo::DELTA_TAU**loser.tau)
      loser.save!
    end
  end
end
