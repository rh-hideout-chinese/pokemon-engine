#===============================================================================
# Battle move code related to Terastallization.
#===============================================================================

#-------------------------------------------------------------------------------
# Changes to dealing damage while Terastallized.
#-------------------------------------------------------------------------------
class Battle::Move
  #-----------------------------------------------------------------------------
  # Utility for checking if a weak Tera move's BP should be boosted to 60 BP.
  #-----------------------------------------------------------------------------
  def pbBaseDamageTera(baseDmg, user, type, override = false)
    return baseDmg if !user.typeTeraBoosted?(type, override)
    return baseDmg if @priority > 0 || self.multiHitMove?
    return baseDmg if [
      "PowerHigherWithUserHP",                # Eruption, Water Spout
      "PowerLowerWithUserHP",                 # Flail, Reversal
      "PowerHigherWithTargetHP",              # Wring Out, Crush Grip
      "PowerHigherWithTargetHP100PowerRange", # Hard Press
      "PowerHigherWithUserHeavierThanTarget", # Heavy Slam, Heat Crash
      "PowerHigherWithTargetWeight",          # Low Kick, Grass Knot
      "PowerHigherWithUserFasterThanTarget",  # Electro Ball
      "PowerHigherWithTargetFasterThanUser",  # Gyro Ball
      "ThrowUserItemAtTarget"                 # Fling
    ].include?(@function_code)
    if user.hasActiveAbility?(:TECHNICIAN)
      return baseDmg if (baseDmg * 1.5) > 60
    else
      return baseDmg if baseDmg > 60
    end
    return 60
  end
  
  #-----------------------------------------------------------------------------
  # Edited to calculate STAB boosts while Terastallized.
  #-----------------------------------------------------------------------------
  def pbCalcDamageMults_Type(user, target, numTargets, type, baseDmg, multipliers)
    if type
      adaptability = user.hasActiveAbility?(:ADAPTABILITY)
      #-------------------------------------------------------------------------
      # Terastal STAB calcs
      if user.tera?
        teraBonus = 1
        adaptability = false if user.tera_type == :STELLAR
        if user.pbPreTeraTypes.include?(type)
          if user.typeTeraBoosted?(type)
            teraBonus = (adaptability) ? 2.25 : 2
          else
            teraBonus = (adaptability) ? 2 : 1.5 
          end
        elsif user.typeTeraBoosted?(type)
          stab = (user.tera_type == :STELLAR) ? 1.2 : 1.5
          teraBonus = (adaptability) ? 2 : stab
        end
        multipliers[:final_damage_multiplier] *= teraBonus
      #-------------------------------------------------------------------------
      # Normal STAB calcs
      elsif user.pbHasType?(type)
        stab = (adaptability) ? 2 : 1.5
        multipliers[:final_damage_multiplier] *= stab
      end
    end
    multipliers[:final_damage_multiplier] *= target.damageState.typeMod
  end
  
  #-----------------------------------------------------------------------------
  # Edited to allow the Stellar-type to hit Tera Pokemon super effectively.
  #-----------------------------------------------------------------------------
  alias tera_pbCalcTypeMod pbCalcTypeMod
  def pbCalcTypeMod(moveType, user, target)
    ret = Effectiveness::NORMAL_EFFECTIVE_MULTIPLIER
    return ret if !moveType
    case moveType
    when :STELLAR
      ret = Effectiveness::SUPER_EFFECTIVE_MULTIPLIER if target.tera?
      if target.abilityActive? && defined?(ModifyTypeEffectiveness)
        ret = Battle::AbilityEffects.triggerModifyTypeEffectiveness(
          target.ability, user, target, self, @battle, ret)
      end
    else
      ret = tera_pbCalcTypeMod(moveType, user, target)
    end
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Plays Tera Burst animation when using Tera-boosted moves.
  #-----------------------------------------------------------------------------
  alias tera_pbDisplayUseMessage pbDisplayUseMessage
  def pbDisplayUseMessage(user)
    if user.tera? && damagingMove? && user.typeTeraBoosted?(pbCalcType(user))
      @battle.pbDeluxeTriggers(user.index, nil, "BeforeTeraMove", user.species, user.tera_type, @id)
      @battle.scene.pbTeraBurst(user.index)
    end
    tera_pbDisplayUseMessage(user)
  end
