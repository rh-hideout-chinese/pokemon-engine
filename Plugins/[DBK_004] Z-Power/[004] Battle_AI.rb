#===============================================================================
# Battle::AI edits.
#===============================================================================
class Battle::AI
  #-----------------------------------------------------------------------------
  # Aliased to calculate move scores for all potential Z-Moves.
  #-----------------------------------------------------------------------------
  alias zmove_pbGetMovesToScore pbGetMovesToScore
  def pbGetMovesToScore
    moves_to_score = zmove_pbGetMovesToScore
    if @battle.pbCanZMove?(@user.index)
      item_data = GameData::Item.get(@user.battler.item)
      pkmn = @user.battler.visiblePokemon
      @user.battler.eachMoveWithIndex do |move, i|
        newID = move.get_compatible_zmove(item_data, pkmn)
        if newID
          zmove = move.make_zmove(newID, @battle)
          zmove.pp = [1, @user.battler.moves[i].pp].min
          zmove.total_pp = 1
          moves_to_score.push(zmove)
        else
          moves_to_score.push(nil)
        end
      end
    end
    return moves_to_score
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to allow the AI to register a Z-Move.
  #-----------------------------------------------------------------------------
  alias zmove_pbRegisterEnemySpecialActionFromMove pbRegisterEnemySpecialActionFromMove
  def pbRegisterEnemySpecialActionFromMove(user, move_sel)
    if move_sel.zMove?
      @battle.pbRegisterZMove(user.index)
      user.display_zmoves
      return
    end
    zmove_pbRegisterEnemySpecialActionFromMove(user, move_sel)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to allow the AI to consider Z-Healing effects when switching out.
  #-----------------------------------------------------------------------------
  alias zmove_rate_replacement_pokemon rate_replacement_pokemon
  def rate_replacement_pokemon(idxBattler, pkmn, score)
    score = zmove_rate_replacement_pokemon(idxBattler, pkmn, score)
    position = @battle.positions[idxBattler]
    if position.effects[PBEffects::ZHealing]
      amt = pkmn.totalhp - pkmn.hp
      score += 20 * amt / pkmn.totalhp
    end
    return score
  end
end

#===============================================================================
# Copycat
#===============================================================================
# Considers whether the last used move was a Z-Move.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.add("UseLastMoveUsed",
  proc { |move, user, ai, battle|
    next true if !battle.lastMoveUsed || !GameData::Move.exists?(battle.lastMoveUsed)
    next true if GameData::Move.get(battle.lastMoveUsed).zMove?
    next move.move.moveBlacklist.include?(GameData::Move.get(battle.lastMoveUsed).function_code)
  }
)

#===============================================================================
# Z-Move score handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Extreme Evoboost.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureCheck.copy("RaiseUserMainStats1",
											"RaiseUserMainStats2")
Battle::AI::Handlers::MoveEffectScore.copy("RaiseUserMainStats1",
										   "RaiseUserMainStats2")

#-------------------------------------------------------------------------------
# Genesis Supernova.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.copy("StartPsychicTerrain",
                                           "DamageTargetStartPsychicTerrain")

#-------------------------------------------------------------------------------
# Splintered Stormshards.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveEffectScore.copy("RemoveTerrain",
                                           "DamageTargetRemoveTerrain")

#-------------------------------------------------------------------------------
# Guardian of Alola.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveBasePower.add("FixedDamageThreeQuartersTargetHP",
  proc { |power, move, user, target, ai, battle|
    next move.move.pbFixedDamage(user.battler, target.battler)
  }
)

