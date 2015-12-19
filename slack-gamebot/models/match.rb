class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at']

  belongs_to :team, index: true
  field :scores, type: Array
  belongs_to :challenge, index: true
  before_create :calculate_elo!
  validate :validate_scores
  validates_presence_of :team
  validate :validate_teams

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  def to_s
    "#{winners.map(&:user_name).join(' and ')} #{score_verb} #{losers.map(&:user_name).join(' and ')}"
  end

  private

  def validate_teams
    teams = [team]
    teams << challenge.team if challenge
    teams.uniq!
    errors.add(:team, 'Match can only be recorded for the same team.') if teams.count != 1
  end

  def validate_scores
    return unless scores
    return if Score.valid?(scores)
    errors.add(:scores, 'Loser scores must come first.')
  end

  def score_verb
    return 'defeated' unless scores
    lose, win = Score.points(scores)
    ratio = lose.to_f / win
    if ratio > 0.9
      'narrowly defeated'
    elsif ratio > 0.4
      'defeated'
    else
      'crushed'
    end
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
