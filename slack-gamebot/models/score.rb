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

  # draw scores?
  def self.tie?(scores)
    points = Score.points(scores)
    points[0] == points[1]
  end

  # parse scores from a string
  def self.parse(expression)
    return unless expression

    scores = []
    expression.split(/[\s,.]/).reject(&:blank?).each do |pair|
      scores << check(pair)
    end
    scores
  end

  def self.check(pair)
    pair_n = if pair.include?(':')
               pair.split(':') if pair.include?(':')
             elsif pair.include?('-')
               pair.split('-')
             elsif pair.include?(',')
               pair.split(',')
             end
    raise SlackGamebot::Error, "Invalid score: #{pair}." unless pair_n && pair_n.length == 2

    pair_n.map do |points|
      points = Integer(points)
      raise SlackGamebot::Error, 'points must be greater or equal to zero' if points < 0

      points
    rescue StandardError => e
      raise SlackGamebot::Error, "Invalid score: #{pair}, #{e}."
    end
  end

  def self.scores_to_string(scores)
    [
      scores.count > 1 ? 'the scores of' : 'the score of',
      scores.map do |score|
        "#{score[1]}:#{score[0]}"
      end
    ].flatten.join(' ')
  end
end
