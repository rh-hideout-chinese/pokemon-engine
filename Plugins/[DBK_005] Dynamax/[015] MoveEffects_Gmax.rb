################################################################################
#
# Moves that lower the stats of Pokemon on the opponent's side.
#
################################################################################

#===============================================================================
# G-Max Foamburst
#===============================================================================
# Lowers the Speed of the Pokemon on the opponent's side by 2 stages.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideSpeed2 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:SPEED, 2]
  end
end

#===============================================================================
# G-Max Tartness
#===============================================================================
# Lowers the Evasion of the Pokemon on the opponent's side by 1 stage.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerTargetSideEva1 < Battle::DynamaxMove::TargetSideStatDownMove
  def initialize(battle, move)
    super
    @statDown = [:EVASION, 1]
  end
end


################################################################################
#
# Moves that inflict status conditions.
#
################################################################################

#===============================================================================
# G-Max Malodor
#===============================================================================
# Poisons the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::PoisonTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:POISON]
  end
end

#===============================================================================
# G-Max Volt Crash
#===============================================================================
# Paralyzes the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::ParalyzeTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:PARALYSIS]
  end
end

#===============================================================================
# G-Max Stun Shock
#===============================================================================
# Randomly poisons or paralyzes the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::PoisonOrParalyzeTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:POISON, :PARALYSIS]
  end
end

#===============================================================================
# G-Max Befuddle
#===============================================================================
# Randomly poisons, paralyzes or puts to sleep the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::PoisonParalyzeOrSleepTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:POISON, :PARALYSIS, :SLEEP]
  end
end

#===============================================================================
# G-Max Cuddle
#===============================================================================
# Infatuates the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::InfatuateTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:INFATUATION]
  end
end

#===============================================================================
# G-Max Smite
#===============================================================================
# Confuses the Pokemon on the opponent's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::ConfuseTargetSide < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:CONFUSE]
  end
end

#===============================================================================
# G-Max Goldrush
#===============================================================================
# Confuses the Pokemon on the opponent's side. Gains money at the end of battle.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::ConfuseTargetSideAddMoney < Battle::DynamaxMove::TargetSideStatusEffectMove
  def initialize(battle, move)
    super
    @statuses = [:CONFUSE]
  end
  
  def pbEffectAfterAllHits(user, target)
    super
    @battle.field.effects[PBEffects::PayDay] += 100 * user.level
    @battle.pbDisplay(_INTL("金币散落一地!"))
  end
end

#===============================================================================
# G-Max Snooze
#===============================================================================
# May make the target drowsy, causing it to fall asleep at the end of the next turn.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetSleepTargetNextTurn < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if target.fainted?
    return if !target.pbCanSleep?(user, true, self)
    return if target.effects[PBEffects::Yawn] > 0
    return if @battle.pbRandom(100) < 50
    target.effects[PBEffects::Yawn] = 2
    @battle.pbDisplay(_INTL("{1}昏昏欲睡了!", target.pbThis))
  end
end


################################################################################
#
# Moves that start effects on one side.
#
################################################################################

#===============================================================================
# G-Max Vine Lash
#===============================================================================
# Starts the Vine Lash effect on the opposing side for 4 turns.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartVineLashOnFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::VineLash] > 0
    user.pbOpposingSide.effects[PBEffects::VineLash] = 4
    @battle.pbDisplay(_INTL("{1}被藤蔓困住了!", user.pbOpposingTeam))
  end
end

#===============================================================================
# G-Max Wildfire
#===============================================================================
# Starts the Wildfire effect on the opposing side for 4 turns.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartWildfireOnFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::Wildfire] > 0
    user.pbOpposingSide.effects[PBEffects::Wildfire] = 4
    @battle.pbDisplay(_INTL("{1}被火焰包围了!", user.pbOpposingTeam))
  end
end

#===============================================================================
# G-Max Cannonade
#===============================================================================
# Starts the Cannonade effect on the opposing side for 4 turns.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartCannonadeOnFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::Cannonade] > 0
    user.pbOpposingSide.effects[PBEffects::Cannonade] = 4
    @battle.pbDisplay(_INTL("{1}被水流漩涡困住了!", user.pbOpposingTeam))
  end
