################################################################################
#
# Dynamax sprites.
#
################################################################################

#-------------------------------------------------------------------------------
# Dynamax sprite patterns.
#-------------------------------------------------------------------------------
class Sprite
  def apply_dynamax_pattern(species)
    return if !self.pattern.nil?
    path = Settings::DYNAMAX_GRAPHICS_PATH + "Patterns/"
    species_path = path + species.to_s
    filename = (pbResolveBitmap(species_path)) ? species_path : path + "dynamax"
    self.pattern = Bitmap.new(filename)
    self.pattern_opacity = 150
    self.pattern_type = :dynamax
  end

  def set_dynamax_pattern(pokemon, override = false)
    return if !pokemon.is_a?(Symbol) && pokemon&.shadowPokemon?
    return if !pokemon.is_a?(Symbol) && pokemon&.tera?
    if override || pokemon&.dynamax?
      if Settings::SHOW_DYNAMAX_SIZE
        self.zoom_x = self.zoom_y = 1.5
      end
      if Settings::SHOW_DYNAMAX_OVERLAY
        if pokemon.is_a?(Battle::Battler)
          pokemon = pokemon.visiblePokemon
        end
        if pokemon.is_a?(Pokemon)
          species = pokemon.species
        else
          species = GameData::Species.get(pokemon).species
        end
        apply_dynamax_pattern(species)
      end
    else
      clear_dynamax_pattern
    end
  end
  
  def set_dynamax_icon_pattern
    return if !self.pokemon
    return if self.pokemon.shadowPokemon?
    return if self.pokemon.tera?
    if self.pokemon.dynamax?
      if Settings::SHOW_DYNAMAX_SIZE && self.bitmap.height <= 64
        self.zoom_x = self.zoom_y = 1.5
      else
        self.zoom_x = self.zoom_y = 1
      end
      return if !Settings::SHOW_DYNAMAX_OVERLAY
      apply_dynamax_pattern(self.pokemon.species)
    else
      clear_dynamax_pattern
    end
  end
  
  def clear_dynamax_pattern
    self.zoom_x = 1 if self.zoom_x > 1
    self.zoom_y = 1 if self.zoom_y > 1
    self.pattern = nil
    self.pattern_type = nil
  end
  
  def update_dynamax_pattern
    return if self.pattern_type != :dynamax
    if (System.uptime / 0.05).to_i % 2 == 0
      case Settings::DYNAMAX_PATTERN_MOVEMENT[0]
      when :left    then self.pattern_scroll_x -= 1 
      when :right   then self.pattern_scroll_x += 1
      when :erratic then self.pattern_scroll_x += rand(-5..5) 
      end
      case Settings::DYNAMAX_PATTERN_MOVEMENT[1]
      when :up      then self.pattern_scroll_y -= 1 
      when :down    then self.pattern_scroll_y += 1
      when :erratic then self.pattern_scroll_y += rand(-5..5)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Compatibility with other plugins that add sprite patterns.
  #-----------------------------------------------------------------------------
  alias dynamax_set_plugin_pattern set_plugin_pattern
  def set_plugin_pattern(pokemon, override = false)
    dynamax_set_plugin_pattern(pokemon, override)
    set_dynamax_pattern(pokemon, override)
  end
  
  alias dynamax_set_plugin_icon_pattern set_plugin_icon_pattern
  def set_plugin_icon_pattern
    dynamax_set_plugin_icon_pattern
	set_dynamax_icon_pattern
  end
  
  alias dynamax_update_plugin_pattern update_plugin_pattern
  def update_plugin_pattern
    dynamax_update_plugin_pattern
	update_dynamax_pattern
  end
end


################################################################################
#
# Changes to UI screens.
#
################################################################################

#-------------------------------------------------------------------------------
# For displaying G-Max Factor in various UI's.
#-------------------------------------------------------------------------------
def pbDisplayGmaxFactor(pokemon, overlay, xpos, ypos)
  return if !pokemon.gmax_factor?
  summaryBW = PluginManager.installed?("BW Party Screen")
  path = (summaryBW) ? "Graphics/Pictures/Summary/gfactor" : Settings::DYNAMAX_GRAPHICS_PATH + "gmax_factor"
  pbDrawImagePositions(overlay, [ [path, xpos, ypos] ])
end

