#===============================================================================
# Utility for setting up Dynamax Pokemon sprite for animations.
#===============================================================================
class Battle::Scene::Animation
  def dynamaxSpriteWithOutline(poke, delay, x, y, mirror = false, color = Color.white)
    picturePOKE = []
    for i in [ [2, 0], [-2, 0], [0, 2], [0, -2], [2, 2], [-2, -2], [2, -2], [-2, 2], [0, 0] ]
      outline = addPokeSprite(poke, false, PictureOrigin::BOTTOM)
      outline.setVisible(delay, false)
      sprite = @pictureEx.length - 1
      @pictureSprites[sprite].mirror = mirror
      @pictureSprites[sprite].x = x + i[0]
      @pictureSprites[sprite].y = y + i[1]
      @pictureSprites[sprite].ox = @pictureSprites[sprite].bitmap.width / 2
      @pictureSprites[sprite].oy = @pictureSprites[sprite].bitmap.height
      @pictureSprites[sprite].z = 999
      case poke
      when Pokemon
        poke.species_data.apply_dynamax_metrics_to_sprite(@pictureSprites[sprite], 1)
        @pictureSprites[sprite].set_dynamax_pattern(pkmn.species_data.id, true)
      when Hash
        species_data = GameData::Species.get_species_form(poke[:species], poke[:form])
        data = [species_data.species, species_data.form]
        data.push(poke[:gender] == 1) if PluginManager.installed?("[DBK] Animated Pokémon System")
        metrics_data = GameData::SpeciesMetrics.get_species_form(*data)
        metrics_data.apply_dynamax_metrics_to_sprite(@pictureSprites[sprite], 1)
        @pictureSprites[sprite].set_dynamax_pattern(species_data.id, true)
      end
      outline.setXY(delay, @pictureSprites[sprite].x, @pictureSprites[sprite].y)
      outline.setZ(delay, @pictureSprites[sprite].z)
      outline.setColor(delay, color) if i != [0, 0]
      picturePOKE.push([outline, sprite])
    end
    return picturePOKE
  end
end

