class Battle
  #=============================================================================
  # Shifting a battler to another position in a battle larger than double
  #=============================================================================
  def pbCanShift?(idxBattler)
    return false if pbSideSize(0) <= 2 && pbSideSize(1) <= 2   # Double battle or smaller
    idxOther = -1
    case pbSideSize(idxBattler)
    when 1
      return false   # Only one battler on that side
    when 2
      idxOther = (idxBattler + 2) % 4
    when 3
      return false if [2, 3].include?(idxBattler)   # In middle spot already
      idxOther = (idxBattler.even?) ? 2 : 3
    end
    return false if pbGetOwnerIndexFromBattlerIndex(idxBattler) != pbGetOwnerIndexFromBattlerIndex(idxOther)
    return true
  end

  def pbRegisterShift(idxBattler)
    @choices[idxBattler][0] = :Shift
    @choices[idxBattler][1] = 0
    @choices[idxBattler][2] = nil
    return true
  end

  #=============================================================================
  # Calling at a battler
  #=============================================================================
  def pbRegisterCall(idxBattler)
    @choices[idxBattler][0] = :Call
    @choices[idxBattler][1] = 0
    @choices[idxBattler][2] = nil
    return true
  end

  def pbCall(idxBattler)
    # Debug ending the battle
    return if pbDebugRun != 0
    # Call the battler
    battler = @battlers[idxBattler]
    trainerName = pbGetOwnerName(idxBattler)
    pbDisplay(_INTL("{1}呼唤了{2}！", trainerName, battler.pbThis(true)))
    pbDisplay(_INTL("{1}！", battler.name))
    if battler.shadowPokemon?
      if battler.inHyperMode?
        battler.pokemon.hyper_mode = false
        battler.pokemon.change_heart_gauge("call")
        pbDisplay(_INTL("在训练家的呼唤下，{1}清醒过来了！", battler.pbThis))
      else
        pbDisplay(_INTL("但是，什么也没有发生！"))
      end
    elsif battler.status == :SLEEP
      battler.pbCureStatus
    elsif battler.pbCanRaiseStatStage?(:ACCURACY, battler)
      battler.pbRaiseStatStage(:ACCURACY, 1, battler)
      battler.pbItemOnStatDropped
    else
      pbDisplay(_INTL("但是，什么也没有发生！"))
    end
  end

  #=============================================================================
  # Choosing to Mega Evolve a battler
  #=============================================================================
  def pbHasMegaRing?(idxBattler)
    if pbOwnedByPlayer?(idxBattler)
      @mega_rings.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @mega_rings.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end

  def pbGetMegaRingName(idxBattler)
    if !@mega_rings.empty?
      if pbOwnedByPlayer?(idxBattler)
        @mega_rings.each { |item| return GameData::Item.get(item).name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @mega_rings.each { |item| return GameData::Item.get(item).name if trainer_items&.include?(item) }
      end
    end
    return _INTL("超级环")
  end

  def pbCanMegaEvolve?(idxBattler)
    return false if $game_switches[Settings::NO_MEGA_EVOLUTION]
    return false if !@battlers[idxBattler].hasMega?
    return false if @battlers[idxBattler].wild?
    return true if $DEBUG && Input.press?(Input::CTRL)
    return false if @battlers[idxBattler].effects[PBEffects::SkyDrop] >= 0
    return false if !pbHasMegaRing?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @megaEvolution[side][owner] == -1
  end

  def pbRegisterMegaEvolution(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = idxBattler
  end

  def pbUnregisterMegaEvolution(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -1 if @megaEvolution[side][owner] == idxBattler
  end

  def pbToggleRegisteredMegaEvolution(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @megaEvolution[side][owner] == idxBattler
      @megaEvolution[side][owner] = -1
    else
      @megaEvolution[side][owner] = idxBattler
    end
  end

  def pbRegisteredMegaEvolution?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @megaEvolution[side][owner] == idxBattler
  end

  #=============================================================================
  # Mega Evolving a battler
  #=============================================================================
  def pbMegaEvolve(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasMega? || battler.mega?
    $stats.mega_evolution_count += 1 if battler.pbOwnedByPlayer?
    trainerName = pbGetOwnerName(idxBattler)
    old_ability = battler.ability_id
    # Break Illusion
    if battler.hasActiveAbility?(:ILLUSION)
      Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
    end
    # Mega Evolve
    case battler.pokemon.megaMessage
    when 1   # Rayquaza
      pbDisplay(_INTL("{1}衷心的祈愿传递到了{2}那里！", trainerName, battler.pbThis))
    else
      pbDisplay(_INTL("{1}的{2}和{3}的{4}起了反应！",
                      battler.pbThis, battler.itemName, trainerName, pbGetMegaRingName(idxBattler)))
    end
    pbCommonAnimation("MegaEvolution", battler)
    battler.pokemon.makeMega
    battler.form = battler.pokemon.form
    battler.pbUpdate(true)
    @scene.pbChangePokemon(battler, battler.pokemon)
    @scene.pbRefreshOne(idxBattler)
    pbCommonAnimation("MegaEvolution2", battler)
    megaName = battler.pokemon.megaName
    megaName = _INTL("超级{1}", battler.pokemon.speciesName) if nil_or_empty?(megaName)
    pbDisplay(_INTL("{1}超级进化成了{2}", battler.pbThis, megaName))
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @megaEvolution[side][owner] = -2
    if battler.isSpecies?(:GENGAR) && battler.mega?
      battler.effects[PBEffects::Telekinesis] = 0
    end
    # Trigger ability
    battler.pbOnLosingAbility(old_ability)
    battler.pbTriggerAbilityOnGainingIt
    # Recalculate turn order
    pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
  end

  #=============================================================================
  # Primal Reverting a battler
  #=============================================================================
  def pbPrimalReversion(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon || battler.fainted?
    return if !battler.hasPrimal? || battler.primal?
    if battler.isSpecies?(:KYOGRE)
      pbCommonAnimation("PrimalKyogre", battler)
    elsif battler.isSpecies?(:GROUDON)
      pbCommonAnimation("PrimalGroudon", battler)
    end
    battler.pokemon.makePrimal
    battler.form = battler.pokemon.form
    battler.pbUpdate(true)
    @scene.pbChangePokemon(battler, battler.pokemon)
    @scene.pbRefreshOne(idxBattler)
    if battler.isSpecies?(:KYOGRE)
      pbCommonAnimation("PrimalKyogre2", battler)
    elsif battler.isSpecies?(:GROUDON)
      pbCommonAnimation("PrimalGroudon2", battler)
    end
    pbDisplay(_INTL("{1}的原始回归！\n恢复了原始的样子！", battler.pbThis))
  end
end
