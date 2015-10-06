module Score
  # returns loser, winner points
  def self.points(scores)
    winning = 0
    losing = 0
    scores.each do |score|
      losing += score[0]
      winning += score[1]
    end
    [losing, winning]
  end

  # loser scores first
  def self.valid?(scores)
    scores.count { |score| score[0] < score[1] } > scores.count / 2
  end

  # parse scores from a string
  def self.parse(expression)
    return unless expression
    scores = []
    expression.split.reject(&:blank?).each do |pair|
      pair_n = pair.split(':')
      fail "Invalid score: #{pair}." if pair_n.length != 2
      pair_n = pair_n.map do |points|
        begin
          points = Integer(points)
          fail 'points must be greater or equal to zero' if points < 0
          points
        rescue StandardError => e
          raise "Invalid score: #{pair}, #{e}."
        end
      end
      scores << pair_n
    end
    scores
  end
end
