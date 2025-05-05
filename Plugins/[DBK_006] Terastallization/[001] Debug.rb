#===============================================================================
# Debug menus.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_tera, {
  "name"        => _INTL("Toggle Terastallization"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("Toggles the availability of Terastallization functionality."),
  "effect"      => proc {
    $game_switches[Settings::NO_TERASTALLIZE] = !$game_switches[Settings::NO_TERASTALLIZE]
    toggle = ($game_switches[Settings::NO_TERASTALLIZE]) ? "disabled" : "enabled"
    pbMessage(_INTL("Terastallization {1}.", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :noTerastallize, {
  "name"        => "No Terastallize: [{1}]",
  "rule"        => "noTerastallize",
  "order"       => 309,
  "parent"      => :set_battle_rules,
  "description" => _INTL("Determines which side Terastallization is disabled for."),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noTerastallize", :Choose, [:All, :Player, :Opponent], 
      _INTL("Choose a side to disable Terastallization for."))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_plugin_settings, {
  "name"        => _INTL("Other plugin settings..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Settings for various features implemented by add-on plugins.")
})

MenuHandlers.add(:debug_menu, :deluxe_tera_settings, {
  "name"        => _INTL("Terastal settings..."),
  "parent"      => :deluxe_plugin_settings,
  "description" => _INTL("Edit the player's Tera Orb and Pokémon Tera types."),
  "effect"      => proc {
    loop do
      commands = [
        _INTL("Player's Tera Orb is charged [{1}]", ($player.tera_charged?)                             ? _INTL("YES") : _INTL("NO")),
        _INTL("Tera Orb has infinite charge [{1}]", ($game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]) ? _INTL("YES") : _INTL("NO")),
        _INTL("Randomize Pokémon Tera types [{1}]", ($game_switches[Settings::RANDOMIZED_TERA_TYPES])   ? _INTL("YES") : _INTL("NO"))
      ]
      command = pbShowCommands(nil, commands, -1, 0)
      break if command < 0
      case command
      when 0 # Tera Orb charge state
        $player.tera_charged = !$player.tera_charge
        toggle = ($player.tera_charged?) ? "charged" : "uncharged"
        pbMessage(_INTL("The player's Tera Orb is now {1}.", toggle))
      when 1 # Tera Orb charge mode
        $game_switches[Settings::TERA_ORB_ALWAYS_CHARGED] = !$game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]
        toggle = ($game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]) ? "no charging" : "charging"
        $player.tera_charged = true if $game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]
        pbMessage(_INTL("The player's Tera Orb now requires {1} between uses.", toggle))
      when 2 # Pokemon Tera types
        $game_switches[Settings::RANDOMIZED_TERA_TYPES] = !$game_switches[Settings::RANDOMIZED_TERA_TYPES]
        toggle = ($game_switches[Settings::RANDOMIZED_TERA_TYPES]) ? "randomized" : "their natural"
        pbMessage(_INTL("New Pokémon will now generate with {1} Tera types.", toggle))
      end
    end
  }
})


#-------------------------------------------------------------------------------
# Pokemon Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :deluxe_attributes, {
  "name"   => _INTL("Plugin attributes..."),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :deluxe_tera_attributes, {
  "name"   => _INTL("Terastal..."),
  "parent" => :deluxe_attributes,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      able = (pkmn.terastal_able?) ? "Yes" : "No"
      type = (pkmn.tera_type) ? GameData::Type.get(pkmn.tera_type).name : "---" 
      tera = (pkmn.tera?) ? "Yes" : "No"
      cmd = screen.pbShowCommands(_INTL("Eligible: {1}\nTera type: {2}\nTerastallized: {3}", able, type, tera),[
           _INTL("Set eligibility"),
           _INTL("Set Tera type"),
           _INTL("Set Terastallized"),
           _INTL("Reset All")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Eligibility
        if !pkmn.can_terastallize?
          pkmn.terastallized = false
          screen.pbDisplay(_INTL("{1} belongs to a species or form that cannot currently Terastallize.\nEligibility cannot be changed.", pkmn.name))
        elsif pkmn.terastal_able?
          pkmn.terastallized = false
          pkmn.terastal_able = false
          screen.pbDisplay(_INTL("{1} is no longer able to Terastallize.", pkmn.name))
        else
          pkmn.terastal_able = true
          screen.pbDisplay(_INTL("{1} is now able to Terastallize.", pkmn.name))
        end
        screen.pbRefreshSingle(pkmnid)
      when 1   # Set Tera type
        if pkmn.terastal_able?
          if !pkmn.getTeraType(true).nil?
            screen.pbDisplay(_INTL("{1}'s Tera type cannot be changed.", pkmn.name))
          else
            default = GameData::Type.get(pkmn.tera_type).icon_position
            newType = pbChooseTypeList(default < 10 ? default + 1 : default)
            if newType && newType != pkmn.tera_type
              pkmn.tera_type = newType
              screen.pbDisplay(_INTL("{1}'s Tera type is now {2}.", pkmn.name, GameData::Type.get(newType).name))
              screen.pbRefreshSingle(pkmnid)
            end
          end
        else
          screen.pbDisplay(_INTL("Can't edit Terastal values on that Pokémon."))
        end
      when 2   # Set Terastallized
        if pkmn.hasTerastalForm?
          screen.pbDisplay(_INTL("{1} changes form when Terastallized.\nThis may only occur in battle.", pkmn.name))
        elsif pkmn.terastal_able?
          if pkmn.tera?
            pkmn.terastallized = false
            screen.pbDisplay(_INTL("{1} is no longer Terastallized.", pkmn.name))
          else
            pkmn.terastallized = true
            screen.pbDisplay(_INTL("{1} is now Terastallized.", pkmn.name))
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("Can't edit Terastal values on that Pokémon."))
        end
      when 3   # Reset All
        pkmn.terastallized = false
        pkmn.terastal_able = nil
        pkmn.tera_type = nil
        screen.pbDisplay(_INTL("All Terastal settings restored to default."))
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})


