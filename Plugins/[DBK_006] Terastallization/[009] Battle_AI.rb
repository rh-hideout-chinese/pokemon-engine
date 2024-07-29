#===============================================================================
# Additions to the Battle::AI class.
#===============================================================================
class Battle::AI
  #-----------------------------------------------------------------------------
  # Utility for checking if a Pokemon has an ability/item that boosts type damage.
  #-----------------------------------------------------------------------------
  TERA_TYPE_DAMAGE_BOOSTERS = {
    :BUG      => {:abils => [:SWARM],
                  :items => [:SILVERPOWDER, :INSECTPLATE]},
    :DARK     => {:abils => [:DARKAURA], 
                  :items => [:BLACKGLASSES, :DREADPLATE]},
    :DRAGON   => {:abils => [:DRAGONSMAW], 
                  :items => [:DRAGONFANG, :DRACOPLATE]},
    :ELECTRIC => {:abils => [:TRANSISTOR, :ELECTROMORPHOSIS], 
                  :items => [:MAGNET, :ZAPPLATE]},
    :FAIRY    => {:abils => [:FAIRYAURA], 
                  :items => [:FAIRYFEATHER, :PIXIEPLATE]},
    :FIGHTING => {:abils => [],
                  :items => [:BLACKBELT, :FISTPLATE]},
    :FIRE     => {:abils => [:BLAZE, :FLASHFIRE], 
                  :items => [:CHARCOAL, :FLAMEPLATE]},
    :FLYING   => {:abils => [],
                  :items => [:SHARPBEAK, :SKYPLATE]},
    :GHOST    => {:abils => [], 
                  :items => [:SPELLTAG, :SPOOKYPLATE]},
    :GRASS    => {:abils => [:OVERGROW], 
                  :items => [:MIRACLESEED, :MEADOWPLATE, :ROSEINCENSE]},
    :GROUND   => {:abils => [],
                  :items => [:SOFTSAND, :EARTHPLATE]},
    :ICE      => {:abils => [],
                  :items => [:NEVERMELTICE, :ICICLEPLATE]},
    :NORMAL   => {:abils => [],
                  :items => [:SILKSCARF]},
    :POISON   => {:abils => [],
                  :items => [:POISONBARB, :TOXICPLATE]},
    :PSYCHIC  => {:abils => [],
                  :items => [:TWISTEDSPOON, :MINDPLATE, :ODDINCENSE]},
    :ROCK     => {:abils => [:ROCKYPAYLOAD],
                  :items => [:HARDSTONE, :STONEPLATE, :ROCKINCENSE]},
    :STEEL    => {:abils => [:STEELWORKER, :STEELYSPIRIT],
                  :items => [:METALCOAT, :IRONPLATE]},
    :WATER    => {:abils => [:WATERBUBBLE],
                  :items => [:MYSTICWATER, :SPLASHPLATE, :SEAINCENSE, :WAVEINCENSE]},
    :STELLAR  => {:abils => [],
                  :items => []}
  }
  
  #-----------------------------------------------------------------------------
  # Registering Terastallization.
  #-----------------------------------------------------------------------------
  alias tera_pbRegisterEnemySpecialAction pbRegisterEnemySpecialAction
  def pbRegisterEnemySpecialAction(idxBattler)
    tera_pbRegisterEnemySpecialAction(idxBattler)
    @battle.pbRegisterTerastallize(idxBattler) if pbEnemyShouldTerastallize?
  end
  
  def pbEnemyShouldTerastallize?
    return false if !@battle.pbCanTerastallize?(@user.index)
    return true if @user.wild?
    if @trainer.has_skill_flag?("ReserveLastPokemon")
      if @battle.pbTeamAbleNonActiveCount(@user.index) == 0
        PBDebug.log_ai("#{@user.name} will Terastallize")
        return true
      end
    elsif wants_to_terastallize?
      PBDebug.log_ai("#{@user.name} will Terastallize")
      return true
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Determines if the AI should Terastallize the current battler, or save it.
  #-----------------------------------------------------------------------------
  def wants_to_terastallize?
    score = @user.get_total_tera_score
    return true if score == 0 && @battle.pbAbleCount(@user.index) == 1
    highest_score = 0
    if @trainer.medium_skill?
      party = @battle.pbParty(@user.index)
      party.each_with_index do |pkmn, i|
        next if !@battle.pbIsOwner?(@user.index, i)
        next if @battle.pbFindBattler(i, @user.index)
        next if pkmn.fainted? || pkmn.tera? || !pkmn.terastal_able?
        next if pkmn.item&.is_mega_stone? && pkmn.hasMegaForm?
        next if defined?(is_zcrystal?) && pkmn.item&.is_zcrystal?
        party_score = get_party_tera_score(pkmn)
        PBDebug.log_ai("#{@user.name} is comparing Terastal score with party member #{pkmn.name} (score: #{party_score})...")
        highest_score = party_score if party_score > highest_score
      end  
    end
    if score <= highest_score
      PBDebug.log_ai("#{@user.name} will not Terastallize")
      return false
    end
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Determines the value of Terastallization for other party members.
  #-----------------------------------------------------------------------------
  def get_party_tera_score(pkmn)
    score = 0
    type = GameData::Type.get(pkmn.tera_type)
    side = @battle.sides[@user.side]
    if pkmn.hasMove?(:TERABLAST)
      score = (pkmn.hasAbility?(:ADAPTABILITY)) ? 15 : 10
    elsif pkmn.moves.any? { |m| m.type == type.id && m.category < 2 }
      score = (pkmn.hasAbility?(:ADAPTABILITY)) ? 10 : 5
    end
    type_hash = TERA_TYPE_DAMAGE_BOOSTERS[type.id]
    score += 5 if type_hash[:abils].include?(pkmn.ability_id)
    score += 5 if type_hash[:items].include?(pkmn.item_id)
    activeWeather = @battle.field.weatherDuration > 1 || @battle.field.weatherDuration < 0
    activeTerrain = @battle.field.terrainDuration > 1 || @battle.field.terrainDuration < 0
    if !pkmn.hasType?(type.id)
      case type.id
      when :ICE
        score += 5 if @battle.pbWeather == :Hail && activeWeather
      when :PSYCHIC
        score += 5 if @battle.field.terrain == :Psychic && activeTerrain
      when :DRAGON
        score -= 5 if @battle.field.terrain == :Misty && activeTerrain
      when :ELECTRIC
        score += 5 if @battle.field.terrain == :Electric && activeTerrain
        score -= 5 if @battle.field.effects[PBEffects::MudSportField] > 1
      when :ROCK
        score += 5 if @battle.pbWeather == :Sandstorm && activeWeather
        score += 5 if defined?(PBEffects::Volcalith) && side.effects[PBEffects::Volcalith] > 1
      when :DARK
        score += 20 if @user.opponent_side_has_ability?(:PRANKSTER)
        score -= 5  if @user.opponent_side_has_function?("StartNegateTargetEvasionStatStageAndDarkImmunity")
      when :GHOST
        if Settings::MORE_TYPE_EFFECTS
          score += 5 if @user.opponent_side_has_ability?([:ARENATRAP, :SHADOWTAG])
          score += 5 if @user.opponent_side_has_function?("TrapTargetInBattle", "BindTarget")
        end
      when :GRASS
        if Settings::MORE_TYPE_EFFECTS
          score += 10 if @user.opponent_side_has_move_flags?("Powder")
          score += 5  if @user.opponent_side_has_ability?(:EFFECTSPORE)
        end
        score += 5  if @battle.field.terrain == :Grassy && activeTerrain
        score += 10 if @user.opponent_side_has_function?("StartLeechSeedTarget")
        score += 5  if defined?(PBEffects::VineLash) && side.effects[PBEffects::VineLash] > 1
      when :WATER
        if activeWeather
          score -= 5  if @battle.pbWeather == :Sun
          score -= 50 if @battle.pbWeather == :HarshSun
          score += 5  if [:Rain, :HeavyRain].include?(@battle.pbWeather)
        end
        score += 5  if defined?(PBEffects::Cannonade) && side.effects[PBEffects::Cannonade] > 1
        score -= 10 if @user.opponent_side_has_function?("FreezeTargetSuperEffectiveAgainstWater")
      when :POISON, :STEEL
        score += 5  if @user.opponent_side_has_ability?(:TOXICCHAIN)
        score += 5  if @user.opponent_side_has_ability?(:POISONTOUCH)
        score += 5  if @user.opponent_side_has_ability?(:POISONPOINT)
        score -= 5  if @user.opponent_side_has_ability?(:MAGNETPULL) && type.id == :STEEL
      when :FIRE
        if activeWeather
          score -= 5  if @battle.pbWeather == :Rain
          score -= 50 if @battle.pbWeather == :HeavyRain
          score += 5  if [:Sun, :HarshSun].include?(@battle.pbWeather)
        end
        score += 5  if side.effects[PBEffects::SeaOfFire] > 1
        score -= 5  if @battle.field.effects[PBEffects::WaterSportField] > 1
        score -= 10 if @user.opponent_side_has_function?("TargetNextFireMoveDamagesTarget")
        score += 5  if defined?(PBEffects::Wildfire) && side.effects[PBEffects::Wildfire] > 1
      when :FLYING
        score += 5  if @user.opponent_side_has_ability?(:ARENATRAP)
        score -= 5  if @battle.field.effects[PBEffects::Gravity] > 1
        score -= 5  if @user.opponent_side_has_function?("StartGravity")
        score += 50 if @battle.pbWeather == :StrongWinds && activeWeather
        score += 5  if @user.opponent_side_has_function?("TwoTurnAttackInvulnerableInSkyTargetCannotAct")
      end
      move = GameData::Move.get(:TERABLAST)
      each_foe_battler(@user.side) do |b, i|
        type.weaknesses.each do |weakness|
          next if !b.has_damaging_move_of_type?(weakness)
          next if pokemon_can_absorb_move?(pkmn, move, weakness)
          score -= 10
          score -= 50 if pkmn.hasAbility?(:WONDERGUARD)
        end
        type.resistances.each do |resistance|
          next if !b.has_damaging_move_of_type?(resistance)
          next if pokemon_can_absorb_move?(pkmn, move, resistance)
          score += 5
          score += 10 if pkmn.hasAbility?(:WONDERGUARD) && !b.has_mold_breaker?
        end
        type.immunities.each do |immunity|
          next if !b.has_damaging_move_of_type?(immunity)
          score += 10
        end
        if pokemon_can_absorb_move?(b, move, type.id)
          score -= 20
        else
          case type.id
          when :ICE
            score -= 5 if b.has_active_ability?([:THICKFAT])
          when :FIRE
            if b.has_active_ability?([:DRYSKIN, :FLUFFY])
              score += 5
            elsif b.has_active_ability?([:THICKFAT, :HEATPROOF, :WATERBUBBLE])
              score -= 5
            end
          when :GROUND
            score -= 15 if pokemon_airborne?(b.pokemon)
          end
          effectiveness = b.effectiveness_of_type_against_battler(type.id)
          if Effectiveness.super_effective?(effectiveness)
            score += 10
            score += 5 if pkmn.hasAbility?(:NEUROFORCE)
            score -= 5 if b.has_active_ability?([:FILTER, :SOLIDROCK, :PRISMARMOR])
          elsif Effectiveness.not_very_effective?(effectiveness)
            score -= 10
            score += 5 if pkmn.hasAbility?(:TINTEDLENS)
          elsif Effectiveness.ineffective?(effectiveness)
            score -= 20
          end
          if @battle.pbCanTerastallize?(b.index)
            effectiveness = b.effectiveness_of_type_against_single_battler_type(type.id, b.battler.tera_type, @user)
            if Effectiveness.super_effective?(effectiveness)
              score += 5
            elsif Effectiveness.not_very_effective?(effectiveness)
              score -= 5
            elsif Effectiveness.ineffective?(effectiveness)
              score -= 10
            end
          end
        end
      end
    end
    return score
  end
