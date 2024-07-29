#===============================================================================
# All Battle::Battler code that has either been rewritten or aliased.
#===============================================================================
class Battle::Battler
  #-----------------------------------------------------------------------------
  # Aliased for initializing new properties and effects.
  #-----------------------------------------------------------------------------
  alias dynamax_pbInitEffects pbInitEffects  
  def pbInitEffects(batonPass)                   
    @effects[PBEffects::Dynamax] = (self.dynamax?) ? Settings::DYNAMAX_TURNS : 0
    @effects[PBEffects::MaxGuard] = false
    @effects[PBEffects::GMaxTrapping] = false if !batonPass
    trap_hash = {}
    @battle.allBattlers.each do |b|
      next if !b.effects[PBEffects::GMaxTrapping]
      trap_hash[b.index] = [b.effects[PBEffects::Trapping],
	                        b.effects[PBEffects::TrappingUser]]
    end
    dynamax_pbInitEffects(batonPass)
    if !trap_hash.empty?
      trap_hash.keys.each do |i|
        next if !@battle.battlers[i] || @battle.battlers[i].fainted?
        @battle.battlers[i].effects[PBEffects::Trapping] = trap_hash[i][0]
        @battle.battlers[i].effects[PBEffects::TrappingUser] = trap_hash[i][1]
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to un-Dynamax fainted battlers.
  #-----------------------------------------------------------------------------
  alias dynamax_pbFaint pbFaint
  def pbFaint(*args)
    self.unDynamax if dynamax? && fainted? && !@fainted
    dynamax_pbFaint(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to copy the appropriate base moves or Dynamax moves when Transforming.
  #-----------------------------------------------------------------------------
  alias dynamax_pbTransform pbTransform
  def pbTransform(target)
    dynamax_pbTransform(target)
    if target.dynamax? && !target.baseMoves.empty?
      @moves = target.baseMoves.clone
      eachMove { |m| m.pp = 5; m.total_pp = 5 }
    end
    self.display_dynamax_moves if dynamax?
    @battle.scene.pbRefreshOne(@index)
  end
  
  #-----------------------------------------------------------------------------
  # Edited to check the user's base moves too, if any.
  #-----------------------------------------------------------------------------
  def pbHasMove?(move_id)
    return false if !move_id
    if dynamax? && !@baseMoves.empty?
      @baseMoves.each { |m| return true if m.id == move_id }
    else
      eachMove { |m| return true if m.id == move_id }
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Edited so Imprison checks the user's base moves instead of Dynamax moves.
  #-----------------------------------------------------------------------------
  alias dynamax_pbCanChooseMove? pbCanChooseMove?
  def pbCanChooseMove?(move, commandPhase, showMessages = true, specialUsage = false)
    if move.dynamaxMove?
      baseMove = @baseMoves[move.index]
      if @battle.allOtherSideBattlers(@index).any? { |b| b.effects[PBEffects::Imprison] && b.pbHasMove?(baseMove.id) }
        if showMessages
          msg = _INTL("{1} can't use its sealed {2}!", pbThis, baseMove.name)
          (commandPhase) ? @battle.pbDisplayPaused(msg) : @battle.pbDisplay(msg)
        end
        return false
      end
    end
    return dynamax_pbCanChooseMove?(move, commandPhase, showMessages, specialUsage)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to convert Dynamax moves if an effect should force it to.
  #-----------------------------------------------------------------------------
  alias dynamax_pbUseMove pbUseMove
  def pbUseMove(choice, specialUsage = false)
    if choice[2].dynamaxMove?
      @powerMoveIndex = choice[1]
      choice[2] = choice[2].convert_dynamax_move(self, @battle)
    end
    dynamax_pbUseMove(choice, specialUsage)
    move = GameData::Move.try_get(@lastMoveUsed)
    if @lastMoveUsed && move && move.dynamaxMove?
      @powerMoveIndex = -1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to indicate when a Dynamax move was partially blocked by Protect.
  #-----------------------------------------------------------------------------
  alias dynamax_pbEffectsAfterMove pbEffectsAfterMove
  def pbEffectsAfterMove(user, targets, move, numHits)
    if move.dynamaxMove? && move.damagingMove?
      targets.each do |b|
        next if b.damageState.unaffected
        next if !b.isProtected?(user, move)
        @battle.pbDisplay(_INTL("{1} couldn't fully protect itself and got hurt!", b.pbThis))
      end
    end
    dynamax_pbEffectsAfterMove(user, targets, move, numHits)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so Grudge interacts properly with Dynamax targets.
  #-----------------------------------------------------------------------------
  alias dynamax_pbEffectsOnMakingHit pbEffectsOnMakingHit
  def pbEffectsOnMakingHit(move, user, target)
    if target.opposes?(user) && target.effects[PBEffects::Grudge] && target.fainted?
      if move.dynamaxMove?
        baseMove = user.baseMoves[move.index]
        user.pbSetPP(move, 0)
        user.pbSetPP(baseMove, 0)
        @battle.pbDisplay(_INTL("{1}'s {2} lost all of its PP due to the grudge!",
                              user.pbThis, baseMove.name))
        target.effects[PBEffects::Grudge] = false
      end
    end
    dynamax_pbEffectsOnMakingHit(move, user, target)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for Max Guard checks.
  #-----------------------------------------------------------------------------
  alias dynamax_pbSuccessCheckAgainstTarget pbSuccessCheckAgainstTarget
  def pbSuccessCheckAgainstTarget(move, user, target, targets)
    if !user.effects[PBEffects::TwoTurnAttack]
      if target.effects[PBEffects::MaxGuard] && !move.ignoresMaxGuard?
        if move.pbShowFailMessages?(targets)
          @battle.pbCommonAnimation("Protect", target)
          @battle.pbDisplay(_INTL("{1} protected itself!", target.pbThis))
        end
        target.damageState.protected = true
        @battle.successStates[user.index].protected = true
        return false
      end
    end
    return dynamax_pbSuccessCheckAgainstTarget(move, user, target, targets)
  end
end