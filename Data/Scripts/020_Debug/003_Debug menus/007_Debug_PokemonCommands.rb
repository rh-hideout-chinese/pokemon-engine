#===============================================================================
# HP/Status options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :hp_status_menu, {
  "name"   => _INTL("HP/状态……"),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :set_hp, {
  "name"   => _INTL("设置HP"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    else
      params = ChooseNumberParams.new
      params.setRange(0, pkmn.totalhp)
      params.setDefaultValue(pkmn.hp)
      newhp = pbMessageChooseNumber(
        _INTL("设置{1}的HP。（最大：{2}）", pkmn.name, pkmn.totalhp), params
      ) { screen.pbUpdate }
      if newhp != pkmn.hp
        pkmn.hp = newhp
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_status, {
  "name"   => _INTL("设置状态"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    elsif pkmn.hp <= 0
      screen.pbDisplay(_INTL("{1}倒下了，不能修改状态。", pkmn.name))
    else
      cmd = 0
      commands = [_INTL("[治疗]")]
      ids = [:NONE]
      GameData::Status.each do |s|
        next if s.id == :NONE
        commands.push(_INTL("设置{1}", s.name))
        ids.push(s.id)
      end
      loop do
        msg = _INTL("当前状态：{1}", GameData::Status.get(pkmn.status).name)
        if pkmn.status == :SLEEP
          msg = _INTL("当前状态：{1}（回合：{2}）",
                      GameData::Status.get(pkmn.status).name, pkmn.statusCount)
        end
        cmd = screen.pbShowCommands(msg, commands, cmd)
        break if cmd < 0
        case cmd
        when 0   # Cure
          pkmn.heal_status
          screen.pbRefreshSingle(pkmnid)
        else   # Give status problem
          count = 0
          cancel = false
          if ids[cmd] == :SLEEP
            params = ChooseNumberParams.new
            params.setRange(0, 9)
            params.setDefaultValue(3)
            count = pbMessageChooseNumber(
              _INTL("设置{1}睡眠的回合"), params
            ) { screen.pbUpdate }
            cancel = true if count <= 0
          end
          if !cancel
            pkmn.status      = ids[cmd]
            pkmn.statusCount = count
            screen.pbRefreshSingle(pkmnid)
          end
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :full_heal, {
  "name"   => _INTL("完全治愈"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    else
      pkmn.heal
      screen.pbDisplay(_INTL("{1}恢复健康了。", pkmn.name))
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :make_fainted, {
  "name"   => _INTL("使其倒下"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    else
      pkmn.hp = 0
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_pokerus, {
  "name"   => _INTL("设置宝可病毒"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      pokerus = (pkmn.pokerus) ? pkmn.pokerus : 0
      msg = [_INTL("{1}没有宝可病毒。", pkmn.name),
             _INTL("具有{1}菌株，可传染{2}天以上。", pokerus / 16, pokerus % 16),
             _INTL("具有{1}菌株，无传染性。", pokerus / 16)][pkmn.pokerusStage]
      cmd = screen.pbShowCommands(msg,
                                  [_INTL("给予随机菌株"),
                                   _INTL("失去传染性"),
                                   _INTL("清除宝可病毒")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Give random strain
        pkmn.givePokerus
        screen.pbRefreshSingle(pkmnid)
      when 1   # Make not infectious
        if pokerus > 0
          strain = pokerus / 16
          p = strain << 4
          pkmn.pokerus = p
          screen.pbRefreshSingle(pkmnid)
        end
      when 2   # Clear Pokérus
        pkmn.pokerus = 0
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

#===============================================================================
# Level/stats options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :level_stats, {
  "name"   => _INTL("等级/能力……"),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :set_level, {
  "name"   => _INTL("设置等级"),
  "parent" => :level_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    else
      params = ChooseNumberParams.new
      params.setRange(1, GameData::GrowthRate.max_level)
      params.setDefaultValue(pkmn.level)
      level = pbMessageChooseNumber(
        _INTL("设置宝可梦的等级。（最高：{1}）", params.maxNumber), params
      ) { screen.pbUpdate }
      if level != pkmn.level
        pkmn.level = level
        pkmn.calc_stats
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_exp, {
  "name"   => _INTL("设置经验值"),
  "parent" => :level_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    else
      minxp = pkmn.growth_rate.minimum_exp_for_level(pkmn.level)
      maxxp = pkmn.growth_rate.minimum_exp_for_level(pkmn.level + 1)
      if minxp == maxxp
        screen.pbDisplay(_INTL("{1}为最高级。", pkmn.name))
      else
        params = ChooseNumberParams.new
        params.setRange(minxp, maxxp - 1)
        params.setDefaultValue(pkmn.exp)
        newexp = pbMessageChooseNumber(
          _INTL("设置宝可梦的Exp。（范围：{1}-{2}）", minxp, maxxp - 1), params
        ) { screen.pbUpdate }
        if newexp != pkmn.exp
          pkmn.exp = newexp
          pkmn.calc_stats
          screen.pbRefreshSingle(pkmnid)
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :hidden_values, {
  "name"   => _INTL("EV/IV/ID……"),
  "parent" => :level_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      persid = sprintf("0x%08X", pkmn.personalID)
      cmd = screen.pbShowCommands(_INTL("ID为{1}。", persid),
                                  [_INTL("设置努力值"),
                                   _INTL("设置个体值"),
                                   _INTL("随机ID")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set EVs
        cmd2 = 0
        loop do
          totalev = 0
          evcommands = []
          ev_id = []
          GameData::Stat.each_main do |s|
            evcommands.push(s.name + " (#{pkmn.ev[s.id]})")
            ev_id.push(s.id)
            totalev += pkmn.ev[s.id]
          end
          evcommands.push(_INTL("随机全部"))
          evcommands.push(_INTL("随机最大"))
          cmd2 = screen.pbShowCommands(_INTL("修改哪个努力值？\n总计：{1}/{2}（{3}%）",
                                             totalev, Pokemon::EV_LIMIT,
                                             100 * totalev / Pokemon::EV_LIMIT), evcommands, cmd2)
          break if cmd2 < 0
          if cmd2 < ev_id.length
            params = ChooseNumberParams.new
            upperLimit = 0
            GameData::Stat.each_main { |s| upperLimit += pkmn.ev[s.id] if s.id != ev_id[cmd2] }
            upperLimit = Pokemon::EV_LIMIT - upperLimit
            upperLimit = [upperLimit, Pokemon::EV_STAT_LIMIT].min
            thisValue = [pkmn.ev[ev_id[cmd2]], upperLimit].min
            params.setRange(0, upperLimit)
            params.setDefaultValue(thisValue)
            params.setCancelValue(thisValue)
            f = pbMessageChooseNumber(_INTL("设置{1}的努力值（最大值：{2}）",
                                            GameData::Stat.get(ev_id[cmd2]).name, upperLimit), params) { screen.pbUpdate }
            if f != pkmn.ev[ev_id[cmd2]]
              pkmn.ev[ev_id[cmd2]] = f
              pkmn.calc_stats
              screen.pbRefreshSingle(pkmnid)
            end
          else   # (Max) Randomise all
            evTotalTarget = Pokemon::EV_LIMIT
            if cmd2 == evcommands.length - 2   # Randomize all (not max)
              evTotalTarget = rand(Pokemon::EV_LIMIT)
            end
            GameData::Stat.each_main { |s| pkmn.ev[s.id] = 0 }
            while evTotalTarget > 0
              r = rand(ev_id.length)
              next if pkmn.ev[ev_id[r]] >= Pokemon::EV_STAT_LIMIT
              addVal = 1 + rand(Pokemon::EV_STAT_LIMIT / 4)
              addVal = addVal.clamp(0, evTotalTarget)
              addVal = addVal.clamp(0, Pokemon::EV_STAT_LIMIT - pkmn.ev[ev_id[r]])
              next if addVal == 0
              pkmn.ev[ev_id[r]] += addVal
              evTotalTarget -= addVal
            end
            pkmn.calc_stats
            screen.pbRefreshSingle(pkmnid)
          end
        end
      when 1   # Set IVs
        cmd2 = 0
        loop do
          hiddenpower = pbHiddenPower(pkmn)
          totaliv = 0
          ivcommands = []
          iv_id = []
          GameData::Stat.each_main do |s|
            ivcommands.push(s.name + " (#{pkmn.iv[s.id]})")
            iv_id.push(s.id)
            totaliv += pkmn.iv[s.id]
          end
          msg = _INTL("修改哪个个体值？\n觉醒力量：\n{1}，威力{2}\n总计：{3}/{4}（{5}%）",
                      GameData::Type.get(hiddenpower[0]).name, hiddenpower[1], totaliv,
                      iv_id.length * Pokemon::IV_STAT_LIMIT, 100 * totaliv / (iv_id.length * Pokemon::IV_STAT_LIMIT))
          ivcommands.push(_INTL("随机全部"))
          cmd2 = screen.pbShowCommands(msg, ivcommands, cmd2)
          break if cmd2 < 0
          if cmd2 < iv_id.length
            params = ChooseNumberParams.new
            params.setRange(0, Pokemon::IV_STAT_LIMIT)
            params.setDefaultValue(pkmn.iv[iv_id[cmd2]])
            params.setCancelValue(pkmn.iv[iv_id[cmd2]])
            f = pbMessageChooseNumber(_INTL("设置{1}的个体值（最大值：31）",
                                            GameData::Stat.get(iv_id[cmd2]).name), params) { screen.pbUpdate }
            if f != pkmn.iv[iv_id[cmd2]]
              pkmn.iv[iv_id[cmd2]] = f
              pkmn.calc_stats
              screen.pbRefreshSingle(pkmnid)
            end
          else   # Randomise all
            GameData::Stat.each_main { |s| pkmn.iv[s.id] = rand(Pokemon::IV_STAT_LIMIT + 1) }
            pkmn.calc_stats
            screen.pbRefreshSingle(pkmnid)
          end
        end
      when 2   # Randomise pID
        pkmn.personalID = rand(2**16) | (rand(2**16) << 16)
        pkmn.calc_stats
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_happiness, {
  "name"   => _INTL("设置亲密度"),
  "parent" => :level_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.happiness)
    h = pbMessageChooseNumber(
      _INTL("设置宝可梦的亲密度（最大：255）"), params
    ) { screen.pbUpdate }
    if h != pkmn.happiness
      pkmn.happiness = h
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :contest_stats, {
  "name"   => _INTL("大赛能力……"),
  "parent" => :level_stats
})

MenuHandlers.add(:pokemon_debug_menu, :set_beauty, {
  "name"   => _INTL("设置美丽度"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.beauty)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的美丽度。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.beauty
      pkmn.beauty = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_cool, {
  "name"   => _INTL("设置帅气度"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.cool)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的帅气度。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.cool
      pkmn.cool = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_cute, {
  "name"   => _INTL("设置可爱度"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.cute)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的可爱度。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.cute
      pkmn.cute = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_smart, {
  "name"   => _INTL("设置聪明度"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.smart)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的聪明度。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.smart
      pkmn.smart = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_tough, {
  "name"   => _INTL("设置强壮度"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.tough)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的强壮度。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.tough
      pkmn.tough = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_sheen, {
  "name"   => _INTL("设置光泽"),
  "parent" => :contest_stats,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    params = ChooseNumberParams.new
    params.setRange(0, 255)
    params.setDefaultValue(pkmn.sheen)
    newval = pbMessageChooseNumber(
      _INTL("设置宝可梦的光泽。（最高：255）"), params
    ) { screen.pbUpdate }
    if newval != pkmn.sheen
      pkmn.sheen = newval
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

#===============================================================================
# Moves options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :moves, {
  "name"   => _INTL("招式……"),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :teach_move, {
  "name"   => _INTL("教授招式"),
  "parent" => :moves,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    move = pbChooseMoveList
    if move
      pbLearnMove(pkmn, move)
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :forget_move, {
  "name"   => _INTL("遗忘招式"),
  "parent" => :moves,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    moveindex = screen.pbChooseMove(pkmn, _INTL("选择要忘记的招式。"))
    if moveindex >= 0
      movename = pkmn.moves[moveindex].name
      pkmn.forget_move_at_index(moveindex)
      screen.pbDisplay(_INTL("{1}忘记了{2}", pkmn.name, movename))
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :reset_moves, {
  "name"   => _INTL("重置招式"),
  "parent" => :moves,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    pkmn.reset_moves
    screen.pbDisplay(_INTL("{1}的招式被重置了。", pkmn.name))
    screen.pbRefreshSingle(pkmnid)
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_move_pp, {
  "name"   => _INTL("设置招式PP"),
  "parent" => :moves,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      commands = []
      pkmn.moves.each do |i|
        break if !i.id
        if i.total_pp <= 0
          commands.push(_INTL("{1}（PP：—）", i.name))
        else
          commands.push(_INTL("{1}（PP：{2}/{3}）", i.name, i.pp, i.total_pp))
        end
      end
      commands.push(_INTL("回复PP"))
      cmd = screen.pbShowCommands(_INTL("改变哪个招式的PP？"), commands, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < commands.length - 1   # Move
        move = pkmn.moves[cmd]
        movename = move.name
        if move.total_pp <= 0
          screen.pbDisplay(_INTL("{1}现在有无限PP。", movename))
        else
          cmd2 = 0
          loop do
            msg = _INTL("{1}：PP{2}/{3}（PP提高：{4}/3）", movename, move.pp, move.total_pp, move.ppup)
            cmd2 = screen.pbShowCommands(msg,
                                         [_INTL("设置PP"),
                                          _INTL("回复PP"),
                                          _INTL("设置PP提高")], cmd2)
            break if cmd2 < 0
            case cmd2
            when 0   # Change PP
              params = ChooseNumberParams.new
              params.setRange(0, move.total_pp)
              params.setDefaultValue(move.pp)
              h = pbMessageChooseNumber(
                _INTL("设置{1}的PP。（最大值：{2})", movename, move.total_pp), params
              ) { screen.pbUpdate }
              move.pp = h
            when 1   # Full PP
              move.pp = move.total_pp
            when 2   # Change PP Up
              params = ChooseNumberParams.new
              params.setRange(0, 3)
              params.setDefaultValue(move.ppup)
              h = pbMessageChooseNumber(
                _INTL("设置{1}的PP提升。（最大值：3)", movename), params
              ) { screen.pbUpdate }
              move.ppup = h
              move.pp = move.total_pp if move.pp > move.total_pp
            end
          end
        end
      elsif cmd == commands.length - 1   # Restore all PP
        pkmn.heal_PP
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_initial_moves, {
  "name"   => _INTL("重置初始招式"),
  "parent" => :moves,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    pkmn.record_first_moves
    screen.pbDisplay(_INTL("{1}的招式被设置为第一个已知招式。", pkmn.name))
    screen.pbRefreshSingle(pkmnid)
    next false
  }
})

#===============================================================================
# Other options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :set_item, {
  "name"   => _INTL("设置持有物"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    commands = [
      _INTL("更改持有物"),
      _INTL("删除持有物")
    ]
    loop do
      msg = (pkmn.hasItem?) ? _INTL("持有物为{1}。", pkmn.item.name) : _INTL("没有持有物。")
      cmd = screen.pbShowCommands(msg, commands, cmd)
      break if cmd < 0
      case cmd
      when 0   # Change item
        item = pbChooseItemList(pkmn.item_id)
        if item && item != pkmn.item_id
          pkmn.item = item
          if GameData::Item.get(item).is_mail?
            pkmn.mail = Mail.new(item, _INTL("文本"), $player.name)
          end
          screen.pbRefreshSingle(pkmnid)
        end
      when 1   # Remove item
        if pkmn.hasItem?
          pkmn.item = nil
          pkmn.mail = nil
          screen.pbRefreshSingle(pkmnid)
        end
      else
        break
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_ability, {
  "name"   => _INTL("设置特性"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    commands = [
      _INTL("设置可能特性"),
      _INTL("设置任意特性"),
      _INTL("重置")
    ]
    loop do
      if pkmn.ability
        msg = _INTL("特性为{1}。（索引：{2}）", pkmn.ability.name, pkmn.ability_index)
      else
        msg = _INTL("无特性。（索引：{1}）", pkmn.ability_index)
      end
      cmd = screen.pbShowCommands(msg, commands, cmd)
      break if cmd < 0
      case cmd
      when 0   # Set possible ability
        abils = pkmn.getAbilityList
        ability_commands = []
        abil_cmd = 0
        abils.each do |i|
          ability_commands.push(((i[1] < 2) ? "" : "(H) ") + GameData::Ability.get(i[0]).name)
          abil_cmd = ability_commands.length - 1 if pkmn.ability_id == i[0]
        end
        abil_cmd = screen.pbShowCommands(_INTL("选择一项特性。"), ability_commands, abil_cmd)
        next if abil_cmd < 0
        pkmn.ability_index = abils[abil_cmd][1]
        pkmn.ability = nil
        screen.pbRefreshSingle(pkmnid)
      when 1   # Set any ability
        new_ability = pbChooseAbilityList(pkmn.ability_id)
        if new_ability && new_ability != pkmn.ability_id
          pkmn.ability = new_ability
          screen.pbRefreshSingle(pkmnid)
        end
      when 2   # Reset
        pkmn.ability_index = nil
        pkmn.ability = nil
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_nature, {
  "name"   => _INTL("设置性格"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    commands = []
    ids = []
    GameData::Nature.each do |nature|
      if nature.stat_changes.length == 0
        commands.push(_INTL("{1}（---）", nature.real_name))
      else
        plus_text = ""
        minus_text = ""
        nature.stat_changes.each do |change|
          if change[1] > 0
            plus_text += "/" if !plus_text.empty?
            plus_text += GameData::Stat.get(change[0]).name_brief
          elsif change[1] < 0
            minus_text += "/" if !minus_text.empty?
            minus_text += GameData::Stat.get(change[0]).name_brief
          end
        end
        commands.push(_INTL("{1}（+{2},，-{3}）", nature.real_name, plus_text, minus_text))
      end
      ids.push(nature.id)
    end
    commands.push(_INTL("[重置]"))
    cmd = ids.index(pkmn.nature_id || ids[0])
    loop do
      msg = _INTL("性格为{1}。", pkmn.nature.name)
      cmd = screen.pbShowCommands(msg, commands, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < commands.length - 1   # Set nature
        pkmn.nature = ids[cmd]
      elsif cmd == commands.length - 1   # Reset
        pkmn.nature = nil
      end
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_gender, {
  "name"   => _INTL("设置性别"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.singleGendered?
      screen.pbDisplay(_INTL("{1}是单性别或无性别。", pkmn.speciesName))
    else
      cmd = 0
      loop do
        msg = [_INTL("性别为雄性。"), _INTL("性别为雌性。")][pkmn.male? ? 0 : 1]
        cmd = screen.pbShowCommands(msg,
                                    [_INTL("成为雄性"),
                                     _INTL("成为雌性"),
                                     _INTL("重置")], cmd)
        break if cmd < 0
        case cmd
        when 0   # Make male
          pkmn.makeMale
          if !pkmn.male?
            screen.pbDisplay(_INTL("{1}的性别无法改变。", pkmn.name))
          end
        when 1   # Make female
          pkmn.makeFemale
          if !pkmn.female?
            screen.pbDisplay(_INTL("{1}的性别无法改变。", pkmn.name))
          end
        when 2   # Reset
          pkmn.gender = nil
        end
        $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :species_and_form, {
  "name"   => _INTL("种族/形态……"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = [_INTL("种族{1}   形态{2}", pkmn.speciesName, pkmn.form),
             _INTL("种族{1}   形态{2}（修改过）", pkmn.speciesName, pkmn.form)][(pkmn.forced_form.nil?) ? 0 : 1]
      cmd = screen.pbShowCommands(msg,
                                  [_INTL("设置物种"),
                                   _INTL("设置形态"),
                                   _INTL("移除形态形态修改")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Set species
        species = pbChooseSpeciesList(pkmn.species)
        if species && species != pkmn.species
          pkmn.species = species
          pkmn.calc_stats
          $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
          screen.pbRefreshSingle(pkmnid)
        end
      when 1   # Set form
        cmd2 = 0
        formcmds = [[], []]
        GameData::Species.each do |sp|
          next if sp.species != pkmn.species
          form_name = sp.form_name
          form_name = _INTL("未命名形态") if !form_name || form_name.empty?
          form_name = sprintf("%d: %s", sp.form, form_name)
          formcmds[0].push(sp.form)
          formcmds[1].push(form_name)
          cmd2 = formcmds[0].length - 1 if pkmn.form == sp.form
        end
        if formcmds[0].length <= 1
          screen.pbDisplay(_INTL("{1}只有一种形态。", pkmn.speciesName))
          if pkmn.form != 0 && screen.pbConfirm(_INTL("要将形态重置为0吗？"))
            pkmn.form = 0
            $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
            screen.pbRefreshSingle(pkmnid)
          end
        else
          cmd2 = screen.pbShowCommands(_INTL("设置宝可梦的形态。"), formcmds[1], cmd2)
          next if cmd2 < 0
          f = formcmds[0][cmd2]
          if f != pkmn.form
            if MultipleForms.hasFunction?(pkmn, "getForm")
              next if !screen.pbConfirm(_INTL("该物种决定形态，确定覆盖？"))
              pkmn.forced_form = f
            end
            pkmn.form = f
            $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
            screen.pbRefreshSingle(pkmnid)
          end
        end
      when 2   # Remove form override
        pkmn.forced_form = nil
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

#===============================================================================
# Cosmetic options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :cosmetic, {
  "name"   => _INTL("信息……"),
  "parent" => :main
})

MenuHandlers.add(:pokemon_debug_menu, :set_shininess, {
  "name"   => _INTL("设置闪光"),
  "parent" => :cosmetic,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg_idx = pkmn.shiny? ? (pkmn.super_shiny? ? 1 : 0) : 2
      msg = [_INTL("现在为闪光宝可梦。"), _INTL("现在为超闪光宝可梦。"), _INTL("现在为正常（无闪光）宝可梦。")][msg_idx]
      cmd = screen.pbShowCommands(msg, [_INTL("使闪光"), _INTL("使超闪光"),
                                        _INTL("使正常"), _INTL("重置")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Make shiny
        pkmn.shiny = true
        pkmn.super_shiny = false
      when 1   # Make super shiny
        pkmn.super_shiny = true
      when 2   # Make normal
        pkmn.shiny = false
        pkmn.super_shiny = false
      when 3   # Reset
        pkmn.shiny = nil
        pkmn.super_shiny = nil
      end
      $player.pokedex.register(pkmn) if !settingUpBattle && !pkmn.egg?
      screen.pbRefreshSingle(pkmnid)
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_pokeball, {
  "name"   => _INTL("设置球种"),
  "parent" => :cosmetic,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    commands = []
    balls = []
    GameData::Item.each do |item_data|
      balls.push([item_data.id, item_data.name]) if item_data.is_poke_ball?
    end
    balls.sort! { |a, b| a[1] <=> b[1] }
    cmd = 0
    balls.each_with_index do |ball, i|
      next if ball[0] != pkmn.poke_ball
      cmd = i
      break
    end
    balls.each { |ball| commands.push(ball[1]) }
    loop do
      oldball = GameData::Item.get(pkmn.poke_ball).name
      cmd = screen.pbShowCommands(_INTL("现在为{1}。", oldball), commands, cmd)
      break if cmd < 0
      pkmn.poke_ball = balls[cmd][0]
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_ribbons, {
  "name"   => _INTL("设置奖章"),
  "parent" => :cosmetic,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      commands = []
      ids = []
      GameData::Ribbon.each do |ribbon_data|
        commands.push(_INTL("{1} {2}",
                            (pkmn.hasRibbon?(ribbon_data.id)) ? "[Y]" : "[  ]", ribbon_data.name))
        ids.push(ribbon_data.id)
      end
      commands.push(_INTL("给予全部"))
      commands.push(_INTL("清除全部"))
      cmd = screen.pbShowCommands(_INTL("{1}奖章。", pkmn.numRibbons), commands, cmd)
      break if cmd < 0
      if cmd >= 0 && cmd < ids.length   # Toggle ribbon
        if pkmn.hasRibbon?(ids[cmd])
          pkmn.takeRibbon(ids[cmd])
        else
          pkmn.giveRibbon(ids[cmd])
        end
      elsif cmd == commands.length - 2   # Give all
        GameData::Ribbon.each do |ribbon_data|
          pkmn.giveRibbon(ribbon_data.id)
        end
      elsif cmd == commands.length - 1   # Clear all
        pkmn.clearAllRibbons
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :set_nickname, {
  "name"   => _INTL("设置昵称"),
  "parent" => :cosmetic,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      speciesname = pkmn.speciesName
      msg = [_INTL("{1}昵称为{2}", speciesname, pkmn.name),
             _INTL("{1}没有昵称", speciesname)][pkmn.nicknamed? ? 0 : 1]
      cmd = screen.pbShowCommands(msg, [_INTL("重命名"), _INTL("消除昵称")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Rename
        oldname = (pkmn.nicknamed?) ? pkmn.name : ""
        newname = pbEnterPokemonName(_INTL("{1}的昵称是？", speciesname),
                                     0, Pokemon::MAX_NAME_SIZE, oldname, pkmn)
        pkmn.name = newname
        screen.pbRefreshSingle(pkmnid)
      when 1   # Erase name
        pkmn.name = nil
        screen.pbRefreshSingle(pkmnid)
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :ownership, {
  "name"   => _INTL("所有者……"),
  "parent" => :cosmetic,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      gender = [_INTL("雄性"), _INTL("雌性"), _INTL("未知")][pkmn.owner.gender]
      msg = [_INTL("玩家的宝可梦\n{1}\n{2}\n{3}（{4}）",
                   pkmn.owner.name, gender, pkmn.owner.public_id, pkmn.owner.id),
             _INTL("外来的宝可梦\n{1}\n{2}\n{3}（{4}）",
                   pkmn.owner.name, gender, pkmn.owner.public_id, pkmn.owner.id)][pkmn.foreign?($player) ? 1 : 0]
      cmd = screen.pbShowCommands(msg,
                                  [_INTL("成为玩家的"),
                                   _INTL("设置初训名字"),
                                   _INTL("设置初训性别"),
                                   _INTL("随机外来ID"),
                                   _INTL("设置外来ID")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Make player's
        pkmn.owner = Pokemon::Owner.new_from_trainer($player)
      when 1   # Set OT's name
        pkmn.owner.name = pbEnterPlayerName(_INTL("{1}初训的名字？", pkmn.name), 1, Settings::MAX_PLAYER_NAME_SIZE)
      when 2   # Set OT's gender
        cmd2 = screen.pbShowCommands(_INTL("设置初训性别。"),
                                     [_INTL("雄性"), _INTL("雌性"), _INTL("未知")], pkmn.owner.gender)
        pkmn.owner.gender = cmd2 if cmd2 >= 0
      when 3   # Random foreign ID
        pkmn.owner.id = $player.make_foreign_ID
      when 4   # Set foreign ID
        params = ChooseNumberParams.new
        params.setRange(0, 65_535)
        params.setDefaultValue(pkmn.owner.public_id)
        val = pbMessageChooseNumber(
          _INTL("设置新ID。（最大：65535)"), params
        ) { screen.pbUpdate }
        pkmn.owner.id = val | (val << 16)
      end
    end
    next false
  }
})

#===============================================================================
# Can store/release/trade
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :set_discardable, {
  "name"   => _INTL("设置抛弃性"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = _INTL("单击选项切换。")
      cmds = []
      cmds.push((pkmn.cannot_store) ? _INTL("不能存储") : _INTL("可以存储"))
      cmds.push((pkmn.cannot_release) ? _INTL("不能放生") : _INTL("可以放生"))
      cmds.push((pkmn.cannot_trade) ? _INTL("不能交换") : _INTL("可以交换"))
      cmd = screen.pbShowCommands(msg, cmds, cmd)
      break if cmd < 0
      case cmd
      when 0   # Toggle storing
        pkmn.cannot_store = !pkmn.cannot_store
      when 1   # Toggle releasing
        pkmn.cannot_release = !pkmn.cannot_release
      when 2   # Toggle trading
        pkmn.cannot_trade = !pkmn.cannot_trade
      end
    end
    next false
  }
})

#===============================================================================
# Other options
#===============================================================================
MenuHandlers.add(:pokemon_debug_menu, :set_egg, {
  "name"        => _INTL("设置蛋"),
  "parent"      => :main,
  "always_show" => false,
  "effect"      => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = [_INTL("不是蛋"),
             _INTL("蛋（{1} 步后孵化）", pkmn.steps_to_hatch)][pkmn.egg? ? 1 : 0]
      cmd = screen.pbShowCommands(msg,
                                  [_INTL("成为蛋"),
                                   _INTL("成为宝可梦"),
                                   _INTL("孵化步数改为1")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Make egg
        if !pkmn.egg? && (pbHasEgg?(pkmn.species) ||
           screen.pbConfirm(_INTL("{1}正常情况下不可能成为蛋，确定吗？", pkmn.speciesName)))
          pkmn.level          = Settings::EGG_LEVEL
          pkmn.calc_stats
          pkmn.name           = _INTL("蛋")
          pkmn.steps_to_hatch = pkmn.species_data.hatch_steps
          pkmn.hatched_map    = 0
          pkmn.obtain_method  = 1
          screen.pbRefreshSingle(pkmnid)
        end
      when 1   # Make Pokémon
        if pkmn.egg?
          pkmn.name           = nil
          pkmn.steps_to_hatch = 0
          pkmn.hatched_map    = 0
          pkmn.obtain_method  = 0
          $player.pokedex.register(pkmn) if !settingUpBattle
          screen.pbRefreshSingle(pkmnid)
        end
      when 2   # Set steps left to 1
        pkmn.steps_to_hatch = 1 if pkmn.egg?
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :shadow_pkmn, {
  "name"   => _INTL("黑暗宝可梦……"),
  "parent" => :main,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    cmd = 0
    loop do
      msg = [_INTL("不是黑暗宝可梦"),
             _INTL("净化计{1}（阶段{2}）", pkmn.heart_gauge, pkmn.heartStage)][pkmn.shadowPokemon? ? 1 : 0]
      cmd = screen.pbShowCommands(msg, [_INTL("成为黑暗宝可梦"), _INTL("设置净化计")], cmd)
      break if cmd < 0
      case cmd
      when 0   # Make Shadow
        if pkmn.shadowPokemon?
          screen.pbDisplay(_INTL("{1}已经是黑暗宝可梦了。", pkmn.name))
        else
          pkmn.makeShadow
          screen.pbRefreshSingle(pkmnid)
        end
      when 1   # Set heart gauge
        if pkmn.shadowPokemon?
          oldheart = pkmn.heart_gauge
          params = ChooseNumberParams.new
          params.setRange(0, pkmn.max_gauge_size)
          params.setDefaultValue(pkmn.heart_gauge)
          val = pbMessageChooseNumber(
            _INTL("设置净化计（最大值：{1})", pkmn.max_gauge_size),
            params
          ) { screen.pbUpdate }
          if val != oldheart
            pkmn.adjustHeart(val - oldheart)
            pkmn.check_ready_to_purify
          end
        else
          screen.pbDisplay(_INTL("{1}不是黑暗宝可梦。", pkmn.name))
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :mystery_gift, {
  "name"        => _INTL("神秘礼物"),
  "parent"      => :main,
  "always_show" => false,
  "effect"      => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    pbCreateMysteryGift(0, pkmn)
    next false
  }
})

MenuHandlers.add(:pokemon_debug_menu, :duplicate, {
  "name"        => _INTL("复制"),
  "parent"      => :main,
  "always_show" => false,
  "effect"      => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    next false if !screen.pbConfirm(_INTL("确定要复制宝可梦吗？"))
    clonedpkmn = pkmn.clone
    case screen
    when PokemonPartyScreen
      pbStorePokemon(clonedpkmn)
      screen.pbHardRefresh
      screen.pbDisplay(_INTL("宝可梦被复制了。"))
    when PokemonStorageScreen
      if screen.storage.pbMoveCaughtToParty(clonedpkmn)
        if pkmnid[0] != -1
          screen.pbDisplay(_INTL("复制的宝可梦加入了队伍。"))
        end
      else
        oldbox = screen.storage.currentBox
        newbox = screen.storage.pbStoreCaught(clonedpkmn)
        if newbox < 0
          screen.pbDisplay(_INTL("所有盒子都满了。"))
        elsif newbox != oldbox
          screen.pbDisplay(_INTL("复制的宝可梦移动到盒子“{1}”了。", screen.storage[newbox].name))
          screen.storage.currentBox = oldbox
        end
      end
      screen.pbHardRefresh
    end
    next true
  }
})

MenuHandlers.add(:pokemon_debug_menu, :delete, {
  "name"        => _INTL("删除"),
  "parent"      => :main,
  "always_show" => false,
  "effect"      => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    next false if !screen.pbConfirm(_INTL("确定要删除此宝可梦吗？"))
    case screen
    when PokemonPartyScreen
      screen.party.delete_at(pkmnid)
      screen.pbHardRefresh
    when PokemonStorageScreen
      screen.scene.pbRelease(pkmnid, heldpoke)
      (heldpoke) ? screen.heldpkmn = nil : screen.storage.pbDelete(pkmnid[0], pkmnid[1])
      screen.scene.pbRefresh
    end
    next true
  }
})
