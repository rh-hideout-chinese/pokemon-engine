#===============================================================================
# Code related to utilizing Tera Shards.
#===============================================================================

#-------------------------------------------------------------------------------
# Gets Tera Shards data.
#-------------------------------------------------------------------------------
module GameData
  class Item
    def is_tera_shard?
      return !@flags.none? { |f| f[/^TeraShard_/i] }
    end
	
    def tera_shard_type
      return if !is_tera_shard?
      @flags.each do |f|
        next if !f[/^TeraShard_(\w+)/i]
        return $~[1].to_sym
      end
    end
  end
end


#-------------------------------------------------------------------------------
# Using Tera Shards from the Bag.
#-------------------------------------------------------------------------------
alias tera_pbUseItem pbUseItem
def pbUseItem(bag, item, bagscene = nil)
  itm = GameData::Item.get(item)
  if itm.field_use && itm.is_tera_shard?
    if $player.pokemon_count == 0
      pbMessage(_INTL("There is no Pokémon."))
      return 0
    end
    tera = itm.tera_shard_type
    qty = [1, Settings::TERA_SHARDS_REQUIRED].max
    qty = 1 if !GameData::Type.exists?(tera)
    if $bag.has?(item, qty)
      ret = false
      annot = []
      $player.party.each do |pkmn|
        elig = pkmn.tera_type != tera && pkmn.getTeraType(true).nil?
        annot.push((elig) ? _INTL("ABLE") : _INTL("NOT ABLE"))
      end
      pbFadeOutIn {
        scene = PokemonParty_Scene.new
        screen = PokemonPartyScreen.new(scene, $player.party)
        screen.pbStartScene(_INTL("Use on which Pokémon?"), false, annot)
        loop do
          scene.pbSetHelpText(_INTL("Use on which Pokémon?"))
          chosen = screen.pbChoosePokemon
          if chosen < 0
            ret = false
            break
          end
          pkmn = $player.party[chosen]
          next if !pbCheckUseOnPokemon(item, pkmn, screen)
          ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
          screen.pbRefreshAnnotations(proc { |p| p.tera_type != tera && p.getTeraType(true).nil? })
          next unless ret && itm.consumed_after_use?
          bag.remove(item, qty)
          next if bag.has?(item, qty)
          if qty == 1
            pbMessage(_INTL("You used your last {1}.", itm.portion_name)) { screen.pbUpdate }
          else
            pbMessage(_INTL("Not enough {1} remaining...", itm.portion_name_plural)) { screen.pbUpdate }
          end
          break
        end
        screen.pbEndScene
        bagscene&.pbRefresh
      }
      return (ret) ? 1 : 0
    else
      pbMessage(_INTL("You don't have enough {1}...\nYou need {2} shards to change a Pokémon's Tera type.", 
                itm.portion_name_plural, qty))
    end
  else
    return tera_pbUseItem(bag, item, bagscene)
  end
end


#-------------------------------------------------------------------------------
# Using Tera Shards from the Party Menu.
#-------------------------------------------------------------------------------
alias tera_pbUseItemOnPokemon pbUseItemOnPokemon
def pbUseItemOnPokemon(item, pkmn, scene)
  itm = GameData::Item.get(item)
  if itm.is_tera_shard?
    tera = itm.tera_shard_type
    qty = [1, Settings::TERA_SHARDS_REQUIRED].max
    qty = 1 if !GameData::Type.exists?(tera)
    if $bag.has?(item, qty)  
      ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, scene)
      scene.pbClearAnnotations
      scene.pbHardRefresh
      if ret
        $bag.remove(item, qty)
        if !$bag.has?(item, qty)
          if qty == 1
            pbMessage(_INTL("You used your last {1}.", itm.name)) { scene.pbUpdate }
          else
            pbMessage(_INTL("Not enough {1} remaining...", itm.portion_name_plural)) { scene.pbUpdate }
          end
        end
      end
      return ret
    else
      pbMessage(_INTL("You don't have enough {1}...\nYou need {2} shards to change a Pokémon's Tera type.", 
                itm.portion_name_plural, qty)) { scene.pbUpdate }
      return false
    end
  else
    return tera_pbUseItemOnPokemon(item, pkmn, scene)
  end
