class ChallengeState
  include Ruby::Enum

  define :PROPOSED, 'proposed'
  define :ACCEPTED, 'accepted'
  define :DECLINED, 'declined'
  define :PLAYED, 'played'
end
