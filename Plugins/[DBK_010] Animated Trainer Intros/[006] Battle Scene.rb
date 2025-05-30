#===============================================================================
# Additions to the Battle::Scene class.
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Rewritten to set new trainer bitmaps for front sprites.
  #-----------------------------------------------------------------------------
  def pbCreateTrainerFrontSprite(idxTrainer, trainerType, numTrainers = 1)
    trainer = @battle.opponent[idxTrainer]
    2.times do |i|
      trSprite = TrainerSprite.new(@viewport, numTrainers, idxTrainer, @animations)
      trSprite.setTrainerBitmap(trainer, trainerType, (i == 1))
      sprite = (i == 0) ? "trainer_#{idxTrainer + 1}" : "trshadow_#{idxTrainer + 1}"
      @sprites[sprite] = trSprite
      @sprites[sprite].visible = (i == 1) ? trSprite.shows_shadow? : true
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to set hues on trainer back sprites.
  #-----------------------------------------------------------------------------
  alias animtrainer_pbCreateTrainerBackSprite pbCreateTrainerBackSprite
  def pbCreateTrainerBackSprite(idxTrainer, trainerType, numTrainers = 1)
    animtrainer_pbCreateTrainerBackSprite(idxTrainer, trainerType, numTrainers)
    hue = GameData::TrainerType.get(trainerType).trainer_sprite_hue
    @sprites["player_#{idxTrainer + 1}"].bitmap.hue_change(hue) if hue != 0
  end
  
  #-----------------------------------------------------------------------------
  # Utility for animating all trainer intros at the start of battle.
  #-----------------------------------------------------------------------------
  def pbAnimateTrainerIntros
    return if !@battle.opponent
    idxTrainers = []
    @battle.opponent.length.times do |i|
      sprite = @sprites["trainer_#{i + 1}"]
      next if !sprite || !sprite.visible || !sprite.bitmap || sprite.finished?
      idxTrainers.push(i + 1)
    end
    return if idxTrainers.empty?
    anims_done = 0
    loop do 
      pbUpdate
      idxTrainers.each do |i|
        next if @sprites["trainer_#{i}"].finished?
        @sprites["trainer_#{i}"]&.play
        @sprites["trshadow_#{i}"]&.play
        anims_done += 1 if @sprites["trainer_#{i}"].finished?
      end
      break if anims_done == idxTrainers.length
    end
  end
  
  #---------------------------------------------------------------------------
  # Midbattle speech utilities.
  #---------------------------------------------------------------------------
  def pbShowAnimatedSpeaker(idxBattler, idxTarget = nil, reversed = false, params = nil)
    params = pbConvertBattlerIndex(idxBattler, idxTarget, params)
    params = idxBattler if !params
    pbUpdateSpeaker(*params)
    return if !@showSpeaker
    speaker = @sprites["midbattle_speaker"]
    if reversed
      speaker.to_last_frame
      speaker.reversed = true
    else
      speaker.to_first_frame
    end
    appearAnim = Animation::SlideSpriteAppear.new(@sprites, @viewport, @battle)
    @animations.push(appearAnim)
    while inPartyAnimation?
      pbUpdate
    end
    loop do 
      pbUpdate
      break if speaker.finished?
      speaker&.play
    end
  end
  
  def pbHideAnimatedSpeaker(reversed = false)
    speaker = @sprites["midbattle_speaker"]
	return if !speaker.visible
    if reversed == :Reversed
      speaker.to_last_frame
      speaker.reversed = true
    else
      speaker.to_first_frame
    end
    pbHideSpeakerWindows
    loop do 
      pbUpdate
      break if speaker.finished?
      speaker&.play
    end
    hideAnim = Animation::SlideSpriteDisappear.new(@sprites, @viewport, @battle, @battle.decision > 0)
    @animations.push(hideAnim)
    while inPartyAnimation?
      pbUpdate
    end
  end
end

#===============================================================================
# Edits the battle intro animation to consider trainer shadows.
#===============================================================================
class Battle::Scene::Animation::Intro < Battle::Scene::Animation
  def createProcesses
    appearTime = 20
    if @sprites["battle_bg2"]
      makeSlideSprite("battle_bg", 0.5, appearTime)
      makeSlideSprite("battle_bg2", 0.5, appearTime)
    end
    makeSlideSprite("base_0", 1, appearTime, PictureOrigin::BOTTOM)
    makeSlideSprite("base_1", -1, appearTime, PictureOrigin::CENTER)
    @battle.player.each_with_index do |_p, i|
      makeSlideSprite("player_#{i + 1}", 1, appearTime, PictureOrigin::BOTTOM)
    end
    if @battle.trainerBattle?
      @battle.opponent.each_with_index do |_p, i|
        makeSlideSprite("trainer_#{i + 1}", -1, appearTime, PictureOrigin::BOTTOM)
        makeSlideSprite("trshadow_#{i + 1}", -1, appearTime, PictureOrigin::BOTTOM)
      end
    else
      @battle.pbParty(1).each_with_index do |_pkmn, i|
        idxBattler = (2 * i) + 1
        makeSlideSprite("pokemon_#{idxBattler}", -1, appearTime, PictureOrigin::BOTTOM)
      end
    end
    @battle.battlers.length.times do |i|
      makeSlideSprite("shadow_#{i}", (i.even?) ? 1 : -1, appearTime, PictureOrigin::CENTER)
    end
    blackScreen = addNewSprite(0, 0, "Graphics/Battle animations/black_screen")
    blackScreen.setZ(0, 999)
    blackScreen.moveOpacity(0, 8, 0)
    blackBar = addNewSprite(@sprites["cmdBar_bg"].x, @sprites["cmdBar_bg"].y,
                            "Graphics/Battle animations/black_bar")
    blackBar.setZ(0, 998)
    blackBar.moveOpacity(appearTime * 3 / 4, appearTime / 4, 0)
  end
