#===============================================================================
# Additions to the Battle:Battler class.
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # Tera attributes.
  #-----------------------------------------------------------------------------
  def tera?;             return @pokemon&.tera?;             end
  def tera_type;         return @pokemon&.tera_type;         end
  def tera_form?;        return @pokemon&.tera_form?;        end
  def display_tera_type; return @pokemon&.display_tera_type; end
  
  #-----------------------------------------------------------------------------
  # Returns true if the user is capable of Terastallization.
  #-----------------------------------------------------------------------------
  def hasTera?(check_available = true)
    return false if shadowPokemon?
    return false if wild? && @battle.wildBattleMode != :tera
    return false if @battle.raidBattle? && @battle.raidRules[:style] != :Tera
    return false if @pokemon.hasTerastalForm? && @effects[PBEffects::Transform]
    return false if @effects[PBEffects::TransformPokemon]&.hasTerastalForm?
    return false if !getActiveState.nil?
    return false if hasEligibleAction?(:mega, :primal, :zmove, :ultra, :dynamax, :style, :zodiac)
    side  = self.idxOwnSide
    owner = @battle.pbGetOwnerIndexFromBattlerIndex(@index)
    return false if check_available && @battle.terastallize[side][owner] == -2
    return !tera_type.nil?
  end
  
  #-----------------------------------------------------------------------------
  # Un-Terastallizes. When teraBreak = true, shows more dramatic animation.
  #-----------------------------------------------------------------------------
  def unTera(teraBreak = false)
    @battle.scene.pbRevertBattlerStart(@index)
    @pokemon.terastallized = false
    self.form_update(true)
    @battle.scene.pbRevertTera(@index, teraBreak)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to un-Terastallize fainted battlers.
  #-----------------------------------------------------------------------------
  alias tera_pbFaint pbFaint
  def pbFaint(*args)
    self.unTera(true) if tera? && fainted? && !@fainted
    tera_pbFaint(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliases related to a battler's typing.
  #-----------------------------------------------------------------------------
  alias tera_pbTypes pbTypes
  def pbTypes(withExtraType = false)
    if tera?
      return @types if tera_type == :STELLAR
      return [tera_type]
    end
    return tera_pbTypes(withExtraType)
  end
  
  alias tera_pbHasOtherType? pbHasOtherType?
  def pbHasOtherType?(type)
    return false if tera?
    return tera_pbHasOtherType?(type)
  end
  
  alias tera_canChangeType? canChangeType?
  def canChangeType?
    return false if tera?
    return tera_canChangeType?
  end
  
  alias tera_pbChangeTypes pbChangeTypes
  def pbChangeTypes(newType)
    if newType.is_a?(Battle::Battler) && newType.tera?
      newTypes = newType.pbPreTeraTypes
      newExtraType = newType.effects[PBEffects::ExtraType]
      newTypes.delete(newExtraType)
      newTypes.push(:NORMAL) if newTypes.length == 0
      @types = newTypes.clone
      @effects[PBEffects::ExtraType] = newExtraType
    else
      tera_pbChangeTypes(newType)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Returns the battler's original typing prior to Terastallization.
  #-----------------------------------------------------------------------------
  def pbPreTeraTypes
    ret = @types
    ret.delete(:FIRE) if @effects[PBEffects::BurnUp]
    if @effects[PBEffects::Roost]
      ret.delete(:FLYING)
      ret.push(:NORMAL) if ret.length == 0
    end
    extra = @effects[PBEffects::ExtraType]
    ret.push(extra) if extra && !@types.include?(extra)
    ret.uniq!
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Checks if Terastallization can boost the damage of a given type.
  #-----------------------------------------------------------------------------
  def typeTeraBoosted?(type, override = false)
    return false if !tera? && !override
    case tera_type
    when :STELLAR
      return true if !tera? && override
      side  = self.idxOwnSide
      owner = @battle.pbGetOwnerIndexFromBattlerIndex(@index)
      return @battle.boosted_tera_types[side][owner].include?(type)
    else
      return type == tera_type
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to track the types that Tera Stellar is able to boost.
  #-----------------------------------------------------------------------------
  alias tera_pbEndTurn pbEndTurn
  def pbEndTurn(_choice)
    tera_pbEndTurn(_choice)
    return if !@lastMoveUsedType
    return if !tera? || tera_type != :STELLAR
    return if @battle.raidBattle? || isSpecies?(:TERAPAGOS)
    return if GameData::Move.get(@lastMoveUsed).category >= 2
    side  = self.idxOwnSide
    owner = @battle.pbGetOwnerIndexFromBattlerIndex(@index)
    if @battle.boosted_tera_types[side][owner].include?(@lastMoveUsedType)
      @battle.boosted_tera_types[side][owner].delete(@lastMoveUsedType)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to prevent Morpeko from changing forms while Terastallized.
  #-----------------------------------------------------------------------------
  alias tera_pbCheckForm pbCheckForm
  def pbCheckForm(endOfRound = false)
    return if isSpecies?(:MORPEKO) && tera?
    tera_pbCheckForm(endOfRound)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for calculating a battler's stats to determine Tera Blast's category.
  #----------------------------------------------------------------------------- 
  def getOffensiveStats
    stageMul = [2, 2, 2, 2, 2, 2, 2, 3, 4, 5, 6, 7, 8]
    stageDiv = [8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 2, 2, 2]
    atk        = self.attack
    atkStage   = self.stages[:ATTACK] + 6
    realAtk    = (atk.to_f * stageMul[atkStage] / stageDiv[atkStage]).floor
    spAtk      = self.spatk
    spAtkStage = self.stages[:SPECIAL_ATTACK] + 6
    realSpAtk  = (spAtk.to_f * stageMul[spAtkStage] / stageDiv[spAtkStage]).floor
    return realAtk, realSpAtk
  end
end