class Battle
  #=============================================================================
  # Running from battle
  #=============================================================================
  def pbCanRun?(idxBattler)
    return false if trainerBattle?
    battler = @battlers[idxBattler]
    return false if !@canRun && !battler.opposes?
    return true if battler.pbHasType?(:GHOST) && Settings::MORE_TYPE_EFFECTS
    return true if battler.abilityActive? &&
                   Battle::AbilityEffects.triggerCertainEscapeFromBattle(battler.ability, battler)
    return true if battler.itemActive? &&
                   Battle::ItemEffects.triggerCertainEscapeFromBattle(battler.item, battler)
    return false if battler.trappedInBattle?
    allOtherSideBattlers(idxBattler).each do |b|
      return false if b.abilityActive? &&
                      Battle::AbilityEffects.triggerTrappingByTarget(b.ability, battler, b, self)
      return false if b.itemActive? &&
                      Battle::ItemEffects.triggerTrappingByTarget(b.item, battler, b, self)
    end
    return true
  end

  # Return values:
  # -1: Chose not to end the battle via Debug means
  #  0: Couldn't end the battle via Debug means; carry on trying to run
  #  1: Ended the battle via Debug means
  def pbDebugRun
    return 0 if !$DEBUG || !Input.press?(Input::CTRL)
    commands = [_INTL("判为胜利"), _INTL("判为失败"),
                _INTL("判为平局"), _INTL("判为逃跑/认输")]
    commands.push(_INTL("判为捕获")) if wildBattle?
    commands.push(_INTL("取消"))
    case pbShowCommands(_INTL("选择这场对战的结果。"), commands)
    when 0   # Win
      @decision = 1
    when 1   # Loss
      @decision = 2
    when 2   # Draw
      @decision = 5
    when 3   # Run away/forfeit
      pbSEPlay("Battle flee")
      pbDisplayPaused(_INTL("顺利逃走了！"))
      @decision = 3
    when 4   # Capture
      return -1 if trainerBattle?
      @decision = 4
    else
      return -1
    end
    return 1
  end

  # Return values:
  # -1: Failed fleeing
  #  0: Wasn't possible to attempt fleeing, continue choosing action for the round
  #  1: Succeeded at fleeing, battle will end
  # duringBattle is true for replacing a fainted Pokémon during the End Of Round
  # phase, and false for choosing the Run command.
  def pbRun(idxBattler, duringBattle = false)
    battler = @battlers[idxBattler]
    if battler.opposes?
      return 0 if trainerBattle?
      @choices[idxBattler][0] = :Run
      @choices[idxBattler][1] = 0
      @choices[idxBattler][2] = nil
      return -1
    end
    # Debug ending the battle
    debug_ret = pbDebugRun
    return debug_ret if debug_ret != 0
    # Running from trainer battles
    if trainerBattle?
      if @internalBattle
        pbDisplayPaused(_INTL("不行！不能在对战中临阵脱逃！"))
      elsif pbDisplayConfirm(_INTL("你要认输并立即结束对战吗？"))
        pbSEPlay("Battle flee")
        pbDisplay(_INTL("{1}认输了！", self.pbPlayer.name))
        @decision = 3
        return 1
      end
      return 0
    end
    if !@canRun
      pbDisplayPaused(_INTL("无法逃走！"))
      return 0
    end
    if !duringBattle
      if battler.pbHasType?(:GHOST) && Settings::MORE_TYPE_EFFECTS
        pbSEPlay("Battle flee")
        pbDisplayPaused(_INTL("顺利逃走了！"))
        @decision = 3
        return 1
      end
      # Abilities that guarantee escape
      if battler.abilityActive? &&
         Battle::AbilityEffects.triggerCertainEscapeFromBattle(battler.ability, battler)
        pbShowAbilitySplash(battler, true)
        pbHideAbilitySplash(battler)
        pbSEPlay("Battle flee")
        pbDisplayPaused(_INTL("顺利逃走了！"))
        @decision = 3
        return 1
      end
      # Held items that guarantee escape
      if battler.itemActive? &&
         Battle::ItemEffects.triggerCertainEscapeFromBattle(battler.item, battler)
        pbSEPlay("Battle flee")
        pbDisplayPaused(_INTL("{1}使用其所携带的{2}逃走了！", battler.pbThis, battler.itemName))
        @decision = 3
        return 1
      end
      # Other certain trapping effects
      if battler.trappedInBattle?
        pbDisplayPaused(_INTL("无法逃走！"))
        return 0
      end
      # Trapping abilities/items
      allOtherSideBattlers(idxBattler).each do |b|
        next if !b.abilityActive?
        if Battle::AbilityEffects.triggerTrappingByTarget(b.ability, battler, b, self)
          pbDisplayPaused(_INTL("因{1}的{2}而无法逃走！", b.pbThis, b.abilityName))
          return 0
        end
      end
      allOtherSideBattlers(idxBattler).each do |b|
        next if !b.itemActive?
        if Battle::ItemEffects.triggerTrappingByTarget(b.item, battler, b, self)
          pbDisplayPaused(_INTL("因{1}的{2}而无法逃走！", b.pbThis, b.itemName))
          return 0
        end
      end
    end
    # Fleeing calculation
    # Get the speeds of the Pokémon fleeing and the fastest opponent
    # NOTE: Not pbSpeed, because using unmodified Speed.
    @runCommand += 1 if !duringBattle   # Make it easier to flee next time
    speedPlayer = @battlers[idxBattler].speed
    speedEnemy = 1
    allOtherSideBattlers(idxBattler).each do |b|
      speed = b.speed
      speedEnemy = speed if speedEnemy < speed
    end
    # Compare speeds and perform fleeing calculation
    if speedPlayer > speedEnemy
      rate = 256
    else
      rate = (speedPlayer * 128) / speedEnemy
      rate += @runCommand * 30
    end
    if rate >= 256 || @battleAI.pbAIRandom(256) < rate
      pbSEPlay("Battle flee")
      pbDisplayPaused(_INTL("顺利逃走了！"))
      @decision = 3
      return 1
    end
    pbDisplayPaused(_INTL("没能逃掉！"))
    return -1
  end
end
