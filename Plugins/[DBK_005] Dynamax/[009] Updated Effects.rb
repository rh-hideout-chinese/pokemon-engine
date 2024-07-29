################################################################################
#
# Items
#
################################################################################

#===============================================================================
# Choice Scarf
#===============================================================================
# Speed boost is ignored while the user is Dynamaxed.
#-------------------------------------------------------------------------------
Battle::ItemEffects::SpeedCalc.add(:CHOICESCARF,
  proc { |item, battler, mult|
    next mult * 1.5 if !battler.dynamax?
  }
)

#===============================================================================
# Red Card
#===============================================================================
# Item triggers, but its effects fail to activate vs Dynamax targets.
#-------------------------------------------------------------------------------
Battle::ItemEffects::AfterMoveUseFromTarget.add(:REDCARD,
  proc { |item, battler, user, move, switched_battlers, battle|
    next if !switched_battlers.empty? || user.fainted?
    newPkmn = battle.pbGetReplacementPokemonIndex(user.index, true)
    next if newPkmn < 0
    battle.pbCommonAnimation("UseItem", battler)
    battle.pbDisplay(_INTL("{1} held up its {2} against {3}!",
       battler.pbThis, battler.itemName, user.pbThis(true)))
    battler.pbConsumeItem
    if user.dynamax?
      battle.pbDisplay(_INTL("But it failed!"))
      next
    end
    next if defined?(PBEffects::Commander) && user.effects[PBEffects::Commander]
    if user.hasActiveAbility?([:SUCTIONCUPS, :GUARDDOG]) && !battle.moldBreaker
      battle.pbShowAbilitySplash(user)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1} anchors itself!", user.pbThis))
      else
        battle.pbDisplay(_INTL("{1} anchors itself with {2}!", user.pbThis, user.abilityName))
      end
      battle.pbHideAbilitySplash(user)
      next
    end
    if user.effects[PBEffects::Ingrain]
      battle.pbDisplay(_INTL("{1} anchored itself with its roots!", user.pbThis))
      next
    end
    battle.pbRecallAndReplace(user.index, newPkmn, true)
    battle.pbDisplay(_INTL("{1} was dragged out!", user.pbThis))
    battle.pbClearChoice(user.index)
    switched_battlers.push(user.index)
    battle.moldBreaker = false
    battle.pbOnBattlerEnteringBattle(user.index)
  }
)

#===============================================================================
# Leppa Berry
#===============================================================================
# Restores the PP of the user's base move while Dynamaxed.
#-------------------------------------------------------------------------------
Battle::ItemEffects::OnEndOfUsingMove.add(:LEPPABERRY,
  proc { |item, battler, battle, forced|
    next false if !forced && !battler.canConsumeBerry?
    found_empty_moves = []
    found_partial_moves = []
    battler.pokemon.moves.each_with_index do |move, i|
      next if move.total_pp <= 0 || move.pp == move.total_pp
      (move.pp == 0) ? found_empty_moves.push(i) : found_partial_moves.push(i)
    end
    next false if found_empty_moves.empty? && (!forced || found_partial_moves.empty?)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    amt = 10
    ripening = false
    if battler.hasActiveAbility?(:RIPEN)
      battle.pbShowAbilitySplash(battler, forced)
      amt *= 2
      ripening = true
    end
    battle.pbCommonAnimation("EatBerry", battler) if !forced
    battle.pbHideAbilitySplash(battler) if ripening
    choice = found_empty_moves.first
    choice = found_partial_moves.first if forced && choice.nil?
    pkmnMove = battler.pokemon.moves[choice]
    pkmnMove.pp += amt
    pkmnMove.pp = pkmnMove.total_pp if pkmnMove.pp > pkmnMove.total_pp
    battler.moves[choice].pp = pkmnMove.pp
    battler.baseMoves[choice].pp = pkmnMove.pp if battler.baseMoves[choice]
    moveName = pkmnMove.name
    if forced
      battle.pbDisplay(_INTL("{1} restored its {2}'s PP.", battler.pbThis, moveName))
    else
      battle.pbDisplay(_INTL("{1}'s {2} restored its {3}'s PP!", battler.pbThis, itemName, moveName))
    end
    next true
  }
)