end


#-------------------------------------------------------------------------------
# Compatibility with the Bag Screen w/int. Party plugin.
#-------------------------------------------------------------------------------
if PluginManager.installed?("Bag Screen w/int. Party")
  class PokemonBag_Scene
    alias tera_pbUpdateAnnotation pbUpdateAnnotation
    def pbUpdateAnnotation
      item = @sprites["itemlist"].item
      item_data = GameData::Item.try_get(item)
      if item_data && item_data.is_tera_shard? && @bag.last_viewed_pocket == 1
        $player.party.each_with_index do |pkmn, i|
          elig = pkmn.tera_type != item_data.tera_shard_type
          annotation = (elig) ? _INTL("ABLE") : _INTL("UNABLE")
          @sprites["pokemon#{i}"].text = annotation
        end
      else
        tera_pbUpdateAnnotation
      end
    end
  end
  
  def pbBagUseItem(bag, item, scene, screen, chosen, bagscene=nil)
    itm     = GameData::Item.get(item)
    useType = itm.field_use
    found   = false
    pkmn    = $player.party[chosen]
    if itm.is_machine?    # TM, HM or TR
      if $player.pokemon_count == 0
        pbMessage(_INTL("There is no Pokémon.")) { screen.pbUpdate }
        return 0
      end
      machine = itm.move
      return 0 if !machine
      movename = GameData::Move.get(machine).name
      move     = GameData::Move.get(machine).id
      movelist = nil; bymachine = false; oneusemachine = false
      if movelist != nil && movelist.is_a?(Array)
        for i in 0...movelist.length
          movelist[i] = GameData::Move.get(movelist[i]).id
        end
      end
      if pkmn.egg?
        pbMessage(_INTL("Eggs can't be taught any moves.")) { screen.pbUpdate }
      elsif pkmn.shadowPokemon?
        pbMessage(_INTL("Shadow Pokémon can't be taught any moves.")) { screen.pbUpdate }
      elsif movelist && !movelist.any? { |j| j == pkmn.species }
        pbMessage(_INTL("{1} can't learn {2}.", pkmn.name, movename)) { screen.pbUpdate }
      elsif !pkmn.compatible_with_move?(move)
        pbMessage(_INTL("{1} can't learn {2}.", pkmn.name, movename)) { screen.pbUpdate }
      else
        if pbLearnMove(pkmn, move, false, bymachine) { screen.pbUpdate }
          pkmn.add_first_move(move) if oneusemachine
          bag.remove(itm) if itm.consumed_after_use?
        end
      end
      screen.pbRefresh; screen.pbUpdate
      return 1
    elsif useType == 1
      if $player.pokemon_count == 0
        pbMessage(_INTL("There is no Pokémon.")) { screen.pbUpdate }
        return 0
      end
      qty = 1
      ret = false
      screen.pbRefresh
      if itm.is_tera_shard?
        tera = itm.tera_shard_type
        qty = [1, Settings::TERA_SHARDS_REQUIRED].max
        qty = 1 if !GameData::Type.exists?(tera)
        if !$bag.has?(item, qty)
          pbMessage(_INTL("You don't have enough {1}..." +
                          "\nYou need {2} Tera Shards to change a Pokémon's Tera Type.", itm.portion_name_plural, qty))
          return 0
        end
      end
      if pbCheckUseOnPokemon(item, pkmn, screen)
        ret = ItemHandlers.triggerUseOnPokemon(item, qty, pkmn, screen)
        if ret && useType == 1
          $bag.remove(item, qty)  if itm.consumed_after_use? { screen.pbRefresh }
        end
        if !$bag.has?(item)
          if itm.is_tera_shard? && qty > 1
            screen.pbDisplay(_INTL("Not enough {1} remaining...", itm.portion_name_plural)) { screen.pbUpdate }
          else
            screen.pbDisplay(_INTL("You used your last {1}.", itm.portion_name)) { screen.pbUpdate }
          end
          screen.pbChangeCursor(2)
        end
        screen.pbRefresh
      end
      bagscene.pbRefresh if bagscene
      return 1
    else
      pbMessage(_INTL("Can't use that here.")) { screen.pbUpdate }
      return 0
    end
  end
