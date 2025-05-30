#===============================================================================
# Debug menus.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_tera, {
  "name"        => _INTL("切换太晶化"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("切换是否启用太晶化功能。"),
  "effect"      => proc {
    $game_switches[Settings::NO_TERASTALLIZE] = !$game_switches[Settings::NO_TERASTALLIZE]
    toggle = ($game_switches[Settings::NO_TERASTALLIZE]) ? "已禁用" : "已启用"
    pbMessage(_INTL("太晶化功能{1}。", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :noTerastallize, {
  "name"        => "禁止太晶化: [{1}]",
  "rule"        => "noTerastallize",
  "order"       => 309,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定禁用太晶化的一方。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noTerastallize", :Choose, [:All, :Player, :Opponent], 
      _INTL("选择要禁止太晶化的一方。"))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_plugin_settings, {
  "name"        => _INTL("其他插件设置..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("用于调整由附加插件实现的各种功能的设置。")
})

MenuHandlers.add(:debug_menu, :deluxe_tera_settings, {
  "name"        => _INTL("太晶相关设置..."),
  "parent"      => :deluxe_plugin_settings,
  "description" => _INTL("编辑玩家的太晶宝珠状态和宝可梦的太晶属性。"),
  "effect"      => proc {
    loop do
      commands = [
        _INTL("玩家的太晶宝珠已蓄能 [ {1} ]", ($player.tera_charged?)                             ? _INTL("是") : _INTL("否")),
        _INTL("太晶宝珠拥有无限能量 [ {1} ]", ($game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]) ? _INTL("是") : _INTL("否")),
        _INTL("随机分配宝可梦太晶属性 [ {1} ]", ($game_switches[Settings::RANDOMIZED_TERA_TYPES])   ? _INTL("是") : _INTL("否"))
      ]
      command = pbShowCommands(nil, commands, -1, 0)
      break if command < 0
      case command
      when 0 # Tera Orb charge state
        $player.tera_charged = !$player.tera_charge
        toggle = ($player.tera_charged?) ? "已蓄能" : "未蓄能"
        pbMessage(_INTL("玩家的太晶宝珠现在{1}。", toggle))
      when 1 # Tera Orb charge mode
        $game_switches[Settings::TERA_ORB_ALWAYS_CHARGED] = !$game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]
        toggle = ($game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]) ? "不需要蓄能" : "需要蓄能"
        $player.tera_charged = true if $game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]
        pbMessage(_INTL("玩家的太晶宝珠现在{1}后才能再次使用。", toggle))
      when 2 # Pokemon Tera types
        $game_switches[Settings::RANDOMIZED_TERA_TYPES] = !$game_switches[Settings::RANDOMIZED_TERA_TYPES]
        toggle = ($game_switches[Settings::RANDOMIZED_TERA_TYPES]) ? "随机的" : "原本的"
        pbMessage(_INTL("新收服的宝可梦将会拥有{1}太晶属性。", toggle))
      end
    end
  }
})


