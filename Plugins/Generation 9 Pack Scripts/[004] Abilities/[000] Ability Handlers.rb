################################################################################
# 
# Ability triggers.
# 
################################################################################


module Battle::AbilityEffects
  OnTypeChange            = AbilityHandlerHash.new  # Protean, Libero
  OnOpposingStatGain      = AbilityHandlerHash.new  # Opportunist
  ModifyTypeEffectiveness = AbilityHandlerHash.new  # Tera Shell (damage)
  OnMoveSuccessCheck      = AbilityHandlerHash.new  # Tera Shell (display)
  OnInflictingStatus      = AbilityHandlerHash.new  # Poison Puppeteer

  def self.triggerOnStatusInflicted(ability, battler, user, status)
    OnInflictingStatus.trigger(user.ability, user, battler, status) if user && user.abilityActive? # Poison Puppeteer
    OnStatusInflicted.trigger(ability, battler, user, status)
  end
  
  def self.triggerOnSwitchIn(ability, battler, battle, switch_in = false)
    OnSwitchIn.trigger(ability, battler, battle, switch_in)
    battle.allSameSideBattlers(battler.index).each do |b|
      next if !b.hasActiveAbility?(:COMMANDER)
      next if b.effects[PBEffects::Commander]
      OnSwitchIn.trigger(b.ability, b, battle, switch_in)	  
    end
  end

  def self.triggerOnTypeChange(ability, battler, type)
    OnTypeChange.trigger(ability, battler, type)
  end

  def self.triggerOnOpposingStatGain(ability, battler, battle, statUps)
    OnOpposingStatGain.trigger(ability, battler, battle, statUps)
  end
  
  def self.triggerModifyTypeEffectiveness(ability, user, target, move, battle, effectiveness)
    return trigger(ModifyTypeEffectiveness, ability, user, target, move, battle, effectiveness, ret: effectiveness)
  end
  
  def self.triggerOnMoveSuccessCheck(ability, user, target, move, battle)
    OnMoveSuccessCheck.trigger(ability, user, target, move, battle)
  end

  def self.triggerOnInflictingStatus(ability, battler, user, status)
    OnInflictingStatus.trigger(ability, battler, user, status)
  end
end


################################################################################
# 
# Updates to old ability handlers.
# 
################################################################################


#===============================================================================
# Insomnia, Vital Spirit
#===============================================================================
# Adds Drowsy as a status that may be healed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::StatusCure.add(:INSOMNIA,
  proc { |ability, battler|
    next if ![:SLEEP, :DROWSY].include?(battler.status)
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case battler.status
      when :SLEEP  then msg = _INTL("{1}的{2}让自己醒过来了！", battler.pbThis, battler.abilityName)
      when :DROWSY then msg = _INTL("{1}的{2}清醒过来了！", battler.pbThis, battler.abilityName)
      end
      battler.battle.pbDisplay(msg)
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:INSOMNIA, :VITALSPIRIT)

