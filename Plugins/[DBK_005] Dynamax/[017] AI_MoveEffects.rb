#===============================================================================
# Dynamax move score handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Max Guard
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("ProtectUserEvenFromDynamaxMoves",
  proc { |score, move, user, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if user.effects[PBEffects::ProtectRate] >= 4
    useless = true
    ai.each_foe_battler(user.side) do |b, i|
      next if !b.can_attack?
      next if b.check_for_move { |m| m.damagingMove? && m.ignoresMaxGuard? }
      useless = false
      score += 7 if b.battler.dynamax?
      score += 15 if b.effects[PBEffects::TwoTurnAttack] &&
                     GameData::Move.get(b.effects[PBEffects::TwoTurnAttack]).category != 2
    end
    next Battle::AI::MOVE_USELESS_SCORE if useless
    user_eor_damage = user.rough_end_of_round_damage
    if user_eor_damage >= user.hp
      next Battle::AI::MOVE_USELESS_SCORE
    elsif user_eor_damage > 0
      score -= 8
    elsif user_eor_damage < 0
      score += 8
    end
    score -= (user.effects[PBEffects::ProtectRate] - 1) * ((Settings::MECHANICS_GENERATION >= 6) ? 15 : 10)
    next score
  }
)

#-------------------------------------------------------------------------------
# Max Flare, Max Geyser, Max Rockfall, Max Hailstorm
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("DamageTargetStartSunWeather",
  proc { |score, move, user, ai, battle|
    case move.type
    when :FIRE  then weatherType = :Sun
    when :WATER then weatherType = :Rain
    when :ROCK  then weatherType = :Sandstorm
    when :ICE   then weatherType = :Hail
    end
    next score if battle.pbCheckGlobalAbility(:AIRLOCK) ||
                  battle.pbCheckGlobalAbility(:CLOUDNINE) ||
                  [:HarshSun, :HeavyRain, :StrongWinds, weatherType].include?(battle.field.weather)
    if ai.trainer.high_skill? && battle.field.weather != :None
      score -= ai.get_score_for_weather(battle.field.weather, user)
    end
    score += ai.get_score_for_weather(weatherType, user, true)
    next score
  }
)
Battle::AI::Handlers::MoveEffectScore.copy("DamageTargetStartSunWeather",
                                           "DamageTargetStartRainWeather",
                                           "DamageTargetStartSandstormWeather",
                                           "DamageTargetStartHailWeather")
										   
#-------------------------------------------------------------------------------
# Max Lightning, Max Overgrowth, Max Starfall, Max Mindstorm
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("DamageTargetStartElectricTerrain",
  proc { |score, move, user, ai, battle|
    case move.type
    when :ELECTRIC then terrainType = :Electric
    when :GRASS    then terrainType = :Grassy
    when :FAIRY    then terrainType = :Misty
    when :PSYCHIC  then terrainType = :Psychic
    end
    next score if battle.field.terrain == terrainType
    if ai.trainer.high_skill? && battle.field.terrain != :None
      score -= ai.get_score_for_terrain(battle.field.terrain, user)
    end
    score += ai.get_score_for_terrain(terrainType, user, true)
    next score
  }
)
Battle::AI::Handlers::MoveEffectScore.copy("DamageTargetStartElectricTerrain",
                                           "DamageTargetStartGrassyTerrain",
                                           "DamageTargetStartMistyTerrain",
                                           "DamageTargetStartPsychicTerrain")
										   
#-------------------------------------------------------------------------------
# Max Knuckle, Max Steelspike, Max Ooze, Max Quake, Max Airstream
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("RaiseUserSideAtk1",
  proc { |score, move, user, ai, battle|
    old_score = score
    battle.allSameSideBattlers(user.battler).each do |b|
      check_score = ai.get_score_for_target_stat_raise(old_score, ai.battlers[b.index], move.move.statUp)
      score += check_score / battle.pbSideBattlerCount(user.battler)
    end
    next score 
  }
)
Battle::AI::Handlers::MoveEffectScore.copy("RaiseUserSideAtk1",
                                           "RaiseUserSideDef1",
                                           "RaiseUserSideSpAtk1",
                                           "RaiseUserSideSpDef1",
                                           "RaiseUserSideSpeed1")
										   
#-------------------------------------------------------------------------------
# Max Wyrmwind, Max Phantasm, Max Flutterby, Max Darkness, Max Strike,
# G-Max Foamburst, G-Max Tartness
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("LowerTargetSideAtk1",
  proc { |score, move, user, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = ai.get_score_for_target_stat_drop(old_score, ai.battlers[b.index], move.move.statDown)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score 
  }
)
Battle::AI::Handlers::MoveEffectScore.copy("LowerTargetSideAtk1",
                                           "LowerTargetSideDef1",
                                           "LowerTargetSideSpAtk1",
                                           "LowerTargetSideSpDef1",
                                           "LowerTargetSideSpeed1",
                                           "LowerTargetSideSpeed2",
                                           "LowerTargetSideEva1")

