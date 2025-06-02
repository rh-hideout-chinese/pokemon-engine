#===============================================================================
# Field options
#===============================================================================
MenuHandlers.add(:debug_menu, :field_menu, {
  "name"        => _INTL("场地设置……"),
  "parent"      => :main,
  "description" => _INTL("切换地图、编辑开关/变量、 使用电脑、编辑培育屋等。"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :warp, {
  "name"        => _INTL("切换地图"),
  "parent"      => :field_menu,
  "description" => _INTL("立即切换到选择的另一张地图。"),
  "effect"      => proc { |sprites, viewport|
    map = pbWarpToMap
    next false if !map
    pbFadeOutAndHide(sprites)
    pbDisposeMessageWindow(sprites["textbox"])
    pbDisposeSpriteHash(sprites)
    viewport.dispose
    if $scene.is_a?(Scene_Map)
      $game_temp.player_new_map_id    = map[0]
      $game_temp.player_new_x         = map[1]
      $game_temp.player_new_y         = map[2]
      $game_temp.player_new_direction = 2
      $scene.transfer_player
    else
      pbCancelVehicles
      $map_factory.setup(map[0])
      $game_player.moveto(map[1], map[2])
      $game_player.turn_down
      $game_map.update
      $game_map.autoplay
    end
    $game_map.refresh
    next true   # Closes the debug menu to allow the warp
  }
})

MenuHandlers.add(:debug_menu, :use_pc, {
  "name"        => _INTL("使用电脑"),
  "parent"      => :field_menu,
  "description" => _INTL("使用电脑访问宝可梦存储系统和玩家电脑。"),
  "effect"      => proc {
    pbPokeCenterPC
  }
})

MenuHandlers.add(:debug_menu, :switches, {
  "name"        => _INTL("开关"),
  "parent"      => :field_menu,
  "description" => _INTL("编辑游戏所有的开关。(除了脚本开关)"),
  "effect"      => proc {
    pbDebugVariables(0)
  }
})

MenuHandlers.add(:debug_menu, :variables, {
  "name"        => _INTL("变量"),
  "parent"      => :field_menu,
  "description" => _INTL("编辑游戏的所有变量，可设置为数字或文本。"),
  "effect"      => proc {
    pbDebugVariables(1)
  }
})

MenuHandlers.add(:debug_menu, :safari_zone_and_bug_contest, {
  "name"        => _INTL("狩猎地带和捕虫大赛"),
  "parent"      => :field_menu,
  "description" => _INTL("编辑步数/剩余时间和精灵球的数量。"),
  "effect"      => proc {
    if pbInSafari?
      safari = pbSafariState
      cmd = 0
      loop do
        cmds = [_INTL("剩余步数：{1}", (Settings::SAFARI_STEPS > 0) ? safari.steps : _INTL("无限")),
                GameData::Item.get(:SAFARIBALL).name_plural + ": " + safari.ballcount.to_s]
        cmd = pbShowCommands(nil, cmds, -1, cmd)
        break if cmd < 0
        case cmd
        when 0   # Steps remaining
          if Settings::SAFARI_STEPS > 0
            params = ChooseNumberParams.new
            params.setRange(0, 99999)
            params.setDefaultValue(safari.steps)
            safari.steps = pbMessageChooseNumber(_INTL("设定此狩猎地带游戏中剩余的步数。"), params)
          end
        when 1   # Safari Balls
          params = ChooseNumberParams.new
          params.setRange(0, 99999)
          params.setDefaultValue(safari.ballcount)
          safari.ballcount = pbMessageChooseNumber(
            _INTL("设置{1}的数量。", GameData::Item.get(:SAFARIBALL).name_plural), params)
        end
      end
    elsif pbInBugContest?
      contest = pbBugContestState
      cmd = 0
      loop do
        cmds = []
        if Settings::BUG_CONTEST_TIME > 0
          time_left = Settings::BUG_CONTEST_TIME - (System.uptime - contest.timer_start).to_i
          time_left = 0 if time_left < 0
          min = time_left / 60
          sec = time_left % 60
          time_string = _ISPRINTF("{1:02d}m {2:02d}s", min, sec)
        else
          time_string = _INTL("无限")
        end
        cmds.push(_INTL("剩余时间：{1}", time_string))
        cmds.push(GameData::Item.get(:SPORTBALL).name_plural + ": " + contest.ballcount.to_s)
        cmd = pbShowCommands(nil, cmds, -1, cmd)
        break if cmd < 0
        case cmd
        when 0   # Steps remaining
          if Settings::BUG_CONTEST_TIME > 0
            params = ChooseNumberParams.new
            params.setRange(0, 99999)
            params.setDefaultValue(min)
            new_time = pbMessageChooseNumber(_INTL("设定捕虫大赛的剩余时间。（以分钟为单位）"), params)
            contest.timer_start += (new_time - min) * 60
            $scene.spriteset.usersprites.each do |sprite|
              next if !sprite.is_a?(TimerDisplay)
              sprite.start_time = contest.timer_start
              break
            end
          end
        when 1   # Safari Balls
          params = ChooseNumberParams.new
          params.setRange(0, 99999)
          params.setDefaultValue(contest.ballcount)
          contest.ballcount = pbMessageChooseNumber(
            _INTL("设置{1}的数量。", GameData::Item.get(:SPORTBALL).name_plural), params)
        end
      end
    else
      pbMessage(_INTL("你不在狩猎地带，也不在捕虫大赛！"))
    end
  }
})

MenuHandlers.add(:debug_menu, :edit_field_effects, {
  "name"        => _INTL("更改场地效果"),
  "parent"      => :field_menu,
  "description" => _INTL("编辑喷雾剂步数，怪力与闪光是否使用，以及黑色/白色玻璃哨的效果。"),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = []
      cmds.push(_INTL("喷雾剂步数：{1}", $PokemonGlobal.repel))
      cmds.push(($PokemonMap.strengthUsed ? "[Y]" : "[  ]") + " " + _INTL("怪力已使用"))
      cmds.push(($PokemonGlobal.flashUsed ? "[Y]" : "[  ]") + " " + _INTL("闪光已使用"))
      cmds.push(($PokemonMap.lower_encounter_rate ? "[Y]" : "[  ]") + " " + _INTL("更低遭遇率"))
      cmds.push(($PokemonMap.higher_encounter_rate ? "[Y]" : "[  ]") + " " + _INTL("更高遭遇率"))
      cmds.push(($PokemonMap.lower_level_wild_pokemon ? "[Y]" : "[  ]") + " " + _INTL("更高低级野生宝可梦遭遇率"))
      cmds.push(($PokemonMap.higher_level_wild_pokemon ? "[Y]" : "[  ]") + " " + _INTL("更高高级野生宝可梦遭遇率"))
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Repel steps
        params = ChooseNumberParams.new
        params.setRange(0, 99999)
        params.setDefaultValue($PokemonGlobal.repel)
        $PokemonGlobal.repel = pbMessageChooseNumber(_INTL("设置宝可梦的等级"), params)
      when 1   # Strength used
        $PokemonMap.strengthUsed = !$PokemonMap.strengthUsed
      when 2   # Flash used
        if $game_map.metadata&.dark_map && $scene.is_a?(Scene_Map)
          $PokemonGlobal.flashUsed = !$PokemonGlobal.flashUsed
          darkness = $game_temp.darkness_sprite
          darkness.dispose if darkness && !darkness.disposed?
          $game_temp.darkness_sprite = DarknessSprite.new
          $scene.spriteset&.addUserSprite($game_temp.darkness_sprite)
          if $PokemonGlobal.flashUsed
            $game_temp.darkness_sprite.radius = $game_temp.darkness_sprite.radiusMax
          end
        else
          pbMessage(_INTL("你不在黑暗的地图里！"))
        end
      when 3   # Lower encounter rate
        $PokemonMap.lower_encounter_rate ||= false
        $PokemonMap.lower_encounter_rate = !$PokemonMap.lower_encounter_rate
      when 4   # Higher encounter rate
        $PokemonMap.higher_encounter_rate ||= false
        $PokemonMap.higher_encounter_rate = !$PokemonMap.higher_encounter_rate
      when 5   # Lower level wild Pokémon
        $PokemonMap.lower_level_wild_pokemon ||= false
        $PokemonMap.lower_level_wild_pokemon = !$PokemonMap.lower_level_wild_pokemon
      when 6   # Higher level wild Pokémon
        $PokemonMap.higher_level_wild_pokemon ||= false
        $PokemonMap.higher_level_wild_pokemon = !$PokemonMap.higher_level_wild_pokemon
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :refresh_map, {
  "name"        => _INTL("刷新地图"),
  "parent"      => :field_menu,
  "description" => _INTL("使地图上的所有事件和公共事件刷新。"),
  "effect"      => proc {
    $game_map.need_refresh = true
    pbMessage(_INTL("地图将会刷新。"))
  }
})

MenuHandlers.add(:debug_menu, :day_care, {
  "name"        => _INTL("培育屋"),
  "parent"      => :field_menu,
  "description" => _INTL("查看和编辑培育屋里的宝可梦。"),
  "effect"      => proc {
    pbDebugDayCare
  }
})

MenuHandlers.add(:debug_menu, :storage_wallpapers, {
  "name"        => _INTL("决定存储壁纸"),
  "parent"      => :field_menu,
  "description" => _INTL("解锁和锁定存储中使用的壁纸。"),
  "effect"      => proc {
    w = $PokemonStorage.allWallpapers
    if w.length <= PokemonStorage::BASICWALLPAPERQTY
      pbMessage(_INTL("没有定义特殊壁纸。"))
    else
      paperscmd = 0
      unlockarray = $PokemonStorage.unlockedWallpapers
      loop do
        paperscmds = []
        paperscmds.push(_INTL("解锁全部"))
        paperscmds.push(_INTL("锁定全部"))
        (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
          paperscmds.push((unlockarray[i] ? "[Y]" : "[  ]") + " " + w[i])
        end
        paperscmd = pbShowCommands(nil, paperscmds, -1, paperscmd)
        break if paperscmd < 0
        case paperscmd
        when 0   # Unlock all
          (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
            unlockarray[i] = true
          end
        when 1   # Lock all
          (PokemonStorage::BASICWALLPAPERQTY...w.length).each do |i|
            unlockarray[i] = false
          end
        else
          paperindex = paperscmd - 2 + PokemonStorage::BASICWALLPAPERQTY
          unlockarray[paperindex] = !$PokemonStorage.unlockedWallpapers[paperindex]
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :skip_credits, {
  "name"        => _INTL("跳过致谢"),
  "parent"      => :field_menu,
  "description" => _INTL("决定是否可以通过按映射为 Use 的键提前结束致谢。"),
  "effect"      => proc {
    $PokemonGlobal.creditsPlayed = !$PokemonGlobal.creditsPlayed
    pbMessage(_INTL("之后玩家将可以跳过致谢。")) if $PokemonGlobal.creditsPlayed
    pbMessage(_INTL("之后玩家将不能跳过致谢。")) if !$PokemonGlobal.creditsPlayed
  }
})

#===============================================================================
# Battle options
#===============================================================================
MenuHandlers.add(:debug_menu, :battle_menu, {
  "name"        => _INTL("对战设置……"),
  "parent"      => :main,
  "description" => _INTL("开始对战、重置训练家，准备重战、 编辑游走宝可梦等。"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :test_wild_battle, {
  "name"        => _INTL("野生宝可梦对战测试"),
  "parent"      => :battle_menu,
  "description" => _INTL("开始一场与野生宝可梦的对战， 物种/等级由你选择。"),
  "effect"      => proc {
    species = pbChooseSpeciesList
    if species
      params = ChooseNumberParams.new
      params.setRange(1, GameData::GrowthRate.max_level)
      params.setInitialValue(5)
      params.setCancelValue(0)
      level = pbMessageChooseNumber(_INTL("设置野生的{1}的等级。",
                                          GameData::Species.get(species).name), params)
      if level > 0
        $game_temp.encounter_type = nil
        setBattleRule("canLose")
        WildBattle.start(species, level)
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_wild_battle_advanced, {
  "name"        => _INTL("高级野生宝可梦对战测试"),
  "parent"      => :battle_menu,
  "description" => _INTL("开始一场与野生宝可梦的对战， 对战规模由你选择。"),
  "effect"      => proc {
    pkmn = []
    size0 = 1
    pkmnCmd = 0
    loop do
      pkmnCmds = []
      pkmn.each { |p| pkmnCmds.push(sprintf("%s Lv.%d", p.name, p.level)) }
      pkmnCmds.push(_INTL("[添加宝可梦]"))
      pkmnCmds.push(_INTL("[设置玩家方规模]"))
      pkmnCmds.push(_INTL("[开始{1}v{2}对战]", size0, pkmn.length))
      pkmnCmd = pbShowCommands(nil, pkmnCmds, -1, pkmnCmd)
      break if pkmnCmd < 0
      if pkmnCmd == pkmnCmds.length - 1      # Start battle
        if pkmn.length == 0
          pbMessage(_INTL("没有选择宝可梦，不能开始对战。"))
          next
        end
        setBattleRule(sprintf("%dv%d", size0, pkmn.length))
        setBattleRule("canLose")
        $game_temp.encounter_type = nil
        WildBattle.start(*pkmn)
        break
      elsif pkmnCmd == pkmnCmds.length - 2   # Set player side size
        if !pbCanDoubleBattle?
          pbMessage(_INTL("你只有一只宝可梦。"))
          next
        end
        maxVal = (pbCanTripleBattle?) ? 3 : 2
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size0)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("选择玩家方的对战宝可梦数（最大：{1}）。", maxVal), params
        )
        size0 = newSize if newSize > 0
      elsif pkmnCmd == pkmnCmds.length - 3   # Add Pokémon
        species = pbChooseSpeciesList
        if species
          params = ChooseNumberParams.new
          params.setRange(1, GameData::GrowthRate.max_level)
          params.setInitialValue(5)
          params.setCancelValue(0)
          level = pbMessageChooseNumber(_INTL("设置野生的{1}的等级。",
                                              GameData::Species.get(species).name), params)
          if level > 0
            pkmn.push(pbGenerateWildPokemon(species, level))
            size0 = pkmn.length
          end
        end
      else                                   # Edit a Pokémon
        if pbConfirmMessage(_INTL("修改宝可梦？"))
          scr = PokemonDebugPartyScreen.new
          scr.pbPokemonDebug(pkmn[pkmnCmd], -1, nil, true)
          scr.pbEndScreen
        elsif pbConfirmMessage(_INTL("删除宝可梦？"))
          pkmn.delete_at(pkmnCmd)
          size0 = [pkmn.length, 1].max
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_trainer_battle, {
  "name"        => _INTL("训练家对战测试"),
  "parent"      => :battle_menu,
  "description" => _INTL("与选择的训练家开始对战。"),
  "effect"      => proc {
    trainerdata = pbListScreen(_INTL("单人测试"), TrainerBattleLister.new(0, false))
    if trainerdata
      setBattleRule("canLose")
      TrainerBattle.start(trainerdata[0], trainerdata[1], trainerdata[2])
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :test_trainer_battle_advanced, {
  "name"        => _INTL("高级训练家对战测试"),
  "parent"      => :battle_menu,
  "description" => _INTL("与选择的训练家开始对战， 对战规模由你选择。"),
  "effect"      => proc {
    trainers = []
    size0 = 1
    size1 = 1
    trainerCmd = 0
    loop do
      trainerCmds = []
      trainers.each { |t| trainerCmds.push(sprintf("%s x%d", t[1].full_name, t[1].party_count)) }
      trainerCmds.push(_INTL("[添加训练家]"))
      trainerCmds.push(_INTL("[设置玩家方规模]"))
      trainerCmds.push(_INTL("[设置对手方规模]"))
      trainerCmds.push(_INTL("[开始{1}v{2}对战]", size0, size1))
      trainerCmd = pbShowCommands(nil, trainerCmds, -1, trainerCmd)
      break if trainerCmd < 0
      if trainerCmd == trainerCmds.length - 1      # Start battle
        if trainers.length == 0
          pbMessage(_INTL("没有选择训练家，不能开始对战。"))
          next
        elsif size1 < trainers.length
          pbMessage(_INTL("对手规模大小无效，最小要是{1}。", trainers.length))
          next
        elsif size1 > trainers.length && trainers[0][1].party_count == 1
          pbMessage(
            _INTL("对手规模不能是{1}，这需要第一个训练家有两只或以上的宝可梦。",
                  size1)
          )
          next
        end
        setBattleRule(sprintf("%dv%d", size0, size1))
        setBattleRule("canLose")
        battleArgs = []
        trainers.each { |t| battleArgs.push(t[1]) }
        TrainerBattle.start(*battleArgs)
        break
      elsif trainerCmd == trainerCmds.length - 2   # Set opponent side size
        if trainers.length == 0 || (trainers.length == 1 && trainers[0][1].party_count == 1)
          pbMessage(_INTL("没有选择训练家或训练家只有一只宝可梦。"))
          next
        end
        maxVal = 2
        maxVal = 3 if trainers.length >= 3 ||
                      (trainers.length == 2 && trainers[0][1].party_count >= 2) ||
                      trainers[0][1].party_count >= 3
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size1)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("选择对手方的对战宝可梦数（最大：{1}）。", maxVal), params
        )
        size1 = newSize if newSize > 0
      elsif trainerCmd == trainerCmds.length - 3   # Set player side size
        if !pbCanDoubleBattle?
          pbMessage(_INTL("你只有一只宝可梦。"))
          next
        end
        maxVal = (pbCanTripleBattle?) ? 3 : 2
        params = ChooseNumberParams.new
        params.setRange(1, maxVal)
        params.setInitialValue(size0)
        params.setCancelValue(0)
        newSize = pbMessageChooseNumber(
          _INTL("选择玩家方的对战宝可梦数（最大：{1}）。", maxVal), params
        )
        size0 = newSize if newSize > 0
      elsif trainerCmd == trainerCmds.length - 4   # Add trainer
        trainerdata = pbListScreen(_INTL("选择训练家"), TrainerBattleLister.new(0, false))
        if trainerdata
          tr = pbLoadTrainer(trainerdata[0], trainerdata[1], trainerdata[2])
          EventHandlers.trigger(:on_trainer_load, tr)
          trainers.push([0, tr])
          size0 = trainers.length
          size1 = trainers.length
        end
      else                                         # Edit a trainer
        if pbConfirmMessage(_INTL("修改此训练家"))
          trainerdata = pbListScreen(_INTL("选择训练家"),
                                     TrainerBattleLister.new(trainers[trainerCmd][0], false))
          if trainerdata
            tr = pbLoadTrainer(trainerdata[0], trainerdata[1], trainerdata[2])
            EventHandlers.trigger(:on_trainer_load, tr)
            trainers[trainerCmd] = [0, tr]
          end
        elsif pbConfirmMessage(_INTL("删除训练家？"))
          trainers.delete_at(trainerCmd)
          size0 = [trainers.length, 1].max
          size1 = [trainers.length, 1].max
        end
      end
    end
    next false
  }
})

MenuHandlers.add(:debug_menu, :encounter_version, {
  "name"        => _INTL("设置野生宝可梦遭遇版本"),
  "parent"      => :battle_menu,
  "description" => _INTL("选择应该使用哪个版本的 野生宝可梦遭遇。"),
  "effect"      => proc {
    params = ChooseNumberParams.new
    params.setRange(0, 99)
    params.setInitialValue($PokemonGlobal.encounter_version)
    params.setCancelValue(-1)
    value = pbMessageChooseNumber(_INTL("将遭遇版本设置为什么值？"), params)
    $PokemonGlobal.encounter_version = value if value >= 0
  }
})

MenuHandlers.add(:debug_menu, :roamers, {
  "name"        => _INTL("游走宝可梦"),
  "parent"      => :battle_menu,
  "description" => _INTL("切换和编辑游走宝可梦。"),
  "effect"      => proc {
    pbDebugRoamers
  }
})

MenuHandlers.add(:debug_menu, :reset_trainers, {
  "name"        => _INTL("重置地图的训练家"),
  "parent"      => :battle_menu,
  "description" => _INTL("关闭所有名称中有“Trainer”的事件 的独立开关A，B。"),
  "effect"      => proc {
    if $game_map
      $game_map.events.each_value do |event|
        if event.name[/trainer/i]
          $game_self_switches[[$game_map.map_id, event.id, "A"]] = false
          $game_self_switches[[$game_map.map_id, event.id, "B"]] = false
        end
      end
      $game_map.need_refresh = true
      pbMessage(_INTL("地图上的训练家都被重置了。"))
    else
      pbMessage(_INTL("这个命令不能在这里使用。"))
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_exp_all, {
  "name"        => _INTL("决定经验效果"),
  "parent"      => :battle_menu,
  "description" => _INTL("决定是否要给未参与者提供经验。"),
  "effect"      => proc {
    $player.has_exp_all = !$player.has_exp_all
    pbMessage(_INTL("启用全体经验。")) if $player.has_exp_all
    pbMessage(_INTL("禁用全体经验。")) if !$player.has_exp_all
  }
})

MenuHandlers.add(:debug_menu, :toggle_logging, {
  "name"        => _INTL("对战信息记录"),
  "parent"      => :battle_menu,
  "description" => _INTL("决定是否在 Data/debuglog.txt 中记录对战调试日志。"),
  "effect"      => proc {
    $INTERNAL = !$INTERNAL
    pbMessage(_INTL("对战调试日志将保存在 Data 文件夹中。")) if $INTERNAL
    pbMessage(_INTL("不生成对战的调试日志。")) if !$INTERNAL
  }
})

#===============================================================================
# Pokémon options
#===============================================================================
MenuHandlers.add(:debug_menu, :pokemon_menu, {
  "name"        => _INTL("宝可梦设置……"),
  "parent"      => :main,
  "description" => _INTL("治疗队伍、添加宝可梦、 填充/清空电脑存储等。"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :heal_party, {
  "name"        => _INTL("治疗队伍"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("治疗队伍中的所有宝可梦。 （HP/状态/PP）"),
  "effect"      => proc {
    $player.party.each { |pkmn| pkmn.heal }
    pbMessage(_INTL("宝可梦治疗完毕。"))
  }
})

MenuHandlers.add(:debug_menu, :add_pokemon, {
  "name"        => _INTL("添加宝可梦"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("添加一个宝可梦，物种/等级由你选择。"),
  "effect"      => proc {
    species = pbChooseSpeciesList
    if species
      params = ChooseNumberParams.new
      params.setRange(1, GameData::GrowthRate.max_level)
      params.setInitialValue(5)
      params.setCancelValue(0)
      level = pbMessageChooseNumber(_INTL("设置宝可梦的等级。"), params)
      if level > 0
        goes_to_party = !$player.party_full?
        if pbAddPokemonSilent(species, level)
          if goes_to_party
            pbMessage(_INTL("{1}加入队伍了。", GameData::Species.get(species).name))
          else
            pbMessage(_INTL("{1}发送到电脑了。", GameData::Species.get(species).name))
          end
        else
          pbMessage(_INTL("无法添加宝可梦，因为队伍和电脑没有空间了。"))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :fill_boxes, {
  "name"        => _INTL("添加全部宝可梦"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("将所有物种的宝可梦添加到电脑。 （等级50）"),
  "effect"      => proc {
    added = 0
    box_qty = $PokemonStorage.maxPokemon(0)
    completed = true
    GameData::Species.each do |species_data|
      sp = species_data.species
      f = species_data.form
      # Record each form of each species as seen and owned
      if f == 0
        if species_data.single_gendered?
          g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
          $player.pokedex.register(sp, g, f, 0, false)
          $player.pokedex.register(sp, g, f, 1, false)
        else   # Both male and female
          $player.pokedex.register(sp, 0, f, 0, false)
          $player.pokedex.register(sp, 0, f, 1, false)
          $player.pokedex.register(sp, 1, f, 0, false)
          $player.pokedex.register(sp, 1, f, 1, false)
        end
        $player.pokedex.set_owned(sp, false)
      elsif species_data.real_form_name && !species_data.real_form_name.empty?
        g = (species_data.gender_ratio == :AlwaysFemale) ? 1 : 0
        $player.pokedex.register(sp, g, f, 0, false)
        $player.pokedex.register(sp, g, f, 1, false)
      end
      # Add Pokémon (if form 0, i.e. one of each species)
      next if f != 0
      if added >= Settings::NUM_STORAGE_BOXES * box_qty
        completed = false
        next
      end
      added += 1
      $PokemonStorage[(added - 1) / box_qty, (added - 1) % box_qty] = Pokemon.new(sp, 50)
    end
    $player.pokedex.refresh_accessible_dexes
    pbMessage(_INTL("电脑里添加了所有物种的宝可梦。"))
    if !completed
      pbMessage(_INTL("注：存储空间数量小于物种数量。（每{1}盒为{2}个）",
                      Settings::NUM_STORAGE_BOXES, box_qty))
    end
  }
})

MenuHandlers.add(:debug_menu, :clear_boxes, {
  "name"        => _INTL("清除存储宝可梦"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("移除电脑里的所有神奇宝贝。"),
  "effect"      => proc {
    $PokemonStorage.maxBoxes.times do |i|
      $PokemonStorage.maxPokemon(i).times do |j|
        $PokemonStorage[i, j] = nil
      end
    end
    pbMessage(_INTL("箱子被清空了。"))
  }
})

MenuHandlers.add(:debug_menu, :give_demo_party, {
  "name"        => _INTL("获得演示队伍"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("获得6个演示宝可梦，当前队伍会被覆盖。"),
  "effect"      => proc {
    party = []
    species = [:PIKACHU, :PIDGEOTTO, :KADABRA, :GYARADOS, :DIGLETT, :CHANSEY]
    species.each { |id| party.push(id) if GameData::Species.exists?(id) }
    $player.party.clear
    # Generate Pokémon of each species at level 20
    party.each do |spec|
      pkmn = Pokemon.new(spec, 20)
      $player.party.push(pkmn)
      $player.pokedex.register(pkmn)
      $player.pokedex.set_owned(spec)
      case spec
      when :PIDGEOTTO
        pkmn.learn_move(:FLY)
      when :KADABRA
        pkmn.learn_move(:FLASH)
        pkmn.learn_move(:TELEPORT)
      when :GYARADOS
        pkmn.learn_move(:SURF)
        pkmn.learn_move(:DIVE)
        pkmn.learn_move(:WATERFALL)
      when :DIGLETT
        pkmn.learn_move(:DIG)
        pkmn.learn_move(:CUT)
        pkmn.learn_move(:HEADBUTT)
        pkmn.learn_move(:ROCKSMASH)
      when :CHANSEY
        pkmn.learn_move(:SOFTBOILED)
        pkmn.learn_move(:STRENGTH)
        pkmn.learn_move(:SWEETSCENT)
      end
      pkmn.record_first_moves
    end
    pbMessage(_INTL("获得了演示宝可梦。"))
  }
})

MenuHandlers.add(:debug_menu, :quick_hatch_party_eggs, {
  "name"        => _INTL("快速孵化队伍里所有蛋"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("使队伍里的所有蛋只需要 一步就可以孵化。"),
  "effect"      => proc {
    $player.party.each { |pkmn| pkmn.steps_to_hatch = 1 if pkmn.egg? }
    pbMessage(_INTL("现在队伍里的蛋只需要 一步就可以孵化了。"))
  }
})

MenuHandlers.add(:debug_menu, :open_storage, {
  "name"        => _INTL("访问宝可梦存储系统"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("在整理盒子的模式下 打开宝可梦存储系统。"),
  "effect"      => proc {
    pbFadeOutIn do
      scene = PokemonStorageScene.new
      screen = PokemonStorageScreen.new(scene, $PokemonStorage)
      screen.pbStartScreen(0)
    end
  }
})

#===============================================================================
# Shadow Pokémon options
#===============================================================================
MenuHandlers.add(:debug_menu, :shadow_pokemon_menu, {
  "name"        => _INTL("黑暗宝可梦设置……"),
  "parent"      => :pokemon_menu,
  "description" => _INTL("夺取器和净化"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :toggle_snag_machine, {
  "name"        => _INTL("决定是否拥有夺取器"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("决定是否所有类别的精灵球都可以抓住黑 暗宝可梦。"),
  "effect"      => proc {
    $player.has_snag_machine = !$player.has_snag_machine
    pbMessage(_INTL("获得了夺取器。")) if $player.has_snag_machine
    pbMessage(_INTL("失去了夺取器。")) if !$player.has_snag_machine
  }
})

MenuHandlers.add(:debug_menu, :toggle_purify_chamber_access, {
  "name"        => _INTL("决定净化室访问权限"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("决定能否通过PC访问净化室。"),
  "effect"      => proc {
    $player.seen_purify_chamber = !$player.seen_purify_chamber
    pbMessage(_INTL("净化室现在可以访问了。")) if $player.seen_purify_chamber
    pbMessage(_INTL("净化室现在不可以访问。")) if !$player.seen_purify_chamber
  }
})

MenuHandlers.add(:debug_menu, :purify_chamber, {
  "name"        => _INTL("使用净化室"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("打开净化室，净化黑暗宝可梦。"),
  "effect"      => proc {
    pbPurifyChamber
  }
})

MenuHandlers.add(:debug_menu, :relic_stone, {
  "name"        => _INTL("使用遗迹石"),
  "parent"      => :shadow_pokemon_menu,
  "description" => _INTL("选择一个黑暗宝可梦让遗迹石进行净化。"),
  "effect"      => proc {
    pbRelicStone
  }
})

#===============================================================================
# Item options
#===============================================================================
MenuHandlers.add(:debug_menu, :items_menu, {
  "name"        => _INTL("道具设置"),
  "parent"      => :main,
  "description" => _INTL("获得和丢弃道具。"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :add_item, {
  "name"        => _INTL("添加道具"),
  "parent"      => :items_menu,
  "description" => _INTL("选择一个道具添加到包中。"),
  "effect"      => proc {
    pbListScreenBlock(_INTL("添加道具"), ItemLister.new) do |button, item|
      if button == Input::USE && item
        params = ChooseNumberParams.new
        params.setRange(1, Settings::BAG_MAX_PER_SLOT)
        params.setInitialValue(1)
        params.setCancelValue(0)
        qty = pbMessageChooseNumber(_INTL("添加多少{1}？",
                                          GameData::Item.get(item).name_plural), params)
        if qty > 0
          $bag.add(item, qty)
          pbMessage(_INTL("获得了{1}x{2}。", qty, GameData::Item.get(item).name))
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :fill_bag, {
  "name"        => _INTL("添加全部道具"),
  "parent"      => :items_menu,
  "description" => _INTL("清空当前的背包，然后添加全部道具。"),
  "effect"      => proc {
    params = ChooseNumberParams.new
    params.setRange(1, Settings::BAG_MAX_PER_SLOT)
    params.setInitialValue(1)
    params.setCancelValue(0)
    qty = pbMessageChooseNumber(_INTL("选择每种道具要添加的数量"), params)
    if qty > 0
      $bag.clear
      # NOTE: This doesn't simply use $bag.add for every item in turn, because
      #       that's really slow when done in bulk.
      pocket_sizes = Settings::BAG_MAX_POCKET_SIZE
      bag = $bag.pockets   # Called here so that it only rearranges itself once
      GameData::Item.each do |i|
        next if !pocket_sizes[i.pocket - 1] || pocket_sizes[i.pocket - 1] == 0
        next if pocket_sizes[i.pocket - 1] > 0 && bag[i.pocket].length >= pocket_sizes[i.pocket - 1]
        item_qty = (i.is_important?) ? 1 : qty
        bag[i.pocket].push([i.id, item_qty])
      end
      # NOTE: Auto-sorting pockets don't need to be sorted afterwards, because
      #       items are added in the same order they would be sorted into.
      pbMessage(_INTL("背包添加了全部道具，每种数量为{1}。", qty))
    end
  }
})

MenuHandlers.add(:debug_menu, :empty_bag, {
  "name"        => _INTL("清空背包"),
  "parent"      => :items_menu,
  "description" => _INTL("移除包里的所有道具。"),
  "effect"      => proc {
    $bag.clear
    pbMessage(_INTL("背包被清空了"))
  }
})

#===============================================================================
# Player options
#===============================================================================
MenuHandlers.add(:debug_menu, :player_menu, {
  "name"        => _INTL("玩家设置……"),
  "parent"      => :main,
  "description" => _INTL("设置金钱，徽章，图鉴，外观、名称等。"),
  "always_show" => false
})

MenuHandlers.add(:debug_menu, :set_money, {
  "name"        => _INTL("设置货币"),
  "parent"      => :player_menu,
  "description" => _INTL("编辑拥有的金钱、游戏代币和对战点数。"),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = [_INTL("金钱：${1}", $player.money.to_s_formatted),
              _INTL("代币：{1}", $player.coins.to_s_formatted),
              _INTL("对战点数：{1}", $player.battle_points.to_s_formatted)]
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Money
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_MONEY)
        params.setDefaultValue($player.money)
        $player.money = pbMessageChooseNumber("\\ts[]" + _INTL("设置玩家的金钱。"), params)
      when 1   # Coins
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_COINS)
        params.setDefaultValue($player.coins)
        $player.coins = pbMessageChooseNumber("\\ts[]" + _INTL("设置玩家的代币。"), params)
      when 2   # Battle Points
        params = ChooseNumberParams.new
        params.setRange(0, Settings::MAX_BATTLE_POINTS)
        params.setDefaultValue($player.battle_points)
        $player.battle_points = pbMessageChooseNumber("\\ts[]" + _INTL("设置玩家的对战点数。"), params)
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :set_badges, {
  "name"        => _INTL("设置道馆徽章"),
  "parent"      => :player_menu,
  "description" => _INTL("决定是否拥有道馆徽章。"),
  "effect"      => proc {
    badgecmd = 0
    loop do
      badgecmds = []
      badgecmds.push(_INTL("获得全部"))
      badgecmds.push(_INTL("移除全部"))
      24.times do |i|
        badgecmds.push(($player.badges[i] ? "[Y]" : "[  ]") + " " + _INTL("徽章{1}", i + 1))
      end
      badgecmd = pbShowCommands(nil, badgecmds, -1, badgecmd)
      break if badgecmd < 0
      case badgecmd
      when 0   # Give all
        24.times { |i| $player.badges[i] = true }
      when 1   # Remove all
        24.times { |i| $player.badges[i] = false }
      else
        $player.badges[badgecmd - 2] = !$player.badges[badgecmd - 2]
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_running_shoes, {
  "name"        => _INTL("决定跑鞋"),
  "parent"      => :player_menu,
  "description" => _INTL("决定是否拥有跑鞋。"),
  "effect"      => proc {
    $player.has_running_shoes = !$player.has_running_shoes
    pbMessage(_INTL("获得了跑鞋。")) if $player.has_running_shoes
    pbMessage(_INTL("失去了跑鞋。")) if !$player.has_running_shoes
  }
})

MenuHandlers.add(:debug_menu, :toggle_pokedex, {
  "name"        => _INTL("决定图鉴和地区图鉴"),
  "parent"      => :player_menu,
  "description" => _INTL("决定是否拥有图鉴和地区图鉴是否开启。"),
  "effect"      => proc {
    dexescmd = 0
    loop do
      dexescmds = []
      dexescmds.push(_INTL("拥有图鉴：{1}", $player.has_pokedex ? "[YES]" : "[NO]"))
      dex_names = Settings.pokedex_names
      dex_names.length.times do |i|
        name = (dex_names[i].is_a?(Array)) ? dex_names[i][0] : dex_names[i]
        unlocked = $player.pokedex.unlocked?(i)
        dexescmds.push((unlocked ? "[Y]" : "[  ]") + " " + name)
      end
      dexescmd = pbShowCommands(nil, dexescmds, -1, dexescmd)
      break if dexescmd < 0
      dexindex = dexescmd - 1
      if dexindex < 0   # Toggle Pokédex ownership
        $player.has_pokedex = !$player.has_pokedex
      elsif $player.pokedex.unlocked?(dexindex)   # Toggle Regional Dex accessibility
        $player.pokedex.lock(dexindex)
      else
        $player.pokedex.unlock(dexindex)
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_pokegear, {
  "name"        => _INTL("决定宝可装置"),
  "parent"      => :player_menu,
  "description" => _INTL("决定是否拥有宝可装置。"),
  "effect"      => proc {
    $player.has_pokegear = !$player.has_pokegear
    pbMessage(_INTL("获得了宝可装置。")) if $player.has_pokegear
    pbMessage(_INTL("失去了宝可装置。")) if !$player.has_pokegear
  }
})

MenuHandlers.add(:debug_menu, :edit_phone_contacts, {
  "name"        => _INTL("编辑电话和联系人"),
  "parent"      => :player_menu,
  "description" => _INTL("编辑电话和注册的联系人的属性。"),
  "effect"      => proc {
    if !$PokemonGlobal.phone
      pbMessage(_INTL("没有定义电话。"))
      next
    end
    cmd = 0
    loop do
      cmds = []
      time = $PokemonGlobal.phone.time_to_next_call.to_i   # time is in seconds
      min = time / 60
      sec = time % 60
      cmds.push(_INTL("距离下次呼叫的时间：{1}分 {2}秒", min, sec))
      cmds.push((Phone.rematches_enabled ? "[Y]" : "[  ]") + " " + _INTL("重战可能"))
      cmds.push(_INTL("重战的最高版本：{1}", Phone.rematch_variant))
      if $PokemonGlobal.phone.contacts.length > 0
        cmds.push(_INTL("令所有联系人准备好重新对战"))
        cmds.push(_INTL("编辑个人联系人：{1}", $PokemonGlobal.phone.contacts.length))
      end
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0   # Time until next call
        params = ChooseNumberParams.new
        params.setRange(0, 99999)
        params.setDefaultValue(min)
        params.setCancelValue(-1)
        new_time = pbMessageChooseNumber(_INTL("设置距下一通电话的时间。（单位：分钟）"), params)
        $PokemonGlobal.phone.time_to_next_call = new_time * 60 if new_time >= 0
      when 1   # Rematches possible
        Phone.rematches_enabled = !Phone.rematches_enabled
      when 2   # Maximum rematch version
        params = ChooseNumberParams.new
        params.setRange(0, 99)
        params.setDefaultValue(Phone.rematch_variant)
        new_version = pbMessageChooseNumber(_INTL("设置训练家联系人可以到达的最高版本。"), params)
        Phone.rematch_variant = new_version
      when 3   # Make all contacts ready for a rematch
        $PokemonGlobal.phone.contacts.each do |contact|
          next if !contact.trainer?
          contact.rematch_flag = 1
          contact.set_trainer_event_ready_for_rematch
        end
        pbMessage(_INTL("电话里的所有训练家现在准备好重战了"))
      when 4   # Edit individual contacts
        contact_cmd = 0
        loop do
          contact_cmds = []
          $PokemonGlobal.phone.contacts.each do |contact|
            visible_string = (contact.visible?) ? "[Y]" : "[  ]"
            if contact.trainer?
              battle_string = (contact.can_rematch?) ? "(can battle)" : ""
              contact_cmds.push(sprintf("%s %s (%i) %s", visible_string, contact.display_name, contact.variant, battle_string))
            else
              contact_cmds.push(sprintf("%s %s", visible_string, contact.display_name))
            end
          end
          contact_cmd = pbShowCommands(nil, contact_cmds, -1, contact_cmd)
          break if contact_cmd < 0
          contact = $PokemonGlobal.phone.contacts[contact_cmd]
          edit_cmd = 0
          loop do
            edit_cmds = []
            edit_cmds.push((contact.visible? ? "[Y]" : "[  ]") + " " + _INTL("联系人可见"))
            if contact.trainer?
              edit_cmds.push((contact.can_rematch? ? "[Y]" : "[  ]") + " " + _INTL("可对战"))
              ready_time = contact.time_to_ready   # time is in seconds
              ready_min = ready_time / 60
              ready_sec = ready_time % 60
              edit_cmds.push(_INTL("准备战斗的时间：{1}分{2}秒", ready_min, ready_sec))
              edit_cmds.push(_INTL("上次击败的版本：{1}", contact.variant))
            end
            break if edit_cmds.length == 0
            edit_cmd = pbShowCommands(nil, edit_cmds, -1, edit_cmd)
            break if edit_cmd < 0
            case edit_cmd
            when 0   # Visibility
              contact.visible = !contact.visible if contact.can_hide?
            when 1   # Can battle
              contact.rematch_flag = (contact.can_rematch?) ? 0 : 1
              contact.time_to_ready = 0 if contact.can_rematch?
            when 2   # Time until ready to battle
              params = ChooseNumberParams.new
              params.setRange(0, 99999)
              params.setDefaultValue(ready_min)
              params.setCancelValue(-1)
              new_time = pbMessageChooseNumber(_INTL("设置训练家准备战斗的时间。（单位：分钟）"), params)
              contact.time_to_ready = new_time * 60 if new_time >= 0
            when 3   # Last defeated version
              params = ChooseNumberParams.new
              params.setRange(0, 99)
              params.setDefaultValue(contact.variant)
              new_version = pbMessageChooseNumber(_INTL("设置此训练家上次击败的的版本。"), params)
              contact.version = contact.start_version + new_version
            end
          end
        end
      end
    end
  }
})

MenuHandlers.add(:debug_menu, :toggle_box_link, {
  "name"        => _INTL("决定队伍访问存储"),
  "parent"      => :player_menu,
  "description" => _INTL("决定是否可以在队伍界面访问存储系统。"),
  "effect"      => proc {
    $player.has_box_link = !$player.has_box_link
    pbMessage(_INTL("已启用从队伍界面访问存储系统。")) if $player.has_box_link
    pbMessage(_INTL("已禁用从队伍界面访问存储系统。")) if !$player.has_box_link
  }
})

MenuHandlers.add(:debug_menu, :set_player_character, {
  "name"        => _INTL("设置玩家角色"),
  "parent"      => :player_menu,
  "description" => _INTL("切换“metadata.txt”中定义的玩家角色。"),
  "effect"      => proc {
    index = 0
    cmds = []
    ids = []
    GameData::PlayerMetadata.each do |player|
      index = cmds.length if player.id == $player.character_ID
      cmds.push(player.id.to_s)
      ids.push(player.id)
    end
    if cmds.length == 1
      pbMessage(_INTL("只定义了一个角色。"))
      break
    end
    cmd = pbShowCommands(nil, cmds, -1, index)
    if cmd >= 0 && cmd != index
      pbChangePlayer(ids[cmd])
      pbMessage(_INTL("玩家的角色改变了。"))
    end
  }
})

MenuHandlers.add(:debug_menu, :change_outfit, {
  "name"        => _INTL("设置玩家装扮"),
  "parent"      => :player_menu,
  "description" => _INTL("编辑玩家的装扮。"),
  "effect"      => proc {
    oldoutfit = $player.outfit
    params = ChooseNumberParams.new
    params.setRange(0, 99)
    params.setDefaultValue(oldoutfit)
    $player.outfit = pbMessageChooseNumber(_INTL("设置玩家的装扮"), params)
    pbMessage(_INTL("玩家的装扮改变了。")) if $player.outfit != oldoutfit
  }
})

MenuHandlers.add(:debug_menu, :rename_player, {
  "name"        => _INTL("设置玩家名称"),
  "parent"      => :player_menu,
  "description" => _INTL("重命名玩家的名称。"),
  "effect"      => proc {
    trname = pbEnterPlayerName("Your name?", 0, Settings::MAX_PLAYER_NAME_SIZE, $player.name)
    if nil_or_empty?(trname) && pbConfirmMessage(_INTL("给你自己取默认名？"))
      trainertype = $player.trainer_type
      gender      = pbGetTrainerTypeGender(trainertype)
      trname      = pbSuggestTrainerName(gender)
    end
    if nil_or_empty?(trname)
      pbMessage(_INTL("玩家的名字仍然是{1}。", $player.name))
    else
      $player.name = trname
      pbMessage(_INTL("玩家的名字修改为{1}。", $player.name))
    end
  }
})

MenuHandlers.add(:debug_menu, :random_id, {
  "name"        => _INTL("随机设置玩家ID"),
  "parent"      => :player_menu,
  "description" => _INTL("为玩家随机生成一个新的ID。"),
  "effect"      => proc {
    $player.id = rand(2**16) | (rand(2**16) << 16)
    pbMessage(_INTL("玩家 ID 修改为{1}（完整 ID：{2}）。", $player.public_ID, $player.id))
  }
})

#===============================================================================
# PBS file editors
#===============================================================================
MenuHandlers.add(:debug_menu, :pbs_editors_menu, {
  "name"        => _INTL("PBS文件编辑……"),
  "parent"      => :main,
  "description" => _INTL("编辑PBS文件中的信息。")
})

MenuHandlers.add(:debug_menu, :set_map_connections, {
  "name"        => _INTL("编辑map_connections.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("使用可视化界面连接地图，还可以编辑地 图的遭遇/元数据。"),
  "effect"      => proc {
    pbFadeOutIn { pbConnectionsEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_encounters, {
  "name"        => _INTL("编辑encounters.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑地图可以遇到的野生宝可梦以及遇到 的方式。"),
  "effect"      => proc {
    pbFadeOutIn { pbEncountersEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_trainers, {
  "name"        => _INTL("编辑trainers.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑训练家，他们的宝可梦和道具。"),
  "effect"      => proc {
    pbFadeOutIn { pbTrainerBattleEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_trainer_types, {
  "name"        => _INTL("编辑trainer_types.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑训练家类型的属性。"),
  "effect"      => proc {
    pbFadeOutIn { pbTrainerTypeEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_map_metadata, {
  "name"        => _INTL("编辑map_metadata.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑地图的元数据。"),
  "effect"      => proc {
    pbMapMetadataScreen(pbDefaultMap)
  }
})

MenuHandlers.add(:debug_menu, :set_metadata, {
  "name"        => _INTL("编辑metadata.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑全局元数据和玩家角色元数据。"),
  "effect"      => proc {
    pbMetadataScreen
  }
})

MenuHandlers.add(:debug_menu, :set_items, {
  "name"        => _INTL("编辑items.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑道具数据。"),
  "effect"      => proc {
    pbFadeOutIn { pbItemEditor }
  }
})

MenuHandlers.add(:debug_menu, :set_species, {
  "name"        => _INTL("编辑pokemon.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑神奇宝贝物种数据。"),
  "effect"      => proc {
    pbFadeOutIn { pbPokemonEditor }
  }
})

MenuHandlers.add(:debug_menu, :position_sprites, {
  "name"        => _INTL("编辑pokemon_metrics.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("调整对战时宝可梦图像位置。"),
  "effect"      => proc {
    pbFadeOutIn do
      sp = SpritePositioner.new
      sps = SpritePositionerScreen.new(sp)
      sps.pbStart
    end
  }
})

MenuHandlers.add(:debug_menu, :auto_position_sprites, {
  "name"        => _INTL("自动设置pokemon_metrics.txts"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("自动调整所有对战时宝可梦图像位置，不 要轻易使用。"),
  "effect"      => proc {
    if pbConfirmMessage(_INTL("确定要调整所有图像的位置吗？"))
      msgwindow = pbCreateMessageWindow
      pbMessageDisplay(msgwindow, _INTL("重新定位所有图像中，请稍候。"), false)
      Graphics.update
      pbAutoPositionAll
      pbDisposeMessageWindow(msgwindow)
    end
  }
})

MenuHandlers.add(:debug_menu, :set_pokedex_lists, {
  "name"        => _INTL("编辑regional_dexes.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("创建、重新排列和删除地区宝可梦索引列 表。"),
  "effect"      => proc {
    pbFadeOutIn { pbRegionalDexEditorMain }
  }
})

#===============================================================================
# Other editors
#===============================================================================
MenuHandlers.add(:debug_menu, :editors_menu, {
  "name"        => _INTL("其他编辑……"),
  "parent"      => :main,
  "description" => _INTL("编辑战斗动画、地形标签、地图数据等。")
})

MenuHandlers.add(:debug_menu, :animation_editor, {
  "name"        => _INTL("对战动画编辑器"),
  "parent"      => :editors_menu,
  "description" => _INTL("编辑对战动画"),
  "effect"      => proc {
    pbFadeOutIn { pbAnimationEditor }
  }
})

MenuHandlers.add(:debug_menu, :animation_organiser, {
  "name"        => _INTL("整理对战动画"),
  "parent"      => :editors_menu,
  "description" => _INTL("重新排列/添加/删除对战动画。"),
  "effect"      => proc {
    pbFadeOutIn { pbAnimationsOrganiser }
  }
})

MenuHandlers.add(:debug_menu, :import_animations, {
  "name"        => _INTL("导入所有战斗动画"),
  "parent"      => :editors_menu,
  "description" => _INTL("从“Animations”文件 夹中导入所有战斗动画。"),
  "effect"      => proc {
    pbImportAllAnimations
  }
})

MenuHandlers.add(:debug_menu, :export_animations, {
  "name"        => _INTL("导出所有战斗动画"),
  "parent"      => :editors_menu,
  "description" => _INTL("将所有战斗动画导出到“Animations” 文件夹。"),
  "effect"      => proc {
    pbExportAllAnimations
  }
})

MenuHandlers.add(:debug_menu, :set_terrain_tags, {
  "name"        => _INTL("编辑地形标签"),
  "parent"      => :editors_menu,
  "description" => _INTL("编辑地图集中地图块的地形标签，需要标 签 8 或以上。"),
  "effect"      => proc {
    pbFadeOutIn { pbTilesetScreen }
  }
})

MenuHandlers.add(:debug_menu, :fix_invalid_tiles, {
  "name"        => _INTL("修复无效地图块"),
  "parent"      => :editors_menu,
  "description" => _INTL("扫描所有地图，清除不存在的地图块。"),
  "effect"      => proc {
    pbDebugFixInvalidTiles
  }
})

#===============================================================================
# Other options
#===============================================================================
MenuHandlers.add(:debug_menu, :files_menu, {
  "name"        => _INTL("文件设置……"),
  "parent"      => :main,
  "description" => _INTL("编译、生成PBS文件、翻译、神秘礼物等。")
})

MenuHandlers.add(:debug_menu, :compile_data, {
  "name"        => _INTL("编译数据"),
  "parent"      => :files_menu,
  "description" => _INTL("编译所有数据。"),
  "effect"      => proc {
    msgwindow = pbCreateMessageWindow
    Compiler.compile_all(true)
    pbMessageDisplay(msgwindow, _INTL("所有游戏数据均已编译。"))
    pbDisposeMessageWindow(msgwindow)
  }
})

MenuHandlers.add(:debug_menu, :create_pbs_files, {
  "name"        => _INTL("生成PBS文件"),
  "parent"      => :files_menu,
  "description" => _INTL("选择生成一个或全部PBS文件。"),
  "effect"      => proc {
    cmd = 0
    cmds = [
      _INTL("[生成全部]"),
      "abilities.txt",
      "battle_facility_lists.txt",
      "berry_plants.txt",
      "dungeon_parameters.txt",
      "dungeon_tilesets.txt",
      "encounters.txt",
      "items.txt",
      "map_connections.txt",
      "map_metadata.txt",
      "metadata.txt",
      "moves.txt",
      "phone.txt",
      "pokemon.txt",
      "pokemon_forms.txt",
      "pokemon_metrics.txt",
      "regional_dexes.txt",
      "ribbons.txt",
      "shadow_pokemon.txt",
      "town_map.txt",
      "trainer_types.txt",
      "trainers.txt",
      "types.txt"
    ]
    loop do
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      case cmd
      when 0  then Compiler.write_all
      when 1  then Compiler.write_abilities
      when 2  then Compiler.write_trainer_lists
      when 3  then Compiler.write_berry_plants
      when 4  then Compiler.write_dungeon_parameters
      when 5  then Compiler.write_dungeon_tilesets
      when 6  then Compiler.write_encounters
      when 7  then Compiler.write_items
      when 8  then Compiler.write_connections
      when 9  then Compiler.write_map_metadata
      when 10 then Compiler.write_metadata
      when 11 then Compiler.write_moves
      when 12 then Compiler.write_phone
      when 13 then Compiler.write_pokemon
      when 14 then Compiler.write_pokemon_forms
      when 15 then Compiler.write_pokemon_metrics
      when 16 then Compiler.write_regional_dexes
      when 17 then Compiler.write_ribbons
      when 18 then Compiler.write_shadow_pokemon
      when 19 then Compiler.write_town_map
      when 20 then Compiler.write_trainer_types
      when 21 then Compiler.write_trainers
      when 22 then Compiler.write_types
      else break
      end
      pbMessage(_INTL("文件已生成。"))
    end
  }
})

MenuHandlers.add(:debug_menu, :rename_files, {
  "name"        => _INTL("重命名过时文件"),
  "parent"      => :files_menu,
  "description" => _INTL("检查名称过时的文件并 重命名/移动，可更改地图数据。"),
  "effect"      => proc {
    if pbConfirmMessage(_INTL("确定要自动重命名过期文件吗？"))
      FilenameUpdater.rename_files
      pbMessage(_INTL("已完成。"))
    end
  }
})

MenuHandlers.add(:debug_menu, :extract_text, {
  "name"        => _INTL("提取文本进行翻译"),
  "parent"      => :files_menu,
  "description" => _INTL("将游戏中的文本提取为文本文件来进行翻 译。"),
  "effect"      => proc {
    if Settings::LANGUAGES.length == 0
      pbMessage(_INTL("Settings中的LANGUAGES数组未定义任何语言。"))
      pbMessage(_INTL("为了能选择提取哪种语言的文本，需要在LANGUAGES中至少定义一种语言。"))
      next
    end
    # Choose a language from Settings to name the extraction folder after
    cmds = []
    Settings::LANGUAGES.each { |val| cmds.push(val[0]) }
    cmds.push(_INTL("取消"))
    language_index = pbMessage(_INTL("选择要提取文本的语言。"), cmds, cmds.length)
    next if language_index == cmds.length - 1
    language_name = Settings::LANGUAGES[language_index][1]
    # Choose whether to extract core text or game text
    text_type = pbMessage(_INTL("选择要提取文本的语言。"),
                          [_INTL("Game-specific文本"), _INTL("Core文本"), _INTL("取消")], 3)
    next if text_type == 2
    # If game text, choose whether to extract map texts to map-specific files or
    # to one big file
    map_files = 0
    if text_type == 0
      map_files = pbMessage(_INTL("怎么提取地图的文本到文件中？"),
                            [_INTL("全部地图放入一个文件"), _INTL("一个地图一个文件"), _INTL("取消")], 3)
      next if map_files == 2
    end
    # Extract the chosen set of text for the chosen language
    Translator.extract_text(language_name, text_type == 1, map_files == 1)
  }
})

MenuHandlers.add(:debug_menu, :compile_text, {
  "name"        => _INTL("编译翻译文本"),
  "parent"      => :files_menu,
  "description" => _INTL("导入文本文件并将其转换为语言文件。"),
  "effect"      => proc {
    # Find all folders with a particular naming convention
    cmds = Dir.glob("Text_*_*")
    if cmds.length == 0
      pbMessage(_INTL("未找到可编译的语言文件夹。"))
      pbMessage(_INTL("语言文件夹必须命名为“Text_此处随意_core”或“Text_此处随意_game”且位于游戏根目录。"))
      next
    end
    cmds.push(_INTL("取消"))
    # Ask which folder to compile into a .dat file
    folder_index = pbMessage(_INTL("选择要编译的语言文件夹。"), cmds, cmds.length)
    next if folder_index == cmds.length - 1
    # Compile the text files in the chosen folder
    dat_filename = cmds[folder_index].gsub!(/^Text_/, "")
    Translator.compile_text(cmds[folder_index], dat_filename)
  }
})

MenuHandlers.add(:debug_menu, :mystery_gift, {
  "name"        => _INTL("管理神秘礼物"),
  "parent"      => :files_menu,
  "description" => _INTL("编辑，启用/禁用神秘礼物。"),
  "effect"      => proc {
    pbManageMysteryGifts
  }
})

MenuHandlers.add(:debug_menu, :reload_system_cache, {
  "name"        => _INTL("重新加载系统缓存"),
  "parent"      => :files_menu,
  "description" => _INTL("刷新系统文件缓存，在游戏过程中更改 文件时使用。"),
  "effect"      => proc {
    System.reload_cache
    pbMessage(_INTL("已完成。"))
  }
})
