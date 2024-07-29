################################################################################
#
# Deluxe Additions
#
################################################################################

#-------------------------------------------------------------------------------
# Game stat tracking.
#-------------------------------------------------------------------------------
class GameStats
  alias zmove_initialize initialize
  def initialize
    zmove_initialize
    @total_zmove_count = 0
    @status_zmove_count = 0
    @wild_zpower_battles_won = 0
  end

  def total_zmove_count
    return @total_zmove_count || 0
  end
  
  def total_zmove_count=(value)
    @total_zmove_count = 0 if !@total_zmove_count
    @total_zmove_count = value
  end
  
  def status_zmove_count
    return @status_zmove_count || 0
  end
  
  def status_zmove_count=(value)
    @status_zmove_count = 0 if !@status_zmove_count
    @status_zmove_count = value
  end
  
  def named_zmove_count
    return @total_zmove_count - @status_zmove_count
  end
  
  def wild_zpower_battles_won=(value)
    @wild_zpower_battles_won = 0 if !@wild_zpower_battles_won
    @wild_zpower_battles_won = value
  end
end

#-------------------------------------------------------------------------------
# Battle Rules.
#-------------------------------------------------------------------------------
class Game_Temp
  alias zmove_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "wildzmoves" then rules["wildBattleMode"] = :zmove
    when "nozmoves"   then rules["noZMoves"]       = var
    else
      zmove_add_battle_rule(rule, var)
    end
  end
end

alias zmove_additionalRules additionalRules
def additionalRules
  rules = zmove_additionalRules
  rules.push("nozmoves")
  return rules
end

#-------------------------------------------------------------------------------
# Used for wild Z-Powered battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_global, :wild_zpower_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle? || pbInSafari?
    next if battle.wildBattleMode != :zmove
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    when "RoundStartCommand_1_foe"
      if battle.pbCanZMove?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} gains a Z-Powered aura")
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 6
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
    when "RoundStartCommand_foe"
      next if battle.pbTriggerActivated?("BattlerReachedHPCap_foe")
      if foe.turnCount % 2 == 0 && battle.zMove[1][0] == -2
        PBDebug.log("[Midbattle Global] #{logname} able to use Z-Moves again")
        battle.zMove[1][0] = -1
        battle.pbAnimation(:DRAGONDANCE, foe, foe)
        battle.pbDisplay(_INTL("{1}'s Z-Power was replenished by its aura!", foe.pbThis))
      end	
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached")
      if foe.hasRaisedStatStages?
        foe.statsLoweredThisRound = true
        battle.pbCommonAnimation("StatDown", foe)
        GameData::Stat.each_main_battle do |s|
          foe.stages[s.id] = 0 if foe.stages[s.id] > 0
        end
      end
      battle.zMove[1][0] == -2
      battle.noBag = false
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("{1}'s aura faded!\nIt may now be captured!", foe.pbThis))
    when "BattleEndWin"
      if battle.wildBattleMode == :zmove
        $stats.wild_zpower_battles_won += 1
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a battler to use the Z-Powered version of their selected move.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "useZMove",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    next if battler.movedThisRound?
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :zmove if battler.wild? && oldMode != :zmove
    if battle.pbCanZMove?(battler.index) && battler.hasCompatibleZMove?(ch[2])
      PBDebug.log("     'useZMove': #{battler.name} (#{battler.index}) set to use a Z-Move")
      battle.scene.pbForceEndSpeech
      battler.display_zmoves
      ch[2] = battler.moves[ch[1]]
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Z-Moves for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableZMoves",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.zMove[side][owner] = (params) ? -2 : -1
    value = (params) ? "disabled" : "enabled"
    trainerName = battle.pbGetOwnerName(idxBattler)
    PBDebug.log("     'disableZMoves': Z-Moves #{value} for #{trainerName}")
  }
)


################################################################################
#
# Battle
#
################################################################################

