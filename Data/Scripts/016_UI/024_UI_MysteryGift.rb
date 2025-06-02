#===============================================================================
# Mystery Gift system
# By Maruno
#===============================================================================
# This url is the location of an example Mystery Gift file.
# You should change it to your file's url once you upload it.
#===============================================================================
module MysteryGift
  URL = "https://pastebin.com/raw/w6BqqUsm"
end

#===============================================================================
# Creating a new Mystery Gift for the Master file, and editing an existing one.
#===============================================================================
# type: 0=Pokémon; 1 or higher=item (is the item's quantity).
# item: The thing being turned into a Mystery Gift (Pokémon object or item ID).
def pbEditMysteryGift(type, item, id = 0, giftname = "")
  begin
    if type == 0   # Pokémon
      commands = [_INTL("神秘礼物"),
                  _INTL("遥远的地方")]
      commands.push(item.obtain_text) if item.obtain_text && !item.obtain_text.empty?
      commands.push(_INTL("[自定义]"))
      loop do
        command = pbMessage(
          _INTL("选择礼物宝可梦的短语。"),
          commands, -1
        )
        if command < 0
          return nil if pbConfirmMessage(_INTL("停止编辑这个礼物？"))
        elsif command < commands.length - 1
          item.obtain_text = commands[command]
          break
        elsif command == commands.length - 1
          obtainname = pbMessageFreeText(_INTL("输入短语。"), "", false, 30)
          if obtainname != ""
            item.obtain_text = obtainname
            break
          end
          return nil if pbConfirmMessage(_INTL("停止编辑这个礼物？"))
        end
      end
    elsif type > 0   # Item
      params = ChooseNumberParams.new
      params.setRange(1, 99_999)
      params.setDefaultValue(type)
      params.setCancelValue(0)
      loop do
        newtype = pbMessageChooseNumber(_INTL("选择{1}的数量。",
                                              GameData::Item.get(item).name), params)
        if newtype == 0
          return nil if pbConfirmMessage(_INTL("停止编辑这个礼物？"))
        else
          type = newtype
          break
        end
      end
    end
    if id == 0
      master = []
      idlist = []
      if FileTest.exist?("MysteryGiftMaster.txt")
        master = IO.read("MysteryGiftMaster.txt")
        master = pbMysteryGiftDecrypt(master)
      end
      master.each do |i|
        idlist.push(i[0])
      end
      params = ChooseNumberParams.new
      params.setRange(0, 99_999)
      params.setDefaultValue(id)
      params.setCancelValue(0)
      loop do
        newid = pbMessageChooseNumber(_INTL("请为此礼物选择唯一ID。"), params)
        if newid == 0
          return nil if pbConfirmMessage(_INTL("停止编辑这个礼物？"))
        elsif idlist.include?(newid)
          pbMessage(_INTL("ID已被一个神秘礼物使用了。"))
        else
          id = newid
          break
        end
      end
    end
    loop do
      newgiftname = pbMessageFreeText(_INTL("输入礼物的名称。"), giftname, false, 250)
      if newgiftname != ""
        giftname = newgiftname
        break
      end
      return nil if pbConfirmMessage(_INTL("停止编辑这个礼物？"))
    end
    return [id, type, item, giftname]
  rescue
    pbMessage(_INTL("无法编辑礼物。"))
    return nil
  end
end

def pbCreateMysteryGift(type, item)
  gift = pbEditMysteryGift(type, item)
  if gift
    begin
      if FileTest.exist?("MysteryGiftMaster.txt")
        master = IO.read("MysteryGiftMaster.txt")
        master = pbMysteryGiftDecrypt(master)
        master.push(gift)
      else
        master = [gift]
      end
      string = pbMysteryGiftEncrypt(master)
      File.open("MysteryGiftMaster.txt", "wb") { |f| f.write(string) }
      pbMessage(_INTL("礼物保存到MysteryGiftMaster.txt了。"))
    rescue
      pbMessage(_INTL("没有把礼物保存到MysteryGiftMaster.txt了。"))
    end
  else
    pbMessage(_INTL("没有创建礼物。"))
  end
