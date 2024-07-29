################################################################################
#
# Deluxe Additions
#
################################################################################

#-------------------------------------------------------------------------------
# Game stat tracking.
#-------------------------------------------------------------------------------
class GameStats
  alias ultraburst_initialize initialize
  def initialize
    ultraburst_initialize
    @ultra_burst_count = 0
    @wild_ultra_battles_won = 0
  end

  def ultra_burst_count
    return @ultra_burst_count || 0
  end
  
  def ultra_burst_count=(value)
    @ultra_burst_count = 0 if !@ultra_burst_count
    @ultra_burst_count = value
  end
  
  def wild_ultra_battles_won
    return @wild_ultra_battles_won || 0
  end
  
  def wild_ultra_battles_won=(value)
    @wild_ultra_battles_won = 0 if !@wild_ultra_battles_won
    @wild_ultra_battles_won = value
  end
end

#-------------------------------------------------------------------------------
# Battle Rules.
#-------------------------------------------------------------------------------
class Game_Temp
  alias ultra_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "wildultraburst" then rules["wildBattleMode"] = :ultra
    when "noultraburst"   then rules["noUltraBurst"]   = var
    else
      ultra_add_battle_rule(rule, var)
    end
  end
end

alias ultra_additionalRules additionalRules
def additionalRules
  rules = ultra_additionalRules
  rules.push("noultraburst")
  return rules
end

#-------------------------------------------------------------------------------
# Used for wild Ultra battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_global, :wild_ultra_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle? || pbInSafari?
    next if battle.wildBattleMode != :ultra
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    when "RoundStartCommand_1_foe"
      if battle.pbCanUltraBurst?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} will Ultra Burst")
        battle.pbUltraBurst(foe.index)
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 6
        PBDebug.log("[Midbattle Global] #{logname} gains a Z-Powered aura")
        battle.pbAnimation(:DRAGONDANCE, foe, foe)
        battle.pbDisplay(_INTL("{1}'s aura flared to life!", foe.pbThis))
        showAnim = true
        GameData::Stat.each_main_battle do |s|
          foe.pbRaiseStatStage(s.id, 1, foe, showAnim)
          showAnim = false
        end
      else
        battle.wildBattleMode = nil
      end
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      foe.unUltra
      if foe.hasRaisedStatStages?
        foe.statsLoweredThisRound = true
        battle.pbCommonAnimation("StatDown", foe)
        GameData::Stat.each_main_battle do |s|
          foe.stages[s.id] = 0 if foe.stages[s.id] > 0
        end
      end
      battle.noBag = false
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("{1}'s Ultra Burst faded!\nIt may now be captured!", foe.pbThis))
    when "BattleEndWin"
      if battle.wildBattleMode == :ultra
        $stats.wild_ultra_battles_won += 1
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to Ultra Burst.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "ultraBurst",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :ultra if battler.wild? && oldMode != :ultra
    if battle.pbCanUltraBurst?(battler.index)
      PBDebug.log("     'ultraBurst': #{battler.name} (#{battler.index}) set to Ultra Burst")
      battle.scene.pbForceEndSpeech
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
      battle.pbUltraBurst(battler.index)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Ultra Burst for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableUltra",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.ultraBurst[side][owner] = (params) ? -2 : -1
    value = (params) ? "disabled" : "enabled"
    trainerName = battle.pbGetOwnerName(idxBattler)
    PBDebug.log("     'disableUltra': Ultra Burst #{value} for #{trainerName}")
  }
)


################################################################################
#
# Battle
#
################################################################################

