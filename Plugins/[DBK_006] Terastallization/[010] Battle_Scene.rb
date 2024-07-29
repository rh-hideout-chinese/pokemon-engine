#-------------------------------------------------------------------------------
# Aliases to the Battle::Scene class.
#-------------------------------------------------------------------------------
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Applies tera pattern to battler sprites.
  #-----------------------------------------------------------------------------
  alias tera_pbChangePokemon pbChangePokemon
  def pbChangePokemon(idxBattler, pkmn)
    tera_pbChangePokemon(idxBattler, pkmn)
    battler = (idxBattler.respond_to?("index")) ? idxBattler : @battle.battlers[idxBattler]
    pkmnSprite = @sprites["pokemon_#{battler.index}"]
    pkmnSprite.set_tera_pattern(battler)
  end
  
  #-----------------------------------------------------------------------------
  # Aliases for commands in the fight menu.
  #-----------------------------------------------------------------------------
  alias tera_pbSetSpecialActionModes pbSetSpecialActionModes
  def pbSetSpecialActionModes(idxBattler, specialAction, cw)
    tera_pbSetSpecialActionModes(idxBattler, specialAction, cw)
    cw.teraType = 0 if specialAction == :tera
  end
  
  alias tera_pbFightMenu_Action pbFightMenu_Action
  def pbFightMenu_Action(battler, specialAction, cw)
    ret = tera_pbFightMenu_Action(battler, specialAction, cw)
    if specialAction == :tera
      if cw.mode == 1
        cw.teraType = GameData::Type.get(battler.tera_type).icon_position + 1
      else
        cw.teraType = 0
      end
      return false
    end
    return ret
  end
end

#-------------------------------------------------------------------------------
# Fight Menu base additions for Terastallization button properties.
#-------------------------------------------------------------------------------
class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  attr_reader :teraType
  
  def teraType=(value)
    oldValue = @teraType
    @teraType = value
    refreshSpecialActionButton if @teraType != oldValue
  end
  
  alias tera_resetMenuToggles resetMenuToggles
  def resetMenuToggles
    tera_resetMenuToggles
    @teraType = -1
  end
  
  alias tera_addSpecialActionButtons addSpecialActionButtons
  def addSpecialActionButtons(path)
    tera_addSpecialActionButtons(path)
    if pbResolveBitmap(path + "cursor_tera")
      @actionButtonBitmap[:tera] = AnimatedBitmap.new(_INTL(path + "cursor_tera"))
    else
      @actionButtonBitmap[:tera] = AnimatedBitmap.new(_INTL(Settings::TERASTAL_GRAPHICS_PATH + "cursor_tera"))
    end
  end
  
  alias tera_getButtonSettings getButtonSettings
  def getButtonSettings
    if @chosenButton == :tera
      return GameData::Type.count + 1, @teraType
    end
    return tera_getButtonSettings
  end
end

#-------------------------------------------------------------------------------
# Battler databox Tera type icon.
#-------------------------------------------------------------------------------
class Battle::Scene::PokemonDataBox < Sprite
  alias tera_draw_special_form_icon draw_special_form_icon
  def draw_special_form_icon
    if @battler.tera?
      specialX = (@battler.opposes?(0)) ? 208 : -28
      path = Settings::TERASTAL_GRAPHICS_PATH + "tera_types"
      type_number = GameData::Type.get(@battler.tera_type).icon_position
      pbDrawImagePositions(self.bitmap, [[path, @spriteBaseX + specialX, 4, 0, type_number * 32, 32, 32]])
    else
      tera_draw_special_form_icon
    end
  end
end