#===============================================================================
#
#===============================================================================
class PokemonLoadPanel < Sprite
  attr_reader :selected

  TEXT_COLOR               = Color.new(232, 232, 232)
  TEXT_SHADOW_COLOR        = Color.new(136, 136, 136)
  MALE_TEXT_COLOR          = Color.new(56, 160, 248)
  MALE_TEXT_SHADOW_COLOR   = Color.new(56, 104, 168)
  FEMALE_TEXT_COLOR        = Color.new(240, 72, 88)
  FEMALE_TEXT_SHADOW_COLOR = Color.new(160, 64, 64)

  def initialize(index, title, isContinue, trainer, stats, mapid, viewport = nil)
    super(viewport)
    @index = index
    @title = title
    @isContinue = isContinue
    @trainer = trainer
    @totalsec = stats&.play_time.to_i || 0
    @mapid = mapid
    @selected = (index == 0)
    @bgbitmap = AnimatedBitmap.new("Graphics/UI/Load/panels")
    @refreshBitmap = true
    @refreshing = false
    refresh
  end

  def dispose
    @bgbitmap.dispose
    self.bitmap.dispose
    super
  end

  def selected=(value)
    return if @selected == value
    @selected = value
    @refreshBitmap = true
    refresh
  end

  def pbRefresh
    @refreshBitmap = true
    refresh
  end

  def refresh
    return if @refreshing
    return if disposed?
    @refreshing = true
    if !self.bitmap || self.bitmap.disposed?
      self.bitmap = Bitmap.new(@bgbitmap.width, 222)
      pbSetSystemFont(self.bitmap)
    end
    if @refreshBitmap
      @refreshBitmap = false
      self.bitmap&.clear
      if @isContinue
        self.bitmap.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, (@selected) ? 222 : 0, @bgbitmap.width, 222))
      else
        self.bitmap.blt(0, 0, @bgbitmap.bitmap, Rect.new(0, 444 + ((@selected) ? 46 : 0), @bgbitmap.width, 46))
      end
      textpos = []
      if @isContinue
        textpos.push([@title, 32, 16, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        textpos.push([_INTL("徽章："), 32, 118, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        textpos.push([@trainer.badge_count.to_s, 206, 118, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        textpos.push([_INTL("图鉴："), 32, 150, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        textpos.push([@trainer.pokedex.seen_count.to_s, 206, 150, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        textpos.push([_INTL("时长："), 32, 182, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        hour = @totalsec / 60 / 60
        min  = @totalsec / 60 % 60
        if hour > 0
          textpos.push([_INTL("{1}时{2}分", hour, min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        else
          textpos.push([_INTL("{1}分", min), 206, 182, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
        end
        if @trainer.male?
          textpos.push([@trainer.name, 112, 70, :left, MALE_TEXT_COLOR, MALE_TEXT_SHADOW_COLOR])
        elsif @trainer.female?
          textpos.push([@trainer.name, 112, 70, :left, FEMALE_TEXT_COLOR, FEMALE_TEXT_SHADOW_COLOR])
        else
          textpos.push([@trainer.name, 112, 70, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
        end
        mapname = pbGetMapNameFromId(@mapid)
        mapname.gsub!(/\\PN/, @trainer.name)
        textpos.push([mapname, 386, 16, :right, TEXT_COLOR, TEXT_SHADOW_COLOR])
      else
        textpos.push([@title, 32, 14, :left, TEXT_COLOR, TEXT_SHADOW_COLOR])
      end
      pbDrawTextPositions(self.bitmap, textpos)
    end
    @refreshing = false
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoad_Scene
  def pbStartScene(commands, show_continue, trainer, stats, map_id)
    @commands = commands
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)
    y = 32
    commands.length.times do |i|
      @sprites["panel#{i}"] = PokemonLoadPanel.new(
        i, commands[i], (show_continue) ? (i == 0) : false, trainer, stats, map_id, @viewport
      )
      @sprites["panel#{i}"].x = 48
      @sprites["panel#{i}"].y = y
      @sprites["panel#{i}"].pbRefresh
      y += (show_continue && i == 0) ? 224 : 48
    end
    @sprites["cmdwindow"] = Window_CommandPokemon.new([])
    @sprites["cmdwindow"].viewport = @viewport
    @sprites["cmdwindow"].visible  = false
  end

  def pbStartScene2
    pbFadeInAndShow(@sprites) { pbUpdate }
  end

  def pbStartDeleteScene
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99998
    addBackgroundOrColoredPlane(@sprites, "background", "Load/bg", Color.new(248, 248, 248), @viewport)
  end

  def pbUpdate
    oldi = @sprites["cmdwindow"].index rescue 0
    pbUpdateSpriteHash(@sprites)
    newi = @sprites["cmdwindow"].index rescue 0
    if oldi != newi
      @sprites["panel#{oldi}"].selected = false
      @sprites["panel#{oldi}"].pbRefresh
      @sprites["panel#{newi}"].selected = true
      @sprites["panel#{newi}"].pbRefresh
      while @sprites["panel#{newi}"].y > Graphics.height - 80
        @commands.length.times do |i|
          @sprites["panel#{i}"].y -= 48
        end
        6.times do |i|
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y -= 48
        end
        @sprites["player"].y -= 48 if @sprites["player"]
      end
      while @sprites["panel#{newi}"].y < 32
        @commands.length.times do |i|
          @sprites["panel#{i}"].y += 48
        end
        6.times do |i|
          break if !@sprites["party#{i}"]
          @sprites["party#{i}"].y += 48
        end
        @sprites["player"].y += 48 if @sprites["player"]
      end
    end
  end

  def pbSetParty(trainer)
    return if !trainer || !trainer.party
    meta = GameData::PlayerMetadata.get(trainer.character_ID)
    if meta
      filename = pbGetPlayerCharset(meta.walk_charset, trainer, true)
      @sprites["player"] = TrainerWalkingCharSprite.new(filename, @viewport)
      if !@sprites["player"].bitmap
        raise _INTL("找不到玩家角色{1}的行走图（文件名：“{2}”）。", trainer.character_ID, filename)
      end
      charwidth  = @sprites["player"].bitmap.width
      charheight = @sprites["player"].bitmap.height
      @sprites["player"].x = 112 - (charwidth / 8)
      @sprites["player"].y = 112 - (charheight / 8)
      @sprites["player"].z = 99999
    end
    trainer.party.each_with_index do |pkmn, i|
      @sprites["party#{i}"] = PokemonIconSprite.new(pkmn, @viewport)
      @sprites["party#{i}"].setOffset(PictureOrigin::CENTER)
      @sprites["party#{i}"].x = 334 + (66 * (i % 2))
      @sprites["party#{i}"].y = 112 + (50 * (i / 2))
      @sprites["party#{i}"].z = 99999
    end
  end

  def pbChoose(commands)
    @sprites["cmdwindow"].commands = commands
    loop do
      Graphics.update
      Input.update
      pbUpdate
      if Input.trigger?(Input::USE)
        return @sprites["cmdwindow"].index
      end
    end
  end

  def pbEndScene
    pbFadeOutAndHide(@sprites) { pbUpdate }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbCloseScene
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end
end

#===============================================================================
#
#===============================================================================
class PokemonLoadScreen
  def initialize(scene)
    @scene = scene
    if SaveData.exists?
      @save_data = load_save_file(SaveData::FILE_PATH)
    else
      @save_data = {}
    end
  end

  # @param file_path [String] file to load save data from
  # @return [Hash] save data
  def load_save_file(file_path)
    save_data = SaveData.read_from_file(file_path)
    unless SaveData.valid?(save_data)
      if File.file?(file_path + ".bak")
        pbMessage(_INTL("存档已损坏，将加载备份存档。"))
        save_data = load_save_file(file_path + ".bak")
      else
        self.prompt_save_deletion
        return {}
      end
    end
    return save_data
  end

  # Called if all save data is invalid.
  # Prompts the player to delete the save files.
  def prompt_save_deletion
    pbMessage(_INTL("游戏存档已损坏或者不兼容。") + "\1")
    exit unless pbConfirmMessageSerious(
      _INTL("要删除游戏存档，重新开始游戏吗？")
    )
    self.delete_save_data
    $game_system   = Game_System.new
    $PokemonSystem = PokemonSystem.new
  end

  def pbStartDeleteScreen
    @scene.pbStartDeleteScene
    @scene.pbStartScene2
    if SaveData.exists?
      if pbConfirmMessageSerious(_INTL("删除游戏存档吗？"))
        pbMessage(_INTL("游戏存档被删除后就无法恢复了") + "\1")
        if pbConfirmMessageSerious(_INTL("确定要删除游戏存档吗？"))
          pbMessage(_INTL("正在删除游戏存档，请不要关闭游戏。") + "\\wtnp[0]")
          self.delete_save_data
        end
      end
    else
      pbMessage(_INTL("没有找到游戏存档。"))
    end
    @scene.pbEndScene
    $scene = pbCallTitle
  end

  def delete_save_data
    begin
      SaveData.delete_file
      pbMessage(_INTL("游戏存档已删除。"))
    rescue SystemCallError
      pbMessage(_INTL("无法删除所有存档。"))
    end
  end

  def pbStartLoadScreen
    commands = []
    cmd_continue     = -1
    cmd_new_game     = -1
    cmd_options      = -1
    cmd_language     = -1
    cmd_mystery_gift = -1
    cmd_debug        = -1
    cmd_quit         = -1
    show_continue = !@save_data.empty?
    if show_continue
      commands[cmd_continue = commands.length] = _INTL("继续游戏")
      if @save_data[:player].mystery_gift_unlocked
        commands[cmd_mystery_gift = commands.length] = _INTL("神秘礼物")
      end
    end
    commands[cmd_new_game = commands.length]  = _INTL("新的游戏")
    commands[cmd_options = commands.length]   = _INTL("设置")
    commands[cmd_language = commands.length]  = _INTL("语言") if Settings::LANGUAGES.length >= 2
    commands[cmd_debug = commands.length]     = _INTL("调试") if $DEBUG
    commands[cmd_quit = commands.length]      = _INTL("退出游戏")
    map_id = show_continue ? @save_data[:map_factory].map.map_id : 0
    @scene.pbStartScene(commands, show_continue, @save_data[:player], @save_data[:stats], map_id)
    @scene.pbSetParty(@save_data[:player]) if show_continue
    @scene.pbStartScene2
    loop do
      command = @scene.pbChoose(commands)
      pbPlayDecisionSE if command != cmd_quit
      case command
      when cmd_continue
        @scene.pbEndScene
        Game.load(@save_data)
        return
      when cmd_new_game
        @scene.pbEndScene
        Game.start_new
        return
      when cmd_mystery_gift
        pbFadeOutIn { pbDownloadMysteryGift(@save_data[:player]) }
      when cmd_options
        pbFadeOutIn do
          scene = PokemonOption_Scene.new
          screen = PokemonOptionScreen.new(scene)
          screen.pbStartScreen(true)
        end
      when cmd_language
        @scene.pbEndScene
        $PokemonSystem.language = pbChooseLanguage
        MessageTypes.load_message_files(Settings::LANGUAGES[$PokemonSystem.language][1])
        if show_continue
          @save_data[:pokemon_system] = $PokemonSystem
          File.open(SaveData::FILE_PATH, "wb") { |file| Marshal.dump(@save_data, file) }
        end
        $scene = pbCallTitle
        return
      when cmd_debug
        pbFadeOutIn { pbDebugMenu(false) }
      when cmd_quit
        pbPlayCloseMenuSE
        @scene.pbEndScene
        $scene = nil
        return
      else
        pbPlayBuzzerSE
      end
    end
  end
end
