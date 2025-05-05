################################################################################
# 
# Pokemon debug command edits.
# 
################################################################################


#-------------------------------------------------------------------------------
# Allows you to set the status count for a Pokemon's Drowsy status in the party.
#-------------------------------------------------------------------------------
MenuHandlers.add(:pokemon_debug_menu, :set_status, {
  "name"   => _INTL("设置异常状态"),
  "parent" => :hp_status_menu,
  "effect" => proc { |pkmn, pkmnid, heldpoke, settingUpBattle, screen|
    if pkmn.egg?
      screen.pbDisplay(_INTL("{1}是蛋。", pkmn.name))
    elsif pkmn.hp <= 0
      screen.pbDisplay(_INTL("{1}已经倒下，无法更改异常状态。", pkmn.name))
    else
      cmd = 0
      commands = [_INTL("[治愈]")]
      ids = [:NONE]
      GameData::Status.each do |s|
        next if s.id == :NONE
        commands.push(_INTL("设为{1}", s.name))
        ids.push(s.id)
      end
      loop do
        msg = _INTL("目前异常状态：{1}", GameData::Status.get(pkmn.status).name)
        if pkmn.status == :SLEEP
          msg = _INTL("目前异常状态：{1}（回合：{2}）",
                      GameData::Status.get(pkmn.status).name, pkmn.statusCount)
        end
        cmd = screen.pbShowCommands(msg, commands, cmd)
        break if cmd < 0
        case cmd
        when 0
          pkmn.heal_status
          screen.pbRefreshSingle(pkmnid)
        else
          count = 0
          cancel = false
          if [:SLEEP, :DROWSY].include?(ids[cmd]) 
            params = ChooseNumberParams.new
            params.setRange(0, 9)
            params.setDefaultValue(3)
			      status = (ids[cmd] == :SLEEP) ? "睡眠" : "瞌睡"
            count = pbMessageChooseNumber(
              _INTL("设置宝可梦#{status}的回合数。"), params
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

#-------------------------------------------------------------------------------
# Allows you to set the status count for a Pokemon's Drowsy status in battle.
#-------------------------------------------------------------------------------
MenuHandlers.add(:battle_pokemon_debug_menu, :set_status, {
  "name"   => _INTL("设置异常状态"),
  "parent" => :hp_status_menu,
  "usage"  => :both,
  "effect" => proc { |pkmn, battler, battle|
    if pkmn.egg?
      pbMessage("\\ts[]" + _INTL("{1}是蛋。", pkmn.name))
      next
    elsif pkmn.hp <= 0
      pbMessage("\\ts[]" + _INTL("{1}已经倒下，无法更改异常状态。", pkmn.name))
      next
    end
    cmd = 0
    commands = [_INTL("[治愈]")]
    ids = [:NONE]
    GameData::Status.each do |s|
      next if s.id == :NONE
      commands.push(_INTL("设为{1}", s.name))
      ids.push(s.id)
    end
    loop do
      msg = _INTL("目前异常状态：{1}", GameData::Status.get(pkmn.status).name)
      if pkmn.status == :SLEEP
        msg += " " + _INTL("（回合：{1}）", pkmn.statusCount)
      elsif pkmn.status == :POISON && pkmn.statusCount > 0
        if battler
          msg += " " + _INTL("剧毒，回合：{1}）", battler.effects[PBEffects::Toxic])
        else
          msg += " " + _INTL("剧毒")
        end
      end
      cmd = pbMessage("\\ts[]" + msg, commands, -1, nil, cmd)
      break if cmd < 0
      case cmd
      when 0
        if battler
          battler.status = :NONE
        else
          pkmn.heal_status
        end
      else
        pkmn_name = (battler) ? battler.pbThis(true) : pkmn.name
        case ids[cmd]
        when :SLEEP, :DROWSY
          params = ChooseNumberParams.new
          params.setRange(0, 99)
          params.setDefaultValue((pkmn.status == :SLEEP) ? pkmn.statusCount : 3)
          params.setCancelValue(-1)
		      status = (ids[cmd] == :SLEEP) ? "睡眠" : "瞌睡"
          count = pbMessageChooseNumber("\\ts[]" + _INTL("设置宝可梦#{status}的回合数（0-99）。", pkmn_name), params)
          next if count < 0
          (battler || pkmn).statusCount = count
        when :POISON
          if pbConfirmMessage("\\ts[]" + _INTL("要使{1}中剧毒吗？", pkmn_name))
            if battler
              params = ChooseNumberParams.new
              params.setRange(0, 16)
              params.setDefaultValue(battler.effects[PBEffects::Toxic])
              params.setCancelValue(-1)
              count = pbMessageChooseNumber(
                "\\ts[]" + _INTL("设置{1}剧毒的回合数。", pkmn_name), params
              )
              next if count < 0
              battler.statusCount = 1
              battler.effects[PBEffects::Toxic] = count
            else
              pkmn.statusCount = 1
            end
          else
            (battler || pkmn).statusCount = 0
          end
        end
        (battler || pkmn).status = ids[cmd]
      end
    end
  }
})


################################################################################
# 
# Used to add new eligible PBEffects to the battle debug menu.
# 
################################################################################


#-------------------------------------------------------------------------------
# Utility for choosing a stat from a list.
#-------------------------------------------------------------------------------
def pbChooseStatList(mode = nil, default = nil)
  commands = []
  GameData::Stat.each do |data|
    case mode
    when :main        then next if ![:main, :main_battle].include?(data.type)
    when :main_battle then next if ![:main_battle].include?(data.type)
    when :battle      then next if ![:main_battle, :battle].include?(data.type)
    end
    name = data.real_name
    next if !name
    commands.push([commands.length + 1, name, data.id])
  end
  return pbChooseList(commands, default, nil, -1)
end

#-------------------------------------------------------------------------------
# Edited to allow for unique inputs for the following effects:
#  -PBEffects::ParadoxStat   : Allows for setting this effect to a Stat ID.
#  -PBEffects::SplintersType : Allows for setting this effect to a Type ID.
#-------------------------------------------------------------------------------
class Battle::DebugSetEffects
  def update_input_for_stat(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseStatList(:main_battle, @variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end
  
  def update_input_for_type(effect, variable_data)
    if Input.trigger?(Input::USE)
      pbPlayDecisionSE
      new_value = pbChooseTypeList(@variables[effect])
      if new_value && new_value != @variables[effect]
        @variables[effect] = new_value
        return true
      end
    elsif Input.trigger?(Input::ACTION) && @variables[effect]
      pbPlayDecisionSE
      @variables[effect] = nil
      return true
    end
    return false
  end

  def update
    loop do
      Graphics.update
      Input.update
      @window.update
      if Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
      index = @window.index
      effect = @variables_data.keys[index]
      variable_data = @variables_data[effect]
      if variable_data[:default] == false
        @window.refresh if update_input_for_boolean(effect, variable_data)
      elsif [0, 1, -2].include?(variable_data[:default])
        @window.refresh if update_input_for_integer(effect, variable_data[:default], variable_data)
      elsif variable_data[:default] == -1
        @window.refresh if update_input_for_battler_index(effect, variable_data)
      elsif variable_data[:default].nil?
        case variable_data[:type]
        when :move
          @window.refresh if update_input_for_move(effect, variable_data)
        when :item
          @window.refresh if update_input_for_item(effect, variable_data)
        when :stat
          @window.refresh if update_input_for_stat(effect, variable_data)
        when :type
          @window.refresh if update_input_for_type(effect, variable_data)
        else
          raise "未知种类的变量！"
        end
      else
        raise "未知种类的变量！"
      end
    end
  end
end