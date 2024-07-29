#===============================================================================
# UI and visuals.
#===============================================================================

#-------------------------------------------------------------------------------
# Terastal sprite patterns.
#-------------------------------------------------------------------------------
class Sprite
  def apply_tera_pattern(type)
    return if !self.pattern.nil?
    self.zoom_x = 1 if self.zoom_x > 1
    self.zoom_y = 1 if self.zoom_y > 1
    path = Settings::TERASTAL_GRAPHICS_PATH + "Patterns/tera_pattern"
    type_path = path + "_" + type.to_s
    filename = (pbResolveBitmap(type_path)) ? type_path : path
    self.pattern = Bitmap.new(filename)
    self.pattern_opacity = 150
    self.pattern_type = :tera
  end

  def set_tera_pattern(pokemon, override = false)
    return if !pokemon.is_a?(Symbol) && pokemon&.shadowPokemon?
    return if !pokemon.is_a?(Symbol) && pokemon&.dynamax?
    return if !Settings::SHOW_TERA_OVERLAY
    if override || pokemon&.tera?
      apply_tera_pattern(pokemon.tera_type)
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end
  
  def set_tera_icon_pattern
    return if self.pokemon&.shadowPokemon?
    return if self.pokemon&.dynamax?
    return if !Settings::SHOW_TERA_OVERLAY
    if self.pokemon&.tera?
      apply_tera_pattern(self.pokemon.tera_type)
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end
  
  def update_tera_pattern
    return if self.pattern_type != :tera
    if (System.uptime / 0.05).to_i % 2 == 0
      case Settings::TERASTAL_PATTERN_MOVEMENT[0]
      when :left    then self.pattern_scroll_x -= 1 
      when :right   then self.pattern_scroll_x += 1
      when :erratic then self.pattern_scroll_x += rand(-5..5) 
      end
      case Settings::TERASTAL_PATTERN_MOVEMENT[1]
      when :up      then self.pattern_scroll_y -= 1 
      when :down    then self.pattern_scroll_y += 1
      when :erratic then self.pattern_scroll_y += rand(-5..5)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compatibility with other plugins that add sprite patterns.
  #-----------------------------------------------------------------------------
  alias tera_set_plugin_pattern set_plugin_pattern
  def set_plugin_pattern(pokemon, override = false)
    tera_set_plugin_pattern(pokemon, override)
    set_tera_pattern(pokemon, override)
  end
  
  alias tera_set_plugin_icon_pattern set_plugin_icon_pattern
  def set_plugin_icon_pattern
    tera_set_plugin_icon_pattern
    set_tera_icon_pattern
  end
  
  alias tera_update_plugin_pattern update_plugin_pattern
  def update_plugin_pattern
    tera_update_plugin_pattern
    update_tera_pattern
  end
end

#-------------------------------------------------------------------------------
# For displaying Tera types in various UI's.
#-------------------------------------------------------------------------------
def pbDisplayTeraType(pokemon, overlay, xpos, ypos, override = false)
  return if !override && !pokemon.tera_type
  type_number = GameData::Type.get(pokemon.display_tera_type).icon_position
  tera_rect = Rect.new(0, type_number * 32, 32, 32)
  terabitmap = AnimatedBitmap.new(_INTL(Settings::TERASTAL_GRAPHICS_PATH + "tera_types"))
  overlay.blt(xpos, ypos, terabitmap.bitmap, tera_rect)
end

class PokemonStorageScene
  alias tera_pbUpdateOverlay pbUpdateOverlay
  def pbUpdateOverlay(selection, party = nil)
    tera_pbUpdateOverlay(selection, party)
    return if !Settings::STORAGE_TERA_TYPES
    if @sprites["pokemon"].visible
      if !@sprites["plugin_overlay"]
        @sprites["plugin_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @boxsidesviewport)
      end
      plugin_overlay = @sprites["plugin_overlay"].bitmap
      if @screen.pbHeldPokemon
        pokemon = @screen.pbHeldPokemon
      elsif selection >= 0
        pokemon = (party) ? party[selection] : @storage[@storage.currentBox, selection]
      end
      pbDisplayTeraType(pokemon, plugin_overlay, 8, 164)      
    end
  end
end

class PokemonSummary_Scene
  alias tera_drawPageOne drawPageOne
  def drawPageOne
    tera_drawPageOne
    return if !Settings::SUMMARY_TERA_TYPES
    overlay = @sprites["overlay"].bitmap
    coords = (PluginManager.installed?("BW Summary Screen")) ? [122, 129] : [330, 143]
    pbDisplayTeraType(@pokemon, overlay, coords[0], coords[1])
  end
end