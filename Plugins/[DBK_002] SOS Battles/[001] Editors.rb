#===============================================================================
# Used for editing conditional SOS encounters in pokemon.txt and pokemon_forms.txt.
#===============================================================================
class SOSEncounterProperty
  def initialize
    @methods = ["Any"]
    @type_ids = [nil]
    GameData::EncounterType.each_alphabetically do |e|
      @methods.push(e.real_name)
      @type_ids.push(e.id)
    end
  end

  def edit_parameter(value = nil)
    params = ChooseNumberParams.new
    params.setRange(0, 65_535)
    params.setDefaultValue(value.to_i) if value
    params.setCancelValue(-1)
    ret = pbMessageChooseNumber(_INTL("选择地图编号"), params)
    ret = nil if ret < 0
    return (ret) ? ret.to_s : nil
  end

  def set(_settingname, oldsetting)
    ret = oldsetting
    cmdwin = pbListWindow([])
    commands = []
    realcmds = []
    realcmds.push([-1, 0, 0, -1])
    oldsetting.length.times do |i|
      realcmds.push([oldsetting[i][0], oldsetting[i][1], oldsetting[i][2], i])
    end
    refreshlist = true
    oldsel = -1
    cmd = [0, 0]
    loop do
      if refreshlist
        realcmds.sort! { |a, b| a[3] <=> b[3] }
        commands = []
        realcmds.length.times do |i|
          if realcmds[i][3] < 0
            commands.push(_INTL("[ADD ENCOUNTER]"))
          else
            mapid = realcmds[i][2]
            mapid = "Any map" if !mapid || (mapid.is_a?(String) && mapid.empty?)
            species_name = GameData::Species.get(realcmds[i][0]).name
            encounter_data = GameData::EncounterType.try_get(realcmds[i][1])
            enc_name = (encounter_data) ? encounter_data.real_name : @methods[0]
            commands.push(_INTL("{1}: {2}, {3}", species_name, enc_name, mapid.to_s))
          end
          cmd[1] = i if oldsel >= 0 && realcmds[i][3] == oldsel
        end
      end
      refreshlist = false
      oldsel = -1
      cmd = pbCommands3(cmdwin, commands, -1, cmd[1], true)
      case cmd[0]
      when 1
        if cmd[1] > 0 && cmd[1] < realcmds.length - 1
          realcmds[cmd[1] + 1][3], realcmds[cmd[1]][3] = realcmds[cmd[1]][3], realcmds[cmd[1] + 1][3]
          refreshlist = true
        end
      when 2
        if cmd[1] > 1
          realcmds[cmd[1] - 1][3], realcmds[cmd[1]][3] = realcmds[cmd[1]][3], realcmds[cmd[1] - 1][3]
          refreshlist = true
        end
      when 0
        if cmd[1] >= 0
          entry = realcmds[cmd[1]]
          if entry[3] == -1
            pbMessage(_INTL("选择一个物种、遭遇类型和地图 ID。"))
            newspecies = pbChooseSpeciesList
            if newspecies
              newtypeindex = pbMessage(_INTL("选择一个遭遇类型。"), @methods, -1)
              if newtypeindex >= 0
                newtype = @type_ids[newtypeindex]
                newmap = edit_parameter
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][3] if realcmds[i][0] == newspecies &&
                                                   realcmds[i][1] == newtype &&
                                                   realcmds[i][2] == newmap
                end
                if existing_sos >= 0
                  oldsel = existing_sos
                else
                  maxid = -1
                  realcmds.each { |i| maxid = [maxid, i[3]].max }
                  realcmds.push([newspecies, newtype, newmap, maxid + 1])
                  oldsel = maxid + 1
                end
                refreshlist = true
              end
            end
          else
            case pbMessage("\\ts[]" + _INTL("对这个遭遇做什么?"),
                           [_INTL("更改物种"), _INTL("更改遭遇类型"),
                            _INTL("更改地图编号"), _INTL("删除"), _INTL("取消")], 5)
            when 0   # Change species
              newspecies = pbChooseSpeciesList(entry[0])
              if newspecies
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][3] if realcmds[i][0] == newspecies &&
                                                   realcmds[i][1] == entry[1] &&
                                                   realcmds[i][2] == entry[2]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                else
                  entry[0] = newspecies
                  oldsel = entry[3]
                end
                refreshlist = true
              end
            when 1   # Change encounter type
              default_index = 0
              @type_ids.each_with_index { |type, i| default_index = i if type == entry[1] }
              newtypeindex = pbMessage(_INTL("选择一个遭遇属性"), @methods, -1, nil, default_index)
              if newtypeindex >= 0
                newtype = @type_ids[newtypeindex]
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][3] if realcmds[i][0] == entry[0] &&
                                                   realcmds[i][1] == newtype &&
                                                   realcmds[i][2] == entry[2]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                elsif newtype != entry[1]
                  entry[1] = newtype
                  entry[2] = 0
                  oldsel = entry[3]
                end
                refreshlist = true
              end
            when 2   # Change map number
              newmap = edit_parameter(entry[2])
              existing_sos = -1
              realcmds.length.times do |i|
                existing_sos = realcmds[i][3] if realcmds[i][0] == entry[0] &&
                                                 realcmds[i][1] == entry[1] &&
                                                 realcmds[i][2] == newmap
              end
              if existing_sos >= 0
                realcmds.delete_at(cmd[1])
                oldsel = existing_sos
              else
                entry[2] = newmap
                oldsel = entry[3]
              end
              refreshlist = true
            when 3   # Delete
              realcmds.delete_at(cmd[1])
              cmd[1] = [cmd[1], realcmds.length - 1].min
              refreshlist = true
            end
          end
        else
          cmd2 = pbMessage(_INTL("保存更改?"),
                           [_INTL("是"), _INTL("否"), _INTL("取消")], 3)
          if [0, 1].include?(cmd2)
            if cmd2 == 0
              realcmds.length.times do |i|
                realcmds[i].pop
                realcmds[i] = nil if realcmds[i][0] == -1
              end
              realcmds.compact!
              ret = realcmds
            end
            break
          end
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def defaultValue
    return []
  end

  def format(value)
    return "" if !value
    ret = ""
    value.length.times do |i|
      ret << "," if i > 0
      ret << (value[i][0].to_s + ",")
      ret << (value[i][1].to_s + ",")
      ret << value[i][2].to_s if value[i][2]
    end
    return ret
  end