#===============================================================================
# Battle animation for triggering Dynamax. (Trainer's Pokemon)
#===============================================================================
class Battle::Scene::Animation::BattlerDynamax < Battle::Scene::Animation
  #-----------------------------------------------------------------------------
  # Initializes data used for the animation.
  #-----------------------------------------------------------------------------
  def initialize(sprites, viewport, idxBattler, battle)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    setPokemonSpriteData
    #---------------------------------------------------------------------------
    # Gets trainer data from battler index.
    items = []
    trainer_item = :DYNAMAXBAND
    trainer = @battle.pbGetOwnerFromBattlerIndex(idxBattler)
    @trainer_file = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
    GameData::Item.each { |item| items.push(item.id) if item.has_flag?("DynamaxBand") }
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
    #---------------------------------------------------------------------------
    # Gets background and animation data.
    @path = Settings::DELUXE_GRAPHICS_PATH
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
    super(sprites, viewport)
  end
  
  #-----------------------------------------------------------------------------
  # Used to determine all Pokemon-related sprites for the animation.
  #-----------------------------------------------------------------------------
  def setPokemonSpriteData
    pkmn = @battler.visiblePokemon
    form = pkmn.getUndynamaxForm
    @pkmn = {
      :pokemon => pkmn,
      :species => pkmn.species,
      :gender  => pkmn.gender,
      :form    => form,
      :shiny   => pkmn.shiny?,
      :shadow  => pkmn.shadowPokemon?,
      :hue     => pkmn.super_shiny_hue
    }
    if @battler.gmax_factor?
      form = pkmn.form        if pkmn.gmax?
      form = pkmn.getGmaxForm if pkmn.hasGigantamaxForm?
    end
    form = pkmn.form        if pkmn.emax?
    form = pkmn.getEmaxForm if pkmn.hasEternamaxForm?
    @dynamax = @pkmn.clone
    @dynamax[:form] = form
    if pkmn.super_shiny? && PluginManager.installed?("[DBK] Animated Pokémon System")
      metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, form, pkmn.gender == 1)
      @dynamax[:hue] = metrics.sprite_super_hue 
    end
    @shadow_file = GameData::Species.shadow_filename(pkmn.species, form)
    @shadow_file = GameData::Species.convert_shadow_file(@shadow_file, pkmn.species, pkmn.form)
    @cry_file = GameData::Species.cry_filename(pkmn.species, form)
    @ball_file = "Graphics/Battle animations/ball_" + pkmn.poke_ball.to_s
    @calyrex = pkmn.isSpecies?(:CALYREX)
  end
  
  #-----------------------------------------------------------------------------
  # Plays the animation.
  #-----------------------------------------------------------------------------
  def createProcesses
    delay = 0
    center_x, center_y = Graphics.width / 2, Graphics.height / 2
    #---------------------------------------------------------------------------
    # Sets up background.
    bgData = dxSetBackdrop(@path + "Dynamax/bg", @bg_file, delay)
    zoomBG = (pbResolveBitmap(@path + "Dynamax/bg")) ? 1 : 1.5
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up Dynamax shadow.
    shadowData = dxSetSprite(@shadow_file, delay, center_x, center_y * 1.5, PictureOrigin::CENTER, 0, 0)
    picSHADOW, sprSHADOW = shadowData[0], shadowData[1]
    #---------------------------------------------------------------------------
    # Sets up Dynamax Pokemon.
    ypos = Graphics.height / 4 + center_y
    arrPOKE = dynamaxSpriteWithOutline(@dynamax, delay, center_x, ypos, !@opposes)
    dxSetSpotPatterns(@dynamax[:pokemon], @pictureSprites[arrPOKE.last[1]]) if @pkmn[:form] == @dynamax[:form]
    arrPOKE.last[0].setColor(delay, Color.white)
    arrPOKE.each do |p, s|
      p.setZoom(delay, 0)
      p.setOpacity(delay, 0)
    end
    #---------------------------------------------------------------------------
    # Sets up pulse.
    pulseData = dxSetSprite(@path + "pulse", delay, center_x, center_y, PictureOrigin::CENTER, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
    #---------------------------------------------------------------------------
    # Sets up base.
    baseData = dxSetBases(@path + "Dynamax/base", @base_file, delay, center_x, center_y)
    picBASE, sprBASE = baseData[0].first, @pictureEx.length - 1
    picBASE.setOrigin(delay, PictureOrigin::BOTTOM)
    base_x = @pictureSprites[sprBASE].x
    base_y = center_y + @pictureSprites[sprBASE].bitmap.height
    picBASE.setXY(delay, center_x, base_y)
    #---------------------------------------------------------------------------
    # Sets up battler.
    pokeData = dxSetPokemon(@pkmn, delay, !@opposes)
    picPOKE, sprPOKE = pokeData[0], pokeData[1]
    dxSetSpotPatterns(@pkmn[:pokemon], @pictureSprites[sprPOKE])
    #---------------------------------------------------------------------------
    # Sets up trainer
    picTRAINER, sprTRAINER = dxSetSprite(@trainer_file, delay, center_x, center_y, PictureOrigin::BOTTOM)
    offsetX = @pictureSprites[sprTRAINER].bitmap.width / 2
    if @opposes
      @pictureSprites[sprTRAINER].x = Graphics.width + offsetX
    else
      @pictureSprites[sprTRAINER].mirror = true
      @pictureSprites[sprTRAINER].x = -offsetX
    end
    trainer_x = @pictureSprites[sprTRAINER].x
    trainer_y = base_y - (@pictureSprites[sprBASE].bitmap.height / 2) + 4
    picTRAINER.setXY(delay, trainer_x, trainer_y)
    #---------------------------------------------------------------------------
    # Sets up Dynamax Band
    item_y = trainer_y - @pictureSprites[sprTRAINER].bitmap.height
    arrITEM = dxSetSpriteWithOutline(@item_file, delay, center_x, item_y)
    #---------------------------------------------------------------------------
    # Sets Poke Ball.
    ballData = dxSetSprite(@ball_file, delay, 0, 0, PictureOrigin::BOTTOM_LEFT)
    picBALL, sprBALL = ballData[0], ballData[1]
    ball_x = center_x - (@pictureSprites[sprBALL].bitmap.width / 16)
    ball_y = trainer_y + 22
    picBALL.setXY(delay, ball_x, ball_y)
    picBALL.setSrcSize(delay, 32, 64)
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
    picBASE.setVisible(delay, true)
    picPOKE.setVisible(delay, true)
    picBALL.setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveDelta(delay, 6, 0, -38)
    picBUTTON.moveDelta(delay + 36, 6, 0, 38)
    #---------------------------------------------------------------------------
    # Opens Poke Ball; begins recall of Pokemon.
    picPOKE.moveColor(delay, 4, Color.new(31 * 8, 22 * 8, 30 * 8, 255))
    delay = picPOKE.totalDuration
    picPOKE.setSE(delay, "Battle recall")
    picBALL.setName(delay, @ball_file + "_open")
    #---------------------------------------------------------------------------
    # Shrink and move Pokemon sprite to ball; close ball.
    picPOKE.moveZoom(delay, 6, 0)
    picPOKE.moveXY(delay, 6, center_x, ball_y - 38)
    picPOKE.moveZ(delay + 1, 1, 1000)
    picPOKE.setVisible(delay + 6, false)
    delay = picPOKE.totalDuration + 1
    picBALL.setName(delay, @ball_file)
    picBALL.setSrcSize(delay, 32, 64)
    #---------------------------------------------------------------------------
    # Slides trainer on screen; shifts ball over.
    picBALL.moveDelta(delay, 8, ((@opposes) ? -64 : 64), 0)
    picTRAINER.setVisible(delay + 6, true)
    delta_trainer = (@opposes) ? -(center_x + offsetX) : center_x + offsetX
    trainer_x += delta_trainer
    picTRAINER.moveDelta(delay + 6, 12, delta_trainer, 0)
    delay = picTRAINER.totalDuration + 1
    #---------------------------------------------------------------------------
    # Dynamax Band appears with outline; slides upwards.  
    picBALL.setSE(delay, "DX Action")
    arrITEM.each do |p, s| 
      p.setVisible(delay, true)
      p.moveDelta(delay, 15, 0, -20)
      p.moveOpacity(delay, 15, 255)
    end
    delay = arrITEM.last[0].totalDuration + 1
    #---------------------------------------------------------------------------
    # Poke Ball enlarges and changes color.
    picBALL.setSE(delay, "Anim/Psych Up", 100)
    picBALL.moveZoom(delay, 6, 150)
    picBALL.moveDelta(delay, 6, -8, 8)
    picBALL.moveColor(delay, 6, Color.new(255, 51, 153, 180))
    delay = picBALL.totalDuration + 6
    picBALL.setVisible(delay, false)
    arrITEM.each { |p, s| p.setVisible(delay, false) }
    #---------------------------------------------------------------------------
    # Overlay flashes; trainer and base zoom off screen.
    picBG.moveZoom(delay, 6, zoomBG * 150)
    picOVERLAY.setVisible(delay, true)
    picOVERLAY.moveOpacity(delay, 6, 255)
    dir = (@opposes) ? -600 : 600
    picBASE.moveZoom(delay, 6, dir.abs)
    picBASE.moveDelta(delay, 6, dir, dir.abs)
    picBASE.setOpacity(delay + 6, 0)
    picTRAINER.moveZoom(delay, 6, dir.abs)
    picTRAINER.moveDelta(delay, 6, dir, dir.abs - 200)
    picTRAINER.setSE(delay, "Battle throw", 100)
    picTRAINER.setVisible(delay + 6, false)
    delay = picTRAINER.totalDuration
    #---------------------------------------------------------------------------
    # Base reappears to serve as the "landing" spot for Poke Ball.
    bg_x, bg_y = -(Graphics.width / 4), -(Graphics.height / 4)
    picBG.setXY(delay, bg_x, bg_y)
    picBASE.setXY(delay, base_x, base_y)
    picBASE.setZoom(delay, 100)
    picBASE.moveOpacity(delay, 6, 255)
    picOVERLAY.moveOpacity(delay, 6, 0)
    picOVERLAY.setVisible(delay + 4, false)
    delay = picOVERLAY.totalDuration + 20
    #---------------------------------------------------------------------------
    # Poke Ball drops, sinks into base, and shakes screen.
    new_ball_x = ball_x - 8
    new_ball_y = ball_y + 16
    picBALL.setXY(delay, new_ball_x, -32)
    picBALL.setVisible(delay, true)
    delay = picBALL.totalDuration + 2
    4.times do |i|
      t = [4, 4, 3, 2][i]
      d = [1, 2, 4, 8][i]
      delay -= t if i == 0
      if i > 0
        picBG.moveXY(delay, t, bg_x, bg_y - (100 / d))
        picBASE.moveXY(delay, t, base_x, base_y - (100 / d))
        picBALL.moveXY(delay, t, new_ball_x, new_ball_y - (100 / d))
      else
        picBALL.setSrcSize(delay + (2 * t), 32, 40)
        picBALL.setSE(delay + (2 * t), "Anim/Earth1")
      end
      picBG.moveXY(delay + t, t, bg_x, bg_y)
      picBASE.moveXY(delay + t, t, base_x, base_y)
      picBALL.moveXY(delay + t, t, new_ball_x, new_ball_y)
      delay = picBALL.totalDuration
    end
    #---------------------------------------------------------------------------
    # Poke Ball opens.
    delay += 10
    picBASE.moveOpacity(delay, 4, 0)
    arrPOKE.each do |p, s| 
      p.setVisible(delay, true)
      p.setXY(delay, center_x, center_y + 100)
    end
    picBALL.setSE(delay, "Battle recall")
    picBALL.setName(delay, @ball_file + "_open")
    picBALL.setSrcSize(delay, 32, 40)
    picBALL.moveOpacity(delay, 4, 0)
    #---------------------------------------------------------------------------
    # Dynamax Pokemon zooms out of ball; shadow expands along with Pokemon.
    picSHADOW.setVisible(delay, true)
    picSHADOW.moveZoom(delay, 20, 200)
    picSHADOW.moveOpacity(delay, 20, 100)
    arrPOKE.each do |p, s| 
      p.setSE(delay, "Anim/Psych Up", 100, 60)
      p.moveXY(delay, 20, @pictureSprites[s].x, @pictureSprites[s].y)
      p.moveZoom(delay, 20, 150)
      p.moveOpacity(delay + 4, 6, 255)
    end
    #---------------------------------------------------------------------------
    # Background zooms out along with Pokemon; color and tone changes.
    delay += 4
    picBG.moveXY(delay, 20, -4, -4)
    picBG.moveZoom(delay, 20, zoomBG * 100)
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 245) : Color.new(255, 51, 153, 245)
    picBG.moveColor(delay, 20, bg_color)
    picBG.moveTone(delay, 10, Tone.new(100, 100, 100, 100))
    #---------------------------------------------------------------------------
    # Trainer and the base zoom back in from off screen.
    new_base_x = (@opposes) ? base_x + 100 : base_x - 100
    new_base_y = base_y + 50
    base_height = @pictureSprites[sprBASE].bitmap.height
    new_trainer_x = (@opposes) ? trainer_x + 100 : trainer_x - 100
    new_trainer_y = new_base_y - (base_height / 4) + 2
    picBASE.setXY(delay, new_base_x, new_base_y + Graphics.height + base_height)
    picBASE.moveXY(delay, 16, new_base_x, new_base_y)
    picBASE.setZoom(delay, 600)
    picBASE.moveZoom(delay, 16, 50)
    picBASE.moveOpacity(delay, 16, 255)
    picTRAINER.setVisible(delay, true)
    picTRAINER.setXY(delay, new_trainer_x, new_trainer_y + Graphics.height)
    picTRAINER.moveXY(delay, 16, new_trainer_x, new_trainer_y)
    picTRAINER.moveZoom(delay, 16, 50)
    delay = picBG.totalDuration + 4
    #---------------------------------------------------------------------------
    # Changes the tone and color of the background and base. Flashes overlay.
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 80) : Color.new(255, 51, 153, 80)
    picOVERLAY.setOpacity(delay, 255)
    picOVERLAY.setColor(delay, Color.new(255, 51, 153, 200)) if !@calyrex
    picBG.setName(delay, "Graphics/UI/evolution_bg")
    picBG.setZoom(delay, 110)
    picBG.setXY(delay, -25, -19)
    picBG.moveColor(delay, 10, bg_color)
    picBG.moveTone(delay, 10, Tone.new(-200, -200, -200))
    picBASE.moveColor(delay, 10, bg_color)
    picBASE.moveTone(delay, 10, Tone.new(-100, -100, -100))
    #---------------------------------------------------------------------------
    # Shakes screen; plays Pokemon cry while flashing overlay. Fades out.
    delay = picBG.totalDuration + 12
    6.times do |i|
      t = [4, 4, 3, 2, 2, 2][i]
      d = [2, 4, 4, 4, 8, 8][i]
      delay -= t if i == 0
      if i > 0
        picOVERLAY.moveOpacity(delay + 2, t, 240)
        picBG.moveXY(delay, t, -25, -(100 / d))        
        picBASE.moveXY(delay, t, new_base_x, new_base_y - (100 / d))
        picTRAINER.moveXY(delay, t, new_trainer_x, new_trainer_y - (100 / d))
        arrPOKE.each { |p, s| p.moveXY(delay + 2, t, @pictureSprites[s].x, @pictureSprites[s].y - (200 / d)) }
      else
        picOVERLAY.setVisible(delay, true)
        picPULSE.setVisible(delay, true)
        picPULSE.moveZoom(delay, 10, 1000)
        picPULSE.moveOpacity(delay + 2, 10, 0)
        for i in 0...arrPOKE.length
          if arrPOKE[i] == arrPOKE.last
            if @pkmn[:form] != @dynamax[:form]
              arrPOKE[i][0].setSE(delay + (2 * t), @cry_file) if @cry_file
            else
              arrPOKE[i][0].setSE(delay + (2 * t), @cry_file, 100, 60) if @cry_file
            end
            arrPOKE[i][0].setSE(delay + (2 * t), "Anim/Explosion3")
            arrPOKE[i][0].moveColor(delay, 5, Color.new(31 * 8, 22 * 8, 30 * 8, 0))
          else
            outline_color = (@calyrex) ? Color.new(36, 243, 243) : Color.new(250, 57, 96)
            arrPOKE[i][0].moveColor(delay, 5, outline_color)
          end
        end
      end
      picOVERLAY.moveOpacity(delay + t, t, 160)
      picBG.moveXY(delay + t, t, -25, -19)
      picBASE.moveXY(delay + t, t, new_base_x, new_base_y)
      picTRAINER.moveXY(delay + t, t, new_trainer_x, new_trainer_y)
      arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y) }
      delay = arrPOKE.last[0].totalDuration
    end
    picOVERLAY.moveOpacity(delay, 4, 0)
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end