#-------------------------------------------------------------------------------
# Pokemon Storage UI.
#-------------------------------------------------------------------------------
# Adds G-Max Factor display.
#-------------------------------------------------------------------------------
class PokemonStorageScene
  alias dynamax_pbUpdateOverlay pbUpdateOverlay
  def pbUpdateOverlay(selection, party = nil)
    dynamax_pbUpdateOverlay(selection, party)
    return if !Settings::STORAGE_GMAX_FACTOR
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
      pbDisplayGmaxFactor(pokemon, plugin_overlay, 8, 52)
    end
  end
end

#-------------------------------------------------------------------------------
# Pokemon Summary UI.
#-------------------------------------------------------------------------------
# Adds G-Max Factor display.
# Adds Dynamax meter display.
# Clears Dynamax properties from sprites/icons.
#-------------------------------------------------------------------------------
class PokemonSummary_Scene
  alias dynamax_drawPage drawPage
  def drawPage(page)
    if !@sprites["dynamax_overlay"]
      @sprites["dynamax_overlay"] = BitmapSprite.new(Graphics.width, Graphics.height, @viewport)
    else
      @sprites["dynamax_overlay"].bitmap.clear
    end
    dynamax_drawPage(page)
    if @pokemon.dynamax?
      @sprites["pokemon"].clear_dynamax_pattern
      @sprites["pokeicon"].clear_dynamax_pattern
    end
    overlay = @sprites["overlay"].bitmap
    coords = (PluginManager.installed?("BW Summary Screen")) ? [454, 82] : [88, 95]
    pbDisplayGmaxFactor(@pokemon, overlay, coords[0], coords[1])
  end
  
  alias dynamax_drawPageTwo drawPageTwo
  def drawPageTwo
    if PluginManager.installed?("BW Summary Screen")
      if @pokemon.dynamax_able? && !$game_switches[Settings::NO_DYNAMAX]
        path = "Graphics/Pictures/Summary/"
        meter = (SUMMARY_B2W2_STYLE) ? "overlay_dynamax_B2W2" : "overlay_dynamax"
        xpos = Graphics.width - 262
        imagepos = [[sprintf(path + meter), xpos, 322]]
        overlay = @sprites["dynamax_overlay"].bitmap
        pbSetSmallFont(overlay)
        pbDrawImagePositions(overlay, imagepos)
        dlevel = @pokemon.dynamax_lvl
        levels = AnimatedBitmap.new(_INTL(path + "dynamax_bar"))
        overlay.blt(xpos + 82, 352, levels.bitmap, Rect.new(0, 0, dlevel * 16, 14))
        pbDrawTextPositions(overlay, [ [_INTL("Dynamax Lv."), Graphics.width - 102, 324, 2, Color.new(255, 255, 255), Color.new(123, 123, 123)] ])
      end
    end
    dynamax_drawPageTwo
  end
  
  alias dynamax_drawPageThree drawPageThree
  def drawPageThree
    if !PluginManager.installed?("BW Summary Screen")
      if @pokemon.dynamax_able? && !$game_switches[Settings::NO_DYNAMAX]
        imagepos = [[sprintf(Settings::DYNAMAX_GRAPHICS_PATH + "dynamax_meter"), 56, 308]]
        overlay = @sprites["dynamax_overlay"].bitmap
        pbDrawImagePositions(overlay, imagepos)
        dlevel = @pokemon.dynamax_lvl
        levels = AnimatedBitmap.new(_INTL(Settings::DYNAMAX_GRAPHICS_PATH + "dynamax_levels"))
        overlay.blt(69, 325, levels.bitmap, Rect.new(0, 0, dlevel * 12, 21))
      end
    end
    dynamax_drawPageThree
  end
  
  alias dynamax_drawSelectedMove drawSelectedMove
  def drawSelectedMove(move_to_learn, selected_move)
    dynamax_drawSelectedMove(move_to_learn, selected_move)
    @sprites["pokeicon"].clear_dynamax_pattern
  end
end

