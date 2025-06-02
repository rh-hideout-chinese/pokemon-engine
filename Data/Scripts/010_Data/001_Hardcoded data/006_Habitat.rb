module GameData
  class Habitat
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

    # @return [String] the translated name of this habitat
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::Habitat.register({
  :id   => :None,
  :name => _INTL("无")
})

GameData::Habitat.register({
  :id   => :Grassland,
  :name => _INTL("草原")
})

GameData::Habitat.register({
  :id   => :Forest,
  :name => _INTL("森林")
})

GameData::Habitat.register({
  :id   => :WatersEdge,
  :name => _INTL("水边")
})

GameData::Habitat.register({
  :id   => :Sea,
  :name => _INTL("海洋")
})

GameData::Habitat.register({
  :id   => :Cave,
  :name => _INTL("洞穴")
})

GameData::Habitat.register({
  :id   => :Mountain,
  :name => _INTL("山地")
})

GameData::Habitat.register({
  :id   => :RoughTerrain,
  :name => _INTL("多岩场地")
})

GameData::Habitat.register({
  :id   => :Urban,
  :name => _INTL("城市")
})

GameData::Habitat.register({
  :id   => :Rare,
  :name => _INTL("罕见")
})