#===============================================================================
# Battle animation for triggering Dynamax. (Wild Pokemon)
#===============================================================================
class Battle::Scene::Animation::BattlerDynamaxWild < Battle::Scene::Animation
  def initialize(sprites, viewport, idxBattler, battle)
    #---------------------------------------------------------------------------
    # Gets Pokemon data from battler index.
    @battle = battle
    @battler = @battle.battlers[idxBattler]
    @opposes = @battle.opposes?(idxBattler)
    setPokemonSpriteData
    #---------------------------------------------------------------------------
    # Gets background and animation data.
    @path = Settings::DELUXE_GRAPHICS_PATH
    backdropFilename, baseFilename = @battle.pbGetBattlefieldFiles
    @bg_file   = "Graphics/Battlebacks/" + backdropFilename + "_bg"
    @base_file = "Graphics/Battlebacks/" + baseFilename + "_base1"
    super(sprites, viewport)
  end
  
  #-----------------------------------------------------------------------------
  # Used to determine all Pokemon-related sprites for the animation.
  #-----------------------------------------------------------------------------
  def setPokemonSpriteData
    pkmn = @battler.visiblePokemon
    form = pkmn.getUndynamaxForm
    @pkmn = {
      :pokemon => pkmn,
      :species => pkmn.species,
      :gender  => pkmn.gender,
      :form    => form,
      :shiny   => pkmn.shiny?,
      :shadow  => pkmn.shadowPokemon?,
      :hue     => pkmn.super_shiny_hue
    }
    if @battler.gmax_factor?
      form = pkmn.form        if pkmn.gmax?
      form = pkmn.getGmaxForm if pkmn.hasGigantamaxForm?
    end
    form = pkmn.form        if pkmn.emax?
    form = pkmn.getEmaxForm if pkmn.hasEternamaxForm?
    @dynamax = @pkmn.clone
    @dynamax[:form] = form
    if pkmn.super_shiny? && PluginManager.installed?("[DBK] Animated Pokémon System")
      metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, form, pkmn.gender == 1)
      @dynamax[:hue] = metrics.sprite_super_hue 
    end
    @shadow_file = GameData::Species.shadow_filename(pkmn.species, form)
    @shadow_file = GameData::Species.convert_shadow_file(@shadow_file, pkmn.species, pkmn.form)
    @cry_file = GameData::Species.cry_filename(pkmn.species, form)
    @calyrex = pkmn.isSpecies?(:CALYREX)
  end
  
  #-----------------------------------------------------------------------------
  # Plays the animation.
  #-----------------------------------------------------------------------------
  def createProcesses
    delay = 0
    center_x, center_y = Graphics.width / 2, Graphics.height / 2
    #---------------------------------------------------------------------------
    # Sets up background.
    bgData = dxSetBackdrop(@path + "Dynamax/bg", @bg_file, delay)
    zoomBG = (pbResolveBitmap(@path + "Dynamax/bg")) ? 1 : 1.5
    picBG, sprBG = bgData[0], bgData[1]
    #---------------------------------------------------------------------------
    # Sets up base.
    baseData = dxSetBases(@path + "Dynamax/base", @base_file, delay, center_x, center_y)
    picBASE, sprBASE = baseData[0].first, @pictureEx.length - 1
    picBASE.setOrigin(delay, PictureOrigin::BOTTOM)
    base_y = center_y + @pictureSprites[sprBASE].bitmap.height + 30
    picBASE.setXY(delay, center_x, base_y)
    #---------------------------------------------------------------------------
    # Sets up Dynamax shadow.
    shadowData = dxSetSprite(@shadow_file, delay, center_x, center_y * 1.5, PictureOrigin::CENTER, 0, 0)
    picSHADOW, sprSHADOW = shadowData[0], shadowData[1]
    #---------------------------------------------------------------------------
    # Sets up overlay.
    overlayData = dxSetOverlay(@path + "burst", delay)
    picOVERLAY, sprOVERLAY = overlayData[0], overlayData[1]
    #---------------------------------------------------------------------------
    # Sets up battler.
    pokeData = dxSetPokemon(@pkmn, delay, !@opposes)
    picPOKE, sprPOKE = pokeData[0], pokeData[1]
    dxSetSpotPatterns(@pkmn[:pokemon], @pictureSprites[sprPOKE])
    @pictureSprites[sprPOKE].y += 30
    picPOKE.setXY(delay, @pictureSprites[sprPOKE].x, @pictureSprites[sprPOKE].y)
    #---------------------------------------------------------------------------
    # Sets up Dynamax Pokemon.
    ypos = Graphics.height / 4 + center_y
    arrPOKE = dynamaxSpriteWithOutline(@dynamax, delay, center_x, ypos, !@opposes)
    dxSetSpotPatterns(@dynamax[:pokemon], @pictureSprites[arrPOKE.last[1]]) if @pkmn[:form] == @dynamax[:form]
    arrPOKE.last[0].setColor(delay, Color.white)
    #---------------------------------------------------------------------------
    # Sets up pulse.
    pulseData = dxSetSprite(@path + "pulse", delay, center_x, center_y, PictureOrigin::CENTER, 100, 50)
    picPULSE, sprPULSE = pulseData[0], pulseData[1]
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
    picBASE.setVisible(delay, true)
    picPOKE.setVisible(delay, true)
    picFADE.moveOpacity(delay, 8, 0)
    delay = picFADE.totalDuration
    picBUTTON.moveXY(delay, 6, 0, Graphics.height - 38)
    picBUTTON.moveXY(delay + 36, 6, 0, Graphics.height)
    #---------------------------------------------------------------------------
    # Changes the tone and color of the background, base and Pokemon.
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 245) : Color.new(255, 51, 153, 245)
    picBG.moveColor(delay, 15, bg_color)
    picBG.moveTone(delay, 15, Tone.new(-200, -200, -200))
    picBASE.moveColor(delay, 15, bg_color)
    picBASE.moveTone(delay, 15, Tone.new(-200, -200, -200))
    picPOKE.moveTone(delay, 15, Tone.new(255, 255, 255, 255))
    delay = picPOKE.totalDuration
    #---------------------------------------------------------------------------
    # Dynamax Pokemon is shown and begins to enlarge along with a shadow.
    picSHADOW.setVisible(delay, true)
    picSHADOW.moveZoom(delay, 20, 200)
    picSHADOW.moveOpacity(delay, 20, 100)
    picBASE.setVisible(delay, false)
    picPOKE.setVisible(delay + 1, false)
    arrPOKE.each do |p, s|
      p.setVisible(delay, true)
      p.setSE(delay, "Anim/Psych Up", 100, 60)
      p.moveZoom(delay, 20, 150)
    end
    delay += 4
    picBG.moveXY(delay, 20, -4, -4)
    picBG.moveZoom(delay, 20, zoomBG * 100)
    delay = picBG.totalDuration + 4
    #---------------------------------------------------------------------------
    # Changes the tone and color of the background. Shows overlay.
    bg_color = (@calyrex) ? Color.new(0, 204, 204, 80) : Color.new(255, 51, 153, 80)
    picOVERLAY.setOpacity(delay, 255)
    picOVERLAY.setColor(delay, Color.new(255, 51, 153, 200)) if !@calyrex
    picBG.setName(delay, "Graphics/UI/evolution_bg")
    picBG.setZoom(delay, 110)
    picBG.setXY(delay, -25, -19)
    picBG.moveColor(delay, 10, bg_color)
    picBG.moveTone(delay, 10, Tone.new(-200, -200, -200))
    #---------------------------------------------------------------------------
    # Shakes screen; plays Pokemon cry while flashing overlay. Fades out.
    delay = picBG.totalDuration + 12
    6.times do |i|
      t = [4, 4, 3, 2, 2, 2][i]
      d = [2, 4, 4, 4, 8, 8][i]
      delay -= t if i == 0
      if i > 0
        picOVERLAY.moveOpacity(delay + 2, t, 240)
        picBG.moveXY(delay, t, -25, -(100 / d))        
        arrPOKE.each { |p, s| p.moveXY(delay + 2, t, @pictureSprites[s].x, @pictureSprites[s].y - (200 / d)) }
      else
        picOVERLAY.setVisible(delay, true)
        picPULSE.setVisible(delay, true)
        picPULSE.moveZoom(delay, 10, 1000)
        picPULSE.moveOpacity(delay + 2, 10, 0)
        for i in 0...arrPOKE.length
          if arrPOKE[i] == arrPOKE.last
            if @pkmn[:form] != @dynamax[:form]
              arrPOKE[i][0].setSE(delay + (2 * t), @cry_file) if @cry_file
            else
              arrPOKE[i][0].setSE(delay + (2 * t), @cry_file, 100, 60) if @cry_file
            end
            arrPOKE[i][0].setSE(delay + (2 * t), "Anim/Explosion3")
            arrPOKE[i][0].moveColor(delay, 5, Color.new(31 * 8, 22 * 8, 30 * 8, 0))
          else
            outline_color = (@calyrex) ? Color.new(36, 243, 243) : Color.new(250, 57, 96)
            arrPOKE[i][0].moveColor(delay, 5, outline_color)
          end
        end
      end
      picOVERLAY.moveOpacity(delay + t, t, 160)
      picBG.moveXY(delay + t, t, -25, -19)
      arrPOKE.each { |p, s| p.moveXY(delay + t, t, @pictureSprites[s].x, @pictureSprites[s].y) }
      delay = arrPOKE.last[0].totalDuration
    end
    picOVERLAY.moveOpacity(delay, 4, 0)
    picFADE.moveOpacity(delay + 20, 8, 255)
  end