#-------------------------------------------------------------------------------
# G-Max Snooze
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("SleepTargetNextTurn",
                                                        "DamageTargetSleepTargetNextTurn")
										   
#-------------------------------------------------------------------------------
# G-Max Malordor
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("PoisonTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Volt Crash
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ParalyzeTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("ParalyzeTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Stun Shock
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonOrParalyzeTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("PoisonTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      check_score += Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("ParalyzeTarget", 
                       old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Befuddle
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("PoisonParalyzeOrSleepTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("PoisonTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      check_score += Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("ParalyzeTarget", 
                       old_score, move, user, ai.battlers[b.index], ai, battle)
      check_score += Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("SleepTarget", 
                       old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Cuddle
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("InfatuateTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("AttractTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Smite, G-Max Goldrush
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("ConfuseTargetSide",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("ConfuseTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("ConfuseTargetSide",
                                                        "ConfuseTargetSideAddMoney")

#-------------------------------------------------------------------------------
# G-Max Stonesurge, G-Max Steelsurge
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("DamageTargetAddStealthRocksToFoeSide",
  proc { |score, move, user, ai, battle|
    inBattleIndices = battle.allSameSideBattlers(user.idxOpposingSide).map { |b| b.pokemonIndex }
    foe_reserves = []
    battle.pbParty(user.idxOpposingSide).each_with_index do |pkmn, idxParty|
      next if !pkmn || !pkmn.able? || inBattleIndices.include?(idxParty)
      if ai.trainer.medium_skill?
        next if pkmn.hasItem?(:HEAVYDUTYBOOTS)
        next if pkmn.hasAbility?(:MAGICGUARD)
      end
      foe_reserves.push(pkmn)
    end
    next score + (10 * foe_reserves.length)
  }
)
Battle::AI::Handlers::MoveEffectScore.copy("DamageTargetAddStealthRocksToFoeSide",
                                           "DamageTargetAddSteelsurgeToFoeSide")
										   
#-------------------------------------------------------------------------------
# G-Max Resonance
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("DamageTargetStartWeakenDamageAgainstUserSide",
  proc { |score, move, user, ai, battle|
    next score if user.pbOwnSide.effects[PBEffects::Reflect] > 0 &&
                  user.pbOwnSide.effects[PBEffects::LightScreen] > 0
    if ai.trainer.has_skill_flag?("HPAware") && battle.pbAbleNonActiveCount(user.idxOwnSide) == 0
      if user.hp <= user.totalhp / 2
        score -= (20 * (0.75 - (user.hp.to_f / user.totalhp))).to_i
      end
    end
    score += 5 if user.has_active_item?(:LIGHTCLAY)
    next score + 15
  }
)

#-------------------------------------------------------------------------------
# G-Max Vine Lash, G-Max Wildfire, G-Max Cannonade, G-Max Volcalith
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("StartVineLashOnFoeSide",
  proc { |score, move, user, target, ai, battle|
    case move.type
    when :GRASS then effect = PBEffects::VineLash
    when :FIRE  then effect = PBEffects::Wildfire
    when :WATER then effect = PBEffects::Cannonade
    when :ROCK  then effect = PBEffects::Volcalith
    end
    next score if user.battler.pbOpposingSide.effects[effect] > 0
    affected_foes = 0
    battle.allOtherSideBattlers(user.battler).each do |b|
      next if b.pbHasType?(move.type)
      affected_foes += 1
    end
    next score + (10 * affected_foes)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.copy("StartVineLashOnFoeSide",
                                                        "StartWildfireOnFoeSide",
                                                        "StartCannonadeOnFoeSide",
                                                        "StartVolcalithOnFoeSide")

#-------------------------------------------------------------------------------
# G-Max Gravitas
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DamageTargetStartGravity",
  proc { |score, move, user, target, ai, battle|
    next score if battle.field.effects[PBEffects::Gravity] > 0
    score += Battle::AI::Handlers::MoveEffectScore.trigger("StartGravity", 
               score, move, user, ai, battle)
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Chi Strike
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("UserSideCriticalBoost1",
  proc { |score, move, user, ai, battle|
    affected_allies = 0
    battle.allSameSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      next if !b.check_for_move { |m| m.damagingMove? }
      affected_allies += 1
      if ai.trainer.medium_skill?
        if b.item_active?
          if b.effects[PBEffects::FocusEnergy] >= 2 ||
             [:RAZORCLAW, :SCOPELENS].include?(b.item_id) ||
             (b.item_id == :LUCKYPUNCH && b.battler.isSpecies?(:CHANSEY)) ||
             ([:LEEK, :STICK].include?(b.item_id) &&
             (b.battler.isSpecies?(:FARFETCHD) || b.battler.isSpecies?(:SIRFETCHD)))
            score += 5
          end
        end
      end
      score += 5 if b.has_active_ability?(:SNIPER)
    end
    next score + (10 * affected_allies)
  }
)

#-------------------------------------------------------------------------------
# G-Max Meltdown
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DisableTargetSideUsingSameMoveConsecutively",
  proc { |score, move, user, target, ai, battle|
    affected_foes = 0
    battle.allOtherSideBattlers(user.battler).each do |b|
	  b = ai.battlers[b.index]
      next if b.has_active_item?(:MENTALHERB)
      affected_foes += 1
      if b.effects[PBEffects::ChoiceBand] ||
         b.has_active_item?([:CHOICEBAND, :CHOICESPECS, :CHOICESCARF]) ||
         b.has_active_ability?(:GORILLATACTICS)
        score += 5
      end
    end
    next score + (10 * affected_foes)
  }
)

#-------------------------------------------------------------------------------
# G-Max Terror
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("TrapTargetSideInBattle",
  proc { |score, move, user, target, ai, battle|
    next score if !battle.pbCanChooseNonActive?(target.index)
    affected_foes = 0
    battle.allOtherSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      next if !b.can_become_trapped?
      affected_foes += 1
      eor_damage = b.rough_end_of_round_damage
      next if eor_damage >= b.hp
      if b.effects[PBEffects::PerishSong] > 0 ||
         b.effects[PBEffects::Attract] >= 0 ||
         b.effects[PBEffects::Confusion] > 0 ||
         eor_damage > 0
        score += 5
      end
    end
    next score + (10 * affected_foes)
  }
)

#-------------------------------------------------------------------------------
# G-Max Centiferno, G-Max Sand Blast
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("BindTargetSideUserCanSwitch",
  proc { |score, move, user, target, ai, battle|
    old_score = score
    battle.allOtherSideBattlers(user.battler).each do |b|
      check_score = Battle::AI::Handlers::MoveEffectAgainstTargetScore.trigger("BindTarget", 
                      old_score, move, user, ai.battlers[b.index], ai, battle)
      score += check_score / battle.pbOpposingBattlerCount(user.battler)
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Sweetness
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("CureStatusConditionsUsersSide",
  proc { |score, move, user, ai, battle|
    battle.allSameSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      next if b.status == :NONE
      score += (b.wants_status_problem?(b.status)) ? -10 : 15
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Finale
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("HealUserSideOneSixthOfTotalHP",
  proc { |score, move, user, target, ai, battle|
    affected_allies = 0
    battle.allSameSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      next if !b.battler.canHeal?
      affected_allies += 1
      if ai.trainer.has_skill_flag?("HPAware")
        score += 5 * (b.totalhp - b.hp) / b.totalhp
      end
    end
    next score + (8 * affected_allies)
  }
)

#-------------------------------------------------------------------------------
# G-Max Replenish
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("RestoreUserSideConsumedBerries",
  proc { |score, move, user, target, ai, battle|
    affected_allies = 0
    battle.allSameSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      next if b.item_active? || !b.battler.recycleItem   
      next if !GameData::Item.get(b.battler.recycleItem).is_berry?
      affected_allies += 1
      item_preference = b.wants_item?(b.battler.recycleItem)
      no_item_preference = b.wants_item?(:NONE)
      score += (item_preference - no_item_preference) * 4
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Depletion
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("LowerPPOfTargetSideLastMoveBy2",
  proc { |score, move, user, target, ai, battle|
    battle.allOtherSideBattlers(user.battler).each do |b|
      b = ai.battlers[b.index]
      if user.faster_than?(b)
        next if !b.battler.lastRegularMoveUsed
        if b.battler.powerMoveIndex >= 0
          last_move = b.moves[b.battler.powerMoveIndex]
        else
          last_move = b.battler.pbGetMoveWithID(b.battler.lastRegularMoveUsed)
        end
        next score + 10 if last_move.pp <= 2
        next score + 5  if last_move.pp <= 3
        next score - 5  if last_move.pp > 6
      end
    end
    next score
  }
)

#-------------------------------------------------------------------------------
# G-Max Wind Rage
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("RemoveSideEffectsAndTerrain",
  proc { |score, move, user, target, ai, battle|
    score += 10 if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Reflect] > 1 ||
                   target.pbOwnSide.effects[PBEffects::LightScreen] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Mist] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Safeguard] > 1
    if target.can_switch_lax?
      score -= 15 if target.pbOwnSide.effects[PBEffects::Spikes] > 0 ||
                     target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0 ||
                     target.pbOwnSide.effects[PBEffects::StealthRock] ||
                     target.pbOwnSide.effects[PBEffects::StickyWeb]
    end
    if user.can_switch_lax?
      score += 15 if target.pbOpposingSide.effects[PBEffects::Spikes] > 0 ||
                     target.pbOpposingSide.effects[PBEffects::ToxicSpikes] > 0 ||
                     target.pbOpposingSide.effects[PBEffects::StealthRock] ||
                     target.pbOpposingSide.effects[PBEffects::StickyWeb]
    end
    if battle.field.terrain != :None
      score -= ai.get_score_for_terrain(battle.field.terrain, user)
    end
    next score
  }
)