#===============================================================================
# Adds a newly called battler to the battle scene.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Prepares the battle scene for the introduction of a new battler.
  #-----------------------------------------------------------------------------
  def pbPrepNewBattler(idxBattler)
    pbRefresh
    battler = @battle.battlers[idxBattler]
    addNewBattler = !@sprites["dataBox_#{idxBattler}"]
    if addNewBattler
      @sprites["targetWindow"].dispose
      @sprites["targetWindow"] = TargetMenu.new(@viewport, 200, @battle.sideSizes)
      @sprites["targetWindow"].visible = false
      pbCreatePokemonSprite(idxBattler)
      if defined?(pbHideInfoUI)
        @sprites["info_icon#{idxBattler}"] = PokemonIconSprite.new(battler.pokemon, @viewport)
        @sprites["info_icon#{idxBattler}"].setOffset(PictureOrigin::CENTER)
        @sprites["info_icon#{idxBattler}"].visible = false
        @sprites["info_icon#{idxBattler}"].z = 300
        pbAddSpriteOutline(["info_icon#{idxBattler}", @viewport, battler.pokemon, PictureOrigin::CENTER])
      end
    else
      @sprites["pokemon_#{idxBattler}"].dispose
      @sprites["shadow_#{idxBattler}"].dispose
      pbCreatePokemonSprite(idxBattler)
    end
    @sprites["pokemon_#{idxBattler}"].visible = false
    @sprites["shadow_#{idxBattler}"].visible = false
    sideSize = @battle.pbSideSize(idxBattler)
    @battle.allSameSideBattlers(idxBattler).each do |b|
      if addNewBattler
        @sprites["dataBox_#{b.index}"]&.dispose
        @sprites["dataBox_#{b.index}"] = PokemonDataBox.new(b, sideSize, @viewport)
      else
        @sprites["dataBox_#{b.index}"].battler = b
        @sprites["dataBox_#{b.index}"].visible = @sprites["pokemon_#{b.index}"].visible
        @sprites["dataBox_#{b.index}"].refresh
      end
      @sprites["dataBox_#{b.index}"].update
    end
    return addNewBattler
  end

  #-----------------------------------------------------------------------------
  # Adds a new wild Pokemon via SOS call.
  #-----------------------------------------------------------------------------
  def pbSOSJoin(idxBattler)
    addNewBattler = pbPrepNewBattler(idxBattler)
    battler = @battle.battlers[idxBattler]
    pbChangePokemon(idxBattler, battler.displayPokemon)
    sosAnim = Animation::SOSJoin.new(@sprites, @viewport, @battle, battler.index, addNewBattler)
    @animations.push(sosAnim)
    while inPartyAnimation?
      pbUpdate
    end
    if @battle.showAnims && battler.shiny?
      pbCommonAnimation("Shiny", battler)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Adds a new trainer.
  #-----------------------------------------------------------------------------
  def pbTrainerJoin(idxBattler, idxTrainer)
    addNewBattler = pbPrepNewBattler(idxBattler)
    battler = @battle.battlers[idxBattler]
    trainer = @battle.opponent[idxTrainer]
    id = "trainer_#{idxTrainer + 1}"
    if @sprites[id]
      trainerFile = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
      spriteX, spriteY = Battle::Scene.pbTrainerPosition(1, idxTrainer, @battle.opponent.length)
      @sprites[id].setBitmap(trainerFile)
      @sprites[id].x = spriteX
      @sprites[id].y = spriteY
      @sprites[id].ox = @sprites[id].src_rect.width / 2
      @sprites[id].oy = @sprites[id].bitmap.height
    else
      pbCreateTrainerFrontSprite(idxTrainer, trainer.trainer_type, @battle.opponent.length)
    end
    if @battle.launcherBattle?
      @sprites["launcherBar_1_#{idxTrainer}"] = WonderLauncherPointsBar.new(1, idxTrainer, trainer, @viewport)
    end
    joinAnim = Animation::TrainerJoin.new(@sprites, @viewport, @battle, battler.index, idxTrainer + 1, addNewBattler)
    @animations.push(joinAnim)
    while inPartyAnimation?
      pbUpdate
    end
    pbDisplayPausedMessage(_INTL("{1} joined the battle!", trainer.full_name))
    pbDisplayMessage(_INTL("{1} sent out {2}!", trainer.full_name, battler.name))
    @battle.pbSendOut([[idxBattler, battler.pokemon]])
  end
  
  #-----------------------------------------------------------------------------
  # Used to quickly add a foe via the battle debug menu.
  #-----------------------------------------------------------------------------
  def pbQuickJoin(idxBattler, idxTrainer = nil)
    addNewBattler = pbPrepNewBattler(idxBattler)
    battler = @battle.battlers[idxBattler]
    @battle.battlers.each do |b|
      next if !b || b.opposes?(idxBattler)
      batSprite = @sprites["pokemon_#{b.index}"]
      shaSprite = @sprites["shadow_#{b.index}"]
      boxSprite = @sprites["dataBox_#{b.index}"]
      if b.index == idxBattler
        batSprite.visible = true
        shaSprite.visible = true
        boxSprite.visible = true
      else
        batSprite.dispose
        shaSprite.dispose
        pbCreatePokemonSprite(b.index)
        @sprites["pokemon_#{b.index}"].visible = true
        @sprites["shadow_#{b.index}"].visible = true
        boxSprite.visible = true if !b.fainted?
      end
      pbChangePokemon(b.index, b.displayPokemon)
    end
    if idxTrainer
      trainer = @battle.opponent[idxTrainer]
      id = "trainer_#{idxTrainer + 1}"
      if @sprites[id]
        trainerFile = GameData::TrainerType.front_sprite_filename(trainer.trainer_type)
        @sprites[id].setBitmap(trainerFile)
      else
        pbCreateTrainerFrontSprite(idxTrainer, trainer.trainer_type, @battle.opponent.length)
        @sprites[id].x = @sprites["trainer_1"].x
      end
      if @battle.launcherBattle?
        @sprites["launcherBar_1_#{idxTrainer}"] = WonderLauncherPointsBar.new(1, idxTrainer, trainer, @viewport)
      end
    end
  end