end

#===============================================================================
# Debug option for managing gifts in the Master file and exporting them to a
# file to be uploaded.
#===============================================================================
def pbManageMysteryGifts
  if !FileTest.exist?("MysteryGiftMaster.txt")
    pbMessage(_INTL("没有定义神秘礼物。"))
    return
  end
  # Load all gifts from the Master file.
  master = IO.read("MysteryGiftMaster.txt")
  master = pbMysteryGiftDecrypt(master)
  if !master || !master.is_a?(Array) || master.length == 0
    pbMessage(_INTL("没有定义神秘礼物。"))
    return
  end
  # Download all gifts from online
  msgwindow = pbCreateMessageWindow
  pbMessageDisplay(msgwindow, _INTL("搜索礼物中……\\wtnp[0]"))
  online = pbDownloadToString(MysteryGift::URL)
  pbDisposeMessageWindow(msgwindow)
  if nil_or_empty?(online)
    pbMessage(_INTL("没有发现神秘礼物。\\wtnp[20]"))
    online = []
  else
    pbMessage(_INTL("发现神秘礼物。\\wtnp[20]"))
    online = pbMysteryGiftDecrypt(online)
    t = []
    online.each { |gift| t.push(gift[0]) }
    online = t
  end
  # Show list of all gifts.
  command = 0
  loop do
    commands = pbRefreshMGCommands(master, online)
    command = pbMessage("\\ts[]" + _INTL("管理神秘礼物(X=在线)。"), commands, -1, nil, command)
    # Gift chosen
    if command == -1 || command == commands.length - 1   # Cancel
      break
    elsif command == commands.length - 2   # Export selected to file
      begin
        newfile = []
        master.each do |gift|
          newfile.push(gift) if online.include?(gift[0])
        end
        string = pbMysteryGiftEncrypt(newfile)
        File.open("MysteryGift.txt", "wb") { |f| f.write(string) }
        pbMessage(_INTL("礼物被保存到MysteryGift.txt了。"))
        pbMessage(_INTL("上传MysteryGift.txt到互联网上了。"))
      rescue
        pbMessage(_INTL("没有把礼物保存到MysteryGift.txt."))
      end
    elsif command >= 0 && command < commands.length - 2   # A gift
      cmd = 0
      loop do
        commands = pbRefreshMGCommands(master, online)
        gift = master[command]
        cmds = [_INTL("切换在线/离线"),
                _INTL("编辑"),
                _INTL("接收"),
                _INTL("删除"),
                _INTL("取消")]
        cmd = pbMessage("\\ts[]" + commands[command], cmds, -1, nil, cmd)
        case cmd
        when -1, cmds.length - 1
          break
        when 0   # Toggle on/offline
          if online.include?(gift[0])
            online.delete(gift[0])
          else
            online.push(gift[0])
          end
        when 1   # Edit
          newgift = pbEditMysteryGift(gift[1], gift[2], gift[0], gift[3])
          master[command] = newgift if newgift
        when 2   # Receive
          if !$player
            pbMessage(_INTL("没有加载存档，不能接收任何礼物。"))
            next
          end
          replaced = false
          $player.mystery_gifts.length.times do |i|
            if $player.mystery_gifts[i][0] == gift[0]
              $player.mystery_gifts[i] = gift
              replaced = true
            end
          end
          $player.mystery_gifts.push(gift) if !replaced
          pbReceiveMysteryGift(gift[0])
        when 3   # Delete
          master.delete_at(command) if pbConfirmMessage(_INTL("确定要删除此礼物吗？"))
          break
        end
      end
    end
  end
end

def pbRefreshMGCommands(master, online)
  commands = []
  master.each do |gift|
    itemname = "BLANK"
    if gift[1] == 0
      itemname = gift[2].speciesName
    elsif gift[1] > 0
      itemname = GameData::Item.get(gift[2]).name + sprintf(" x%d", gift[1])
    end
    ontext = ["[  ]", "[X]"][(online.include?(gift[0])) ? 1 : 0]
    commands.push(_INTL("{1} {2}：{3} ({4})", ontext, gift[0], gift[3], itemname))
  end
  commands.push(_INTL("导出选定的文件"))
  commands.push(_INTL("取消"))
  return commands
