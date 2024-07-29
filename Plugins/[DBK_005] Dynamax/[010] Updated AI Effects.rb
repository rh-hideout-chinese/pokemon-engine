################################################################################
#
# Updates to the AI of existing moves.
#
################################################################################

#===============================================================================
# Rapid Spin
#===============================================================================
# Also considers the effects of G-Max Steelsurge.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("RemoveUserBindingAndEntryHazards",
  proc { |score, move, user, ai, battle|
    if Settings::MECHANICS_GENERATION >= 8
      score = Battle::AI::Handlers.apply_move_effect_score("RaiseUserSpeed1",
         score, move, user, ai, battle)
    end
    score += 10 if user.effects[PBEffects::Trapping] > 0
    score += 15 if user.effects[PBEffects::LeechSeed] >= 0
    if battle.pbAbleNonActiveCount(user.idxOwnSide) > 0
      score += 15 if user.pbOwnSide.effects[PBEffects::Spikes] > 0
      score += 15 if user.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
      score += 20 if user.pbOwnSide.effects[PBEffects::StealthRock]
      score += 20 if user.pbOwnSide.effects[PBEffects::Steelsurge]
      score += 15 if user.pbOwnSide.effects[PBEffects::StickyWeb]
    end
    next score
  }
)

#===============================================================================
# Defog
#===============================================================================
# Also considers the effects of G-Max Steelsurge.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("LowerTargetEvasion1RemoveSideEffects",
  proc { |move, user, target, ai, battle|
    target_side = target.pbOwnSide
    target_opposing_side = target.pbOpposingSide
    next false if target_side.effects[PBEffects::AuroraVeil] > 0 ||
                  target_side.effects[PBEffects::LightScreen] > 0 ||
                  target_side.effects[PBEffects::Reflect] > 0 ||
                  target_side.effects[PBEffects::Mist] > 0 ||
                  target_side.effects[PBEffects::Safeguard] > 0
    next false if target_side.effects[PBEffects::StealthRock] ||
                  target_side.effects[PBEffects::Steelsurge] ||
                  target_side.effects[PBEffects::Spikes] > 0 ||
                  target_side.effects[PBEffects::ToxicSpikes] > 0 ||
                  target_side.effects[PBEffects::StickyWeb]
    next false if Settings::MECHANICS_GENERATION >= 6 &&
                  (target_opposing_side.effects[PBEffects::StealthRock] ||
                  target_opposing_side.effects[PBEffects::Steelsurge] ||
                  target_opposing_side.effects[PBEffects::Spikes] > 0 ||
                  target_opposing_side.effects[PBEffects::ToxicSpikes] > 0 ||
                  target_opposing_side.effects[PBEffects::StickyWeb])
    next false if Settings::MECHANICS_GENERATION >= 8 && battle.field.terrain != :None
    next move.statusMove? &&
         !target.battler.pbCanLowerStatStage?(move.move.statDown[0], user.battler, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("LowerTargetEvasion1RemoveSideEffects",
  proc { |score, move, user, target, ai, battle|
    next Battle::AI::MOVE_USELESS_SCORE if !target.opposes?(user)
    score = ai.get_score_for_target_stat_drop(score, target, move.move.statDown)
    score += 10 if target.pbOwnSide.effects[PBEffects::AuroraVeil] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Reflect] > 1 ||
                   target.pbOwnSide.effects[PBEffects::LightScreen] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Mist] > 1 ||
                   target.pbOwnSide.effects[PBEffects::Safeguard] > 1
    if target.can_switch_lax?
      score -= 15 if target.pbOwnSide.effects[PBEffects::Spikes] > 0 ||
                     target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0 ||
                     target.pbOwnSide.effects[PBEffects::StealthRock] ||
                     target.pbOwnSide.effects[PBEffects::Steelsurge] ||
                     target.pbOwnSide.effects[PBEffects::StickyWeb]
    end
    if user.can_switch_lax? && Settings::MECHANICS_GENERATION >= 6
      score += 15 if target.pbOpposingSide.effects[PBEffects::Spikes] > 0 ||
                     target.pbOpposingSide.effects[PBEffects::ToxicSpikes] > 0 ||
                     target.pbOpposingSide.effects[PBEffects::StealthRock] ||
                     target.pbOpposingSide.effects[PBEffects::Steelsurge] ||
                     target.pbOpposingSide.effects[PBEffects::StickyWeb]
    end
    if Settings::MECHANICS_GENERATION >= 8 && battle.field.terrain != :None
      score -= ai.get_score_for_terrain(battle.field.terrain, user)
    end
    next score
  }
)