#-------------------------------------------------------------------------------
# Pokedex UI.
#-------------------------------------------------------------------------------
# Displays weight as "????.?" for Gigantamax forms.
#-------------------------------------------------------------------------------
class PokemonPokedexInfo_Scene
  def drawPageInfo
    @sprites["infosprite"].visible = true
    @sprites["background"].setBitmap(_INTL("Graphics/UI/Pokedex/bg_info"))
    overlay = @sprites["overlay"].bitmap
    base   = Color.new(88, 88, 80)
    shadow = Color.new(168, 184, 184)
    imagepos = []
    imagepos.push([_INTL("Graphics/UI/Pokedex/overlay_info"), 0, 0]) if @brief
    species_data = GameData::Species.get_species_form(@species, @form)
    indexText = "???"
    if @dexlist[@index][:number] > 0
      indexNumber = @dexlist[@index][:number]
      indexNumber -= 1 if @dexlist[@index][:shift]
      indexText = sprintf("%03d", indexNumber)
    end
    textpos = [
      [_INTL("{1}{2} {3}", indexText, " ", species_data.name),
       246, 48, :left, Color.new(248, 248, 248), Color.black]
    ]
    if @show_battled_count
      textpos.push([_INTL("Number Battled"), 314, 164, :left, base, shadow])
      textpos.push([$player.pokedex.battled_count(@species).to_s, 452, 196, :right, base, shadow])
    else
      textpos.push([_INTL("Height"), 314, 164, :left, base, shadow])
      textpos.push([_INTL("Weight"), 314, 196, :left, base, shadow])
    end
    if $player.owned?(@species)
      textpos.push([_INTL("{1} Pokémon", species_data.category), 246, 80, :left, base, shadow])
      if !@show_battled_count
        height = species_data.height
        weight = species_data.weight
        if System.user_language[3..4] == "US"
          inches = (height / 0.254).round
          pounds = (weight / 0.45359).round
          textpos.push([_ISPRINTF("{1:d}'{2:02d}\"", inches / 12, inches % 12), 460, 164, :right, base, shadow])
          if species_data.dynamax_form?
            textpos.push([_INTL("????.? lbs."), 494, 196, :right, base, shadow])
          else
            textpos.push([_ISPRINTF("{1:4.1f} lbs.", pounds / 10.0), 494, 196, :right, base, shadow])
          end
        else
          textpos.push([_ISPRINTF("{1:.1f} m", height / 10.0), 470, 164, :right, base, shadow])
          if species_data.dynamax_form?
            textpos.push([_INTL("????.? kg"), 482, 196, :right, base, shadow])
          else
            textpos.push([_ISPRINTF("{1:.1f} kg", weight / 10.0), 482, 196, :right, base, shadow])
          end
        end
      end
      drawTextEx(overlay, 40, 246, Graphics.width - 80, 4,
                 species_data.pokedex_entry, base, shadow)
      pbDisplayFootprint(overlay)
      imagepos.push(["Graphics/UI/Pokedex/icon_own", 212, 44])
      species_data.types.each_with_index do |type, i|
        type_number = GameData::Type.get(type).icon_position
        type_rect = Rect.new(0, type_number * 32, 96, 32)
        overlay.blt(296 + (100 * i), 120, @typebitmap.bitmap, type_rect)
      end
    else
      textpos.push([_INTL("????? Pokémon"), 246, 80, :left, base, shadow])
      if !@show_battled_count
        if System.user_language[3..4] == "US"
          textpos.push([_INTL("???'??\""), 460, 164, :right, base, shadow])
          textpos.push([_INTL("????.? lbs."), 494, 196, :right, base, shadow])
        else
          textpos.push([_INTL("????.? m"), 470, 164, :right, base, shadow])
          textpos.push([_INTL("????.? kg"), 482, 196, :right, base, shadow])
        end
      end
    end
    pbDrawTextPositions(overlay, textpos)
    pbDrawImagePositions(overlay, imagepos)
  end
  
  def pbDisplayFootprint(overlay)
    if PluginManager.installed?("Generation 8 Pack Scripts") && !Settings::DEX_SHOWS_FOOTPRINTS
      iconfile = GameData::Species.icon_filename(@species, @form)
      if iconfile
        icon = RPG::Cache.load_bitmap("", iconfile)
        min_width  = (((icon.width >= icon.height * 2) ? icon.height : icon.width) - 64) / 2
        min_height = [(icon.height - 56) / 2, 0].max
        overlay.blt(210, 130, icon, Rect.new(min_width, min_height, 64, 56))
      end
    else
      footprintfile = GameData::Species.footprint_filename(@species, @form)
      if footprintfile
        footprint = RPG::Cache.load_bitmap("", footprintfile)
        overlay.blt(226, 138, footprint, footprint.rect)
        footprint.dispose
      end
    end
  end
end