end

#-------------------------------------------------------------------------------
# Changes to the AI dealing damage while Terastallized.
#-------------------------------------------------------------------------------
class Battle::AI::AIMove
  #-----------------------------------------------------------------------------
  # Aliased for checking if an AI's weak Tera move's BP should be boosted or not.
  #-----------------------------------------------------------------------------
  alias tera_base_power base_power
  def base_power
    ret = tera_base_power
    ret = @move.pbBaseDamageTera(ret, @ai.user.battler, rough_type)
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Calculates AI damage multipliers based on typing.
  #-----------------------------------------------------------------------------
  def calc_type_mults(user, target, base_dmg, calc_type, is_critical, multipliers)
    if calc_type
      adaptability = user.has_active_ability?(:ADAPTABILITY)
      if user.battler.tera?
        teraBonus = 1
        adaptability = false if user.battler.tera_type == :STELLAR
        if user.battler.pbPreTeraTypes.include?(calc_type)
          if user.battler.typeTeraBoosted?(calc_type)
            teraBonus = (adaptability) ? 2.25 : 2
          else
            teraBonus = (adaptability) ? 2 : 1.5
          end
        elsif user.battler.typeTeraBoosted?(calc_type)
          stab = (user.battler.tera_type == :STELLAR) ? 1.2 : 1.5
          teraBonus = (adaptability) ? 2 : stab
        end
        multipliers[:final_damage_multiplier] *= teraBonus
      elsif user.has_type?(calc_type)
        stab = (adaptability) ? 2 : 1.5
        multipliers[:final_damage_multiplier] *= stab
      end
    end
    typemod = target.effectiveness_of_type_against_battler(calc_type, user, @move)
    multipliers[:final_damage_multiplier] *= typemod
  end
end


################################################################################
#
# Move functions.
#
################################################################################

#===============================================================================
# Hidden Power
#===============================================================================
# Excludes Stellar as a potential Hidden Power type.
#-------------------------------------------------------------------------------
def pbHiddenPower(pkmn)
  iv = pkmn.iv
  idxType = 0
  power = 60
  types = []
  GameData::Type.each do |t|
    types[t.icon_position] ||= []
    types[t.icon_position].push(t.id) if !t.pseudo_type && ![:NORMAL, :STELLAR, :SHADOW].include?(t.id)
  end
  types.flatten!.compact!
  idxType |= (iv[:HP] & 1)
  idxType |= (iv[:ATTACK] & 1) << 1
  idxType |= (iv[:DEFENSE] & 1) << 2
  idxType |= (iv[:SPEED] & 1) << 3
  idxType |= (iv[:SPECIAL_ATTACK] & 1) << 4
  idxType |= (iv[:SPECIAL_DEFENSE] & 1) << 5
  idxType = (types.length - 1) * idxType / 63
  type = types[idxType]
  if Settings::MECHANICS_GENERATION <= 5
    powerMin = 30
    powerMax = 70
    power |= (iv[:HP] & 2) >> 1
    power |= (iv[:ATTACK] & 2)
    power |= (iv[:DEFENSE] & 2) << 1
    power |= (iv[:SPEED] & 2) << 2
    power |= (iv[:SPECIAL_ATTACK] & 2) << 3
    power |= (iv[:SPECIAL_DEFENSE] & 2) << 4
    power = powerMin + ((powerMax - powerMin) * power / 63)
  end
  return [type, power]
end

