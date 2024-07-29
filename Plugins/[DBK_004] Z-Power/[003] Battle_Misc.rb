################################################################################
#
# PBEffects
#
################################################################################

module PBEffects
  EncoreRestore = 201  # Used for restoring the Encore effect after a Z-Move was used.
  ZHealing      = 709  # The healing effect of Z-Parting Shot/Z-Memento.
end

module Battle::DebugVariables
  POSITION_EFFECTS[PBEffects::ZHealing] = { name: "Whether Z-Healing is waiting to apply", default: false }
end

class Battle::ActivePosition
  alias zmove_initialize initialize  
  def initialize
    zmove_initialize
    @effects[PBEffects::ZHealing] = false
  end
end


################################################################################
#
# Battle
#
################################################################################

class Battle
  #-----------------------------------------------------------------------------
  # Aliased to reapply the user's Encore after executing a Z-Move.
  #-----------------------------------------------------------------------------
  alias zmove_pbCanShowFightMenu? pbCanShowFightMenu?
  def pbCanShowFightMenu?(idxBattler)
    battler = @battlers[idxBattler]
    if !battler.effects[PBEffects::EncoreRestore].empty?
      battler.effects[PBEffects::Encore]     = battler.effects[PBEffects::EncoreRestore][0]
      battler.effects[PBEffects::EncoreMove] = battler.effects[PBEffects::EncoreRestore][1]
      battler.effects[PBEffects::EncoreRestore].clear
    end
    return zmove_pbCanShowFightMenu?(idxBattler)
  end

  #-----------------------------------------------------------------------------
  # Aliased for the switch-in effect of Z-Memento/Z-Parting Shot.
  #-----------------------------------------------------------------------------
  alias zmove_pbEffectsOnBattlerEnteringPosition pbEffectsOnBattlerEnteringPosition
  def pbEffectsOnBattlerEnteringPosition(battler)
    position = @positions[battler.index]
    if position.effects[PBEffects::ZHealing]
      if battler.canHeal?
        pbCommonAnimation("HealingWish", battler)
        pbDisplay(_INTL("The Z-Power healed {1}!", battler.pbThis(true)))
        battler.pbRecoverHP(battler.totalhp)
        position.effects[PBEffects::ZHealing] = false
      elsif Settings::MECHANICS_GENERATION < 8
        position.effects[PBEffects::ZHealing] = false
      end
    end
    zmove_pbEffectsOnBattlerEnteringPosition(battler)
  end
  
  #-----------------------------------------------------------------------------
  # Resets to base moves if Z-Move was selected.
  #-----------------------------------------------------------------------------
  alias zmove_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    zmove_pbEndOfRoundPhase
    allBattlers.each do |battler|
      if battler.selectedMoveIsZMove
        battler.display_base_moves
        battler.selectedMoveIsZMove = false
      end
    end
  end
end


################################################################################
#
# Battle::Battler
#
################################################################################

