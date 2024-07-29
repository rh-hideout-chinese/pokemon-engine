#===============================================================================
# Battle animation for triggering Terastallization.
#===============================================================================
class Battle::Scene::Animation::BattlerTerastallize < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, battle)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    @pkmn = @battler.visiblePokemon
    @terastal = [@pkmn.species, @pkmn.gender, @pkmn.getTerastalForm, @pkmn.shiny?, @pkmn.shadowPokemon?]
    @cry_file = GameData::Species.cry_filename_from_pokemon(@pkmn)
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index (non-wild only).
    if !@battler.wild?
      items = []
      trainer_item = :TERAORB
      trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
      @trainer_file = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
      GameData::Item.each { |item| items.push(item.id) if item.has_flag?("TeraOrb") }
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
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
    @type_outline, @type_bg = pbGetTypeColors(@battler.tera_type)
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
    bgData = dxSetBackdrop(@path + "Tera/bg", @bg_file, delay)
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up bases.
    baseData = dxSetBases(@path + "Tera/base", @base_file, delay, center_x, center_y, !@battler.wild?)
    arrBASES, tr_base_offset = baseData[0], baseData[1]
    #---------------------------------------------------------------------------
    # Sets up trainer & Tera Orb                                        
    if !@battler.wild?
      trData = dxSetTrainerWithItem(@trainer_file, @item_file, delay, !@opposes)
      picTRAINER, trainer_end_x, trainer_y, arrITEM = trData[0], trData[1], trData[2], trData[3]
    end
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up shine.
    shineData = dxSetSprite(@path + "shine", delay, center_x, center_y, !@battler.wild?)
    picSHINE, sprSHINE = shineData[0], shineData[1]
    picSHINE.setColor(delay, Color.new(*@type_outline))
    #---------------------------------------------------------------------------
    # Sets up battler.
    pokeData = dxSetPokemon(@pkmn, delay, !@opposes, !@battler.wild?)
    picPOKE, sprPOKE = pokeData[0], pokeData[1]
    #---------------------------------------------------------------------------
    # Sets up Tera Pokemon.
    arrPOKE = dxSetPokemonWithOutline(@terastal, delay, !@opposes, !@battler.wild?, Color.new(*@type_outline))
    @pictureSprites[arrPOKE.last[1]].set_tera_pattern(@pkmn, true)
    #---------------------------------------------------------------------------
    # Sets up Tera crystals.
    arrCRYSTALS = []
    3.times do |i|
      crystal = dxSetSprite(@path + "Tera/crystal_#{i + 1}", delay, center_x, center_y, !@battler.wild?, 100, 0)
      arrCRYSTALS.push([crystal[0], crystal[1]])
    end
    #---------------------------------------------------------------------------
    # Sets up shattered Tera crystals.
    arrBREAK = dxSetParticlesRect(@path + "Tera/crystal_4", delay, 154, 166, 100, !@battler.wild?)
    #---------------------------------------------------------------------------
    # Sets up Tera pulse.
    pulseData = dxSetSprite(@path + "Tera/pulse", delay, center_x, center_y, !@battler.wild?, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
    #---------------------------------------------------------------------------
    # Sets up Tera icon.
    iconData = dxSetSprite(@path + "Tera/icon", delay, center_x, center_y, !@battler.wild?, 0, 50)
    picICON, sprICON = iconData[0], iconData[1]
    #---------------------------------------------------------------------------
    # Sets up rainbow shine.
    shine2Data = dxSetSprite(@path + "Tera/shine", delay, center_x, center_y, !@battler.wild?)
    picSHINE2, sprSHINE2 = shine2Data[0], shine2Data[1]
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
    picPOKE.setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveXY(delay, 6, 0, Graphics.height - 38)
    picBUTTON.moveXY(delay + 36, 6, 0, Graphics.height)
    #---------------------------------------------------------------------------
    # Slides trainer on screen with base (non-wild only).
    if !@battler.wild?
      picTRAINER.setVisible(delay + 4, true)
      arrBASES.first.setVisible(delay + 4, true)
      picTRAINER.moveXY(delay + 4, 8, trainer_end_x, trainer_y)
      arrBASES.first.moveXY(delay + 4, 8, trainer_end_x - tr_base_offset, center_y - 33)
      delay = picTRAINER.totalDuration + 1
      #-------------------------------------------------------------------------
      # Tera Orb appears with outline; slide upwards.
      picTRAINER.setSE(delay, "Anim/Saint7", 100, 90)
      arrITEM.each do |p, s| 
        p.setVisible(delay, true)
        p.moveXY(delay, 15, @pictureSprites[s].x, @pictureSprites[s].y - 20)
        p.moveOpacity(delay, 15, 255)
      end
      delay = picTRAINER.totalDuration
    end
    #---------------------------------------------------------------------------
    # Shifts background/base tone to match type; brightens Pokemon tone to white.
    picBG.setSE(delay, "Anim/Saint7", 100, 90) if @battler.wild?
    picBG.moveColor(delay, 15, Color.new(*@type_bg, 180))
    picBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    arrBASES.each do |p|
      p.moveColor(delay, 15, Color.new(*@type_bg, 180))
      p.moveTone(delay, 15, Tone.new(-200, -200, -200))
    end
    picPOKE.moveTone(delay, 15, Tone.new(255, 255, 255, 255))
    #---------------------------------------------------------------------------
    # Zooms out/fades tera icon; tera crystals surround Pokemon and shake.
    picICON.setVisible(delay + 4, true)
    picICON.moveOpacity(delay + 4, 8, 255)
    picICON.moveZoom(delay + 8, 16, 200)
    picICON.moveOpacity(delay + 8, 16, 0)
    delay = picPOKE.totalDuration
    arrCRYSTALS.reverse.each_with_index do |p, i|
      p[0].setVisible(delay, true)
      p[0].setSE(delay, "Anim/Sword2", 100, 80)
      p[0].moveZoom(delay, 2, 100)
      delay = p[0].totalDuration
      delay += (i == 0) ? 4 : 1
    end
    delay = arrCRYSTALS.first[0].totalDuration
    picPOKE.setVisible(delay, false)
    t = 0.5
    16.times do |i|
      arrCRYSTALS.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x + 2, @pictureSprites[s].y) }
      arrCRYSTALS.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x - 2, @pictureSprites[s].y) }
      delay = arrCRYSTALS.first[0].totalDuration
    end
    #---------------------------------------------------------------------------
    # White screen flash; hides crystal sprites; shows terastallized Pokemon.
    picFADE.setColor(delay - 8, Color.white)
    picFADE.moveOpacity(delay - 8, 12, 255)
    delay = picFADE.totalDuration
    arrITEM.each { |p, s| p.setVisible(delay, false) } if !@battler.wild?
    arrCRYSTALS.each { |p, s| p.setVisible(delay, false) }
    picICON.setVisible(delay, false)
    picSHINE.setVisible(delay, true)
    arrPOKE.each { |p, s| p.setVisible(delay, true) }
    picFADE.moveOpacity(delay, 6, 0)
    picFADE.setColor(delay + 6, Color.black)
    #---------------------------------------------------------------------------
    # Crystal break animation, followed by rainbow pulse.
    picSHINE2.setVisible(delay + 1, true)
    arrBREAK.each_with_index do |p, i|
      p[0].setVisible(delay + 1, true)
      p[0].setSE(delay, "Anim/Earth1", 100, 80) if i == 0
      p[0].moveXY(delay + 1, 4, p[1], p[2])
      p[0].setVisible(delay + 5, false)
    end
    delay = picFADE.totalDuration
    picOVERLAY.setVisible(delay, true)
    picOVERLAY.moveOpacity(delay, 5, 0)
    picPULSE.setVisible(delay, true)
    picPULSE.setSE(delay, "Anim/Ice5", 100, 80)
    picPULSE.moveZoom(delay, 5, 1000)
    picPULSE.moveOpacity(delay + 2, 5, 0)
    #---------------------------------------------------------------------------
    # Shakes Pokemon; plays cry; flashes transition. Fades out.
    6.times do |i|
      if i > 0
        arrPOKE.each { |p, s| p.moveXY(delay, t, @pictureSprites[s].x, @pictureSprites[s].y + 2) }
        arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y - 2) }
        picOVERLAY.moveOpacity(delay, 2, 160)
        picSHINE.moveOpacity(delay, 2, 160)
        picSHINE2.moveOpacity(delay, 2, 160)
        delay = picOVERLAY.totalDuration
      else
        delay = picPULSE.totalDuration
        picOVERLAY.setOpacity(delay, 255)
        picSHINE.setOpacity(delay, 255)
        picSHINE2.setOpacity(delay, 255)
        picPOKE.setSE(delay, @cry_file) if @cry_file
      end
      picOVERLAY.moveOpacity(delay + t, 2, 240)
      picSHINE.moveOpacity(delay + t, 2, 240)
      picSHINE2.moveOpacity(delay + t, 2, 240)
    end
    picOVERLAY.moveOpacity(delay, 4, 0)
    picSHINE.moveOpacity(delay, 4, 0)
    picSHINE2.moveOpacity(delay, 4, 0)
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbShowTerastallize(idxBattler)
    teraAnim = Animation::BattlerTerastallize.new(@sprites, @viewport, idxBattler, @battle)
    loop do
      if Input.press?(Input::ACTION)
        pbPlayCancelSE
        break 
      end
      teraAnim.update
      pbUpdate
      break if teraAnim.animDone?
    end
    teraAnim.dispose
  end