end


#===============================================================================
# Allows the size of side to be edited mid-battle.
#===============================================================================
class Battle::Scene::BattlerSprite < RPG::Sprite
  attr_accessor :sideSize
end

class Battle::Scene::BattlerShadowSprite < RPG::Sprite
  attr_accessor :sideSize
end

#===============================================================================
# Animation used for new wild Pokemon joining the battle.
#===============================================================================
class Battle::Scene::Animation::SOSJoin < Battle::Scene::Animation
  def initialize(sprites, viewport, battle, idxSOS, addNewBattler)
    @battle = battle
    @idxSOS = idxSOS
    @addNewBattler = addNewBattler
    @sideSize = @battle.pbSideSize(idxSOS)
    super(sprites, viewport)
  end
  
  def pbGetShadowCoords(b)
    p = Battle::Scene.pbBattlerPosition(b.index, @sideSize)
    m = GameData::SpeciesMetrics.get_species_form(b.species, b.form)
    newX = p[0] + m.shadow_x * 2
    newY = p[1]
    newZ = 3
    return newX, newY, newZ
  end
  
  def pbGetBattlerCoords(b)
    p = Battle::Scene.pbBattlerPosition(b.index, @sideSize)
    m = GameData::SpeciesMetrics.get_species_form(b.species, b.form)
    newX = p[0] + m.front_sprite[0] * 2
    newY = p[1] + m.front_sprite[1] * 2
    newY -= m.front_sprite_altitude * 2
    newZ = 50 - (5 * (b.index + 1) / 2)
    return newX, newY, newZ
  end
 
  def createProcesses
    delay = 0
    @battle.battlers.each do |b|
      next if !b || b.opposes?(@idxSOS)
      batSprite = @sprites["pokemon_#{b.index}"]
      shaSprite = @sprites["shadow_#{b.index}"]
      boxSprite = @sprites["dataBox_#{b.index}"]
      if b.index == @idxSOS
        shaSprite.visible = false
        shadow = addSprite(shaSprite, PictureOrigin::CENTER)
        shadow.setOpacity(delay, 0)
        shadow.setVisible(delay, true)
        shadow.moveOpacity(delay, 4, 255)
        battler = addSprite(batSprite, PictureOrigin::BOTTOM)
        battler.setTone(delay, Tone.new(-196, -196, -196, -196))
        battler.setOpacity(delay, 0)
        battler.setVisible(delay, true)
        battler.moveOpacity(delay, 4, 255)
        battler.moveTone(delay + 4, 10, Tone.new(0, 0, 0, 0), [batSprite,:pbPlayIntroAnimation])
        dir = (b.index.even?) ? 1 : -1
        box = addSprite(boxSprite)
        box.setDelta(delay, dir * Graphics.width / 2, 0)
        box.setVisible(delay, true)
        box.moveDelta(delay, 8, -dir * Graphics.width / 2, 0)
      else
        x, y, z = pbGetShadowCoords(b)
        shadow = addSprite(shaSprite, PictureOrigin::CENTER)	
        shadow.setZ(delay, z)
        shadow.moveXY(delay, 4, x, y)
        x, y, z = pbGetBattlerCoords(b)
        battler = addSprite(batSprite, PictureOrigin::BOTTOM)	
        battler.setZ(delay, z)
        battler.moveXY(delay, 4, x, y)
        if @addNewBattler
          dir = (b.index.even?) ? 1 : -1
          box = addSprite(boxSprite)
          box.setDelta(delay, dir * Graphics.width / 2, 0)
          box.setVisible(delay, true) if !b.fainted?
          box.moveDelta(delay, 8, -dir * Graphics.width / 2, 0)
        else
          box = addSprite(boxSprite)
          box.setVisible(delay, true) if !b.fainted?
        end
      end
      delay += 1
    end
  end
