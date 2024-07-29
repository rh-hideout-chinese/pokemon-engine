################################################################################
#
# Base move effects used by other Dynamax moves.
#
################################################################################

#-------------------------------------------------------------------------------
# Generic checks used by all Dynamax moves.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::Move < Battle::Move
  def pbEffectAfterAllHits(user, target)
    return false if @addlEffect > 0
    return false if target.damageState.unaffected
    return false if @battle.decision > 0
    return true
  end
  
  def pbAdditionalEffect(user, target)
    return false if @addlEffect == 0
    return true
  end
end

#-------------------------------------------------------------------------------
# Raises one of the stats for the user's entire side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::UserSideStatUpMove < Battle::DynamaxMove::Move
  attr_reader :statUp

  def pbMoveFailed?(user, targets)
    return false if damagingMove?
    @battle.allSameSideBattlers(user).each do |b|
      return false if b.pbCanRaiseStatStage?(@statUp[0], user, self)
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return true
  end

  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.allSameSideBattlers(user).each do |b|
      if b.pbCanRaiseStatStage?(@statUp[0], user, self, true)
        b.pbRaiseStatStage(@statUp[0], @statUp[1], user)
      end
    end
  end

  def pbAdditionalEffect(user, target)
    return if !super
    @battle.allSameSideBattlers(user).each do |b|
      if b.pbCanRaiseStatStage?(@statUp[0], user, self, true)
        b.pbRaiseStatStage(@statUp[0], @statUp[1], user)
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Lowers one of the stats for the opponent's entire side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::TargetSideStatDownMove < Battle::DynamaxMove::Move
  attr_reader :statDown

  def pbMoveFailed?(user, targets)
    return false if damagingMove?
    @battle.allOtherSideBattlers(user).each do |b|
      return false if b.pbCanLowerStatStage?(@statDown[0], user, self)
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return true
  end

  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.allOtherSideBattlers(user).each do |b|
      if b.pbCanLowerStatStage?(@statDown[0], user, self, true)
        b.pbLowerStatStage(@statDown[0], @statDown[1], user)
      end
    end
  end

  def pbAdditionalEffect(user, target)
    return if !super
    @battle.allOtherSideBattlers(user).each do |b|
      if b.pbCanLowerStatStage?(@statDown[0], user, self, true)
        b.pbLowerStatStage(@statDown[0], @statDown[1], user)
      end
    end
  end
end

#-------------------------------------------------------------------------------
# Inflicts status conditions for the opponent's entire side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::TargetSideStatusEffectMove < Battle::DynamaxMove::Move
  attr_reader :statuses

  def pbMoveFailed?(user, targets)
    return false if damagingMove?
    @battle.allOtherSideBattlers(user).each do |b|
      @statuses.shuffle.each do |status|
        case status
        when :NONE        then return false if b.status != :NONE
        when :BAD_POISON  then return false if b.pbCanPoison?(user, false, self)
        when :INFATUATION then return false if b.pbCanAttract?(user, false)
        when :CONFUSE     then return false if b.pbCanConfuse?(user, false, self)
        else return false if b.pbCanInflictStatus?(status, user, false, self)
        end
      end
    end
    @battle.pbDisplay(_INTL("But it failed!"))
    return true
  end
  
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    applyStatuses(user)
  end

  def pbAdditionalEffect(user, target)
    return if !super
    applyStatuses(user)
  end
  
  def applyStatuses(user)
    @battle.allOtherSideBattlers(user).each do |b|
      @statuses.shuffle.each do |status|
        case status
        when :NONE
          if b.status != :NONE
            b.pbCureStatus
            break
          end
        when :TOXIC, :TOXIC_POISON, :BAD_POISON
          if b.pbCanPoison?(user, false, self)
            b.pbPoison(user, nil, true)
            break
          end
        when :ATTRACT, :INFATUATION
          if b.pbCanAttract?(user, false)
            b.pbAttract(user)
            break
          end
        when :CONFUSE, :CONFUSED, :CONFUSION
          if b.pbCanConfuse?(user, false, self)
            b.pbConfuse
            break
          end
        else
          if !b.pbHasAnyStatus? && b.pbCanInflictStatus?(status, user, false, self)
            count = ([:SLEEP, :DROWSY].include?(status)) ? b.pbSleepDuration : 0
            b.pbInflictStatus(status, count, nil, user)
            break
          end
        end
      end
    end
  end
end


################################################################################
#
# Moves that start weather.
#
################################################################################