end

#===============================================================================
# Downloads all available Mystery Gifts that haven't been downloaded yet.
#===============================================================================
# Called from the Continue/New Game screen.
def pbDownloadMysteryGift(trainer)
  sprites = {}
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  addBackgroundPlane(sprites, "background", "mysterygift_bg", viewport)
  pbFadeInAndShow(sprites)
  sprites["msgwindow"] = pbCreateMessageWindow
  pbMessageDisplay(sprites["msgwindow"], _INTL("搜索礼物中。\n请稍等片刻……") + "\\wtnp[0]")
  string = pbDownloadToString(MysteryGift::URL)
  if nil_or_empty?(string)
    pbMessageDisplay(sprites["msgwindow"], _INTL("没有新的可接收礼物。"))
  else
    online = pbMysteryGiftDecrypt(string)
    pending = []
    online.each do |gift|
      notgot = true
      trainer.mystery_gifts.each do |j|
        notgot = false if j[0] == gift[0]
      end
      pending.push(gift) if notgot
    end
    if pending.length == 0
      pbMessageDisplay(sprites["msgwindow"], _INTL("没有新的可接收礼物。"))
    else
      loop do
        commands = []
        pending.each do |gift|
          commands.push(gift[3])
        end
        commands.push(_INTL("取消"))
        pbMessageDisplay(sprites["msgwindow"], _INTL("选择想接收的礼物。") + "\\wtnp[0]")
        command = pbShowCommands(sprites["msgwindow"], commands, -1)
        if command == -1 || command == commands.length - 1
          break
        else
          gift = pending[command]
          sprites["msgwindow"].visible = false
          if gift[1] == 0
            sprite = PokemonSprite.new(viewport)
            sprite.setOffset(PictureOrigin::CENTER)
            sprite.setPokemonBitmap(gift[2])
            sprite.x = Graphics.width / 2
            sprite.y = -sprite.bitmap.height / 2
          else
            sprite = ItemIconSprite.new(0, 0, gift[2], viewport)
            sprite.x = Graphics.width / 2
            sprite.y = -sprite.height / 2
          end
          timer_start = System.uptime
          start_y = sprite.y
          loop do
            sprite.y = lerp(start_y, Graphics.height / 2, 1.5, timer_start, System.uptime)
            Graphics.update
            Input.update
            sprite.update
            break if sprite.y >= Graphics.height / 2
          end
          pbMEPlay("Battle capture success")
          pbWait(3.0) { sprite.update }
          sprites["msgwindow"].visible = true
          pbMessageDisplay(sprites["msgwindow"], _INTL("接收到礼物了！") + "\1") { sprite.update }
          pbMessageDisplay(sprites["msgwindow"], _INTL("请到售卖道具的售货员那里领取礼物。")) { sprite.update }
          trainer.mystery_gifts.push(gift)
          pending.delete_at(command)
          timer_start = System.uptime
          loop do
            sprite.opacity = lerp(255, 0, 1.5, timer_start, System.uptime)
            Graphics.update
            Input.update
            sprite.update
            break if sprite.opacity <= 0
          end
          sprite.dispose
        end
        if pending.length == 0
          pbMessageDisplay(sprites["msgwindow"], _INTL("没有新的可接收礼物。"))
          break
        end
      end
    end
  end
  pbFadeOutAndHide(sprites)
  pbDisposeMessageWindow(sprites["msgwindow"])
  pbDisposeSpriteHash(sprites)
  viewport.dispose
end

#===============================================================================
# Converts an array of gifts into a string and back.
#===============================================================================
def pbMysteryGiftEncrypt(gift)
  ret = [Zlib::Deflate.deflate(Marshal.dump(gift))].pack("m")
  return ret
end