class Battle::Battler
  attr_accessor :selectedMoveIsZMove # Checks if the user's selected move is considered a Z-Move.
  attr_accessor :lastMoveUsedIsZMove # Checks if a Z-Move was the user's last selected move (even if it failed to trigger).
  
  #-----------------------------------------------------------------------------
  # Aliased for initializing new effects and other properties.
  #-----------------------------------------------------------------------------
  alias zud_pbInitEffects pbInitEffects  
  def pbInitEffects(batonPass)                     
    @selectedMoveIsZMove = false
    @lastMoveUsedIsZMove = false
    @effects[PBEffects::EncoreRestore] = []
    zud_pbInitEffects(batonPass)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so that the Grudge effect fails on Z-Moves.
  #-----------------------------------------------------------------------------
  alias zmove_pbEffectsOnMakingHit pbEffectsOnMakingHit
  def pbEffectsOnMakingHit(move, user, target)
    if move.zMove? && target.opposes?(user) && target.fainted?
      target.effects[PBEffects::Grudge] = false
    end
    zmove_pbEffectsOnMakingHit(move, user, target)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so index of encored move is reset during the turn a Z-Move is used.
  #-----------------------------------------------------------------------------
  alias zmove_pbEncoredMoveIndex pbEncoredMoveIndex
  def pbEncoredMoveIndex
    if @battle.choices[self.index][0] == :UseMove && @battle.choices[self.index][2].zMove?
      turns = @effects[PBEffects::Encore]
      move  = @effects[PBEffects::EncoreMove]
      @effects[PBEffects::EncoreRestore] = [turns, move]
      return -1
    end
    zmove_pbEncoredMoveIndex
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so Z-Moves ignore most effects that would prevent move selection.
  #-----------------------------------------------------------------------------
  alias zmove_pbCanChooseMove? pbCanChooseMove?
  def pbCanChooseMove?(move, commandPhase, showMessages = true, specialUsage = false)
    if move.zMove?
      if @battle.field.effects[PBEffects::Gravity] > 0 && move.unusableInGravity?
        if showMessages
          msg = _INTL("{1} can't use {2} because of gravity!", pbThis, move.name)
          (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
        end
        return false
      end
      return false if !move.pbCanChooseMove?(self, commandPhase, showMessages)
      return true
    else
      return zmove_pbCanChooseMove?(move, commandPhase, showMessages, specialUsage)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Edited for allowing Z-Moves when called by other moves.
  #-----------------------------------------------------------------------------  
  def pbUseMoveSimple(moveID, target = -1, idxMove = -1, specialUsage = true)
    choice = []
    choice[0] = :UseMove
    choice[1] = idxMove
    if idxMove >= 0
      choice[2] = @moves[idxMove]
    else
      choice[2] = Battle::Move.from_pokemon_move(@battle, Pokemon::Move.new(moveID))
      choice[2].pp = -1
    end
    choice[3] = target
    PBDebug.log("[Move usage] #{pbThis} started using the called/simple move #{choice[2].name}")
    side  = (@battle.opposes?(self.index)) ? 1 : 0
    owner = @battle.pbGetOwnerIndexFromBattlerIndex(self.index)
    if @selectedMoveIsZMove && choice[2].damagingMove?
      @powerMoveIndex = choice[1]
      choice[2] = choice[2].convert_zmove(self, @battle, specialUsage)
      pbUseMove(choice, specialUsage)
    else
      pbUseMove(choice, specialUsage)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to set Z-Move properties upon using a move.
  #-----------------------------------------------------------------------------
  alias zmove_pbUseMove pbUseMove
  def pbUseMove(choice, specialUsage = false)
    @lastMoveUsedIsZMove = false
    if choice[2].zMove? & !choice[2].specialUseZMove
      @powerMoveIndex = choice[1]
      choice[2] = choice[2].convert_zmove(self, @battle, specialUsage)
    end
    zmove_pbUseMove(choice, specialUsage)
    if @lastMoveUsed && !@lastMoveUsedIsZMove
      @powerMoveIndex = -1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to flag user's last move as a Z-Move if successfully used.
  #-----------------------------------------------------------------------------
  alias zmove_pbTryUseMove pbTryUseMove 
  def pbTryUseMove(*args)
    ret = zmove_pbTryUseMove(*args)
    @lastMoveUsedIsZMove = ret if args[1].zMove?
    return ret 
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to indicate when a Z-Move was partially blocked by Protect.
  #-----------------------------------------------------------------------------
  alias zmove_pbEffectsAfterMove pbEffectsAfterMove
  def pbEffectsAfterMove(user, targets, move, numHits)
    if move.zMove? && move.damagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        next if !b.isProtected?(user, move)
        @battle.pbDisplay(_INTL("{1} couldn't fully protect itself and got hurt!", b.pbThis))
      end
    end
    zmove_pbEffectsAfterMove(user, targets, move, numHits)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to register a trainer's one Z-Move for this battle as being used.
  #-----------------------------------------------------------------------------
  alias zmove_pbEndTurn pbEndTurn
  def pbEndTurn(_choice)
    if _choice[0] == :UseMove && _choice[2].zMove?
      if @lastMoveUsedIsZMove
        side  = self.idxOwnSide
        owner = @battle.pbGetOwnerIndexFromBattlerIndex(@index)
        @battle.zMove[side][owner] = -2
      else 
        @battle.pbUnregisterZMove(@index)
      end
    end
    zmove_pbEndTurn(_choice)
  end
end