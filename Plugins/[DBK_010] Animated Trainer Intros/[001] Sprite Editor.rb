#===============================================================================
# Trainer sprite editor.
#===============================================================================
class TrainerSpriteEditor
  def pbOpen
    @sprites = {}
    @viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
    @viewport.z = 99999
    @sprites["battle_bg"] = AnimatedPlane.new(@viewport)
    @sprites["battle_bg"].setBitmap("Graphics/Battlebacks/indoor1_bg")
    @sprites["battle_bg"].z = 0
    2.times do |i|
      baseX, baseY = Battle::Scene.pbBattlerPosition(i)
      @sprites["base_#{i}"] = IconSprite.new(baseX, baseY, @viewport)
      @sprites["base_#{i}"].setBitmap("Graphics/Battlebacks/indoor1_base#{i}")
      @sprites["base_#{i}"].z = 1
      bitmap = @sprites["base_#{i}"].bitmap
      if bitmap
        @sprites["base_#{i}"].ox = bitmap.width / 2
        @sprites["base_#{i}"].oy = (i == 0) ? bitmap.height : bitmap.height / 2
      end
    end
    @sprites["messageBox"] = IconSprite.new(0, Graphics.height - 96, @viewport)
    @sprites["messageBox"].setBitmap("Graphics/UI/Debug/battle_message")
    @sprites["messageBox"].z = 2
    @sprites["mugshot"] = IconSprite.new(40, 0, @viewport)
    @sprites["mugshot"].z = 3
    2.times do |i|
      trainerX, trainerY = Battle::Scene.pbTrainerPosition(i)
      if i == 1
        @sprites["shadow_#{i}"] = IconSprite.new(trainerX, trainerY, @viewport)
        @sprites["shadow_#{i}"].z = 4
      end
      @sprites["trainer_#{i}"] = IconSprite.new(trainerX, trainerY, @viewport)
      @sprites["trainer_#{i}"].z = 4
    end
    @sprites["icon"] = IconSprite.new(4, 4, @viewport)
    @sprites["icon"].z = 5
    @sprites["info"] = Window_UnformattedTextPokemon.new("")
    @sprites["info"].viewport = @viewport
    @sprites["info"].visible  = false
    pbGetSpriteList
    @starting        = true
    @trainerChanged  = false
    @oldTrainerIndex = 0
    @trainerID       = nil
    refresh
  end
  
  #-----------------------------------------------------------------------------
  # General utilities.
  #-----------------------------------------------------------------------------
  def pbClose
    if @trainerChanged && pbConfirmMessage(_INTL("已完成部分编辑，请保存更改。?"))
      pbSaveEdits
      @trainerChanged = false
    else
      GameData::TrainerType.load
    end
    pbFadeOutAndHide(@sprites) { update }
    pbDisposeSpriteHash(@sprites)
    @viewport.dispose
  end

  def pbSaveEdits
    GameData::TrainerType.save
    pbConvertTrainerData
  end

  def update
    pbUpdateSpriteHash(@sprites)
    return if !@sprites["trainer_1"].bitmap
    @sprites["trainer_1"].play
    @sprites["shadow_1"].play
  end
  
  #-----------------------------------------------------------------------------
  # Compiles a list of all valid trainer types.
  #-----------------------------------------------------------------------------
  def pbGetSpriteList
    alltrainers = []
    GameData::TrainerType.each do |tr|
      check = tr.id.to_s.split("_")
      gender = (tr.gender == 0) ? " ♂" : (tr.gender == 1) ? " ♀" : ""
      name = (check.length > 1) ? tr.name + gender + " (#{check.last})" : tr.name + gender
      alltrainers.push([tr.id, name])
    end
    alltrainers.sort! { |a, b| a[1] <=> b[1] }
    @alltrainers = alltrainers
    if @alltrainers.empty?
      pbMessage("未找到任何训练师类型。正在关闭编辑器……")
      pbClose
      return
    end
  end
  
  #-----------------------------------------------------------------------------
  # Sets all available images for trainer sprites.
  #-----------------------------------------------------------------------------
  def pbChangeTrainer(trainer)
    @trainerID = trainer
    return if !GameData::TrainerType.exists?(@trainerID)
    @sprites["trainer_1"].setTrainerBitmap(@trainerID)
    @sprites["shadow_1"].setTrainerBitmap(@trainerID, true)
    back_sprite = GameData::TrainerType.back_sprite_filename(@trainerID)
    hue = GameData::TrainerType.get(@trainerID).sprite_hue || 0
    @sprites["trainer_0"].setBitmap(back_sprite, hue)
    icon_sprite = GameData::TrainerType.charset_filename(@trainerID)
    @sprites["icon"].setBitmap(icon_sprite)
    mugshot_sprite = pbFindTrainerMugshot
    @sprites["mugshot"].setBitmap(mugshot_sprite, hue)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for finding a viable mugshot for a trainer.
  #-----------------------------------------------------------------------------
  def pbFindTrainerMugshot
    return nil if !@trainerID
    ["vsE4_", "rocket_", "hgss_vs_", "vsTrainer_"].each do |prefix|
      try_file = "Graphics/Transitions/" + prefix + @trainerID.to_s
      next if !pbResolveBitmap(try_file)
      return try_file
    end
    return nil
  end
  
  #-----------------------------------------------------------------------------
  # Refreshes the properties of all relevant trainer sprites.
  #-----------------------------------------------------------------------------
  def refresh
    if !@trainerID
      @sprites["trainer_1"].visible = false
      @sprites["shadow_1"].visible  = false
      @sprites["trainer_0"].visible = false
      @sprites["mugshot"].visible   = false
      @sprites["icon"].visible      = false
      return
    end
    bitmap = @sprites["trainer_1"].iconBitmap
    if bitmap
      data = GameData::TrainerType.get(@trainerID)
      scale = data.trainer_sprite_scale
      hue = data.trainer_sprite_hue
      bitmap.scale = scale
      bitmap.refresh
      bitmap.hue_change(hue)
      @sprites["trainer_1"].ox = bitmap.width / 2
      @sprites["trainer_1"].oy = bitmap.height
      @sprites["trainer_1"].visible = true
      bitmap = @sprites["shadow_1"].iconBitmap
      shadow = data.shadow_xy
      bitmap.scale = scale
      bitmap.refresh
      @sprites["shadow_1"].ox = bitmap.width / 2
      @sprites["shadow_1"].oy = bitmap.height
      @sprites["shadow_1"].x = @sprites["trainer_1"].x + shadow[0]
      @sprites["shadow_1"].y = @sprites["trainer_1"].y + shadow[1]
      @sprites["shadow_1"].visible = data.shows_shadow?
    end
    bitmap = @sprites["trainer_0"].bitmap
    if bitmap
      if bitmap.width > bitmap.height * 2
        @sprites["trainer_0"].src_rect.x = 0
        @sprites["trainer_0"].src_rect.width = bitmap.width / 5
      end
      @sprites["trainer_0"].ox = @sprites["trainer_0"].src_rect.width / 2
      @sprites["trainer_0"].oy = bitmap.height
      @sprites["trainer_0"].visible = true
    end
    bitmap = @sprites["icon"].bitmap
    if bitmap
      charwidth  = @sprites["icon"].bitmap.width
      charheight = @sprites["icon"].bitmap.height
      @sprites["icon"].src_rect = Rect.new(0, 0, charwidth / 4, charheight / 4)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utility for scaling sprites.
  #-----------------------------------------------------------------------------
  def pbSetSpriteScaling
    data = GameData::TrainerType.get(@trainerID)
    scale = data.trainer_sprite_scale
    oldscale = scale
    @sprites["info"].visible = true
    loop do
      @sprites["trainer_1"].visible = ((System.uptime * 8).to_i % 4) < 3
      Graphics.update
      Input.update
      self.update
      @sprites["info"].setTextToFit("Sprite Scale = #{scale}")
      if Input.repeat?(Input::UP) || Input.repeat?(Input::RIGHT) || Input.repeat?(Input::JUMPUP)
        scale += 1 if scale < 10
        data.sprite_scale = scale
        refresh
      elsif Input.repeat?(Input::DOWN) || Input.repeat?(Input::LEFT) || Input.repeat?(Input::JUMPDOWN)
        scale -= 1 if scale > 1
        data.sprite_scale = scale
        refresh
      elsif Input.repeat?(Input::USE)
        @trainerChanged = true if scale != oldscale
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        data.sprite_scale = oldscale
        pbPlayCancelSE
        refresh
        break
      end
    end
    @sprites["trainer_1"].visible = true
  end
  
  #-----------------------------------------------------------------------------
  # Utility for adjusting shadow position.
  #-----------------------------------------------------------------------------
  def pbSetShadowPosition
    data = GameData::TrainerType.get(@trainerID)
    if !data.shows_shadow?
      pbMessage(_INTL("此训练师没有可编辑的影子。"))
      return
    end
    shadow = data.shadow_xy
    oldshadow = shadow.clone
    @sprites["info"].visible = true
    loop do
      @sprites["shadow_1"].visible = ((System.uptime * 8).to_i % 4) < 3
      Graphics.update
      Input.update
      self.update
      @sprites["info"].setTextToFit("Shadow Position = #{shadow[0]},#{shadow[1]}")
      if Input.repeat?(Input::RIGHT) || Input.repeat?(Input::LEFT)
        shadow[0] += (Input.repeat?(Input::RIGHT)) ? 1 : -1
        data.shadow_xy = shadow
        refresh
      elsif Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
        shadow[1] += (Input.repeat?(Input::DOWN)) ? 1 : -1
        data.shadow_xy = shadow
        refresh
      elsif Input.repeat?(Input::USE)
        @trainerChanged = true if shadow != oldshadow
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        data.shadow_xy = oldshadow
        pbPlayCancelSE
        refresh
        break
      end
    end
    @sprites["shadow_1"].visible = true
  end
  
  #-----------------------------------------------------------------------------
  # Utility for toggling shadow visibility.
  #-----------------------------------------------------------------------------
  def pbSetShadowVisibility
    data = GameData::TrainerType.get(@trainerID)
    oldshadow = data.hide_shadow
    @sprites["info"].visible = true
    loop do
      Graphics.update
      Input.update
      self.update
      shadow = (data.shows_shadow?) ? "True" : "False"
      @sprites["info"].setTextToFit("Shadow Visible = #{shadow}")
      if Input.repeat?(Input::USE)
        data.hide_shadow = !data.hide_shadow
        pbPlayDecisionSE
        refresh
      elsif Input.repeat?(Input::BACK)
        pbPlayCancelSE
        if data.hide_shadow != oldshadow
          if pbConfirmMessage(_INTL("要设置这个影子的可见性吗？"))
            data.shadow_xy = [0, 0]
            @trainerChanged = true
          else
            data.hide_shadow = oldshadow
            refresh
          end
        end
        break
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utility for adjusting sprite hue.
  #-----------------------------------------------------------------------------
  def pbSetSpriteHue
    data = GameData::TrainerType.get(@trainerID)
    hue = data.trainer_sprite_hue
    oldhue = hue
    @sprites["info"].visible = true
    loop do
      Graphics.update
      Input.update
      self.update
      @sprites["info"].setTextToFit("Sprite Hue = #{hue}")
      if Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)
        hue += (Input.repeat?(Input::UP)) ? 1 : -1
        hue = 255 if hue >= 255
        hue = -255 if hue <= - 255
        data.sprite_hue = hue
        refresh
      elsif Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
        hue += (Input.repeat?(Input::RIGHT)) ? 10 : -10
        hue = 255 if hue >= 255
        hue = -255 if hue <= - 255
        data.sprite_hue = hue
        refresh
      elsif Input.repeat?(Input::USE)
        @trainerChanged = true if hue != oldhue
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        data.sprite_hue = oldhue
        pbPlayCancelSE
        refresh
        break 
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Handles all sprite editing utilities.
  #-----------------------------------------------------------------------------
  def pbSetParameter(param)
    return if !@trainerID
    case param
    when 0
      @sprites["trainer_1"].to_first_frame
      @sprites["shadow_1"].to_first_frame
    when 1 then pbSetSpriteScaling
    when 2 then pbSetShadowPosition
    when 3 then pbSetShadowVisibility
    when 4 then pbSetSpriteHue
    end
    @sprites["info"].visible = false
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Main menu.
  #-----------------------------------------------------------------------------
  def pbMenu
    refresh
    cw = Window_CommandPokemon.new(
      [_INTL("播放动画"),
       _INTL("设置图片缩放"),
       _INTL("设置影子位置"),
       _INTL("设置影子可见性"),
       _INTL("设置图像色调")]
    )
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = -1
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    cw.dispose
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Controls for navigating the trainer list.
  #-----------------------------------------------------------------------------
  def pbChooseTrainer
    if @starting
      pbFadeInAndShow(@sprites) { update }
      @starting = false
    end
    cw = Window_CommandPokemonEx.newEmpty(0, 0, 260, 176, @viewport)
    cw.rowHeight = 24
    pbSetSmallFont(cw.contents)
    cw.x = Graphics.width - cw.width
    cw.y = Graphics.height - cw.height
    commands = []
    @alltrainers.each { |sp| commands.push(sp[1]) }
    cw.commands = commands
    cw.index    = @oldTrainerIndex
    ret = false
    oldindex = -1
    @sprites["icon"].visible = true
    @sprites["mugshot"].visible = true
    loop do
      Graphics.update
      Input.update
      cw.update
      if cw.index != oldindex
        oldindex = cw.index
        pbChangeTrainer(@alltrainers[cw.index][0])
        refresh
      end
      self.update
      if Input.trigger?(Input::BACK)
        @sprites["icon"].visible = false
        @sprites["mugshot"].visible = false
        pbChangeTrainer(nil)
        refresh
        break
      elsif Input.trigger?(Input::USE)
        @sprites["icon"].visible = false
        @sprites["mugshot"].visible = false
        pbChangeTrainer(@alltrainers[cw.index][0])
        ret = true
        break
      elsif Input.trigger?(Input::ACTION)
        find_trainer = pbMessageFreeText("\\ts[]" + _INTL("搜索特定的训练家类型"), "", false, 100, Graphics.width)
        next if nil_or_empty?(find_trainer)
        next if find_trainer.downcase == commands[cw.index].downcase
        new_trainer = false
        commands.each_with_index do |name, i|
          next if !name.downcase.include?(find_trainer.downcase)
          new_trainer = true
          pbPlayDecisionSE
          oldindex = cw.index
          cw.index = i
          pbChangeTrainer(@alltrainers[i][0])
          refresh
          break
        end
        pbMessage("No trainer type found.") if !new_trainer
      end
    end
    @oldTrainerIndex = cw.index
    cw.dispose
    return ret
  end
