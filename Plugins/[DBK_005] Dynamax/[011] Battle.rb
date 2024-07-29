#===============================================================================
# New PBEffects.
#===============================================================================
module PBEffects  
  #-----------------------------------------------------------------------------
  # Battler effects.
  #-----------------------------------------------------------------------------
  Dynamax      = 202  # The Dynamax state, and how many turns until it expires.
  MaxGuard     = 203  # The effect for the move Max Guard.
  GMaxTrapping = 204  # Flags a battler as being trapped by a G-Max move, and persists even if the trap user switches out.
  
  #-----------------------------------------------------------------------------
  # Effects that apply to a side.
  #-----------------------------------------------------------------------------
  VineLash     = 822  # The lingering effect of G-Max Vine Lash.
  Wildfire     = 823  # The lingering effect of G-Max Wildfire.
  Cannonade    = 824  # The lingering effect of G-Max Cannonade.
  Volcalith    = 825  # The lingering effect of G-Max Volcalith.
  Steelsurge   = 826  # The hazard effect of G-Max Steelsurge.
end

#-------------------------------------------------------------------------------
# Allows new effects to be set in the battle debug menu.
#-------------------------------------------------------------------------------
module Battle::DebugVariables
  BATTLER_EFFECTS[PBEffects::Dynamax]  = { name: "Dynamax number of rounds remaining", default: 0     }
  BATTLER_EFFECTS[PBEffects::MaxGuard] = { name: "Max Guard applies this round",       default: false }
  SIDE_EFFECTS[PBEffects::VineLash]    = { name: "G-Max Vine Lash duration",           default: 0     }
  SIDE_EFFECTS[PBEffects::Wildfire]    = { name: "G-Max Wildfire duration",            default: 0     }
  SIDE_EFFECTS[PBEffects::Cannonade]   = { name: "G-Max Cannonade duration",           default: 0     }
  SIDE_EFFECTS[PBEffects::Volcalith]   = { name: "G-Max Volcalith duration",           default: 0     }
  SIDE_EFFECTS[PBEffects::Steelsurge]  = { name: "G-Max Steelsurge exists",            default: false }
end

#-------------------------------------------------------------------------------
# Initializes new effects.
#-------------------------------------------------------------------------------
class Battle::ActiveSide
  alias dynamax_initialize initialize  
  def initialize
    dynamax_initialize
    @effects[PBEffects::Cannonade]  = 0
    @effects[PBEffects::Steelsurge] = false
    @effects[PBEffects::VineLash]   = 0
    @effects[PBEffects::Volcalith]  = 0
    @effects[PBEffects::Wildfire]   = 0
  end
end


