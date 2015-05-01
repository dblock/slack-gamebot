class Match
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :challenge

  has_and_belongs_to_many :winners, class_name: 'User', inverse_of: nil
  has_and_belongs_to_many :losers, class_name: 'User', inverse_of: nil

  def to_s
    "#{winners.map(&:user_name).join(' and ')} defeated #{losers.map(&:user_name).join(' and ')}"
  end
end