#===============================================================================
# Court Change
#===============================================================================
# Also considers the effects of certain G-Max moves.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.add("SwapSideEffects",
  proc { |score, move, user, ai, battle|
    if ai.trainer.medium_skill?
      good_effects = [:AuroraVeil, :LightScreen, :Mist, :Rainbow, :Reflect,
                      :Safeguard, :SeaOfFire, :Swamp, :Tailwind].map! { |e| PBEffects.const_get(e) }
      bad_effects = [:Spikes, :StealthRock, :StickyWeb, :ToxicSpikes, :Steelsurge, 
                     :Cannonade, :VineLash, :Volcalith, :Wildfire].map! { |e| PBEffects.const_get(e) }
      bad_effects.each do |e|
        score += 10 if ![0, false, nil].include?(user.pbOwnSide.effects[e])
        score -= 10 if ![0, 1, false, nil].include?(user.pbOpposingSide.effects[e])
      end
      if ai.trainer.high_skill?
        good_effects.each do |e|
          score += 10 if ![0, 1, false, nil].include?(user.pbOpposingSide.effects[e])
          score -= 10 if ![0, false, nil].include?(user.pbOwnSide.effects[e])
        end
      end
    end
    next score
  }
)

#===============================================================================
# Low Kick, Grass Knot
#===============================================================================
# Considers Dynamax immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PowerHigherWithTargetWeight",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)

#===============================================================================
# Heavy Slam, Heat Crash
#===============================================================================
# Considers Dynamax immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("PowerHigherWithUserHeavierThanTarget",
  proc { |move, user, target, ai, battle|
    next move.move.pbFailsAgainstTarget?(user.battler, target.battler, false)
  }
)

#===============================================================================
# Disable
#===============================================================================
# Considers Dynamax immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("DisableTargetLastMoveUsed",
  proc { |move, user, target, ai, battle|
    next true if target.battler.dynamax?
    next true if target.effects[PBEffects::Disable] > 0 || !target.battler.lastRegularMoveUsed
    next true if move.move.pbMoveFailedAromaVeil?(user.battler, target.battler, false)
    next !target.check_for_move { |m| m.id == target.battler.lastRegularMoveUsed }
  }
)

#===============================================================================
# Torment
#===============================================================================
# Considers Dynamax immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("DisableTargetUsingSameMoveConsecutively",
  proc { |move, user, target, ai, battle|
    next true if target.battler.dynamax?
    next true if target.effects[PBEffects::Torment]
    next true if move.move.pbMoveFailedAromaVeil?(user.battler, target.battler, false)
    next false
  }
)

#===============================================================================
# Me First
#===============================================================================
# Considers whether the target is Dynamaxed.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("UseMoveTargetIsAboutToUse",
  proc { |move, user, target, ai, battle|
    next true if target.battler.dynamax?
    next !target.check_for_move { |m| m.damagingMove? && !move.move.moveBlacklist.include?(m.function_code) }
  }
)

#===============================================================================
# Instruct
#===============================================================================
# Considers Dynamax immunity.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("TargetUsesItsLastUsedMoveAgain",
  proc { |move, user, target, ai, battle|
    next true if target.battler.dynamax?
    next target.battler.usingMultiTurnAttack?
  }
)

#===============================================================================
# Dragon Tail, Circle Throw
#===============================================================================
# Considers Dynamax immunity to switch-out effect.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("SwitchOutTargetDamagingMove",
  proc { |score, move, user, target, ai, battle|
    next score if target.wild?
    next score if target.battler.dynamax?
    next score if !battle.moldBreaker && target.has_active_ability?(:SUCTIONCUPS)
    next score if target.effects[PBEffects::Ingrain]
    can_switch = false
    battle.eachInTeamFromBattlerIndex(target.index) do |_pkmn, i|
      can_switch = battle.pbCanSwitchIn?(target.index, i)
      break if can_switch
    end
    next score if !can_switch
    next score if target.effects[PBEffects::Substitute] > 0
    score -= 20 if target.effects[PBEffects::PerishSong] > 0
    if target.stages.any? { |key, val| val >= 2 }
      score += 15
    elsif target.stages.any? { |key, val| val < 0 }
      score -= 15
    end
    eor_damage = target.rough_end_of_round_damage
    score -= 15 if eor_damage > 0
    score += 15 if eor_damage < 0
    score += 10 if target.pbOwnSide.effects[PBEffects::Spikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::ToxicSpikes] > 0
    score += 10 if target.pbOwnSide.effects[PBEffects::StealthRock]
    next score
  }
)

#===============================================================================
# Behemoth Blade, Behemoth Bash, Dynamax Cannon
#===============================================================================
# Considers whether the target is Dynamaxed.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("DoubleDamageOnDynamaxTargets",
  proc { |score, move, user, target, ai, battle|
    next score if !target.battler.dynamax? || target.battler.emax?
    next score + 60
  }
)