#===============================================================================
# Additions to the Battle::AI class.
#===============================================================================
class Battle::AI
  #-----------------------------------------------------------------------------
  # Registering Dynamax.
  #-----------------------------------------------------------------------------
  alias dynamax_pbRegisterEnemySpecialAction pbRegisterEnemySpecialAction
  def pbRegisterEnemySpecialAction(idxBattler)
    dynamax_pbRegisterEnemySpecialAction(idxBattler)
    @battle.pbRegisterDynamax(idxBattler) if pbEnemyShouldDynamax?
  end
  
  def pbEnemyShouldDynamax?
    return false if !@battle.pbCanDynamax?(@user.index)
    return true if @user.wild?
    if @trainer.has_skill_flag?("ReserveLastPokemon")
      if @battle.pbTeamAbleNonActiveCount(@user.index) == 0
        PBDebug.log_ai("#{@user.name} will Dynamax")
        return true
      end
    elsif wants_to_dynamax?
      PBDebug.log_ai("#{@user.name} will Dynamax")
      return true
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Determines if the AI should Dynamax the current battler, or save it.
  #-----------------------------------------------------------------------------
  def wants_to_dynamax?
    score = @user.get_total_dynamax_score
    return true if score == 0 && @battle.pbAbleCount(@user.index) == 1
    highest_score = 0
    if @trainer.medium_skill?
      party = @battle.pbParty(@user.index)
      party.each_with_index do |pkmn, i|
        next if !@battle.pbIsOwner?(@user.index, i)
        next if @battle.pbFindBattler(i, @user.index)
        next if pkmn.fainted? || pkmn.dynamax? || !pkmn.dynamax_able?
        next if pkmn.item&.is_mega_stone? && pkmn.hasMegaForm?
        next if defined?(is_zcrystal?) && pkmn.item&.is_zcrystal?
        party_score = get_party_dynamax_score(pkmn)
        PBDebug.log_ai("#{@user.name} is comparing Dynamax score with party member #{pkmn.name} (score: #{party_score})...")
        highest_score = party_score if party_score > highest_score
      end  
    end
    if score <= highest_score
      PBDebug.log_ai("#{@user.name} will not Dynamax")
      return false
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Determines the value of Dynamax for other party members.
  #-----------------------------------------------------------------------------
  def get_party_dynamax_score(pkmn)
    score = 0
    move_types = []
    pkmn.moves.each do |move|
      next if move.pp == 0
      next if move.status_move?
      next if move_types.include?(move.type)
      move_types.push(move.type)
      score += 5
    end
    if pkmn.moves.any? { |m| m.status_move? }
      each_foe_battler(@user.side) do |b, i|
        next if !b.check_for_move { |m| m.dynamaxMove? }
        score += 5
        break
      end
    end
    if pkmn.hasGigantamaxForm? && pkmn.gmax_factor?
      form = pkmn.getGmaxForm
      gmax = GameData::Species.get_species_form(pkmn.species, form).gmax_move
      type = GameData::Move.get(gmax).type
      score += 5 if pkmn.moves.any? { |m| m.type == type }
    end
    score += 10 if @user.opponent_side_has_function?(*dynamax_immunity_functions)
    score -= 10 if @user.opponent_side_has_function?("DoubleDamageOnDynamaxTargets")
    if pkmn.ability != :KLUTZ && 
       @battle.field.effects[PBEffects::MagicRoom] == 0
      score -= 5 if [:CHOICEBAND, :CHOICESPECS, :CHOICESCARF, :EJECTBUTTON].include?(pkmn.item_id)
    end
    if !@battle.pbCheckGlobalAbility(:NEUTRALIZINGGAS)
      score -= 5 if [:WIMPOUT, :EMERGENCYEXIT].include?(pkmn.ability_id)
    end
    baseHP = pkmn.baseStats[:HP]
    dynamaxHP = (baseHP > 1) ? (pkmn.hp * pkmn.dynamax_calc).ceil : 1
    if dynamaxHP > 1
      score += (dynamaxHP / 10).floor
    else
      score -= 10
    end
  end
  
  #-----------------------------------------------------------------------------
  # Returns the function codes of all moves with effects that Dynamax is immune to.
  #-----------------------------------------------------------------------------
  def dynamax_immunity_functions
    return [
      "OHKO",
      "OHKOIce",
      "OHKOHitsUndergroundTarget",
      "FlinchTarget",
      "BurnFlinchTarget",
      "FreezeFlinchTarget",
      "ParalyzeFlinchTarget",
      "HitTwoTimesFlinchTarget",
      "TwoTurnAttackFlinchTarget",
      "FlinchTargetFailsIfUserNotAsleep",
      "FlinchTargetFailsIfNotUserFirstTurn",
      "AttackerFaintsIfUserFaints",
      "UserTargetSwapAbilities",
      "SetTargetAbilityToUserAbility",
      "DisableTargetLastMoveUsed",
      "DisableTargetUsingDifferentMove",
      "DisableTargetUsingSameMoveConsecutively",
      "TargetUsesItsLastUsedMoveAgain",
      "SwitchOutTargetStatusMove",
      "SwitchOutTargetDamagingMove",
      "PowerHigherWithTargetWeight", 
      "PowerHigherWithUserHeavierThanTarget",
      "TwoTurnAttackInvulnerableInSkyTargetCannotAct"
    ]
  end

  #-----------------------------------------------------------------------------
  # Aliased to score the user's Dynamax moves if Dynamax will be used.
  #-----------------------------------------------------------------------------
  alias dynamax_pbGetMovesToScore pbGetMovesToScore
  def pbGetMovesToScore
    if @battle.pbRegisteredDynamax?(@user.battler.index)
      @user.battler.display_dynamax_moves
    end
    return dynamax_pbGetMovesToScore
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to allow the AI to consider hazard damage from G-Max Steelsurge.
  #-----------------------------------------------------------------------------
  alias dynamax_calculate_entry_hazard_damage calculate_entry_hazard_damage
  def calculate_entry_hazard_damage(pkmn, side)
    ret = dynamax_calculate_entry_hazard_damage(pkmn, side)
    if !(pkmn.hasAbility?(:MAGICGUARD) || pkmn.hasItem?(:HEAVYDUTYBOOTS))
      if @battle.sides[side].effects[PBEffects::Steelsurge] && GameData::Type.exists?(:STEEL)
        pkmn_types = pkmn.types
        eff = Effectiveness.calculate(:STEEL, *pkmn_types)
        ret += pkmn.totalhp * eff / 8 if !Effectiveness.ineffective?(eff)
      end
    end
    return ret
  end