end

#===============================================================================
# Accessing the trainer sprite editor.
#===============================================================================
class TrainerSpriteEditorScreen
  def initialize(scene)
    @scene = scene
  end
  
  def pbStart
    @scene.pbOpen
    loop do
      trainerID = @scene.pbChooseTrainer
      break if !trainerID
      loop do
        command = @scene.pbMenu
        break if command < 0
        loop do
          par = @scene.pbSetParameter(command)
          break if !par
        end
      end
    end
    @scene.pbClose
  end
end

#===============================================================================
# Rewrites the trainer type debug handler.
#===============================================================================
MenuHandlers.add(:debug_menu, :set_trainer_types, {
  "name"        => _INTL("更改trainer_types.txt"),
  "parent"      => :pbs_editors_menu,
  "description" => _INTL("编辑训练家类型。"),
  "effect"      => proc {
    cmd = 0
    loop do
      cmds = [
        _INTL("编辑类型"),
        _INTL("编辑图片")
      ]
      cmd = pbShowCommands(nil, cmds, -1, cmd)
      break if cmd < 0
      case cmd
      when 0
        pbFadeOutIn { pbTrainerTypeEditor }
      when 1
        pbFadeOutIn do
          sp = TrainerSpriteEditor.new
          sps = TrainerSpriteEditorScreen.new(sp)
          sps.pbStart
        end
      end
    end
  }
})