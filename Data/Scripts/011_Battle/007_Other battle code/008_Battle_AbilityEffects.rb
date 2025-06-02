#===============================================================================
#
#===============================================================================
module Battle::AbilityEffects
  SpeedCalc                        = AbilityHandlerHash.new
  WeightCalc                       = AbilityHandlerHash.new
  # Battler's HP/stat changed
  OnHPDroppedBelowHalf             = AbilityHandlerHash.new
  # Battler's status problem
  StatusCheckNonIgnorable          = AbilityHandlerHash.new   # Comatose
  StatusImmunity                   = AbilityHandlerHash.new
  StatusImmunityNonIgnorable       = AbilityHandlerHash.new
  StatusImmunityFromAlly           = AbilityHandlerHash.new
  OnStatusInflicted                = AbilityHandlerHash.new   # Synchronize
  StatusCure                       = AbilityHandlerHash.new
  # Battler's stat stages
  StatLossImmunity                 = AbilityHandlerHash.new
  StatLossImmunityNonIgnorable     = AbilityHandlerHash.new   # Full Metal Body
  StatLossImmunityFromAlly         = AbilityHandlerHash.new   # Flower Veil
  OnStatGain                       = AbilityHandlerHash.new   # None!
  OnStatLoss                       = AbilityHandlerHash.new
  # Priority and turn order
  PriorityChange                   = AbilityHandlerHash.new
  PriorityBracketChange            = AbilityHandlerHash.new   # Stall
  PriorityBracketUse               = AbilityHandlerHash.new   # None!
  # Move usage failures
  OnFlinch                         = AbilityHandlerHash.new   # Steadfast
  MoveBlocking                     = AbilityHandlerHash.new
  MoveImmunity                     = AbilityHandlerHash.new
  # Move usage
  ModifyMoveBaseType               = AbilityHandlerHash.new
  # Accuracy calculation
  AccuracyCalcFromUser             = AbilityHandlerHash.new
  AccuracyCalcFromAlly             = AbilityHandlerHash.new   # Victory Star
  AccuracyCalcFromTarget           = AbilityHandlerHash.new
  # Damage calculation
  DamageCalcFromUser               = AbilityHandlerHash.new
  DamageCalcFromAlly               = AbilityHandlerHash.new
  DamageCalcFromTarget             = AbilityHandlerHash.new
  DamageCalcFromTargetNonIgnorable = AbilityHandlerHash.new
  DamageCalcFromTargetAlly         = AbilityHandlerHash.new
  CriticalCalcFromUser             = AbilityHandlerHash.new
  CriticalCalcFromTarget           = AbilityHandlerHash.new
  # Upon a move hitting a target
  OnBeingHit                       = AbilityHandlerHash.new
  OnDealingHit                     = AbilityHandlerHash.new   # Poison Touch
  # Abilities that trigger at the end of using a move
  OnEndOfUsingMove                 = AbilityHandlerHash.new
  AfterMoveUseFromTarget           = AbilityHandlerHash.new
  # End Of Round
  EndOfRoundWeather                = AbilityHandlerHash.new
  EndOfRoundHealing                = AbilityHandlerHash.new
  EndOfRoundEffect                 = AbilityHandlerHash.new
  EndOfRoundGainItem               = AbilityHandlerHash.new
  # Switching and fainting
  CertainSwitching                 = AbilityHandlerHash.new   # None!
  TrappingByTarget                 = AbilityHandlerHash.new
  OnSwitchIn                       = AbilityHandlerHash.new
  OnSwitchOut                      = AbilityHandlerHash.new
  ChangeOnBattlerFainting          = AbilityHandlerHash.new
  OnBattlerFainting                = AbilityHandlerHash.new   # Soul-Heart
  OnTerrainChange                  = AbilityHandlerHash.new   # Mimicry
  OnIntimidated                    = AbilityHandlerHash.new   # Rattled (Gen 8)
  # Running from battle
  CertainEscapeFromBattle          = AbilityHandlerHash.new   # Run Away

  #=============================================================================

  def self.trigger(hash, *args, ret: false)
    new_ret = hash.trigger(*args)
    return (!new_ret.nil?) ? new_ret : ret
  end

  #=============================================================================

  def self.triggerSpeedCalc(ability, battler, mult)
    return trigger(SpeedCalc, ability, battler, mult, ret: mult)
  end

  def self.triggerWeightCalc(ability, battler, weight)
    return trigger(WeightCalc, ability, battler, weight, ret: weight)
  end

  #=============================================================================

  def self.triggerOnHPDroppedBelowHalf(ability, user, move_user, battle)
    return trigger(OnHPDroppedBelowHalf, ability, user, move_user, battle)
  end

  #=============================================================================

  def self.triggerStatusCheckNonIgnorable(ability, battler, status)
    return trigger(StatusCheckNonIgnorable, ability, battler, status)
  end

  def self.triggerStatusImmunity(ability, battler, status)
    return trigger(StatusImmunity, ability, battler, status)
  end

  def self.triggerStatusImmunityNonIgnorable(ability, battler, status)
    return trigger(StatusImmunityNonIgnorable, ability, battler, status)
  end

  def self.triggerStatusImmunityFromAlly(ability, battler, status)
    return trigger(StatusImmunityFromAlly, ability, battler, status)
  end

  def self.triggerOnStatusInflicted(ability, battler, user, status)
    OnStatusInflicted.trigger(ability, battler, user, status)
  end

  def self.triggerStatusCure(ability, battler)
    return trigger(StatusCure, ability, battler)
  end

  #=============================================================================

  def self.triggerStatLossImmunity(ability, battler, stat, battle, show_messages)
    return trigger(StatLossImmunity, ability, battler, stat, battle, show_messages)
  end

  def self.triggerStatLossImmunityNonIgnorable(ability, battler, stat, battle, show_messages)
    return trigger(StatLossImmunityNonIgnorable, ability, battler, stat, battle, show_messages)
  end

  def self.triggerStatLossImmunityFromAlly(ability, bearer, battler, stat, battle, show_messages)
    return trigger(StatLossImmunityFromAlly, ability, bearer, battler, stat, battle, show_messages)
  end

  def self.triggerOnStatGain(ability, battler, stat, user)
    OnStatGain.trigger(ability, battler, stat, user)
  end

  def self.triggerOnStatLoss(ability, battler, stat, user)
    OnStatLoss.trigger(ability, battler, stat, user)
  end

  #=============================================================================

  def self.triggerPriorityChange(ability, battler, move, priority)
    return trigger(PriorityChange, ability, battler, move, priority, ret: priority)
  end

  def self.triggerPriorityBracketChange(ability, battler, battle)
    return trigger(PriorityBracketChange, ability, battler, battle, ret: 0)
  end

  def self.triggerPriorityBracketUse(ability, battler, battle)
    PriorityBracketUse.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerOnFlinch(ability, battler, battle)
    OnFlinch.trigger(ability, battler, battle)
  end

  def self.triggerMoveBlocking(ability, bearer, user, targets, move, battle)
    return trigger(MoveBlocking, ability, bearer, user, targets, move, battle)
  end

  def self.triggerMoveImmunity(ability, user, target, move, type, battle, show_message)
    return trigger(MoveImmunity, ability, user, target, move, type, battle, show_message)
  end

  #=============================================================================

  def self.triggerModifyMoveBaseType(ability, user, move, type)
    return trigger(ModifyMoveBaseType, ability, user, move, type, ret: type)
  end

  #=============================================================================

  def self.triggerAccuracyCalcFromUser(ability, mods, user, target, move, type)
    AccuracyCalcFromUser.trigger(ability, mods, user, target, move, type)
  end

  def self.triggerAccuracyCalcFromAlly(ability, mods, user, target, move, type)
    AccuracyCalcFromAlly.trigger(ability, mods, user, target, move, type)
  end

  def self.triggerAccuracyCalcFromTarget(ability, mods, user, target, move, type)
    AccuracyCalcFromTarget.trigger(ability, mods, user, target, move, type)
  end

  #=============================================================================

  def self.triggerDamageCalcFromUser(ability, user, target, move, mults, power, type)
    DamageCalcFromUser.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromAlly(ability, user, target, move, mults, power, type)
    DamageCalcFromAlly.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTarget(ability, user, target, move, mults, power, type)
    DamageCalcFromTarget.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTargetNonIgnorable(ability, user, target, move, mults, power, type)
    DamageCalcFromTargetNonIgnorable.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerDamageCalcFromTargetAlly(ability, user, target, move, mults, power, type)
    DamageCalcFromTargetAlly.trigger(ability, user, target, move, mults, power, type)
  end

  def self.triggerCriticalCalcFromUser(ability, user, target, crit_stage)
    return trigger(CriticalCalcFromUser, ability, user, target, crit_stage, ret: crit_stage)
  end

  def self.triggerCriticalCalcFromTarget(ability, user, target, crit_stage)
    return trigger(CriticalCalcFromTarget, ability, user, target, crit_stage, ret: crit_stage)
  end

  #=============================================================================

  def self.triggerOnBeingHit(ability, user, target, move, battle)
    OnBeingHit.trigger(ability, user, target, move, battle)
  end

  def self.triggerOnDealingHit(ability, user, target, move, battle)
    OnDealingHit.trigger(ability, user, target, move, battle)
  end

  #=============================================================================

  def self.triggerOnEndOfUsingMove(ability, user, targets, move, battle)
    OnEndOfUsingMove.trigger(ability, user, targets, move, battle)
  end

  def self.triggerAfterMoveUseFromTarget(ability, target, user, move, switched_battlers, battle)
    AfterMoveUseFromTarget.trigger(ability, target, user, move, switched_battlers, battle)
  end

  #=============================================================================

  def self.triggerEndOfRoundWeather(ability, weather, battler, battle)
    EndOfRoundWeather.trigger(ability, weather, battler, battle)
  end

  def self.triggerEndOfRoundHealing(ability, battler, battle)
    EndOfRoundHealing.trigger(ability, battler, battle)
  end

  def self.triggerEndOfRoundEffect(ability, battler, battle)
    EndOfRoundEffect.trigger(ability, battler, battle)
  end

  def self.triggerEndOfRoundGainItem(ability, battler, battle)
    EndOfRoundGainItem.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerCertainSwitching(ability, switcher, battle)
    return trigger(CertainSwitching, ability, switcher, battle)
  end

  def self.triggerTrappingByTarget(ability, switcher, bearer, battle)
    return trigger(TrappingByTarget, ability, switcher, bearer, battle)
  end

  def self.triggerOnSwitchIn(ability, battler, battle, switch_in = false)
    OnSwitchIn.trigger(ability, battler, battle, switch_in)
  end

  def self.triggerOnSwitchOut(ability, battler, end_of_battle)
    OnSwitchOut.trigger(ability, battler, end_of_battle)
  end

  def self.triggerChangeOnBattlerFainting(ability, battler, fainted, battle)
    ChangeOnBattlerFainting.trigger(ability, battler, fainted, battle)
  end

  def self.triggerOnBattlerFainting(ability, battler, fainted, battle)
    OnBattlerFainting.trigger(ability, battler, fainted, battle)
  end

  def self.triggerOnTerrainChange(ability, battler, battle, ability_changed)
    OnTerrainChange.trigger(ability, battler, battle, ability_changed)
  end

  def self.triggerOnIntimidated(ability, battler, battle)
    OnIntimidated.trigger(ability, battler, battle)
  end

  #=============================================================================

  def self.triggerCertainEscapeFromBattle(ability, battler)
    return trigger(CertainEscapeFromBattle, ability, battler)
  end