end


#===============================================================================
# Animation used for a new trainer joining the battle.
#===============================================================================
class Battle::Scene::Animation::TrainerJoin < Battle::Scene::Animation
  def initialize(sprites, viewport, battle, idxSOS, idxTrainer, addNewBattler)
    @battle = battle
    @idxSOS = idxSOS
    @idxTrainer = idxTrainer
    @addNewBattler = addNewBattler
    @sideSize = @battle.pbSideSize(idxSOS)
    super(sprites, viewport)
  end
 
  def createProcesses
    delay = 0
    @battle.battlers.each do |b|
      next if !b || b.opposes?(@idxSOS) || b.index == @idxSOS
      batSprite = @sprites["pokemon_#{b.index}"]
      shaSprite = @sprites["shadow_#{b.index}"]
      boxSprite = @sprites["dataBox_#{b.index}"]
      battler = addSprite(batSprite, PictureOrigin::BOTTOM)
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      batSprite.sideSize = @sideSize
      shaSprite.sideSize = @sideSize
      batSprite.pbSetPosition
      shaSprite.pbSetPosition
      battler.moveXY(delay, 4, batSprite.x, batSprite.y)
      shadow.moveXY(delay, 4, shaSprite.x, shaSprite.y)
      if @addNewBattler
        dir = (b.index.even?) ? 1 : -1
        box = addSprite(boxSprite)
        box.setDelta(delay, dir * Graphics.width / 2, 0)
        box.setVisible(delay, true) if !b.fainted?
        box.moveDelta(delay, 8, -dir * Graphics.width / 2, 0)
      else
        box = addSprite(boxSprite)
        box.setVisible(delay, true) if !b.fainted?
      end
      delay += 1
    end
    trSprite = @sprites["trainer_#{@idxTrainer}"]
    trSprite.visible = false
    trainer = addSprite(trSprite, PictureOrigin::BOTTOM)
    trainer.setOpacity(delay, 0)
    trainer.setTone(delay, Tone.new(-196, -196, -196, -196))
    trainer.setVisible(delay, true)
    trainer.moveOpacity(delay, 4, 255)
    trainer.moveTone(delay + 4, 10, Tone.new(0, 0, 0, 0))
  end
end