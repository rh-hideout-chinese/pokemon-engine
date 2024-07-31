################################################################################
# 
# DLC item handlers.
# 
################################################################################

#===============================================================================
# Health Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:HPUP, :HEALTHMOCHI)
ItemHandlers::UseOnPokemon.copy(:HPUP, :HEALTHMOCHI)

#===============================================================================
# Muscle Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:PROTEIN, :MUSCLEMOCHI)
ItemHandlers::UseOnPokemon.copy(:PROTEIN, :MUSCLEMOCHI)

#===============================================================================
# Resist Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:IRON, :RESISTMOCHI)
ItemHandlers::UseOnPokemon.copy(:IRON, :RESISTMOCHI)

#===============================================================================
# Genius Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:CALCIUM, :GENIUSMOCHI)
ItemHandlers::UseOnPokemon.copy(:CALCIUM, :GENIUSMOCHI)

#===============================================================================
# Clever Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:ZINC, :CLEVERMOCHI)
ItemHandlers::UseOnPokemon.copy(:ZINC, :CLEVERMOCHI)

#===============================================================================
# Swift Mochi
#===============================================================================
ItemHandlers::UseOnPokemonMaximum.copy(:CARBOS, :SWIFTMOCHI)
ItemHandlers::UseOnPokemon.copy(:CARBOS, :SWIFTMOCHI)

#===============================================================================
# Fresh-Start Mochi
#===============================================================================
ItemHandlers::UseOnPokemon.add(:FRESHSTARTMOCHI, proc { |item, qty, pkmn, scene|
  next false if pkmn.ev.values.none? { |ev| ev > 0 }
  GameData::Stat.each_main { |s| pkmn.ev[s.id] = 0 }
  pkmn.changeHappiness("vitamin")
  pkmn.calc_stats
  pbSEPlay("Use item in party")
  scene.pbRefresh
  scene.pbDisplay(_INTL("{1}的努力值全部重置为零了！", pkmn.name))
  next true
})

#===============================================================================
# Fairy Feather
#===============================================================================
Battle::ItemEffects::DamageCalcFromUser.copy(:PIXIEPLATE, :FAIRYFEATHER)

#===============================================================================
# Wellspring Mask, Hearthflame Mask, Cornerstone Mask
#===============================================================================
Battle::ItemEffects::DamageCalcFromUser.add(:WELLSPRINGMASK,
  proc { |item, user, target, move, mults, power, type|
    mults[:final_damage_multiplier] *= 1.2 if user.isSpecies?(:OGERPON)
  }
)

Battle::ItemEffects::DamageCalcFromUser.copy(:WELLSPRINGMASK, :HEARTHFLAMEMASK, :CORNERSTONEMASK)


#===============================================================================
# Meteorite
#===============================================================================
ItemHandlers::UseOnPokemon.add(:METEORITE, proc { |item, qty, pkmn, scene|
  if !pkmn.isSpecies?(:DEOXYS)
    scene.pbDisplay(_INTL("没有效果。"))
    next false
  elsif pkmn.fainted?
    scene.pbDisplay(_INTL("不能给倒下的宝可梦使用。"))
    next false
  end
  choices = [
    _INTL("一般形态"),
    _INTL("攻击形态"),
    _INTL("防御形态"),
    _INTL("速度形态"),
    _INTL("取消")
  ]
  new_form = scene.pbShowCommands(_INTL("{1}应该变成哪一个形态？", pkmn.name), choices, pkmn.form)
  if new_form == pkmn.form
    scene.pbDisplay(_INTL("即便使用也无效果哦。"))
    next false
  elsif new_form > -1 && new_form < choices.length - 1
    pkmn.setForm(new_form) do
      scene.pbRefresh
      scene.pbDisplay(_INTL("{1}的样子发生了变化！", pkmn.name))
    end
    next true
  end
  next false
})