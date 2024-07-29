#===============================================================================
# Debug menus.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_zmoves, {
  "name"        => _INTL("Toggle Z-Moves"),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Toggles the availability of Z-Move functionality."),
  "effect"      => proc {
    $game_switches[Settings::NO_ZMOVE] = !$game_switches[Settings::NO_ZMOVE]
    toggle = ($game_switches[Settings::NO_ZMOVE]) ? "disabled" : "enabled"
    pbMessage(_INTL("Z-Moves {1}.", toggle))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_ultra_burst, {
  "name"        => _INTL("Toggle Ultra Burst"),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("Toggles the availability of Ultra Burst functionality."),
  "effect"      => proc {
    $game_switches[Settings::NO_ULTRA_BURST] = !$game_switches[Settings::NO_ULTRA_BURST]
    toggle = ($game_switches[Settings::NO_ULTRA_BURST]) ? "disabled" : "enabled"
    pbMessage(_INTL("Ultra Burst {1}.", toggle))
  }
})


#-------------------------------------------------------------------------------
# Battle Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_debug_menu, :deluxe_battle_zmoves, {
  "name"        => _INTL("Z-Moves"),
  "parent"      => :trainers,
  "description" => _INTL("Whether each trainer is allowed to use Z-Moves."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      commands = []
      cmds = []
      battle.zMove.each_with_index do |side_values, side|
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
      cmd = pbMessage("\\ts[]" + _INTL("Choose trainer to toggle whether they can use Z-Moves."),
                      commands, -1, nil, cmd)
      break if cmd < 0
      real_cmd = cmds[cmd]
      if battle.zMove[real_cmd[0]][real_cmd[1]] == -1
        battle.zMove[real_cmd[0]][real_cmd[1]] = -2   # Make unable
      else
        battle.zMove[real_cmd[0]][real_cmd[1]] = -1   # Make able
      end
    end
  }
})


MenuHandlers.add(:battle_debug_menu, :deluxe_battle_ultra_burst, {
  "name"        => _INTL("Ultra Burst"),
  "parent"      => :trainers,
  "description" => _INTL("Whether each trainer is allowed to Ultra Burst."),
  "effect"      => proc { |battle|
    cmd = 0
    loop do
      commands = []
      cmds = []
      battle.ultraBurst.each_with_index do |side_values, side|
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
      cmd = pbMessage("\\ts[]" + _INTL("Choose trainer to toggle whether they can Ultra Burst."),
                      commands, -1, nil, cmd)
      break if cmd < 0
      real_cmd = cmds[cmd]
      if battle.ultraBurst[real_cmd[0]][real_cmd[1]] == -1
        battle.ultraBurst[real_cmd[0]][real_cmd[1]] = -2   # Make unable
      else
        battle.ultraBurst[real_cmd[0]][real_cmd[1]] = -1   # Make able
      end
    end
  }
})