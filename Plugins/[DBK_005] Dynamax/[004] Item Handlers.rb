#===============================================================================
# Item handlers.
#===============================================================================

#-------------------------------------------------------------------------------
# Dynamax Candy/XL
#-------------------------------------------------------------------------------
# Increases the Dynamax Level of a Pokemon by 1. The XL variety maxes out this 
# level instead. This won't have any effect on Pokemon that are incapable of
# Dynamaxing or may only Dynamax into an Eternamax form.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:DYNAMAXCANDY, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon? || pkmn.egg?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pkmn.dynamax_lvl < 10 && pkmn.dynamax_able? && !pkmn.hasEternamaxForm?
    pbSEPlay("Pkmn move learnt")
    if item == :DYNAMAXCANDYXL
      scene.pbDisplay(_INTL("{1}'s Dynamax level was increased to 10!", pkmn.name))
      $stats.total_dynamax_lvls_gained += (10 - pkmn.dynamax_lvl)
      pkmn.dynamax_lvl = 10
    else
      scene.pbDisplay(_INTL("{1}'s Dynamax level was increased by 1!", pkmn.name))
      $stats.total_dynamax_lvls_gained += 1
      pkmn.dynamax_lvl += 1
    end
    scene.pbHardRefresh
    next true
  else
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
})

ItemHandlers::UseOnPokemon.copy(:DYNAMAXCANDY, :DYNAMAXCANDYXL)

#-------------------------------------------------------------------------------
# Max Soup
#-------------------------------------------------------------------------------
# Toggles Gigantamax Factor if the species has a Gigantamax form.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.add(:MAXSOUP, proc { |item, qty, pkmn, scene|
  if pkmn.shadowPokemon? || pkmn.egg?
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
  if pkmn.hasGigantamaxForm?
    if pkmn.gmax_factor?
      pkmn.gmax_factor = false
      scene.pbDisplay(_INTL("{1} lost its Gigantamax energy.", pkmn.name))
    else
      pbSEPlay("Pkmn move learnt")
      pkmn.gmax_factor = true
      $stats.total_gmax_factors_given += 1
      scene.pbDisplay(_INTL("{1} is now bursting with Gigantamax energy!", pkmn.name))
    end
    scene.pbHardRefresh
    next true
  else
    scene.pbDisplay(_INTL("It won't have any effect."))
    next false
  end
})

#-------------------------------------------------------------------------------
# Wishing Star
#-------------------------------------------------------------------------------
# Restores your ability to use Dynamax if it was already used in battle. Using
# this item will take up your entire turn, and cannot be used if orders have
# already been given to a Pokemon. This item also can't be used if you still
# currently have a Dynamaxed Pokemon on the field.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Usability handler
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:WISHINGSTAR, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  side  = battler.idxOwnSide
  owner = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  band  = battle.pbGetDynamaxBandName(battler.index)      
  dmax  = false
  battle.eachSameSideBattler(battler) { |b| dmax = true if b.dynamax? }
  if !battle.pbHasDynamaxBand?(battler.index)
    scene.pbDisplay(_INTL("You don't have a {1} to charge!", band)) if showMessages
    next false
  elsif !firstAction
    scene.pbDisplay(_INTL("You can't use this item while issuing orders at the same time!")) if showMessages
    next false
  elsif dmax || battle.dynamax[side][owner] == -1
    scene.pbDisplay(_INTL("You don't need to recharge your {1} yet!", band)) if showMessages
    next false
  end
  next true
})

#-------------------------------------------------------------------------------
# Effect handler
#-------------------------------------------------------------------------------
ItemHandlers::UseInBattle.add(:WISHINGSTAR, proc { |item, battler, battle|
  side    = battler.idxOwnSide
  owner   = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  battle.dynamax[side][owner] = -1
  band    = battle.pbGetDynamaxBandName(battler.index)
  trainer = battle.pbGetOwnerName(battler.index)
  item    = GameData::Item.get(item).portion_name
  pbSEPlay(sprintf("Anim/Lucky Chant"))
  battle.pbDisplayPaused(_INTL("The {1} fully recharged {2}'s {3}!\n{2} can use Dynamax again!", item, trainer, band))
})