class Battle
  attr_accessor :zMove
  
  #-----------------------------------------------------------------------------
  # Aliases for Z-Moves.
  #-----------------------------------------------------------------------------
  alias zpower_initialize initialize
  def initialize(*args)
    zpower_initialize(*args)
    @zMove = [
       [-1] * (@player ? @player.length : 1),
       [-1] * (@opponent ? @opponent.length : 1)
    ]
    @z_rings = []
    GameData::Item.each { |item| @z_rings.push(item.id) if item.has_flag?("ZRing") }
  end
  
  alias zmove_pbInitializeSpecialActions pbInitializeSpecialActions
  def pbInitializeSpecialActions(idxTrainer)
    return if !idxTrainer
    zmove_pbInitializeSpecialActions(idxTrainer)
    @zMove[1][idxTrainer] = -1
  end
  
  alias zmove_pbCanUseAnyBattleMechanic? pbCanUseAnyBattleMechanic?
  def pbCanUseAnyBattleMechanic?(idxBattler)
    return true if pbCanZMove?(idxBattler)
    return zmove_pbCanUseAnyBattleMechanic?(idxBattler)
  end
  
  alias zmove_pbCanUseBattleMechanic? pbCanUseBattleMechanic?
  def pbCanUseBattleMechanic?(idxBattler, mechanic)
    return true if mechanic == :zmove && pbCanZMove?(idxBattler)
    return zmove_pbCanUseBattleMechanic?(idxBattler, mechanic)
  end
  
  alias zmove_pbGetEligibleBattleMechanic pbGetEligibleBattleMechanic
  def pbGetEligibleBattleMechanic(idxBattler)
    return :zmove if pbCanZMove?(idxBattler)
    return zmove_pbGetEligibleBattleMechanic(idxBattler)
  end
  
  alias zmove_pbUnregisterAllSpecialActions pbUnregisterAllSpecialActions
  def pbUnregisterAllSpecialActions(idxBattler)
    zmove_pbUnregisterAllSpecialActions(idxBattler)
    @battlers[idxBattler].display_base_moves if pbRegisteredZMove?(idxBattler)
    pbUnregisterZMove(idxBattler)
  end
  
  alias zmove_pbBattleMechanicIsRegistered? pbBattleMechanicIsRegistered?
  def pbBattleMechanicIsRegistered?(idxBattler, mechanic)
    return true if mechanic == :zmove && pbRegisteredZMove?(idxBattler)
    return zmove_pbBattleMechanicIsRegistered?(idxBattler, mechanic)
  end
  
  alias zmove_pbToggleSpecialActions pbToggleSpecialActions
  def pbToggleSpecialActions(idxBattler, cmd)
    zmove_pbToggleSpecialActions(idxBattler, cmd)
    pbToggleRegisteredZMove(idxBattler) if cmd == :zmove
  end
  
  alias zmove_pbActionCommands pbActionCommands
  def pbActionCommands(side)
    zmove_pbActionCommands(side)
    @zMove[side].each_with_index do |zmove, i|
      @zMove[side][i] = -1 if zmove >= 0
    end
  end
  
  alias zmove_pbAttackPhaseSpecialActions3 pbAttackPhaseSpecialActions3
  def pbAttackPhaseSpecialActions3
    zmove_pbAttackPhaseSpecialActions3
    pbPriority.each do |b|
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @zMove[b.idxOwnSide][owner] != b.index
      b.selectedMoveIsZMove = true
    end
  end
  
  #-----------------------------------------------------------------------------
  # Z-Rings
  #-----------------------------------------------------------------------------
  def pbHasZRing?(idxBattler)
    return true if @battlers[idxBattler].wild?
    if pbOwnedByPlayer?(idxBattler)
      @z_rings.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @z_rings.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end
  
  def pbGetZRingName(idxBattler)
    if !@z_rings.empty?
      if pbOwnedByPlayer?(idxBattler)
        @z_rings.each { |item| return GameData::Item.get(item).portion_name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @z_rings.each { |item| return GameData::Item.get(item).portion_name if trainer_items&.include?(item) }
      end
    end
    return _INTL("Z-Ring")
  end
  
  #-----------------------------------------------------------------------------
  # Z-Move eligibility.
  #-----------------------------------------------------------------------------
  def pbCanZMove?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_ZMOVE]                    # No Z-Moves if switch enabled.
    return false if !battler.hasZMove?                                    # No Z-Moves if ineligible.
    return true  if $DEBUG && Input.press?(Input::CTRL) && !battler.wild? # Allows Z-Moves with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0              # No Z-Moves if in Sky Drop.
    return false if !pbHasZRing?(idxBattler)                              # No Z-Moves if no Z-Ring.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @zMove[side][owner] == -1
  end
  
  #-----------------------------------------------------------------------------
  # Registering Z-Moves.
  #-----------------------------------------------------------------------------
  def pbRegisterZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @zMove[side][owner] = idxBattler
  end
  
  def pbUnregisterZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @zMove[side][owner] = -1 if @zMove[side][owner] == idxBattler
  end

  def pbToggleRegisteredZMove(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @zMove[side][owner] == idxBattler
      @zMove[side][owner] = -1
    else
      @zMove[side][owner] = idxBattler
    end
  end
  
  def pbRegisteredZMove?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @zMove[side][owner] == idxBattler
  end
end


################################################################################
#
# Battle::Battler
#
################################################################################

class Battle::Battler
  #-----------------------------------------------------------------------------
  # Eligibility check.
  #-----------------------------------------------------------------------------
  def hasZMove?
    return false if shadowPokemon?
    return false if wild? && @battle.wildBattleMode != :zmove
    return false if ![nil, :ultra].include?(self.getActiveState)
    return false if hasEligibleAction?(:primal, :ultra, :zodiac)
    return hasCompatibleZMove?
  end
  
  #-----------------------------------------------------------------------------
  # Checks for compatible Z-Move.
  #-----------------------------------------------------------------------------
  def hasCompatibleZMove?(baseMove = nil)
    return false if !@item_id
    item = GameData::Item.get(@item_id)
    return false if !item.is_zcrystal?
    return false if @effects[PBEffects::Transform] && item.is_ultra_item?
    item = GameData::Item.get(@item_id)
    moves = (baseMove.nil?) ? @moves : [baseMove]
    if item.has_zmove_combo?
      return false if !GameData::Move.get(item.zmove).zMove?
      return false if !moves.any? { |m| m.id == item.zmove_base_move }
      pkmn = @effects[PBEffects::TransformPokemon] || @pokemon
      species = (item.has_flag?("UsableByAllForms")) ? pkmn.species : pkmn.species_data.id
      return item.zmove_species.include?(species)
    else
      return moves.any? { |m| m.type == item.zmove_type }
    end
  end
  
  #-----------------------------------------------------------------------------
  # Displays Z-Moves in the fight menu.
  #-----------------------------------------------------------------------------
  def display_zmoves
    return if !hasCompatibleZMove?
    item_data = GameData::Item.get(@item_id)
    pkmn = @effects[PBEffects::TransformPokemon] || @pokemon
    for i in 0...@moves.length
      @baseMoves.push(@moves[i])
      new_id = @moves[i].get_compatible_zmove(item_data, pkmn)
      next if !new_id
      @moves[i]          = @moves[i].make_zmove(new_id, @battle)
      @moves[i].pp       = [1, @baseMoves[i].pp].min
      @moves[i].total_pp = 1
    end
  end
end


################################################################################
#
# Battle::Scene
#
################################################################################

class Battle::Scene
  #-----------------------------------------------------------------------------
  # Aliases for Fight menu displays.
  #-----------------------------------------------------------------------------
  alias zmove_pbFightMenu_Confirm pbFightMenu_Confirm
  def pbFightMenu_Confirm(battler, specialAction, cw)
    ret = zmove_pbFightMenu_Confirm(battler, specialAction, cw)
    if specialAction == :zmove
      if cw.mode == 2
        baseMove = battler.baseMoves[cw.index]
        if !battler.hasCompatibleZMove?(baseMove)
          itemname = battler.item.name
          movename = battler.moves[cw.index].name
          @battle.pbDisplay(_INTL("{1} is not compatible with {2}!", movename, itemname))
          ret = :cancel
        end
      end
    end
    return ret
  end
  
  alias zmove_pbFightMenu_Cancel pbFightMenu_Cancel
  def pbFightMenu_Cancel(battler, specialAction, cw)
    ret = zmove_pbFightMenu_Cancel(battler, specialAction, cw)
    battler.display_base_moves if specialAction == :zmove
    return ret
  end

  alias zmove_pbFightMenu_Action pbFightMenu_Action
  def pbFightMenu_Action(battler, specialAction, cw)
    ret = zmove_pbFightMenu_Action(battler, specialAction, cw)
    if specialAction == :zmove
      (cw.mode == 1) ? battler.display_zmoves : battler.display_base_moves
      return true
    end
    return ret
  end
end

class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  alias zmove_addSpecialActionButtons addSpecialActionButtons
  def addSpecialActionButtons(path)
    zmove_addSpecialActionButtons(path)
    if pbResolveBitmap(path + "cursor_zmove")
      @actionButtonBitmap[:zmove] = AnimatedBitmap.new(_INTL(path + "cursor_zmove"))
    else
      @actionButtonBitmap[:zmove] = AnimatedBitmap.new(_INTL(Settings::ZMOVE_GRAPHICS_PATH + "cursor_zmove"))
    end
  end
end


################################################################################
#
# Pokemon
#
################################################################################

class Pokemon
  #-----------------------------------------------------------------------------
  # Checks if a Pokemon object is compatible with a Z-Crystal.
  #-----------------------------------------------------------------------------
  def has_zmove?(item = nil)
    return false if egg? || shadowPokemon? || dynamax? || tera? || celestial?
    item = (item) ? item : self.item
    item = GameData::Item.try_get(item)
    return false if !item || !item.is_zcrystal?
    if item.has_zmove_combo?
      return false if !GameData::Move.get(item.zmove).zMove?
      return false if !@moves.any? { |m| m.id == item.zmove_base_move }
      check_species = (item.has_flag?("UsableByAllForms")) ? @species : species_data.id
      return item.zmove_species.include?(check_species)
    else
      return @moves.any? { |m| m.type == item.zmove_type }
    end
  end
  
  #-----------------------------------------------------------------------------
  # Defines whether a Pokemon move is a Z-Move.
  #-----------------------------------------------------------------------------
  class Move
    def zMove?; return GameData::Move.get(@id).zMove?; end
  end
end