Battle::AbilityEffects::OnSwitchOut.add(:INSOMNIA,
  proc { |ability, battler, endOfBattle|
    next if ![:SLEEP, :DROWSY].include?(battler.status)
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:INSOMNIA, :VITALSPIRIT)

#===============================================================================
# Magma Armor
#===============================================================================
# Adds Frostbite as a status that may be healed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::StatusCure.add(:MAGMAARMOR,
  proc { |ability, battler|
    next if ![:FROZEN, :FROSTBITE].include?(battler.status)
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case battler.status
      when :FROZEN    then msg = _INTL("{1}的{2}治愈了冰冻状态！", battler.pbThis, battler.abilityName)
      when :FROSTBITE then msg = _INTL("{1}的{2}治愈了伙伴的冻伤！", battler.pbThis, battler.abilityName)
      end
      battler.battle.pbDisplay(msg)
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:MAGMAARMOR,
  proc { |ability, battler, endOfBattle|
    next if ![:FROZEN, :FROSTBITE].include?(battler.status)
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

#===============================================================================
# Healer
#===============================================================================
# Adds Drowsy/Frostbite as statuses that may be healed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::EndOfRoundHealing.add(:HEALER,
  proc { |ability, battler, battle|
    next unless battle.pbRandom(100) < 30
    battler.allAllies.each do |b|
      next if b.status == :NONE
      battle.pbShowAbilitySplash(battler)
      oldStatus = b.status
      b.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
      if !Battle::Scene::USE_ABILITY_SPLASH
        case oldStatus
        when :SLEEP
          battle.pbDisplay(_INTL("{1}的{2}让队友醒过来了！", battler.pbThis, battler.abilityName))
        when :POISON
          battle.pbDisplay(_INTL("{1}的{2}治愈了队友的中毒！", battler.pbThis, battler.abilityName))
        when :BURN
          battle.pbDisplay(_INTL("{1}的{2}治愈了队友的灼伤！", battler.pbThis, battler.abilityName))
        when :PARALYSIS
          battle.pbDisplay(_INTL("{1}的{2}治愈了队友的麻痹！", battler.pbThis, battler.abilityName))
        when :FROZEN
          battle.pbDisplay(_INTL("{1}的{2}治愈了队友的冰冻！", battler.pbThis, battler.abilityName))
        when :DROWSY
          battle.pbDisplay(_INTL("{1}的{2}让伙伴清醒过来了！", battler.pbThis, battler.abilityName))
        when :FROSTBITE
          battle.pbDisplay(_INTL("{1}的{2}治愈了伙伴的冻伤！", battler.pbThis, battler.abilityName))
        end
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

#===============================================================================
# Hydration
#===============================================================================
# Adds Drowsy/Frostbite as statuses that may be healed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::EndOfRoundHealing.add(:HYDRATION,
  proc { |ability, battler, battle|
    next if battler.status == :NONE
    next if ![:Rain, :HeavyRain].include?(battler.effectiveWeather)
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case oldStatus
      when :SLEEP
        battle.pbDisplay(_INTL("{1}的{2}让队友醒过来了！", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的中毒！", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的灼伤！", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的麻痹！", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的冰冻！", battler.pbThis, battler.abilityName))
      when :DROWSY
        battle.pbDisplay(_INTL("{1}的{2}让伙伴清醒过来了！", battler.pbThis, battler.abilityName))
      when :FROSTBITE
        battle.pbDisplay(_INTL("{1}的{2}治愈了伙伴的冻伤！", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# Shed Skin
#===============================================================================
# Adds Drowsy/Frostbite as statuses that may be healed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::EndOfRoundHealing.add(:SHEDSKIN,
  proc { |ability, battler, battle|
    next if battler.status == :NONE
    next unless battle.pbRandom(100) < 30
    battle.pbShowAbilitySplash(battler)
    oldStatus = battler.status
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      case oldStatus
      when :SLEEP
        battle.pbDisplay(_INTL("{1}的{2}让队友醒过来了！", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的中毒！", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的灼伤！", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的麻痹！", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("{1}的{2}治愈了队友的冰冻！", battler.pbThis, battler.abilityName))
      when :DROWSY
        battle.pbDisplay(_INTL("{1}的{2}让伙伴清醒过来了！", battler.pbThis, battler.abilityName))
      when :FROSTBITE
        battle.pbDisplay(_INTL("{1}的{2}治愈了伙伴的冻伤！", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# Synchronize
#===============================================================================
# Adds Drowsy/Frostbite as statuses that may be passed.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnStatusInflicted.add(:SYNCHRONIZE,
  proc { |ability, battler, user, status|
    next if !user || user.index == battler.index
    case status
    when :POISON
      if user.pbCanPoisonSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("{1}的{2}让{3}中毒了！", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbPoison(nil, msg, (battler.statusCount > 0))
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :BURN
      if user.pbCanBurnSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("{1}的{2}让{3}灼伤了！", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbBurn(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :PARALYSIS
      if user.pbCanParalyzeSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("{1}的{2}让{3}麻痹了！很难使出招式！",
             battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbParalyze(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :DROWSY
      if user.pbCanSynchronizeStatus?(:SLEEP, battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("{1}的{2}让{3}瞌睡了！可能无法行动！",
             battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbSleep(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :FROSTBITE
      if user.pbCanSynchronizeStatus?(:FROZEN, battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("{1}的{2}让{3}冻伤了！", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbFreeze(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

#===============================================================================
# Poison Touch
#===============================================================================
# Adds Covert Cloak immunity.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnDealingHit.add(:POISONTOUCH,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
    next if !move.contactMove?
    next if battle.pbRandom(100) >= 30
    next if target.hasActiveItem?(:COVERTCLOAK)
    battle.pbShowAbilitySplash(user)
    if target.hasActiveAbility?(:SHIELDDUST) && !battle.moldBreaker
      battle.pbShowAbilitySplash(target)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("对于{1}，完全没有效果！", target.pbThis))
      end
      battle.pbHideAbilitySplash(target)
    elsif target.pbCanPoison?(user, Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1}的{2}让{3}中毒了！", user.pbThis, user.abilityName, target.pbThis(true))
      end
      target.pbPoison(user, msg)
    end
    battle.pbHideAbilitySplash(user)
  }
)

#===============================================================================
# Power of Alchemy, Receiver
#===============================================================================
# Adds Ability Shield immunity.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::ChangeOnBattlerFainting.add(:POWEROFALCHEMY,
  proc { |ability, battler, fainted, battle|
    next if battler.opposes?(fainted)
    next if fainted.uncopyableAbility?
    next if battler.hasActiveItem?(:ABILITYSHIELD)
    battle.pbShowAbilitySplash(battler, true)
    battler.ability = fainted.ability
    battle.pbReplaceAbilitySplash(battler)
    battle.pbDisplay(_INTL("继承了{1}的{2}！", fainted.pbThis, fainted.abilityName))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::ChangeOnBattlerFainting.copy(:POWEROFALCHEMY, :RECEIVER)


#===============================================================================
# Mummy
#===============================================================================
# Adds Ability Shield immunity. Lingering Aroma ability uses the same code.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:MUMMY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.unstoppableAbility?
    next if [:MUMMY, :LINGERINGAROMA].include?(user.ability_id)
    next if user.hasActiveItem?(:ABILITYSHIELD)
    oldAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = ability
      battle.pbReplaceAbilitySplash(user) if user.opposes?(target)
      if Battle::Scene::USE_ABILITY_SPLASH
	    case ability
        when :MUMMY
          msg = _INTL("{1}的特性变成了{2}！", user.pbThis, user.abilityName)
        when :LINGERINGAROMA
          msg = _INTL("{1}沾上了味道且挥之不去！", user.pbThis(true))
        end
        battle.pbDisplay(msg)
      else
        battle.pbDisplay(_INTL("由于{3}，{1}的特性变成了{2}！",
           user.pbThis, user.abilityName, target.pbThis(true)))
      end
      battle.pbHideAbilitySplash(user) if user.opposes?(target)
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldAbil)
    user.pbTriggerAbilityOnGainingIt
  }
)

#===============================================================================
# Wandering Spirit
#===============================================================================
# Adds Ability Shield immunity.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:WANDERINGSPIRIT,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.uncopyableAbility?
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
        battle.pbDisplay(_INTL("{1}与{2}互换了各自的特性！", target.pbThis, user.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}的{2}与{3}的{4}特性互换了！",
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

#===============================================================================
# Neutralizing Gas
#===============================================================================
# Adds Ability Shield immunity.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:NEUTRALIZINGGAS,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.pbDisplay(_INTL("周围充满了化学变化气体！"))
    battle.allBattlers.each do |b|
      if b.hasActiveItem?(:ABILITYSHIELD)
        itemname = GameData::Item.get(b.item).name
        battle.pbDisplay(_INTL("{1}的特性受到了{2}的保护！", b.pbThis, itemname))
        next
      end
      b.effects[PBEffects::SlowStart] = 0
      b.effects[PBEffects::Truant] = false
      if !b.hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF])
        b.effects[PBEffects::ChoiceBand] = nil
      end
      if b.effects[PBEffects::Illusion]
        b.effects[PBEffects::Illusion] = nil
        if !b.effects[PBEffects::Transform]
          battle.scene.pbChangePokemon(b, b.pokemon)
          battle.pbDisplay(_INTL("{1}的{2}消失了！", b.pbThis, b.abilityName))
          battle.pbSetSeen(b)
        end
      end
    end
    battler.ability_id = nil
    had_unnerve = battle.pbCheckGlobalAbility(:UNNERVE)
    battler.ability_id = :NEUTRALIZINGGAS
    if had_unnerve && !battle.pbCheckGlobalAbility(:UNNERVE)
      battle.allBattlers.each { |b| b.pbItemsOnUnnerveEnding }
    end
  }
)

#===============================================================================
# Intimidate
#===============================================================================
# Targets with Guard Dog don't proc items that are only used when Intimidated.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:INTIMIDATE,
  proc { |ability, battler, battle, switch_in|
    next if battler.effects[PBEffects::OneUseAbility] == ability
    battle.pbShowAbilitySplash(battler)
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler)
      check_item = true
      if b.hasActiveAbility?([:CONTRARY, :GUARDDOG])
        check_item = false if b.statStageAtMax?(:ATTACK)
      elsif b.statStageAtMin?(:ATTACK)
        check_item = false
      end
      check_ability = b.pbLowerAttackStatStageIntimidate(battler)
      b.pbAbilitiesOnIntimidated if check_ability
      b.pbItemOnIntimidatedCheck if check_item
    end
    battle.pbHideAbilitySplash(battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

#===============================================================================
# Anger Point
#===============================================================================
# Allows Mirror Herb/Opportunist to copy the stat boosts granted by this ability.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:ANGERPOINT,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.critical
    next if !target.pbCanRaiseStatStage?(:ATTACK, target)
    battle.pbShowAbilitySplash(target)
    target.stages[:ATTACK] = 6
    target.addSideStatUps(:ATTACK, 6)
    target.statsRaisedThisRound = true
    battle.pbCommonAnimation("StatUp", target)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}使{2}最大化了！", target.pbThis, GameData::Stat.get(:ATTACK).name))
    else
      battle.pbDisplay(_INTL("{1}的{2}使{3}最大化了！",
         target.pbThis, target.abilityName, GameData::Stat.get(:ATTACK).name))
    end
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Dauntless Shield
#===============================================================================
# Adds once-per-battle check.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:DAUNTLESSSHIELD,
  proc { |ability, battler, battle, switch_in|
    next if Settings::MECHANICS_GENERATION >= 9 && battler.ability_triggered?
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

#===============================================================================
# Intrepid Sword
#===============================================================================
# Adds once-per-battle check.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnSwitchIn.add(:INTREPIDSWORD,
  proc { |ability, battler, battle, switch_in|
    next if Settings::MECHANICS_GENERATION >= 9 && battler.ability_triggered?
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

#===============================================================================
# Protean, Libero
#===============================================================================
# Gen 9+ version that only triggers once per switch-in.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnTypeChange.add(:PROTEAN,
  proc { |ability, battler, type|
    next if Settings::MECHANICS_GENERATION < 9
    next if GameData::Type.get(type).pseudo_type
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnTypeChange.copy(:PROTEAN, :LIBERO)

#===============================================================================
# Battle Bond
#===============================================================================
# Gen 9+ version that boosts stats instead of becoming Ash-Greninja.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnEndOfUsingMove.add(:BATTLEBOND,
  proc { |ability, user, targets, move, battle|
    next if Settings::MECHANICS_GENERATION < 9
    next if user.fainted? || battle.pbAllFainted?(user.idxOpposingSide)
    next if !user.isSpecies?(:GRENINJA) || user.effects[PBEffects::Transform]
    next if battle.battleBond[user.index & 1][user.pokemonIndex]
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0
    battle.pbShowAbilitySplash(user)
    battle.battleBond[user.index & 1][user.pokemonIndex] = true
    battle.pbDisplay(_INTL("{1}浑身充满了牵绊之力！", user.pbThis))
    battle.pbHideAbilitySplash(user)
    showAnim = true
    [:ATTACK, :SPECIAL_ATTACK, :SPEED].each do |stat|
      next if !user.pbCanRaiseStatStage?(stat, user)
      if user.pbRaiseStatStage(stat, 1, user, showAnim)
        showAnim = false
      end
    end
    battle.pbDisplay(_INTL("{1}的能力已经无法再提高了！", user.pbThis)) if showAnim
  }
)

#===============================================================================
# Illuminate
#===============================================================================
# Gen 9+ version prevents loss of accuracy and ignores target's evasion bonuses.
#-------------------------------------------------------------------------------
if Settings::MECHANICS_GENERATION >= 9
  Battle::AbilityEffects::StatLossImmunity.copy(:KEENEYE, :ILLUMINATE)
  Battle::AbilityEffects::AccuracyCalcFromUser.copy(:KEENEYE, :ILLUMINATE)
end

#===============================================================================
# Transistor
#===============================================================================
# Gen 9+ version reduces power bonus from 50% to 30%
#-------------------------------------------------------------------------------
Battle::AbilityEffects::DamageCalcFromUser.add(:TRANSISTOR,
  proc { |ability, user, target, move, mults, power, type|
    bonus = (Settings::MECHANICS_GENERATION >= 9) ? 1.3 : 1.5
    mults[:attack_multiplier] *= bonus if type == :ELECTRIC
  }
)