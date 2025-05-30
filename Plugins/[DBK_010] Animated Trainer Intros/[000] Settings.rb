#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # The amount of zoom applied to the front sprites of all trainers. (1 for no scaling)
  #-----------------------------------------------------------------------------
  TRAINER_SPRITE_SCALE = 2
  
  #-----------------------------------------------------------------------------
  # The amount of time (in seconds) trainers will take to complete their animations.
  # Increase this number to slow them down; decrease to speed them up.
  # This should always be set to a float number (ex. 2.0, not just "2")
  #-----------------------------------------------------------------------------
  TRAINER_ANIMATION_SPEED = 1.5
end