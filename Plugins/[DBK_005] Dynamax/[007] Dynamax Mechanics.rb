################################################################################
#
# Deluxe Additions
#
################################################################################

#-------------------------------------------------------------------------------
# Game stat tracking.
#-------------------------------------------------------------------------------
class GameStats
  alias dynamax_initialize initialize
  def initialize
    dynamax_initialize
    @dynamax_count             = 0
    @gigantamax_count          = 0
    @total_dynamax_lvls_gained = 0
    @total_gmax_factors_given  = 0
    @wild_dynamax_battles_won  = 0
  end
  
  def dynamax_count
    return @dynamax_count || 0
  end
  
  def dynamax_count=(value)
    @dynamax_count = 0 if !@dynamax_count
    @dynamax_count = value
  end
  
  def gigantamax_count
    return @gigantamax_count || 0
  end
  
  def gigantamax_count=(value)
    @gigantamax_count = 0 if !@gigantamax_count
    @gigantamax_count = value
  end
  
  def total_dynamax_lvls_gained
    return @total_dynamax_lvls_gained || 0
  end
  
  def total_dynamax_lvls_gained=(value)
    @total_dynamax_lvls_gained = 0 if !@total_dynamax_lvls_gained
    @total_dynamax_lvls_gained = value
  end
  
  def total_gmax_factors_given
    return @total_gmax_factors_given || 0
  end
  
  def total_gmax_factors_given=(value)
    @total_gmax_factors_given = 0 if !@total_gmax_factors_given
    @total_gmax_factors_given = value
  end
  
  def wild_dynamax_battles_won
    return @wild_dynamax_battles_won || 0
  end
  
  def wild_dynamax_battles_won=(value)
    @wild_dynamax_battles_won = 0 if !@wild_dynamax_battles_won
    @wild_dynamax_battles_won = value
  end
end

#-------------------------------------------------------------------------------
# Battle Rules.
#-------------------------------------------------------------------------------
class Game_Temp
  alias dynamax_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "wilddynamax" then rules["wildBattleMode"] = :dynamax
    when "nodynamax"   then rules["noDynamax"]      = var
    else
      dynamax_add_battle_rule(rule, var)
    end
  end
end

alias dynamax_additionalRules additionalRules
def additionalRules
  rules = dynamax_additionalRules
  rules.push("nodynamax")
  return rules
end

#-------------------------------------------------------------------------------
# Used for wild Dynamax battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_global, :wild_dynamax_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle? || pbInSafari?
    next if battle.wildBattleMode != :dynamax
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    when "RoundStartCommand_1_foe"
      if battle.pbCanDynamax?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} will Dynamax")
        foe.display_dynamax_moves
        battle.pbDynamax(foe.index)
        foe.effects[PBEffects::Dynamax] = -1
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 6
      else
        battle.wildBattleMode = nil
      end
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      foe.unDynamax
      battle.noBag = false
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("{1}'s Dynamax energy faded!\nIt may now be captured!", foe.pbThis))
      ch = battle.choices[idxBattler]
      if !foe.movedThisRound? && ch[0] == :UseMove
        ch[2] = foe.moves[ch[1]]
      end
    when "BattleEndWin"
      if battle.wildBattleMode == :dynamax
        $stats.wild_dynamax_battles_won += 1
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to Dynamax.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "dynamax",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :dynamax if battler.wild? && oldMode != :dynamax
    if battle.pbCanDynamax?(battler.index)
      PBDebug.log("     'dynamax': #{battler.name} (#{battler.index}) set to Dynamax")
      battle.scene.pbForceEndSpeech
      battler.display_dynamax_moves
      ch[2] = battler.moves[ch[1]] if !battler.movedThisRound?
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
      battle.pbDynamax(battler.index)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Dynamax for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableDynamax",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.dynamax[side][owner] = (params) ? -2 : -1
    value = (params) ? "disabled" : "enabled"
    trainerName = battle.pbGetOwnerName(idxBattler)
    PBDebug.log("     'disableDynamax': Dynamax #{value} for #{trainerName}")
  }
)