#===============================================================================
# Changes to the Battle class.
#===============================================================================
class Battle  
  #-----------------------------------------------------------------------------
  # Aliased for the hazard effect of G-Max Steelsurge.
  #-----------------------------------------------------------------------------
  alias dynamax_pbEntryHazards pbEntryHazards
  def pbEntryHazards(battler)
    dynamax_pbEntryHazards(battler)
    battler_side = battler.pbOwnSide
    if battler_side.effects[PBEffects::Steelsurge] && battler.takesIndirectDamage? &&
       GameData::Type.exists?(:STEEL) && !battler.hasActiveItem?(:HEAVYDUTYBOOTS)
      eff = Effectiveness.calculate(:STEEL, *battler.pbTypes(true))
      if !Effectiveness.ineffective?(eff)
        eff = eff.to_f / Effectiveness::NORMAL_EFFECTIVE
        battler.pbReduceHP(battler.totalhp * eff / 8, false)
        pbDisplay(_INTL("The sharp steel bit into {1}!", battler.pbThis(true)))
        battler.pbItemHPHealCheck
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for the end of round damage for certain G-Max move effects.
  #-----------------------------------------------------------------------------
  alias dynamax_pbEORSeaOfFireDamage pbEORSeaOfFireDamage
  def pbEORSeaOfFireDamage(priority)
    dynamax_pbEORSeaOfFireDamage(priority)
    2.times do |side|
      #-------------------------------------------------------------------------
      # G-Max Vine Lash
      if @sides[side].effects[PBEffects::VineLash] > 0
        if @scene.pbCommonAnimationExists?("VineLash")
          pbCommonAnimation("VineLash") if side == 0
          pbCommonAnimation("VineLashOpp") if side == 1
        end
        priority.each do |battler|
          next if battler.opposes?(side)
          next if !battler.takesIndirectDamage? || battler.pbHasType?(:GRASS)
          @scene.pbDamageAnimation(battler)
          movename = GameData::Move.get(:GMAXVINELASH).name
          battler.pbTakeEffectDamage(battler.totalhp / 6, false) { |hp_lost|
            pbDisplay(_INTL("{1} is hurt by {2}'s ferocious beating!", battler.pbThis, movename))
          }
        end
      end
      #-------------------------------------------------------------------------
      # G-Max Wildfire
      if @sides[side].effects[PBEffects::Wildfire] > 0
        if @scene.pbCommonAnimationExists?("Wildfire")
          pbCommonAnimation("Wildfire") if side == 0
          pbCommonAnimation("WildfireOpp") if side == 1
        end
        priority.each do |battler|
          next if battler.opposes?(side)
          next if !battler.takesIndirectDamage? || battler.pbHasType?(:FIRE)
          @scene.pbDamageAnimation(battler)
          movename = GameData::Move.get(:GMAXWILDFIRE).name
          battler.pbTakeEffectDamage(battler.totalhp / 6, false) { |hp_lost|
            pbDisplay(_INTL("{1} is burning up within {2}'s flames!", battler.pbThis, movename))
          }
        end
      end
      #-------------------------------------------------------------------------
      # G-Max Cannonade
      if @sides[side].effects[PBEffects::Cannonade] > 0
        if @scene.pbCommonAnimationExists?("Cannonade")
          pbCommonAnimation("Cannonade") if side == 0
          pbCommonAnimation("CannonadeOpp") if side == 1
        end
        priority.each do |battler|
          next if battler.opposes?(side)
          next if !battler.takesIndirectDamage? || battler.pbHasType?(:WATER)
          @scene.pbDamageAnimation(battler)
          movename = GameData::Move.get(:GMAXCANNONADE).name
          battler.pbTakeEffectDamage(battler.totalhp / 6, false) { |hp_lost|
            pbDisplay(_INTL("{1} is hurt by {2}'s vortex!", battler.pbThis, movename))
          }
        end
      end
      #-------------------------------------------------------------------------
      # G-Max Volcalith
      if @sides[side].effects[PBEffects::Volcalith] > 0
        if @scene.pbCommonAnimationExists?("Volcalith")
          pbCommonAnimation("Volcalith") if side == 0
          pbCommonAnimation("VolcalithOpp") if side == 1
        end
        priority.each do |battler|
          next if battler.opposes?(side)
          next if !battler.takesIndirectDamage? || battler.pbHasType?(:ROCK)
          @scene.pbDamageAnimation(battler)
          movename = GameData::Move.get(:GMAXVOLCALITH).name
          battler.pbTakeEffectDamage(battler.totalhp / 6, false) { |hp_lost|
            pbDisplay(_INTL("{1} is hurt by the rocks thrown out by {2}!", battler.pbThis, movename))
          }
        end
      end
    end
  end
  
  alias dynamax_pbEOREndSideEffects pbEOREndSideEffects
  def pbEOREndSideEffects(side, priority)
    dynamax_pbEOREndSideEffects(side, priority)
    # Vine Lash
    movename = GameData::Move.get(:GMAXVINELASH).name
    pbEORCountDownSideEffect(side, PBEffects::VineLash,
                             _INTL("{1} was released from {2}'s beating!", @battlers[side].pbTeam, movename))
    # Wildfire
    movename = GameData::Move.get(:GMAXWILDFIRE).name
    pbEORCountDownSideEffect(side, PBEffects::Wildfire,
                             _INTL("{1} was released from {2}'s flames!", @battlers[side].pbTeam, movename))
    # Cannonade
    movename = GameData::Move.get(:GMAXCANNONADE).name
    pbEORCountDownSideEffect(side, PBEffects::Cannonade,
                             _INTL("{1} was released from {2}'s vortex!", @battlers[side].pbTeam, movename))
    # Volcalith
    movename = GameData::Move.get(:GMAXVOLCALITH).name
    pbEORCountDownSideEffect(side, PBEffects::Volcalith,
                             _INTL("Rocks stopped being thrown out by {1} on {2}!", movename, @battlers[side].pbTeam(true)))
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for ending Dynamax. (End of round)
  #-----------------------------------------------------------------------------
  alias dynamax_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    if @decision > 0
      allBattlers.each do |battler|
        next if battler.isRaidBoss?
        battler.effects[PBEffects::Dynamax] -= 1
        battler.unDynamax if battler.effects[PBEffects::Dynamax] == 0
      end
      return
    end
    dynamax_pbEndOfRoundPhase
    return if @decision > 0
    allBattlers.each do |battler|
      battler.effects[PBEffects::MaxGuard] = false
      next if !battler.dynamax?
      if battler.pbOwnedByPlayer? && battler.moves.any? { |m| !m.dynamaxMove? }
        battler.display_dynamax_moves
      end
      battler.effects[PBEffects::Dynamax] -= 1 if battler.effects[PBEffects::Dynamax] > 0
      next if battler.isRaidBoss?
      battler.unDynamax if battler.effects[PBEffects::Dynamax] == 0
    end
  end

  #-----------------------------------------------------------------------------
  # Aliased for ending Dynamax. (Switching)
  #-----------------------------------------------------------------------------
  alias dynamax_pbRecallAndReplace pbRecallAndReplace
  def pbRecallAndReplace(*args)
    idxBattler = args[0]
    @battlers[idxBattler].unDynamax if @battlers[idxBattler].dynamax?
    dynamax_pbRecallAndReplace(*args)
  end
  
  alias dynamax_pbSwitchInBetween pbSwitchInBetween
  def pbSwitchInBetween(*args)
    idxBattler = args[0]
    ret = dynamax_pbSwitchInBetween(*args)
    @battlers[idxBattler].unDynamax if @battlers[idxBattler].dynamax? && ret > -1
    return ret 
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for ending Dynamax. (End of battle)
  #-----------------------------------------------------------------------------
  alias dynamax_pbEndOfBattle pbEndOfBattle
  def pbEndOfBattle
    @battlers.each { |b| b.unDynamax if b&.dynamax? }
    dynamax_pbEndOfBattle
  end
