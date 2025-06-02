module GameData
  class MapMetadata
    attr_reader :id
    attr_reader :real_name
    attr_reader :outdoor_map
    attr_reader :announce_location
    attr_reader :can_bicycle
    attr_reader :always_bicycle
    attr_reader :teleport_destination
    attr_reader :weather
    attr_reader :town_map_position
    attr_reader :dive_map_id
    attr_reader :dark_map
    attr_reader :safari_map
    attr_reader :snap_edges
    attr_reader :still_reflections
    attr_reader :random_dungeon
    attr_reader :battle_background
    attr_reader :wild_battle_BGM
    attr_reader :trainer_battle_BGM
    attr_reader :wild_victory_BGM
    attr_reader :trainer_victory_BGM
    attr_reader :wild_capture_ME
    attr_reader :town_map_size
    attr_reader :battle_environment
    attr_reader :flags
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "map_metadata.dat"
    PBS_BASE_FILENAME = "map_metadata"

    SCHEMA = {
      "SectionName"       => [:id,                   "u"],
      "Name"              => [:real_name,            "s"],
      "Outdoor"           => [:outdoor_map,          "b"],
      "ShowArea"          => [:announce_location,    "b"],
      "Bicycle"           => [:can_bicycle,          "b"],
      "BicycleAlways"     => [:always_bicycle,       "b"],
      "HealingSpot"       => [:teleport_destination, "vuu"],
      "Weather"           => [:weather,              "eu", :Weather],
      "MapPosition"       => [:town_map_position,    "uuu"],
      "DiveMap"           => [:dive_map_id,          "v"],
      "DarkMap"           => [:dark_map,             "b"],
      "SafariMap"         => [:safari_map,           "b"],
      "SnapEdges"         => [:snap_edges,           "b"],
      "StillReflections"  => [:still_reflections,    "b"],
      "Dungeon"           => [:random_dungeon,       "b"],
      "BattleBack"        => [:battle_background,    "s"],
      "WildBattleBGM"     => [:wild_battle_BGM,      "s"],
      "TrainerBattleBGM"  => [:trainer_battle_BGM,   "s"],
      "WildVictoryBGM"    => [:wild_victory_BGM,     "s"],
      "TrainerVictoryBGM" => [:trainer_victory_BGM,  "s"],
      "WildCaptureME"     => [:wild_capture_ME,      "s"],
      "MapSize"           => [:town_map_size,        "us"],
      "Environment"       => [:battle_environment,   "e", :Environment],
      "Flags"             => [:flags,                "*s"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["ID",                ReadOnlyProperty,        _INTL("此地图的ID编号。")],
        ["Name",              StringProperty,          _INTL("玩家看到的地图名称 。可以与RMXP中 的地图名称不同。")],
        ["Outdoor",           BooleanProperty,         _INTL("如果为true，则 此地图为室外地图， 会根据一天中的时间 着色。")],
        ["ShowArea",          BooleanProperty,         _INTL("如果为true，进 入地图时会显示地图 的名称。")],
        ["Bicycle",           BooleanProperty,         _INTL("如果为true，可 以在此地图上使用自 行车。")],
        ["BicycleAlways",     BooleanProperty,         _INTL("如果为true，进 入此地图时会自动骑 上自行车，并且不能 下车。")],
        ["HealingSpot",       MapCoordsProperty,       _INTL("此宝可梦中心的城镇 地图ID，以及 X/Y坐标。")],
        ["Weather",           WeatherEffectProperty,   _INTL("此地图的天气。")],
        ["MapPosition",       RegionMapCoordsProperty, _INTL("标记此地图在地区地 图上的位置。")],
        ["DiveMap",           MapProperty,             _INTL("指定此地图的水下区 域。当此地图有深水 时使用。")],
        ["DarkMap",           BooleanProperty,         _INTL("如果为true，此 地图是黑暗的，玩家 周围会出现一个光圈 。可以使用闪光来扩 大光圈。")],
        ["SafariMap",         BooleanProperty,         _INTL("如果为true，此 地图是狩猎区的一部 分（包括室内和室外 ）。不要在接待处使 用。")],
        ["SnapEdges",         BooleanProperty,         _INTL("如果为true，当 玩家靠近此地图边缘 时，游戏不会将玩家 居中。")],
        ["StillReflections",  BooleanProperty,         _INTL("如果为true，事 件和玩家的倒影不会 波动。")],
        ["Dungeon",           BooleanProperty,         _INTL("如果为true，这 个地图会随机生成布 局。更多信息请参见 wiki。")],
        ["BattleBack",        StringProperty,          _INTL("对战背景文件夹中名 为'XXX_bg'、'XXX_b ase0'、'XXX_base1'、 'XXX_message'的PN G文件，其中XXX是 这个属性的值。")],
        ["WildBattleBGM",     BGMProperty,             _INTL("此地图野生宝可梦对 战的默认BGM。")],
        ["TrainerBattleBGM",  BGMProperty,             _INTL("此地图训练家对战的 默认BGM。")],
        ["WildVictoryBGM",    BGMProperty,             _INTL("在此地图赢得野生宝 可梦对战后播放的默 认BGM。")],
        ["TrainerVictoryBGM", BGMProperty,             _INTL("在此地图赢得训练家 对战后播放的默认 BGM。")],
        ["WildCaptureME",     MEProperty,              _INTL("在此地图捕捉野生宝 可梦后播放的默认 ME。")],
        ["MapSize",           MapSizeProperty,         _INTL("地图在城镇地图方格 中的宽度，以及用来 表示哪些方格属于此 地图的一个字符串。")],
        ["Environment",       GameDataProperty.new(:Environment), _INTL("在此地图上对战的默 认环境。")],
        ["Flags",             StringListProperty,      _INTL("区分此地图和其他地 图的英文单词/短语 。")]
      ]
    end

    def initialize(hash)
      @id                   = hash[:id]
      @real_name            = hash[:real_name]
      @outdoor_map          = hash[:outdoor_map]
      @announce_location    = hash[:announce_location]
      @can_bicycle          = hash[:can_bicycle]
      @always_bicycle       = hash[:always_bicycle]
      @teleport_destination = hash[:teleport_destination]
      @weather              = hash[:weather]
      @town_map_position    = hash[:town_map_position]
      @dive_map_id          = hash[:dive_map_id]
      @dark_map             = hash[:dark_map]
      @safari_map           = hash[:safari_map]
      @snap_edges           = hash[:snap_edges]
      @still_reflections    = hash[:still_reflections]
      @random_dungeon       = hash[:random_dungeon]
      @battle_background    = hash[:battle_background]
      @wild_battle_BGM      = hash[:wild_battle_BGM]
      @trainer_battle_BGM   = hash[:trainer_battle_BGM]
      @wild_victory_BGM     = hash[:wild_victory_BGM]
      @trainer_victory_BGM  = hash[:trainer_victory_BGM]
      @wild_capture_ME      = hash[:wild_capture_ME]
      @town_map_size        = hash[:town_map_size]
      @battle_environment   = hash[:battle_environment]
      @flags                = hash[:flags]           || []
      @pbs_file_suffix      = hash[:pbs_file_suffix] || ""
    end

    # @return [String] the translated name of this map
    def name
      ret = pbGetMessageFromHash(MessageTypes::MAP_NAMES, @real_name)
      ret = pbGetBasicMapNameFromId(@id) if nil_or_empty?(ret)
      ret.gsub!(/\\PN/, $player.name) if $player
      return ret
    end

    def has_flag?(flag)
      return @flags.any? { |f| f.downcase == flag.downcase }
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      return __orig__get_property_for_PBS(key)
    end
  end
end
