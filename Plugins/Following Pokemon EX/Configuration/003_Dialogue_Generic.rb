#-------------------------------------------------------------------------------
# These are used to define what the Follower will say when spoken to in general
#这里定义了，在没有什么条件的时候与跟随精灵对话，会发生什么，有些对话会带表情。
#----翻译BY:IFRIT-------------------------------------------------------------------

#-------------------------------------------------------------------------------
# All dialogues with the Music Note animation 音乐表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :music_generic, proc { |pkmn, random_val|
  if random_val == 0
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_MUSIC)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 看起来很想和 {2} 玩。"),
      _INTL("{1} 在哼哼。"),
      _INTL("{1} 抬头看着 {2} 露出开心的表情。"),
      _INTL("{1} 随心所欲地扭来扭去。"),
      _INTL("{1} 无忧无虑地跳来跳去！"),
      _INTL("{1} 炫耀地跑来跑去，应该是想展示它的敏捷与灵活。"),
      _INTL("{1} 欢快地走来走去！"),
      _INTL("哇哦! {1} 突然高兴得手舞足蹈起来！"),
      _INTL("{1} 紧紧的跟着 {2}!"),
      _INTL("{1} 欢脱地跳来跳去。"),
      _INTL("{1} 在嗅着脏脏的地面。"),
      _INTL("{1} 在闻 {2} 的鞋子!"),
      _INTL("{1} 飞快地赶上了 {2}。"),
      _INTL("{1} 围着 {2} 转来转去。"),
      _INTL("{1} 很卖力地展示其强大的力量！"),
      _INTL("{1} 看起来想溜出去玩！"),
      _INTL("{1} 正在到处闲逛，欣赏风景。"),
      _INTL("{1} 似乎还有点乐在其中！"),
      _INTL("{1} 十分欢快！"),
      _INTL("{1} 似乎在哼着什么？"),
      _INTL("{1} 正在跳着欢快的吉格舞！!"),
      _INTL("{1} 高兴极了，甚至开始唱歌了！"),
      _INTL("{1} 看起来对舞蹈很积极。"),
      _INTL("看起来 {1} 想要跳舞!"),
      _INTL("{1} 突然开始唱歌了！它似乎感觉很好！"),
      _INTL("看起来 {1} 想要和 {2} 一起跳舞!"),
	  _INTL("{1} 想要和 {2} 一起唱歌!")
    ]
    value = rand(messages.length)
    case value
    # Special move route to go along with some of the dialogue
	#有些对话会有不同的动作，但我不是机翻的，所以有概率出现动作与对话不符。
    when 3, 9
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 80])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 4, 5
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 6, 17
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP
      ])
    when 7, 28
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 60])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 21, 22
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 50])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Angry animation 生气表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :angry_generic, proc { |pkmn, random_val|
  if random_val == 1
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ANGRY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 不耐烦地吼叫!"),
      _INTL("{1} 看起来不太高兴!"),
      _INTL("{1} 似乎因为什么东西而不高兴。"),
      _INTL("{1} 在咬着 {2} 的鞋子。"),
      _INTL("{1} 转过身去，你看不到它的表情。"),
      _INTL("{1} 恶狠狠地盯着 {2} 的敌人!"),
      _INTL("{1} 想找个倒霉蛋打一架!"),
      _INTL("{1} 准备好进行战斗了!"),
      _INTL("{1} 的眼神？似乎要对每一个路过的人使出连环巴掌！"),
      _INTL("{1} 在强烈地谴责与反抗！就像在说How dare u!？"),
	  _INTL("{1} 嘟着嘴！很气！"),
	  _INTL("{1} 火冒三丈！")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 6, 7, 8
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 25])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Neutral Animation 自然表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :ellipses_generic, proc { |pkmn, random_val|
  if random_val == 2
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_ELIPSES)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 低着头，不知道在看什么。"),
      _INTL("{1} 正在四处嗅探。"),
      _INTL("{1} 正在全神贯注......地发呆。"),
      _INTL("{1} 对着 {2} and 点了点头。"),
      _INTL("{1} 正直勾勾地盯着 {2} 的眼睛。"),
      _INTL("{1} 正在勘测该区域。"),
      _INTL("{1} 目光炯炯，锐利如锋!"),
      _INTL("{1} 正心不在焉地四处张望。"),
      _INTL("{1} 打了个很大的哈欠！"),
      _INTL("{1} 正在休息。"),
      _INTL("{1} 全神贯注地盯着 {2}。"),
      _INTL("{1} 正目不转睛地盯着什么。"),
	  _INTL("{1} 正目不转睛地盯空无一物的地方。"),
      _INTL("{1} 正在集中精力，不然要睡着了。"),
      _INTL("{1} 盯着 {2} 的脚印。"),
      _INTL("{1} 看起来好像想和 {2} 一起玩儿。"),
      _INTL("{1} 似乎在模仿思考者。"),
      _INTL("{1} 没有注意到 {2}...好像在思考着什么。"),
      _INTL("{1} 看起来很严肃的样子，但是好像要装不下去了。"),
      _INTL("{1} 无精打采的。"),
      _INTL("{1} 似乎心不在焉的。"),
      _INTL("{1} 似乎是在侦查周围环境，而没有在乎 {2} 的呼唤。"),
      _INTL("{1} 看起来百无聊赖。"),
      _INTL("{1} 的脸上露出紧张的神情。"),
      _INTL("{1} 正凝视着深渊。"),
      _INTL("{1} 似乎在仔细揣测 {2} 的心情。"),
      _INTL("{1} 似乎试图与你进行眼神交流。"),
      _INTL("... {1} 打了个喷嚏。"),
      _INTL("... {1} 注意到 {2} 的鞋子有点脏。"),
      _INTL("{1} 的脸扭曲成一团了！难道是刚刚吃的红蘑菇？"),
      _INTL("{1} 在津津有味地嚼着什么东西。"),
      _INTL("{1} 似乎注意到 {2} 的背包上有什么东西，便虚心地转过头去。"),
      _INTL("...... ...... ...... ...... ...... ...... ...... ...... ...... ...... ...... {1} 故作深沉地点了点头。")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 1, 5, 7, 20, 21
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 35])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Happy animation 高兴表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :happy_generic, proc { |pkmn, random_val|
  if random_val == 3
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HAPPY)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 戳了戳 {2}。"),
      _INTL("{1} 看起来心情不错。"),
      _INTL("{1} 满脸幸福地偎依着 {2}。"),
      _INTL("{1} 高兴得没办法停下来。"),
      _INTL("噢？{1} 看起来想当旗帜宝可梦。"),
      _INTL("{1} 这一路都挺开心的。"),
      _INTL("{1} 似乎很喜欢和 {2} 一起散步!"),
      _INTL("{1} 正在茁壮成长。"),
      _INTL("{1} 似乎很兴奋。"),
      _INTL("{1} 为了 {2} 在刻苦训练。"),
      _INTL("{1} 在仔细闻着空气中的味道。"),
      _INTL("{1} 欢欣雀跃起来!"),
      _INTL("{1} 仍然感觉良好!"),
      _INTL("{1} 伸展着自己的身体。"),
      _INTL("{1} 正在全力追赶 {2}。"),
      _INTL("{1} 开心地搂着 {2}!"),
      _INTL("{1} 看起来精神饱满!"),
      _INTL("{1} 高兴得快晕过去了!"),
      _INTL("{1} 正在四处游荡，似乎有我们听不到的声音。"),
      _INTL("{1} 给了 {2} 一个意味深长的眼神。"),
      _INTL("{1} 正在粗重地呼吸！"),
      _INTL("{1} 激动地颤抖着!"),
      _INTL("{1} 开心地打滚。"),
      _INTL("{1} 很高兴能得到 {2} 的关注。"),
      _INTL("{1} 似乎在暗自窃喜 {2} 没有注意到!"),
      _INTL("{1} 开始兴奋地扭动全身!"),
      _INTL("{1} 开始兴奋地扭动全身!"),
      _INTL("{1} 在悄悄地接近 {2} 的脚指头。")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 3
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 45])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    when 11, 16, 17, 24
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 40])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with the Heart animation 爱心表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :heart_generic, proc { |pkmn, random_val|
  if random_val == 4
    FollowingPkmn.animation(FollowingPkmn::ANIMATION_EMOTE_HEART)
    pbMoveRoute($game_player, [PBMoveRoute::WAIT, 20])
    messages = [
      _INTL("{1} 突然开始走近 {2}。"),
      _INTL("哇哦! {1} 突然抱住了 {2}。"),
      _INTL("{1} 用脸颊狠狠地摩擦着 {2}。"),
      _INTL("{1} 正密切关注着 {2}。"),
      _INTL("{1} 扭扭捏捏的。"),
      _INTL("{1} 想要一直陪着 {2}!"),
      _INTL("{1} 忽然嬉戏起来!"),
      _INTL("{1} 摩擦着 {2} 的腿!"),
      _INTL("{1} 看向 {2} 的眼神充满了崇拜!"),
      _INTL("{1} 似乎想要 {2} 给出什么反应。"),
      _INTL("{1} 想要从 {2} 那里得到关注。"),
      _INTL("{1} 很高兴能和 {2} 一起旅行。"),
      _INTL("{1} 似乎对 {2} 充满好感。"),
      _INTL("{1} 对 {2} 的眼神充满爱意。"),
      _INTL("{1} 看起来很想要 {2} 给点零食。"),
      _INTL("{1} 看起来很想要 {2} 摸摸它!"),
      _INTL("{1} 亲昵地摩擦着 {2}。"),
      _INTL("{1} 用头轻轻地蹭着 {2} 的手。"),
      _INTL("{1} 翻了个身，满眼期待地看着 {2}。"),
      _INTL("{1} 满怀期待地看着 {2}。"),
      _INTL("{1} 似乎在乞求着 {2}!"),
      _INTL("{1} 在模仿着 {2}!"),
	  _INTL("{1} 似乎很喜欢 {2}!"),
	  _INTL("{1} 的脸很红!"),
	  _INTL("{1} 的眼神？")
    ]
    value = rand(messages.length)
    case value
    when 1, 6,
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 10])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
# All dialogues with no animation 没有表情
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_talk, :generic,  proc { |pkmn, random_val|
  if random_val == 5
    messages = [
      _INTL("{1} 转了一圈又一圈！"),
      _INTL("{1} 发出了战斗的呐喊。"),
      _INTL("{1} 在寻找着什么。"),
      _INTL("{1} 安静地跟着你。"),
      _INTL("{1} 正焦躁不安地四处张望。"),
      _INTL("{1} 正在四处游荡。"),
      _INTL("{1} 在大吼大叫!"),
      _INTL("{1} 在 {2} 的脚边绕来绕去。"),
      _INTL("{1} 对着 {2} 笑了笑。"),
      _INTL("{1} 正目不转睛地盯着远方。"),
      _INTL("{1} 一下子就追上了 {2}。"),
      _INTL("{1} 看起来怡然自得。"),
      _INTL("{1} 正在逐渐成长!"),
      _INTL("{1} 对 {2} 使用了同步。啊！同手同脚了。"),
      _INTL("{1} 开始转啊转啊转啊转啊转啊转啊转啊转啊转啊转啊转啊。"),
      _INTL("{1} 看向 {2} 的眼神带着别样的期待。"),
      _INTL("{1} 平地摔了！嗯？{1} 尴尬得使出了挖洞？"),
      _INTL("{1} 想要看看 {2} 会做什么。"),
      _INTL("{1} 正在静观 {2} 的奇怪动作。"),
      _INTL("{1} 似乎想要从 {2} 那儿得到什么。"),
      _INTL("{1} 原地不动, 等待着 {2} 的指令。"),
      _INTL("{1} 十分自然地坐在了 {2} 的脚边。"),
      _INTL("{1} 被吓了一跳!"),
      _INTL("{1} 被 {2} 的鬼脸吓到了！现在在生气中!")
    ]
    value = rand(messages.length)
    # Special move route to go along with some of the dialogue
    case value
    when 0
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 15])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN
      ])
    when 2, 4
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 35])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 10,
        PBMoveRoute::TURN_DOWN
      ])
    when 14
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 50])
      FollowingPkmn.move_route([
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_RIGHT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_UP,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_LEFT,
        PBMoveRoute::WAIT, 4,
        PBMoveRoute::TURN_DOWN
      ])
    when 22, 23
      pbMoveRoute($game_player, [PBMoveRoute::WAIT, 10])
      FollowingPkmn.move_route([
        PBMoveRoute::JUMP, 0, 0
      ])
    end
    pbMessage(_INTL(messages[value], pkmn.name, $player.name))
    next true
  end
})
#-------------------------------------------------------------------------------
