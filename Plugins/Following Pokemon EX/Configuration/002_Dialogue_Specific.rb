#不同条件下的对话-------------------------------------
# 在map_metadata里面有一个FLAG的信息，如果不设置这个FLAG那这一页基本等于没有。
#----翻译BY:IFRIT-------------------------------------------------------------------

#-------------------------------------------------------------------------------
# Amie Compatibility
#-------------------------------------------------------------------------------
if defined?(PkmnAR)
  EventHandlers.add(:following_pkmn_talk, :amie, proc { |_pkmn, _random_val|
    cmd = pbMessage(_INTL("你想做什么？"), [
      _INTL("陪ta玩耍"),
      _INTL("试图交流"),
      _INTL("什么都不做")
    ])
    PkmnAR.show if cmd == 0
    next true if [0, 2].include?(cmd)
  })
end
#-------------------------------------------------------------------------------
# Special Dialogue when statused 状态类对话
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :status, proc { |pkmn, _random_val|
  case pkmn.status
  when :POISON
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_POISON)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} 因为中毒，浑身都在发抖。", pkmn.name))
  when :BURN
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} 的烧伤看起来很严重。", pkmn.name))
  when :FROZEN
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} 非常冷，冻得像石头一样！", pkmn.name))
  when :SLEEP
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} 在梦游！", pkmn.name))
  when :PARALYSIS
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    pbMessage(_INTL("{1} 一动不动，抽搐不已。", pkmn.name))
  end
  next true if pkmn.status != :NONE
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Pokemon Lab metadata flag 在大木研究室等
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :pokemon_lab, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("PokemonLab")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
	_INTL("{1} 一直在上下拨动某种开关！"),
      _INTL("{1} 咬断了一根数据线！"),
      _INTL("{1} 一直在盯着奇怪的机器。"),
	  _INTL("{1} 似乎对奇怪的机器抱有敌意。"),
	  _INTL("{1} 似乎对奇怪的机器很感兴趣。")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map name has the players name in it like the
# Player's House 在玩家的房子 可能是这样的 \PN's House 
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :player_house, proc { |pkmn, _random_val|
  if $game_map.name.include?($player.name)
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 在家里嗅来嗅去。"),
      _INTL("{1} 注意到 {2} 的妈妈在悄悄靠近。"),
      _INTL("{1} 赖在家里不愿意出去了！"),
	  _INTL("{1} 在家里滚来滚去。"),
	  _INTL("{1} 在拨弄自己的饭碗。"),
	  _INTL("{1} 躺在了地板上。")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has Pokecenter metadata flag 在宝可梦中心
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :pokemon_center, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("PokeCenter")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
	_INTL("{1} 见到乔伊小姐特别高兴。"),
      _INTL("{1} 赖在这里不想走了。"),
      _INTL("{1} 对治疗机很着迷。"),
      _INTL("{1} 看起来想打个盹。"),
      _INTL("{1} 想要舔一舔乔伊小姐的脸。"),
      _INTL("{1} 饶有趣味地看着 {2} 。"),
      _INTL("{1} 在这里非常自在！"),
      _INTL("{1} 找到了一个舒服的角落。"),
      _INTL("{1} 的脸上露出了满足的表情。")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Gym metadata flag 在道馆
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :gym, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("GymMap")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 渴望着战斗！"),
      _INTL("{1} 目不转睛地盯着 {2} ，眼中闪烁着坚定的光芒。"),
      _INTL("{1} 在试图恐吓其他的训练家。"),
      _INTL("{1} 相信 {2} 会制定必胜的策略。"),
      _INTL("{1} 恶狠狠地盯着道馆主。"),
      _INTL("{1} 甚至想要随便找只宝可梦进行对战！"),
      _INTL("{1} 看起来正在准备一场世纪大决战！"),
      _INTL("{1} 想进行对战以炫耀自己的强大！"),
      _INTL("{1} ...在做...七彩阳光？！"),
      _INTL("{1} 在低声咆哮...")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Storm. Pokemon of different types
# have different reactions to the weather. 在暴雨天，雷雨天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :storm_weather, proc { |pkmn, _random_val|
  if :Storm == $game_screen.weather_type
    if pkmn.hasType?(:ELECTRIC)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 正仰望着天空。"),
        _INTL("风暴似乎使得 {1} 更加兴奋。"),
        _INTL("{1} 仰望天空，在大吼大叫！"),
        _INTL("雷暴雨似乎让 {1} 更加有活力了!"),
        _INTL("{1} 非常有活力地转圈圈！"),
        _INTL("闪电根本影响不了 {1} 。")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 想要使用引雷！还好它不是电系宝可梦。"),
        _INTL("风暴似乎使得 {1} 有些焦虑。"),
        _INTL("噢！闪电吓到 {1} 了!"),
        _INTL("狂风骤雨根本拦不住 {1} 。"),
        _INTL("糟糕的天气让 {1} 有点紧张。"),
        _INTL("{1} 被闪电吓了一跳，紧紧依偎着 {2}!")
		]   
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Snowy. Pokemon of different types
# have different reactions to the weather. 在下雪天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :snow_weather, proc { |pkmn, _random_val|
  if :Snow == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 看着雪花飘飘。"),
        _INTL("{1} 被大雪埋住了！"),
        _INTL("{1} 沉浸在飘雪中。"),
        _INTL("{1} 好像很喜欢下雪。"),
        _INTL("{1} 因为很喜欢下雪，而跑来跑去。")
		
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 看着雪花飘飘。"),
        _INTL("{1} 想要舔到飘落的雪花。"),
        _INTL("噢不！地上的积雪被 {1} 的嘴收集起来了。。"),
        _INTL("{1} 被雪迷住了。"),
        _INTL("{1} 的牙齿在打颤！"),
        _INTL("{1} 的身体蜷缩在一起...")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Blizzard. Pokemon of different types
