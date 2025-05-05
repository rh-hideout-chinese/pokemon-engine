################################################################################
#
# Pokemon sprites (Battle)
#
################################################################################

class Battle::Scene::BattlerSprite < RPG::Sprite
  attr_accessor :substitute, :speed, :reversed, :hue
  
  #-----------------------------------------------------------------------------
  # General sprite utilities.
  #-----------------------------------------------------------------------------
  def animated?
    return !@_iconBitmap.nil? && @_iconBitmap.is_a?(DeluxeBitmapWrapper)
  end
  
  def static?
    return true if !animated?
    return @_iconBitmap.length > 1
  end
  
  def iconBitmap; return @_iconBitmap; end
  
  #-----------------------------------------------------------------------------
  # Rewritten for displaying Substitute doll and updating animation.
  #-----------------------------------------------------------------------------
  def setPokemonBitmap(pkmn, battler, back = false)
    @pkmn = pkmn
    @battler = battler
    @_iconBitmap&.dispose
    if @substitute
      @_iconBitmap = GameData::Species.substitute_sprite_bitmap(back)
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      self.pattern = nil
      self.pattern_type = nil
    else
      @_iconBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pkmn, back)
      @_iconBitmap.setPokemon(@battler, back, @hue)
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      self.set_plugin_pattern(@battler)
    end
    pbSetPosition
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to include Substitute doll metrics.
  #-----------------------------------------------------------------------------
  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    if @index.even?
      self.z = 50 + (5 * @index / 2)
    else
      self.z = 50 - (5 * (@index + 1) / 2)
    end
    p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
    @spriteX = p[0]
    @spriteY = p[1]
    if @substitute
      side = (@index.even?) ? 0 : 1
      @spriteY += Settings::SUBSTITUTE_DOLL_METRICS[side]
    else
      @pkmn.species_data.apply_metrics_to_sprite(self, @index)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten for updating animations and patterns.
  # Turns of sprite bobbing for animated sprites.
  #-----------------------------------------------------------------------------
  def update
    return if !@_iconBitmap
    @updating = true
    @_iconBitmap.update
    self.bitmap = @_iconBitmap.bitmap
    @spriteYExtra = 0
    if @selected == 1 && COMMAND_BOBBING_DURATION && $PokemonSystem.animated_sprites > 0
      bob_delta = System.uptime % COMMAND_BOBBING_DURATION
      bob_frame = (4 * bob_delta / COMMAND_BOBBING_DURATION).floor
      case bob_frame
      when 1 then @spriteYExtra = 2
      when 3 then @spriteYExtra = -2
      end
    end
    self.x       = self.x
    self.y       = self.y
    self.visible = @spriteVisible
    if @selected == 2 && @spriteVisible && TARGET_BLINKING_DURATION
      blink_delta = System.uptime % TARGET_BLINKING_DURATION   # 0-TARGET_BLINKING_DURATION
      blink_frame = (3 * blink_delta / TARGET_BLINKING_DURATION).floor
      self.visible = (blink_frame != 0)
    end
    @updating = false
    self.set_status_pattern(@battler) if !@substitute
    self.update_plugin_pattern
    @_iconBitmap.update_pokemon_sprite(@speed, @reversed) if animated?
  end
end


################################################################################
#
# Pokemon shadow sprites (Battle)
#
################################################################################