end


#===============================================================================
# Used for editing special SOS encounters in map_metadata.txt.
#===============================================================================
class SOSMapEncounterProperty
  def initialize
    @time_methods = GameData::MapMetadata::SOS_TIME_OF_DAY.clone
    @cond_methods = GameData::MapMetadata::SOS_CONDITIONS.clone
  end

  def get_gamedata(index)
    case index
    when 1 then return GameData::BattleWeather
    when 2 then return GameData::BattleTerrain
    when 3 then return GameData::Environment
    end
    return nil
  end
  
  def edit_parameter(index)
    ret = get_gamedata(index)
    if ret
      methods = []
      type_ids = []
      ret.each_alphabetically do |e|
        methods.push(e.real_name)
        type_ids.push(e.id)
      end
      newindex = pbMessage(_INTL("选择{1}的属性。", @cond_methods[index].downcase), methods, -1)
      ret = type_ids[newindex]
    end
    return ret
  end
  
  def edit_encounter_chance(value = nil)
    params = ChooseNumberParams.new
    params.setRange(1, 100)
    params.setDefaultValue(value.to_i) if value
    params.setCancelValue(0)
    ret = pbMessageChooseNumber(_INTL("设置遭遇几率。"), params)
    ret = nil if ret < 1
    return ret
  end

  def set(_settingname, oldsetting)
    ret = oldsetting
    cmdwin = pbListWindow([])
    commands = []
    realcmds = []
    realcmds.push([-1, 0, 0, 0, 0, -1])
    oldsetting.length.times do |i|
      realcmds.push([oldsetting[i][0], oldsetting[i][1], # Species, encounter chance
                     oldsetting[i][2], oldsetting[i][3], # Time of day, condition
                     oldsetting[i][4], i])               # Type of condition
    end
    refreshlist = true
    oldsel = -1
    cmd = [0, 0]
    loop do
      if refreshlist
        realcmds.sort! { |a, b| a[5] <=> b[5] }
        commands = []
        realcmds.length.times do |i|
          if realcmds[i][5] < 0
            commands.push(_INTL("[ADD ENCOUNTER]"))
          else
            species_name = GameData::Species.get(realcmds[i][0]).name
            chance = realcmds[i][1]
            time_name = (realcmds[i][2]) ? @time_methods[realcmds[i][2]] : @time_methods[0]
            cond_name = (realcmds[i][3]) ? @cond_methods[realcmds[i][3]] : @cond_methods[0]
            game_data = get_gamedata(realcmds[i][3])
            type = (game_data) ? game_data.try_get(realcmds[i][4]) : nil
            type_name = (type) ? type.real_name : ""
            commands.push(_INTL("{1}: {2}, {3}, {4}, {5}", 
              species_name, chance.to_s, time_name, cond_name, type_name))
          end
          cmd[1] = i if oldsel >= 0 && realcmds[i][5] == oldsel
        end
      end
      refreshlist = false
      oldsel = -1
      cmd = pbCommands3(cmdwin, commands, -1, cmd[1], true)
      case cmd[0]
      when 1   # Swap encounter up
        if cmd[1] > 0 && cmd[1] < realcmds.length - 1
          realcmds[cmd[1] + 1][5], realcmds[cmd[1]][5] = realcmds[cmd[1]][5], realcmds[cmd[1] + 1][5]
          refreshlist = true
        end
      when 2   # Swap encounter down
        if cmd[1] > 1
          realcmds[cmd[1] - 1][5], realcmds[cmd[1]][5] = realcmds[cmd[1]][5], realcmds[cmd[1] - 1][5]
          refreshlist = true
        end
      when 0
        if cmd[1] >= 0
          entry = realcmds[cmd[1]]
          if entry[5] == -1   # Add new sos encounter
            pbMessage(_INTL("选择一个物种、遭遇几率、\n时间段、战斗条件以及条件类型。"))
            newspecies = pbChooseSpeciesList
            if newspecies
              newchance = edit_encounter_chance
              if newchance
                newtimeindex = pbMessage(_INTL("选择时间"), @time_methods, -1)
                if newtimeindex >= 0
                  newcondindex = pbMessage(_INTL("选择一个战斗条件"), @cond_methods, -1)
                  if newcondindex >= 0
                    newtype = edit_parameter(newcondindex)
                    existing_sos = -1
                    realcmds.length.times do |i|
                      existing_sos = realcmds[i][5] if realcmds[i][0] == newspecies &&
                                                       realcmds[i][1] == newchance &&
                                                       realcmds[i][2] == newtimeindex &&
                                                       realcmds[i][3] == newcondindex &&
                                                       realcmds[i][4] == newtype
                    end
                    if existing_sos >= 0
                      oldsel = existing_sos
                    else
                      maxid = -1
                      realcmds.each { |i| maxid = [maxid, i[5]].max }
                      realcmds.push([newspecies, newchance, newtimeindex, newcondindex, newtype, maxid + 1])
                      oldsel = maxid + 1
                    end
                    refreshlist = true
                  end
                end
              end
            end
          else   # Edit encounter
            case pbMessage("\\ts[]" + _INTL("对这个进化做什么?"),
                           [_INTL("更改物种"), 
                            _INTL("更改遭遇几率"),
                            _INTL("更改时间段"), 
                            _INTL("更改战斗条件"), 
                            _INTL("更改条件类型"), 
                            _INTL("删除"), _INTL("取消")], 7)
            when 0   # Change species
              newspecies = pbChooseSpeciesList(entry[0])
              if newspecies
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][5] if realcmds[i][0] == newspecies &&
                                                   realcmds[i][1] == entry[1] &&
                                                   realcmds[i][2] == entry[2] &&
                                                   realcmds[i][3] == entry[3] &&
                                                   realcmds[i][4] == entry[4]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                else
                  entry[0] = newspecies
                  oldsel = entry[5]
                end
                refreshlist = true
              end
            when 1   # Change chance
              newchance = edit_encounter_chance(entry[1])
              if newchance
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][5] if realcmds[i][0] == entry[0] &&
                                                   realcmds[i][1] == newchance &&
                                                   realcmds[i][2] == entry[2] &&
                                                   realcmds[i][3] == entry[3] &&
                                                   realcmds[i][4] == entry[4]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                else
                  entry[1] = newchance
                  oldsel = entry[5]
                end
                refreshlist = true
              end
            when 2   # Change time
              default_index = 0
              @time_methods.each_with_index { |time, i| default_index = i if time == entry[2] }
              newtimeindex = pbMessage(_INTL("选择时间"), @time_methods, -1, nil, default_index)
              if newtimeindex >= 0
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][5] if realcmds[i][0] == entry[0] &&
                                                   realcmds[i][1] == entry[1] &&
                                                   realcmds[i][2] == newtimeindex &&
                                                   realcmds[i][3] == entry[3] &&
                                                   realcmds[i][4] == entry[4]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                else
                  entry[2] = newtimeindex
                  oldsel = entry[5]
                end
                refreshlist = true
              end
            when 3   # Change condition
              default_index = 0
              @cond_methods.each_with_index { |cond, i| default_index = i if cond == entry[3] }
              newcondindex = pbMessage(_INTL("选择一个战斗条件"), @cond_methods, -1, nil, default_index)
              if newcondindex >= 0
                existing_sos = -1
                realcmds.length.times do |i|
                  existing_sos = realcmds[i][5] if realcmds[i][0] == entry[0] &&
                                                   realcmds[i][1] == entry[1] &&
                                                   realcmds[i][2] == entry[2] &&
                                                   realcmds[i][3] == newcondindex &&
                                                   realcmds[i][4] == entry[4]
                end
                if existing_sos >= 0
                  realcmds.delete_at(cmd[1])
                  oldsel = existing_sos
                elsif newcondindex != entry[3]
                  entry[3] = newcondindex
                  entry[4] = edit_parameter(newcondindex)
                  oldsel = entry[5]
                end
                refreshlist = true
              end
            when 4   # Change condition type
              if entry[3] == 0
                pbMessage(_INTL("未设置特定的战斗条件。"))
              else
                newtype = edit_parameter(entry[3])
                if newtype != entry[4]
                  existing_sos = -1
                  realcmds.length.times do |i|
                    existing_sos = realcmds[i][5] if realcmds[i][0] == entry[0] &&
                                                     realcmds[i][1] == entry[1] &&
                                                     realcmds[i][2] == entry[2] &&
                                                     realcmds[i][3] == entry[3] &&
                                                     realcmds[i][4] == newtype
                  end
                  if existing_sos >= 0
                    realcmds.delete_at(cmd[1])
                    oldsel = existing_sos
                  else
                    entry[4] = newtype
                    oldsel = entry[5]
                  end
                  refreshlist = true
                end
              end
            when 5   # Delete
              realcmds.delete_at(cmd[1])
              cmd[1] = [cmd[1], realcmds.length - 1].min
              refreshlist = true
            end
          end
        else
          cmd2 = pbMessage(_INTL("保存更改?"),
                           [_INTL("是"), _INTL("否"), _INTL("取消")], 3)
          if [0, 1].include?(cmd2)
            if cmd2 == 0
              realcmds.length.times do |i|
                realcmds[i].pop
                realcmds[i] = nil if realcmds[i][0] == -1
              end
              realcmds.compact!
              ret = realcmds
            end
            break
          end
        end
      end
    end
    cmdwin.dispose
    return ret
  end

  def defaultValue
    return []
  end

  def format(value)
    return "" if !value
    ret = ""
    value.length.times do |i|
      ret << "," if i > 0
      ret << (value[i][0].to_s + ",")
      ret << (value[i][1].to_s + ",")
      ret << value[i][2].to_s if value[i][2]
    end
    return ret
  end
