#===============================================================================
# Adds Dynamax-related tools to debug options.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_dynamax, {
  "name"        => _INTL("Toggle Dynamax"),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Toggles the availability of Dynamax functionality."),
  "effect"      => proc {
    $game_switches[Settings::NO_DYNAMAX] = !$game_switches[Settings::NO_DYNAMAX]
    toggle = ($game_switches[Settings::NO_DYNAMAX]) ? "disabled" : "enabled"
    pbMessage(_INTL("Dynamax {1}.", toggle))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_dynamax_settings, {
  "name"        => _INTL("Dynamax settings..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Edit when and where Dynamax is able to be used."),
  "effect"      => proc {
    loop do
      commands = [
        _INTL("Dynamax usable on every map [{1}]",    ($game_switches[Settings::DYNAMAX_ON_ANY_MAP])      ? _INTL("YES") : _INTL("NO")),
        _INTL("Dynamax usable in wild battles [{1}]", ($game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]) ? _INTL("YES") : _INTL("NO"))
      ]
      command = pbShowCommands(nil, commands, -1, 0)
      break if command < 0
      case command
      when 0
        $game_switches[Settings::DYNAMAX_ON_ANY_MAP] = !$game_switches[Settings::DYNAMAX_ON_ANY_MAP]
        if $game_switches[Settings::DYNAMAX_ON_ANY_MAP]
          pbMessage(_INTL("Dynamax is now usable on every map."))
        else
          pbMessage(_INTL("Dynamax is now only usable on maps with the 'PowerSpot' flag."))
        end
      when 1
        $game_switches[Settings::DYNAMAX_IN_WILD_BATTLES] = !$game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]
        if $game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]
          pbMessage(_INTL("Dynamax is now also usable in wild battles."))
        else
          pbMessage(_INTL("Dynamax is now only usable in trainer battles."))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :deluxe_dynamax_metrics, {
  "name"        => _INTL("Dynamax metrics..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Reposition Pokémon Dynamax sprites displayed in battle."),
  "effect"      => proc {
    if Settings::SHOW_DYNAMAX_SIZE
      loop do
        commands = [
          _INTL("Edit Dynamax metrics"),
          _INTL("Auto-set Dynamax metrics")
        ]
        command = pbShowCommands(nil, commands, -1, 0)
        break if command < 0
        case command
        when 0  # Edit Dynamax metrics
          filterCommands = [_INTL("All sprites"), _INTL("Gigantamax sprites"), _INTL("Sprites by generation...")]
          filterCommand = pbMessage(_INTL("Which sprites do you want to edit?"), filterCommands, -1)
          next if filterCommand < 0
          case filterCommand
          when 1
            filterCommand = -1
          when 2
            params = ChooseNumberParams.new
            params.setRange(1, 99)
            params.setDefaultValue(1)
            params.setCancelValue(-1)
            filterCommand = pbMessageChooseNumber(_INTL("Select a generation."), params)
          end
          styleCommands = [_INTL("Half back sprites (Gen 4 style)"), _INTL("Full back sprites (Gen 5 style)")]
          styleCommand = pbMessage(_INTL("What style of back sprites are you using?"), styleCommands, -1)
          next if styleCommand < 0
          pbFadeOutIn {
            scene = DynamaxSpritePositioner.new
            scene.setSpriteFilter(filterCommand)
            scene.setBackSpriteStyle(styleCommand)
            screen = DynamaxSpritePositionerScreen.new(scene)
            screen.pbStart
          }
        when 1  # Auto-set Dynamax metrics
          if pbConfirmMessage(_INTL("Are you sure you want to automatically reposition all Dynamax sprites?"))
            styleCommands = [_INTL("Half back sprites (Gen 4 style)"), _INTL("Full back sprites (Gen 5 style)")]
            styleCommand = pbMessage(_INTL("What style of back sprites are you using?"), styleCommands, -1)
            next if styleCommand < 0
            msgwindow = pbCreateMessageWindow
            pbMessageDisplay(msgwindow, _INTL("Repositioning all Dynamax sprites. Please wait."), false)
            Graphics.update
            pbDynamaxAutoPositionAll(styleCommand)
            pbDisposeMessageWindow(msgwindow)
          end
        end
      end
    else
      pbMessage(_INTL("SHOW_DYNAMAX_SIZE is set to 'false', so no Dynamax metrics need to be set."))
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

MenuHandlers.add(:pokemon_debug_menu, :deluxe_dynamax_attributes, {
  "name"   => _INTL("Dynamax..."),
  "parent" => :deluxe_attributes,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      able = (pkmn.dynamax_able?) ? "Yes" : "No"
      dlvl = pkmn.dynamax_lvl
      gmax = (pkmn.gmax_factor?)  ? "Yes" : "No" 
      dmax = (pkmn.dynamax?)      ? "Yes" : "No"
      cmd = screen.pbShowCommands(_INTL("Eligible: {1}\nDynamax Level: {2}\nG-Max Factor: {3}\nDynamaxed: {4}", able, dlvl, gmax, dmax),[
           _INTL("Set eligibility"),
           _INTL("Set Dynamax Level"),
           _INTL("Set G-Max Factor"),
           _INTL("Set Dynamax"),
           _INTL("Reset All")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Eligibility
        if !pkmn.can_dynamax?
          pkmn.dynamax = false
          screen.pbDisplay(_INTL("{1} belongs to a species or form that cannot currently use Dynamax.\nEligibility cannot be changed.", pkmn.name))
        elsif pkmn.dynamax_able?
          pkmn.dynamax = false
          pkmn.dynamax_lvl = 0
          pkmn.gmax_factor = false
          pkmn.dynamax_able = false
          screen.pbDisplay(_INTL("{1} is no longer able to use Dynamax.", pkmn.name))
        else
          pkmn.dynamax_able = true
          screen.pbDisplay(_INTL("{1} is now able to use Dynamax.", pkmn.name))
        end
        screen.pbRefreshSingle(pkmnid)
      when 1   # Set Dynamax Level
        if pkmn.dynamax_able?
          params = ChooseNumberParams.new
          params.setRange(0, 10)
          params.setDefaultValue(pkmn.dynamax_lvl)
          params.setCancelValue(pkmn.dynamax_lvl)
          f = pbMessageChooseNumber(
            _INTL("Set {1}'s Dynamax level (max. 10).", pkmn.name), params) { screen.pbUpdate }
          if f != pkmn.dynamax_lvl
            pkmn.dynamax_lvl = f
            pkmn.calc_stats
            screen.pbRefreshSingle(pkmnid)
          end
        else
          screen.pbDisplay(_INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 2   # Set G-Max Factor
        if pkmn.dynamax_able?
          if pkmn.gmax_factor?
            pkmn.gmax_factor = false
            screen.pbDisplay(_INTL("Gigantamax factor was removed from {1}.", pkmn.name))
          else
            if pkmn.hasGigantamaxForm?
              pkmn.gmax_factor = true
              screen.pbDisplay(_INTL("Gigantamax factor was given to {1}.", pkmn.name))
            else
              if pbConfirmMessage(_INTL("{1} doesn't have a Gigantamax form.\nGive it Gigantamax factor anyway?", pkmn.name))
                pkmn.gmax_factor = true
                screen.pbDisplay(_INTL("Gigantamax factor was given to {1}.", pkmn.name))
              end
            end
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 3   # Set Dynamax
        if pkmn.dynamax_able?
          if pkmn.dynamax?
            pkmn.dynamax = false
            screen.pbDisplay(_INTL("{1} is no longer Dynamaxed.", pkmn.name))
          else
            pkmn.dynamax = true
            screen.pbDisplay(_INTL("{1} is now Dynamaxed.", pkmn.name))
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 4   # Reset All
        pkmn.dynamax = false
        pkmn.dynamax_lvl = 0
        pkmn.gmax_factor = false
        pkmn.dynamax_able = nil
        screen.pbDisplay(_INTL("All Dynamax settings restored to default."))
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})


#-------------------------------------------------------------------------------
# Battle Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_debug_menu, :deluxe_battle_dynamax, {
  "name"        => _INTL("Dynamax"),
  "parent"      => :trainers,
  "description" => _INTL("Whether each trainer is allowed to Dynamax."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      commands = []
      cmds = []
      battle.dynamax.each_with_index do |side_values, side|
        trainers = (side == 0) ? battle.player : battle.opponent
        next if !trainers
        side_values.each_with_index do |value, i|
          next if !trainers[i]
          text = (side == 0) ? "Your side:" : "Foe side:"
          text += sprintf(" %d: %s", i, trainers[i].name)
          text += sprintf(" [ABLE]") if value == -1
          text += sprintf(" [UNABLE]") if value == -2
          commands.push(text)
          cmds.push([side, i])
        end
      end
      cmd = pbMessage("\\ts[]" + _INTL("Choose trainer to toggle whether they can Dynamax."),
                      commands, -1, nil, cmd)
      break if cmd < 0
      real_cmd = cmds[cmd]
      if battle.dynamax[real_cmd[0]][real_cmd[1]] == -1
        battle.dynamax[real_cmd[0]][real_cmd[1]] = -2   # Make unable
      else
        battle.dynamax[real_cmd[0]][real_cmd[1]] = -1   # Make able
      end
    end
  }
})


#-------------------------------------------------------------------------------
# Battle Pokemon Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_pokemon_debug_menu, :set_dynamax, {
  "name"   => _INTL("Dynamax values"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      dlvl = pkmn.dynamax_lvl
      able = (pkmn.dynamax_able?) ? "Can" : "Cannot"
      gmax = (pkmn.gmax_factor?)  ? "Yes" : "No" 
      dmax = (pkmn.dynamax?)      ? "Is"  : "Is not"
      msg = _INTL("{1} Dynamax [Lvl: {2}] [G-Max: {3}]\n{4} currently Dynamaxed.", able, dlvl, gmax, dmax)
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("Set eligibility"),
                       _INTL("Set Dynamax Lvl"),
                       _INTL("Set G-Max Factor"),
                       _INTL("Set Dynamax state"),
                       _INTL("Reset")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Set eligibility
        if !pkmn.can_dynamax?
          pkmn.dynamax = false
          pbMessage("\\ts[]" + _INTL("{1} belongs to a species or form that cannot currently use Dynamax.\nEligibility cannot be changed.", pkmn.name))
          battler&.pbUpdate
        elsif pkmn.dynamax_able?
          pkmn.gmax_factor = false
          pkmn.dynamax = false
          pkmn.dynamax_lvl = 0
          pkmn.dynamax_able = false
          pbMessage("\\ts[]" + _INTL("{1} is no longer able to use Dynamax.", pkmn.name))
          battler&.display_base_moves
          battler&.pbUpdate
        else
          pkmn.dynamax_able = true
          pbMessage("\\ts[]" + _INTL("{1} is now able to use Dynamax.", pkmn.name))
        end
      when 1   # Set Dynamax Lvl
        if pkmn.dynamax_able?
          params = ChooseNumberParams.new
          params.setRange(0, 10)
          params.setDefaultValue(pkmn.dynamax_lvl)
          params.setCancelValue(pkmn.dynamax_lvl)
          f = pbMessageChooseNumber(
            "\\ts[]" + _INTL("Set {1}'s Dynamax level (max. 10).", pkmn.name), params
          )
          if f != pkmn.dynamax_lvl
            pkmn.dynamax_lvl = f
            pkmn.calc_stats
            battler&.pbUpdate
          end
        else
          pbMessage("\\ts[]" + _INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 2   # Set G-Max Factor
        if pkmn.dynamax_able?
          if pkmn.gmax_factor?
            pkmn.gmax_factor = false
            pbMessage("\\ts[]" + _INTL("Gigantamax factor was removed from {1}.", pkmn.name))
          elsif pkmn.hasGigantamaxForm?
            pkmn.gmax_factor = true
            pbMessage("\\ts[]" + _INTL("Gigantamax factor was given to {1}.", pkmn.name))
          elsif pbConfirmMessage("\\ts[]" + _INTL("{1} doesn't have a Gigantamax form.\nGive it Gigantamax factor anyway?", pkmn.name))
            pkmn.gmax_factor = true
            pbMessage("\\ts[]" + _INTL("Gigantamax factor was given to {1}.", pkmn.name))
          end
          battler&.pbUpdate
          if battler&.dynamax?
            battler.display_base_moves
            battler.display_dynamax_moves
          end
        else
          pbMessage("\\ts[]" + _INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 3   # Set Dynamax state
        if pkmn.dynamax_able?
          if pkmn.dynamax?
            pkmn.dynamax = false
            battler&.display_base_moves
            battler&.effects[PBEffects::Dynamax] = 0
            pbMessage("\\ts[]" + _INTL("{1} is no longer Dynamaxed.", pkmn.name))
          else
            pkmn.dynamax = true
            if battler
              battler.effects[PBEffects::Dynamax]    = Settings::DYNAMAX_TURNS
              battler.effects[PBEffects::Encore]     = 0
              battler.effects[PBEffects::EncoreMove] = nil
              battler.effects[PBEffects::Disable]    = 0
              battler.effects[PBEffects::Substitute] = 0
              battler.effects[PBEffects::Torment]    = false
              battler.display_dynamax_moves
            end
            pbMessage("\\ts[]" + _INTL("{1} is now Dynamaxed.", pkmn.name))
          end
          battler&.pbUpdate
        else
          pbMessage("\\ts[]" + _INTL("Can't edit Dynamax values on that Pokémon."))
        end
      when 4   # Reset
        pkmn.gmax_factor = false
        pkmn.dynamax = false
        pkmn.dynamax_lvl = 0
        pkmn.dynamax_able = nil
        if battler
          battler.effects[PBEffects::Dynamax] = 0
          battler.display_base_moves
          battler.pbUpdate
        end
        pbMessage("\\ts[]" + _INTL("All Dynamax settings restored to default."))
      end
    end
  }
})