#===============================================================================
# Tar Shot
#===============================================================================
# Does not apply Tar Shot effect on a Terastallized target.
#-------------------------------------------------------------------------------
class Battle::Move::LowerTargetSpeed1MakeTargetWeakerToFire < Battle::Move::TargetStatDownMove
  def pbFailsAgainstTarget?(user, target, show_message)
    return super if target.effects[PBEffects::TarShot] || target.tera?
    return false
  end

  def pbEffectAgainstTarget(user, target)
    super
    if !target.effects[PBEffects::TarShot] && !target.tera?
      target.effects[PBEffects::TarShot] = true
      @battle.pbDisplay(_INTL("{1} became weaker to fire!", target.pbThis))
    end
  end
end

#===============================================================================
# Revelation Dance
#===============================================================================
# Edited so that move type isn't affected by Terastallization.
#-------------------------------------------------------------------------------
class Battle::Move::TypeIsUserFirstType < Battle::Move
  def pbBaseType(user)
    userTypes = user.pokemon.types
    return userTypes[1] || userTypes[0] || @type
  end
end

#===============================================================================
# Tera Blast
#===============================================================================
# Type is based on user's Tera type when Terastallized.
# Deals damage based on user's highest stat when Terastallized.
# When Stellar-type, this move's base power is increased to 100.
# When Stellar-type, this move lower's the user's Atk/Sp.Atk by 1 stage each per use.
#-------------------------------------------------------------------------------
class Battle::Move::CategoryDependsOnHigherDamageTera < Battle::Move
  def initialize(battle, move)
    super
    @calcCategory = 1
  end

  def physicalMove?(thisType = nil); return (@calcCategory == 0); end
  def specialMove?(thisType = nil);  return (@calcCategory == 1); end

  def pbOnStartUse(user, targets)
    return if !user.tera?
    realAtk, realSpAtk = user.getOffensiveStats
    @calcCategory = (realAtk > realSpAtk) ? 0 : 1
  end
  
  def pbBaseType(user)
    return (user.tera?) ? user.tera_type : :NORMAL
  end
  
  def pbBaseDamage(baseDmg, user, target)
    return 100 if user.tera? && user.tera_type == :STELLAR
    return baseDmg
  end
  
  def pbEffectWhenDealingDamage(user, target)
    return if @battle.pbAllFainted?(target.idxOwnSide)
    if user.tera? && user.tera_type == :STELLAR
      showAnim = true
      statDown = [:ATTACK, 1, :SPECIAL_ATTACK, 1]
      (statDown.length / 2).times do |i|
        next if !user.pbCanLowerStatStage?(statDown[i * 2], user, self)
        if user.pbLowerStatStage(statDown[i * 2], statDown[(i * 2) + 1], user, showAnim)
          showAnim = false
        end
      end
    end
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = GameData::Type.get(pbBaseType(user)).icon_position
    super
  end
end

#===============================================================================
# Tera Starstorm
#===============================================================================
# Type becomes Stellar when Terastallized.
# Deals damage based on user's highest stat when Terastallized.
# When Stellar-type, this move targets all opposing battlers.
#-------------------------------------------------------------------------------
class Battle::Move::TerapagosCategoryDependsOnHigherDamage < Battle::Move
  def initialize(battle, move)
    super
    @calcCategory = 1
  end
  
  def isStellarTerapagos?(user)
    return user.isSpecies?(:TERAPAGOS) && user.tera? && user.tera_type == :STELLAR
  end

  def physicalMove?(thisType = nil); return (@calcCategory == 0); end
  def specialMove?(thisType = nil);  return (@calcCategory == 1); end
  
  def pbOnStartUse(user, targets)
    return if !isStellarTerapagos?(user)
    realAtk, realSpAtk = user.getOffensiveStats
    @calcCategory = (realAtk > realSpAtk) ? 0 : 1
  end
    
  def pbBaseType(user)
    return (isStellarTerapagos?(user)) ? :STELLAR : :NORMAL
  end
  
  def pbTarget(user)
    return GameData::Target.get(:AllFoes) if isStellarTerapagos?(user)
    return super
  end

  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if isStellarTerapagos?(user)
    super
  end
end