end


#===============================================================================
# Adds plugin utilities to debug menus.
#===============================================================================

#-------------------------------------------------------------------------------
# General Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:debug_menu, :deluxe_mode_toggles, {
  "name"        => _INTL("切换插件战斗模式..."),
  "parent"      => :deluxe_plugins_menu,
  "description" => _INTL("切换由插件实现的\n各种战斗模式。")
})

MenuHandlers.add(:debug_menu, :deluxe_sos, {
  "name"        => _INTL("切换SOS战斗"),
  "parent"      => :deluxe_mode_toggles,
  "description" => _INTL("切换野生宝可梦呼叫\n援助（SOS）功能。"),
  "effect"      => proc {
    $game_switches[Settings::SOS_CALL_SWITCH] = !$game_switches[Settings::SOS_CALL_SWITCH]
    toggle = ($game_switches[Settings::SOS_CALL_SWITCH]) ? "enabled" : "disabled"
    pbMessage(_INTL("SOS calls {1}.", toggle))
  }
})

MenuHandlers.add(:battle_rules_menu, :SOSBattle, {
  "name"        => "SOS战斗：[ {1} ]",
  "rule"        => "SOSBattle",
  "order"       => 316,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定是否允许野生宝可梦呼叫援助（SOS）。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("SOSBattle", :Boolean, nil, 
      _INTL("设定是否允许野生宝可梦呼叫援助（SOS）。"))
  }
})