end

#===============================================================================
# G-Max Volcalith
#===============================================================================
# Starts the Volcalith effect on the opposing side for 4 turns.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::StartVolcalithOnFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::Volcalith] > 0
    user.pbOpposingSide.effects[PBEffects::Volcalith] = 4
    @battle.pbDisplay(_INTL("{1}被岩石包围了!", user.pbOpposingTeam))
  end
end

#===============================================================================
# G-Max Stonesurge
#===============================================================================
# Entry hazard. Lays stealth rocks on the opposing side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetAddStealthRocksToFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::StealthRock]
    user.pbOpposingSide.effects[PBEffects::StealthRock] = true
    @battle.pbDisplay(_INTL("尖锐的岩石在,{1}周围的空中漂浮!", user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# G-Max Steelsurge
#===============================================================================
# Entry hazard. Lays sharp steel on the opposing side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetAddSteelsurgeToFoeSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOpposingSide.effects[PBEffects::Steelsurge]
    user.pbOpposingSide.effects[PBEffects::Steelsurge] = true
    @battle.pbDisplay(_INTL("尖锐的钢刺开始在{1}的,周围漂浮!", user.pbOpposingTeam(true)))
  end
end

#===============================================================================
# G-Max Resonance
#===============================================================================
# For 5 rounds, lowers power of attacks against the user's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartWeakenDamageAgainstUserSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if user.pbOwnSide.effects[PBEffects::AuroraVeil] > 0
    user.pbOwnSide.effects[PBEffects::AuroraVeil] = 5
    user.pbOwnSide.effects[PBEffects::AuroraVeil] = 8 if user.hasActiveItem?(:LIGHTCLAY)
    @battle.pbDisplay(_INTL("{1}变得更能抵抗物攻和特攻了!", user.pbTeam))
  end
end


################################################################################
#
# Moves that apply effects on battlers.
#
################################################################################

#===============================================================================
# G-Max Chi Strike
#===============================================================================
# Pokemon on the user's side have their critical hit rate heightened.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::UserSideCriticalBoost1 < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.allSameSideBattlers(user).each do |b|
	  next if b.effects[PBEffects::FocusEnergy] >= 4
      b.effects[PBEffects::FocusEnergy] += 1
      @battle.pbDisplay(_INTL("{1}变得更容易命中要害了!", b.pbThis))
    end
  end
end

#===============================================================================
# G-Max Meltdown
#===============================================================================
# Pokemon on the opponent's side become subjected to Torment.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DisableTargetSideUsingSameMoveConsecutively < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.allOtherSideBattlers(user).each do |b|
      next if b.effects[PBEffects::Torment]
      b.effects[PBEffects::Torment] = true
      @battle.pbDisplay(_INTL("{1}受到了折磨!", b.pbThis))
      b.pbItemStatusCureCheck
    end
  end
end

#===============================================================================
# G-Max Terror
#===============================================================================
# Pokemon on the opponent's side cannot switch or flee while the user is active.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::TrapTargetSideInBattle < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.allOtherSideBattlers(user).each do |b|
      next if b.effects[PBEffects::MeanLook] == user.index
      next if Settings::MORE_TYPE_EFFECTS && b.pbHasType?(:GHOST)
      @battle.pbDisplay(_INTL("{1}不能再逃脱了!", b.pbThis))
      b.effects[PBEffects::MeanLook] = user.index
    end
  end
end

#===============================================================================
# G-Max Centiferno, G-Max Sand Blast
#===============================================================================
# Trapping move. Traps for 4 or 5 rounds. Trapped Pokémon lose 1/8 of max HP
# at end of each round. Trapping effect persists even upon the user switching out.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::BindTargetSideUserCanSwitch < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    case @type
    when :NORMAL then moveid = :BIND
    when :WATER  then moveid = :WHIRLPOOL
    when :FIRE   then moveid = :FIRESPIN
    when :BUG    then moveid = :INFESTATION
    when :GROUND then moveid = :SANDTOMB
    end
    @battle.allOtherSideBattlers(user).each do |b|
      next if b.effects[PBEffects::Trapping] > 0
      b.effects[PBEffects::Trapping] = 4 + @battle.pbRandom(2)
      b.effects[PBEffects::Trapping] = 7 if user.hasActiveItem?(:GRIPCLAW)
      b.effects[PBEffects::TrappingMove] = moveid
      b.effects[PBEffects::TrappingUser] = user.index
      b.effects[PBEffects::GMaxTrapping] = true
      case moveid
      when :BIND
        msg = _INTL("{1}被{2}挤压了!", b.pbThis, user.pbThis(true))
      when :FIRESPIN
        msg = _INTL("{1}被火焰漩涡困住了", b.pbThis)
      when :INFESTATION
        msg = _INTL("{1}被{2}的“超极巨蝶影蛊惑”,缠上了!", b.pbThis, user.pbThis(true))
      when :SANDTOMB
        msg = _INTL("{1}被沙岩困住了!", b.pbThis)
      when :WHIRLPOOL
        msg = _INTL("{1}被水流漩涡困住了!", b.pbThis)
      else
        msg = _INTL("{1}被漩涡困住了!", b.pbThis)
      end
      @battle.pbDisplay(msg)
    end
  end
end


################################################################################
#
# Moves that heal battler's HP or status.
#
################################################################################

#===============================================================================
# G-Max Sweetness
#===============================================================================
# Cures the status conditions of all Pokemon on the user's side.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::CureStatusConditionsUsersSide < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    @battle.allSameSideBattlers(user).each { |b| b.pbCureStatus }
  end
end

#===============================================================================
# G-Max Finale
#===============================================================================
# Pokemon on the user's side gain 1/6th of their total HP. 
# Doesn't scale down when healing Dynamaxed Pokemon.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::HealUserSideOneSixthOfTotalHP < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    @battle.allSameSideBattlers(user).each do |b|
      next if b.hp == b.totalhp
      next if b.effects[PBEffects::HealBlock] > 0
      b.stopBoostedHPScaling = true
      b.pbRecoverHP(b.totalhp / 6.0)
    end
  end
end


################################################################################
#
# Other moves.
#
################################################################################

#===============================================================================
# G-Max Drum Solo, G-Max Fireball, G-Max Hydrosnipe
#===============================================================================
# Ignores the target's Ability.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::IgnoreTargetAbility < Battle::Move::IgnoreTargetAbility
end

#===============================================================================
# G-Max Replenish
#===============================================================================
# Pokemon on the user's side may recover consumed berries.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RestoreUserSideConsumedBerries < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    @battle.allSameSideBattlers(user).each do |b|
      next if !b.recycleItem || !GameData::Item.get(b.recycleItem).is_berry?
      next if @battle.pbRandom(2) < 1
      b.item = b.recycleItem
      b.setRecycleItem(nil)
      b.setInitialItem(b.item) if !b.initialItem
      @battle.pbDisplay(_INTL("{1}找到了一个{2}!", b.pbThis, b.itemName))	  
      b.pbHeldItemTriggerCheck
    end
  end
end

#===============================================================================
# G-Max Depletion
#===============================================================================
# Pokemon on the opponent's side lose 2 PP for their last used move.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::LowerPPOfTargetSideLastMoveBy2 < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    return if target.pokemon.immunities.include?(:PPLOSS)
    @battle.allOtherSideBattlers(user).each do |b|
      next if !b.lastRegularMoveUsed
      showMsg = false
      if b.powerMoveIndex >= 0
        last_move = b.moves[b.powerMoveIndex]
        if b.dynamax?
          base_move = b.baseMoves[b.powerMoveIndex]
          if base_move && base_move.pp > 0
            reduction = [2, base_move.pp].min
            b.pbSetPP(base_move, base_move.pp - reduction)
            showMsg = true
          end
        end
      else
        last_move = b.pbGetMoveWithID(b.lastRegularMoveUsed)
      end
      if last_move && last_move.pp > 0
        reduction = [2, last_move.pp].min
        b.pbSetPP(last_move, last_move.pp - reduction)
        showMsg = true
      end
      @battle.pbDisplay(_INTL("{1}的PP减少了!", b.pbThis)) if showMsg
    end
  end
end

#===============================================================================
# G-Max Gravitas
#===============================================================================
# Starts gravity.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::DamageTargetStartGravity < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    @battle.field.effects[PBEffects::Gravity] = 5
    @battle.pbDisplay(_INTL("环境里的重力加强了!"))
    @battle.allBattlers.each do |b|
      showMessage = false
      if b.inTwoTurnAttack?("TwoTurnAttackInvulnerableInSky",
                            "TwoTurnAttackInvulnerableInSkyParalyzeTarget",
                            "TwoTurnAttackInvulnerableInSkyTargetCannotAct")
        b.effects[PBEffects::TwoTurnAttack] = nil
        @battle.pbClearChoice(b.index) if !b.movedThisRound?
        showMessage = true
      end
      if b.effects[PBEffects::MagnetRise] > 0 ||
         b.effects[PBEffects::Telekinesis] > 0 ||
         b.effects[PBEffects::SkyDrop] >= 0
        b.effects[PBEffects::MagnetRise]  = 0
        b.effects[PBEffects::Telekinesis] = 0
        b.effects[PBEffects::SkyDrop]     = -1
        showMessage = true
      end
      if showMessage
        @battle.pbDisplay(_INTL("{1}由于重力无法保持在空中!", b.pbThis))
      end
    end
  end
end

#===============================================================================
# G-Max Wind Rage
#===============================================================================
# Removes terrain and entry hazards from the entire field. Also removes barriers 
# from the opponent's side only.
#-------------------------------------------------------------------------------
class Battle::DynamaxMove::RemoveSideEffectsAndTerrain < Battle::DynamaxMove::Move
  def pbEffectAfterAllHits(user, target)
    return if !super
    return if @battle.pbAllFainted?(target.idxOwnSide)
    msg_check = []
    side_effects = [
      [PBEffects::Spikes,      0,     _INTL("{1}吹走了尖刺！", user.pbThis)],
      [PBEffects::ToxicSpikes, 0,     _INTL("{1}吹走了毒刺！", user.pbThis)],
      [PBEffects::StealthRock, false, _INTL("{1}吹走了隐形岩！", user.pbThis)],
      [PBEffects::Steelsurge,  false, _INTL("{1}吹走了尖锐的钢铁！", user.pbThis)],
      [PBEffects::StickyWeb,   false, _INTL("{1}吹走了粘网！", user.pbThis)]
    ]
    side_effects.each do |effect|
      next if user.pbOwnSide.effects[effect[0]] == effect[1]
      user.pbOwnSide.effects[effect[0]] = effect[1]
      @battle.pbDisplay(effect[2]) if effect[2]
      msg_check.push(effect[0])
    end
    side_effects.push(
      [PBEffects::AuroraVeil,  0, _INTL("{1}的极光幕消失了！", user.pbOpposingTeam)],
      [PBEffects::LightScreen, 0, _INTL("{1}的光墙消失了！", user.pbOpposingTeam)],
      [PBEffects::Reflect,     0, _INTL("{1}的反射壁消失了！", user.pbOpposingTeam)],
      [PBEffects::Mist,        0, _INTL("{1}的白雾消失了！", user.pbOpposingTeam)],
      [PBEffects::Safeguard,   0, _INTL("{1}不再受到神秘守护保护！", user.pbOpposingTeam)]
    )
    side_effects.each do |effect|
      next if user.pbOpposingSide.effects[effect[0]] == effect[1]
      user.pbOpposingSide.effects[effect[0]] = effect[1]
      next if msg_check.include?(effect[0])
      @battle.pbDisplay(effect[2]) if effect[2]
    end
    if @battle.field.terrain != :None
      case @battle.field.terrain
      when :Electric then @battle.pbDisplay(_INTL("电气场地消失了。"))
      when :Grassy   then @battle.pbDisplay(_INTL("青草场地效果消失了。"))
      when :Misty    then @battle.pbDisplay(_INTL("薄雾场地消失了"))
      when :Psychic  then @battle.pbDisplay(_INTL("精神场地消失了"))
      else                @battle.pbDisplay(_INTL("场地恢复正常。")) 
      end
      @battle.field.terrain = :None
    end
  end
end