class Battle::Scene::BattlerShadowSprite < RPG::Sprite
  attr_accessor :substitute, :speed, :reversed
  
  #-----------------------------------------------------------------------------
  # General sprite utilities.
  #-----------------------------------------------------------------------------
  def animated?
    return !@_iconBitmap.nil? && @_iconBitmap.is_a?(DeluxeBitmapWrapper)
  end
  
  def iconBitmap; return @_iconBitmap; end
  
  #-----------------------------------------------------------------------------
  # Rewritten for setting animated shadows as well as Substitute doll shadows.
  #-----------------------------------------------------------------------------
  def setPokemonBitmap(pkmn, battler, sprite)
    @pkmn = pkmn
    @battler = battler
    @_iconBitmap&.dispose
    if @substitute
      filename = pbResolveBitmap("Graphics/Pokemon/Shadow/2")
      return if !filename
      @_iconBitmap = AnimatedBitmap.new(filename)
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      pbSetDisplay
    else
      return if !sprite.animated?
      @reversed = sprite.reversed
      @_iconBitmap = GameData::Species.sprite_bitmap_from_pokemon(@pkmn, @index.even?)
      @_iconBitmap.speed = sprite.iconBitmap.speed
      @_iconBitmap.pokemon = sprite.iconBitmap.pokemon
      self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
      self.mirror  = @index.even?
      pbSetDisplay(sprite.opacity)
    end
    self.pattern = nil
    self.pattern_type = nil
    pbSetPosition(sprite)
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to include Substitute doll and animated shadow metrics.
  #-----------------------------------------------------------------------------
  def pbSetPosition(sprite)
    return if !@_iconBitmap
    if @substitute
      pbSetOrigin
      p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
      self.x      = p[0]
      self.y      = p[1]
      self.angle  = 0
      self.zoom_x = 1
      self.zoom_y = 1
    else
      self.ox     = sprite.bitmap.width / 2
      self.oy     = sprite.bitmap.height / 2
      self.x      = sprite.x
      self.y      = sprite.y
      self.y     -= sprite.bitmap.height / 4 if @index.odd?
      self.y     -= 25 if @battler.dynamax? && @index.odd? && Settings::SHOW_DYNAMAX_SIZE
      self.angle  = sprite.angle
      self.angle += ((@index.even?) ? 176 : -2)
      @pkmn.species_data.apply_metrics_to_sprite(self, @index, true)
      metrics = GameData::SpeciesMetrics.get_species_form(@pkmn.species, @pkmn.form, @pkmn.female?)
      size = metrics.shadow_size
      if size != 0
        size -= 1 if size > 0
        size -= 4 if @battler&.airborneOffScreen?
        self.zoom_x = sprite.zoom_x + (size * 0.1)
        self.zoom_y = (sprite.zoom_y * @_iconBitmap.scale * 0.25) * 0.5 + (size * 0.025)
      end
    end
    self.z = 3
  end
  
  #-----------------------------------------------------------------------------
  # Sets the visual parameters of shadow sprites.
  #-----------------------------------------------------------------------------
  def pbSetDisplay(opacity = 255)
    if @substitute
      self.opacity = opacity
      self.tone = Tone.new(0, 0, 0, 0)
    else
      self.opacity = opacity * 0.3
      self.tone = Tone.new(-255, -255, -255, 255)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Aliased for updating animations.
  #-----------------------------------------------------------------------------
  alias animated_update update
  def update
    animated_update
    return if !animated?
    pbSetDisplay
    @_iconBitmap.update_pokemon_sprite(@speed, @reversed)
  end
end


################################################################################
#
# Mosaic Battler sprites.
#
################################################################################

class MosaicBattlerSprite < Battle::Scene::BattlerSprite
  INITIAL_MOSAIC = 10

  def initialize(*args)
    super(*args)
    @mosaic = 0
    @inrefresh = false
    @mosaicbitmap = nil
    @mosaicbitmap2 = nil
    @oldbitmap = self.bitmap
  end

  def dispose
    super
    @mosaicbitmap&.dispose
    @mosaicbitmap = nil
    @mosaicbitmap2&.dispose
    @mosaicbitmap2 = nil
  end

  def bitmap=(value)
    super
    mosaicRefresh(value)
  end
  
  def mosaic=(value)
    @mosaic = value
    @mosaic = 0 if @mosaic < 0
    @start_mosaic = @mosaic if !@start_mosaic
  end

  def mosaic_duration=(val)
    @mosaic_duration = val
    @mosaic_duration = 0 if @mosaic_duration < 0
    @mosaic_timer_start = System.uptime if @mosaic_duration > 0
  end
  
  def update
    super
    if @mosaic_timer_start
      @start_mosaic = INITIAL_MOSAIC if !@start_mosaic || @start_mosaic == 0
      new_mosaic = lerp(@start_mosaic, 0, @mosaic_duration, @mosaic_timer_start, System.uptime).to_i
      self.mosaic = new_mosaic
      mosaicRefresh(@oldbitmap)
      if new_mosaic == 0
        @mosaic_timer_start = nil
        @start_mosaic = nil
      end
    end
  end

  def mosaicRefresh(bitmap)
    return if @inrefresh || !bitmap
    @inrefresh = true
    @oldbitmap = bitmap
    if @mosaic <= 0 || !@oldbitmap
      @mosaicbitmap&.dispose
      @mosaicbitmap = nil
      @mosaicbitmap2&.dispose
      @mosaicbitmap2 = nil
      self.bitmap = @oldbitmap
    else
      newWidth  = [(@oldbitmap.width / @mosaic), 1].max
      newHeight = [(@oldbitmap.height / @mosaic), 1].max
      @mosaicbitmap2&.dispose
      @mosaicbitmap = pbDoEnsureBitmap(@mosaicbitmap, newWidth, newHeight)
      @mosaicbitmap.clear
      @mosaicbitmap2 = pbDoEnsureBitmap(@mosaicbitmap2, @oldbitmap.width, @oldbitmap.height)
      @mosaicbitmap2.clear
      @mosaicbitmap.stretch_blt(Rect.new(0, 0, newWidth, newHeight), @oldbitmap, @oldbitmap.rect)
      @mosaicbitmap2.stretch_blt(
        Rect.new((-@mosaic / 2) + 1, (-@mosaic / 2) + 1, @mosaicbitmap2.width, @mosaicbitmap2.height),
        @mosaicbitmap, Rect.new(0, 0, newWidth, newHeight)
      )
      self.bitmap = @mosaicbitmap2
    end
    @inrefresh = false
  end
