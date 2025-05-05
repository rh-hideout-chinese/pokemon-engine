#===============================================================================
# Debug menus.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_zmoves, {
  "name"        => _INTL("切换Z招式"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("切换Z招式功能的可用性。"),
  "effect"      => proc {
    $game_switches[Settings::NO_ZMOVE] = !$game_switches[Settings::NO_ZMOVE]
    toggle = ($game_switches[Settings::NO_ZMOVE]) ? "disabled" : "enabled"
    pbMessage(_INTL("Z招式{1}.", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :noZMoves, {
  "name"        => "Z招式编号[{1}]",
  "rule"        => "noZMoves",
  "order"       => 306,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定禁止使用Z招式\n的一方。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noZMoves", :Choose, [:All, :Player, :Opponent], 
      _INTL("请选择要禁止使用Z招式的一方。"))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_ultra_burst, {
  "name"        => _INTL("切换究极爆发"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("切换究极爆发功能的\n可用性。"),
  "effect"      => proc {
    $game_switches[Settings::NO_ULTRA_BURST] = !$game_switches[Settings::NO_ULTRA_BURST]
    toggle = ($game_switches[Settings::NO_ULTRA_BURST]) ? "disabled" : "enabled"
    pbMessage(_INTL("究极爆发{1}.", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :noUltraBurst, {
  "name"        => "究极爆发编号: [{1}]",
  "rule"        => "noUltraBurst",
  "order"       => 307,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定禁止使用究极爆发\n的一方。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noUltraBurst", :Choose, [:All, :Player, :Opponent], 
      _INTL("请选择要禁止使用究极爆发的一方。"))
  }
})


#-------------------------------------------------------------------------------
# Battle Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_debug_menu, :deluxe_battle_zmoves, {
  "name"        => _INTL("Z招式"),
  "parent"      => :trainers,
  "description" => _INTL("切换每个训练师是否允许\n使用Z招式功能。"),
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
      cmd = pbMessage("\\ts[]" + _INTL("选择训练师来切换是否\n可以使用Z招式。"),
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
  "name"        => _INTL("究极爆发"),
  "parent"      => :trainers,
  "description" => _INTL("每个训练师是否允许\n进行究极爆发。"),
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
      cmd = pbMessage("\\ts[]" + _INTL("选择训练师来切换是否\n可以进行究极爆发。"),
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