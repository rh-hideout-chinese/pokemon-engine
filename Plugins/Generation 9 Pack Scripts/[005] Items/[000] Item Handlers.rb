################################################################################
# 
# Updates to old item handlers (overworld use).
# 
################################################################################


#===============================================================================
# Awakening, Chesto Berry, Blue Flute
#===============================================================================
# Adds Drowsiness as a status that may be healed.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:AWAKENING, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || ![:SLEEP, :DROWSY].include?(pkmn.status)
    scene.pbDisplay(_INTL("没有任何效果。"))
    next false
  end
  case pkmn.status
  when :SLEEP  then msg = _INTL("{1}醒过来了！", pkmn.name)
  when :DROWSY then msg = _INTL("{1}清醒过来了！", pkmn.name)
  end
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(msg)
  next true
})

ItemHandlers::UseOnPokemon.copy(:AWAKENING, :CHESTOBERRY, :BLUEFLUTE, :POKEFLUTE)

#===============================================================================
# Ice Heal, Aspear Berry
#===============================================================================
# Adds Frostbite as a status that may be healed.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:ICEHEAL, proc { |item, qty, pkmn, scene|
  if pkmn.fainted? || ![:FROZEN, :FROSTBITE].include?(pkmn.status)
    scene.pbDisplay(_INTL("没有任何效果。"))
    next false
  end
  case pkmn.status
  when :FROZEN    then msg = _INTL("{1}身体的冰融化了！", pkmn.name)
  when :FROSTBITE then msg = _INTL("{1}的冻伤痊愈了！", pkmn.name)
  end
  pkmn.heal_status
  scene.pbRefresh
  scene.pbDisplay(msg)
  next true
})

ItemHandlers::UseOnPokemon.copy(:ICEHEAL, :ASPEARBERRY)

#===============================================================================
# Gracidea
#===============================================================================
# Can now toggle between Shaymin forms, and fails if the user is Frostbitten.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:GRACIDEA, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:SHAYMIN) || [:FROZEN, :FROSTBITE].include?(pkmn.status) || PBDayNight.isNight?
    scene.pbDisplay(_INTL("即便使用也无效果哦。"))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("不能用于濒死的宝可梦。"))
    next false
  end
  form = (pkmn.form == 0) ? 1 : 0
  pkmn.setForm(form) do
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1}的形态改变了！", pkmn.name))
  end
  next true
})

#===============================================================================
# Reveal Glass
#===============================================================================
# Adds compatibility with any species with the "ForcesOfNature" flag.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:REVEALGLASS, proc { |item, qty, pkmn, scene|
  if !pkmn.species_data.has_flag?("ForcesOfNature")
    scene.pbDisplay(_INTL("即便使用也无效果哦。"))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("不能用于濒死的宝可梦。"))
    next false
  end
  newForm = (pkmn.form == 0) ? 1 : 0
  pkmn.setForm(newForm) {
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1}的形态改变了！", pkmn.name))
  }
  next true
})

#===============================================================================
# Ability Patch
#===============================================================================
# Adds the ability to switch from a Hidden Ability.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:ABILITYPATCH, proc { |item, qty, pkmn, scene|
  if scene.pbConfirm(_INTL("要改变{1}的特性吗？", pkmn.name))
    current_abi = pkmn.ability_index
    abils = pkmn.getAbilityList
    new_ability_id = nil
    abils.each { |a| new_ability_id = a[0] if (current_abi < 2 && a[1] == 2) || (current_abi == 2 && a[1] == 0) }
    if !new_ability_id || pkmn.isSpecies?(:ZYGARDE)
      scene.pbDisplay(_INTL("没有任何效果。"))
      next false
    end
    new_ability_name = GameData::Ability.get(new_ability_id).name
    pkmn.ability_index = current_abi < 2 ? 2 : 0
    pkmn.ability = nil
    scene.pbRefresh
    scene.pbDisplay(_INTL("{1}的特性变成了{2}！",
       pkmn.name, new_ability_name))
    next true
  end
  next false
})


################################################################################
# 
# Updates to old battle item handlers (used from the bag).
# 
################################################################################


#===============================================================================
# Awakening, Chesto Berry, Blue Flute
#===============================================================================
# Adds Drowsiness as a status that may be healed.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:AWAKENING, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next pbBattleItemCanCureStatus?(:SLEEP, pokemon, scene, showMessages) ||
       pbBattleItemCanCureStatus?(:DROWSY, pokemon, scene, showMessages)
})

ItemHandlers::CanUseInBattle.copy(:AWAKENING, :CHESTOBERRY)