# have different reactions to the weather. 在暴风雪，冰雹天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :blizzard_weather, proc { |pkmn, _random_val|
  if :Blizzard == $game_screen.weather_type
    if pkmn.hasType?(:ICE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 正看着冰雹落下。"),
        _INTL("{1} 一点也不怕冰雹。"),
        _INTL("{1} 想用嘴接住冰雹。"),
        _INTL("{1} 居然对冰雹很感兴趣？"),
        _INTL("{1} 正在啃一块冰雹？？冰鬼护！")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 被冰雹砸疼了，想要回到球里！"),
        _INTL("{1} 正在左右横跳以躲避冰雹。"),
        _INTL("{1} 被冰雹砸疼了，在吼叫着！"),
        _INTL("{1} 看起来特别不高兴！"),
        _INTL("{1} 抖掉了身上的雪。")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Sandstorm. Pokemon of different types
# have different reactions to the weather. 在沙暴天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :sandstorm_weather, proc { |pkmn, _random_val|
  if :Sandstorm == $game_screen.weather_type
    if [:ROCK, :GROUND].any? { |type| pkmn.hasType?(type) }
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 在沙子里滚来滚去。"),
        _INTL("{1} 甚至想在沙暴里面玩。"),
        _INTL("{1} 完全没有被沙暴拖住脚步!"),
        _INTL("{1} 非常喜欢沙暴！")
      ]
    elsif pkmn.hasType?(:STEEL)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 想在沙子里滚来滚去。"),
        _INTL("{1} 完全没有被沙暴影响到!"),
        _INTL("{1} 完全没有被沙暴拖住脚步!"),
        _INTL("{1} 根本不在乎沙暴")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 满嘴都是沙子..."),
		_INTL("{1} 糊了一嘴沙子..."),
        _INTL("{1} 吐出一口沙子！"),
        _INTL("{1} 在沙尘暴中眯着眼睛。"),
        _INTL("{1} 很不喜欢沙暴天气。")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has the Forest metadata flag 在树林地图
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :forest_map, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("Forest")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_MUSIC)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    if [:BUG, :GRASS].any? { |type| pkmn.hasType?(type) }
      messages = [
        _INTL("{1} 似乎对森林非常感兴趣。"),
        _INTL("{1} 似乎很享受虫系宝可梦发出的嗡嗡声。"),
        _INTL("{1} 在森林里跳来跳去。")
      ]
    else
      messages = [
        _INTL("{1} 似乎对每一个树洞都非常感兴趣。"),
        _INTL("{1} 似乎很享受虫系宝可梦发出的嗡嗡声。"),
        _INTL("{1} 想要使用居合斩！"),
        _INTL("{1} 在四处游玩，聆听森林不同的声音。"),
        _INTL("{1} 正在啃草。"),
        _INTL("{1} 正在四处闲逛，欣赏森林美景。"),
        _INTL("{1} 差点啃到了走路草。"),
        _INTL("{1} 正在研究丁达尔效应......"),
        _INTL("{1} 跳起来，想够到一片树叶。"),
        _INTL("{1} 似乎在倾听树叶沙沙作响的声音。"),
        _INTL("你根本叫不动 {1} 。因为它是一棵树..."),
        _INTL("{1} 被树枝绊倒了，这树枝真没树枝！"),
        _INTL(" {1} 在寻找假装成树的胡说树。 ")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Rainy. Pokemon of different types
# have different reactions to the weather. 在雨天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :rainy_weather, proc { |pkmn, _random_val|
  if [:Rain, :HeavyRain].include?($game_screen.weather_type)
    if pkmn.hasType?(:FIRE) || pkmn.hasType?(:GROUND) || pkmn.hasType?(:ROCK)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 不太喜欢下雨天。"),
        _INTL("{1} 冷得发抖..."),
        _INTL("{1} 不喜欢被打湿的感觉。"),
        _INTL("{1} 正在甩干自己。"),
        _INTL("{1} 浑身湿漉漉地贴在 {2} 身上。"),
        _INTL("{1} 看着满地的水塘，皱着眉头。"),
        _INTL("{1} 被水塘围住了！")
      ]
    elsif pkmn.hasType?(:WATER) || pkmn.hasType?(:GRASS)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 非常喜欢下雨天。"),
        _INTL("{1} 正在利用大雨滋润身体。"),
        _INTL("{1} 因为下雨了，而特别兴奋。"),
        _INTL("{1} 对着 {2} 开心地笑着!"),
        _INTL("{1} 一直盯着漫天的乌云。"),
        _INTL("雨滴打在 {1} 身上。"),
        _INTL("{1} 看到下雨，高兴得合不拢嘴。")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 盯着黑黑的天空。"),
        _INTL("{1} 因为下雨了，而有些惊讶。"),
        _INTL("{1} 正在甩干自己。"),
        _INTL("暴雨似乎没能影响到 {1} 。"),
        _INTL("{1} 在水塘里打滚!"),
        _INTL("{1} 在模仿溜溜糖球！摔倒了.....")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message if the map has Beach metadata flag 在沙滩
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :beach_map, proc { |pkmn, _random_val|
  if $game_map.metadata&.has_flag?("Beach")
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 似乎在欣赏风景。"),
      _INTL("{1} 似乎很享受海浪拍打沙滩的声音。"),
      _INTL("{1} 看起来特别想游泳！"),
	  _INTL("{1} 完全不听你的话！已经冲进海浪里了！"),
      _INTL("{1} 对着海洋使用了锐利目光。"),
      _INTL("{1} 正痴痴地凝视着海洋。"),
      _INTL("{1} 一直试图把 {2} 推进水里。"),
      _INTL("{1} 兴奋地看着大海！"),
      _INTL("{1} 兴奋地看着海浪！"),
      _INTL("{1} 在沙滩上游来游去!"),
      _INTL("{1} 的每一步都踩在 {2} 在沙滩留下的脚印上。 "),
      _INTL("{1} 在沙滩上使用了滚动。")
    ]
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# Specific message when the weather is Sunny. Pokemon of different types
# have different reactions to the weather. 在烈阳天
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :sunny_weather, proc { |pkmn, _random_val|
  if :Sun == $game_screen.weather_type
    if pkmn.hasType?(:GRASS)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 似乎很高兴能在阳光下活动。"),
        _INTL("{1} 正在享受日光浴。"),
		_INTL("{1} 使用了光合作用。"),
        _INTL("{1} 甚至能在这么刺眼的阳光下睁开眼睛。"),
        _INTL("{1} 将一团团烟圈似的孢子云送入空中！"),
        _INTL("{1} 伸展着可能有的藤蔓，悠闲地晒着阳光。"),
        _INTL("{1} 散发着氤氲花香。")
      ]
    elsif pkmn.hasType?(:FIRE)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 似乎在说：天气好！散步一起吧。"),
        _INTL("{1} 似乎觉得40℃不太暖和。"),
        _INTL("{1} 看起来很喜欢大晴天！"),
        _INTL("{1} 在吐火球玩。"),
        _INTL("{1} 在使用喷射火焰！！"),
        _INTL("{1} 欢快的样子，让你想起了火之高兴。")
      ]
    elsif pkmn.hasType?(:DARK)
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 只想躲在你的影子里。"),
        _INTL("{1} 似乎很讨厌大太阳。"),
        _INTL("{1} 非常困扰于烈阳天。"),
        _INTL("{1} 看起来心情很坏。"),
        _INTL("{1} 很想钻进精灵球里。"),
        _INTL("{1} 在不断寻找哪里有能躲避阳光的树荫。")
      ]
    else
      FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
      messages = [
        _INTL("{1} 在明媚的阳光下眯着眼睛。"),
        _INTL("{1} 的水分好像要被蒸发掉了。"),
        _INTL("{1} 不太喜欢烈阳天。"),
        _INTL("{1} 好像有些晕晕？{1} 中暑了！"),
        _INTL("{1} 在往外冒水蒸汽！"),
        _INTL("{1} 没有理你，因为 {1} 根本没有睁开眼！")
      ]
    end
    pbMessage(_INTL(messages.sample, pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