end


#===============================================================================
# Changes to the Battle::Scene class.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Aliased to apply Dynamax pattern to battler sprites.
  #-----------------------------------------------------------------------------
  alias dynamax_pbChangePokemon pbChangePokemon
  def pbChangePokemon(idxBattler, pkmn)
    pkmn = pbGetDynamaxPokemon(idxBattler, pkmn)
    dynamax_pbChangePokemon(idxBattler, pkmn)
  end
  
  def pbGetDynamaxPokemon(idxBattler, pkmn)
    battler = (idxBattler.respond_to?("index")) ? idxBattler : @battle.battlers[idxBattler]
    if !pbInSafari? && battler.pokemon.personalID != pkmn.personalID
      newPkmn             = Pokemon.new(pkmn.species, pkmn.level)
      newPkmn.gender      = pkmn.gender
      newPkmn.shiny       = pkmn.shiny?
      newPkmn.super_shiny = pkmn.super_shiny?
      newPkmn.gmax_factor = battler.gmax_factor?
      newPkmn.dynamax     = battler.dynamax?
      newPkmn.makeShadow if pkmn.shadowPokemon?
      return newPkmn
    end
    return pkmn
  end
  
  #-----------------------------------------------------------------------------
  # Edited to allow for enlarged/colored Dynamax sprites.
  #-----------------------------------------------------------------------------
  def pbAnimationCore(animation, user, target, oppMove = false)
    return if !animation
    @briefMessage = false
    userSprite   = (user) ? @sprites["pokemon_#{user.index}"] : nil
    targetSprite = (target) ? @sprites["pokemon_#{target.index}"] : nil
    oldUserX = (userSprite) ? userSprite.x : 0
    oldUserY = (userSprite) ? userSprite.y : 0
    oldTargetX = (targetSprite) ? targetSprite.x : oldUserX
    oldTargetY = (targetSprite) ? targetSprite.y : oldUserY
    #---------------------------------------------------------------------------
    # Applies Dynamax effects to sprites.
    #---------------------------------------------------------------------------
    if Settings::SHOW_DYNAMAX_SIZE
      oldUserZoomX   = (userSprite)   ? userSprite.zoom_x   : 1
      oldUserZoomY   = (userSprite)   ? userSprite.zoom_y   : 1
      oldTargetZoomX = (targetSprite) ? targetSprite.zoom_x : 1
      oldTargetZoomY = (targetSprite) ? targetSprite.zoom_y : 1
    end
    #---------------------------------------------------------------------------
    animPlayer = PBAnimationPlayerX.new(animation,user,target,self,oppMove)
    userHeight = (userSprite && userSprite.bitmap && !userSprite.bitmap.disposed?) ? userSprite.bitmap.height : 128
    if targetSprite
      targetHeight = (targetSprite.bitmap && !targetSprite.bitmap.disposed?) ? targetSprite.bitmap.height : 128
    else
      targetHeight = userHeight
    end
    animPlayer.setLineTransform(
      FOCUSUSER_X, FOCUSUSER_Y, FOCUSTARGET_X, FOCUSTARGET_Y,
      oldUserX, oldUserY - (userHeight / 2), oldTargetX, oldTargetY - (targetHeight / 2)
    )
    animPlayer.start
    loop do
      animPlayer.update
      #-------------------------------------------------------------------------
      # Updates Dynamax effects on sprites.
      #-------------------------------------------------------------------------
      if Settings::SHOW_DYNAMAX_SIZE
        userSprite.zoom_x   = oldUserZoomX   if userSprite
        userSprite.zoom_y   = oldUserZoomY   if userSprite
        targetSprite.zoom_x = oldTargetZoomX if targetSprite
        targetSprite.zoom_y = oldTargetZoomY if targetSprite
      end
      #-------------------------------------------------------------------------
      pbUpdate
      break if animPlayer.animDone?
    end
    animPlayer.dispose
    if userSprite
      userSprite.x = oldUserX
      userSprite.y = oldUserY
      userSprite.pbSetOrigin
    end
    if targetSprite
      targetSprite.x = oldTargetX
      targetSprite.y = oldTargetY
      targetSprite.pbSetOrigin
    end
  end
end