#-------------------------------------------------------------------------------
# Battle Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_debug_menu, :deluxe_battle_tera, {
  "name"        => _INTL("Terastallization"),
  "parent"      => :trainers,
  "description" => _INTL("Whether each trainer is allowed to Terastallize."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      commands = []
      cmds = []
      battle.terastallize.each_with_index do |side_values, side|
        trainers = (side == 0) ? battle.player : battle.opponent
        next if !trainers
        side_values.each_with_index do |value, i|
          next if !trainers[i]
          text = (side == 0) ? "Your side:" : "Foe side:"
          text += sprintf(" %d: %s", i, trainers[i].name)
          if side == 0 && i == 0
            case value
            when -1
              if !$player.tera_charged?
                charge = false
                text += sprintf(" [UNABLE]")
              else
                charge = true 
                text += sprintf(" [ABLE]")
              end
            when -2
              charge = false
              text += sprintf(" [UNABLE]")
            end
          else
            case value
            when -1 
              charge = true
              text += sprintf(" [ABLE]")
            when -2
              charge = false
              text += sprintf(" [UNABLE]")
            end
          end
          commands.push(text)
          cmds.push([side, i, charge])
        end
      end
      cmd = pbMessage("\\ts[]" + _INTL("Choose trainer to toggle whether they can Terastallize."),
                      commands, -1, nil, cmd)
      break if cmd < 0
      real_cmd = cmds[cmd]
      if real_cmd[2]
        battle.terastallize[real_cmd[0]][real_cmd[1]] = -2   # Make unable
      else
        battle.terastallize[real_cmd[0]][real_cmd[1]] = -1   # Make able
        $player.tera_charged = true if real_cmd == [0, 0, false]
      end
    end
  }
})


#-------------------------------------------------------------------------------
# Battle Pokemon Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_pokemon_debug_menu, :set_terastal, {
  "name"   => _INTL("Terastal values"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      type = (pkmn.tera_type) ? GameData::Type.get(pkmn.tera_type).name : "---" 
      able = (pkmn.terastal_able?) ? "Can" : "Cannot"
      tera = (pkmn.tera?)          ? "Is"  : "Is not"
      msg = _INTL("{1} Terastallize [Type: {2}]\n{3} currently Terastallized.", able, type, tera)
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("Set eligibility"),
                       _INTL("Set Tera type"),
                       _INTL("Set Terastal state"),
                       _INTL("Reset")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Set eligibility
        if !pkmn.can_terastallize?
          pkmn.terastallized = false
          pbMessage("\\ts[]" + _INTL("{1} belongs to a species or form that cannot currently Terastallize.\nEligibility cannot be changed.", pkmn.name))
          battler&.pbUpdate
        elsif pkmn.terastal_able?
          pkmn.terastallized = false
          pkmn.terastal_able = false
          pbMessage("\\ts[]" + _INTL("{1} is no longer able to Terastallize.", pkmn.name))
          battler&.pbUpdate
        else
          pkmn.terastal_able = true
          pbMessage("\\ts[]" + _INTL("{1} is now able to Terastallize.", pkmn.name))
        end
      when 1   # Set Tera type
        if pkmn.terastal_able?
          if !pkmn.getTeraType(true).nil?
            pbMessage("\\ts[]" + _INTL("{1}'s Tera type cannot be changed.", pkmn.name))
          else
            default = GameData::Type.get(pkmn.tera_type).icon_position
            newType = pbChooseTypeList(default < 10 ? default + 1 : default)
            if newType && newType != pkmn.tera_type
              pkmn.tera_type = newType
              pbMessage("\\ts[]" + _INTL("{1}'s Tera type is now {2}.", pkmn.name, GameData::Type.get(newType).name))
              battler&.pbUpdate
            end
          end
        else
          pbMessage("\\ts[]" + _INTL("Can't edit Terastal values on that Pokémon."))
        end
      when 2   # Set Terastal state
        if pkmn.terastal_able?
          if pkmn.tera?
            pkmn.terastallized = false
            pbMessage("\\ts[]" + _INTL("{1} is no longer Terastallized.", pkmn.name))
          else
            if battler
              illusion = battler.effects[PBEffects::Illusion]
              if illusion && (illusion.hasTerastalForm? || pkmn.hasTerastalForm?)
                battler.effects[PBEffects::Illusion] = nil
              end
              if battler.tera_type == :STELLAR
                side  = battler.idxOwnSide
                owner = battle.pbGetOwnerIndexFromBattlerIndex(battler.index)
                GameData::Type.each do |t| 
                  next if t.pseudo_type
                  next if battle.boosted_tera_types[side][owner].include?(t.id)
                  battle.boosted_tera_types[side][owner].push(t.id)
                end
              end
            end
            pkmn.terastallized = true
            pbMessage("\\ts[]" + _INTL("{1} is now Terastallized.", pkmn.name))
          end
          battler&.pbUpdate
        else
          pbMessage("\\ts[]" + _INTL("Can't edit Terastal values on that Pokémon."))
        end
      when 3   # Reset
        pkmn.terastallized = false
        pkmn.terastal_able = nil
        pkmn.tera_type = nil
		battler&.pbUpdate
        pbMessage("\\ts[]" + _INTL("All Terastal settings restored to default."))
      end
    end
  }
})