end

#===============================================================================
# SpeedCalc handlers
#===============================================================================

Battle::AbilityEffects::SpeedCalc.add(:CHLOROPHYLL,
  proc { |ability, battler, mult|
    next mult * 2 if [:Sun, :HarshSun].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:QUICKFEET,
  proc { |ability, battler, mult|
    next mult * 1.5 if battler.pbHasAnyStatus?
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SANDRUSH,
  proc { |ability, battler, mult|
    next mult * 2 if [:Sandstorm].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SLOWSTART,
  proc { |ability, battler, mult|
    next mult / 2 if battler.effects[PBEffects::SlowStart] > 0
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SLUSHRUSH,
  proc { |ability, battler, mult|
    next mult * 2 if [:Hail].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SURGESURFER,
  proc { |ability, battler, mult|
    next mult * 2 if battler.battle.field.terrain == :Electric
  }
)

Battle::AbilityEffects::SpeedCalc.add(:SWIFTSWIM,
  proc { |ability, battler, mult|
    next mult * 2 if [:Rain, :HeavyRain].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::SpeedCalc.add(:UNBURDEN,
  proc { |ability, battler, mult|
    next mult * 2 if battler.effects[PBEffects::Unburden] && !battler.item
  }
)

#===============================================================================
# WeightCalcy handlers
#===============================================================================

Battle::AbilityEffects::WeightCalc.add(:HEAVYMETAL,
  proc { |ability, battler, w|
    next w * 2
  }
)

Battle::AbilityEffects::WeightCalc.add(:LIGHTMETAL,
  proc { |ability, battler, w|
    next [w / 2, 1].max
  }
)

#===============================================================================
# OnHPDroppedBelowHalf handlers
#===============================================================================

Battle::AbilityEffects::OnHPDroppedBelowHalf.add(:EMERGENCYEXIT,
  proc { |ability, battler, move_user, battle|
    next false if battler.effects[PBEffects::SkyDrop] >= 0 ||
                  battler.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSkyTargetCannotAct")   # Sky Drop
    # In wild battles
    if battle.wildBattle?
      next false if battler.opposes? && battle.pbSideBattlerCount(battler.index) > 1
      next false if !battle.pbCanRun?(battler.index)
      battle.pbShowAbilitySplash(battler, true)
      battle.pbHideAbilitySplash(battler)
      pbSEPlay("Battle flee")
      battle.pbDisplay(_INTL("{1}脱离了战斗！", battler.pbThis))
      battle.decision = 3   # Escaped
      next true
    end
    # In trainer battles
    next false if battle.pbAllFainted?(battler.idxOpposingSide)
    next false if !battle.pbCanSwitchOut?(battler.index)   # Battler can't switch out
    next false if !battle.pbCanChooseNonActive?(battler.index)   # No Pokémon can switch in
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的{2}发动！", battler.pbThis, battler.abilityName))
    end
    battle.pbDisplay(_INTL("{1}要回到{2}的身边了！",
       battler.pbThis, battle.pbGetOwnerName(battler.index)))
    if battle.endOfRound   # Just switch out
      battle.scene.pbRecall(battler.index) if !battler.fainted?
      battler.pbAbilitiesOnSwitchOut   # Inc. primordial weather check
      next true
    end
    newPkmn = battle.pbGetReplacementPokemonIndex(battler.index)   # Owner chooses
    next false if newPkmn < 0   # Shouldn't ever do this
    battle.pbRecallAndReplace(battler.index, newPkmn)
    battle.pbClearChoice(battler.index)   # Replacement Pokémon does nothing this round
    battle.moldBreaker = false if move_user && battler.index == move_user.index
    battle.pbOnBattlerEnteringBattle(battler.index)
    next true
  }
)

Battle::AbilityEffects::OnHPDroppedBelowHalf.copy(:EMERGENCYEXIT, :WIMPOUT)

#===============================================================================
# StatusCheckNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatusCheckNonIgnorable.add(:COMATOSE,
  proc { |ability, battler, status|
    next false if !battler.isSpecies?(:KOMALA)
    next true if status.nil? || status == :SLEEP
  }
)

#===============================================================================
# StatusImmunity handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunity.add(:FLOWERVEIL,
  proc { |ability, battler, status|
    next true if battler.pbHasType?(:GRASS)
  }
)

Battle::AbilityEffects::StatusImmunity.add(:IMMUNITY,
  proc { |ability, battler, status|
    next true if status == :POISON
  }
)

Battle::AbilityEffects::StatusImmunity.copy(:IMMUNITY, :PASTELVEIL)

Battle::AbilityEffects::StatusImmunity.add(:INSOMNIA,
  proc { |ability, battler, status|
    next true if status == :SLEEP
  }
)

Battle::AbilityEffects::StatusImmunity.copy(:INSOMNIA, :SWEETVEIL, :VITALSPIRIT)

Battle::AbilityEffects::StatusImmunity.add(:LEAFGUARD,
  proc { |ability, battler, status|
    next true if [:Sun, :HarshSun].include?(battler.effectiveWeather)
  }
)

Battle::AbilityEffects::StatusImmunity.add(:LIMBER,
  proc { |ability, battler, status|
    next true if status == :PARALYSIS
  }
)

Battle::AbilityEffects::StatusImmunity.add(:MAGMAARMOR,
  proc { |ability, battler, status|
    next true if status == :FROZEN
  }
)

Battle::AbilityEffects::StatusImmunity.add(:WATERVEIL,
  proc { |ability, battler, status|
    next true if status == :BURN
  }
)

Battle::AbilityEffects::StatusImmunity.copy(:WATERVEIL, :WATERBUBBLE)

#===============================================================================
# StatusImmunityNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunityNonIgnorable.add(:COMATOSE,
  proc { |ability, battler, status|
    next true if battler.isSpecies?(:KOMALA)
  }
)

Battle::AbilityEffects::StatusImmunityNonIgnorable.add(:SHIELDSDOWN,
  proc { |ability, battler, status|
    next true if battler.isSpecies?(:MINIOR) && battler.form < 7
  }
)

#===============================================================================
# StatusImmunityFromAlly handlers
#===============================================================================

Battle::AbilityEffects::StatusImmunityFromAlly.add(:FLOWERVEIL,
  proc { |ability, battler, status|
    next true if battler.pbHasType?(:GRASS)
  }
)

Battle::AbilityEffects::StatusImmunityFromAlly.add(:PASTELVEIL,
  proc { |ability, battler, status|
    next true if status == :POISON
  }
)

Battle::AbilityEffects::StatusImmunityFromAlly.add(:SWEETVEIL,
  proc { |ability, battler, status|
    next true if status == :SLEEP
  }
)

#===============================================================================
# OnStatusInflicted handlers
#===============================================================================

Battle::AbilityEffects::OnStatusInflicted.add(:SYNCHRONIZE,
  proc { |ability, battler, user, status|
    next if !user || user.index == battler.index
    case status
    when :POISON
      if user.pbCanPoisonSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("因为{1}的{2}，{3}中毒了！", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbPoison(nil, msg, (battler.statusCount > 0))
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :BURN
      if user.pbCanBurnSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("因为{1}的{2}，{3}被灼伤了！", battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbBurn(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    when :PARALYSIS
      if user.pbCanParalyzeSynchronize?(battler)
        battler.battle.pbShowAbilitySplash(battler)
        msg = nil
        if !Battle::Scene::USE_ABILITY_SPLASH
          msg = _INTL("因为{1}的{2}，{3}被麻痹了！很难使出招式！",
             battler.pbThis, battler.abilityName, user.pbThis(true))
        end
        user.pbParalyze(nil, msg)
        battler.battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

#===============================================================================
# StatusCure handlers
#===============================================================================

Battle::AbilityEffects::StatusCure.add(:IMMUNITY,
  proc { |ability, battler|
    next if battler.status != :POISON
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("因为{2}，{1}治愈了中毒！", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:IMMUNITY, :PASTELVEIL)

Battle::AbilityEffects::StatusCure.add(:INSOMNIA,
  proc { |ability, battler|
    next if battler.status != :SLEEP
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("因为{2}，{1}醒过来了！", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:INSOMNIA, :VITALSPIRIT)

Battle::AbilityEffects::StatusCure.add(:LIMBER,
  proc { |ability, battler|
    next if battler.status != :PARALYSIS
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("因为{2}，{1}治愈了麻痹！", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:MAGMAARMOR,
  proc { |ability, battler|
    next if battler.status != :FROZEN
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("因为{2}，{1}治愈了冰冻状态！", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:OBLIVIOUS,
  proc { |ability, battler|
    next if battler.effects[PBEffects::Attract] < 0 &&
            (battler.effects[PBEffects::Taunt] == 0 || Settings::MECHANICS_GENERATION <= 5)
    battler.battle.pbShowAbilitySplash(battler)
    if battler.effects[PBEffects::Attract] >= 0
      battler.pbCureAttract
      if Battle::Scene::USE_ABILITY_SPLASH
        battler.battle.pbDisplay(_INTL("{1}的着迷状态治愈了！", battler.pbThis))
      else
        battler.battle.pbDisplay(_INTL("因为{2}，{1}治愈了着迷状态！",
           battler.pbThis, battler.abilityName))
      end
    end
    if battler.effects[PBEffects::Taunt] > 0 && Settings::MECHANICS_GENERATION >= 6
      battler.effects[PBEffects::Taunt] = 0
      if Battle::Scene::USE_ABILITY_SPLASH
        battler.battle.pbDisplay(_INTL("{1}的挑衅消失了！", battler.pbThis))
      else
        battler.battle.pbDisplay(_INTL("因为{2}，{1}的挑衅消失了！",
           battler.pbThis, battler.abilityName))
      end
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:OWNTEMPO,
  proc { |ability, battler|
    next if battler.effects[PBEffects::Confusion] == 0
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureConfusion
    if Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("{1}的混乱解除了！", battler.pbThis))
    else
      battler.battle.pbDisplay(_INTL("因为{2}，{1}的混乱解除了！",
         battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.add(:WATERVEIL,
  proc { |ability, battler|
    next if battler.status != :BURN
    battler.battle.pbShowAbilitySplash(battler)
    battler.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battler.battle.pbDisplay(_INTL("因为{2}，{1}治愈了灼伤！", battler.pbThis, battler.abilityName))
    end
    battler.battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::StatusCure.copy(:WATERVEIL, :WATERBUBBLE)

#===============================================================================
# StatLossImmunity handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunity.add(:BIGPECKS,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :DEFENSE
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的{2}不能降低！", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了{3}降低！", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:CLEARBODY,
  proc { |ability, battler, stat, battle, showMessages|
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的能力不能进一步降低了！", battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了能力降低！", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.copy(:CLEARBODY, :WHITESMOKE)

Battle::AbilityEffects::StatLossImmunity.add(:FLOWERVEIL,
  proc { |ability, battler, stat, battle, showMessages|
    next false if !battler.pbHasType?(:GRASS)
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的能力不能进一步降低了！", battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了能力降低！", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:HYPERCUTTER,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :ATTACK
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的{2}不能进一步降低了！", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了能力降低！", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

Battle::AbilityEffects::StatLossImmunity.add(:KEENEYE,
  proc { |ability, battler, stat, battle, showMessages|
    next false if stat != :ACCURACY
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的{2}不能进一步降低了！", battler.pbThis, GameData::Stat.get(stat).name))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了能力降低！", battler.pbThis,
           battler.abilityName, GameData::Stat.get(stat).name))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

#===============================================================================
# StatLossImmunityNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunityNonIgnorable.add(:FULLMETALBODY,
  proc { |ability, battler, stat, battle, showMessages|
    if showMessages
      battle.pbShowAbilitySplash(battler)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的能力不能进一步降低了！", battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了能力降低！", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
    next true
  }
)

#===============================================================================
# StatLossImmunityFromAlly handlers
#===============================================================================

Battle::AbilityEffects::StatLossImmunityFromAlly.add(:FLOWERVEIL,
  proc { |ability, bearer, battler, stat, battle, showMessages|
    next false if !battler.pbHasType?(:GRASS)
    if showMessages
      battle.pbShowAbilitySplash(bearer)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的能力不能进一步降低了！", battler.pbThis))
      else
        battle.pbDisplay(_INTL("{1}的{2}防止了{3}的能力降低！",
           bearer.pbThis, bearer.abilityName, battler.pbThis(true)))
      end
      battle.pbHideAbilitySplash(bearer)
    end
    next true
  }
)

#===============================================================================
# OnStatGain handlers
#===============================================================================

# There aren't any!

#===============================================================================
# OnStatLoss handlers
#===============================================================================

Battle::AbilityEffects::OnStatLoss.add(:COMPETITIVE,
  proc { |ability, battler, stat, user|
    next if user && !user.opposes?(battler)
    battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 2, battler)
  }
)

Battle::AbilityEffects::OnStatLoss.add(:DEFIANT,
  proc { |ability, battler, stat, user|
    next if user && !user.opposes?(battler)
    battler.pbRaiseStatStageByAbility(:ATTACK, 2, battler)
  }
)

#===============================================================================
# PriorityChange handlers
#===============================================================================

Battle::AbilityEffects::PriorityChange.add(:GALEWINGS,
  proc { |ability, battler, move, pri|
    next pri + 1 if (Settings::MECHANICS_GENERATION <= 6 || battler.hp == battler.totalhp) &&
                    move.type == :FLYING
  }
)

Battle::AbilityEffects::PriorityChange.add(:PRANKSTER,
  proc { |ability, battler, move, pri|
    if move.statusMove?
      battler.effects[PBEffects::Prankster] = true
      next pri + 1
    end
  }
)

Battle::AbilityEffects::PriorityChange.add(:TRIAGE,
  proc { |ability, battler, move, pri|
    next pri + 3 if move.healingMove?
  }
)

#===============================================================================
# PriorityBracketChange handlers
#===============================================================================

Battle::AbilityEffects::PriorityBracketChange.add(:QUICKDRAW,
  proc { |ability, battler, battle|
    next 1 if battle.pbRandom(100) < 30
  }
)

Battle::AbilityEffects::PriorityBracketChange.add(:STALL,
  proc { |ability, battler, battle|
    next -1
  }
)

#===============================================================================
# PriorityBracketUse handlers
#===============================================================================

Battle::AbilityEffects::PriorityBracketUse.add(:QUICKDRAW,
  proc { |ability, battler, battle|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}让{2}行动变快了！", battler.abilityName, battler.pbThis(true)))
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# OnFlinch handlers
#===============================================================================

Battle::AbilityEffects::OnFlinch.add(:STEADFAST,
  proc { |ability, battler, battle|
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
  }
)

#===============================================================================
# MoveBlocking handlers
#===============================================================================

Battle::AbilityEffects::MoveBlocking.add(:DAZZLING,
  proc { |ability, bearer, user, targets, move, battle|
    next false if battle.choices[user.index][4] <= 0
    next false if !bearer.opposes?(user)
    ret = false
    targets.each { |b| ret = true if b.opposes?(user) }
    next ret
  }
)

Battle::AbilityEffects::MoveBlocking.copy(:DAZZLING, :QUEENLYMAJESTY)

#===============================================================================
# MoveImmunity handlers
#===============================================================================

Battle::AbilityEffects::MoveImmunity.add(:BULLETPROOF,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.bombMove?
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("对于{1}，好像没有效果……", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("因为{1}的{2}，{3}无效！",
           target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:FLASHFIRE,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if user.index == target.index
    next false if type != :FIRE
    if show_message
      battle.pbShowAbilitySplash(target)
      if !target.effects[PBEffects::FlashFire]
        target.effects[PBEffects::FlashFire] = true
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("{1}的火焰威力提高了！", target.pbThis(true)))
        else
          battle.pbDisplay(_INTL("因为{2}，{1}的火焰威力提高了！",
             target.pbThis(true), target.abilityName))
        end
      elsif Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("对于{1}，好像没有效果……", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("因为{1}的{2}，{3}无效！",
                               target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:LIGHTNINGROD,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :SPECIAL_ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:MOTORDRIVE,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :ELECTRIC, :SPEED, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:SAPSIPPER,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :GRASS, :ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:SOUNDPROOF,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if !move.soundMove?
    next false if Settings::MECHANICS_GENERATION >= 8 && user.index == target.index
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("对于{1}，好像没有效果……", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}的{2}阻止了{3}！", target.pbThis, target.abilityName, move.name))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:STORMDRAIN,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityStatRaisingAbility(user, move, type,
       :WATER, :SPECIAL_ATTACK, 1, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:TELEPATHY,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if move.statusMove?
    next false if user.index == target.index || target.opposes?(user)
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("我方宝可梦的攻击没有击中{1}！", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("因为{2}，我方宝可梦的攻击没有击中{1}！",
           target.pbThis, target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

Battle::AbilityEffects::MoveImmunity.add(:VOLTABSORB,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityHealingAbility(user, move, type, :ELECTRIC, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.add(:WATERABSORB,
  proc { |ability, user, target, move, type, battle, show_message|
    next target.pbMoveImmunityHealingAbility(user, move, type, :WATER, show_message)
  }
)

Battle::AbilityEffects::MoveImmunity.copy(:WATERABSORB, :DRYSKIN)

Battle::AbilityEffects::MoveImmunity.add(:WONDERGUARD,
  proc { |ability, user, target, move, type, battle, show_message|
    next false if move.statusMove?
    next false if !type || Effectiveness.super_effective?(target.damageState.typeMod)
    if show_message
      battle.pbShowAbilitySplash(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("对于{1}，好像没有效果……", target.pbThis(true)))
      else
        battle.pbDisplay(_INTL("因为{2}，{1}没有受到伤害！", target.pbThis, target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
    end
    next true
  }
)

#===============================================================================
# ModifyMoveBaseType handlers
#===============================================================================

Battle::AbilityEffects::ModifyMoveBaseType.add(:AERILATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:FLYING)
    move.powerBoost = true
    next :FLYING
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:GALVANIZE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:ELECTRIC)
    move.powerBoost = true
    next :ELECTRIC
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:LIQUIDVOICE,
  proc { |ability, user, move, type|
    next :WATER if GameData::Type.exists?(:WATER) && move.soundMove?
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:NORMALIZE,
  proc { |ability, user, move, type|
    next if !GameData::Type.exists?(:NORMAL)
    move.powerBoost = true if Settings::MECHANICS_GENERATION >= 7
    next :NORMAL
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:PIXILATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:FAIRY)
    move.powerBoost = true
    next :FAIRY
  }
)

Battle::AbilityEffects::ModifyMoveBaseType.add(:REFRIGERATE,
  proc { |ability, user, move, type|
    next if type != :NORMAL || !GameData::Type.exists?(:ICE)
    move.powerBoost = true
    next :ICE
  }
)

#===============================================================================
# AccuracyCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromUser.add(:COMPOUNDEYES,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:HUSTLE,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 0.8 if move.physicalMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:KEENEYE,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_stage] = 0 if mods[:evasion_stage] > 0 && Settings::MECHANICS_GENERATION >= 6
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:NOGUARD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:UNAWARE,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_stage] = 0 if move.damagingMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromUser.add(:VICTORYSTAR,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.1
  }
)

#===============================================================================
# AccuracyCalcFromAlly handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromAlly.add(:VICTORYSTAR,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] *= 1.1
  }
)

#===============================================================================
# AccuracyCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:LIGHTNINGROD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0 if type == :ELECTRIC
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:NOGUARD,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:SANDVEIL,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_multiplier] *= 1.25 if target.effectiveWeather == :Sandstorm
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:SNOWCLOAK,
  proc { |ability, mods, user, target, move, type|
    mods[:evasion_multiplier] *= 1.25 if target.effectiveWeather == :Hail
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:STORMDRAIN,
  proc { |ability, mods, user, target, move, type|
    mods[:base_accuracy] = 0 if type == :WATER
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:TANGLEDFEET,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_multiplier] /= 2 if target.effects[PBEffects::Confusion] > 0
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:UNAWARE,
  proc { |ability, mods, user, target, move, type|
    mods[:accuracy_stage] = 0 if move.damagingMove?
  }
)

Battle::AbilityEffects::AccuracyCalcFromTarget.add(:WONDERSKIN,
  proc { |ability, mods, user, target, move, type|
    if move.statusMove? && user.opposes?(target) && mods[:base_accuracy] > 50
      mods[:base_accuracy] = 50
    end
  }
)

#===============================================================================
# DamageCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromUser.add(:AERILATE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.powerBoost
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:AERILATE, :GALVANIZE, :NORMALIZE, :PIXILATE, :REFRIGERATE)

Battle::AbilityEffects::DamageCalcFromUser.add(:ANALYTIC,
  proc { |ability, user, target, move, mults, power, type|
    # NOTE: In the official games, if another battler faints earlier in the
    #       round but it would have moved after the user, then Analytic does not
    #       power up the move. However, this makes the determination so much
    #       more complicated (involving pbPriority and counting or not counting
    #       speed/priority modifiers depending on which Generation's mechanics
    #       are being used), so I'm choosing to ignore it. The effect is thus:
    #       "power up the move if all other battlers on the field right now have
    #       already moved".
    if move.pbMoveFailedLastInRound?(user, false)
      mults[:power_multiplier] *= 1.3
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:BLAZE,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:DEFEATIST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] /= 2 if user.hp <= user.totalhp / 2
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:DRAGONSMAW,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :DRAGON
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLAREBOOST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if user.burned? && move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLASHFIRE,
  proc { |ability, user, target, move, mults, power, type|
    if user.effects[PBEffects::FlashFire] && type == :FIRE
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:GORILLATACTICS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:GUTS,
  proc { |ability, user, target, move, mults, power, type|
    if user.pbHasAnyStatus? && move.physicalMove?
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:HUGEPOWER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:HUGEPOWER, :PUREPOWER)

Battle::AbilityEffects::DamageCalcFromUser.add(:HUSTLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:IRONFIST,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.punchingMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:MEGALAUNCHER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if move.pulseMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:MINUS,
  proc { |ability, user, target, move, mults, power, type|
    next if !move.specialMove?
    if user.allAllies.any? { |b| b.hasActiveAbility?([:MINUS, :PLUS]) }
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.copy(:MINUS, :PLUS)

Battle::AbilityEffects::DamageCalcFromUser.add(:NEUROFORCE,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 1.25
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:OVERGROW,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :GRASS
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:PUNKROCK,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.3 if move.soundMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:RECKLESS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.2 if move.recoilMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:RIVALRY,
  proc { |ability, user, target, move, mults, power, type|
    if user.gender != 2 && target.gender != 2
      if user.gender == target.gender
        mults[:power_multiplier] *= 1.25
      else
        mults[:power_multiplier] *= 0.75
      end
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SANDFORCE,
  proc { |ability, user, target, move, mults, power, type|
    if user.effectiveWeather == :Sandstorm &&
       [:ROCK, :GROUND, :STEEL].include?(type)
      mults[:power_multiplier] *= 1.3
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SHEERFORCE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.3 if move.addlEffect > 0
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SLOWSTART,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] /= 2 if user.effects[PBEffects::SlowStart] > 0 && move.physicalMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SNIPER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if target.damageState.critical
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SOLARPOWER,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STAKEOUT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if target.battle.choices[target.index][0] == :SwitchOut
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STEELWORKER,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :STEEL
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STEELYSPIRIT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if type == :STEEL
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:STRONGJAW,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.5 if move.bitingMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:SWARM,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :BUG
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TECHNICIAN,
  proc { |ability, user, target, move, mults, power, type|
    if user.index != target.index && move && move.function_code != "Struggle" &&
       power * mults[:power_multiplier] <= 60
      mults[:power_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TINTEDLENS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 2 if Effectiveness.resistant?(target.damageState.typeMod)
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TORRENT,
  proc { |ability, user, target, move, mults, power, type|
    if user.hp <= user.totalhp / 3 && type == :WATER
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TOUGHCLAWS,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 4 / 3.0 if move.contactMove?
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TOXICBOOST,
  proc { |ability, user, target, move, mults, power, type|
    if user.poisoned? && move.physicalMove?
      mults[:power_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:TRANSISTOR,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 1.5 if type == :ELECTRIC
  }
)

Battle::AbilityEffects::DamageCalcFromUser.add(:WATERBUBBLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:attack_multiplier] *= 2 if type == :WATER
  }
)

#===============================================================================
# DamageCalcFromAlly handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromAlly.add(:BATTERY,
  proc { |ability, user, target, move, mults, power, type|
    next if !move.specialMove?
    mults[:final_damage_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.physicalMove? && [:Sun, :HarshSun].include?(user.effectiveWeather)
      mults[:attack_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:POWERSPOT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.3
  }
)

Battle::AbilityEffects::DamageCalcFromAlly.add(:STEELYSPIRIT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.5 if type == :STEEL
  }
)

#===============================================================================
# DamageCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTarget.add(:DRYSKIN,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] *= 1.25 if type == :FIRE
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FILTER,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 0.75
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.copy(:FILTER, :SOLIDROCK)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(target.effectiveWeather)
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FLUFFY,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 2 if move.calcType == :FIRE
    mults[:final_damage_multiplier] /= 2 if move.pbContactMove?(user)
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:FURCOAT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:defense_multiplier] *= 2 if move.physicalMove? ||
                                       move.function_code == "UseTargetDefenseInsteadOfTargetSpDef"   # Psyshock
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:GRASSPELT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:defense_multiplier] *= 1.5 if user.battle.field.terrain == :Grassy
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:HEATPROOF,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] /= 2 if type == :FIRE
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:ICESCALES,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if move.specialMove?
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:MARVELSCALE,
  proc { |ability, user, target, move, mults, power, type|
    if target.pbHasAnyStatus? && move.physicalMove?
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:MULTISCALE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if target.hp == target.totalhp
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:PUNKROCK,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if move.soundMove?
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:THICKFAT,
  proc { |ability, user, target, move, mults, power, type|
    mults[:power_multiplier] /= 2 if [:FIRE, :ICE].include?(type)
  }
)

Battle::AbilityEffects::DamageCalcFromTarget.add(:WATERBUBBLE,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if type == :FIRE
  }
)

#===============================================================================
# DamageCalcFromTargetNonIgnorable handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable.add(:PRISMARMOR,
  proc { |ability, user, target, move, mults, power, type|
    if Effectiveness.super_effective?(target.damageState.typeMod)
      mults[:final_damage_multiplier] *= 0.75
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTargetNonIgnorable.add(:SHADOWSHIELD,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] /= 2 if target.hp == target.totalhp
  }
)

#===============================================================================
# DamageCalcFromTargetAlly handlers
#===============================================================================

Battle::AbilityEffects::DamageCalcFromTargetAlly.add(:FLOWERGIFT,
  proc { |ability, user, target, move, mults, power, type|
    if move.specialMove? && [:Sun, :HarshSun].include?(target.effectiveWeather)
      mults[:defense_multiplier] *= 1.5
    end
  }
)

Battle::AbilityEffects::DamageCalcFromTargetAlly.add(:FRIENDGUARD,
  proc { |ability, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 0.75
  }
)

#===============================================================================
# CriticalCalcFromUser handlers
#===============================================================================

Battle::AbilityEffects::CriticalCalcFromUser.add(:MERCILESS,
  proc { |ability, user, target, c|
    next 99 if target.poisoned?
  }
)

Battle::AbilityEffects::CriticalCalcFromUser.add(:SUPERLUCK,
  proc { |ability, user, target, c|
    next c + 1
  }
)

#===============================================================================
# CriticalCalcFromTarget handlers
#===============================================================================

Battle::AbilityEffects::CriticalCalcFromTarget.add(:BATTLEARMOR,
  proc { |ability, user, target, c|
    next -1
  }
)

Battle::AbilityEffects::CriticalCalcFromTarget.copy(:BATTLEARMOR, :SHELLARMOR)

#===============================================================================
# OnBeingHit handlers
#===============================================================================

Battle::AbilityEffects::OnBeingHit.add(:AFTERMATH,
  proc { |ability, user, target, move, battle|
    next if !target.fainted?
    next if !move.pbContactMove?(user)
    battle.pbShowAbilitySplash(target)
    if !battle.moldBreaker
      dampBattler = battle.pbCheckGlobalAbility(:DAMP)
      if dampBattler
        battle.pbShowAbilitySplash(dampBattler)
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("{1}无法使用{2}！", target.pbThis, target.abilityName))
        else
          battle.pbDisplay(_INTL("因{3}的{4}，{1}无法使出{2}！",
             target.pbThis, target.abilityName, dampBattler.pbThis(true), dampBattler.abilityName))
        end
        battle.pbHideAbilitySplash(dampBattler)
        battle.pbHideAbilitySplash(target)
        next
      end
    end
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(user.totalhp / 4, false)
      battle.pbDisplay(_INTL("{1}被爆炸伤害到了！", user.pbThis))
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:ANGERPOINT,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.critical
    next if !target.pbCanRaiseStatStage?(:ATTACK, target)
    battle.pbShowAbilitySplash(target)
    target.stages[:ATTACK] = Battle::Battler::STAT_STAGE_MAXIMUM
    target.statsRaisedThisRound = true
    battle.pbCommonAnimation("StatUp", target)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的{2}被提高到了最大！", target.pbThis, GameData::Stat.get(:ATTACK).name))
    else
      battle.pbDisplay(_INTL("{1}的{3}被{2}提高到了最大！",
         target.pbThis, target.abilityName, GameData::Stat.get(:ATTACK).name))
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:COTTONDOWN,
  proc { |ability, user, target, move, battle|
    next if battle.allBattlers.none? { |b| b.index != target.index && b.pbCanLowerStatStage?(:SPEED, target) }
    battle.pbShowAbilitySplash(target)
    battle.allBattlers.each do |b|
      b.pbLowerStatStageByAbility(:SPEED, 1, target, false) if b.index != target.index
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:CURSEDBODY,
  proc { |ability, user, target, move, battle|
    next if user.fainted?
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
        battle.pbDisplay(_INTL("封住了{1}的{2}！", user.pbThis, regularMove.name))
      else
        battle.pbDisplay(_INTL("{3}的{4}封住了{1}的{2}！",
           user.pbThis, regularMove.name, target.pbThis(true), target.abilityName))
      end
      battle.pbHideAbilitySplash(target)
      user.pbItemStatusCureCheck
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:CUTECHARM,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
    next if !move.pbContactMove?(user)
    next if battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanAttract?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("因为{1}的{2}让{3}着迷了！", target.pbThis,
           target.abilityName, user.pbThis(true))
      end
      user.pbAttract(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:EFFECTSPORE,
  proc { |ability, user, target, move, battle|
    # NOTE: This ability has a 30% chance of triggering, not a 30% chance of
    #       inflicting a status condition. It can try (and fail) to inflict a
    #       status condition that the user is immune to.
    next if !move.pbContactMove?(user)
    next if battle.pbRandom(100) >= 30
    r = battle.pbRandom(3)
    next if r == 0 && user.asleep?
    next if r == 1 && user.poisoned?
    next if r == 2 && user.paralyzed?
    battle.pbShowAbilitySplash(target)
    if user.affectedByPowder?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      case r
      when 0
        if user.pbCanSleep?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}的{2}让{3}睡着了！", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbSleep(msg)
        end
      when 1
        if user.pbCanPoison?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}的{2}让{3}中毒了！", target.pbThis,
               target.abilityName, user.pbThis(true))
          end
          user.pbPoison(target, msg)
        end
      when 2
        if user.pbCanParalyze?(target, Battle::Scene::USE_ABILITY_SPLASH)
          msg = nil
          if !Battle::Scene::USE_ABILITY_SPLASH
            msg = _INTL("{1}的{2}让{3}被麻痹了！很难使出招式！",
               target.pbThis, target.abilityName, user.pbThis(true))
          end
          user.pbParalyze(target, msg)
        end
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:FLAMEBODY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.burned? || battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanBurn?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1}的{2}让{3}被灼伤了！", target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbBurn(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:GOOEY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    user.pbLowerStatStageByAbility(:SPEED, 1, target, true, true)
  }
)

Battle::AbilityEffects::OnBeingHit.copy(:GOOEY, :TANGLINGHAIR)

Battle::AbilityEffects::OnBeingHit.add(:ILLUSION,
  proc { |ability, user, target, move, battle|
    # NOTE: This intentionally doesn't show the ability splash.
    next if !target.effects[PBEffects::Illusion]
    target.effects[PBEffects::Illusion] = nil
    battle.scene.pbChangePokemon(target, target.pokemon)
    battle.pbDisplay(_INTL("{1}造成的幻觉被解除了！", target.pbThis))
    battle.pbSetSeen(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:INNARDSOUT,
  proc { |ability, user, target, move, battle|
    next if !target.fainted? || user.dummy
    battle.pbShowAbilitySplash(target)
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(target.damageState.hpLost, false)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}受到了伤害！", user.pbThis))
      else
        battle.pbDisplay(_INTL("{1}被{2}的{3}伤害了！", user.pbThis,
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:IRONBARBS,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    battle.pbShowAbilitySplash(target)
    if user.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      battle.scene.pbDamageAnimation(user)
      user.pbReduceHP(user.totalhp / 8, false)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}受到了伤害！", user.pbThis))
      else
        battle.pbDisplay(_INTL("{1}被{2}的{3}伤害了！", user.pbThis,
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.copy(:IRONBARBS, :ROUGHSKIN)

Battle::AbilityEffects::OnBeingHit.add(:JUSTIFIED,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :DARK
    target.pbRaiseStatStageByAbility(:ATTACK, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:MUMMY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.unstoppableAbility? || user.ability == ability
    oldAbil = nil
    battle.pbShowAbilitySplash(target) if user.opposes?(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      oldAbil = user.ability
      battle.pbShowAbilitySplash(user, true, false) if user.opposes?(target)
      user.ability = ability
      battle.pbReplaceAbilitySplash(user) if user.opposes?(target)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的特性变成了{2}！", user.pbThis, user.abilityName))
      else
        battle.pbDisplay(_INTL("因为{3}，{1}的特性变成了{2}！",
           user.pbThis, user.abilityName, target.pbThis(true)))
      end
      battle.pbHideAbilitySplash(user) if user.opposes?(target)
    end
    battle.pbHideAbilitySplash(target) if user.opposes?(target)
    user.pbOnLosingAbility(oldAbil)
    user.pbTriggerAbilityOnGainingIt
  }
)

Battle::AbilityEffects::OnBeingHit.add(:PERISHBODY,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.fainted?
    next if user.effects[PBEffects::PerishSong] > 0 || target.effects[PBEffects::PerishSong] > 0
    battle.pbShowAbilitySplash(target)
    if user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      user.effects[PBEffects::PerishSong] = 4
      user.effects[PBEffects::PerishSongUser] = target.index
      target.effects[PBEffects::PerishSong] = 4
      target.effects[PBEffects::PerishSongUser] = target.index
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("宝可梦3回合后会陷入昏厥！"))
      else
        battle.pbDisplay(_INTL("因为{1}的{2}，宝可梦3回合后会陷入昏厥！",
           target.pbThis(true), target.abilityName))
      end
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:POISONPOINT,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.poisoned? || battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanPoison?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1}的{2}让{3}中毒了！", target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbPoison(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:RATTLED,
  proc { |ability, user, target, move, battle|
    next if ![:BUG, :DARK, :GHOST].include?(move.calcType)
    target.pbRaiseStatStageByAbility(:SPEED, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:SANDSPIT,
  proc { |ability, user, target, move, battle|
    battle.pbStartWeatherAbility(:Sandstorm, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:STAMINA,
  proc { |ability, user, target, move, battle|
    target.pbRaiseStatStageByAbility(:DEFENSE, 1, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:STATIC,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.paralyzed? || battle.pbRandom(100) >= 30
    battle.pbShowAbilitySplash(target)
    if user.pbCanParalyze?(target, Battle::Scene::USE_ABILITY_SPLASH) &&
       user.affectedByContactEffect?(Battle::Scene::USE_ABILITY_SPLASH)
      msg = nil
      if !Battle::Scene::USE_ABILITY_SPLASH
        msg = _INTL("{1}的{2}让{3}被麻痹了！很难使出招式！",
           target.pbThis, target.abilityName, user.pbThis(true))
      end
      user.pbParalyze(target, msg)
    end
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WANDERINGSPIRIT,
  proc { |ability, user, target, move, battle|
    next if !move.pbContactMove?(user)
    next if user.ungainableAbility? || [:RECEIVER, :WONDERGUARD].include?(user.ability_id)
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
        battle.pbDisplay(_INTL("{1}互换了各自的特性", target.pbThis, user.pbThis(true)))
      else
        battle.pbDisplay(_INTL("{1}将{2}与{3}的{4}互换了！",
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

Battle::AbilityEffects::OnBeingHit.add(:WATERCOMPACTION,
  proc { |ability, user, target, move, battle|
    next if move.calcType != :WATER
    target.pbRaiseStatStageByAbility(:DEFENSE, 2, target)
  }
)

Battle::AbilityEffects::OnBeingHit.add(:WEAKARMOR,
  proc { |ability, user, target, move, battle|
    next if !move.physicalMove?
    next if !target.pbCanLowerStatStage?(:DEFENSE, target) &&
            !target.pbCanRaiseStatStage?(:SPEED, target)
    battle.pbShowAbilitySplash(target)
    target.pbLowerStatStageByAbility(:DEFENSE, 1, target, false)
    target.pbRaiseStatStageByAbility(:SPEED,
       (Settings::MECHANICS_GENERATION >= 7) ? 2 : 1, target, false)
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# OnDealingHit handlers
#===============================================================================

Battle::AbilityEffects::OnDealingHit.add(:POISONTOUCH,
  proc { |ability, user, target, move, battle|
    next if !move.contactMove?
    next if battle.pbRandom(100) >= 30
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
# OnEndOfUsingMove handlers
#===============================================================================

Battle::AbilityEffects::OnEndOfUsingMove.add(:BEASTBOOST,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0
    userStats = user.plainStats
    highestStatValue = 0
    userStats.each_value { |value| highestStatValue = value if highestStatValue < value }
    GameData::Stat.each_main_battle do |s|
      next if userStats[s.id] < highestStatValue
      if user.pbCanRaiseStatStage?(s.id, user)
        user.pbRaiseStatStageByAbility(s.id, numFainted, user)
      end
      break
    end
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.add(:CHILLINGNEIGH,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:ATTACK, user)
    user.ability_id = :CHILLINGNEIGH   # So the As One abilities can just copy this
    user.pbRaiseStatStageByAbility(:ATTACK, 1, user)
    user.ability_id = ability
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.copy(:CHILLINGNEIGH, :ASONECHILLINGNEIGH)

Battle::AbilityEffects::OnEndOfUsingMove.add(:GRIMNEIGH,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:SPECIAL_ATTACK, user)
    user.ability_id = :GRIMNEIGH   # So the As One abilities can just copy this
    user.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, user)
    user.ability_id = ability
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.copy(:GRIMNEIGH, :ASONEGRIMNEIGH)

Battle::AbilityEffects::OnEndOfUsingMove.add(:MAGICIAN,
  proc { |ability, user, targets, move, battle|
    next if battle.futureSight
    next if !move.pbDamagingMove?
    next if user.item
    next if user.wild?
    targets.each do |b|
      next if b.damageState.unaffected || b.damageState.substitute
      next if !b.item
      next if b.unlosableItem?(b.item) || user.unlosableItem?(b.item)
      battle.pbShowAbilitySplash(user)
      if b.hasActiveAbility?(:STICKYHOLD)
        battle.pbShowAbilitySplash(b) if user.opposes?(b)
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("{1}的道具不能夺取！", b.pbThis))
        end
        battle.pbHideAbilitySplash(b) if user.opposes?(b)
        next
      end
      user.item = b.item
      b.item = nil
      b.effects[PBEffects::Unburden] = true if b.hasActiveAbility?(:UNBURDEN)
      if battle.wildBattle? && !user.initialItem && user.item == b.initialItem
        user.setInitialItem(user.item)
        b.setInitialItem(nil)
      end
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}夺取了{2}的{3}！", user.pbThis,
           b.pbThis(true), user.itemName))
      else
        battle.pbDisplay(_INTL("{1}用{4}夺取了{2}的{3}！", user.pbThis,
           b.pbThis(true), user.itemName, user.abilityName))
      end
      battle.pbHideAbilitySplash(user)
      user.pbHeldItemTriggerCheck
      break
    end
  }
)

Battle::AbilityEffects::OnEndOfUsingMove.add(:MOXIE,
  proc { |ability, user, targets, move, battle|
    next if battle.pbAllFainted?(user.idxOpposingSide)
    numFainted = 0
    targets.each { |b| numFainted += 1 if b.damageState.fainted }
    next if numFainted == 0 || !user.pbCanRaiseStatStage?(:ATTACK, user)
    user.pbRaiseStatStageByAbility(:ATTACK, numFainted, user)
  }
)

#===============================================================================
# AfterMoveUseFromTarget handlers
#===============================================================================

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:BERSERK,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if !move.damagingMove?
    next if !target.droppedBelowHalfHP
    next if !target.pbCanRaiseStatStage?(:SPECIAL_ATTACK, target)
    target.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, target)
  }
)

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:COLORCHANGE,
  proc { |ability, target, user, move, switched_battlers, battle|
    next if target.damageState.calcDamage == 0 || target.damageState.substitute
    next if !move.calcType || GameData::Type.get(move.calcType).pseudo_type
    next if target.pbHasType?(move.calcType) && !target.pbHasOtherType?(move.calcType)
    typeName = GameData::Type.get(move.calcType).name
    battle.pbShowAbilitySplash(target)
    target.pbChangeTypes(move.calcType)
    battle.pbDisplay(_INTL("因为{3}，{1}的属性变成了{2}！",
       target.pbThis, typeName, target.abilityName))
    battle.pbHideAbilitySplash(target)
  }
)

Battle::AbilityEffects::AfterMoveUseFromTarget.add(:PICKPOCKET,
  proc { |ability, target, user, move, switched_battlers, battle|
    # NOTE: According to Bulbapedia, this can still trigger to steal the user's
    #       item even if it was switched out by a Red Card. That doesn't make
    #       sense, so this code doesn't do it.
    next if target.wild?
    next if switched_battlers.include?(user.index)   # User was switched out
    next if !move.contactMove?
    next if user.effects[PBEffects::Substitute] > 0 || target.damageState.substitute
    next if target.item || !user.item
    next if user.unlosableItem?(user.item) || target.unlosableItem?(user.item)
    battle.pbShowAbilitySplash(target)
    if user.hasActiveAbility?(:STICKYHOLD)
      battle.pbShowAbilitySplash(user) if target.opposes?(user)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的道具不能夺取！", user.pbThis))
      end
      battle.pbHideAbilitySplash(user) if target.opposes?(user)
      battle.pbHideAbilitySplash(target)
      next
    end
    target.item = user.item
    user.item = nil
    user.effects[PBEffects::Unburden] = true if user.hasActiveAbility?(:UNBURDEN)
    if battle.wildBattle? && !target.initialItem && target.item == user.initialItem
      target.setInitialItem(target.item)
      user.setInitialItem(nil)
    end
    battle.pbDisplay(_INTL("{1}偷走了{2}的{3}！", target.pbThis,
       user.pbThis(true), target.itemName))
    battle.pbHideAbilitySplash(target)
    target.pbHeldItemTriggerCheck
  }
)

#===============================================================================
# EndOfRoundWeather handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundWeather.add(:DRYSKIN,
  proc { |ability, weather, battler, battle|
    case weather
    when :Sun, :HarshSun
      if battler.takesIndirectDamage?
        battle.pbShowAbilitySplash(battler)
        battle.scene.pbDamageAnimation(battler)
        battler.pbReduceHP(battler.totalhp / 8, false)
        battle.pbDisplay(_INTL("{1}被日照伤害了！", battler.pbThis))
        battle.pbHideAbilitySplash(battler)
        battler.pbItemHPHealCheck
      end
    when :Rain, :HeavyRain
      next if !battler.canHeal?
      battle.pbShowAbilitySplash(battler)
      battler.pbRecoverHP(battler.totalhp / 8)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的体力回复了！", battler.pbThis))
      else
        battle.pbDisplay(_INTL("因为{2}，{1}回复了体力！", battler.pbThis, battler.abilityName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:ICEBODY,
  proc { |ability, weather, battler, battle|
    next unless weather == :Hail
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp / 16)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的体力回复了！", battler.pbThis))
    else
      battle.pbDisplay(_INTL("因为{2}，{1}回复了体力！", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:ICEFACE,
  proc { |ability, weather, battler, battle|
    next if weather != :Hail
    next if !battler.canRestoreIceFace || battler.form != 1
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的{2}发动！", battler.pbThis, battler.abilityName))
    end
    battler.pbChangeForm(0, _INTL("{1}的样子发生了变化！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:RAINDISH,
  proc { |ability, weather, battler, battle|
    next if ![:Rain, :HeavyRain].include?(weather)
    next if !battler.canHeal?
    battle.pbShowAbilitySplash(battler)
    battler.pbRecoverHP(battler.totalhp / 16)
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的体力回复了！", battler.pbThis))
    else
      battle.pbDisplay(_INTL("因为{2}，{1}回复了体力！", battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::EndOfRoundWeather.add(:SOLARPOWER,
  proc { |ability, weather, battler, battle|
    next if ![:Sun, :HarshSun].include?(weather)
    next if !battler.takesIndirectDamage?
    battle.pbShowAbilitySplash(battler)
    battle.scene.pbDamageAnimation(battler)
    battler.pbReduceHP(battler.totalhp / 8, false)
    battle.pbDisplay(_INTL("{1}被日照伤害了！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battler.pbItemHPHealCheck
  }
)

#===============================================================================
# EndOfRoundHealing handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundHealing.add(:HEALER,
  proc { |ability, battler, battle|
    next if battle.pbRandom(100) >= 30
    battler.allAllies.each do |b|
      next if b.status == :NONE
      battle.pbShowAbilitySplash(battler)
      oldStatus = b.status
      b.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
      if !Battle::Scene::USE_ABILITY_SPLASH
        case oldStatus
        when :SLEEP
          battle.pbDisplay(_INTL("因为{1}的{2}，伙伴醒过来了！", battler.pbThis, battler.abilityName))
        when :POISON
          battle.pbDisplay(_INTL("因为{1}的{2}，伙伴治愈了中毒！", battler.pbThis, battler.abilityName))
        when :BURN
          battle.pbDisplay(_INTL("因为{1}的{2}，伙伴治愈了灼伤！", battler.pbThis, battler.abilityName))
        when :PARALYSIS
          battle.pbDisplay(_INTL("因为{1}的{2}，伙伴治愈了麻痹！", battler.pbThis, battler.abilityName))
        when :FROZEN
          battle.pbDisplay(_INTL("因为{1}的{2}，伙伴治愈了冰冻状态！", battler.pbThis, battler.abilityName))
        end
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

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
        battle.pbDisplay(_INTL("因为{2}，{1}醒过来了！", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了中毒！", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了灼伤！", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了麻痹！", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了冰冻状态！", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

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
        battle.pbDisplay(_INTL("因为{2}，{1}醒过来了！", battler.pbThis, battler.abilityName))
      when :POISON
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了中毒！", battler.pbThis, battler.abilityName))
      when :BURN
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了灼伤！", battler.pbThis, battler.abilityName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了麻痹！", battler.pbThis, battler.abilityName))
      when :FROZEN
        battle.pbDisplay(_INTL("因为{2}，{1}治愈了冰冻状态！", battler.pbThis, battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# EndOfRoundEffect handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundEffect.add(:BADDREAMS,
  proc { |ability, battler, battle|
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler) || !b.asleep?
      battle.pbShowAbilitySplash(battler)
      next if !b.takesIndirectDamage?(Battle::Scene::USE_ABILITY_SPLASH)
      b.pbTakeEffectDamage(b.totalhp / 8) do |hp_lost|
        if Battle::Scene::USE_ABILITY_SPLASH
          battle.pbDisplay(_INTL("{1}正被恶梦缠身！", b.pbThis))
        else
          battle.pbDisplay(_INTL("因为{2}的{3}，{1}被恶梦缠身！",
             b.pbThis, battler.pbThis(true), battler.abilityName))
        end
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

Battle::AbilityEffects::EndOfRoundEffect.add(:MOODY,
  proc { |ability, battler, battle|
    randomUp = []
    randomDown = []
    if Settings::MECHANICS_GENERATION >= 8
      GameData::Stat.each_main_battle do |s|
        randomUp.push(s.id) if battler.pbCanRaiseStatStage?(s.id, battler)
        randomDown.push(s.id) if battler.pbCanLowerStatStage?(s.id, battler)
      end
    else
      GameData::Stat.each_battle do |s|
        randomUp.push(s.id) if battler.pbCanRaiseStatStage?(s.id, battler)
        randomDown.push(s.id) if battler.pbCanLowerStatStage?(s.id, battler)
      end
    end
    next if randomUp.length == 0 && randomDown.length == 0
    battle.pbShowAbilitySplash(battler)
    if randomUp.length > 0
      r = battle.pbRandom(randomUp.length)
      battler.pbRaiseStatStageByAbility(randomUp[r], 2, battler, false)
      randomDown.delete(randomUp[r])
    end
    if randomDown.length > 0
      r = battle.pbRandom(randomDown.length)
      battler.pbLowerStatStageByAbility(randomDown[r], 1, battler, false)
    end
    battle.pbHideAbilitySplash(battler)
    battler.pbItemStatRestoreCheck if randomDown.length > 0
    battler.pbItemOnStatDropped
  }
)

Battle::AbilityEffects::EndOfRoundEffect.add(:SPEEDBOOST,
  proc { |ability, battler, battle|
    # A Pokémon's turnCount is 0 if it became active after the beginning of a
    # round
    if battler.turnCount > 0 && battle.choices[battler.index][0] != :Run &&
       battler.pbCanRaiseStatStage?(:SPEED, battler)
      battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
    end
  }
)

#===============================================================================
# EndOfRoundGainItem handlers
#===============================================================================

Battle::AbilityEffects::EndOfRoundGainItem.add(:BALLFETCH,
  proc { |ability, battler, battle|
    next if battler.item
    next if battle.first_poke_ball.nil?
    battle.pbShowAbilitySplash(battler)
    battler.item = battle.first_poke_ball
    battler.setInitialItem(battler.item) if !battler.initialItem
    battle.first_poke_ball = nil
    battle.pbDisplay(_INTL("{1}捡回了扔出的{2}！", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

Battle::AbilityEffects::EndOfRoundGainItem.add(:HARVEST,
  proc { |ability, battler, battle|
    next if battler.item
    next if !battler.recycleItem || !GameData::Item.get(battler.recycleItem).is_berry?
    if ![:Sun, :HarshSun].include?(battler.effectiveWeather)
      next unless battle.pbRandom(100) < 50
    end
    battle.pbShowAbilitySplash(battler)
    battler.item = battler.recycleItem
    battler.setRecycleItem(nil)
    battler.setInitialItem(battler.item) if !battler.initialItem
    battle.pbDisplay(_INTL("{1}收获了{2}！", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

Battle::AbilityEffects::EndOfRoundGainItem.add(:PICKUP,
  proc { |ability, battler, battle|
    next if battler.item
    foundItem = nil
    fromBattler = nil
    use = 0
    battle.allBattlers.each do |b|
      next if b.index == battler.index
      next if b.effects[PBEffects::PickupUse] <= use
      foundItem   = b.effects[PBEffects::PickupItem]
      fromBattler = b
      use         = b.effects[PBEffects::PickupUse]
    end
    next if !foundItem
    battle.pbShowAbilitySplash(battler)
    battler.item = foundItem
    fromBattler.effects[PBEffects::PickupItem] = nil
    fromBattler.effects[PBEffects::PickupUse]  = 0
    fromBattler.setRecycleItem(nil) if fromBattler.recycleItem == foundItem
    if battle.wildBattle? && !battler.initialItem && fromBattler.initialItem == foundItem
      battler.setInitialItem(foundItem)
      fromBattler.setInitialItem(nil)
    end
    battle.pbDisplay(_INTL("{1}捡来了{2}！", battler.pbThis, battler.itemName))
    battle.pbHideAbilitySplash(battler)
    battler.pbHeldItemTriggerCheck
  }
)

#===============================================================================
# CertainSwitching handlers
#===============================================================================

# There aren't any!

#===============================================================================
# TrappingByTarget handlers
#===============================================================================

Battle::AbilityEffects::TrappingByTarget.add(:ARENATRAP,
  proc { |ability, switcher, bearer, battle|
    next true if !switcher.airborne?
  }
)

Battle::AbilityEffects::TrappingByTarget.add(:MAGNETPULL,
  proc { |ability, switcher, bearer, battle|
    next true if switcher.pbHasType?(:STEEL)
  }
)

Battle::AbilityEffects::TrappingByTarget.add(:SHADOWTAG,
  proc { |ability, switcher, bearer, battle|
    next true if !switcher.hasActiveAbility?(:SHADOWTAG)
  }
)

#===============================================================================
# OnSwitchIn handlers
#===============================================================================

Battle::AbilityEffects::OnSwitchIn.add(:AIRLOCK,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}已经拥有了{2}！", battler.pbThis, battler.abilityName))
    end
    battle.pbDisplay(_INTL("天气的影响消失了！"))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:AIRLOCK, :CLOUDNINE)

Battle::AbilityEffects::OnSwitchIn.add(:ANTICIPATION,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    battlerTypes = battler.pbTypes(true)
    types = battlerTypes
    found = false
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.eachMove do |m|
        next if m.statusMove?
        if types.length > 0
          moveType = m.type
          if Settings::MECHANICS_GENERATION >= 6 && m.function_code == "TypeDependsOnUserIVs"   # Hidden Power
            moveType = pbHiddenPower(b.pokemon)[0]
          end
          eff = Effectiveness.calculate(moveType, *types)
          next if Effectiveness.ineffective?(eff)
          next if !Effectiveness.super_effective?(eff) &&
                  !["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
        elsif !["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
          next
        end
        found = true
        break
      end
      break if found
    end
    if found
      battle.pbShowAbilitySplash(battler)
      battle.pbDisplay(_INTL("{1}因预知到了危险而发抖！", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ASONECHILLINGNEIGH,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}同时拥有了两种特性！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
    battler.ability_id = :UNNERVE
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}因太紧张而无法食用树果！", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
    battler.ability_id = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.copy(:ASONECHILLINGNEIGH, :ASONEGRIMNEIGH)

Battle::AbilityEffects::OnSwitchIn.add(:AURABREAK,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}压制了所有气场！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:COMATOSE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}处于半梦半醒状态！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:CURIOUSMEDICINE,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.hasAlteredStatStages? }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if !b.hasAlteredStatStages?
      b.pbResetStatStages
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}的能力变化消失了！", b.pbThis))
      else
        battle.pbDisplay(_INTL("因为{2}的{3}，{1}的能力变化消失了！",
           b.pbThis, battler.pbThis(true), battler.abilityName))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DARKAURA,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}正在释放暗黑气场！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DAUNTLESSSHIELD,
  proc { |ability, battler, battle, switch_in|
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DELTASTREAM,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:StrongWinds, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DESOLATELAND,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:HarshSun, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DOWNLOAD,
  proc { |ability, battler, battle, switch_in|
    oDef = oSpDef = 0
    battle.allOtherSideBattlers(battler.index).each do |b|
      oDef   += b.defense
      oSpDef += b.spdef
    end
    stat = (oDef < oSpDef) ? :ATTACK : :SPECIAL_ATTACK
    battler.pbRaiseStatStageByAbility(stat, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DRIZZLE,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Rain, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:DROUGHT,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Sun, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ELECTRICSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Electric
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Electric)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FAIRYAURA,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}正在释放妖精气场！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FOREWARN,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    highestPower = 0
    forewarnMoves = []
    battle.allOtherSideBattlers(battler.index).each do |b|
      b.eachMove do |m|
        power = m.power
        power = 160 if ["OHKO", "OHKOIce", "OHKOHitsUndergroundTarget"].include?(m.function_code)
        power = 150 if ["PowerHigherWithUserHP"].include?(m.function_code)    # Eruption
        # Counter, Mirror Coat, Metal Burst
        power = 120 if ["CounterPhysicalDamage",
                        "CounterSpecialDamage",
                        "CounterDamagePlusHalf"].include?(m.function_code)
        # Sonic Boom, Dragon Rage, Night Shade, Endeavor, Psywave,
        # Return, Frustration, Crush Grip, Gyro Ball, Hidden Power,
        # Natural Gift, Trump Card, Flail, Grass Knot
        power = 80 if ["FixedDamage20",
                       "FixedDamage40",
                       "FixedDamageUserLevel",
                       "LowerTargetHPToUserHP",
                       "FixedDamageUserLevelRandom",
                       "PowerHigherWithUserHappiness",
                       "PowerLowerWithUserHappiness",
                       "PowerHigherWithUserHP",
                       "PowerHigherWithTargetFasterThanUser",
                       "TypeAndPowerDependOnUserBerry",
                       "PowerHigherWithLessPP",
                       "PowerLowerWithUserHP",
                       "PowerHigherWithTargetWeight"].include?(m.function_code)
        power = 80 if Settings::MECHANICS_GENERATION <= 5 && m.function_code == "TypeDependsOnUserIVs"
        next if power < highestPower
        forewarnMoves = [] if power > highestPower
        forewarnMoves.push(m.name)
        highestPower = power
      end
    end
    if forewarnMoves.length > 0
      battle.pbShowAbilitySplash(battler)
      forewarnMoveName = forewarnMoves[battle.pbRandom(forewarnMoves.length)]
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}预知到了{2}！",
          battler.pbThis, forewarnMoveName))
      else
        battle.pbDisplay(_INTL("{1}因预知梦预知到了{2}！",
          battler.pbThis, forewarnMoveName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:FRISK,
  proc { |ability, battler, battle, switch_in|
    next if !battler.pbOwnedByPlayer?
    foes = battle.allOtherSideBattlers(battler.index).select { |b| b.item }
    if foes.length > 0
      battle.pbShowAbilitySplash(battler)
      if Settings::MECHANICS_GENERATION >= 6
        foes.each do |b|
          battle.pbDisplay(_INTL("{1}察觉到了{2}的{3}！",
             battler.pbThis, b.pbThis(true), b.itemName))
        end
      else
        foe = foes[battle.pbRandom(foes.length)]
        battle.pbDisplay(_INTL("{1}察觉到了敌人的{3}！",
           battler.pbThis, foe.itemName))
      end
      battle.pbHideAbilitySplash(battler)
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:GRASSYSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Grassy
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Grassy)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:ICEFACE,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:EISCUE) || battler.form != 1
    next if battler.effectiveWeather != :Hail
    battle.pbShowAbilitySplash(battler)
    if !Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}的{2}发动！", battler.pbThis, battler.abilityName))
    end
    battler.pbChangeForm(0, _INTL("{1}的样子发生了变化！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:IMPOSTER,
  proc { |ability, battler, battle, switch_in|
    next if !switch_in || battler.effects[PBEffects::Transform]
    choice = battler.pbDirectOpposing
    next if choice.fainted?
    next if choice.effects[PBEffects::Transform] ||
            choice.effects[PBEffects::Illusion] ||
            choice.effects[PBEffects::Substitute] > 0 ||
            choice.effects[PBEffects::SkyDrop] >= 0 ||
            choice.semiInvulnerable?
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.pbAnimation(:TRANSFORM, battler, choice)
    battle.scene.pbChangePokemon(battler, choice.pokemon)
    battler.pbTransform(choice)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:INTIMIDATE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler)
      check_item = true
      if b.hasActiveAbility?(:CONTRARY)
        check_item = false if b.statStageAtMax?(:ATTACK)
      elsif b.statStageAtMin?(:ATTACK)
        check_item = false
      end
      check_ability = b.pbLowerAttackStatStageIntimidate(battler)
      b.pbAbilitiesOnIntimidated if check_ability
      b.pbItemOnIntimidatedCheck if check_item
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:INTREPIDSWORD,
  proc { |ability, battler, battle, switch_in|
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MIMICRY,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :None
    Battle::AbilityEffects.triggerOnTerrainChange(ability, battler, battle, false)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MISTYSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Misty
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Misty)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:MOLDBREAKER,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}打破了常规！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:NEUTRALIZINGGAS,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler, true)
    battle.pbHideAbilitySplash(battler)
    battle.pbDisplay(_INTL("周围充满了化学变化气体！"))
    battle.allBattlers.each do |b|
      # Slow Start - end all turn counts
      b.effects[PBEffects::SlowStart] = 0
      # Truant - let b move on its first turn after Neutralizing Gas disappears
      b.effects[PBEffects::Truant] = false
      # Gorilla Tactics - end choice lock
      if !b.hasActiveItem?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF])
        b.effects[PBEffects::ChoiceBand] = nil
      end
      # Illusion - end illusions
      if b.effects[PBEffects::Illusion]
        b.effects[PBEffects::Illusion] = nil
        if !b.effects[PBEffects::Transform]
          battle.scene.pbChangePokemon(b, b.pokemon)
          battle.pbDisplay(_INTL("{1}的{2}消失了！", b.pbThis, b.abilityName))
          battle.pbSetSeen(b)
        end
      end
    end
    # Trigger items upon Unnerve being negated
    battler.ability_id = nil   # Allows checking if Unnerve was active before
    had_unnerve = battle.pbCheckGlobalAbility([:UNNERVE, :ASONECHILLINGNEIGH, :ASONEGRIMNEIGH])
    battler.ability_id = :NEUTRALIZINGGAS
    if had_unnerve && !battle.pbCheckGlobalAbility([:UNNERVE, :ASONECHILLINGNEIGH, :ASONEGRIMNEIGH])
      battle.allBattlers.each { |b| b.pbItemsOnUnnerveEnding }
    end
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PASTELVEIL,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.status == :POISON }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if b.status != :POISON
      b.pbCureStatus(Battle::Scene::USE_ABILITY_SPLASH)
      if !Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("因为{1}的{2}，{1}治愈了中毒！",
           battler.pbThis, battler.abilityName, b.pbThis(true)))
      end
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PRESSURE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("从{1}的身上感到了压迫感！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PRIMORDIALSEA,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:HeavyRain, battler, true)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:PSYCHICSURGE,
  proc { |ability, battler, battle, switch_in|
    next if battle.field.terrain == :Psychic
    battle.pbShowAbilitySplash(battler)
    battle.pbStartTerrain(battler, :Psychic)
    # NOTE: The ability splash is hidden again in def pbStartTerrain.
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SANDSTREAM,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Sandstorm, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SCREENCLEANER,
  proc { |ability, battler, battle, switch_in|
    next if battler.pbOwnSide.effects[PBEffects::AuroraVeil] == 0 &&
            battler.pbOwnSide.effects[PBEffects::LightScreen] == 0 &&
            battler.pbOwnSide.effects[PBEffects::Reflect] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::AuroraVeil] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::LightScreen] == 0 &&
            battler.pbOpposingSide.effects[PBEffects::Reflect] == 0
    battle.pbShowAbilitySplash(battler)
    if battler.pbOpposingSide.effects[PBEffects::AuroraVeil] > 0
      battler.pbOpposingSide.effects[PBEffects::AuroraVeil] = 0
      battle.pbDisplay(_INTL("{1}的极光幕消失了！", battler.pbOpposingTeam))
    end
    if battler.pbOpposingSide.effects[PBEffects::LightScreen] > 0
      battler.pbOpposingSide.effects[PBEffects::LightScreen] = 0
      battle.pbDisplay(_INTL("{1}的光墙消失了！", battler.pbOpposingTeam))
    end
    if battler.pbOpposingSide.effects[PBEffects::Reflect] > 0
      battler.pbOpposingSide.effects[PBEffects::Reflect] = 0
      battle.pbDisplay(_INTL("{1}的反射壁消失了！", battler.pbOpposingTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
      battler.pbOwnSide.effects[PBEffects::AuroraVeil] = 0
      battle.pbDisplay(_INTL("{1}的极光幕消失了！", battler.pbTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::LightScreen] > 0
      battler.pbOwnSide.effects[PBEffects::LightScreen] = 0
      battle.pbDisplay(_INTL("{1}的光墙消失了！", battler.pbTeam))
    end
    if battler.pbOwnSide.effects[PBEffects::Reflect] > 0
      battler.pbOwnSide.effects[PBEffects::Reflect] = 0
      battle.pbDisplay(_INTL("{1}的反射壁消失了！", battler.pbTeam))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SLOWSTART,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battler.effects[PBEffects::SlowStart] = 5
    if Battle::Scene::USE_ABILITY_SPLASH
      battle.pbDisplay(_INTL("{1}无法拿出平时的水平！", battler.pbThis))
    else
      battle.pbDisplay(_INTL("因为{2}，{1}无法拿出平时的水平！",
         battler.pbThis, battler.abilityName))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:SNOWWARNING,
  proc { |ability, battler, battle, switch_in|
    battle.pbStartWeatherAbility(:Hail, battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:TERAVOLT,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}正在释放溅射气场！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:TURBOBLAZE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}正在释放炽焰气场！", battler.pbThis))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:UNNERVE,
  proc { |ability, battler, battle, switch_in|
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}因太紧张而无法食用树果！", battler.pbOpposingTeam))
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# OnSwitchOut handlers
#===============================================================================

Battle::AbilityEffects::OnSwitchOut.add(:IMMUNITY,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :POISON
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:INSOMNIA,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :SLEEP
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:INSOMNIA, :VITALSPIRIT)

Battle::AbilityEffects::OnSwitchOut.add(:LIMBER,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :PARALYSIS
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:MAGMAARMOR,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :FROZEN
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:NATURALCURE,
  proc { |ability, battler, endOfBattle|
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:REGENERATOR,
  proc { |ability, battler, endOfBattle|
    next if endOfBattle
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.pbRecoverHP(battler.totalhp / 3, false, false)
  }
)

Battle::AbilityEffects::OnSwitchOut.add(:WATERVEIL,
  proc { |ability, battler, endOfBattle|
    next if battler.status != :BURN
    PBDebug.log("[Ability triggered] #{battler.pbThis}'s #{battler.abilityName}")
    battler.status = :NONE
  }
)

Battle::AbilityEffects::OnSwitchOut.copy(:WATERVEIL, :WATERBUBBLE)

#===============================================================================
# ChangeOnBattlerFainting handlers
#===============================================================================

Battle::AbilityEffects::ChangeOnBattlerFainting.add(:POWEROFALCHEMY,
  proc { |ability, battler, fainted, battle|
    next if battler.opposes?(fainted)
    next if fainted.ungainableAbility? ||
       [:POWEROFALCHEMY, :RECEIVER, :TRACE, :WONDERGUARD].include?(fainted.ability_id)
    battle.pbShowAbilitySplash(battler, true)
    battler.ability = fainted.ability
    battle.pbReplaceAbilitySplash(battler)
    battle.pbDisplay(_INTL("继承了{1}的{2}！", fainted.pbThis, fainted.abilityName))
    battle.pbHideAbilitySplash(battler)
  }
)

Battle::AbilityEffects::ChangeOnBattlerFainting.copy(:POWEROFALCHEMY, :RECEIVER)

#===============================================================================
# OnBattlerFainting handlers
#===============================================================================

Battle::AbilityEffects::OnBattlerFainting.add(:SOULHEART,
  proc { |ability, battler, fainted, battle|
    battler.pbRaiseStatStageByAbility(:SPECIAL_ATTACK, 1, battler)
  }
)

#===============================================================================
# OnTerrainChange handlers
#===============================================================================

Battle::AbilityEffects::OnTerrainChange.add(:MIMICRY,
  proc { |ability, battler, battle, ability_changed|
    if battle.field.terrain == :None
      # Revert to original typing
      battle.pbShowAbilitySplash(battler)
      battler.pbResetTypes
      battle.pbDisplay(_INTL("{1}变回了正常的属性！", battler.pbThis))
      battle.pbHideAbilitySplash(battler)
    else
      # Change to new typing
      terrain_hash = {
        :Electric => :ELECTRIC,
        :Grassy   => :GRASS,
        :Misty    => :FAIRY,
        :Psychic  => :PSYCHIC
      }
      new_type = terrain_hash[battle.field.terrain]
      new_type_name = nil
      if new_type
        type_data = GameData::Type.try_get(new_type)
        new_type = nil if !type_data
        new_type_name = type_data.name if type_data
      end
      if new_type
        battle.pbShowAbilitySplash(battler)
        battler.pbChangeTypes(new_type)
        battle.pbDisplay(_INTL("{1}的属性变成了{2}！", battler.pbThis, new_type_name))
        battle.pbHideAbilitySplash(battler)
      end
    end
  }
)

#===============================================================================
# OnIntimidated handlers
#===============================================================================

Battle::AbilityEffects::OnIntimidated.add(:RATTLED,
  proc { |ability, battler, battle|
    next if Settings::MECHANICS_GENERATION < 8
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
  }
)

#===============================================================================
# CertainEscapeFromBattle handlers
#===============================================================================

Battle::AbilityEffects::CertainEscapeFromBattle.add(:RUNAWAY,
  proc { |ability, battler|
    next true
  }
)