MenuHandlers.add(:battle_rules_menu, :totemBattle, {
  "name"        => "霸主战斗：[ {1} ]",
  "rule"        => "totemBattle",
  "order"       => 317,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定SOS呼叫出现的宝可梦种类。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("totemBattle", :Toggle, true)
  }
})

MenuHandlers.add(:battle_rules_menu, :setSOSPokemon, {
  "name"        => "强制SOS呼叫：[ {1} ]",
  "rule"        => "setSOSPokemon",
  "order"       => 318,
  "parent"      => :set_battle_rules,
  "description" => _INTL("设定SOS呼叫出现的宝可梦种类。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("setSOSPokemon", :Data, :Species,
      _INTL("请选择SOS呼叫时出现的\n宝可梦种类。"))
  }
})

MenuHandlers.add(:battle_rules_menu, :addSOSPokemon, {
  "name"        => "附加SOS种类：[ {1} ]",
  "rule"        => "addSOSPokemon",
  "order"       => 319,
  "parent"      => :set_battle_rules,
  "description" => _INTL("添加可能通过SOS呼叫出现的额外宝可梦种类。"),
  "effect"      => proc { |menu|
    next pbApplyBattleRule("addSOSPokemon", :Data, :Species,
      _INTL("选择要加入SOS呼叫可能出现种类的宝可梦。"))
  }
})


