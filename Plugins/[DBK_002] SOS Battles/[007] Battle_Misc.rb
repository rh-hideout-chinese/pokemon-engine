#===============================================================================
# Flags wild Pokemon that took Super Effective damage to increase SOS odds.
#===============================================================================
class Battle::Move
  alias sos_pbEffectivenessMessage pbEffectivenessMessage
  def pbEffectivenessMessage(user, target, numTargets = 1)
    sos_pbEffectivenessMessage(user, target, numTargets)
    if target.wild?
      return if self.is_a?(Battle::Move::FixedDamageMove)
      return if target.damageState.disguise || target.damageState.iceFace
      if Effectiveness.super_effective?(target.damageState.typeMod)
        target.tookSuperEffectiveDamage = true
      end
    end
  end
end


#===============================================================================
# Battle::AI
#===============================================================================
class Battle::AI
  #-----------------------------------------------------------------------------
  # Used to create a new AI Battler object for Pokemon called via SOS.
  #-----------------------------------------------------------------------------
  def create_new_ai_battler(idxBattler)
    @battlers[idxBattler] = AIBattler.new(self, idxBattler)
  end
  
  #-----------------------------------------------------------------------------
  # Used to create a new AI Trainer object for new trainers added to battle.
  #-----------------------------------------------------------------------------
  def create_new_ai_trainer(idxTrainer)
    trainer = @battle.opponent[idxTrainer]
    @trainers[1][idxTrainer] = AITrainer.new(self, 1, idxTrainer, trainer)
  end
end


#===============================================================================
# Battle::AI::Trainer
#===============================================================================
class Battle::AI::AITrainer
  #-----------------------------------------------------------------------------
  # Aliased to give Totem Pokemon better AI than normal wild Pokemon.
  #-----------------------------------------------------------------------------
  alias totem_set_up_skill set_up_skill
  def set_up_skill
    totem_set_up_skill
    if !@trainer && @skill == 0
      wild_battler = @ai.battle.battlers[@side]
      @skill = 32 if wild_battler.totemBattler
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so that wild Pokemon consider their moves vs rival species.
  #-----------------------------------------------------------------------------
  alias rival_set_up_skill_flags  set_up_skill_flags 
  def set_up_skill_flags
    rival_set_up_skill_flags
    if !@trainer && @skill == 0
      wild_battler = @ai.battle.battlers[@side]
      sp_data = wild_battler.pokemon.species_data
      @skill_flags.push("ScoreMoves") if !sp_data.rival_species.empty?
    end
  end
end


#===============================================================================
# Ensures wild Pokemon prioritize attacking rival species, if any.
#===============================================================================
Battle::AI::Handlers::GeneralMoveAgainstTargetScore.add(:rival_target,
  proc { |score, move, user, target, ai, battle|
    if user.wild? && move.damagingMove? && score > 0 && !battle.totemBattle
      user_data = user.battler.pokemon.species_data
      targ_data = target.battler.displayPokemon.species_data
      targ_id = (user_data.has_flag?("AllRivalForms")) ? targ_data.species : targ_data.id
      if !user_data.rival_species.empty? && user_data.rival_species.include?(targ_id)
        old_score = score
        score += 1000
        PBDebug.log_score_change(score - old_score, "prefer attacking a Pokémon of a rival species")
      end
    end
    next score
  }
)