################################################################################
#
# Abilities
#
################################################################################

#===============================================================================
# Cursed Body
#===============================================================================
# Ability fails to trigger if the attacker is a Dynamaxed Pokemon.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:CURSEDBODY,
  proc { |ability, user, target, move, battle|
    next if user.fainted? || user.dynamax?
    next if user.effects[PBEffects::Disable] > 0
    regularMove = nil
    user.eachMove do |m|
      next if m.id != user.lastRegularMoveUsed
      regularMove = m
      break
    end
    next if !regularMove || (regularMove.pp == 0 && regularMove.total_pp > 0)
    next if battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if !move.pbMoveFailedAromaVeil?(target, user, Battle::Scene::USE_ABILITY_SPLASH)
      user.effects[PBEffects::Disable]     = 3
      user.effects[PBEffects::DisableMove] = regularMove.id
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}'s {2} was disabled!", user.pbThis, regularMove.name))
      else
        battle.pbDisplay(_INTL("{1}'s {2} was disabled by {3}'s {4}!",
           user.pbThis, regularMove.name, target.pbThis(true), target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
      user.pbItemStatusCureCheck
    end
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Wandering Spirit
#===============================================================================
# Ability fails to trigger if the attacker is a Dynamaxed Pokemon.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:WANDERINGSPIRIT,
  proc { |ability, user, target, move, battle|
    next if user.dynamax?
    next if !move.pbContactMove?(user)
    next if user.ungainableAbility? || [:RECEIVER, :WONDERGUARD].include?(user.ability_id)
    next if user.hasActiveItem?(:ABILITYSHIELD) || target.hasActiveItem?(:ABILITYSHIELD)
    oldUserAbil   = nil
    oldTargetAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      oldUserAbil   = user.ability
      oldTargetAbil = target.ability
      user.ability   = oldTargetAbil
      target.ability = oldUserAbil
      if user.opposes?(target)
        battle.pbReplaceAbilitySplash(user)
        battle.pbReplaceAbilitySplash(target)
      end
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1} swapped Abilities with {2}!", target.pbThis, user.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1} swapped its {2} Ability with {3}'s {4} Ability!",
           target.pbThis, user.abilityName, user.pbThis(true), target.abilityName))
      end
      if user.opposes?(target)
        battle.pbHideAbilitySplash(user)
        battle.pbHideAbilitySplash(target)
      end
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldUserAbil)
    target.pbOnLosingAbility(oldTargetAbil)
    user.pbTriggerAbilityOnGainingIt
    target.pbTriggerAbilityOnGainingIt
  }
)


################################################################################
#
# Moves
#
################################################################################

#===============================================================================
# Rapid Spin
#===============================================================================
# Also clears away hazard applied with G-Max Steelsurge.
#-------------------------------------------------------------------------------
class Battle::Move::RemoveUserBindingAndEntryHazards < Battle::Move::StatUpMove
  alias dynamax_pbEffectAfterAllHits pbEffectAfterAllHits
  def pbEffectAfterAllHits(user, target)
    dynamax_pbEffectAfterAllHits(user,target)
    if user.pbOwnSide.effects[PBEffects::Steelsurge]
      user.pbOwnSide.effects[PBEffects::Steelsurge] = false
      @battle.pbDisplay(_INTL("{1} blew away the pointed steel!", user.pbThis))
    end
  end
end

#===============================================================================
# Defog
#===============================================================================
# Also clears away hazard applied with G-Max Steelsurge.
#-------------------------------------------------------------------------------
class Battle::Move::LowerTargetEvasion1RemoveSideEffects < Battle::Move::TargetStatDownMove
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    return false if Settings::MECHANICS_GENERATION >= 6 && target.pbOpposingSide.effects[PBEffects::Steelsurge]
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
  
  alias dynamax_pbEffectAgainstTarget pbEffectAgainstTarget
  def pbEffectAgainstTarget(user, target)
    dynamax_pbEffectAgainstTarget(user, target)
    if target.pbOwnSide.effects[PBEffects::Steelsurge] ||
       (Settings::MECHANICS_GENERATION >= 6 && target.pbOpposingSide.effects[PBEffects::Steelsurge])
      target.pbOwnSide.effects[PBEffects::Steelsurge]      = false
      target.pbOpposingSide.effects[PBEffects::Steelsurge] = false if Settings::MECHANICS_GENERATION >= 6
      @battle.pbDisplay(_INTL("{1} blew away the pointed steel!", user.pbThis))
    end
  end
