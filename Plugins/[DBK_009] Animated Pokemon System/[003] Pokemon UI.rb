#===============================================================================
# Miscellaneous edits to various Pokemon UI's for constricting sprites.
#===============================================================================

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------
class PokemonSummary_Scene
  def pbFadeInAndShow(sprites, visiblesprites = nil)
    if visiblesprites
      visiblesprites.each do |i|
        if i[1] && sprites[i[0]] && !pbDisposed?(sprites[i[0]])
          sprites[i[0]].visible = true
        end
      end
    end
    @sprites["pokemon"].constrict([208, 164]) if @sprites["pokemon"]
    numFrames = (Graphics.frame_rate * 0.4).floor
    alphaDiff = (255.0 / numFrames).ceil
    pbDeactivateWindows(sprites) {
      (0..numFrames).each do |j|
        pbSetSpritesToColor(sprites, Color.new(0, 0, 0, ((numFrames - j) * alphaDiff)))
        (block_given?) ? yield : pbUpdateSpriteHash(sprites)
      end
    }
  end

  alias animated_pbChangePokemon pbChangePokemon
  def pbChangePokemon
    animated_pbChangePokemon
    @sprites["pokemon"].constrict([208, 164])
  end
  
  alias animated_drawPage drawPage
  def drawPage(page)
    animated_drawPage(page)
    @sprites["pokemon"].constrict([208, 164])
  end
end

#-------------------------------------------------------------------------------
# Pokedex
#-------------------------------------------------------------------------------
class PokemonPokedexInfo_Scene
  alias animated_pbUpdateDummyPokemon pbUpdateDummyPokemon
  def pbUpdateDummyPokemon
    animated_pbUpdateDummyPokemon
    return if !Settings::CONSTRICT_POKEMON_SPRITES
    sp_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    @sprites["infosprite"].constrict([208, 200])
    @sprites["formfront"].constrict([200, 196]) if @sprites["formfront"]
    return if !@sprites["formback"]
    @sprites["formback"].constrict([300, 294])
    return if sp_data.back_sprite_scale == sp_data.front_sprite_scale
    @sprites["formback"].setOffset(PictureOrigin::CENTER)
    @sprites["formback"].y = @sprites["formfront"].y if @sprites["formfront"]
    @sprites["formback"].zoom_x = (sp_data.front_sprite_scale.to_f / sp_data.back_sprite_scale)
    @sprites["formback"].zoom_y = (sp_data.front_sprite_scale.to_f / sp_data.back_sprite_scale)
  end
end

class PokemonPokedex_Scene
  alias animated_setIconBitmap setIconBitmap
  def setIconBitmap(*args)
    animated_setIconBitmap(*args)
    @sprites["icon"].constrict([224, 216])
  end
end

#-------------------------------------------------------------------------------
# Storage
#-------------------------------------------------------------------------------
class PokemonStorageScene
  alias animated_pbUpdateOverlay pbUpdateOverlay
  def pbUpdateOverlay(*args)
    animated_pbUpdateOverlay(*args)
    @sprites["pokemon"].constrict(168, true)
  end
end