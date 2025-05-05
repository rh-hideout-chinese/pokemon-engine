#===============================================================================
# Adds Dynamax-related tools to debug options.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_dynamax, {
  "name"        => _INTL("切换极巨化。"),
  "parent"      => :deluxe_gimmick_toggles,
  "description" => _INTL("T切换极巨化功能的可用性。"),
  "effect"      => proc {
    $game_switches[Settings::NO_DYNAMAX] = !$game_switches[Settings::NO_DYNAMAX]
    toggle = ($game_switches[Settings::NO_DYNAMAX]) ? "disabled" : "enabled"
    pbMessage(_INTL("极巨化 {1}。", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :noDynamax, {
  "name"        => "禁止极巨化：[{1}]",
  "rule"        => "noDynamax",
  "order"       => 308,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定禁止使用极巨化的一方。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("noDynamax", :Choose, [:All, :Player, :Opponent], 
      _INTL("请选择要禁止极巨化的一方。"))
  }
})

MenuHandlers.add(:debug_menu, :deluxe_plugin_settings, {
  "name"        => _INTL("其他插件设定..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("编辑极巨化何时何地\n可以使用。")
})

MenuHandlers.add(:debug_menu, :deluxe_dynamax_settings, {
  "name"        => _INTL("极巨化设定..."),
  "parent"      => :deluxe_plugin_settings,
  "description" => _INTL("编辑可使用极巨化\n的时间与场所。"),
  "effect"      => proc {
    loop do
      commands = [
        _INTL("所有地图均可使用极巨化 [{1}]",    ($game_switches[Settings::DYNAMAX_ON_ANY_MAP])      ? _INTL("YES") : _INTL("NO")),
        _INTL("野外战斗中可使用极巨化 [{1}]", ($game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]) ? _INTL("YES") : _INTL("NO"))
      ]
      command = pbShowCommands(nil, commands, -1, 0)
      break if command < 0
      case command
      when 0
        $game_switches[Settings::DYNAMAX_ON_ANY_MAP] = !$game_switches[Settings::DYNAMAX_ON_ANY_MAP]
        if $game_switches[Settings::DYNAMAX_ON_ANY_MAP]
          pbMessage(_INTL("现在可在任何地图\n使用极巨化。"))
        else
          pbMessage(_INTL("极巨化现在仅在\n带有“极巨能量”标志的\n地图上可用。"))
        end
      when 1
        $game_switches[Settings::DYNAMAX_IN_WILD_BATTLES] = !$game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]
        if $game_switches[Settings::DYNAMAX_IN_WILD_BATTLES]
          pbMessage(_INTL("极巨化现在也可以在\n野生战斗中使用。"))
        else
          pbMessage(_INTL("极巨化现在仅在\n训练师对战中可用。"))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :deluxe_dynamax_metrics, {
  "name"        => _INTL("极巨化指标..."),
  "parent"      => :deluxe_plugin_settings,
  "description" => _INTL("重新定位战斗中显示的\n宝可梦极巨化图片"),
  "effect"      => proc {
    if Settings::SHOW_DYNAMAX_SIZE
      loop do
        commands = [
          _INTL("编辑极巨化指标"),
          _INTL("自动设置极巨化指标")
        ]
        command = pbShowCommands(nil, commands, -1, 0)
        break if command < 0
        case command
        when 0  # Edit Dynamax metrics
          filterCommands = [_INTL("全精灵"), _INTL("超极巨化"), _INTL("按世代划分的精灵...")]
          filterCommand = pbMessage(_INTL("你想编辑哪只精灵?"), filterCommands, -1)
          next if filterCommand < 0
          case filterCommand
          when 1
            filterCommand = -1
          when 2
            params = ChooseNumberParams.new
            params.setRange(1, 99)
            params.setDefaultValue(1)
            params.setCancelValue(-1)
            filterCommand = pbMessageChooseNumber(_INTL("选择一个世代。"), params)
          end
          styleCommands = [_INTL("半背面精灵 (第四世代风格)"), _INTL("全背面精灵 (第五世代风格)")]
          styleCommand = pbMessage(_INTL("你使用的是哪种背面\n精灵图风格?"), styleCommands, -1)
          next if styleCommand < 0
          pbFadeOutIn {
            scene = DynamaxSpritePositioner.new
            scene.setSpriteFilter(filterCommand)
            scene.setBackSpriteStyle(styleCommand)
            screen = DynamaxSpritePositionerScreen.new(scene)
            screen.pbStart
          }
        when 1  # Auto-set Dynamax metrics
          if pbConfirmMessage(_INTL("你确定要自动重新定位所有\n极巨化精灵图片吗?"))
            styleCommands = [_INTL("半背面精灵 (第四世代风格)"), _INTL("全背面精灵 (五世代风格)")]
            styleCommand = pbMessage(_INTL("你使用的是哪种背面\n精灵图风格?"), styleCommands, -1)
            next if styleCommand < 0
            msgwindow = pbCreateMessageWindow
            pbMessageDisplay(msgwindow, _INTL("正在重新定位所有\n极巨化精灵.请稍后"), false)
            Graphics.update
            pbDynamaxAutoPositionAll(styleCommand)
            pbDisposeMessageWindow(msgwindow)
          end
        end
      end
    else
      pbMessage(_INTL("SHOW_DYNAMAX_SIZE被设置为'false',\n 无需设置极巨化指标"))
    end
  }
})


#-------------------------------------------------------------------------------
# Pokemon Debug options.
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :deluxe_attributes, {
  "name"   => _INTL("插件配置..."),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :deluxe_dynamax_attributes, {
  "name"   => _INTL("极巨化..."),
  "parent" => :deluxe_attributes,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      able = (pkmn.dynamax_able?) ? "Yes" : "No"
      dlvl = pkmn.dynamax_lvl
      gmax = (pkmn.gmax_factor?)  ? "Yes" : "No" 
      dmax = (pkmn.dynamax?)      ? "Yes" : "No"
      cmd = screen.pbShowCommands(_INTL("符合资格: {1}\n极巨化等级: {2}\n超极巨招式元素: {3}\n极巨化: {4}", able, dlvl, gmax, dmax),[
         _INTL("设置资格"),
         _INTL("设置极巨化等级"),
         _INTL("设置超极巨招式元素"),
         _INTL("设置极巨化"),
         _INTL("重置")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set Eligibility
        if !pkmn.can_dynamax?
          pkmn.dynamax = false
          screen.pbDisplay(_INTL("{1}属于当前无法使用\n极巨化的物种或形态.\n资格无法更改。", pkmn.name))
        elsif pkmn.dynamax_able?
          pkmn.dynamax = false
          pkmn.dynamax_lvl = 0
          pkmn.gmax_factor = false
          pkmn.dynamax_able = false
          screen.pbDisplay(_INTL("{1}现在无法\n使用极巨化。", pkmn.name))
        else
          pkmn.dynamax_able = true
          screen.pbDisplay(_INTL("{1}现在可以\n使用极巨化。", pkmn.name))
        end
        screen.pbRefreshSingle(pkmnid)
      when 1   # Set Dynamax Level
        if pkmn.dynamax_able?
          params = ChooseNumberParams.new
          params.setRange(0, 10)
          params.setDefaultValue(pkmn.dynamax_lvl)
          params.setCancelValue(pkmn.dynamax_lvl)
          f = pbMessageChooseNumber(
            _INTL("设置 {1}的\n极巨化等级 (最大值. 10)。", pkmn.name), params) { screen.pbUpdate }
          if f != pkmn.dynamax_lvl
            pkmn.dynamax_lvl = f
            pkmn.calc_stats
            screen.pbRefreshSingle(pkmnid)
          end
        else
          screen.pbDisplay(_INTL("无法编辑该宝可梦的\n极巨化等级"))
        end
      when 2   # Set G-Max Factor
        if pkmn.dynamax_able?
          if pkmn.gmax_factor?
            pkmn.gmax_factor = false
            screen.pbDisplay(_INTL("超极巨化元素已从\n{1}中移除。", pkmn.name))
          else
            if pkmn.hasGigantamaxForm?
              pkmn.gmax_factor = true
              screen.pbDisplay(_INTL("已赋予{1}超极巨化\n元素。", pkmn.name))
            else
              if pbConfirmMessage(_INTL("{1}没有超极巨化形态.\n仍然赋予它极巨化元素?", pkmn.name))
                pkmn.gmax_factor = true
                screen.pbDisplay(_INTL("已赋予{1}超极巨化元素。", pkmn.name))
              end
            end
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("无法编辑该宝可梦的\n极巨化等级。"))
        end
      when 3   # Set Dynamax
        if pkmn.dynamax_able?
          if pkmn.dynamax?
            pkmn.dynamax = false
            screen.pbDisplay(_INTL("{1}现在不再处于\n极巨化状态.。", pkmn.name))
          else
            pkmn.dynamax = true
            screen.pbDisplay(_INTL("{1}现在处\n极巨化状态。", pkmn.name))
          end
          screen.pbRefreshSingle(pkmnid)
        else
          screen.pbDisplay(_INTL("无法编辑该宝可梦的\n极巨化等级。"))
        end
      when 4   # Reset All
        pkmn.dynamax = false
        pkmn.dynamax_lvl = 0
        pkmn.gmax_factor = false
        pkmn.dynamax_able = nil
        screen.pbDisplay(_INTL("所有极巨化设置\n已恢复为默认值。"))
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
  "name"        => _INTL("极巨化。"),
  "parent"      => :trainers,
  "description" => _INTL("每个训练师是否允许极巨化。"),
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
      cmd = pbMessage("\\ts[]" + _INTL("选择训练师以切换他们是否\n可以极巨化。"),
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
  "name"   => _INTL("极巨化等级"),
  "parent" => :main,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    cmd = 0
    loop do
      dlvl = pkmn.dynamax_lvl
      able = (pkmn.dynamax_able?) ? "Can" : "Cannot"
      gmax = (pkmn.gmax_factor?)  ? "Yes" : "No" 
      dmax = (pkmn.dynamax?)      ? "Is"  : "Is not"
      msg = _INTL("{1}极巨化 [等级: {2}] [超极巨化: {3}]\n{4} 当前处于极巨化状态。", able, dlvl, gmax, dmax)
      cmd = pbMessage("\\ts[]" + msg,
                      [_INTL("设置资格"),
                       _INTL("设置极巨化等级"),
                       _INTL("设置超极巨招式元素"),
                       _INTL("设置极巨化状态"),
                       _INTL("重置")], -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0   # Set eligibility
        if !pkmn.can_dynamax?
          pkmn.dynamax = false
          pbMessage("\\ts[]" + _INTL("{1}属于当前无法使用\n极巨化的物种或形态.\n资格无法更改。", pkmn.name))
          battler&.pbUpdate
        elsif pkmn.dynamax_able?
          pkmn.gmax_factor = false
          pkmn.dynamax = false
          pkmn.dynamax_lvl = 0
          pkmn.dynamax_able = false
          pbMessage("\\ts[]" + _INTL("{1}现在无法使用\n极巨化。", pkmn.name))
          battler&.display_base_moves
          battler&.pbUpdate
        else
          pkmn.dynamax_able = true
          pbMessage("\\ts[]" + _INTL("{1}现在可以使用\n极巨化。", pkmn.name))
        end
      when 1   # Set Dynamax Lvl
        if pkmn.dynamax_able?
          params = ChooseNumberParams.new
          params.setRange(0, 10)
          params.setDefaultValue(pkmn.dynamax_lvl)
          params.setCancelValue(pkmn.dynamax_lvl)
          f = pbMessageChooseNumber(
            "\\ts[]" + _INTL("设置{1}的极巨化\n等级(最大值. 10).", pkmn.name), params
          )
          if f != pkmn.dynamax_lvl
            pkmn.dynamax_lvl = f
            pkmn.calc_stats
            battler&.pbUpdate
          end
        else
          pbMessage("\\ts[]" + _INTL("无法编辑该宝可梦的极巨等级。"))
        end
      when 2   # Set G-Max Factor
        if pkmn.dynamax_able?
          if pkmn.gmax_factor?
            pkmn.gmax_factor = false
            pbMessage("\\ts[]" + _INTL("超极巨化元素\n已从{1}中移除。", pkmn.name))
          elsif pkmn.hasGigantamaxForm?
            pkmn.gmax_factor = true
            pbMessage("\\ts[]" + _INTL("{1}获得了可以\n超极巨化的元素。", pkmn.name))
          elsif pbConfirmMessage("\\ts[]" + _INTL("{1}没有超极巨化形态。\n仍然赋予它超极巨化元素吗?", pkmn.name))
            pkmn.gmax_factor = true
            pbMessage("\\ts[]" + _INTL("已赋予{1}超极巨化元素。", pkmn.name))
          end
          battler&.pbUpdate
          if battler&.dynamax?
            battler.display_base_moves
            battler.display_dynamax_moves
          end
        else
          pbMessage("\\ts[]" + _INTL("无法编辑该宝可梦的\n极巨化值。"))
        end
      when 3   # Set Dynamax state
        if pkmn.dynamax_able?
          if pkmn.dynamax?
            pkmn.dynamax = false
            battler&.display_base_moves
            battler&.effects[PBEffects::Dynamax] = 0
            pbMessage("\\ts[]" + _INTL("{1}现在不再处于\n极巨化状态。", pkmn.name))
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
            pbMessage("\\ts[]" + _INTL("{1}现在处于\n极巨化状态。", pkmn.name))
          end
          battler&.pbUpdate
        else
          pbMessage("\\ts[]" + _INTL("无法编辑该宝可梦\n的极巨化值。"))
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
        pbMessage("\\ts[]" + _INTL("所有极巨化设置\n已恢复为默认值。"))
      end
    end
  }
})