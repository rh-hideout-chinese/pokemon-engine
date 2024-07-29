#===============================================================================
# Message types.
#===============================================================================
# Adds held descriptions to the list of message types. Renumber if necessary.
#-------------------------------------------------------------------------------
module MessageTypes
  HELD_ITEM_DESCRIPTIONS = 32
end

#===============================================================================
# Z-Move and Ultra Burst Settings.
#===============================================================================
module Settings
  #-----------------------------------------------------------------------------
  # Stores the path name for the graphics utilized by this plugin.
  #-----------------------------------------------------------------------------
  ZMOVE_GRAPHICS_PATH = "Graphics/Plugins/Z-Power/"

  #-----------------------------------------------------------------------------
  # Switch used to determine whether Z-Move functionality is available.
  #-----------------------------------------------------------------------------
  NO_ZMOVE = 64
  
  #-----------------------------------------------------------------------------
  # Switch used to determine whether Ultra Burst functionality is available.
  #-----------------------------------------------------------------------------
  NO_ULTRA_BURST = 65
  
  #-----------------------------------------------------------------------------
  # When true, plays the Z-Move animation whenever triggered.
  #-----------------------------------------------------------------------------
  SHOW_ZMOVE_ANIM = true
  
  #-----------------------------------------------------------------------------
  # When true, plays the Ultra Burst animation whenever triggered.
  #-----------------------------------------------------------------------------
  SHOW_ULTRA_ANIM = true
  
  #-----------------------------------------------------------------------------
  # Sets the name to be displayed for the Z-Crystal bag pocket.
  #-----------------------------------------------------------------------------
  ZCRYSTAL_BAG_POCKET_NAME = _INTL("Z-Crystals")
  
  #-----------------------------------------------------------------------------
  # Sets the bag pocket used for Z-Crystals. This adds a new bag slot by default.
  # YOU WILL NEED TO RECOMPILE AND CLEAR YOUR BAG WHENEVER YOU CHANGE THIS SETTING.
  #-----------------------------------------------------------------------------
  ZCRYSTAL_BAG_POCKET = 9
end