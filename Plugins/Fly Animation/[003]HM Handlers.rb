HiddenMoveHandlers::UseMove.add(:FLY,proc { |move, pokemon|
   if $game_temp.fly_destination.nil?
  pbMessage(_INTL("You can't use that here."))
    next false
  end
  if !pbHiddenMoveAnimation(pokemon)
    name = pokemon&.name || $player.name 
    move = :FLY
    pbMessage(_INTL("{1} used {2}!", name, GameData::Move.get(move).name))
  end
  $stats.fly_count += 1
  pbFlyAnimation
  pbFadeOutIn {
    $game_temp.player_new_map_id    = $game_temp.fly_destination[0]
    $game_temp.player_new_x         = $game_temp.fly_destination[1]
    $game_temp.player_new_y         = $game_temp.fly_destination[2]
    $game_temp.player_new_direction = 2
    $game_temp.fly_destination = nil
    $scene.transfer_player
    $game_map.autoplay
    $game_map.refresh
  }
  pbFlyAnimation(false)
  pbEraseEscapePoint
  next true
})
