#===============================================================================#
# Whether the options menu shows the speed up settings (true by default)
#===============================================================================#
module Settings
  SPEED_OPTIONS = true
end
#===============================================================================#
# Speed-up config
#===============================================================================#
SPEEDUP_STAGES = [1, 1.5, 2]
$GameSpeed = 0
$CanToggle = true
$RefreshEventsForTurbo = false
#===============================================================================#
# Set $CanToggle depending on the saved setting
#===============================================================================#
module Game
  class << self
    alias_method :original_load, :load unless method_defined?(:original_load)
  end

  def self.load(save_data)
    original_load(save_data)
          #echoln "UNSCALED #{System.unscaled_uptime} * #{SPEEDUP_STAGES[$GameSpeed]} - #{$GameSpeed}"
    $CanToggle = $PokemonSystem.only_speedup_battles == 0
  end
end
#===============================================================================#
# Handle incrementing speed stages if $CanToggle allows it
#===============================================================================#
module Input
  def self.update
    update_KGC_ScreenCapture
    pbScreenCapture if trigger?(Input::F8)
    if $CanToggle && trigger?(Input::AUX1)
      $GameSpeed += 1
      $GameSpeed = 0 if $GameSpeed >= SPEEDUP_STAGES.size
      $PokemonSystem.battle_speed = $GameSpeed if $PokemonSystem && $PokemonSystem.only_speedup_battles == 1
      $RefreshEventsForTurbo  = true
    end
  end
end
#===============================================================================#
# Return System.Uptime with a multiplier to create an alternative timeline
#===============================================================================#
module System
  class << self
    alias_method :unscaled_uptime, :uptime unless method_defined?(:unscaled_uptime)
  end

  def self.uptime
    return SPEEDUP_STAGES[$GameSpeed] * unscaled_uptime
  end
end
#===============================================================================#
# Event handlers for in-battle speed-up restrictions
#===============================================================================#
EventHandlers.add(:on_start_battle, :start_speedup, proc {
  $CanToggle = false
  $GameSpeed = $PokemonSystem.battle_speed if $PokemonSystem.only_speedup_battles == 1
})
EventHandlers.add(:on_end_battle, :stop_speedup, proc {
  $GameSpeed = 0 if $PokemonSystem.only_speedup_battles == 1
  $CanToggle = true if $PokemonSystem.only_speedup_battles == 0
})
#===============================================================================#
# Can only change speed in battle during command phase (prevents weird animation glitches)
#===============================================================================#
class Battle
  alias_method :original_pbCommandPhase, :pbCommandPhase unless method_defined?(:original_pbCommandPhase)
  def pbCommandPhase
    $CanToggle = true
    original_pbCommandPhase
    $CanToggle = false
  end
end
#===============================================================================#
# Fix for consecutive battle soft-lock glitch
#===============================================================================#
alias :original_pbBattleOnStepTaken :pbBattleOnStepTaken
def pbBattleOnStepTaken(repel_active)
  return if $game_temp.in_battle
  original_pbBattleOnStepTaken(repel_active)
end

class Game_Event < Game_Character
def pbGetInterpreter
  return @interpreter
end

def pbResetInterpreterWaitCount
  @interpreter.pbRefreshWaitCount if @interpreter && IsParallel
end

def IsParallel
  return @trigger == 4
end  
end  

class Interpreter
  def pbRefreshWaitCount
    @wait_count = 0
    @wait_start = System.uptime
  end  
end  

class Window_AdvancedTextPokemon < SpriteWindow_Base
  def pbResetWaitCounter
    @wait_timer_start = nil
    @waitcount = 0
    @display_last_updated = nil
  end  
end  

$CurrentMsgWindow = nil;
def pbMessage(message, commands = nil, cmdIfCancel = 0, skin = nil, defaultCmd = 0, &block)
  ret = 0
  msgwindow = pbCreateMessageWindow(nil, skin)
  $CurrentMsgWindow = msgwindow

  if commands
    ret = pbMessageDisplay(msgwindow, message, true,
                           proc { |msgwndw|
                             next Kernel.pbShowCommands(msgwndw, commands, cmdIfCancel, defaultCmd, &block)
                           }, &block)
  else
    pbMessageDisplay(msgwindow, message, &block)
  end
  pbDisposeMessageWindow(msgwindow)
  $CurrentMsgWindow = nil
  Input.update
  return ret
