#===============================================================================
# Battle animation for triggering Z-Moves.
#===============================================================================
class Battle::Scene::Animation::BattlerZMove < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, battle, move_id)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    @pkmn = @battler.visiblePokemon
    @zpkmn = {
      :pokemon => @pkmn,
      :species => @pkmn.species,
      :gender  => @pkmn.gender,
      :form    => @pkmn.form,
      :shiny   => @pkmn.shiny?,
      :shadow  => @pkmn.shadowPokemon?,
      :hue     => @pkmn.super_shiny_hue
    }
    @cry_file = GameData::Species.cry_filename_from_pokemon(@pkmn)
    if @battler.item && @battler.item.is_zcrystal?
      @zcrystal_file = "Graphics/Items/" + @battler.item_id.to_s
    end
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index.
    if !@battler.wild?
      items = []
      trainer_item = :ZRING
      trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
      @trainer_file = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
      GameData::Item.each { |item| items.push(item.id) if item.has_flag?("ZRing") }
      if @battle.pbOwnedByPlayer?(idxBattler)
        items.each do |item|
          next if !$bag.has?(item)
          trainer_item = item
        end
      else
        trainer_items = @battle.pbGetOwnerItems(idxBattler)
        items.each do |item|
          next if !trainer_items&.include?(item)
          trainer_item = item
        end
      end
      @item_file = "Graphics/Items/" + trainer_item.to_s
    end
    #---------------------------------------------------------------------------
    # Gets background and animation data.
    @path = Settings::DELUXE_GRAPHICS_PATH
    @title_file = @path + "Z-Power/Z-Titles/" + move_id.to_s
    @upper_title = [:CATASTROPIKA, :TENMILLIONVOLTTHUNDERBOLT, :LETSSNUGGLEFOREVER].include?(move_id)
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
    @type_outline, @type_bg = pbGetTypeColors(GameData::Move.get(move_id).type)
    super(sprites, viewport)
  end
  
  #-----------------------------------------------------------------------------
  # Plays the animation.
  #-----------------------------------------------------------------------------
  def createProcesses
    delay = 0
    center_x, center_y = Graphics.width / 2, Graphics.height / 2
    #---------------------------------------------------------------------------
    # Sets up background.
    bgData = dxSetBackdrop(@path + "Z-Power/bg", @bg_file, delay)
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up bases.
    baseData = dxSetBases(@path + "Z-Power/base", @base_file, delay, center_x, center_y, !@battler.wild?)
    arrBASES, base_width = baseData[0], baseData[1]
    #---------------------------------------------------------------------------
    # Sets up trainer & Z-Ring                                          
    if !@battler.wild?
      trData = dxSetTrainerWithItem(@trainer_file, @item_file, delay, !@opposes, base_width)
      picTRAINER, arrITEM = trData[0], trData[1]
    end
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up battler.
    arrPOKE = dxSetPokemonWithOutline(@zpkmn, delay, !@opposes, !@battler.wild?, Color.new(*@type_outline))
    dxSetSpotPatterns(@pkmn, @pictureSprites[arrPOKE.last[1]]) if @pkmn.form == @zpkmn[:form]
    #---------------------------------------------------------------------------
    # Sets up Z-Crystal.
    pkmnsprite = @pictureSprites[arrPOKE.last[1]]
    item_y = pkmnsprite.y - pkmnsprite.bitmap.height + findTop(pkmnsprite.bitmap)
    arrCRYSTAL = dxSetSpriteWithOutline(@zcrystal_file, delay, center_x, item_y)
    #---------------------------------------------------------------------------
    # Sets particles.
    arrPARTICLES = dxSetParticles(@path + "Z-Power/particle", delay, center_x, center_y, 200)
    #---------------------------------------------------------------------------
    # Sets up pulse.
    offset_y = (@battler.wild?) ? center_y : center_y + 20
    pulseData = dxSetSprite(@path + "pulse", delay, center_x, offset_y, PictureOrigin::CENTER, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
    #---------------------------------------------------------------------------
    # Sets Z-Move title.
    arrTITLE = dxSetTitleWithOutline(@title_file, delay, @upper_title, Color.new(*@type_outline))
    #---------------------------------------------------------------------------
    # Sets up skip button & fade out.
    picBUTTON = dxSetSkipButton(delay)
    picFADE = dxSetFade(delay)
    ############################################################################
    # Animation start.
    ############################################################################
    # Fades in scene.
    picFADE.moveOpacity(delay, 8, 255)
    delay = picFADE.totalDuration
    picBG.setVisible(delay, true)
    arrBASES.last.setVisible(delay, true)
    arrPOKE.last[0].setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveDelta(delay, 6, 0, -38)
    picBUTTON.moveDelta(delay + 36, 6, 0, 38)
    #---------------------------------------------------------------------------
    # Slides trainer on screen with base (non-wild only).
    if !@battler.wild?
      picTRAINER.setVisible(delay + 4, true)
      arrBASES.first.setVisible(delay + 4, true)
      delta = (base_width.to_f * 0.75).to_i
      delta = -delta if @opposes
      picTRAINER.moveDelta(delay + 4, 8, delta, 0)
      arrBASES.first.moveDelta(delay + 4, 8, delta, 0)
      delay = picTRAINER.totalDuration + 1
      #-------------------------------------------------------------------------
      # Z-Ring appears with outline; slide upwards.
      picTRAINER.setSE(delay, "DX Action")
      arrITEM.each do |p, s| 
        p.setVisible(delay, true)
        p.moveDelta(delay, 15, 0, -20)
        p.moveOpacity(delay, 15, 255)
      end
      delay = picTRAINER.totalDuration
    end
    #---------------------------------------------------------------------------
    # Z-Crystal appears with outline; slide upwards.
    picBG.setSE(delay, "DX Action") if @battler.wild?    
    arrCRYSTAL.each do |p, s| 
      p.setVisible(delay, true)
      p.moveDelta(delay, 15, 0, -20)
      p.moveOpacity(delay, 15, 255)
    end
    #---------------------------------------------------------------------------
    # Particles begin traveling towards the Pokemon; overlay shown.
    picOVERLAY.setVisible(delay, true)
    picOVERLAY.moveOpacity(delay, 30, 255)
    repeat = delay
    2.times do |t|
      repeat -= 4 if t > 0
      arrPARTICLES.each_with_index do |p, i|
        p[0].setVisible(repeat + i, true)
        p[0].moveXY(repeat + i, 4, center_x, center_y)
        repeat = p[0].totalDuration
        p[0].setVisible(repeat + i, false)
        p[0].setXY(repeat + i, p[1], p[2])
        p[0].setZoom(repeat + i, 100)
        repeat = p[0].totalDuration - 2
      end
    end
    #---------------------------------------------------------------------------
    # Background/base match move type color; Pokemon becomes white. Shakes Pokemon.
    picBG.moveColor(delay, 15, Color.new(*@type_bg, 180))
    picBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    arrBASES.each do |p|
      p.moveColor(delay, 15, Color.new(*@type_bg, 180))
      p.moveTone(delay, 15, Tone.new(-200, -200, -200))
    end
    arrPOKE.last[0].moveTone(delay, 15, Tone.new(255, 255, 255, 255))
    delay = arrPOKE.last[0].totalDuration
    t = 0.5
    16.times do |i|
      arrPOKE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
      arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
      delay = arrPOKE.first[0].totalDuration
    end
    #---------------------------------------------------------------------------
    # White screen flash; hides item sprites; reverts Pokemon tone; shows outline.
    picFADE.setColor(delay, Color.white)
    picFADE.moveOpacity(delay, 12, 255)
    delay = picFADE.totalDuration
    picOVERLAY.setVisible(delay, false)
    arrITEM.each { |p, s| p.setVisible(delay, false) } if !@battler.wild?
    arrCRYSTAL.each { |p, s| p.setVisible(delay, false) }
    arrPOKE.each { |p, s| p.setVisible(delay, true) }
    arrPOKE.last[0].moveTone(delay, 6, Tone.new(0, 0, 0, 0))
    picFADE.moveOpacity(delay, 6, 0)
    picFADE.setColor(delay + 6, Color.black)
    delay = picFADE.totalDuration
    #---------------------------------------------------------------------------
    # Z-Move title zooms on screen; shakes title and reveals name; fades out.
    if !arrTITLE.empty?
      arrTITLE.last[0].setSE(delay, "Z-Move Title")
      arrTITLE.each do |p, s|
        p.setVisible(delay, true)
        p.moveOpacity(delay, 4, 255)
        p.moveZoom(delay, 4, 100)
      end
      delay = arrTITLE.last[0].totalDuration
      16.times do |i|
        arrTITLE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x + 8, @pictureSprites[s].y) }
        arrTITLE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x - 8, @pictureSprites[s].y) }
        delay = arrTITLE.last[0].totalDuration
      end
      arrTITLE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y) }
      picPULSE.setVisible(delay, true)
      picPULSE.moveZoom(delay, 5, 1000)
      picPULSE.moveOpacity(delay + 2, 5, 0)
      arrTITLE.each do |p, s|
        p.setXY(delay, @pictureSprites[s].x + 8, @pictureSprites[s].y)
        p.setTone(delay, Tone.new(0, 0, 0, 0))
      end
      delay = arrTITLE.last[0].totalDuration
    end
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbShowZMove(idxBattler, move_id)
    zmoveAnim = Animation::BattlerZMove.new(@sprites, @viewport, idxBattler, @battle, move_id)
    loop do
      if Input.press?(Input::ACTION)
        pbPlayCancelSE
        break 
      end
      zmoveAnim.update
      pbUpdate
      break if zmoveAnim.animDone?
    end
    zmoveAnim.dispose
  end
end