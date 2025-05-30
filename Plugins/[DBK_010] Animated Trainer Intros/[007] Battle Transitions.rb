#===============================================================================
# Battle Transitions
#===============================================================================

#-------------------------------------------------------------------------------
# Edits "hgss_vs" transition to use default bar sprite if no specific one exists.
#-------------------------------------------------------------------------------
module Transitions
  class VSTrainer < Transition_Base
    def initialize_bitmaps
      tr_type = $game_temp.transition_animation_data[0]
      if pbResolveBitmap("Graphics/Transitions/hgss_vsBar_#{tr_type}")
        @bar_bitmap = RPG::Cache.transition("hgss_vsBar_#{tr_type}")
      else
        @bar_bitmap = RPG::Cache.transition("hgss_vsBar")
      end
      @vs_1_bitmap  = RPG::Cache.transition("hgss_vs1")
      @vs_2_bitmap  = RPG::Cache.transition("hgss_vs2")
      @foe_bitmap   = RPG::Cache.transition("hgss_vs_#{$game_temp.transition_animation_data[0]}")
      @foe_bitmap.hue_change(GameData::TrainerType.get(tr_type).trainer_sprite_hue) if @foe_bitmap
      @black_bitmap = RPG::Cache.transition("black_half")
      dispose if !@bar_bitmap || !@vs_1_bitmap || !@vs_2_bitmap || !@foe_bitmap || !@black_bitmap
    end
  end
end

SpecialBattleIntroAnimations.register("vs_trainer_animation", 60,
  proc { |battle_type, foe, location|
    next false if battle_type.even? || foe.length != 1
    tr_type = foe[0].trainer_type
    barBitmap = pbResolveBitmap("Graphics/Transitions/hgss_vsBar_#{tr_type}")
    barBitmap = pbResolveBitmap("Graphics/Transitions/hgss_vsBar") if !barBitmap
    next barBitmap && pbResolveBitmap("Graphics/Transitions/hgss_vs_#{tr_type}")
  },
  proc { |viewport, battle_type, foe, location|
    $game_temp.transition_animation_data = [foe[0].trainer_type, foe[0].name]
    pbBattleAnimationCore("VSTrainer", viewport, location, 1)
    $game_temp.transition_animation_data = nil
  }
)

#-------------------------------------------------------------------------------
# Edits "vsE4" transition to use default bar sprite if no specific one exists.
#-------------------------------------------------------------------------------
module Transitions  
  class VSEliteFour < Transition_Base
    def initialize_bitmaps
      tr_type = $game_temp.transition_animation_data[0]
      if pbResolveBitmap("Graphics/Transitions/vsE4Bar_#{tr_type}")
        @bar_bitmap = RPG::Cache.transition("vsE4Bar_#{tr_type}")
      else
        @bar_bitmap = RPG::Cache.transition("vsE4Bar")
      end
      @vs_1_bitmap   = RPG::Cache.transition("hgss_vs1")
      @vs_2_bitmap   = RPG::Cache.transition("hgss_vs2")
      @player_bitmap = RPG::Cache.transition("vsE4_#{$game_temp.transition_animation_data[2]}")
      @foe_bitmap    = RPG::Cache.transition("vsE4_#{$game_temp.transition_animation_data[0]}")
      @foe_bitmap.hue_change(GameData::TrainerType.get(tr_type).trainer_sprite_hue) if @foe_bitmap
      @black_bitmap  = RPG::Cache.transition("black_half")
      dispose if !@bar_bitmap || !@vs_1_bitmap || !@vs_2_bitmap || !@foe_bitmap || !@black_bitmap
      @num_bar_frames = @bar_bitmap.height / BAR_HEIGHT
    end
  end
end