end

#===============================================================================
# Court Change
#===============================================================================
# Also swaps side effects of certain G-Max moves.
#-------------------------------------------------------------------------------
class Battle::Move::SwapSideEffects < Battle::Move
  alias dynamax_initialize initialize
  def initialize(battle, move)
    dynamax_initialize(battle, move)
    @boolean_effects.push(PBEffects::Steelsurge)
    @number_effects += [
      PBEffects::Cannonade, 
      PBEffects::VineLash, 
      PBEffects::Volcalith, 
      PBEffects::Wildfire
    ]
  end
end

#===============================================================================
# Low Kick, Grass Knot
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::PowerHigherWithTargetWeight < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Heavy Slam, Heat Crash
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::PowerHigherWithUserHeavierThanTarget < Battle::Move
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return false
  end
end

#===============================================================================
# Entrainment
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::SetTargetAbilityToUserAbility < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Skill Swap
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::UserTargetSwapAbilities < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Copycat
#===============================================================================
# If last move used was a Dynamax Move, copies the base move instead.
#-------------------------------------------------------------------------------
class Battle::Move::UseLastMoveUsed < Battle::Move
  def pbChangeUsageCounters(user, specialUsage)
    super
    @copied_move = @battle.lastMoveUsed
    @copied_user = @battle.lastMoveUser
  end
  
  def pbEffectGeneral(user)
    if GameData::Move.get(@copied_move).dynamaxMove?
      battler = @battle.battlers[@copied_user]
      if battler
        idxMove = battler.powerMoveIndex
        moves = (battler.dynamax?) ? battler.baseMoves : battler.moves
        @copied_move = moves[idxMove].id
      else
        @battle.pbDisplay(_INTL("But it failed!"))
        return
      end
    end
    user.pbUseMoveSimple(@copied_move)
  end
end

#===============================================================================
# Disable
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::DisableTargetLastMoveUsed < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Encore
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::DisableTargetUsingDifferentMove < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Torment
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::DisableTargetUsingSameMoveConsecutively < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Instruct
#===============================================================================
# Fails to work on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::TargetUsesItsLastUsedMoveAgain < Battle::Move
  alias dynamax_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.dynamax?
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return dynamax_pbFailsAgainstTarget?(user, target, show_message)
  end
end

#===============================================================================
# Dragon Tail, Circle Throw
#===============================================================================
# Forced switch fails to trigger on Dynamax targets.
#-------------------------------------------------------------------------------
class Battle::Move::SwitchOutTargetDamagingMove < Battle::Move
  def pbSwitchOutTargetEffect(user, targets, numHits, switched_battlers)
    return if @battle.wildBattle? || !switched_battlers.empty?
    return if user.fainted? || numHits == 0
    targets.each do |b|
      next if b.fainted? || b.damageState.unaffected || b.damageState.substitute || b.dynamax?
      next if b.effects[PBEffects::Ingrain]
      next if b.hasActiveAbility?([:SUCTIONCUPS, :GUARDDOG]) && !@battle.moldBreaker
      next if defined?(b.isCommander?) && b.isCommander?
      newPkmn = @battle.pbGetReplacementPokemonIndex(b.index, true)
      next if newPkmn < 0
      @battle.pbRecallAndReplace(b.index, newPkmn, true)
      @battle.pbDisplay(_INTL("{1} was dragged out!", b.pbThis))
      @battle.pbClearChoice(b.index)
      @battle.pbOnBattlerEnteringBattle(b.index)
      switched_battlers.push(b.index)
      break
    end
  end
end

#===============================================================================
# Behemoth Blade, Behemoth Bash, Dynamax Cannon
#===============================================================================
# Deals double damage vs Dynamax targets, unless they're in Eternamax form.
#-------------------------------------------------------------------------------
class Battle::Move::DoubleDamageOnDynamaxTargets < Battle::Move
  def pbBaseDamage(baseDmg, user, target)
    baseDmg *= 2 if target.dynamax? && !target.emax?
    return baseDmg
  end
end