#-------------------------------------------------------------------------------
# Battle Debug options
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_debug_menu, :add_new_foe, {
  "name"        => _INTL("添加新的对手"),
  "parent"      => :battlers,
  "description" => _INTL("添加或替换对手方的一只宝可梦。"),
  "effect"      => proc { |battle|
    cmd = 0
    cmds = []
    indecies = [1, 3, 5]
    size = battle.pbSideSize(1)
    3.times do |i|
      next if i > size
      idx = indecies[i]
      b = battle.battlers[idx]
      name = (b) ? b.name : "---"
      owner = (!b) ? "" : (b.wild?) ? "(Wild)" :  "(#{battle.pbGetOwnerName(b.index)})"
      cmds.push(_INTL("[{1}] {2} {3}", idx, name, owner))
    end
    loop do
      cmd = pbMessage("\\ts[]" + _INTL("在对方一方添加或替换一个对手。"), cmds, -1, nil, cmd)
      break if cmd < 0
      if battle.trainerBattle?
        trainerdata = pbListScreen(_INTL("选择训练师"), TrainerBattleLister.new(0, false))
        break if !trainerdata
        slot = cmd + 1
        if size < 3 && slot > size 
          battle.sideSizes[1] = slot
        end
        trainer = pbLoadTrainer(trainerdata[0], trainerdata[1], trainerdata[2])
        EventHandlers.trigger(:on_trainer_load, trainer)
        idxTrainer = cmd
        idxTrainer = cmd - 1 if !battle.opponent[cmd - 1]
        battle.opponent[idxTrainer] = trainer
        battle.items[idxTrainer] = trainer.items
        pokemon = trainer.party.first
        idxBattler = indecies[cmd]
        fullUpdate = battle.battlers[idxBattler].nil?
        battle.pbInitializeNewBattler([idxBattler, pokemon], [idxTrainer, trainer], fullUpdate)
        battle.scene.pbQuickJoin(idxBattler, idxTrainer)
        owner = "(#{trainer.full_name})"
      else
        species = pbChooseSpeciesList
        break if !species
        speciesName = GameData::Species.get(species).name
        params = ChooseNumberParams.new
        params.setRange(1, GameData::GrowthRate.max_level)
        params.setDefaultValue(5)
        level = pbMessageChooseNumber(
          "\\ts[]" + _INTL("设置{1}的等级(最高{2}).", speciesName, params.maxNumber), params
        )
        break if !level
        slot = cmd + 1
        size = battle.pbSideSize(1)
        if size < 3 && slot > size 
          battle.sideSizes[1] = slot
        end
        pokemon = pbGenerateWildPokemon(species, level)
        idxBattler = indecies[cmd]
        fullUpdate = battle.battlers[idxBattler].nil?
        battle.pbInitializeNewBattler([idxBattler, pokemon], [], fullUpdate)
        battle.scene.pbQuickJoin(idxBattler)
        owner = "(Wild)"
      end
      cmds.push(_INTL("[{1}] ---", indecies.last)) if slot == 2 && cmds.length < 3
      cmds[cmd] = _INTL("[{1}] {2} {3}", idxBattler, pokemon.name, owner)
    end
  }
})