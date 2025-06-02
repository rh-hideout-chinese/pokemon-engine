module GameData
  class Environment
    attr_reader :id
    attr_reader :real_name
    attr_reader :battle_base

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id          = hash[:id]
      @real_name   = hash[:name] || "Unnamed"
      @battle_base = hash[:battle_base]
    end

    # @return [String] the translated name of this environment
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::Environment.register({
  :id   => :None,
  :name => _INTL("无")
})

GameData::Environment.register({
  :id          => :Grass,
  :name        => _INTL("草地"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id          => :TallGrass,
  :name        => _INTL("高草地"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id          => :MovingWater,
  :name        => _INTL("流水"),
  :battle_base => "water"
})

GameData::Environment.register({
  :id          => :StillWater,
  :name        => _INTL("静水"),
  :battle_base => "water"
})

GameData::Environment.register({
  :id          => :Puddle,
  :name        => _INTL("水洼"),
  :battle_base => "puddle"
})

GameData::Environment.register({
  :id   => :Underwater,
  :name => _INTL("水下")
})

GameData::Environment.register({
  :id   => :Cave,
  :name => _INTL("洞穴")
})

GameData::Environment.register({
  :id   => :Rock,
  :name => _INTL("岩地")
})

GameData::Environment.register({
  :id          => :Sand,
  :name        => _INTL("沙地"),
  :battle_base => "sand"
})

GameData::Environment.register({
  :id   => :Forest,
  :name => _INTL("森林")
})

GameData::Environment.register({
  :id          => :ForestGrass,
  :name        => _INTL("森林草丛"),
  :battle_base => "grass"
})

GameData::Environment.register({
  :id   => :Snow,
  :name => _INTL("雪地")
})

GameData::Environment.register({
  :id          => :Ice,
  :name        => _INTL("冰原"),
  :battle_base => "ice"
})

GameData::Environment.register({
  :id   => :Volcano,
  :name => _INTL("火山")
})

GameData::Environment.register({
  :id   => :Graveyard,
  :name => _INTL("墓地")
})

GameData::Environment.register({
  :id   => :Sky,
  :name => _INTL("天空")
})

GameData::Environment.register({
  :id   => :Space,
  :name => _INTL("太宙")
})

GameData::Environment.register({
  :id   => :UltraSpace,
  :name => _INTL("究极空间")
})
