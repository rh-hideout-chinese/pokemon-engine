# NOTE: The order these colors are registered are the order they are listed in
#       the Pokédex search screen.
module GameData
  class BodyColor
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

    # @return [String] the translated name of this body color
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::BodyColor.register({
  :id   => :Red,
  :name => _INTL("红色")
})

GameData::BodyColor.register({
  :id   => :Blue,
  :name => _INTL("蓝色")
})

GameData::BodyColor.register({
  :id   => :Yellow,
  :name => _INTL("黄色")
})

GameData::BodyColor.register({
  :id   => :Green,
  :name => _INTL("绿色")
})

GameData::BodyColor.register({
  :id   => :Black,
  :name => _INTL("黑色")
})

GameData::BodyColor.register({
  :id   => :Brown,
  :name => _INTL("褐色")
})

GameData::BodyColor.register({
  :id   => :Purple,
  :name => _INTL("紫色")
})

GameData::BodyColor.register({
  :id   => :Gray,
  :name => _INTL("灰色")
})

GameData::BodyColor.register({
  :id   => :White,
  :name => _INTL("白色")
})

GameData::BodyColor.register({
  :id   => :Pink,
  :name => _INTL("粉红色")
})