ItemHandlers::CanUseInBattle.add(:BLUEFLUTE, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  if battler&.hasActiveAbility?(:SOUNDPROOF)
    scene.pbDisplay(_INTL("没有任何效果。")) if showMessages
    next false
  end
  next pbBattleItemCanCureStatus?(:SLEEP, pokemon, scene, showMessages) ||
       pbBattleItemCanCureStatus?(:DROWSY, pokemon, scene, showMessages)
})

ItemHandlers::BattleUseOnPokemon.add(:AWAKENING, proc { |item, pokemon, battler, choices, scene|
  oldStatus = pokemon.status
  pokemon.heal_status
  battler&.pbCureStatus(false)
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  case oldStatus
  when :SLEEP  then scene.pbDisplay(_INTL("{1}醒过来了！", name))
  when :DROWSY then scene.pbDisplay(_INTL("{1}清醒过来了！", name))
  end
})

ItemHandlers::BattleUseOnPokemon.copy(:AWAKENING, :CHESTOBERRY, :BLUEFLUTE)

#===============================================================================
# Poke Flute
#===============================================================================
# Adds Drowsiness as a status that may be healed.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:POKEFLUTE, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  if battle.allBattlers.none? { |b| [:SLEEP, :DROWSY].include?(b.status) && !b.hasActiveAbility?(:SOUNDPROOF) }
    scene.pbDisplay(_INTL("没有任何效果。")) if showMessages
    next false
  end
  next true
})

ItemHandlers::UseInBattle.add(:POKEFLUTE, proc { |item, battler, battle|
  battle.allBattlers.each do |b|
    b.pbCureStatus(false) if [:SLEEP, :DROWSY].include?(b.status) && !b.hasActiveAbility?(:SOUNDPROOF)
  end
  battle.pbDisplay(_INTL("所有的宝可梦被旋律激起了兴致！"))
})

#===============================================================================
# Ice Heal, Aspear Berry
#===============================================================================
# Adds Frostbite as a status that may be healed.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:ICEHEAL, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next pbBattleItemCanCureStatus?(:FROZEN, pokemon, scene, showMessages) ||
       pbBattleItemCanCureStatus?(:FROSTBITE, pokemon, scene, showMessages)
})

ItemHandlers::CanUseInBattle.copy(:ICEHEAL, :ASPEARBERRY)

ItemHandlers::BattleUseOnPokemon.add(:ICEHEAL, proc { |item, pokemon, battler, choices, scene|
  oldStatus = pokemon.status
  pokemon.heal_status
  battler&.pbCureStatus(false)
  name = (battler) ? battler.pbThis : pokemon.name
  scene.pbRefresh
  case oldStatus
  when :FROZEN    then scene.pbDisplay(_INTL("{1}身体的冰融化了！", name))
  when :FROSTBITE then scene.pbDisplay(_INTL("{1}的冻伤痊愈了！", name))
  end
})

ItemHandlers::BattleUseOnPokemon.copy(:ICEHEAL, :ASPEARBERRY)


################################################################################
# 
# Updates to old battle item handlers (held items).
# 
################################################################################


#===============================================================================
# Lum Berry
#===============================================================================
# Adds Drowsy/Frostbite as statuses that may be healed.
#-------------------------------------------------------------------------------
Battle::ItemEffects::StatusCure.add(:LUMBERRY,
  proc { |item, battler, battle, forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if battler.status == :NONE &&
                  battler.effects[PBEffects::Confusion] == 0
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry", battler) if !forced
    oldStatus = battler.status
    oldConfusion = (battler.effects[PBEffects::Confusion] > 0)
    battler.pbCureStatus(forced)
    battler.pbCureConfusion
    if forced
      battle.pbDisplay(_INTL("{1}的混乱解除了！", battler.pbThis)) if oldConfusion
    else
      case oldStatus
      when :SLEEP
        battle.pbDisplay(_INTL("{1}的{2}让自己醒过来了！", battler.pbThis, itemName))
      when :POISON
        battle.pbDisplay(_INTL("{1}的{2}治愈了中毒！", battler.pbThis, itemName))
      when :BURN
        battle.pbDisplay(_INTL("{1}的{2}治愈了灼伤！", battler.pbThis, itemName))
      when :PARALYSIS
        battle.pbDisplay(_INTL("{1}的{2}治愈了麻痹！", battler.pbThis, itemName))
      when :FROZEN
        battle.pbDisplay(_INTL("{1}的{2}治愈了冰冻状态！", battler.pbThis, itemName))
      when :DROWSY
        battle.pbDisplay(_INTL("{1}的{2}让自己清醒过来了！", battler.pbThis, itemName))
      when :FROSTBITE
        battle.pbDisplay(_INTL("{1}的{2}治愈了冻伤！", battler.pbThis, itemName))
      end
      if oldConfusion
        battle.pbDisplay(_INTL("{1}的{2}治愈了混乱！", battler.pbThis, itemName))
      end
    end
    next true
  }
)