################################################################################
#
# Battle
#
################################################################################

class Battle
  attr_accessor :dynamax
  
  #-----------------------------------------------------------------------------
  # Aliases for Dynamax.
  #-----------------------------------------------------------------------------
  alias dynamax_initialize initialize
  def initialize(*args)
    dynamax_initialize(*args)
    @dynamax = [
      [-1] * (@player ? @player.length : 1),
      [-1] * (@opponent ? @opponent.length : 1)
    ]
    @dynamax_bands = []
    GameData::Item.each { |item| @dynamax_bands.push(item.id) if item.has_flag?("DynamaxBand") }
  end
  
  alias dynamax_pbInitializeSpecialActions pbInitializeSpecialActions
  def pbInitializeSpecialActions(idxTrainer)
    return if !idxTrainer
    dynamax_pbInitializeSpecialActions(idxTrainer)
    @dynamax[1][idxTrainer] = -1
  end
  
  alias dynamax_pbCanUseAnyBattleMechanic? pbCanUseAnyBattleMechanic?
  def pbCanUseAnyBattleMechanic?(idxBattler)
    return true if pbCanDynamax?(idxBattler)
    return dynamax_pbCanUseAnyBattleMechanic?(idxBattler)
  end
  
  alias dynamax_pbCanUseBattleMechanic? pbCanUseBattleMechanic?
  def pbCanUseBattleMechanic?(idxBattler, mechanic)
    return true if mechanic == :dynamax && pbCanDynamax?(idxBattler)
    return dynamax_pbCanUseBattleMechanic?(idxBattler, mechanic)
  end
  
  alias dynamax_pbGetEligibleBattleMechanic pbGetEligibleBattleMechanic
  def pbGetEligibleBattleMechanic(idxBattler)
    return :dynamax if pbCanDynamax?(idxBattler)
    return dynamax_pbGetEligibleBattleMechanic(idxBattler)
  end
  
  alias dynamax_pbUnregisterAllSpecialActions pbUnregisterAllSpecialActions
  def pbUnregisterAllSpecialActions(idxBattler)
    dynamax_pbUnregisterAllSpecialActions(idxBattler)
    @battlers[idxBattler].display_base_moves if pbRegisteredDynamax?(idxBattler)
    pbUnregisterDynamax(idxBattler)
  end
  
  alias dynamax_pbBattleMechanicIsRegistered? pbBattleMechanicIsRegistered?
  def pbBattleMechanicIsRegistered?(idxBattler, mechanic)
    return true if mechanic == :dynamax && pbRegisteredDynamax?(idxBattler)
    return dynamax_pbBattleMechanicIsRegistered?(idxBattler, mechanic)
  end
  
  alias dynamax_pbToggleSpecialActions pbToggleSpecialActions
  def pbToggleSpecialActions(idxBattler, cmd)
    dynamax_pbToggleSpecialActions(idxBattler, cmd)
    pbToggleRegisteredDynamax(idxBattler) if cmd == :dynamax
  end
  
  alias dynamax_pbActionCommands pbActionCommands
  def pbActionCommands(side)
    dynamax_pbActionCommands(side)
    @dynamax[side].each_with_index do |dynamax, i|
      @dynamax[side][i] = -1 if dynamax >= 0
    end
  end
  
  alias dynamax_pbAttackPhaseSpecialActions3 pbAttackPhaseSpecialActions3
  def pbAttackPhaseSpecialActions3
    dynamax_pbAttackPhaseSpecialActions3
    pbPriority.each do |b|
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @dynamax[b.idxOwnSide][owner] != b.index
      pbDynamax(b.index)
    end
  end
  
  alias dynamax_pbPursuitSpecialActions pbPursuitSpecialActions
  def pbPursuitSpecialActions(battler, owner)
    dynamax_pbPursuitSpecialActions(battler, owner)
    pbDynamax(battler.index) if @dynamax[battler.idxOwnSide][owner] == battler.index
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax Bands
  #-----------------------------------------------------------------------------
  def pbHasDynamaxBand?(idxBattler)
    return true if @battlers[idxBattler].wild?
    if pbOwnedByPlayer?(idxBattler)
      @dynamax_bands.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @dynamax_bands.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end
  
  def pbGetDynamaxBandName(idxBattler)
    if !@dynamax_bands.empty?
      if pbOwnedByPlayer?(idxBattler)
        @dynamax_bands.each { |item| return GameData::Item.get(item).name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @dynamax_bands.each { |item| return GameData::Item.get(item).portion_name if trainer_items&.include?(item) }
      end
    end
    return _INTL("Dynamax Band")
  end
  
  #-----------------------------------------------------------------------------
  # Eligibility check.
  #-----------------------------------------------------------------------------
  def pbCanDynamax?(idxBattler)
    battler = @battlers[idxBattler]
    return false if !battler.hasDynamax?                                   # No Dynamax if ineligible.
    return true  if $DEBUG && Input.press?(Input::CTRL) && !battler.wild?  # Allows Dynamax with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0               # No Dynamax if in Sky Drop.
    return false if !pbHasDynamaxBand?(idxBattler)                         # No Dynamax if no Dynamax Band.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @dynamax[side][owner] == -1
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax.
  #-----------------------------------------------------------------------------  
  def pbDynamax(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasDynamax? || battler.dynamax?
    return if @choices[idxBattler][2] == @struggle
    $stats.dynamax_count += 1 if battler.pbOwnedByPlayer?
    triggers = ["BeforeDynamax", battler.species, *battler.pokemon.types]
    if battler.hasGmax?
      $stats.gigantamax_count += 1 if battler.pbOwnedByPlayer?
      triggers.push("BeforeGigantamax", battler.species, *battler.pokemon.types)
    end
    pbDeluxeTriggers(idxBattler, nil, *triggers)
    @scene.pbAnimateSubstitute(idxBattler, :hide)
    battler.effects[PBEffects::Dynamax]    = Settings::DYNAMAX_TURNS
    battler.effects[PBEffects::Encore]     = 0
    battler.effects[PBEffects::EncoreMove] = nil
    battler.effects[PBEffects::Disable]    = 0
    battler.effects[PBEffects::Substitute] = 0
    battler.effects[PBEffects::Torment]    = false
    battler.pokemon.form = 0 if battler.isSpecies?(:CRAMORANT)
    oldhp = battler.hp
    pbAnimateDynamax(battler)
    @scene.pbHPChanged(battler, oldhp)
    @scene.pbRefreshOne(battler.index)
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = -2
    triggers = ["AfterDynamax", battler.species, *battler.pokemon.types]
    if battler.hasGmax?
      triggers.push("AfterGigantamax", battler.species, *battler.pokemon.types)
    end
    pbDeluxeTriggers(idxBattler, nil, *triggers)
    @scene.pbAnimateSubstitute(idxBattler, :show)
  end
  
  #-----------------------------------------------------------------------------
  # Animates Dynamax and updates battler's attributes.
  #-----------------------------------------------------------------------------
  def pbAnimateDynamax(battler)
    if @scene.pbCommonAnimationExists?("Dynamax")
      pbCommonAnimation("Dynamax", battler)
      battler.makeDynamax
      pbCommonAnimation("Dynamax2", battler)
    else 
      if Settings::SHOW_DYNAMAX_ANIM && $PokemonSystem.battlescene == 0
        @scene.pbShowDynamax(battler.index)
        battler.makeDynamax
      else
        type = (battler.hasEmax?) ? "Eternamax" : (battler.hasGmax?) ? "Gigantamax" : "Dynamax"
        idxBattler = battler.index
        if battler.wild?
          pbDisplay(_INTL("{1} surrounded itself in {2} energy!", battler.pbThis, type))
          @scene.pbRevertBattlerStart(idxBattler)
          battler.makeDynamax
          @scene.pbRevertBattlerEnd
        else
          trainerName = pbGetOwnerName(idxBattler)
          pbDisplay(_INTL("{1} recalled {2}!", trainerName, battler.pbThis(true)))
          xpos, ypos = @scene.sprites["pokemon_#{idxBattler}"].x, @scene.sprites["pokemon_#{idxBattler}"].y
          @scene.pbRecall(idxBattler)
          pbDisplay(_INTL("{1}'s ball surges with {2} energy!", battler.pbThis, type))
          @scene.pbDynamaxSendOut(idxBattler, xpos, ypos)
        end
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Registering Dynamax
  #-----------------------------------------------------------------------------
  def pbRegisterDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = idxBattler
  end

  def pbUnregisterDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @dynamax[side][owner] = -1 if @dynamax[side][owner] == idxBattler
  end

  def pbToggleRegisteredDynamax(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @dynamax[side][owner] == idxBattler
      @dynamax[side][owner] = -1
    else
      @dynamax[side][owner] = idxBattler
    end
  end

  def pbRegisteredDynamax?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @dynamax[side][owner] == idxBattler
  end
end


################################################################################
#
# Battle::Battler
#
################################################################################

class Battle::Battler
  #-----------------------------------------------------------------------------
  # Checks if the battler is in one of these modes.
  #-----------------------------------------------------------------------------
  def dynamax?;      return @pokemon&.dynamax?;      end
  def gmax?;         return @pokemon&.gmax?;         end
  def emax?;         return @pokemon&.emax?;         end
    
  #-----------------------------------------------------------------------------
  # Checks various Dynamax conditions.
  #-----------------------------------------------------------------------------
  def dynamax_able?; return @pokemon&.dynamax_able?; end
  def dynamax_boost; return @pokemon&.dynamax_boost; end
  def dynamax_calc;  return @pokemon&.dynamax_calc;  end
  def gmax_factor?;  return @pokemon&.gmax_factor?;  end
  
  #-----------------------------------------------------------------------------
  # Checks if battler has the option to Dynamax.
  #-----------------------------------------------------------------------------
  def hasDynamax?
    return false if shadowPokemon?
    return false if !pbDynamaxAvailable?
    return false if !getActiveState.nil?
    return false if hasEligibleAction?(:mega, :primal, :zmove, :ultra, :zodiac)
    return false if defined?(isCommanderHost?) && isCommanderHost?
    return false if hasEmax? && !pbEternamaxAvailable?
    pokemon = visiblePokemon
    transformed = @effects[PBEffects::Transform] || @effects[PBEffects::Illusion]
    return false if transformed && pokemon.hasEternamaxForm?
    return pokemon.dynamax_able?
  end
  
  def hasGmax?
    return false if !gmax_factor?
    return @pokemon&.hasGigantamaxForm?
  end
  
  def hasEmax?
    return @pokemon&.hasEternamaxForm?
  end
  
  def pbDynamaxAvailable?
    side  = self.idxOwnSide
    owner = @battle.pbGetOwnerIndexFromBattlerIndex(@index)
    return false if @battle.dynamax[side][owner] == -2
    return false if $game_switches[Settings::NO_DYNAMAX]
    map_data = GameData::MapMetadata.try_get($game_map.map_id)
    if @battle.trainerBattle?
      return true if $game_switches[Settings::DYNAMAX_ON_ANY_MAP]
      return $game_map && map_data&.has_flag?("PowerSpot")
    else
      return false if wild? && @battle.wildBattleMode != :dynamax
      return false if !wild? && !$game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]
      return true if $game_switches[Settings::DYNAMAX_ON_ANY_MAP]
      return $game_map && map_data&.has_flag?("PowerSpot")
    end
  end
  
  def pbEternamaxAvailable?
    return false if @effects[PBEffects::Illusion]
    return false if @effects[PBEffects::Transform]
    map_data = GameData::MapMetadata.try_get($game_map.map_id)
    return $game_map && map_data&.has_flag?("EternaSpot")
  end
  
  #-----------------------------------------------------------------------------
  # Changing Dynamax states.
  #-----------------------------------------------------------------------------
  def makeDynamax
    return if !dynamax_able?
    @pokemon.makeDynamaxForm
    self.form = @pokemon.form
    @pokemon.makeDynamax
    pbUpdate(true)
    pkmn = visiblePokemon
    @battle.scene.pbChangePokemon(self, pkmn)
  end
  
  def unDynamax
    return if !@pokemon
    if !isRaidBoss?
      @battle.scene.pbRevertBattlerStart(@index)
      self.display_base_moves
      @effects[PBEffects::Dynamax] = 0
      @pokemon.makeUndynamaxForm
      self.form = @pokemon.form
      @pokemon.makeUndynamax
      pbUpdate(true)
      pkmn = visiblePokemon
      @battle.scene.pbChangePokemon(self, pkmn)
      @battle.scene.pbRevertBattlerEnd
      @battle.scene.pbHPChanged(self, @totalhp) if !fainted?
      @battle.scene.pbRefreshOne(@index)
      if hasActiveAbility?(:COMMANDER)
        Battle::AbilityEffects.triggerOnSwitchIn(self.ability, self, @battle)
      end
    else
      @pokemon.dynamax = false
    end
  end
  
  #-----------------------------------------------------------------------------
  # Converts the battler's base moves into Dynamax moves.
  #-----------------------------------------------------------------------------
  def display_dynamax_moves
    hash = GameData::Move.get_generic_dynamax_moves
    for i in 0...@moves.length
      next if @moves[i].dynamaxMove?
      new_id = @moves[i].get_compatible_dynamax_move(self, hash)
      next if !new_id
      @baseMoves[i]      = @moves[i].clone
      @moves[i]          = @moves[i].make_dynamax_move(new_id, @battle, i)
      @moves[i].pp       = @baseMoves[i].pp
      @moves[i].total_pp = @baseMoves[i].total_pp
    end
  end
end


################################################################################
#
# Battle::Scene
#
################################################################################

#-------------------------------------------------------------------------------
# Fight menu aliases.
#-------------------------------------------------------------------------------
class Battle::Scene
  alias dynamax_pbFightMenu_Cancel pbFightMenu_Cancel
  def pbFightMenu_Cancel(battler, specialAction, cw)
    ret = dynamax_pbFightMenu_Cancel(battler, specialAction, cw)
    battler.display_base_moves if specialAction == :dynamax
    return ret
  end

  alias dynamax_pbFightMenu_Action pbFightMenu_Action
  def pbFightMenu_Action(battler, specialAction, cw)
    ret = dynamax_pbFightMenu_Action(battler, specialAction, cw)
    if specialAction == :dynamax
      (cw.mode == 1) ? battler.display_dynamax_moves : battler.display_base_moves
      return true
    end
    return ret
  end
end

class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  alias dynamax_addSpecialActionButtons addSpecialActionButtons
  def addSpecialActionButtons(path)
    dynamax_addSpecialActionButtons(path)
    if pbResolveBitmap(path + "cursor_dynamax")
      @actionButtonBitmap[:dynamax] = AnimatedBitmap.new(_INTL(path + "cursor_dynamax"))
    else
      @actionButtonBitmap[:dynamax] = AnimatedBitmap.new(_INTL(Settings::DYNAMAX_GRAPHICS_PATH + "cursor_dynamax"))
    end
  end
end

#-------------------------------------------------------------------------------
# Dynamax databox icon.
#-------------------------------------------------------------------------------
class Battle::Scene::PokemonDataBox < Sprite
  alias dynamax_draw_special_form_icon draw_special_form_icon
  def draw_special_form_icon
    if @battler.dynamax?
      specialX = (@battler.opposes?(0)) ? 208 : -28
      pbDrawImagePositions(self.bitmap, [[Settings::DYNAMAX_GRAPHICS_PATH + "icon_dynamax", @spriteBaseX + specialX, 4]])
    else
      dynamax_draw_special_form_icon
    end
  end
end