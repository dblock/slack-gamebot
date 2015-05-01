class ChallengeState
  include Ruby::Enum

  define :PROPOSED, 'proposed'
  define :ACCEPTED, 'accepted'
  define :DECLINED, 'declined'
  define :CANCELED, 'canceled'
  define :PLAYED, 'played'
end