end


#===============================================================================
# Additions to the Battle::AI::AIBattler class.
#===============================================================================
class Battle::AI::AIBattler
  #-----------------------------------------------------------------------------
  # Aliased to add Stellar-type effectiveness.
  #-----------------------------------------------------------------------------
  alias tera_effectiveness_of_type_against_battler effectiveness_of_type_against_battler
  def effectiveness_of_type_against_battler(type, user = nil, move = nil)
    ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    return ret if !type
    case type
    when :STELLAR
      ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER if battler.tera?
      if self.ability_active? && defined?(ModifyTypeEffectiveness)
        ret = Battle::AbilityEffects.triggerModifyTypeEffectiveness(
          self.ability_id, user, battler, move, @ai.battle, ret)
      end
    else
      ret = tera_effectiveness_of_type_against_battler(type, user, move)
    end
    return ret
  end
  
  alias tera_effectiveness_of_type_against_single_battler_type effectiveness_of_type_against_single_battler_type
  def effectiveness_of_type_against_single_battler_type(type, defend_type, user = nil)
    ret = tera_effectiveness_of_type_against_single_battler_type(type, defend_type, user)
    ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER if battler.tera? && type == :STELLAR
    return ret
  end

  #-----------------------------------------------------------------------------
  # Calculates the total score for Terastallization.
  #-----------------------------------------------------------------------------
  def get_total_tera_score
    score = 0
    tera_type = @battler.tera_type
    lost_types = pbTypes(true).select { |t| t != tera_type }
    type_name = GameData::Type.get(tera_type).name
    PBDebug.log_ai("#{self.name} is considering Terastallizing into the #{type_name}-type...")
    if can_attack? &&
       (has_damaging_move_of_type?(tera_type) || 
       has_move_with_function?("CategoryDependsOnHigherDamageTera",
	                           "TerapagosCategoryDependsOnHigherDamage"))
      if lost_types.empty?
        score = get_offensive_tera_score(score, tera_type, true)
      else
        old_score = 0
        tera_score = get_offensive_tera_score(0, tera_type, true)
        lost_types.each do |type|
          type_score = get_offensive_tera_score(0, type)
          old_score += type_score / lost_types.length
        end
        score += tera_score if tera_score > old_score
      end
    end
    offensive_score = score
    PBDebug.log_score_change(offensive_score, "offensive advantage")
    if @ai.trainer.high_skill?
      contact = @battler.affectedByContactEffect? && check_for_move { |m| m.contactMove? }
      if lost_types.empty?
        score = get_defensive_tera_score(score, tera_type, contact)
      else
        old_score = 0
        tera_score = get_defensive_tera_score(0, tera_type, contact)
        lost_types.each do |type|
          type_score = get_defensive_tera_score(0, type, contact)
          old_score += type_score / lost_types.length
        end
        score += tera_score if tera_score > old_score
      end
    end
    PBDebug.log_score_change(score - offensive_score, "defensive advantage")
    return score
  end
  
  #-----------------------------------------------------------------------------
  # Determines the offensive value of Terastallization.
  #-----------------------------------------------------------------------------
  def get_offensive_tera_score(score, type, terastal = false)
    case type
    when :STELLAR
      score += 5 if has_move_with_function?("TerapagosCategoryDependsOnHigherDamage")
    when :GRASS
      score += 5 if @ai.battle.field.terrain == :Grassy
    when :PSYCHIC
      score += 5 if @ai.battle.field.terrain == :Psychic
    when :DRAGON
      score -= 5 if @ai.battle.field.terrain == :Misty
    when :DARK
      score += 5 if @ai.battle.pbCheckGlobalAbility(:DARKAURA)
    when :FAIRY
      score += 5 if @ai.battle.pbCheckGlobalAbility(:FAIRYAURA)
    when :ELECTRIC
      score += 5 if self.effects[PBEffects::Charge] > 0
      score += 5 if @ai.battle.field.terrain == :Electric
      score -= 5 if @ai.battle.field.effects[PBEffects::MudSportField] > 0
    when :WATER
      score -= 5  if @battler.effectiveWeather == :Sun
      score -= 50 if @battler.effectiveWeather == :HarshSun
      score += 5  if [:Rain, :HeavyRain].include?(@battler.effectiveWeather)
    when :FIRE
      score -= 5  if @battler.effectiveWeather == :Rain
      score -= 50 if @battler.effectiveWeather == :HeavyRain
      score += 5  if [:Sun, :HarshSun].include?(@battler.effectiveWeather)
      score -= 5  if @ai.battle.field.effects[PBEffects::WaterSportField] > 0
    end
    score += 5 if has_active_ability?(:ADAPTABILITY)
    type_hash = Battle::AI::TERA_TYPE_DAMAGE_BOOSTERS[type]
    type_hash[:abils].each do |abil|
      next if !has_active_ability?(abil)
      score += 5
      break
    end
    type_hash[:items].each do |item|
      next if !has_active_item?(item)
      score += 5
      break
    end
    move = GameData::Move.get(:TERABLAST)
    @ai.each_foe_battler(@side) do |b, i|
      if self.hp < self.totalhp / 4
        score -= 5 if b.faster_than?(self)
      end
      if !has_mold_breaker? && @ai.pokemon_can_absorb_move?(b, move, type)
        score -= 20
      else
        case type
        when :ICE
          score -= 5 if b.has_active_ability?([:THICKFAT]) && !has_mold_breaker?
        when :FIRE
          if b.has_active_ability?([:DRYSKIN, :FLUFFY])
            score += 5
          elsif b.has_active_ability?([:THICKFAT, :HEATPROOF, :WATERBUBBLE])
            score -= 5 if !has_mold_breaker?
          end
        when :GROUND
          score -= 15 if @ai.pokemon_airborne?(b.pokemon)
        end
        effectiveness = b.effectiveness_of_type_against_battler(type, self)
        if Effectiveness.super_effective?(effectiveness)
          score += 10
          score += 5 if terastal
          score += 5 if has_active_ability?(:NEUROFORCE)
          score -= 5 if b.has_active_ability?([:FILTER, :SOLIDROCK, :PRISMARMOR]) && !has_mold_breaker?
        elsif Effectiveness.not_very_effective?(effectiveness)
          score -= 10
          score += 5 if terastal
          score += 5 if has_active_ability?(:TINTEDLENS)
        elsif Effectiveness.ineffective?(effectiveness)
          score -= 20
        elsif terastal
          score += 5
        end
        if @ai.battle.pbCanTerastallize?(b.index)
          effectiveness = b.effectiveness_of_type_against_single_battler_type(type, b.battler.tera_type, self)
          if Effectiveness.super_effective?(effectiveness)
            score += 5
          elsif Effectiveness.not_very_effective?(effectiveness)
            score -= 5
          elsif Effectiveness.ineffective?(effectiveness)
            score -= 10
          end
        end
      end
    end
    return score
  end
  
  #-----------------------------------------------------------------------------
  # Determines the defensive value of Terastallization.
  #-----------------------------------------------------------------------------
  def get_defensive_tera_score(score, type, contact)
    side = @ai.battle.sides[@side]
    case type
    when :GROUND
      score += 10 if risks_getting_status?(:PARALYSIS, "ParalyzeTargetIfNotTypeImmune")
    when :WATER
      score += 5  if defined?(PBEffects::Cannonade) && side.effects[PBEffects::Cannonade] > 0
      score -= 10 if opponent_side_has_function?("FreezeTargetSuperEffectiveAgainstWater")
    when :ICE
      score += 5  if @battler.effectiveWeather == :Hail
      score += 10 if risks_getting_status?(:FROZEN, "FreezeTarget")
      score += 10 if risks_getting_status?(:FROSTBITE, "FrostbiteTarget")
    when :ROCK
      score += 5  if @battler.effectiveWeather == :Sandstorm
      score += 5  if defined?(PBEffects::Volcalith) && side.effects[PBEffects::Volcalith] > 0
    when :ELECTRIC
      score += 5  if self.effects[PBEffects::MagnetRise] > 0
      score += 10 if risks_getting_status?(:PARALYSIS, "ParalyzeTarget")
    when :DARK
      score -= 5  if self.effects[PBEffects::MiracleEye]
      score += 20 if opponent_side_has_ability?(:PRANKSTER)
      score -= 5  if opponent_side_has_function?("StartNegateTargetEvasionStatStageAndDarkImmunity")
    when :GHOST
      if Settings::MORE_TYPE_EFFECTS
        score += 5 if @battler.trappedInBattle?
        score += 5 if opponent_side_has_ability?([:ARENATRAP, :SHADOWTAG])
        score += 5 if opponent_side_has_function?("TrapTargetInBattle", "BindTarget")
      end
    when :GRASS
      if @battler.affectedByPowder?
        score += 10 if opponent_side_has_move_flags?("Powder")
        score += 5  if opponent_side_has_ability?(:EFFECTSPORE, true) && contact
      end
      score += 10 if opponent_side_has_function?("StartLeechSeedTarget")
      score += 5  if defined?(PBEffects::VineLash) && side.effects[PBEffects::VineLash] > 0
    when :FIRE
      score -= 10 if self.effects[PBEffects::Powder]
      score += 5  if side.effects[PBEffects::SeaOfFire] > 0
      score += 10 if risks_getting_status?(:BURN, "BurnTarget")
      score -= 10 if opponent_side_has_function?("TargetNextFireMoveDamagesTarget")
      score += 5  if defined?(PBEffects::Wildfire) && side.effects[PBEffects::Wildfire] > 0
    when :POISON, :STEEL
      score += 5  if side.effects[PBEffects::ToxicSpikes] > 0
      score += 5  if opponent_side_has_ability?(:TOXICCHAIN)
      score += 5  if opponent_side_has_ability?(:POISONTOUCH, true)
      score += 5  if opponent_side_has_ability?(:POISONPOINT, true) && contact
      score -= 5  if opponent_side_has_ability?(:MAGNETPULL) && type == :STEEL
      score += 10 if risks_getting_status?(:POISON, "PoisonTarget", "BadPoisonTarget")
    when :FLYING
      score += 5  if side.effects[PBEffects::StickyWeb]
      score -= 5  if self.effects[PBEffects::SmackDown]
      score += 5  if side.effects[PBEffects::Spikes] > 0
      score += 5  if side.effects[PBEffects::ToxicSpikes] > 0
      score += 5  if opponent_side_has_ability?(:ARENATRAP)
      score += 50 if @battler.effectiveWeather == :StrongWinds
      score -= 5  if opponent_side_has_function?("StartGravity")
      score -= 5  if @ai.battle.field.effects[PBEffects::Gravity] > 0
      score += 5  if opponent_side_has_function?("TwoTurnAttackInvulnerableInSkyTargetCannotAct")
    end
    checked_types = []
    @ai.each_foe_battler(@side) do |b, i|
      b.battler.eachMove do |move|
        next if !move.damagingMove?
        move_type = move.pbCalcType(b.battler)
        if @ai.battle.pbCanTerastallize?(b.index)
          if ["CategoryDependsOnHigherDamageTera",
		      "TerapagosCategoryDependsOnHigherDamage"].include?(move.function_code)
            move_type = b.battler.tera_type
          end			  
        end
        next if @ai.pokemon_can_absorb_move?(self, move, move_type)
        incomingMove = b.effects[PBEffects::TwoTurnAttack] && 
                       b.effects[PBEffects::TwoTurnAttack] == move.id &&
                       @ai.battle.choices[b.index][3] == @index
        next if checked_types.include?(move_type) && !incomingMove
        effectiveness = self.effectiveness_of_type_against_single_battler_type(move_type, type, b)
        if Effectiveness.super_effective?(effectiveness)
          score -= 10
          score -= 10 if incomingMove
          score -= 50 if has_active_ability?(:WONDERGUARD)
        elsif Effectiveness.not_very_effective?(effectiveness)
          score += 5
          score += 10 if incomingMove
          score += 10 if has_active_ability?(:WONDERGUARD) && !b.has_mold_breaker?
        elsif Effectiveness.ineffective?(effectiveness)
          score += 10
          score += 10 if incomingMove
        end
        checked_types.push(move_type)
      end
    end
    return score
  end
end

#===============================================================================
# Tar Shot
#===============================================================================
# Considers whether the target is Terastallized.
#-------------------------------------------------------------------------------
Battle::AI::Handlers::MoveFailureAgainstTargetCheck.add("LowerTargetSpeed1MakeTargetWeakerToFire",
  proc { |move, user, target, ai, battle|
    next false if !target.effects[PBEffects::TarShot] && !target.battler.tera?
    next move.statusMove? &&
         !target.battler.pbCanLowerStatStage?(move.move.statDown[0], user.battler, move.move)
  }
)
Battle::AI::Handlers::MoveEffectAgainstTargetScore.add("LowerTargetSpeed1MakeTargetWeakerToFire",
  proc { |score, move, user, target, ai, battle|
    score = ai.get_score_for_target_stat_drop(score, target, move.move.statDown)
    if !target.effects[PBEffects::TarShot] && !target.battler.tera?
      eff = target.effectiveness_of_type_against_battler(:FIRE)
      if !Effectiveness.ineffective?(eff)
        score += 10 * eff if user.has_damaging_move_of_type?(:FIRE)
      end
    end
    next score
  }
)