end


################################################################################
#
# Implements new battler sprites.
#
################################################################################

#===============================================================================
# Battle::Scene
#===============================================================================
class Battle::Scene
  #-----------------------------------------------------------------------------
  # Rewritten to use mosaic sprites for battlers.
  #-----------------------------------------------------------------------------
  def pbCreatePokemonSprite(idxBattler)
    sideSize = @battle.pbSideSize(idxBattler)
    batSprite = MosaicBattlerSprite.new(@viewport, sideSize, idxBattler, @animations)
    @sprites["pokemon_#{idxBattler}"] = batSprite
    shaSprite = BattlerShadowSprite.new(@viewport, sideSize, idxBattler)
    shaSprite.visible = false
    @sprites["shadow_#{idxBattler}"] = shaSprite
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten to use new sprite methods for displaying sprites and shadows.
  #-----------------------------------------------------------------------------
  def pbChangePokemon(idxBattler, pkmn, update = false)
    idxBattler = idxBattler.index if idxBattler.respond_to?("index")
    pkmnSprite   = @sprites["pokemon_#{idxBattler}"]
    shadowSprite = @sprites["shadow_#{idxBattler}"]
    back = !@battle.opposes?(idxBattler)
    pkmn = pbGetDynamaxPokemon(idxBattler, pkmn) if PluginManager.installed?("[DBK] Dynamax")
    battler = @battle.battlers[idxBattler]
    pkmnSprite.setPokemonBitmap(pkmn, battler, back)
    shadowSprite.setPokemonBitmap(pkmn, battler, pkmnSprite)
    showShadow = pkmn.species_data.shows_shadow?(back)
    shadowSprite.visible = showShadow if shadowSprite && !battler.vanished
    pkmnSprite.mosaic_duration = 0.50 if battler.mosaicChange
    battler.mosaicChange = false
    if update
      if battler.vanishedOffScreen?
        battler.vanished = true
        pkmnSprite.visible = false
        if shadowSprite.visible && !battler.airborneOffScreen?
          shadowSprite.visible = false
        end
      else
        battler.vanished = false
        pkmnSprite.visible = true
        shadowSprite.visible = showShadow
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten for compatibility with Ally Switch/Shift command.
  #-----------------------------------------------------------------------------
  def pbSwapBattlerSprites(idxA, idxB)
    @sprites["pokemon_#{idxA}"], @sprites["pokemon_#{idxB}"] = @sprites["pokemon_#{idxB}"], @sprites["pokemon_#{idxA}"]
    @sprites["shadow_#{idxA}"], @sprites["shadow_#{idxB}"] = @sprites["shadow_#{idxB}"], @sprites["shadow_#{idxA}"]
    @lastCmd[idxA], @lastCmd[idxB] = @lastCmd[idxB], @lastCmd[idxA]
    @lastMove[idxA], @lastMove[idxB] = @lastMove[idxB], @lastMove[idxA]
    [idxA, idxB].each do |i|
      @sprites["pokemon_#{i}"].index = i
      @sprites["pokemon_#{i}"].pbSetPosition
      @sprites["shadow_#{i}"].index = i
      @sprites["shadow_#{i}"].pbSetPosition(@sprites["pokemon_#{i}"])
      @sprites["dataBox_#{i}"].battler = @battle.battlers[i]
    end
    pbRefresh
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to prevent animations for battlers who have vanished off screen.
  #-----------------------------------------------------------------------------
  alias animated_pbAnimationCore pbAnimationCore
  def pbAnimationCore(animation, user, target, oppMove = false)
    return if user && user.vanished
    return if target && target.vanished
    animated_pbAnimationCore(animation, user, target, oppMove)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for returning a battler's sprite and shadow sprite.
  #-----------------------------------------------------------------------------
  def pbGetBattlerSprites(idxBattler)
    return @sprites["pokemon_#{idxBattler}"], @sprites["shadow_#{idxBattler}"]
  end
