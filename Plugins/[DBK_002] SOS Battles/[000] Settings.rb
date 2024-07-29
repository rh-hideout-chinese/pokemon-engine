#===============================================================================
# Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # The switch number used to enable wild Pokemon to begin using SOS calls.
  # All eligible wild Pokemon will be capable of SOS calls when turned on. 
  # When off, SOS calls will never occur unless turned on via a Battle Rule.
  #-----------------------------------------------------------------------------
  SOS_CALL_SWITCH = 62
  
  #-----------------------------------------------------------------------------
  # When true, wild Pokemon may only SOS call once per battle. Wild Pokemon will
  # make unlimited calls if set to false, or after an Adrenaline Orb is used.
  #-----------------------------------------------------------------------------
  LIMIT_SOS_CALLS_TO_ONE = true
  
  #-----------------------------------------------------------------------------
  # This may be used to increase the odds of shiny Pokemon appearing during an
  # SOS chain. The number set here multiplies the number of shiny rolls by that
  # number. Set to 1 by default for the normal SOS chain shiny rolls.
  #-----------------------------------------------------------------------------
  SOS_CHAIN_SHINY_MULTIPLIER = 100
end