#===============================================================================
# Chesto Berry
#===============================================================================
# Adds Drowsiness as a status that may be healed.
#-------------------------------------------------------------------------------
Battle::ItemEffects::StatusCure.add(:CHESTOBERRY,
  proc { |item, battler, battle, forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if ![:SLEEP, :DROWSY].include?(battler.status)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry", battler) if !forced
    case battler.status
    when :SLEEP  then msg = _INTL("{1}的{2}让自己醒过来了！", battler.pbThis, itemName)
    when :DROWSY then msg = _INTL("{1}的{2}让自己清醒过来了！", battler.pbThis, itemName)
    end
    battler.pbCureStatus(forced)
    battle.pbDisplay(msg) if !forced
    next true
  }
)

#===============================================================================
# Aspear Berry
#===============================================================================
# Adds Frostbite as a status that may be healed.
#-------------------------------------------------------------------------------
Battle::ItemEffects::StatusCure.add(:ASPEARBERRY,
  proc { |item, battler, battle, forced|
    next false if !forced && !battler.canConsumeBerry?
    next false if ![:FROZEN, :FROSTBITE].include?(battler.status)
    itemName = GameData::Item.get(item).name
    PBDebug.log("[Item triggered] #{battler.pbThis}'s #{itemName}") if forced
    battle.pbCommonAnimation("EatBerry", battler) if !forced
    case battler.status
    when :FROZEN    then msg = _INTL("{1}的{2}治愈了冰冻状态！", battler.pbThis, itemName)
    when :FROSTBITE then msg = _INTL("{1}的{2}治愈了冻伤！", battler.pbThis, itemName)
    end
    battler.pbCureStatus(forced)
    battle.pbDisplay(msg) if !forced
    next true
  }
)

#===============================================================================
# Red Card
#===============================================================================
# Adds Guard Dog immunity.
#-------------------------------------------------------------------------------
Battle::ItemEffects::AfterMoveUseFromTarget.add(:REDCARD,
  proc { |item, battler, user, move, switched_battlers, battle|
    next if !switched_battlers.empty? || user.fainted?
    newPkmn = battle.pbGetReplacementPokemonIndex(user.index, true)
    next if newPkmn < 0
    battle.pbCommonAnimation("UseItem", battler)
    battle.pbDisplay(_INTL("{1}猛地向{3}出示了{2}！",
       battler.pbThis, battler.itemName, user.pbThis(true)))
    battler.pbConsumeItem
    next if user.effects[PBEffects::Commander]
    if user.hasActiveAbility?([:SUCTIONCUPS, :GUARDDOG]) && !battle.moldBreaker
      battle.pbShowAbilitySplash(user)
      if Battle::Scene::USE_ABILITY_SPLASH
        battle.pbDisplay(_INTL("{1}屹立不动！", user.pbThis))
      else
        battle.pbDisplay(_INTL("{1}的{2}固定住了自己！", user.pbThis, user.abilityName))
      end
      battle.pbHideAbilitySplash(user)
      next
    end
    if user.effects[PBEffects::Ingrain]
      battle.pbDisplay(_INTL("{1}扎下了根，屹立不动！", user.pbThis))
      next
    end
    battle.pbRecallAndReplace(user.index, newPkmn, true)
    battle.pbDisplay(_INTL("{1}被拖进了战斗！", user.pbThis))
    battle.pbClearChoice(user.index)
    switched_battlers.push(user.index)
    battle.moldBreaker = false
    battle.pbOnBattlerEnteringBattle(user.index)
  }
)

#===============================================================================
# Quick Claw
#===============================================================================
# Cannot trigger if the user has Mycelium Might and used a status move.
#-------------------------------------------------------------------------------
Battle::ItemEffects::PriorityBracketChange.add(:QUICKCLAW,
  proc { |item, battler, battle|
    if battler.hasActiveAbility?(:MYCELIUMMIGHT)
      pri = Battle::AbilityEffects.triggerPriorityBracketChange(battler.ability, battler, battle)
      next pri if pri != 0
    end
    next 1 if battle.pbRandom(100) < 20
  }
)