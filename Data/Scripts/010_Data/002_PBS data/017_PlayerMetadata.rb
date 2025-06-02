module GameData
  class PlayerMetadata
    attr_reader :id
    attr_reader :trainer_type
    attr_reader :walk_charset
    attr_reader :home
    attr_reader :pbs_file_suffix

    DATA = {}
    DATA_FILENAME = "player_metadata.dat"

    SCHEMA = {
      "SectionName"     => [:id,                "u"],
      "TrainerType"     => [:trainer_type,      "e", :TrainerType],
      "WalkCharset"     => [:walk_charset,      "s"],
      "RunCharset"      => [:run_charset,       "s"],
      "CycleCharset"    => [:cycle_charset,     "s"],
      "SurfCharset"     => [:surf_charset,      "s"],
      "DiveCharset"     => [:dive_charset,      "s"],
      "FishCharset"     => [:fish_charset,      "s"],
      "SurfFishCharset" => [:surf_fish_charset, "s"],
      "Home"            => [:home,              "vuuu"]
    }

    extend ClassMethodsIDNumbers
    include InstanceMethods

    def self.editor_properties
      return [
        ["ID",              ReadOnlyProperty,        _INTL("此玩家的ID编号。")],
        ["TrainerType",     TrainerTypeProperty,     _INTL("此玩家的训练家类型 。")],
        ["WalkCharset",     CharacterProperty,       _INTL("玩家静止及行走时使 用的图集。")],
        ["RunCharset",      CharacterProperty,       _INTL("玩家奔跑时使用的图 集。如果未定义，则 使用行走图集。")],
        ["CycleCharset",    CharacterProperty,       _INTL("玩家骑行时使用的图 集。如果未定义，则 使用奔跑图集。")],
        ["SurfCharset",     CharacterProperty,       _INTL("玩家冲浪时使用的图 集。如果未定义，则 使用骑行图集。")],
        ["DiveCharset",     CharacterProperty,       _INTL("玩家潜水时使用的图 集。如果未定义，则 使用冲浪图集。")],
        ["FishCharset",     CharacterProperty,       _INTL("玩家钓鱼时使用的图 集。如果未定义，则 使用行走图集。")],
        ["SurfFishCharset", CharacterProperty,       _INTL("玩家冲浪时钓鱼时使 用的图集。如果未定 义，则使用钓鱼图集 。")],
        ["Home",            MapCoordsFacingProperty, _INTL("如果没有在宝可梦中 心恢复过，玩家输掉 比赛后去往的地方。 （地图 ID 和 X/Y 坐标）")]
      ]
    end

    # @param player_id [Integer]
    # @return [self, nil]
    def self.get(player_id = 1)
      validate player_id => Integer
      return self::DATA[player_id] if self::DATA.has_key?(player_id)
      return self::DATA[1]
    end

    def initialize(hash)
      @id                = hash[:id]
      @trainer_type      = hash[:trainer_type]
      @walk_charset      = hash[:walk_charset]
      @run_charset       = hash[:run_charset]
      @cycle_charset     = hash[:cycle_charset]
      @surf_charset      = hash[:surf_charset]
      @dive_charset      = hash[:dive_charset]
      @fish_charset      = hash[:fish_charset]
      @surf_fish_charset = hash[:surf_fish_charset]
      @home              = hash[:home]
      @pbs_file_suffix   = hash[:pbs_file_suffix] || ""
    end

    def run_charset
      return @run_charset || @walk_charset
    end

    def cycle_charset
      return @cycle_charset || run_charset
    end

    def surf_charset
      return @surf_charset || cycle_charset
    end

    def dive_charset
      return @dive_charset || surf_charset
    end

    def fish_charset
      return @fish_charset || @walk_charset
    end

    def surf_fish_charset
      return @surf_fish_charset || fish_charset
    end

    alias __orig__get_property_for_PBS get_property_for_PBS unless method_defined?(:__orig__get_property_for_PBS)
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      return __orig__get_property_for_PBS(key)
    end
  end
end