def pbMysteryGiftDecrypt(gift)
  return [] if nil_or_empty?(gift)
  ret = Marshal.restore(Zlib::Inflate.inflate(gift.unpack("m")[0]))
  if ret
    ret.each do |gft|
      if gft[1] == 0   # Pokémon
        gft[2] = gft[2]
      else   # Item
        gft[2] = GameData::Item.get(gft[2]).id
      end
    end
  end
  return ret
end

#===============================================================================
# Collecting a Mystery Gift from the deliveryman.
#===============================================================================
def pbNextMysteryGiftID
  $player.mystery_gifts.each do |i|
    return i[0] if i.length > 1
  end
  return 0
end

def pbReceiveMysteryGift(id)
  index = -1
  $player.mystery_gifts.length.times do |i|
    if $player.mystery_gifts[i][0] == id && $player.mystery_gifts[i].length > 1
      index = i
      break
    end
  end
  if index == -1
    pbMessage(_INTL("找不到ID为{1}的无主神秘礼物。", id))
    return false
  end
  gift = $player.mystery_gifts[index]
  if gift[1] == 0   # Pokémon
    gift[2].personalID = rand(2**16) | (rand(2**16) << 16)
    gift[2].calc_stats
    gift[2].timeReceived = Time.now.to_i
    gift[2].obtain_method = 4   # Fateful encounter
    gift[2].record_first_moves
    gift[2].obtain_level = gift[2].level
    gift[2].obtain_map = $game_map&.map_id || 0
    was_owned = $player.owned?(gift[2].species)
    if pbAddPokemonSilent(gift[2])
      pbMessage(_INTL("{1}收到了{2}！", $player.name, gift[2].name) + "\\me[Pkmn get]\\wtnp[80]")
      $player.mystery_gifts[index] = [id]
      # Show Pokédex entry for new species if it hasn't been owned before
      if Settings::SHOW_NEW_SPECIES_POKEDEX_ENTRY_MORE_OFTEN && !was_owned &&
         $player.has_pokedex && $player.pokedex.species_in_unlocked_dex?(gift[2].species)
        pbMessage(_INTL("{1}的资料被添加到宝可梦图鉴里了！", gift[2].name))
        $player.pokedex.register_last_seen(gift[2])
        pbFadeOutIn do
          scene = PokemonPokedexInfo_Scene.new
          screen = PokemonPokedexInfoScreen.new(scene)
          screen.pbDexEntry(gift[2].species)
        end
      end
      return true
    end
  elsif gift[1] > 0   # Item
    item = gift[2]
    qty = gift[1]
    if $bag.can_add?(item, qty)
      $bag.add(item, qty)
      itm = GameData::Item.get(item)
      itemname = (qty > 1) ? itm.portion_name_plural : itm.portion_name
      if item == :DNASPLICERS
        pbMessage("\\me[Item get]" + _INTL("你获得了\\c[1]{1}\\c[0]！", itemname) + "\\wtnp[40]")
      elsif itm.is_machine?   # TM or HM
        if qty > 1
          pbMessage("\\me[Machine get]" + _INTL("你获得了{1}个\\c[1]{2}{3}\\c[0]！",
                                                qty, itemname, GameData::Move.get(itm.move).name) + "\\wtnp[70]")
        else
          pbMessage("\\me[Machine get]" + _INTL("你获得了\\c[1]{1}{2}\\c[0]！", itemname,
                                                GameData::Move.get(itm.move).name) + "\\wtnp[70]")
        end
      elsif qty > 1
        pbMessage("\\me[Item get]" + _INTL("你获得了{1}个\\c[1]{2}\\c[0]！", qty, itemname) + "\\wtnp[40]")
      elsif itemname.starts_with_vowel?
        pbMessage("\\me[Item get]" + _INTL("你获得了\\c[1]{1}\\c[0]！", itemname) + "\\wtnp[40]")
      else
        pbMessage("\\me[Item get]" + _INTL("你获得了\\c[1]{1}\\c[0]！", itemname) + "\\wtnp[40]")
      end
      $player.mystery_gifts[index] = [id]
      return true
    end
  end
  return false
end
