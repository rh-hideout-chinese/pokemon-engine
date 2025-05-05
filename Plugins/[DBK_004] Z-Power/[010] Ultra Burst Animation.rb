#===============================================================================
# Battle animation for triggering Ultra Burst.
#===============================================================================
class Battle::Scene::Animation::BattlerUltraBurst < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    @idxBattler = idxBattler
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    @pkmn = @battler.pokemon
    @ultra = {
      :pokemon => @pkmn,
      :species => @pkmn.species,
      :gender  => @pkmn.gender,
      :form    => @pkmn.getUltraForm,
      :shiny   => @pkmn.shiny?,
      :shadow  => @pkmn.shadowPokemon?,
      :hue     => @pkmn.super_shiny_hue
    }
    @cry_file = GameData::Species.cry_filename(@ultra[:species], @ultra[:form])
    #---------------------------------------------------------------------------
    # Gets background and animation data.
    @path = Settings::DELUXE_GRAPHICS_PATH
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
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
    bgData = dxSetBackdrop(@path + "Z-Power/ultra_bg", @bg_file, delay)
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up bases.
    baseData = dxSetBases(@path + "Z-Power/ultra_base", @base_file, delay, center_x, center_y)
    arrBASES = baseData[0]
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up shine.
    shineData = dxSetSprite(@path + "shine", delay, center_x, center_y)
    picSHINE, sprSHINE = shineData[0], shineData[1]
    #---------------------------------------------------------------------------
    # Sets up battler.
    pokeData = dxSetPokemon(@pkmn, delay, !@opposes)
    picPOKE, sprPOKE = pokeData[0], pokeData[1]
    #---------------------------------------------------------------------------
    # Sets up Ultra Pokemon.
    arrPOKE = dxSetPokemonWithOutline(@ultra, delay, !@opposes)
    #---------------------------------------------------------------------------
    # Sets up pulse.
    pulseData = dxSetSprite(@path + "pulse", delay, center_x, center_y, PictureOrigin::CENTER, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
    #---------------------------------------------------------------------------
    # Sets up Ultra icon.
    iconData = dxSetSprite(@path + "Z-Power/ultra_icon", delay, center_x, center_y, PictureOrigin::CENTER, 0)
    picICON, sprICON = iconData[0], iconData[1]
    #---------------------------------------------------------------------------
    # Sets up particles.
    arrPARTICLES = dxSetParticlesRect(@path + "Z-Power/ultra_strobes", delay, 154, 128, 200, false, true)
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
    arrBASES.first.setVisible(delay, true)
    picPOKE.setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveDelta(delay, 6, 0, -38)
    picBUTTON.moveDelta(delay + 26, 6, 0, 38)
    #---------------------------------------------------------------------------
    # Darkens background/base tone; begins zooming in ultra particles.
    picPOKE.setSE(delay, "DX Action")
    picBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    arrBASES.first.moveTone(delay, 15, Tone.new(-200, -200, -200))
    repeat = delay
    2.times do |t|
      repeat -= 4  if t > 0
      arrPARTICLES.each_with_index do |p, i|
        p[0].setVisible(repeat + i, true)
        p[0].setXY(repeat + i, p[1], p[2])
        p[0].moveXY(repeat + i, 4, center_x, center_y)
        p[0].moveZoom(repeat + i, 4, 0)
        repeat = p[0].totalDuration
        p[0].setVisible(repeat + i, false)
        p[0].setXY(repeat + i, p[1], p[2])
        p[0].setZoom(repeat + i, 100)
        repeat = p[0].totalDuration - 2
      end
    end
    #---------------------------------------------------------------------------
    # Shakes Pokemon; changes tone to white; shows and zooms in ultra icon.
    t = 0.5
    16.times do |i|
      picPOKE.moveXY(delay, t, @pictureSprites[sprPOKE].x, @pictureSprites[sprPOKE].y + 2)
      picPOKE.moveXY(delay + t, t, @pictureSprites[sprPOKE].x, @pictureSprites[sprPOKE].y - 2)
      delay = picPOKE.totalDuration
      if i == 0
        picICON.setVisible(delay + 8, true)
        picICON.moveOpacity(delay + 8, 16, 255)
        picICON.moveZoom(delay + 8, 16, 50)
      end
    end
    picPOKE.moveTone(delay - 8, 2, Tone.new(255, 255, 255, 255))
    #---------------------------------------------------------------------------
    # White screen flash; hides icon; reveals Ultra Pokemon with outline.
    picFADE.setColor(delay + 8, Color.white)
    picFADE.moveOpacity(delay + 8, 12, 255)
    delay = picFADE.totalDuration
    picPOKE.setVisible(delay, false)
    picICON.setVisible(delay, false)
    arrPOKE.each { |p, s| p.setVisible(delay, true) }
    picFADE.moveOpacity(delay, 6, 0)
    picFADE.setColor(delay + 6, Color.black)
    delay = picFADE.totalDuration
    #---------------------------------------------------------------------------
    # Shakes Pokemon; plays cry; flashes overlay. Fades out.
    picOVERLAY.setVisible(delay, true)
    picSHINE.setVisible(delay, true)
    picPULSE.setVisible(delay, true)
    picPULSE.moveZoom(delay, 5, 1000)
    picPULSE.moveOpacity(delay + 2, 5, 0)
    16.times do |i|
      if i > 0
        arrPOKE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
        arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
        picOVERLAY.moveOpacity(delay + t, 2, 160)
        picSHINE.moveOpacity(delay + t, 2, 160)
      else
        picPOKE.setSE(delay + t, @cry_file) if @cry_file
      end
      picOVERLAY.moveOpacity(delay + t, 2, 240)
      picSHINE.moveOpacity(delay + t, 2, 240)
      delay = arrPOKE.last[0].totalDuration
    end
    picOVERLAY.moveOpacity(delay, 4, 0)
    picSHINE.moveOpacity(delay, 4, 0)
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbShowUltraBurst(idxBattler)
    ultraAnim = Animation::BattlerUltraBurst.new(@sprites, @viewport, idxBattler, @battle)
    loop do
	  if Input.press?(Input::ACTION)
	    pbPlayCancelSE
	    break 
	  end
      ultraAnim.update
      pbUpdate
      break if ultraAnim.animDone?
    end
    ultraAnim.dispose
  end
end