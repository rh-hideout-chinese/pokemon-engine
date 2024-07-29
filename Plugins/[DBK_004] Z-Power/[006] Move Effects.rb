################################################################################
#
# Z-Moves
#
################################################################################

#===============================================================================
# Generic Z-Move.
#===============================================================================
class Battle::ZMove::None < Battle::Move
end

#===============================================================================
# Stoked Sparksurfer
#===============================================================================
# Paralyzes the target.
#-------------------------------------------------------------------------------
class Battle::ZMove::ParalyzeTarget < Battle::Move::ParalyzeTarget
  def canMagicCoat?; return false; end
end

#===============================================================================
# Clangorus Soulblaze
#===============================================================================
# Raises all of the user's stats by 1 stage.
#-------------------------------------------------------------------------------
class Battle::ZMove::RaiseUserMainStats1 < Battle::Move::MultiStatUpMove
  def canSnatch?; return false; end
  
  def initialize(battle, move)
    super
    @statUp = [
      :ATTACK,          1,
      :DEFENSE,         1,
      :SPECIAL_ATTACK,  1,
      :SPECIAL_DEFENSE, 1,
      :SPEED,           1
    ]
  end
end

#===============================================================================
# Extreme Evoboost
#===============================================================================
# Raises all of the user's stats by 2 stages.
#-------------------------------------------------------------------------------
class Battle::ZMove::RaiseUserMainStats2 < Battle::Move::MultiStatUpMove
  def canSnatch?; return false; end
  
  def initialize(battle, move)
    super
    @statUp = [
      :ATTACK,          2,
      :DEFENSE,         2,
      :SPECIAL_ATTACK,  2,
      :SPECIAL_DEFENSE, 2,
      :SPEED,           2
    ]
  end
end

#===============================================================================
# Genesis Supernova
#===============================================================================
# Starts psychic terrain.
#-------------------------------------------------------------------------------
class Battle::ZMove::DamageTargetStartPsychicTerrain < Battle::Move
  def pbAdditionalEffect(user, target)
    @battle.pbStartTerrain(user, :Psychic)
  end
end

#===============================================================================
# Splintered Stormshards
#===============================================================================
# Removes any active terrain. Animation differs based on form.
#-------------------------------------------------------------------------------
class Battle::ZMove::DamageTargetRemoveTerrain < Battle::Move
  def pbAdditionalEffect(user, target)
    case @battle.field.terrain
    when :Electric
      @battle.pbDisplay(_INTL("The electricity disappeared from the battlefield."))
    when :Grassy
      @battle.pbDisplay(_INTL("The grass disappeared from the battlefield."))
    when :Misty
      @battle.pbDisplay(_INTL("The mist disappeared from the battlefield."))
    when :Psychic
      @battle.pbDisplay(_INTL("The weirdness disappeared from the battlefield."))
    end
    @battle.field.terrain = :None
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = user.form
    super
  end
end

#===============================================================================
# Guardian of Alola
#===============================================================================
# Inflicts 75% of the target's current HP.
#-------------------------------------------------------------------------------
class Battle::ZMove::FixedDamageThreeQuartersTargetHP < Battle::Move::FixedDamageMove
  def pbFixedDamage(user,target)
    return (target.real_hp * 0.75).round
  end
  
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    case user.species
    when :TAPUKOKO then hitNum = 0
    when :TAPULELE then hitNum = 1
    when :TAPUBULU then hitNum = 2
    when :TAPUFINI then hitNum = 3
    end
    super
  end
end

#===============================================================================
# Searing Sunraze Smash, Menacing Moonraze Maelstrom
#===============================================================================
# Ignores the target's Ability.
#-------------------------------------------------------------------------------
class Battle::ZMove::IgnoreTargetAbility < Battle::Move::IgnoreTargetAbility
end

#===============================================================================
# Light That Burns the Sky
#===============================================================================
# Ignores the target's Ability. Damage category is chosen based on which would
# deal the most damage.
#-------------------------------------------------------------------------------
class Battle::ZMove::CategoryDependsOnHigherDamageIgnoreTargetAbility < Battle::Move::CategoryDependsOnHigherDamageIgnoreTargetAbility
end


################################################################################
#
# Standard moves.
#
################################################################################

#===============================================================================
# Copycat
#===============================================================================
# Move fails when the last used move was a Z-Move.
#-------------------------------------------------------------------------------
class Battle::Move::UseLastMoveUsed < Battle::Move
  def pbMoveFailed?(user, targets)
    if !@copied_move || GameData::Move.get(@copied_move).zMove? ||
       @moveBlacklist.include?(GameData::Move.get(@copied_move).function_code)
      @battle.pbDisplay(_INTL("But it failed!"))
      return true
    end
    return false
  end
end

#===============================================================================
# Encore
#===============================================================================
# Move fails if the target's last used move was a Z-Move.
#-------------------------------------------------------------------------------
class Battle::Move::DisableTargetUsingDifferentMove < Battle::Move
  alias zmove_pbFailsAgainstTarget? pbFailsAgainstTarget?
  def pbFailsAgainstTarget?(user, target, show_message)
    if target.lastMoveUsedIsZMove
      @battle.pbDisplay(_INTL("But it failed!")) if show_message
      return true
    end
    return zmove_pbFailsAgainstTarget?(user, target, show_message)
  end
end