SpecialBattleIntroAnimations.register("vs_elite_four_animation", 60,
  proc { |battle_type, foe, location|
    next false if battle_type.even? || foe.length != 1
    tr_type = foe[0].trainer_type
    barBitmap = pbResolveBitmap("Graphics/Transitions/vsE4Bar_#{tr_type}")
    barBitmap = pbResolveBitmap("Graphics/Transitions/vsE4Bar") if !barBitmap
    next barBitmap && pbResolveBitmap("Graphics/Transitions/vsE4_#{tr_type}")
  },
  proc { |viewport, battle_type, foe, location|
    tr_sprite_name = $player.trainer_type.to_s
    if pbResolveBitmap("Graphics/Transitions/vsE4_#{tr_sprite_name}_#{$player.outfit}")
      tr_sprite_name += "_#{$player.outfit}"
    end
    $game_temp.transition_animation_data = [foe[0].trainer_type, foe[0].name, tr_sprite_name]
    pbBattleAnimationCore("VSEliteFour", viewport, location, 0)
    $game_temp.transition_animation_data = nil
  }
)

#-------------------------------------------------------------------------------
# Edits "vsTrainer" transition to use default bar sprite if no specific one exists.
#-------------------------------------------------------------------------------
SpecialBattleIntroAnimations.register("alternate_vs_trainer_animation", 50,
  proc { |battle_type, foe, location|
    next false if battle_type.even? || foe.length != 1
    tr_type = foe[0].trainer_type
    barBitmap = pbResolveBitmap("Graphics/Transitions/vsBar_#{tr_type}")
    barBitmap = pbResolveBitmap("Graphics/Transitions/vsBar") if !barBitmap
    next barBitmap && pbResolveBitmap("Graphics/Transitions/vsTrainer_#{tr_type}")
  },
  proc { |viewport, battle_type, foe, location|
    tr_type = foe[0].trainer_type
    if pbResolveBitmap("Graphics/Transitions/vsBar_#{tr_type}")
      trainer_bar_graphic = sprintf("vsBar_%s", tr_type.to_s) rescue nil
    else
      trainer_bar_graphic = sprintf("vsBar") rescue nil
    end
    trainer_graphic     = sprintf("vsTrainer_%s", tr_type.to_s) rescue nil
    player_tr_type = $player.trainer_type
    outfit = $player.outfit
    player_bar_graphic = sprintf("vsBar_%s_%d", player_tr_type.to_s, outfit) rescue nil
    if !pbResolveBitmap("Graphics/Transitions/" + player_bar_graphic)
      player_bar_graphic = sprintf("vsBar_%s", player_tr_type.to_s) rescue nil
    end
    player_graphic = sprintf("vsTrainer_%s_%d", player_tr_type.to_s, outfit) rescue nil
    if !pbResolveBitmap("Graphics/Transitions/" + player_graphic)
      player_graphic = sprintf("vsTrainer_%s", player_tr_type.to_s) rescue nil
    end
    viewplayer = Viewport.new(0, Graphics.height / 3, Graphics.width / 2, 128)
    viewplayer.z = viewport.z
    viewopp = Viewport.new(Graphics.width / 2, Graphics.height / 3, Graphics.width / 2, 128)
    viewopp.z = viewport.z
    viewvs = Viewport.new(0, 0, Graphics.width, Graphics.height)
    viewvs.z = viewport.z
    fade = Sprite.new(viewport)
    fade.bitmap  = RPG::Cache.transition("vsFlash")
    fade.tone    = Tone.new(-255, -255, -255)
    fade.opacity = 100
    overlay = Sprite.new(viewport)
    overlay.bitmap = Bitmap.new(Graphics.width, Graphics.height)
    pbSetSystemFont(overlay.bitmap)
    xoffset = ((Graphics.width / 2) / 10) * 10
    bar1 = Sprite.new(viewplayer)
    bar1.bitmap = RPG::Cache.transition(player_bar_graphic)
    bar1.x      = -xoffset
    bar2 = Sprite.new(viewopp)
    bar2.bitmap = RPG::Cache.transition(trainer_bar_graphic)
    bar2.x      = xoffset
    vs_x = Graphics.width / 2
    vs_y = Graphics.height / 1.5
    vs = Sprite.new(viewvs)
    vs.bitmap  = RPG::Cache.transition("vs")
    vs.ox      = vs.bitmap.width / 2
    vs.oy      = vs.bitmap.height / 2
    vs.x       = vs_x
    vs.y       = vs_y
    vs.visible = false
    flash = Sprite.new(viewvs)
    flash.bitmap  = RPG::Cache.transition("vsFlash")
    flash.opacity = 0
    pbWait(0.25) do |delta_t|
      bar1.x = lerp(-xoffset, 0, 0.25, delta_t)
      bar2.x = lerp(xoffset, 0, 0.25, delta_t)
    end
    bar1.dispose
    bar2.dispose
    pbSEPlay("Vs flash")
    pbSEPlay("Vs sword")
    flash.opacity = 255
    bar1 = AnimatedPlane.new(viewplayer)
    bar1.bitmap = RPG::Cache.transition(player_bar_graphic)
    bar2 = AnimatedPlane.new(viewopp)
    bar2.bitmap = RPG::Cache.transition(trainer_bar_graphic)
    player = Sprite.new(viewplayer)
    player.bitmap = RPG::Cache.transition(player_graphic)
    player.x      = -xoffset
    trainer = Sprite.new(viewopp)
    trainer.bitmap = RPG::Cache.transition(trainer_graphic)
    trainer.bitmap.hue_change(GameData::TrainerType.get(tr_type).trainer_sprite_hue)
    trainer.x      = xoffset
    trainer.tone   = Tone.new(-255, -255, -255)
    pbWait(1.2) do |delta_t|
      flash.opacity = lerp(255, 0, 0.25, delta_t)
      bar1.ox = lerp(0, -bar1.bitmap.width * 3, 1.2, delta_t)
      bar2.ox = lerp(0, bar2.bitmap.width * 3, 1.2, delta_t)
      player.x = lerp(-xoffset, 0, 0.25, delta_t - 0.6)
      trainer.x = lerp(xoffset, 0, 0.25, delta_t - 0.6)
    end
    player.x = 0
    trainer.x = 0
    flash.opacity = 255
    pbSEPlay("Vs sword")
    vs.visible = true
    trainer.tone = Tone.new(0, 0, 0)
    trainername = foe[0].name
    textpos = [
      [$player.name, Graphics.width / 4, (Graphics.height / 1.5) + 16, :center,
       Color.new(248, 248, 248), Color.new(72, 72, 72)],
      [trainername, (Graphics.width / 4) + (Graphics.width / 2), (Graphics.height / 1.5) + 16, :center,
       Color.new(248, 248, 248), Color.new(72, 72, 72)]
    ]
    pbDrawTextPositions(overlay.bitmap, textpos)
    shudder_time = 1.75
    zoom_time = 2.5
    pbWait(2.8) do |delta_t|
      if delta_t <= shudder_time
        flash.opacity = lerp(255, 0, 0.25, delta_t)
      elsif delta_t >= zoom_time
        flash.tone = Tone.new(-255, -255, -255)
        flash.opacity = lerp(0, 255, 0.25, delta_t - zoom_time)
      end
      bar1.ox = lerp(0, -bar1.bitmap.width * 7, 2.8, delta_t)
      bar2.ox = lerp(0, bar2.bitmap.width * 7, 2.8, delta_t)
      if delta_t <= shudder_time
        period = (delta_t / 0.025).to_i % 4
        shudder_delta = [2, 0, -2, 0][period]
        vs.x = vs_x + shudder_delta
        vs.y = vs_y - shudder_delta
      elsif delta_t <= zoom_time
        vs.zoom_x = lerp(1.0, 7.0, zoom_time - shudder_time, delta_t - shudder_time)
        vs.zoom_y = vs.zoom_x
      end
    end
    player.dispose
    trainer.dispose
    flash.dispose
    vs.dispose
    bar1.dispose
    bar2.dispose
    overlay.dispose
    fade.dispose
    viewvs.dispose
    viewopp.dispose
    viewplayer.dispose
    viewport.color = Color.black
  }
)