end

#===============================================================================
# Edits the animation that slides trainers on screen to consider trainer shadows.
#===============================================================================
class Battle::Scene::Animation::TrainerAppear < Battle::Scene::Animation
  def createProcesses
    delay = 0
    if @idxTrainer > 0 && @sprites["trainer_#{@idxTrainer}"].visible
      oldTrainer = addSprite(@sprites["trainer_#{@idxTrainer}"], PictureOrigin::BOTTOM)
      oldTrainer.moveDelta(delay, 8, Graphics.width / 4, 0)
      oldTrainer.setVisible(delay + 8, false)
      oldShadow = addSprite(@sprites["trshadow_#{@idxTrainer}"], PictureOrigin::BOTTOM)
      oldShadow.moveDelta(delay, 8, Graphics.width / 4, 0)
      oldShadow.setVisible(delay + 8, false)
      delay = oldTrainer.totalDuration
    end
    if @sprites["trainer_#{@idxTrainer + 1}"]
      trainerX, trainerY = Battle::Scene.pbTrainerPosition(1)
      trainerX += 64 + (Graphics.width / 4)
      newTrainer = addSprite(@sprites["trainer_#{@idxTrainer + 1}"], PictureOrigin::BOTTOM)
      newTrainer.setVisible(delay, true)
      newTrainer.setXY(delay, trainerX, trainerY)
      newTrainer.moveDelta(delay, 8, -Graphics.width / 4, 0)
      newShadow = addSprite(@sprites["trshadow_#{@idxTrainer + 1}"], PictureOrigin::BOTTOM)
      trainer = @sprites["trainer_#{@idxTrainer + 1}"].outfit
      trData = GameData::TrainerType.get(trainer)
      newShadow.setVisible(delay, trData.shows_shadow?)
      shadowPos = trData.shadow_xy
      newShadow.setXY(delay, trainerX + shadowPos[0], trainerY + shadowPos[1])
      newShadow.moveDelta(delay, 8, -Graphics.width / 4, 0)
    end
  end
end

#===============================================================================
# Edits the animation that slides trainers off screen to consider trainer shadows.
#===============================================================================
class Battle::Scene::Animation::TrainerFade < Battle::Scene::Animation
  def createProcesses
    i = 1
    while @sprites["trainer_#{i}"]
      trSprite = @sprites["trainer_#{i}"]
      shaSprite = @sprites["trshadow_#{i}"]
      i += 1
      next if !trSprite.visible || trSprite.x > Graphics.width
      trainer = addSprite(trSprite, PictureOrigin::BOTTOM)
      trainer.moveDelta(0, 16, Graphics.width / 2, 0)
      trainer.setVisible(16, false)
      next if !shaSprite.visible || shaSprite.x > Graphics.width
      shadow = addSprite(shaSprite, PictureOrigin::BOTTOM)
      shadow.moveDelta(0, 16, Graphics.width / 2, 0)
      shadow.setVisible(16, false)
    end
    delay = 3
    if @sprites["partyBar_1"]&.visible
      partyBar = addSprite(@sprites["partyBar_1"])
      partyBar.moveDelta(delay, 16, Graphics.width / 4, 0) if @fullAnim
      partyBar.moveOpacity(delay, 12, 0)
      partyBar.setVisible(delay + 12, false)
      partyBar.setOpacity(delay + 12, 255)
    end
    Battle::Scene::NUM_BALLS.times do |j|
      next if !@sprites["partyBall_1_#{j}"] || !@sprites["partyBall_1_#{j}"].visible
      partyBall = addSprite(@sprites["partyBall_1_#{j}"])
      partyBall.moveDelta(delay + (2 * j), 16, Graphics.width, 0) if @fullAnim
      partyBall.moveOpacity(delay, 12, 0)
      partyBall.setVisible(delay + 12, false)
      partyBall.setOpacity(delay + 12, 255)
    end
  end
end

#===============================================================================
# Midbattle triggers.
#===============================================================================

#-------------------------------------------------------------------------------
# Slides a new speaker on screen and animates them prior to displaying text.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "setAnimSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    reversed = false
    if params.is_a?(Array) && params.last == :Reversed
      params = params[0..params.length - 2]
      reversed = true
    end
    if !battle.scene.pbInCinematicSpeech?
      battle.scene.pbToggleDataboxes 
      battle.scene.pbToggleBlackBars(true)
    end
    battle.scene.pbHideSpeaker
    battle.scene.pbShowAnimatedSpeaker(idxBattler, idxTarget, reversed, params)
    speaker = battle.scene.pbGetSpeaker
    battle.scene.pbShowSpeakerWindows(speaker)
    PBDebug.log("     'setAnimSpeaker': 用动画展示新的发言角色 (#{speaker.name})")
  }
)

#-------------------------------------------------------------------------------
# Animates a speaker prior to sliding them off screen.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "hideAnimSpeaker",
  proc { |battle, idxBattler, idxTarget, params|
    next if !battle.scene.sprites["midbattle_speaker"].visible
    battle.scene.pbHideAnimatedSpeaker(params)
    PBDebug.log("     'endSpeech': 动画完成后隐藏当前发言人")
  }
)