end


#-------------------------------------------------------------------------------
# Tera Shards - Changes a Pokemon's Tera Type.
#-------------------------------------------------------------------------------
ItemHandlers::UseOnPokemon.addIf(:tera_shards,
  proc { |item| GameData::Item.get(item).is_tera_shard? },
  proc { |item, qty, pkmn, scene|
    old_tera = pkmn.tera_type
    type = GameData::Item.get(item).tera_shard_type
    if type && pkmn.tera_type != type && pkmn.getTeraType(true).nil? && !pkmn.shadowPokemon?
      case type
      when :Random
        pkmn.tera_type = :Random
      when :Choose
        scene.pbDisplay(_INTL("Select a new Tera type for {1}.", pkmn.name))
        default = GameData::Type.get(pkmn.tera_type).icon_position
        newType = pbChooseTypeList(default < 10 ? default + 1 : default)
        next false if !newType.is_a?(Symbol)
        if newType != pkmn.tera_type && ![:QMARKS, :SHADOW].include?(newType)
          pkmn.tera_type = newType
        end
      else
        data = GameData::Type.try_get(type)
        if data && !data.pseudo_type && ![:QMARKS, :SHADOW].include?(type)
          pkmn.tera_type = type
        end
      end
    end
    if pkmn.tera_type != old_tera
      scene.pbDisplay(_INTL("{1}'s Tera type is now {2}.", pkmn.name, GameData::Type.get(pkmn.tera_type).name))
      $stats.total_tera_types_changed += 1
      scene.pbHardRefresh
      next true
    else
      scene.pbDisplay(_INTL("It won't have any effect."))
      next false
    end
  }
)


#-------------------------------------------------------------------------------
# Radiant Tera Jewel
#-------------------------------------------------------------------------------
# Restores your ability to use Terastallization if it was already used in battle.
# Using this item will take up your entire turn, and cannot be used if orders have
# already been given to a Pokemon.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Usability handler
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:RADIANTTERAJEWEL, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  side  = battler.idxOwnSide
  owner = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  orb   = battle.pbGetTeraOrbName(battler.index)      
  if !battle.pbHasTeraOrb?(battler.index)
    scene.pbDisplay(_INTL("You don't have a {1} to charge!", orb)) if showMessages
    next false
  elsif !firstAction
    scene.pbDisplay(_INTL("You can't use this item while issuing orders at the same time!")) if showMessages
    next false
  elsif battle.terastallize[side][owner] == -1 || (side == 0 && owner == 0 && $player.tera_charged?)
    scene.pbDisplay(_INTL("You don't need to recharge your {1} yet!", orb)) if showMessages
    next false
  end
  next true
})

#-------------------------------------------------------------------------------
# Effect handler
#-------------------------------------------------------------------------------
ItemHandlers::UseInBattle.add(:RADIANTTERAJEWEL, proc { |item, battler, battle|
  side    = battler.idxOwnSide
  owner   = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
  battle.terastallize[side][owner] = -1
  $player.tera_charged = true if side == 0 && owner == 0
  orb     = battle.pbGetTeraOrbName(battler.index)
  trainer = battle.pbGetOwnerName(battler.index)
  item    = GameData::Item.get(item).portion_name
  pbSEPlay(sprintf("Anim/Lucky Chant"))
  battle.pbDisplayPaused(_INTL("The {1} fully recharged {2}'s {3}!\n{2} can use Terastallization again!", item, trainer, orb))
})