end

#===============================================================================#
# Fix for scrolling fog speed
#===============================================================================#
class Game_Map
  alias_method :original_update, :update unless method_defined?(:original_update)

  def update
    if $RefreshEventsForTurbo
      echoln "UNSCALED #{System.unscaled_uptime} * #{SPEEDUP_STAGES[$GameSpeed]} - #{$GameSpeed}"
      if $game_map&.events
        $game_map.events.each_value { |event| event.pbResetInterpreterWaitCount }
      end

      @scroll_timer_start = System.uptime/SPEEDUP_STAGES[SPEEDUP_STAGES.size-1] if (@scroll_distance_x || 0) != 0 || (@scroll_distance_y || 0) != 0

      $CurrentMsgWindow.pbResetWaitCounter if $game_temp.message_window_showing && $CurrentMsgWindow 

      $RefreshEventsForTurbo = false
    end

    temp_timer = @fog_scroll_last_update_timer
    @fog_scroll_last_update_timer = System.uptime # Don't scroll in the original update method
    original_update
    @fog_scroll_last_update_timer = temp_timer
    update_fog
  end

  def update_fog
    uptime_now = System.unscaled_uptime
    @fog_scroll_last_update_timer = uptime_now unless @fog_scroll_last_update_timer
    speedup_mult = $PokemonSystem.only_speedup_battles == 1 ? 1 : SPEEDUP_STAGES[$GameSpeed]
    scroll_mult = (uptime_now - @fog_scroll_last_update_timer) * 5 * speedup_mult
    @fog_ox -= @fog_sx * scroll_mult
    @fog_oy -= @fog_sy * scroll_mult
    @fog_scroll_last_update_timer = uptime_now
  end
end
#===============================================================================#
# Fix for animation index crash
#===============================================================================#
class SpriteAnimation
  def update_animation
    new_index = ((System.uptime - @_animation_timer_start) / @_animation_time_per_frame).to_i
    if new_index >= @_animation_duration
      dispose_animation
      return
    end
    quick_update = (@_animation_index == new_index)
    @_animation_index = new_index
    frame_index = @_animation_index
    current_frame = @_animation.frames[frame_index]
    unless current_frame
      dispose_animation
      return
    end
    cell_data   = current_frame.cell_data
    position    = @_animation.position
    animation_set_sprites(@_animation_sprites, cell_data, position, quick_update)
    return if quick_update
    @_animation.timings.each do |timing|
      next if timing.frame != frame_index
      animation_process_timing(timing, @_animation_hit)
    end
  end
end
#===============================================================================#
# PokemonSystem Accessors
#===============================================================================#
class PokemonSystem
  alias_method :original_initialize, :initialize unless method_defined?(:original_initialize)
  attr_accessor :only_speedup_battles
  attr_accessor :battle_speed

  def initialize
    original_initialize
    @only_speedup_battles = 0 # Speed up setting (0=always, 1=battle_only)
    @battle_speed = 0 # Depends on the SPEEDUP_STAGES array size
  end
end
#===============================================================================#
# Options menu handlers
#===============================================================================#
MenuHandlers.add(:options_menu, :only_speedup_battles, {
  "name" => _INTL("加速设置"),
  "order" => 25,
  "type" => EnumOption,
  "parameters" => [_INTL("永久"), _INTL("仅限战斗")],
  "description" => _INTL("选择一个加速速度/"),
  "get_proc" => proc { next $PokemonSystem.only_speedup_battles },
  "set_proc" => proc { |value, scene|
    $GameSpeed = 0 if value != $PokemonSystem.only_speedup_battles
    $PokemonSystem.only_speedup_battles = value
    $CanToggle = value == 0
  }
})
MenuHandlers.add(:options_menu, :battle_speed, {
  "name" => _INTL("战斗速度"),
  "order" => 26,
  "type" => EnumOption,
  "parameters" => [_INTL("x#{SPEEDUP_STAGES[0]}"), _INTL("x#{SPEEDUP_STAGES[1]}"), _INTL("x#{SPEEDUP_STAGES[2]}")],
  "description" => _INTL("如果你选了战斗加速而已\n请选择一个速度"),
  "get_proc" => proc { next $PokemonSystem.battle_speed },
  "set_proc" => proc { |value, scene|
    $PokemonSystem.battle_speed = value
  }
})