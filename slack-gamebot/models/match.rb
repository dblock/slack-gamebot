class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  SORT_ORDERS = ['created_at', '-created_at']

  belongs_to :team, index: true
  field :tied, type: Boolean, default: false
  field :resigned, type: Boolean, default: false
  field :scores, type: Array
  belongs_to :challenge, index: true
  before_create :calculate_elo!
  validate :validate_scores, unless: :tied?
  validate :validate_tied_scores, if: :tied?
  validate :validate_resigned_scores, if: :resigned?
  validate :validate_tied_resigned
  validates_presence_of :team
  validate :validate_teams

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  def scores?
    scores && scores.any?
  end

  def to_s
    if resigned?
      "#{losers.map(&:user_name).and} resigned against #{winners.map(&:user_name).and}"
    else
      [
        "#{winners.map(&:user_name).and} #{score_verb} #{losers.map(&:user_name).and}",
        scores ? "with #{Score.scores_to_string(scores)}" : nil
      ].compact.join(' ')
    end
  end

  private

  def validate_teams
    teams = [team]
    teams << challenge.team if challenge
    teams.uniq!
    errors.add(:team, 'Match can only be recorded for the same team.') if teams.count != 1
  end

  def validate_scores
    return unless scores && scores.any?
    errors.add(:scores, 'Loser scores must come first.') unless Score.valid?(scores)
  end

  def validate_tied_scores
    return unless scores && scores.any?
    errors.add(:scores, 'In a tie both sides must have the same number of points.') unless Score.tie?(scores)
  end

  def validate_resigned_scores
    return unless scores && scores.any?
    errors.add(:scores, 'Cannot score when resigning.')
  end

  def validate_tied_resigned
    errors.add(:tied, 'Cannot be tied and resigned.') if tied? && resigned?
  end

  def score_verb
    if tied?
      'tied with'
    elsif !scores
      'defeated'
    else
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
  end

  def calculate_elo!
    winners_elo = Elo.team_elo(winners)
    losers_elo = Elo.team_elo(losers)

    ratio = if winners_elo == losers_elo && tied?
              0 # no elo updates when tied and elo is equal
            elsif tied?
              0.5 # half the elo in a tie
            else
              1 # whole elo
            end

    winners.each do |winner|
      e = 100 - 1.0 / (1.0 + (10.0**((losers_elo - winner.elo) / 400.0))) * 100
      winner.tau += 0.5
      winner.elo += e * ratio * (Elo::DELTA_TAU**winner.tau)
      winner.save!
    end

    losers.each do |loser|
      e = 100 - 1.0 / (1.0 + (10.0**((loser.elo - winners_elo) / 400.0))) * 100
      loser.tau += 0.5
      loser.elo -= e * ratio * (Elo::DELTA_TAU**loser.tau)
      loser.save!
    end
  end
end
