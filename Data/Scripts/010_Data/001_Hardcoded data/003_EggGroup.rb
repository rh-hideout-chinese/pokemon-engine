module GameData
  class EggGroup
    attr_reader :id
    attr_reader :real_name

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Unnamed"
    end

    # @return [String] the translated name of this egg group
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::EggGroup.register({
  :id   => :Undiscovered,
  :name => _INTL("未发现")
})

GameData::EggGroup.register({
  :id   => :Monster,
  :name => _INTL("怪兽")
})

GameData::EggGroup.register({
  :id   => :Water1,
  :name => _INTL("水中1")
})

GameData::EggGroup.register({
  :id   => :Bug,
  :name => _INTL("虫")
})

GameData::EggGroup.register({
  :id   => :Flying,
  :name => _INTL("飞行")
})

GameData::EggGroup.register({
  :id   => :Field,
  :name => _INTL("陆上")
})

GameData::EggGroup.register({
  :id   => :Fairy,
  :name => _INTL("妖精")
})

GameData::EggGroup.register({
  :id   => :Grass,
  :name => _INTL("植物")
})

GameData::EggGroup.register({
  :id   => :Humanlike,
  :name => _INTL("人型")
})

GameData::EggGroup.register({
  :id   => :Water3,
  :name => _INTL("水中3")
})

GameData::EggGroup.register({
  :id   => :Mineral,
  :name => _INTL("矿物")
})

GameData::EggGroup.register({
  :id   => :Amorphous,
  :name => _INTL("不定形")
})

GameData::EggGroup.register({
  :id   => :Water2,
  :name => _INTL("水中2")
})

GameData::EggGroup.register({
  :id   => :Ditto,
  :name => _INTL("百变怪")
})

GameData::EggGroup.register({
  :id   => :Dragon,
  :name => _INTL("龙")
})