end


#-------------------------------------------------------------------------------
# Calls the animations.
#-------------------------------------------------------------------------------
class Battle::Scene
  def pbShowDynamax(idxBattler)
    battler = @battle.battlers[idxBattler]
    if battler.wild?
      dynamaxAnim = Animation::BattlerDynamaxWild.new(@sprites, @viewport, idxBattler, @battle)
    else
      dynamaxAnim = Animation::BattlerDynamax.new(@sprites, @viewport, idxBattler, @battle)
    end
    loop do
      if Input.press?(Input::ACTION)
        pbPlayCancelSE
        break 
      end
      dynamaxAnim.update
      pbUpdate
      break if dynamaxAnim.animDone?
    end
    dynamaxAnim.dispose
  end
  
  def pbDynamaxSendOut(idxBattler, xpos, ypos)
    @sprites["pokemon_#{idxBattler}"].x = xpos
    @sprites["pokemon_#{idxBattler}"].y = ypos
    battler = @battle.battlers[idxBattler]
    if battler.opposes?
      sendOutAnim = Animation::PokeballTrainerSendOut.new(@sprites, @viewport, 0, battler, false, 0)
    else
      sendOutAnim = Animation::PokeballPlayerSendOut.new(@sprites, @viewport, 0, battler, false, 0)
    end
    dataBoxAnim = Animation::DataBoxAppear.new(@sprites, @viewport, idxBattler)
    loop do
      sendOutAnim.update
      dataBoxAnim.update if sendOutAnim.animDone?
      pbUpdate
      break if dataBoxAnim.animDone?
    end
    sendOutAnim.dispose
    dataBoxAnim.dispose
    pbRefresh
    pbRevertBattlerStart(idxBattler)
    battler.makeDynamax
    pbRevertBattlerEnd
  end
end