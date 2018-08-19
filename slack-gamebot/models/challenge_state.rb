class ChallengeState
  include Ruby::Enum

  define :PROPOSED, 'proposed'
  define :ACCEPTED, 'accepted'
  define :DECLINED, 'declined'
  define :CANCELED, 'canceled'
  define :DRAWN, 'drawing'
  define :PLAYED, 'played'
end