class Battle
  attr_accessor :ultraBurst
  
  #-----------------------------------------------------------------------------
  # Aliases for Ultra Burst.
  #-----------------------------------------------------------------------------
  alias ultraburst_initialize initialize
  def initialize(*args)
    ultraburst_initialize(*args)
    @ultraBurst = [
      [-1] * (@player ? @player.length : 1),
      [-1] * (@opponent ? @opponent.length : 1)
    ]
  end
  
  alias ultraburst_pbInitializeSpecialActions pbInitializeSpecialActions
  def pbInitializeSpecialActions(idxTrainer)
    return if !idxTrainer
    ultraburst_pbInitializeSpecialActions(idxTrainer)
    @ultraBurst[1][idxTrainer] = -1
  end
  
  alias ultraburst_pbCanUseAnyBattleMechanic? pbCanUseAnyBattleMechanic?
  def pbCanUseAnyBattleMechanic?(idxBattler)
    return true if pbCanUltraBurst?(idxBattler)
    return ultraburst_pbCanUseAnyBattleMechanic?(idxBattler)
  end
  
  alias ultraburst_pbCanUseBattleMechanic? pbCanUseBattleMechanic?
  def pbCanUseBattleMechanic?(idxBattler, mechanic)
    return true if mechanic == :ultra && pbCanUltraBurst?(idxBattler)
    return ultraburst_pbCanUseBattleMechanic?(idxBattler, mechanic)
  end
  
  alias ultraburst_pbGetEligibleBattleMechanic pbGetEligibleBattleMechanic
  def pbGetEligibleBattleMechanic(idxBattler)
    return :ultra if pbCanUltraBurst?(idxBattler)
    return ultraburst_pbGetEligibleBattleMechanic(idxBattler)
  end
  
  alias ultraburst_pbUnregisterAllSpecialActions pbUnregisterAllSpecialActions
  def pbUnregisterAllSpecialActions(idxBattler)
    ultraburst_pbUnregisterAllSpecialActions(idxBattler)
    pbUnregisterUltraBurst(idxBattler)
  end
  
  alias ultraburst_pbBattleMechanicIsRegistered? pbBattleMechanicIsRegistered?
  def pbBattleMechanicIsRegistered?(idxBattler, mechanic)
    return true if mechanic == :ultra && pbRegisteredUltraBurst?(idxBattler)
    return ultraburst_pbBattleMechanicIsRegistered?(idxBattler, mechanic)
  end
  
  alias ultraburst_pbToggleSpecialActions pbToggleSpecialActions
  def pbToggleSpecialActions(idxBattler, cmd)
    ultraburst_pbToggleSpecialActions(idxBattler, cmd)
    pbToggleRegisteredUltraBurst(idxBattler) if cmd == :ultra
  end
  
  alias ultraburst_pbActionCommands pbActionCommands
  def pbActionCommands(side)
    ultraburst_pbActionCommands(side)
    @ultraBurst[side].each_with_index do |ultra, i|
      @ultraBurst[side][i] = -1 if ultra >= 0
    end
  end
  
  alias ultraburst_pbAttackPhaseSpecialActions3 pbAttackPhaseSpecialActions3
  def pbAttackPhaseSpecialActions3
    ultraburst_pbAttackPhaseSpecialActions3
    pbPriority.each do |b|
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @ultraBurst[b.idxOwnSide][owner] != b.index
      pbUltraBurst(b.index)
    end
  end

  alias ultraburst_pbPursuitSpecialActions pbPursuitSpecialActions
  def pbPursuitSpecialActions(battler, owner)
    ultraburst_pbPursuitSpecialActions(battler, owner)
    pbUltraBurst(battler.index) if @ultraBurst[battler.idxOwnSide][owner] == battler.index
  end

  #-----------------------------------------------------------------------------
  # Ultra Burst eligibility.
  #-----------------------------------------------------------------------------
  def pbCanUltraBurst?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_ULTRA_BURST]               # No Ultra Burst if switch enabled.
    return false if !battler.hasUltra?                                     # No Ultra Burst if ineligible.
    return true  if $DEBUG && Input.press?(Input::CTRL) && !battler.wild?  # Allows Ultra Burst with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0               # No Ultra Burst if in Sky Drop.
    return false if !pbHasZRing?(idxBattler)                               # No Ultra Burst if no Z-Ring.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @ultraBurst[side][owner] == -1
  end
  
  #-----------------------------------------------------------------------------
  # Ultra Burst.
  #-----------------------------------------------------------------------------  
  def pbUltraBurst(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasUltra? || battler.ultra?
    $stats.ultra_burst_count += 1 if battler.pbOwnedByPlayer?
    pbDeluxeTriggers(idxBattler, nil, "BeforeUltraBurst", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :hide)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
    end
    pbDisplay(_INTL("Bright light is about to burst out of {1}!", battler.pbThis(true)))    
    pbAnimateUltraBurst(battler)
    pbDisplay(_INTL("{1} regained its true power with Ultra Burst!", battler.pbThis))    
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = -2
    battler.pbOnLosingAbility(old_ability)
    battler.pbTriggerAbilityOnGainingIt
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
    pbDeluxeTriggers(idxBattler, nil, "AfterUltraBurst", battler.species, *battler.pokemon.types)
    @scene.pbAnimateSubstitute(idxBattler, :show)
  end
  
  #-----------------------------------------------------------------------------
  # Animates Ultra Burst and updates the battler's form.
  #-----------------------------------------------------------------------------
  def pbAnimateUltraBurst(battler)
    if @scene.pbCommonAnimationExists?("UltraBurst")
      pbCommonAnimation("UltraBurst", battler)
      battler.pokemon.makeUltra
      battler.form_update(true)
      pbCommonAnimation("UltraBurst2", battler)
    else 
      if Settings::SHOW_ULTRA_ANIM && $PokemonSystem.battlescene == 0
        @scene.pbShowUltraBurst(battler.index)
        battler.pokemon.makeUltra
        battler.form_update(true)
      else
        @scene.pbRevertBattlerStart(battler.index)
        battler.pokemon.makeUltra
        battler.form_update(true)
        @scene.pbRevertBattlerEnd
      end
    end
  end

  #-----------------------------------------------------------------------------
  # Registering Ultra Burst.
  #-----------------------------------------------------------------------------
  def pbRegisterUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = idxBattler
  end
  
  def pbUnregisterUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @ultraBurst[side][owner] = -1 if @ultraBurst[side][owner] == idxBattler
  end

  def pbToggleRegisteredUltraBurst(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @ultraBurst[side][owner] == idxBattler
      @ultraBurst[side][owner] = -1
    else
      @ultraBurst[side][owner] = idxBattler
    end
  end
  
  def pbRegisteredUltraBurst?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @ultraBurst[side][owner] == idxBattler
  end
end


################################################################################
#
# Battle::Battler
#
################################################################################

class Battle::Battler
  def ultra?; return @pokemon&.ultra?; end
  
  #-----------------------------------------------------------------------------
  # Eligibility check.
  #-----------------------------------------------------------------------------
  def hasUltra?
    return false if shadowPokemon? || @effects[PBEffects::Transform]
    return false if wild? && ![:zmove, :ultra].include?(@battle.wildBattleMode)
    return false if !getActiveState.nil?
    return false if hasEligibleAction?(:primal, :zodiac)
    return false if !@item_id || @item_id != @pokemon&.getUltraItem
    return @pokemon&.hasUltraForm?
  end
  
  #-----------------------------------------------------------------------------
  # Reverts an Ultra form battler to its original form.
  #-----------------------------------------------------------------------------
  def unUltra
    @battle.scene.pbRevertBattlerStart(@index)
    @pokemon.makeUnUltra if ultra?
    self.form_update(true)
    @battle.scene.pbRevertBattlerEnd
  end
  
  #-----------------------------------------------------------------------------
  # Prevents Ultra item from being removed if the user is or has an Ultra form.
  #-----------------------------------------------------------------------------
  alias ultra_unlosableItem? unlosableItem?
  def unlosableItem?(check_item)
    return false if !check_item
    item_data = GameData::Item.get(check_item)
    return true if item_data.is_zcrystal?
    if (ultra? || @pokemon.hasUltraForm?) && !@effects[PBEffects::Transform]
      return true if @pokemon.getUltraItem == item_data.id
    end
    return ultra_unlosableItem?(check_item)
  end
end


################################################################################
#
# Battle::AI
#
################################################################################

class Battle::AI
  alias ultraburst_pbRegisterEnemySpecialAction pbRegisterEnemySpecialAction
  def pbRegisterEnemySpecialAction(idxBattler)
    ultraburst_pbRegisterEnemySpecialAction(idxBattler)
    @battle.pbRegisterUltraBurst(idxBattler) if pbEnemyShouldUltraBurst?
  end
  
  #-----------------------------------------------------------------------------
  # The AI will always immediately Ultra Burst as soon as they are able.
  #-----------------------------------------------------------------------------
  def pbEnemyShouldUltraBurst?
    if @battle.pbCanUltraBurst?(@user.index)
      PBDebug.log_ai("#{@user.name} will Ultra Burst")
      return true
    end
    return false
  end
end


################################################################################
#
# Battle::Peer
#
################################################################################

class Battle::Peer
  #-----------------------------------------------------------------------------
  # Aliased to revert Ultra form battlers upon fainting or ending a battle.
  #-----------------------------------------------------------------------------
  alias ultraburst_pbOnLeavingBattle pbOnLeavingBattle
  def pbOnLeavingBattle(battle, pkmn, usedInBattle, endBattle = false)
    ultraburst_pbOnLeavingBattle(battle, pkmn, usedInBattle, endBattle)
    return if !pkmn
    f = MultipleForms.call("getUnUltraForm", pkmn)
    if f && pkmn.form != f && (endBattle || pkmn.fainted?)
      pkmn.form_simple = f
      pkmn.ability = nil
      pkmn.hp = pkmn.totalhp if pkmn.hp > pkmn.totalhp
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
  alias ultraburst_pbFightMenu_Action pbFightMenu_Action
  def pbFightMenu_Action(battler, specialAction, cw)
    ret = ultraburst_pbFightMenu_Action(battler, specialAction, cw)
    return false if specialAction == :ultra
    return ret
  end
end

class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  alias ultraburst_addSpecialActionButtons addSpecialActionButtons
  def addSpecialActionButtons(path)
    ultraburst_addSpecialActionButtons(path)
    if pbResolveBitmap(path + "cursor_ultra")
      @actionButtonBitmap[:ultra] = AnimatedBitmap.new(_INTL(path + "cursor_ultra"))
    else
      @actionButtonBitmap[:ultra] = AnimatedBitmap.new(_INTL(Settings::ZMOVE_GRAPHICS_PATH + "cursor_ultra"))
    end
  end
end

#-------------------------------------------------------------------------------
# Ultra Burst databox icon.
#-------------------------------------------------------------------------------
class Battle::Scene::PokemonDataBox < Sprite
  alias ultraburst_draw_special_form_icon draw_special_form_icon
  def draw_special_form_icon
    if @battler.ultra?
      specialX = (@battler.opposes?(0)) ? 208 : -28
      pbDrawImagePositions(self.bitmap, [[Settings::ZMOVE_GRAPHICS_PATH + "icon_ultra", @spriteBaseX + specialX, 4]])
    else
      ultraburst_draw_special_form_icon
    end
  end
end


################################################################################
#
# Pokemon
#
################################################################################

#-------------------------------------------------------------------------------
# Ultra form utilities.
#-------------------------------------------------------------------------------
class Pokemon  
  def hasUltraForm?
    v = MultipleForms.hasFunction?(@species, "getUltraForm")
    return !v.nil?
  end
  
  def ultra?
    v = MultipleForms.call("getUltraForm", self)
    return !v.nil? && v == @form
  end

  def makeUltra
    v = MultipleForms.call("getUltraForm", self)
    self.form = v if !v.nil?
  end
  
  def makeUnUltra
    v = MultipleForms.call("getUnUltraForm", self)
    if !v.nil?
      self.form_simple = v
    elsif ultra?
      self.form_simple = 0
    end
  end
  
  def getUltraForm
    v = MultipleForms.call("getUltraForm", self)
    return v || @form
  end
  
  def getUltraItem
    v = MultipleForms.call("getUltraItem", self)
    return v
  end
end

#-------------------------------------------------------------------------------
# Ultra Burst form handlers added to Necrozma.
#-------------------------------------------------------------------------------
MultipleForms.register(:NECROZMA, {
  #-----------------------------------------------------------------------------
  # Gets appropriate Ultra Burst form.
  "getUltraForm" => proc { |pkmn|
    next 3 if [1, 3].include?(pkmn.form)
    next 4 if [2, 4].include?(pkmn.form)
  },
  #-----------------------------------------------------------------------------
  # Gets Ultra form's appropriate base form.
  "getUnUltraForm" => proc { |pkmn|
    next pkmn.form - 2 if pkmn.form >= 3
  },
  #-----------------------------------------------------------------------------
  # Gets Ultra item for this species.
  "getUltraItem" => proc { |pkmn|
    next :ULTRANECROZIUMZ if pkmn.form > 0
  },
  #-----------------------------------------------------------------------------
  # Pokedex Data Page compatibility.
  "getDataPageInfo" => proc { |pkmn|
    form = [1, 2].sample
    next [3, form, :ULTRANECROZIUMZ]
  },
  #-----------------------------------------------------------------------------
  # Default Essentials handler.
  "onSetForm" => proc { |pkmn, form, oldForm|
    next if form > 2 || oldForm > 2
    form_moves = [
      :SUNSTEELSTRIKE,
      :MOONGEISTBEAM
    ]
    if form == 0
      form_moves.each do |move|
        next if !pkmn.hasMove?(move)
        pkmn.forget_move(move)
        pbMessage(_INTL("{1} forgot {2}...", pkmn.name, GameData::Move.get(move).name))
      end
      pbLearnMove(pkmn, :CONFUSION) if pkmn.numMoves == 0
    else
      new_move_id = form_moves[form - 1]
      pbLearnMove(pkmn, new_move_id, true)
    end
  }
})