end


#===============================================================================
# Tera revert animation.
#===============================================================================
class Battle::Scene::Animation::RevertTera < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle, teraBreak)
    @battle = battle
    @index = idxBattler
    @teraBreak = teraBreak
    super(sprites, viewport)
  end

  def createProcesses
    delay = 0
    if @teraBreak
      xpos = @sprites["pokemon_#{@index}"].x
      ypos = @sprites["pokemon_#{@index}"].y
      path = Settings::DELUXE_GRAPHICS_PATH + "Tera/crystal_4"
      arrBREAK = dxSetParticlesRect(path, delay, 154, 166, 100, false, false, @index)
      battler = addSprite(@sprites["pokemon_#{@index}"], PictureOrigin::BOTTOM)
      t = 0.5
      8.times do |i|
        battler.moveXY(delay, t, xpos + 4, ypos)
        battler.moveXY(delay + t, t, xpos - 4, ypos)
        delay = battler.totalDuration
      end
      arrBREAK.each_with_index do |p, i|
        p[0].setVisible(delay + 1, true)
        p[0].setSE(delay, "Anim/Crash", 100, 80) if i == 0
        p[0].moveXY(delay + 1, 6, p[1], p[2])
        p[0].setVisible(delay + 5, false)
      end
    end
    revertBattlefield(@battle, delay)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbRevertTera(idxBattler, teraBreak = false)
    reversionAnim = Animation::RevertTera.new(@sprites, @viewport, idxBattler, @battle, teraBreak)
    loop do
      reversionAnim.update
      pbUpdate
      break if reversionAnim.animDone?
    end
    reversionAnim.dispose
  end