#-------------------------------------------------------------------------------
# Pokemon Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :deluxe_attributes, {
  "name"   => _INTL("插件属性..."),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :deluxe_tera_attributes, {
  "name"   => _INTL("太晶属性..."),
  "parent" => :deluxe_attributes,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      able = (pkmn.terastal_able?) ? "Yes" : "No"
      type = (pkmn.tera_type) ? GameData::Type.get(pkmn.tera_type).name : "---" 
      tera = (pkmn.tera?) ? "Yes" : "No"
      cmd = screen.pbShowCommands(_INTL("是否可太晶化：{1}\n太晶属性：{2}\n是否已太晶化：{3}", able, type, tera), [
          _INTL("设置是否可太晶化"),
          _INTL("设置太晶属性"),
          _INTL("设置是否已太晶化"),
          _INTL("重置所有设置")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Eligibility
        if !pkmn.can_terastallize?
          pkmn.terastallized = false
          screen.pbDisplay(_INTL("{1}属于当前无法太晶化的种类或形态。\n无法更改其资格。", pkmn.name))
        elsif pkmn.terastal_able?
          pkmn.terastallized = false
          pkmn.terastal_able = false
          screen.pbDisplay(_INTL("{1}现在无法太晶化了。", pkmn.name))
        else
          pkmn.terastal_able = true
          screen.pbDisplay(_INTL("{1}现在可以太晶化了。", pkmn.name))
        end
        screen.pbRefreshSingle(pkmnid)
      when 1   # Set Tera type
        if pkmn.terastal_able?
          if !pkmn.getTeraType(true).nil?
            screen.pbDisplay(_INTL("{1}的太晶属性无法更改。", pkmn.name))
          else
            default = GameData::Type.get(pkmn.tera_type).icon_position
            newType = pbChooseTypeList(default < 10 ? default + 1 : default)
            if newType && newType != pkmn.tera_type
              pkmn.tera_type = newType
              screen.pbDisplay(_INTL("{1}的太晶属性现在是{2}属性。", pkmn.name, GameData::Type.get(newType).name))
              screen.pbRefreshSingle(pkmnid)
            end
          end
        else
          screen.pbDisplay(_INTL("无法编辑该宝可梦的太晶属性。"))
        end
      when 2   # Set Terastallized
        if pkmn.hasTerastalForm?
          screen.pbDisplay(_INTL("{1}在太晶化时会改变形态。\n该变化仅会在战斗中发生。", pkmn.name))
        elsif pkmn.terastal_able?
          if pkmn.tera?
            pkmn.terastallized = false
            screen.pbDisplay(_INTL("{1}不再处于太晶化状态。", pkmn.name))
          else
            pkmn.terastallized = true
            screen.pbDisplay(_INTL("{1}现在处于太晶化状态。", pkmn.name))
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("无法编辑该宝可梦的太晶属性。"))
        end
      when 3   # Reset All
        pkmn.terastallized = false
        pkmn.terastal_able = nil
        pkmn.tera_type = nil
        screen.pbDisplay(_INTL("所有太晶设置已恢复为默认状态。"))
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
  "name"        => _INTL("太晶化"),
  "parent"      => :trainers,
  "description" => _INTL("设定每位训练师是否可以进行太晶化。"),
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
          text = (side == 0) ? "我方：" : "敌方："
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
      cmd = pbMessage("\\ts[]" + _INTL("选择要切换是否可以进行太晶化的训练师。"),
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
  "name"   => _INTL("太晶相关数值"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      type = (pkmn.tera_type) ? GameData::Type.get(pkmn.tera_type).name : "---" 
      able = (pkmn.terastal_able?) ? "可以" : "不可"
      tera = (pkmn.tera?) ? "已" : "未"
      msg = _INTL("{1}进行太晶化 [太晶属性：{2}]\n目前{3}处于太晶化状态。", able, type, tera)
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("设定是否可太晶化"),
                       _INTL("设定太晶属性"),
                       _INTL("设定太晶化状态"),
                       _INTL("重置")]
      break if cmd < 0
      case cmd
      when 0   # Set eligibility
        if !pkmn.can_terastallize?
          pkmn.terastallized = false
          pbMessage("\\ts[]" + _INTL("{1}属于目前无法太晶化的种类或形态。\n无法更改太晶化资格。", pkmn.name))
          battler&.pbUpdate
        elsif pkmn.terastal_able?
          pkmn.terastallized = false
          pkmn.terastal_able = false
          pbMessage("\\ts[]" + _INTL("{1}已无法进行太晶化。", pkmn.name))
          battler&.pbUpdate
        else
          pkmn.terastal_able = true
          pbMessage("\\ts[]" + _INTL("{1}现在可以进行太晶化了。", pkmn.name))
        end
      when 1   # Set Tera type
        if pkmn.terastal_able?
          if !pkmn.getTeraType(true).nil?
            pbMessage("\\ts[]" + _INTL("{1}的太晶属性无法更改。", pkmn.name))
          else
            default = GameData::Type.get(pkmn.tera_type).icon_position
            newType = pbChooseTypeList(default < 10 ? default + 1 : default)
            if newType && newType != pkmn.tera_type
              pkmn.tera_type = newType
              pbMessage("\\ts[]" + _INTL("{1}的太晶属性现在是{2}.", pkmn.name, GameData::Type.get(newType).name))
              battler&.pbUpdate
            end
          end
        else
          pbMessage("\\ts[]" + _INTL("无法编辑该宝可梦的太晶数据。"))
        end
      when 2   # Set Terastal state
        if pkmn.terastal_able?
          if pkmn.tera?
            pkmn.terastallized = false
            pbMessage("\\ts[]" + _INTL("{1}已不处于太晶化状态。", pkmn.name))
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
            pbMessage("\\ts[]" + _INTL("{1}现在处于太晶化状态。", pkmn.name))
          end
          battler&.pbUpdate
        else
          pbMessage("\\ts[]" + _INTL("无法编辑该宝可梦的太晶数据。"))
        end
      when 3   # Reset
        pkmn.terastallized = false
        pkmn.terastal_able = nil
        pkmn.tera_type = nil
		battler&.pbUpdate
        pbMessage("\\ts[]" + _INTL("所有太晶设置已恢复为默认值。"))
      end
    end
  }
})