#-------------------------------------------------------------------------------
# Z-Powered status moves.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::GeneralMoveScore.add(:zpower_status_effects,
  proc { |score, move, user, ai, battle|
    next score if !(move.move.status_zmove && move.move.has_zpower?)
    old_score = score
    effect, stage = move.move.get_zpower_effect
    effect = "HealUser" if move.id == :CURSE && user.has_type?(:GHOST)
    case effect
    #---------------------------------------------------------------------------
    # Z-Powered effects that fully restores the user's HP.
    when "HealUser"
      if ai.trainer.has_skill_flag?("HPAware")
        if user.battler.canHeal?
          score = Battle::AI::MOVE_BASE_SCORE
          score += 30 * (user.totalhp - user.hp) / user.totalhp
          PBDebug.log_score_change(score - old_score, "user aware that Z-Power will heal its HP")
        else
          score -= 10
        end
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that fully restores the HP of an incoming Pokemon.
    when "HealSwitch"
      if battle.pbCanChooseNonActive?(user.index)
        if ai.trainer.medium_skill?
          need_healing = false
          battle.eachInTeamFromBattlerIndex(user.index) do |pkmn, party_index|
            next if pkmn.hp >= pkmn.totalhp * 0.75
            need_healing = true
            break
          end
          effect_score = (need_healing) ? Battle::AI::MOVE_BASE_SCORE : Battle::AI::MOVE_USELESS_SCORE
        end
        if ai.trainer.high_skill?
          reserves = battle.pbAbleNonActiveCount(user.idxOwnSide)
          foes     = battle.pbAbleNonActiveCount(user.idxOpposingSide)
          if reserves > 0 && foes == 0
            effect_score += 20
          end
        end
        if effect_score > Battle::AI::MOVE_USELESS_SCORE
          score += effect_score / 2 
          PBDebug.log_score_change(score - old_score, "user aware that Z-Power will heal an incoming party member")
        end
      else
        score -= 10
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that boost the user's critical hit ratio.
    when "CriticalHit"
      if !user.check_for_move { |m| m.damagingMove? } || 
         user.effects[PBEffects::FocusEnergy] >= 4
        score -= 10
      else
        score += 15
        if ai.trainer.medium_skill?
          if user.item_active?
            if [:RAZORCLAW, :SCOPELENS].include?(user.item_id) ||
               (user.item_id == :LUCKYPUNCH && user.battler.isSpecies?(:CHANSEY)) ||
               ([:LEEK, :STICK].include?(user.item_id) &&
               (user.battler.isSpecies?(:FARFETCHD) || user.battler.isSpecies?(:SIRFETCHD)))
              score += 10
            end
          end
          score += 10 if user.has_active_ability?(:SNIPER)
        end
        PBDebug.log_score_change(score - old_score, "user aware that Z-Power will boost critical hit rate")
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that resets the user's lowered stats.
    when "ResetStats"
      stats = []
      GameData::Stat.each_battle do |s|
        next if user.stages[s.id] >= 0
        stats.push(s.id)
        stats.push(user.stages[s.id])
      end
      if stats.length > 0
        effect_score = ai.get_score_for_target_stat_raise(score, user, stats, false, true, true) 
        if effect_score > score
          score += effect_score - score
          PBDebug.log_score_change(score - old_score, "user aware that Z-Power will reset lowered stat stages")
        else
          score -= 10
        end
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that cause misdirection.
    when "FollowMe"
      if user.battler.allAllies.length == 0
        score -= 10
      elsif ai.trainer.has_skill_flag?("HPAware") && user.hp > user.totalhp * 2 / 3
        ai.each_ally(user.index) do |b, i|
          score += 10 if b.hp <= b.totalhp / 3
        end
        PBDebug.log_score_change(score - old_score, "user aware that Z-Power will redirect attacks to itself")
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that raise the user's stats.
    else
      if stage
        stats = []
        stage = stage.to_i
        case effect
        when "AllStats"
          GameData::Stat.each_main_battle { |s| stats.push(s.id, stage) }
        else
          stat = GameData::Stat.try_get(effect.to_sym)
          stats.push(stat.id, stage) if stat
        end
        if stats.length > 0
          effect_score = ai.get_score_for_target_stat_raise(score, user, stats, false, true, true)
          if effect_score > score
            score += effect_score - score 
            PBDebug.log_score_change(score - old_score, "user aware that Z-Power will boost a useful stat")
          else
            score -= 10
          end
        end
      end
    end
    next score
  }
)