end


#===============================================================================
# Tera Burst animation.
#===============================================================================
class Battle::Scene::Animation::TeraBurst < Battle::Scene::Animation
  def initialize(sprites, viewport, battle, idxBattler)
    @index = idxBattler
    @battle = battle
    super(sprites, viewport)
  end

  def createProcesses
    return if !@sprites["pokemon_#{@index}"]
    delay = 0
    xpos  = @sprites["pokemon_#{@index}"].x
    ypos  = @sprites["pokemon_#{@index}"].y
    zpos  = @sprites["pokemon_#{@index}"].z
    color = @sprites["pokemon_#{@index}"].color
    battler = addSprite(@sprites["pokemon_#{@index}"], PictureOrigin::BOTTOM)
    path = Settings::DELUXE_GRAPHICS_PATH + "Tera/pulse"
    burst = addNewSprite(xpos, ypos - 60, path, PictureOrigin::CENTER)
    burst.setColor(delay, color)
    burst.setZoom(delay, 0)
    burst.setZ(delay, zpos)
    t = 0.5
    8.times do |i|
	  darkenBattlefield(@battle, delay, @index) if i == 0
      battler.moveXY(delay, t, xpos + 4, ypos)
      battler.moveXY(delay + t, t, xpos - 4, ypos)
      battler.setSE(delay + t, "Anim/Ice5", 100, 80) if i == 0
      delay = battler.totalDuration
    end
    revertBattlefield(@battle, delay)
    burst.moveZoom(delay, 5, 800)
    battler.moveColor(1, delay, Color.new(255, 255, 255, 248))
    battler.setXY(delay, xpos, ypos)
    battler.moveColor(delay, 4, color)
  end
end

#-------------------------------------------------------------------------------
# Calls the animation.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbTeraBurst(idxBattler)
    burstAnim = Animation::TeraBurst.new(@sprites, @viewport, @battle, idxBattler)
    loop do
      burstAnim.update
      pbUpdate
      break if burstAnim.animDone?
    end
    burstAnim.dispose
  end
end