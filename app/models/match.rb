class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :challenge
  before_create :calculate_elo!

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  def to_s
    "#{winners.map(&:user_name).join(' and ')} defeated #{losers.map(&:user_name).join(' and ')}"
  end

  private

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
    end
  end
end
