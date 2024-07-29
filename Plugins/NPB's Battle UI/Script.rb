class Battle::Scene
  MESSAGE_BASE_COLOR   = Color.new(0, 0, 0)
  MESSAGE_SHADOW_COLOR = Color.new(160, 160, 168)
end

class Battle::Scene::MenuBase
  TEXT_BASE_COLOR   = Battle::Scene::MESSAGE_BASE_COLOR
  TEXT_SHADOW_COLOR = Color.new(160, 160, 168,50)
end

class Battle::Scene::FightMenu < Battle::Scene::MenuBase
  attr_reader :battler
  attr_reader :shiftMode

  GET_MOVE_TEXT_COLOR_FROM_MOVE_BUTTON = false
end

class Battle::Scene::PokemonDataBox < BitmapWrapper
  def draw_shiny_icon
    return if !@battler.shiny?
    shiny_x = (@battler.opposes?(0)) ? 206 : -6   # Foe's/player's
    pbDrawImagePositions(self.bitmap, [["Graphics/UI/shiny", @spriteBaseX + shiny_x, 44]])
  end
end
    
class PokemonTrainerCard_Scene
  def pbDrawTrainerCardFront
    overlay = @sprites["overlay"].bitmap
    overlay.clear
    baseColor   = Color.new(255, 255, 255)
    shadowColor = Color.new(160, 160, 160)
    totalsec = $stats.play_time.to_i
    hour = totalsec / 60 / 60
    min = totalsec / 60 % 60
    time = (hour > 0) ? _INTL("{1}h {2}m", hour, min) : _INTL("{1}m", min)
    $PokemonGlobal.startTime = pbGetTimeNow if !$PokemonGlobal.startTime
    starttime = _INTL("{1} {2}, {3}",
                      pbGetAbbrevMonthName($PokemonGlobal.startTime.mon),
                      $PokemonGlobal.startTime.day,
                      $PokemonGlobal.startTime.year)
    textPositions = [
      [_INTL("Name"), 34, 70, 0, baseColor, shadowColor],
      [$player.name, 302, 70, 1, baseColor, shadowColor],
      [_INTL("ID No."), 332, 70, 0, baseColor, shadowColor],
      [sprintf("%05d", $player.public_ID), 468, 70, 1, baseColor, shadowColor],
      [_INTL("Money"), 34, 118, 0, baseColor, shadowColor],
      [_INTL("${1}", $player.money.to_s_formatted), 302, 118, 1, baseColor, shadowColor],
      [_INTL("Pokédex"), 34, 166, 0, baseColor, shadowColor],
      [sprintf("%d/%d", $player.pokedex.owned_count, $player.pokedex.seen_count), 302, 166, 1, baseColor, shadowColor],
      [_INTL("Time"), 34, 214, 0, baseColor, shadowColor],
      [time, 302, 214, 1, baseColor, shadowColor],
      [_INTL("Started"), 34, 262, 0, baseColor, shadowColor],
      [starttime, 302, 262, 1, baseColor, shadowColor]
    ]
    pbDrawTextPositions(overlay, textPositions)
    x = 72
    region = pbGetCurrentRegion(0) # Get the current region
    imagePositions = []
    8.times do |i|
      if $player.badges[i + (region * 8)]
        imagePositions.push(["Graphics/UI/Trainer Card/icon_badges", x, 310, i * 32, region * 32, 32, 32])
      end
      x += 48
    end
    pbDrawImagePositions(overlay, imagePositions)
  end
end

class Battle::Scene::PokemonDataBox < Sprite
  STATUS_ICON_HEIGHT = 24
  end