#===============================================================================
# Play the B2W2 Vs. Champion battle transition animation for any single
# trainer battle where the following graphics exist in the Graphics/Transitions/
# folder for the player and opponent:
#   * "champion_vs_TRAINERTYPE.png"
#===============================================================================
SpecialBattleIntroAnimations.register("vs_champion_animation", 60,
  proc { |battle_type, foe, location|
    next false if battle_type.even? || foe.length != 1
    tr_type = foe[0].trainer_type
    next pbResolveBitmap("Graphics/Transitions/champion_vs_#{tr_type}")
  },
  proc { |viewport, battle_type, foe, location|
    tr_type = foe[0].trainer_type
    trainer_graphic = sprintf("champion_vs_%s", tr_type.to_s) rescue nil
    player_tr_type = $player.trainer_type
    outfit = $player.outfit
    player_hue = 0
    player_graphic = sprintf("champion_vs_%s_%d", player_tr_type.to_s, outfit) rescue nil
    if !pbResolveBitmap("Graphics/Transitions/" + player_graphic)
      player_graphic = sprintf("champion_vs_%s", player_tr_type.to_s) rescue nil
      player_hue = GameData::TrainerType.get($player.trainer_type).trainer_sprite_hue
    end
    width = Graphics.width
    height = Graphics.height
    #---------------------------------------------------------------------------
    # Set up viewports
    viewbg = Viewport.new(0, 0, width, height)
    viewbg.z = viewport.z
    viewplayer = Viewport.new(0, 0, width / 2, height)
    viewplayer.z = viewport.z
    viewopp = Viewport.new(width / 2, 0, width, height)
    viewopp.z = viewport.z
    viewvs1 = Viewport.new(0, 0, width, height)
    viewvs1.z = viewport.z
    viewvs2 = Viewport.new(0, 0, width, height)
    viewvs2.z = viewport.z
    #---------------------------------------------------------------------------
    # Set up transition to black screen.
    star1 = Sprite.new(viewport)
    star1.bitmap  = RPG::Cache.transition("champion_vsShine1")
    star1.tone    = Tone.new(-255, -255, -255)
    star1.x       = width / 2
    star1.y       = height / 2
    star1.ox      = star1.bitmap.width / 2
    star1.oy      = star1.bitmap.height / 2
    star1.zoom_x  = 0.5
    star1.zoom_y  = 0.5
    star2 = Sprite.new(viewport)
    star2.bitmap  = RPG::Cache.transition("champion_vsShine2")
    star2.tone    = Tone.new(-255, -255, -255)
    star2.x       = width / 2
    star2.y       = height / 2
    star2.ox      = star2.bitmap.width / 2
    star2.oy      = star2.bitmap.height / 2
    star2.opacity = 150
    #---------------------------------------------------------------------------
    # Set up background elements.
    bg = Sprite.new(viewbg)
    bg.bitmap   = RPG::Cache.transition("champion_vsBG")
    bg.x        = width / 2
    bg.y        = height / 2
    bg.ox       = bg.bitmap.width / 2
    bg.oy       = bg.bitmap.height / 2
    bg.visible  = false
    bg1 = Sprite.new(viewplayer)
    bg1.bitmap  = RPG::Cache.transition("champion_vsBG_player")
    bg1.opacity = 0
    bg2 = Sprite.new(viewopp)
    bg2.bitmap  = RPG::Cache.transition("champion_vsBG_trainer")
    bg2.opacity = 0
    #---------------------------------------------------------------------------
    # Set up trainers & name bars.
    bar1 = Sprite.new(viewplayer)
    bar1.bitmap     = RPG::Cache.transition("champion_vsBar")
    bar1.y          = 20
    bar1.visible    = false
    player = Sprite.new(viewplayer)
    player.bitmap   = RPG::Cache.transition(player_graphic)
     
    player.bitmap.hue_change(player_hue)
    player.y        = -32
    player.opacity  = 100
    player.visible  = false
    trainer = Sprite.new(viewopp)
    trainer.bitmap  = RPG::Cache.transition(trainer_graphic)
    trainer.bitmap.hue_change(GameData::TrainerType.get(tr_type).trainer_sprite_hue)
    trainer.y       = 64
    trainer.opacity = 0
    trainer.visible = false
    bar2 = Sprite.new(viewopp)
    bar2.bitmap     = RPG::Cache.transition("champion_vsBar")
    bar2.x          = width - bar2.bitmap.width
    bar2.y          = height - bar2.bitmap.height + 20
    bar2.angle      = 180
    bar2.visible    = false
    overlay = Sprite.new(viewvs2)
    overlay.bitmap  = Bitmap.new(width, height)
    pbSetSystemFont(overlay.bitmap)
    #---------------------------------------------------------------------------
    # Set up other sprites.
    shine1 = Sprite.new(viewvs2)
    shine1.bitmap  = RPG::Cache.transition("champion_vsShine1")
    shine1.x       = width / 2
    shine1.y       = height / 2
    shine1.ox      = shine1.bitmap.width / 2
    shine1.oy      = shine1.bitmap.height / 2
    shine1.visible = false
    shine2 = Sprite.new(viewvs2)
    shine2.bitmap  = RPG::Cache.transition("champion_vsShine2")
    shine2.x       = width / 2
    shine2.y       = height / 2
    shine2.ox      = shine2.bitmap.width / 2
    shine2.oy      = shine2.bitmap.height / 2
    shine2.visible = false
    vs1 = Sprite.new(viewvs2)
    vs1.bitmap     = RPG::Cache.transition("vs2")
    vs1.x          = -100
    vs1.y          = -100
    vs1.ox         = vs1.bitmap.width / 2
    vs1.oy         = vs1.bitmap.height / 2
    vs1.visible    = false
    vs1.src_rect.width = 66
    vs2 = Sprite.new(viewvs2)
    vs2.bitmap     = RPG::Cache.transition("vs2")
    vs2.x          = width + 100
    vs2.y          = height + 100
    vs2.ox         = vs2.bitmap.width / 2
    vs2.oy         = vs2.bitmap.height / 2
    vs2.visible    = false
    vs2.src_rect.x = 66
    shine3 = Sprite.new(viewvs2)
    shine3.bitmap  = RPG::Cache.transition("champion_vsShine1")
    shine3.x       = width / 2
    shine3.y       = height / 2
    shine3.ox      = shine3.bitmap.width / 2
    shine3.oy      = shine3.bitmap.height / 2
    shine3.zoom_x  = 0.5
    shine3.zoom_y  = 0.5
    shine3.visible = false
    flash = Sprite.new(viewvs2)
    flash.bitmap  = RPG::Cache.transition("vsFlash")
    flash.opacity = 0
    #---------------------------------------------------------------------------
    # Phase 1 of animation: Transition to black screen.
    pbWait(1.0) do |delta_t|
      star1.angle  = lerp(0, -180, 1.0, delta_t)
      star1.zoom_x = lerp(0.5, 10.0, 1.0, delta_t)
      star1.zoom_y = star1.zoom_x
      star2.angle  = lerp(0, 180, 1.0, delta_t)
      star2.zoom_x = lerp(1.0, 8.0, 1.0, delta_t)
      star2.zoom_y = star2.zoom_x
    end
    #---------------------------------------------------------------------------
    # Phase 2 of animation: Fade and slide trainers in, show VS clashes.
    player.visible = true
    trainer.visible = true
    vs1.visible = true
    vs2.visible = true
    foe_appear_time = 0.75
    vs_clash_count = 0
    vs_clash_time = foe_appear_time + 0.3
    vs_clash_speed = vs_clash_time / 4
    total_sec = vs_clash_time + (vs_clash_speed * 6)
    vs_pos = {
      0 => [
        vs1.x, vs1.y,                        # Starting "V" coords
        (width / 2) + 6, height / 2,         # Center "V" coords
        (width / 2) - 64, (height / 2) + 64, # Diagonal "V" coords
        (width / 2) - 94, 0                  # Horizontal "V" coords
      ],
      1 => [
        vs2.x, vs2.y,                         # Starting "S" coords
        (width / 2) + 60, height / 2,         # Center "S" coords
        (width / 2) + 124, (height / 2) - 64, # Diagonal "S" coords
        (width / 2) + 160, 0                  # Horizontal "S" coords
      ]
    }
    pbWait(total_sec) do |delta_t|
      #-------------------------------------------------------------------------
      # Animates the player trainer appearing on screen.
      bg1.opacity     = lerp(0, 255, total_sec / 7, delta_t)
      player.opacity  = lerp(0, 255, total_sec / 2, delta_t)
      player.y        = lerp(-32, 64, total_sec - 0.4, delta_t)
      #-------------------------------------------------------------------------
      # Animates the opponent trainer appearing on screen.
      if delta_t >= foe_appear_time
        bg2.opacity     = lerp(0, 255, total_sec / 7, delta_t - foe_appear_time)
        trainer.opacity = lerp(0, 255, total_sec / 2, delta_t - foe_appear_time)
        trainer.y       = lerp(64, 0, total_sec - 0.4, delta_t)
      end
      #-------------------------------------------------------------------------
      # Animates the "VS" icons clashing.
      dt = delta_t - vs_clash_time
      case vs_clash_count
      when 0 # VS meets in the center the first time.
        next if delta_t < vs_clash_time
        [vs1, vs2].each_with_index do |s, i|
          s.x = lerp(vs_pos[i][0], vs_pos[i][2], vs_clash_speed, dt)
          s.y = lerp(vs_pos[i][1], vs_pos[i][3], vs_clash_speed, dt)
        end
        if delta_t >= vs_clash_time + vs_clash_speed
          vs_clash_count += 1
          vs_clash_time += vs_clash_speed
          shine3.visible = true
          pbSEPlay("Vs sword")
        end
      when 1 # VS ricochet diagonally.
        shine3.visible = false if delta_t >= vs_clash_time + 0.1
        [vs1, vs2].each_with_index do |s, i|
          s.x = lerp(vs_pos[i][2], vs_pos[i][4], vs_clash_speed, dt)
          s.y = lerp(vs_pos[i][3], vs_pos[i][5], vs_clash_speed, dt)
        end
        if delta_t >= vs_clash_time + vs_clash_speed
          vs_clash_count += 1
          vs_clash_time += vs_clash_speed
        end
      when 2 # VS meets in the center a second time.
        [vs1, vs2].each_with_index do |s, i|
          s.x = lerp(vs_pos[i][4], vs_pos[i][2], vs_clash_speed, dt)
          s.y = lerp(vs_pos[i][5], vs_pos[i][3], vs_clash_speed, dt)
        end
        if delta_t >= vs_clash_time + vs_clash_speed
          vs_clash_count += 1
          vs_clash_time += vs_clash_speed
          shine3.visible = true
          pbSEPlay("Vs sword")
        end
      when 3 # VS ricochet horizontally.
        shine3.visible = false if delta_t >= vs_clash_time + 0.1
        [vs1, vs2].each_with_index do |s, i|
          s.x = lerp(vs_pos[i][2], vs_pos[i][6], vs_clash_speed, dt)
        end
        if delta_t >= vs_clash_time + vs_clash_speed
          vs_clash_count += 1
          vs_clash_time += vs_clash_speed
        end
      when 4 # VS meets in the center the final time.
        [vs1, vs2].each_with_index do |s, i|
          s.x = lerp(vs_pos[i][6], vs_pos[i][2], vs_clash_speed, dt)
        end
        if delta_t >= vs_clash_time + vs_clash_speed
          vs_clash_count += 1
          shine3.visible = true
        end
      else
        shine3.visible = false
      end
    end
    #---------------------------------------------------------------------------
    # White flash, show new background and elements.
    flash.opacity = 255
    pbSEPlay("Vs flash")
    pbSEPlay("Vs sword")
    star1.visible = false
    star2.visible = false
    bg1.visible = false
    bg2.visible = false
    bg.visible = true
    bar1.visible = true
    bar2.visible = true
    shine1.visible = true
    shine2.visible = true
    beam = AnimatedPlane.new(viewvs1)
    beam.bitmap = RPG::Cache.transition("champion_vsBeam")
    colors = [Color.new(248, 248, 248), Color.new(72, 72, 72)]
    textpos = [
      [$player.name, bg1.bitmap.width - 96, bar1.y + 12, :right, *colors],
      [foe[0].name, bg2.bitmap.width + 96, bar2.y - 32, :left, *colors]
    ]
    pbDrawTextPositions(overlay.bitmap, textpos)
    #---------------------------------------------------------------------------
    # Phase 3 of animation: Jitter trainers & VS; rotate background and other elements.
    trainer_pos = {
      0 => [player.x, player.y],
      1 => [trainer.x, trainer.y]
    }
    vs_pos = {
      0 => [vs1.x, vs1.y],
      1 => [vs2.x, vs2.y]
    }
    zoom_time = 2.5
    shudder_time = 1.75
    pbWait(2.8) do |delta_t|
      if delta_t <= shudder_time
        flash.opacity = lerp(255, 0, 0.25, delta_t)
      elsif delta_t >= zoom_time
        flash.tone = Tone.new(-255, -255, -255)
        flash.opacity = lerp(0, 255, 0.25, delta_t - zoom_time)
      end
      bg.angle = lerp(0, -90, 2.8, delta_t)
      shine1.angle = lerp(0, -180, 2.8, delta_t)
      shine2.angle = lerp(0, 180, 2.8, delta_t)
      beam.oy = lerp(0, beam.bitmap.height * 7, 2.8, delta_t)
      if delta_t <= shudder_time
        period = (delta_t / 0.025).to_i % 4
        shudder_delta = [2, 0, -2, 0][period]
        [player, trainer].each_with_index do |s, i|
          s.x = trainer_pos[i][0] + shudder_delta
          s.y = trainer_pos[i][1] - shudder_delta
        end
        [vs1, vs2].each_with_index do |s, i|
          s.x = vs_pos[i][0] - shudder_delta
          s.y = vs_pos[i][1] + shudder_delta
        end
      elsif delta_t <= zoom_time
        shine3.visible = true
        shine3.zoom_x = lerp(1.0, 10.0, zoom_time - shudder_time, delta_t - shudder_time)
        shine3.zoom_y = shine3.zoom_x
      end
    end
    #---------------------------------------------------------------------------
    # End of animation
    star1.dispose
    star2.dispose
    bg.dispose
    bg1.dispose
    bg2.dispose
    player.dispose
    trainer.dispose
    flash.dispose
    vs1.dispose
    vs2.dispose
    beam.dispose
    shine1.dispose
    shine2.dispose
    shine3.dispose
    bar1.dispose
    bar2.dispose
    overlay.dispose
    viewvs1.dispose
    viewvs2.dispose
    viewopp.dispose
    viewplayer.dispose
    viewport.color = Color.black
  }
)