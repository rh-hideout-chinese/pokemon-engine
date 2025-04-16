################################################################################
# 
# DLC ability handlers.
# 
################################################################################

############################## Teal Mask DLC ###################################

#===============================================================================
# Supersweet Syrup
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:SUPERSWEETSYRUP,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbShowAbilitySplash(battler)
    battle.pbDisplay(_INTL("{1}的蜜散发出了甜甜香气！", battler.pbThis(true)))
    battle.allOtherSideBattlers(battler.index).each do |b|
      next if !b.near?(battler) || b.fainted?
      if b.itemActive? && !b.hasActiveAbility?(:CONTRARY) && b.effects[PBEffects::Substitute] == 0
        next if Battle::ItemEffects.triggerStatLossImmunity(b.item, b, :EVASION, battle, true)
      end
      b.pbLowerStatStageByAbility(:EVASION, 1, battler, false)
    end
    battle.pbHideAbilitySplash(battler)
    battle.pbSetAbilityTrigger(battler)
  }
)

#===============================================================================
# Hospitality
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:HOSPITALITY,
  proc { |ability, battler, battle, switch_in|
    next if battler.allAllies.none? { |b| b.canHeal? }
    battle.pbShowAbilitySplash(battler)
    battler.allAllies.each do |b|
      next if !b.canHeal?
      amt = (b.totalhp / 4).floor
      b.pbRecoverHP(amt)
      battle.pbDisplay(_INTL("{1}喝光了{2}泡的茶！", b.pbThis, battler.pbThis(true)))
    end
    battle.pbHideAbilitySplash(battler)
  }
)

#===============================================================================
# Toxic Chain
#===============================================================================
Battle::AbilityEffects::OnDealingHit.add(:TOXICCHAIN,
  proc { |ability, user, target, move, battle|
    next if target.fainted?
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
        msg = _INTL("{1}中剧毒了！", target.pbThis)
      end
      target.pbPoison(user, msg, true)
    end
    battle.pbHideAbilitySplash(user)
  }
)

#===============================================================================
# Mind's Eye
#===============================================================================
Battle::AbilityEffects::StatLossImmunity.copy(:KEENEYE, :MINDSEYE)
Battle::AbilityEffects::AccuracyCalcFromUser.copy(:KEENEYE, :MINDSEYE)

#===============================================================================
# Embody Aspect
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON).form_name
    battle.pbDisplay(_INTL("{2}让{1}发出光辉！", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPEED, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_1,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_1).form_name
    battle.pbDisplay(_INTL("{2}让{1}发出光辉！", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:SPECIAL_DEFENSE, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_2,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_2).form_name
    battle.pbDisplay(_INTL("{2}让{1}发出光辉！", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:ATTACK, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)

Battle::AbilityEffects::OnSwitchIn.add(:EMBODYASPECT_3,
  proc { |ability, battler, battle, switch_in|
    next if !battler.isSpecies?(:OGERPON)
    next if battler.effects[PBEffects::OneUseAbility] == ability
    mask = GameData::Species.get(:OGERPON_3).form_name
    battle.pbDisplay(_INTL("{2}让{1}发出光辉！", mask, battler.pbThis(true)))
    battler.pbRaiseStatStageByAbility(:DEFENSE, 1, battler)
    battler.effects[PBEffects::OneUseAbility] = ability
  }
)


############################# Indigo Disk DLC ##################################

#===============================================================================
# Tera Shell
#===============================================================================
Battle::AbilityEffects::ModifyTypeEffectiveness.add(:TERASHELL,
  proc { |ability, user, target, move, battle, effectiveness|
    next if !move.damagingMove?
    next if user.hasMoldBreaker?
    next if target.hp < target.totalhp
    next if effectiveness < Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    target.damageState.terashell = true
    next Effectiveness::NOT_VERY_EFFECTIVE_MULTIPLIER
  }
)

Battle::AbilityEffects::OnMoveSuccessCheck.add(:TERASHELL,
  proc { |ability, user, target, move, battle|
    next if !target.damageState.terashell
    battle.pbShowAbilitySplash(target)
    battle.pbDisplay(_INTL("{1}让甲壳发出光辉，使属性相克发生扭曲！！", target.pbThis))
    battle.pbHideAbilitySplash(target)
  }
)

#===============================================================================
# Teraform Zero
#===============================================================================
Battle::AbilityEffects::OnSwitchIn.add(:TERAFORMZERO,
  proc { |ability, battler, battle, switch_in|
    next if battler.ability_triggered?
    battle.pbSetAbilityTrigger(battler)
    weather = battle.field.weather
    terrain = battle.field.terrain
    next if weather == :None && terrain == :None
    showSplash = false
    if weather != :None && battle.field.defaultWeather == :None
	  showSplash = true
      battle.pbShowAbilitySplash(battler)
      battle.field.weather = :None
      battle.field.weatherDuration = 0
      case weather
      when :Sun         then battle.pbDisplay(_INTL("日照复原了！"))
      when :Rain        then battle.pbDisplay(_INTL("雨停了！"))
      when :Sandstorm   then battle.pbDisplay(_INTL("沙暴停止了！"))
      when :Hail
        case Settings::HAIL_WEATHER_TYPE
        when 0 then battle.pbDisplay(_INTL("冰雹不下了！"))
        when 1 then battle.pbDisplay(_INTL("雪停了！"))
        when 2 then battle.pbDisplay(_INTL("暴风雪停息了！"))
        end
      when :HarshSun    then battle.pbDisplay(_INTL("日照复原了！"))
      when :HeavyRain   then battle.pbDisplay(_INTL("暴雨停了！"))
      when :StrongWinds then battle.pbDisplay(_INTL("神秘的乱流停止了！"))
      else
        battle.pbDisplay(_INTL("天气恢复正常了。"))
      end
    end
    if terrain != :None && battle.field.defaultTerrain == :None
      battle.pbShowAbilitySplash(battler) if !showSplash
      battle.field.terrain = :None
      battle.field.terrainDuration = 0
      case terrain
      when :Electric then battle.pbDisplay(_INTL("脚下的电光消失不见了！"))
      when :Grassy   then battle.pbDisplay(_INTL("脚下的青草消失不见了！"))
      when :Psychic  then battle.pbDisplay(_INTL("脚下的雾气消失不见了！"))
      when :Misty    then battle.pbDisplay(_INTL("脚下的奇妙感觉消失了！"))
      else
        battle.pbDisplay(_INTL("对战场地恢复正常了。"))
      end
    end
    next if !showSplash
    battle.pbHideAbilitySplash(battler)
    battle.allBattlers.each { |b| b.pbCheckFormOnWeatherChange }
    battle.allBattlers.each { |b| b.pbAbilityOnTerrainChange }
    battle.allBattlers.each { |b| b.pbItemTerrainStatBoostCheck }
  }
)

#===============================================================================
# Poison Puppeteer
#===============================================================================
Battle::AbilityEffects::OnInflictingStatus.add(:POISONPUPPETEER,
  proc { |ability, user, battler, status|
    next if !user || user.index == battler.index
    next if status != :POISON
    next if battler.effects[PBEffects::Confusion] > 0
    user.battle.pbShowAbilitySplash(user)
    battler.pbConfuse if battler.pbCanConfuse?(user, false, nil)
    user.battle.pbHideAbilitySplash(user)
  }
)