end

#===============================================================================
# Additions to the Battle::AI::AIBattler class.
#===============================================================================
class Battle::AI::AIBattler
  #-----------------------------------------------------------------------------
  # Calculates the total score for Dynamax.
  #-----------------------------------------------------------------------------
  def get_total_dynamax_score
    score = 0
    maxtype = (@battler.hasEmax?) ? "Eternamax" : (@battler.hasGmax?) ? "Gigantamax" : "Dynamax"
    PBDebug.log_ai("#{self.name} is considering entering #{maxtype} form...")
    if can_attack? && check_for_move { |m| m.damagingMove? }
      score = get_offensive_dynamax_score(score)
    end
    if @ai.trainer.high_skill?
      score = get_defensive_dynamax_score(score)
    end
    return score
  end
  
  #-----------------------------------------------------------------------------
  # Determines the offensive value of Dynamax.
  #-----------------------------------------------------------------------------
  def get_offensive_dynamax_score(score)
    old_score = score
    move_types = []
    @battler.eachMove do |move|
      next if move.pp == 0
      next if move.statusMove?
      next if move_types.include?(move.type)
      move_types.push(move.type)
      score += 5
    end
    PBDebug.log_score_change(score - old_score, "has damaging moves to convert into Max Moves")
    old_score = score
    if @battler.hasGmax?
      form = @battler.pokemon.getGmaxForm
      gmax = GameData::Species.get_species_form(@battler.species, form).gmax_move
      type = GameData::Move.get(gmax).type
      score += 5 if check_for_move { |m| m.pbCalcType(@battler) == type }
    end
    PBDebug.log_score_change(score - old_score, "has a damaging move to convert into a G-Max Move")
    old_score = score
    score += 5  if self.effects[PBEffects::Torment]
    score += 5  if self.effects[PBEffects::Encore] > 0
    score += 5  if self.effects[PBEffects::Disable] > 0
    PBDebug.log_score_change(score - old_score, "Dynamax would remove effects disabling moves")
    old_score = score	
    @ai.each_foe_battler(@side) do |b, i|
      next if !b.has_active_item?(:REDCARD)
      score += 5
      break
    end
    score += 5 if opponent_side_has_ability?([:CURSEDBODY, :WANDERINGSPIRIT])
    PBDebug.log_score_change(score - old_score, "attacking while Dynamaxed would ignore a foe's item/ability")
    if self.effects[PBEffects::ChoiceBand]
      old_score = score
      score += 5 if self.effects[PBEffects::Torment]
      score += 5 if self.effects[PBEffects::Encore] > 0
      score += 5 if self.effects[PBEffects::Disable] > 0
      move = @battler.pbGetMoveWithID(self.effects[PBEffects::ChoiceBand])
      if move.statusMove? || move.pp == 0
        score += 10
      else
        move_type = move.pbCalcType(@battler)
        @ai.each_foe_battler(@side) do |b, i|
        if has_active_item?(:CHOICESCARF)
          foeSpd = b.pbSpeed
          selfSpd = @battler.pbSpeed
          if selfSpd > foeSpd
            oldSpd = ((selfSpd * 2) / 4).floor
            score -= 5 if foeSpd > oldSpd
          end
        end
          if !has_mold_breaker? && @ai.pokemon_can_absorb_move?(b, move, move_type)
            score += 10
          else
            effectiveness = b.effectiveness_of_type_against_battler(move_type, self, move)
            if Effectiveness.super_effective?(effectiveness)
              score -= 10
            elsif Effectiveness.not_very_effective?(effectiveness)
              score += 5
            elsif Effectiveness.ineffective?(effectiveness)
              score += 10
            end
          end
        end
      end
      PBDebug.log_score_change(score - old_score, "Dynamax preference over Choiced move")
    end
    return score
  end
  
  #-----------------------------------------------------------------------------
  # Determines the defensive value of Dynamax.
  #-----------------------------------------------------------------------------
  def get_defensive_dynamax_score(score)
    old_score = score
    score += 10 if opponent_side_has_function?(*@ai.dynamax_immunity_functions)
    score -= 10 if opponent_side_has_function?("DoubleDamageOnDynamaxTargets")
    PBDebug.log_score_change(score - old_score, "Dynamax defensive utility against a foe's moves")
    if check_for_move { |m| m.statusMove? }
      @ai.each_foe_battler(@side) do |b, i|
        next if !b.check_for_move { |m| m.dynamaxMove? }
        score += 5
        PBDebug.log_score_change(5, "foe has Max Moves and user can Max Guard")
        break
      end
    end
    old_score = score
    score -= 5  if has_active_item?(:EJECTBUTTON)
    score -= 5  if has_active_ability?([:WIMPOUT, :EMERGENCYEXIT])
    score -= 10 if self.effects[PBEffects::Substitute] > 0
    score -= 20 if self.effects[PBEffects::PerishSong] > 0
    PBDebug.log_score_change(score - old_score, "has an item/ability/effect that could make Dynamaxing wasteful")
    old_score = score
    baseHP = @battler.pokemon.baseStats[:HP]
    dynamaxHP = (baseHP > 1) ? (@battler.hp * @battler.dynamax_calc).ceil : 1
    if dynamaxHP > 1
      score += (dynamaxHP / 10).floor
    else
      score -= 10
    end
    PBDebug.log_score_change(score - old_score, "benefit of additional HP gained from Dynamax")
    return score
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to consider end of round damage from certain G-Max move effects.
  #-----------------------------------------------------------------------------
  alias dynamax_rough_end_of_round_damage rough_end_of_round_damage
  def rough_end_of_round_damage
    ret = dynamax_rough_end_of_round_damage
    { :WATER => PBEffects::Cannonade,
      :GRASS => PBEffects::VineLash,
      :ROCK  => PBEffects::Volcalith,
      :FIRE  => PBEffects::Wildfire
    }.each do |type, effect|
      if @ai.battle.sides[@side].effects[effect] > 1 &&
         battler.takesIndirectDamage? && !has_type?(type)
        ret += [self.totalhp / 6, 1].max
      end
    end
    return ret
  end
end

#===============================================================================
# Don't bother switching if the battler has more than 1 remaining turn of Dynamax.
#===============================================================================
Battle::AI::Handlers::ShouldNotSwitch.add(:battler_is_dynamaxed,
  proc { |battler, reserves, ai, battle|
    if battler.battler.dynamax? && battler.effects[PBEffects::Dynamax] > 1
      PBDebug.log_ai("#{battler.name} won't switch after all because doing so would waste Dynamax turns")
      next true
    end
    next false
  }
)