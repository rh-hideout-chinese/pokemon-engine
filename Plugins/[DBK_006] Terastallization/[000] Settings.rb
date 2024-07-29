#===============================================================================
# Terastal Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  TERASTAL_GRAPHICS_PATH = "Graphics/Plugins/Terastallization/"
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether Terstallization functionality is available.
  #-----------------------------------------------------------------------------
  NO_TERASTALLIZE   = 69
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether the player's Tera Orb requires recharging.
  #-----------------------------------------------------------------------------
  TERA_ORB_ALWAYS_CHARGED = 70
  
  #-----------------------------------------------------------------------------
  # Switch used to determine if Pokemon should generate with random Tera types.
  #-----------------------------------------------------------------------------
  RANDOMIZED_TERA_TYPES = 71

  #-----------------------------------------------------------------------------
  # When true, plays the Terastallization animation whenever triggered.
  #-----------------------------------------------------------------------------
  SHOW_TERA_ANIM = true
  
  #-----------------------------------------------------------------------------
  # When true, displays the crystal pattern overlay on Terastallized Pokemon.
  #-----------------------------------------------------------------------------
  SHOW_TERA_OVERLAY = true
  
  #-----------------------------------------------------------------------------
  # Sets how the overlay pattern on Terastallized Pokemon animates.
  # The first entry in the array corresponds to X-axis movement.
  # The second entry in the array corresponds to Y-axis movement.
  #-----------------------------------------------------------------------------
  # X-Axis    Y-Axis
  # :none     :none 
  # :left     :up
  # :right    :down
  # :erratic  :erratic
  #-----------------------------------------------------------------------------
  TERASTAL_PATTERN_MOVEMENT = [:right, :erratic]
  
  #-----------------------------------------------------------------------------
  # When true, displays Tera type in the Summary.
  #-----------------------------------------------------------------------------
  SUMMARY_TERA_TYPES = true
  
  #-----------------------------------------------------------------------------
  # When true, displays Tera type in the PC Storage.
  #-----------------------------------------------------------------------------
  STORAGE_TERA_TYPES = true
  
  #-----------------------------------------------------------------------------
  # Sets the number of Tera Shards required to change a Pokemon's Tera type.
  #-----------------------------------------------------------------------------
  TERA_SHARDS_REQUIRED = 50
  
  #-----------------------------------------------------------------------------
  # Species that are blacklisted from being compatible with the move Tera Blast.
  #-----------------------------------------------------------------------------
  TERABLAST_BANLIST = [:MAGIKARP, :DITTO, :SMEARGLE, :UNOWN, :WOBBUFFET, :WYNAUT]
end