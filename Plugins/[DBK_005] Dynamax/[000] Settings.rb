#===============================================================================
# Dynamax Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  DYNAMAX_GRAPHICS_PATH = "Graphics/Plugins/Dynamax/"
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether Dynamax functionality is available.
  #-----------------------------------------------------------------------------
  NO_DYNAMAX = 66
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether every map is considered a Power Spot.
  #-----------------------------------------------------------------------------
  DYNAMAX_ON_ANY_MAP = 67
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether the player may Dynamax in wild battles.
  #-----------------------------------------------------------------------------
  DYNAMAX_IN_WILD_BATTLES = 68
  
  #-----------------------------------------------------------------------------
  # The number of turns Dynamax lasts before expiring.
  #-----------------------------------------------------------------------------
  DYNAMAX_TURNS = 3
  
  #-----------------------------------------------------------------------------
  # Array of move types that are weakened when converted into Max Moves.
  #-----------------------------------------------------------------------------
  DYNAMAX_TYPES_TO_WEAKEN = [:FIGHTING, :POISON]
  
  #-----------------------------------------------------------------------------
  # When true, plays the Dynamax animation whenever triggered.
  #-----------------------------------------------------------------------------
  SHOW_DYNAMAX_ANIM = true
  
  #-----------------------------------------------------------------------------
  # When true, Dynamaxed Pokemon will have enlarged sprites and icons.
  #-----------------------------------------------------------------------------
  SHOW_DYNAMAX_SIZE = true
  
  #-----------------------------------------------------------------------------
  # When true, Dynamaxed Pokemon sprites and icons will have a red overlay.
  #-----------------------------------------------------------------------------
  SHOW_DYNAMAX_OVERLAY = true
  
  #-----------------------------------------------------------------------------
  # Sets how the overlay pattern on Dynamax Pokemon animates.
  # The first entry in the array corresponds to X-axis movement.
  # The second entry in the array corresponds to Y-axis movement.
  #-----------------------------------------------------------------------------
  # X-Axis    Y-Axis
  # :none     :none 
  # :left     :up
  # :right    :down
  # :erratic  :erratic
  #-----------------------------------------------------------------------------
  DYNAMAX_PATTERN_MOVEMENT = [:left, :none]
  
  #-----------------------------------------------------------------------------
  # When true, displays G-Max Factor icon in the PC Storage.
  #-----------------------------------------------------------------------------
  STORAGE_GMAX_FACTOR = true
end