end

#===============================================================================
# Battle::Battler
#===============================================================================
class Battle::Battler
  attr_accessor :mosaicChange, :vanished
  
  #-----------------------------------------------------------------------------
  # Aliased to initialize new battler sprite attributes.
  #-----------------------------------------------------------------------------
  alias animated_pbInitialize pbInitialize
  def pbInitialize(pkmn, idxParty, batonPass = false)
    animated_pbInitialize(pkmn, idxParty, batonPass)
    @mosaicChange = false
    @vanished = false
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so mosaic is triggered upon a battler changing form.
  #-----------------------------------------------------------------------------
  alias animated_pbChangeForm pbChangeForm
  def pbChangeForm(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    @mosaicChange = true
    animated_pbChangeForm(newForm, msg)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so mosaic is triggered upon a battler losing the Illusion ability.
  #-----------------------------------------------------------------------------
  alias animated_pbOnLosingAbility pbOnLosingAbility
  def pbOnLosingAbility(oldAbil, suppressed = false)
    if oldAbil == :ILLUSION && @effects[PBEffects::Illusion] && !@effects[PBEffects::Transform]
      @mosaicChange = true
    end
    animated_pbOnLosingAbility(oldAbil, suppressed)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to refresh the sprites of vanished battlers each turn.
  #-----------------------------------------------------------------------------
  alias animated_pbEndTurn pbEndTurn
  def pbEndTurn(_choice)
    if @vanished || vanishedOffScreen?
      @battle.scene.pbChangePokemon(self, self.visiblePokemon, true)
    end
    animated_pbEndTurn(_choice)
  end
  
  #-----------------------------------------------------------------------------
  # Utility for determining if a battler is vanished off screen.
  #-----------------------------------------------------------------------------
  def vanishedOffScreen?(ignoreAirborne = false)
    move = GameData::Move.try_get(@effects[PBEffects::TwoTurnAttack])
    return true if move && [
      "TwoTurnAttackInvulnerableUnderground",         # Dig
      "TwoTurnAttackInvulnerableUnderwater",          # Dive
      "TwoTurnAttackInvulnerableRemoveProtections",   # Phantom Force/Shadow Force
    ].include?(move.function_code)
    return (ignoreAirborne) ? false : airborneOffScreen?
  end
  
  #-----------------------------------------------------------------------------
  # Utility for determining if a battler is specifically vanished above the battlefield.
  #-----------------------------------------------------------------------------
  def airborneOffScreen?
    return true if @effects[PBEffects::SkyDrop] >= 0
    return false if !@effects[PBEffects::TwoTurnAttack]
    move = GameData::Move.get(@effects[PBEffects::TwoTurnAttack])
    return [
      "TwoTurnAttackInvulnerableInSky",               # Fly
      "TwoTurnAttackInvulnerableInSkyParalyzeTarget", # Bounce
      "TwoTurnAttackInvulnerableInSkyTargetCannotAct" # Sky Drop
    ].include?(move.function_code)
  end
end

#===============================================================================
# Safari Zone compatibility.
#===============================================================================
class Battle::FakeBattler
  def vanishedOffScreen?; return false; end
  def airborneOffScreen?; return false; end
  def vanished;           return false; end
  def mosaicChange;       return false; end
  def vanished=(value);                 end
  def mosaicChange=(value);             end
end


################################################################################
#
# Animation tweaks for abilities and moves.
#
################################################################################

#===============================================================================
# Illusion
#===============================================================================
# Rewritten so that mosaic is triggered upon Illusion ending.
#-------------------------------------------------------------------------------
Battle::AbilityEffects::OnBeingHit.add(:ILLUSION,
  proc { |ability, user, target, move, battle|
    next if !target.effects[PBEffects::Illusion]
    target.mosaicChange = true
    battle.scene.pbAnimateSubstitute(target, :hide)
    target.effects[PBEffects::Illusion] = nil
    battle.scene.pbChangePokemon(target, target.pokemon)
    battle.pbDisplay(_INTL("{1}'s illusion wore off!", target.pbThis))
    battle.pbSetSeen(target)
    battle.scene.pbAnimateSubstitute(target, :show, true)
  }
)

#===============================================================================
# Two-Turn Attacks
#===============================================================================
# Edited to toggle visibility of vanished battlers.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnMove < Battle::Move
  def pbShowAnimation(id, user, targets, hitNum = 0, showAnimation = true)
    hitNum = 1 if @chargingTurn && !@damagingTurn
    invulMove = [
      "TwoTurnAttackInvulnerableInSky",               # Fly
      "TwoTurnAttackInvulnerableUnderground",         # Dig
      "TwoTurnAttackInvulnerableUnderwater",          # Dive
      "TwoTurnAttackInvulnerableInSkyParalyzeTarget", # Bounce
      "TwoTurnAttackInvulnerableRemoveProtections",   # Phantom Force/Shadow Force
      "TwoTurnAttackInvulnerableInSkyTargetCannotAct" # Sky Drop
    ].include?(@function_code)
    if invulMove
      @battle.scene.pbChangePokemon(user, user.visiblePokemon, true) if user.vanished
      super
      @battle.scene.pbChangePokemon(user, user.visiblePokemon, true) if !user.vanished
    else
      super
    end
  end
end

#===============================================================================
# Sky Drop
#===============================================================================
# Edited to toggle visibility of the vanished target lifted up with Sky Drop.
#-------------------------------------------------------------------------------
class Battle::Move::TwoTurnAttackInvulnerableInSkyTargetCannotAct < Battle::Move::TwoTurnMove
  def pbChargingTurnEffect(user, target)
    target.effects[PBEffects::SkyDrop] = user.index
    @battle.scene.pbChangePokemon(target, target.visiblePokemon, true)
  end

  def pbEffectAfterAllHits(user, target)
    target.effects[PBEffects::SkyDrop] = -1 if @damagingTurn
    [user, target].each { |b| @battle.scene.pbChangePokemon(b, b.visiblePokemon, true) }
  end
end


################################################################################
#
# Animation fixes for shadow sprites.
#
################################################################################

#===============================================================================
# Utility for handling shadow sprites during switching/capture animations.
#===============================================================================
module Battle::Scene::Animation::BallAnimationMixin
  def shadowAppear(battler, delay, shadow = nil)
    shadow = addSprite(@sprites["shadow_#{battler.index}"], PictureOrigin::CENTER) if !shadow
    pkmn = battler.visiblePokemon
    metrics = GameData::SpeciesMetrics.get_species_form(pkmn.species, pkmn.form, pkmn.female?)
    size = metrics.shadow_size
    scale = (battler.opposes?(0)) ? metrics.front_sprite_scale : metrics.back_sprite_scale
    zoomX = 100 * (1 + size * 0.1)
    zoomY = 100 * (scale * 0.25 * 0.5 + (size * 0.025))
    shadow.setZoomXY(delay, zoomX, zoomY)
    shadow.setOpacity(delay, 0)
    shadow.setVisible(delay, @shadowVisible)
    shadow.moveOpacity(delay + 5, 10, 255 * 0.3)
  end
end

#===============================================================================
# Rewrites of animations to support animated shadow sprites.
#===============================================================================
# Player send out.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballPlayerSendOut < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    traSprite = @sprites["player_#{@idxTrainer}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 255
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = ballPos[0]
    battlerStartY = ballPos[1]
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    ballStartX = -6
    ballStartY = 202
    ballMidX = 0
    ballMidY = battlerStartY - 144
    ball = addBallSprite(ballStartX, ballStartY, poke_ball)
    ball.setZ(0, 25)
    ball.setVisible(0, false)
    if @showingTrainer && traSprite && traSprite.x > 0
      ball.setZ(0, traSprite.z - 1)
      ballStartX, ballStartY = ballTracksHand(ball, traSprite)
    end
    delay = ball.totalDuration
    createBallTrajectory(ball, delay, 12,
                         ballStartX, ballStartY, ballMidX, ballMidY, battlerStartX, battlerStartY - 18)
    ball.setZ(9, batSprite.z - 1)
    delay = ball.totalDuration + 4
    delay += 10 * @idxOrder
    ballOpenUp(ball, delay - 2, poke_ball)
    ballBurst(delay, ball, battlerStartX, battlerStartY - 18, poke_ball)
    ball.moveOpacity(delay + 2, 2, 0)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setXY(0, battlerStartX, battlerStartY)
    battler.setZoom(0, 0)
    battler.setColor(0, col)
    battlerAppear(battler, delay, battlerEndX, battlerEndY, batSprite, col)
    shadowAppear(@battler, delay) if @shadowVisible
  end
end

#-------------------------------------------------------------------------------
# Trainer send out.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballTrainerSendOut < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 255
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = ballPos[0]
    battlerStartY = ballPos[1]
    battlerEndX = batSprite.x
    battlerEndY = batSprite.y
    ball = addBallSprite(0, 0, poke_ball)
    ball.setZ(0, batSprite.z - 1)
    createBallTrajectory(ball, battlerStartX, battlerStartY)
    delay = ball.totalDuration + 6
    delay += 10 if @showingTrainer
    delay += 10 * @idxOrder
    ballOpenUp(ball, delay - 2, poke_ball)
    ballBurst(delay, ball, battlerStartX, battlerStartY - 18, poke_ball)
    ball.moveOpacity(delay + 2, 2, 0)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setXY(0, battlerStartX, battlerStartY)
    battler.setZoom(0, 0)
    battler.setColor(0, col)
    battlerAppear(battler, delay, battlerEndX, battlerEndY, batSprite, col)
    shadowAppear(@battler, delay) if @shadowVisible
  end
end

#-------------------------------------------------------------------------------
# Battler recall.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::BattlerRecall < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@idxBattler}"]
    shaSprite = @sprites["shadow_#{@idxBattler}"]
    poke_ball = (batSprite.pkmn) ? batSprite.pkmn.poke_ball : nil
    col = getBattlerColorFromPokeBall(poke_ball)
    col.alpha = 0
    ballPos = Battle::Scene.pbBattlerPosition(@idxBattler, batSprite.sideSize)
    battlerEndX = ballPos[0]
    battlerEndY = ballPos[1]
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    battler.setVisible(0, true)
    battler.setColor(0, col)
    ball = addBallSprite(battlerEndX, battlerEndY, poke_ball)
    ball.setZ(0, batSprite.z + 1)
    ballOpenUp(ball, 0, poke_ball)
    delay = ball.totalDuration
    ballBurstRecall(delay, ball, battlerEndX, battlerEndY, poke_ball)
    ball.moveOpacity(10, 2, 0)
    battlerAbsorb(battler, delay, battlerEndX, battlerEndY, col)
    if shaSprite.visible
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      shadow.setVisible(delay, false)
    end
  end
end

#-------------------------------------------------------------------------------
# Capturing wild Pokemon.
#-------------------------------------------------------------------------------
class Battle::Scene::Animation::PokeballThrowCapture < Battle::Scene::Animation
  def createProcesses
    batSprite = @sprites["pokemon_#{@battler.index}"]
    shaSprite = @sprites["shadow_#{@battler.index}"]
    traSprite = @sprites["player_1"]
    ballPos = Battle::Scene.pbBattlerPosition(@battler.index, batSprite.sideSize)
    battlerStartX = batSprite.x
    battlerStartY = batSprite.y
    ballStartX = -6
    ballStartY = 246
    ballMidX   = 0
    ballMidY   = 78
    ballEndX   = ballPos[0]
    ballEndY   = 112
    ballGroundY = ballPos[1] - 4
    ball = addBallSprite(ballStartX, ballStartY, @poke_ball)
    ball.setZ(0, batSprite.z + 1)
    @ballSpriteIndex = (@success) ? @tempSprites.length - 1 : -1
    if @showingTrainer && traSprite && traSprite.bitmap.width >= traSprite.bitmap.height * 2
      trainer = addSprite(traSprite, PictureOrigin::BOTTOM)
      ballStartX, ballStartY = trainerThrowingFrames(ball, trainer, traSprite)
    end
    delay = ball.totalDuration
    if @critCapture
      ball.setSE(delay, "Battle critical catch throw")
    else
      ball.setSE(delay, "Battle throw")
    end
    createBallTrajectory(ball, delay, 16,
                         ballStartX, ballStartY, ballMidX, ballMidY, ballEndX, ballEndY)
    ball.setZ(9, batSprite.z + 1)
    ball.setSE(delay + 16, "Battle ball hit")
    delay = ball.totalDuration + 6
    ballOpenUp(ball, delay, @poke_ball, true, false)
    battler = addSprite(batSprite, PictureOrigin::BOTTOM)
    delay = ball.totalDuration
    ballBurstCapture(delay, ball, ballEndX, ballEndY, @poke_ball)
    battler.setSE(delay, "Battle jump to ball")
    battler.moveXY(delay, 5, ballEndX, ballEndY)
    battler.moveZoom(delay, 5, 0)
    battler.setVisible(delay + 5, false)
    if @shadowVisible
      shadow = addSprite(shaSprite, PictureOrigin::CENTER)
      shadow.moveOpacity(delay, 5, 0)
      shadow.moveZoom(delay, 5, 0)
      shadow.setVisible(delay + 5, false)
    end
    delay = ball.totalDuration
    ballSetClosed(ball, delay, @poke_ball)
    ball.moveTone(delay, 3, Tone.new(96, 64, -160, 160))
    ball.moveTone(delay + 5, 3, Tone.new(0, 0, 0, 0))
    delay = ball.totalDuration + 3
    if @critCapture
      ball.setSE(delay, "Battle ball shake")
      ball.moveXY(delay, 1, ballEndX + 4, ballEndY)
      ball.moveXY(delay + 1, 2, ballEndX - 4, ballEndY)
      ball.moveXY(delay + 3, 2, ballEndX + 4, ballEndY)
      ball.setSE(delay + 4, "Battle ball shake")
      ball.moveXY(delay + 5, 2, ballEndX - 4, ballEndY)
      ball.moveXY(delay + 7, 1, ballEndX, ballEndY)
      delay = ball.totalDuration + 3
    end
    4.times do |i|
      t = [4, 4, 3, 2][i]
      d = [1, 2, 4, 8][i]
      delay -= t if i == 0
      if i > 0
        ball.setZoomXY(delay, 100 + (5 * (5 - i)), 100 - (5 * (5 - i)))
        ball.moveZoom(delay, 2, 100)
        ball.moveXY(delay, t, ballEndX, ballGroundY - ((ballGroundY - ballEndY) / d))
      end
      ball.moveXY(delay + t, t, ballEndX, ballGroundY)
      ball.setSE(delay + (2 * t), "Battle ball drop", 100 - (i * 7))
      delay = ball.totalDuration
    end
    battler.setXY(ball.totalDuration, ballEndX, ballGroundY)
    delay = ball.totalDuration + 12
    [@numShakes, 3].min.times do |i|
      ball.setSE(delay, "Battle ball shake")
      ball.moveXY(delay, 2, ballEndX - (2 * (4 - i)), ballGroundY)
      ball.moveAngle(delay, 2, 5 * (4 - i))
      ball.moveXY(delay + 2, 4, ballEndX + (2 * (4 - i)), ballGroundY)
      ball.moveAngle(delay + 2, 4, -5 * (4 - i))
      ball.moveXY(delay + 6, 2, ballEndX, ballGroundY)
      ball.moveAngle(delay + 6, 2, 0)
      delay = ball.totalDuration + 8
    end
    if @success
      ballCaptureSuccess(ball, delay, ballEndX, ballGroundY)
    else
      ball.setZ(delay, batSprite.z - 1)
      ballOpenUp(ball, delay, @poke_ball, false)
      ballBurst(delay, ball, ballEndX, ballGroundY, @poke_ball)
      ball.moveOpacity(delay + 2, 2, 0)
      col = getBattlerColorFromPokeBall(@poke_ball)
      col.alpha = 255
      battler.setColor(delay, col)
      battlerAppear(battler, delay, battlerStartX, battlerStartY, batSprite, col)
      shadowAppear(@battler, delay, shadow) if @shadowVisible
    end
  end
end