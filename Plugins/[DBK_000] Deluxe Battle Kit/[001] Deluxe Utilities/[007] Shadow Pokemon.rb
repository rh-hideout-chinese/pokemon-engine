#===============================================================================
# Shadow Pokemon.
#===============================================================================


#-------------------------------------------------------------------------------
# Shadow Pokemon sprite patterns.
#-------------------------------------------------------------------------------
class Sprite
  attr_accessor :pattern_type
  
  def apply_shadow_pattern(pokemon, subfolder = "Front")
    path = Settings::DELUXE_GRAPHICS_PATH
    return if !pbResolveBitmap(path + "shadow_pattern")
    if Settings::DONT_OVERLAY_EXISTING_SHADOW_SPRITES
      try_form, try_gender = [""], [""]
      try_form.insert(0, sprintf("_%d", pokemon.form)) if pokemon.form > 0
      try_gender.insert(0, "_female") if pokemon.gender == 1
      try_form.each do |f|
        try_gender.each do |g|
          try_file = sprintf("Graphics/Pokemon/%s/%s%s%s_shadow", subfolder, pokemon.species, f, g)
          next if !pbResolveBitmap(try_file)
          self.pattern = nil
          self.pattern_type = nil
          return
        end
      end
    end
    self.pattern = Bitmap.new(path + "shadow_pattern")
    self.pattern_opacity = 150
    self.pattern_type = :shadow
  end

  def set_shadow_pattern(pokemon)
    if pokemon.shadowPokemon?
      apply_shadow_pattern(pokemon)
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end
  
  def set_shadow_icon_pattern
    if self.pokemon.shadowPokemon?
      apply_shadow_pattern(self.pokemon, "Icons")
    else
      self.pattern = nil
      self.pattern_type = nil
    end
  end
  
  def update_shadow_pattern
    return if self.pattern_type != :shadow
    if (System.uptime / 0.05).to_i % 2 == 0
      case Settings::SHADOW_PATTERN_MOVEMENT[0]
      when :left    then self.pattern_scroll_x -= 1 
      when :right   then self.pattern_scroll_x += 1
      when :erratic then self.pattern_scroll_x += rand(-5..5) 
      end
      case Settings::SHADOW_PATTERN_MOVEMENT[1]
      when :up      then self.pattern_scroll_y -= 1 
      when :down    then self.pattern_scroll_y += 1
      when :erratic then self.pattern_scroll_y += rand(-5..5)
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # To be aliased by other plugins that add sprite patterns.
  #-----------------------------------------------------------------------------
  def set_plugin_pattern(pokemon, override = false)
    set_shadow_pattern(pokemon)
  end
  
  def set_plugin_icon_pattern
    set_shadow_icon_pattern
  end
  
  def update_plugin_pattern
    update_shadow_pattern
  end
end

#-------------------------------------------------------------------------------
# Aliased to set Shadow pattern on species sprites (Defined Pokemon)
#-------------------------------------------------------------------------------
class PokemonSprite < Sprite
  alias shadow_setPokemonBitmap setPokemonBitmap
  def setPokemonBitmap(pokemon, back = false)
    shadow_setPokemonBitmap(pokemon, back)
    self.set_plugin_pattern(pokemon)
  end

  alias shadow_setPokemonBitmapSpecies setPokemonBitmapSpecies
  def setPokemonBitmapSpecies(pokemon, species, back = false)
    shadow_setPokemonBitmapSpecies(pokemon, species, back)
    self.set_plugin_pattern(pokemon)
  end
  
  alias shadow_update update
  def update
    shadow_update
    self.update_plugin_pattern
  end
end

class Battle::Scene::BattlerSprite < RPG::Sprite
  alias shadow_update update
  def update
    shadow_update
    return if !@_iconBitmap
    self.update_plugin_pattern
  end
end

#-------------------------------------------------------------------------------
# Aliased to set Shadow pattern on species icons (Defined Pokemon)
#-------------------------------------------------------------------------------
class PokemonIconSprite < Sprite
  alias :shadow_pokemon= :pokemon=
  def pokemon=(value)
    self.shadow_pokemon=(value)
    self.set_plugin_icon_pattern
  end
end

#-------------------------------------------------------------------------------
# Aliased to set Shadow pattern on species icons (Storage)
#-------------------------------------------------------------------------------
class PokemonBoxIcon < IconSprite
  alias shadow_refresh refresh 
  def refresh
    shadow_refresh
    self.set_shadow_pattern(@pokemon) if @pokemon
  end
end

#-------------------------------------------------------------------------------
# Updates Shadow pattern on battler sprites.
#-------------------------------------------------------------------------------
class Battle::Scene
  alias shadow_pbChangePokemon pbChangePokemon
  def pbChangePokemon(idxBattler, pkmn)
    shadow_pbChangePokemon(idxBattler, pkmn)
    battler = (idxBattler.respond_to?("index")) ? idxBattler : @battle.battlers[idxBattler]
    pkmnSprite = @sprites["pokemon_#{battler.index}"]
    pkmnSprite.set_plugin_pattern(battler)
  end
end