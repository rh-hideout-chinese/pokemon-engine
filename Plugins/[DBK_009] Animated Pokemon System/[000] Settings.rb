#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # The amount of zoom applied to the front sprites of all Pokemon. (1 for no scaling)
  #-----------------------------------------------------------------------------
  FRONT_BATTLER_SPRITE_SCALE = 2
  
  #-----------------------------------------------------------------------------
  # The amount of zoom applied to the back sprites of all Pokemon. (1 for no scaling)
  #-----------------------------------------------------------------------------
  BACK_BATTLER_SPRITE_SCALE = 3
  
  #-----------------------------------------------------------------------------
  # The base number of frames it takes to load each new frame of a sprite's animation.
  # Increase to make all sprites animate slower. Decrease to animate faster.
  #-----------------------------------------------------------------------------
  ANIMATION_FRAME_DELAY = 60
  
  #-----------------------------------------------------------------------------
  # Hides battler shadow sprites on the player's side when true.
  # This is false by default because the default battle UI will hide them anyway.
  #-----------------------------------------------------------------------------
  SHOW_PLAYER_SIDE_SHADOW_SPRITES = false
  
  #-----------------------------------------------------------------------------
  # When true, sprites will be constricted in the Summary/Storage/Pokedex UI's.
  #-----------------------------------------------------------------------------
  CONSTRICT_POKEMON_SPRITES = true
  
  #-----------------------------------------------------------------------------
  # Y-coordinate metrics for the Substitute doll's back and front sprites, respectively.
  #-----------------------------------------------------------------------------
  SUBSTITUTE_DOLL_METRICS = [36, 56]
end