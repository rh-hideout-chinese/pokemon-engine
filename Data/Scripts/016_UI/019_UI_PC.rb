#===============================================================================
#
#===============================================================================
def pbPCItemStorage
  command = 0
  loop do
    command = pbShowCommandsWithHelp(nil,
                                     [_INTL("取出道具"),
                                      _INTL("存放道具"),
                                      _INTL("丢弃道具"),
                                      _INTL("退出")],
                                     [_INTL("从电脑中取出道具。"),
                                      _INTL("在电脑中存放道具。"),
                                      _INTL("扔掉储存在电脑里的道具。"),
                                      _INTL("返回上级菜单。")], -1, command)
    case command
    when 0   # Withdraw Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("没有道具。"))
      else
        pbFadeOutIn do
          scene = WithdrawItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbWithdrawItemScreen
        end
      end
    when 1   # Deposit Item
      pbFadeOutIn do
        scene = PokemonBag_Scene.new
        screen = PokemonBagScreen.new(scene, $bag)
        screen.pbDepositItemScreen
      end
    when 2   # Toss Item
      if !$PokemonGlobal.pcItemStorage
        $PokemonGlobal.pcItemStorage = PCItemStorage.new
      end
      if $PokemonGlobal.pcItemStorage.empty?
        pbMessage(_INTL("没有道具。"))
      else
        pbFadeOutIn do
          scene = TossItemScene.new
          screen = PokemonBagScreen.new(scene, $bag)
          screen.pbTossItemScreen
        end
      end
    else
      break
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbPCMailbox
  if !$PokemonGlobal.mailbox || $PokemonGlobal.mailbox.length == 0
    pbMessage(_INTL("没有邮件。"))
  else
    loop do
      command = 0
      commands = []
      $PokemonGlobal.mailbox.each do |mail|
        commands.push(mail.sender)
      end
      commands.push(_INTL("取消"))
      command = pbShowCommands(nil, commands, -1, command)
      if command >= 0 && command < $PokemonGlobal.mailbox.length
        mailIndex = command
        commandMail = pbMessage(
          _INTL("如何处理{1}的邮件？", $PokemonGlobal.mailbox[mailIndex].sender),
          [_INTL("阅读"),
           _INTL("放到背包"),
           _INTL("给予"),
           _INTL("取消")], -1
        )
        case commandMail
        when 0   # Read
          pbFadeOutIn do
            pbDisplayMail($PokemonGlobal.mailbox[mailIndex])
          end
        when 1   # Move to Bag
          if pbConfirmMessage(_INTL("邮件上的信息将会被抹去，确定吗？"))
            if $bag.add($PokemonGlobal.mailbox[mailIndex].item)
              pbMessage(_INTL("邮件放到背包里了，邮件上的信息被抹去了。"))
              $PokemonGlobal.mailbox.delete_at(mailIndex)
            else
              pbMessage(_INTL("背包已经满了。"))
            end
          end
        when 2   # Give
          pbFadeOutIn do
            sscene = PokemonParty_Scene.new
            sscreen = PokemonPartyScreen.new(sscene, $player.party)
            sscreen.pbPokemonGiveMailScreen(mailIndex)
          end
        end
      else
        break
      end
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbTrainerPC
  pbMessage("\\se[PC open]" + _INTL("{1}启动了电脑。", $player.name))
  pbTrainerPCMenu
  pbSEPlay("PC close")
end

def pbTrainerPCMenu
  command = 0
  loop do
    command = pbMessage(_INTL("想要做什么？"),
                        [_INTL("道具存储"),
                         _INTL("邮箱"),
                         _INTL("关闭")], -1, nil, command)
    case command
    when 0 then pbPCItemStorage
    when 1 then pbPCMailbox
    else        break
    end
  end
end

#===============================================================================
#
#===============================================================================
def pbPokeCenterPC
  pbMessage("\\se[PC open]" + _INTL("{1}启动了电脑。", $player.name))
  # Get all commands
  command_list = []
  commands = []
  MenuHandlers.each_available(:pc_menu) do |option, hash, name|
    command_list.push(name)
    commands.push(hash)
  end
  # Main loop
  command = 0
  loop do
    choice = pbMessage(_INTL("要访问哪个电脑？"), command_list, -1, nil, command)
    if choice < 0
      pbPlayCloseMenuSE
      break
    end
    break if commands[choice]["effect"].call
  end
  pbSEPlay("PC close")
end

def pbGetStorageCreator
  return GameData::Metadata.get.storage_creator
end

#===============================================================================
#
#===============================================================================
MenuHandlers.add(:pc_menu, :pokemon_storage, {
  "name"      => proc {
    next ($player.seen_storage_creator) ? _INTL("{1}的电脑", pbGetStorageCreator) : _INTL("某人的电脑")
  },
  "order"     => 10,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("开启了宝可梦存储系统。"))
    command = 0
    loop do
      command = pbShowCommandsWithHelp(nil,
                                       [_INTL("整理盒子"),
                                        _INTL("取出宝可梦"),
                                        _INTL("存放宝可梦"),
                                        _INTL("再见！")],
                                       [_INTL("整理盒子和队伍。"),
                                        _INTL("将电脑里的宝可梦取出。"),
                                        _INTL("将队伍里的宝可梦存放到电脑里。"),
                                        _INTL("返回上级菜单。")], -1, command)
      break if command < 0
      case command
      when 0   # Organize
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(0)
        end
      when 1   # Withdraw
        if $PokemonStorage.party_full?
          pbMessage(_INTL("队伍已经满了！"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(1)
        end
      when 2   # Deposit
        count = 0
        $PokemonStorage.party.each do |p|
          count += 1 if p && !p.egg? && p.hp > 0
        end
        if count <= 1
          pbMessage(_INTL("不能存放最后的宝可梦！"))
          next
        end
        pbFadeOutIn do
          scene = PokemonStorageScene.new
          screen = PokemonStorageScreen.new(scene, $PokemonStorage)
          screen.pbStartScreen(2)
        end
      else
        break
      end
    end
    next false
  }
})

MenuHandlers.add(:pc_menu, :player_pc, {
  "name"      => proc { next _INTL("{1}的电脑", $player.name) },
  "order"     => 20,
  "effect"    => proc { |menu|
    pbMessage("\\se[PC access]" + _INTL("已访问{1}的电脑。", $player.name))
    pbTrainerPCMenu
    next false
  }
})

MenuHandlers.add(:pc_menu, :close, {
  "name"      => _INTL("注销"),
  "order"     => 100,
  "effect"    => proc { |menu|
    next true
  }
})