#===============================================================================
# Max Flare
#===============================================================================
# Starts sunny weather.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartSunWeather < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if [:HarshSun, :HeavyRain, :StrongWinds].include?(@battle.field.weather)
    @battle.pbStartWeather(user, :Sun, true)
  end
end

#===============================================================================
# Max Geyser
#===============================================================================
# Starts rainy weather.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartRainWeather < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if [:HarshSun, :HeavyRain, :StrongWinds].include?(@battle.field.weather)
    @battle.pbStartWeather(user, :Rain, true)
  end
end

#===============================================================================
# Max Rockfall
#===============================================================================
# Starts sandstorm weather.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartSandstormWeather < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if [:HarshSun, :HeavyRain, :StrongWinds].include?(@battle.field.weather)
    @battle.pbStartWeather(user, :Sandstorm, true)
  end
end

#===============================================================================
# Max Hailstorm
#===============================================================================
# Starts hail weather.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartHailWeather < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if [:HarshSun, :HeavyRain, :StrongWinds].include?(@battle.field.weather)
    @battle.pbStartWeather(user, :Hail, true)
  end
end


################################################################################
#
# Moves that start terrain.
#
################################################################################

#===============================================================================
# Max Overgrowth
#===============================================================================
# Starts grassy terrain.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartGrassyTerrain < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.pbStartTerrain(user, :Grassy)
  end
end

#===============================================================================
# Max Lightning
#===============================================================================
# Starts electric terrain.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartElectricTerrain < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.pbStartTerrain(user, :Electric)
  end
end

#===============================================================================
# Max Starfall
#===============================================================================
# Starts misty terrain.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartMistyTerrain < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.pbStartTerrain(user, :Misty)
  end
end

#===============================================================================
# Max Mindstorm
#===============================================================================
# Starts psychic terrain.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartPsychicTerrain < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.pbStartTerrain(user, :Psychic)
  end
end


################################################################################
#
# Moves that raise the stats of Pokemon on the user's side.
#
################################################################################

#===============================================================================
# Max Knuckle
#===============================================================================
# Raises the Attack of the Pokemon on the user's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RaiseUserSideAtk1 < Battle::DynamaxMove::UserSideStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:ATTACK, 1]
  end
end

#===============================================================================
# Max Steelspike
#===============================================================================
# Raises the Defense of the Pokemon on the user's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RaiseUserSideDef1 < Battle::DynamaxMove::UserSideStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:DEFENSE, 1]
  end
end

#===============================================================================
# Max Ooze
#===============================================================================
# Raises the Sp.Atk of the Pokemon on the user's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RaiseUserSideSpAtk1 < Battle::DynamaxMove::UserSideStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPECIAL_ATTACK, 1]
  end
end

#===============================================================================
# Max Quake
#===============================================================================
# Raises the Sp.Def of the Pokemon on the user's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RaiseUserSideSpDef1 < Battle::DynamaxMove::UserSideStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPECIAL_DEFENSE, 1]
  end
end

#===============================================================================
# Max Airstream
#===============================================================================
# Raises the Speed of the Pokemon on the user's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RaiseUserSideSpeed1 < Battle::DynamaxMove::UserSideStatUpMove
  def initialize(battle, move)
    super
    @statUp = [:SPEED, 1]
  end
end


################################################################################
#
# Moves that lower the stats of Pokemon on the opponent's side.
#
################################################################################

#===============================================================================
# Max Wyrmwind
#===============================================================================
# Lowers the Attack of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideAtk1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:ATTACK, 1]
  end
end

#===============================================================================
# Max Phantasm
#===============================================================================
# Lowers the Defense of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideDef1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:DEFENSE, 1]
  end
end

#===============================================================================
# Max Flutterby
#===============================================================================
# Lowers the Sp.Atk of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideSpAtk1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:SPECIAL_ATTACK, 1]
  end
end

#===============================================================================
# Max Darkness
#===============================================================================
# Lowers the Sp.Def of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideSpDef1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:SPECIAL_DEFENSE, 1]
  end
end

#===============================================================================
# Max Strike
#===============================================================================
# Lowers the Speed of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideSpeed1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:SPEED, 1]
  end
end


################################################################################
#
# Other moves.
#
################################################################################

#===============================================================================
# Max Guard
#===============================================================================
# Protects the user from attacks, including Dynamax moves.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::ProtectUserEvenFromDynamaxMoves < Battle::Move::ProtectMove
  def initialize(battle, move)
    super
    @effect = PBEffects::MaxGuard
  end
end