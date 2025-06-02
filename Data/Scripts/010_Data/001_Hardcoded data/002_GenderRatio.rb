# If a Pokémon's gender ratio is none of :AlwaysMale, :AlwaysFemale or
# :Genderless, then it will choose a random number between 0 and 255 inclusive,
# and compare it to the @female_chance. If the random number is lower than this
# chance, it will be female; otherwise, it will be male.
module GameData
  class GenderRatio
    attr_reader :id
    attr_reader :real_name
    attr_reader :female_chance

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id            = hash[:id]
      @real_name     = hash[:name] || "Unnamed"
      @female_chance = hash[:female_chance]
    end

    # @return [String] the translated name of this gender ratio
    def name
      return _INTL(@real_name)
    end

    # @return [Boolean] whether a Pokémon with this gender ratio can only ever
    #   be a single gender
    def single_gendered?
      return @female_chance.nil?
    end
  end
end

#===============================================================================

GameData::GenderRatio.register({
  :id            => :AlwaysMale,
  :name          => _INTL("只有雄性")
})

GameData::GenderRatio.register({
  :id            => :AlwaysFemale,
  :name          => _INTL("只有雌性")
})

GameData::GenderRatio.register({
  :id            => :Genderless,
  :name          => _INTL("无性别")
})

GameData::GenderRatio.register({
  :id            => :FemaleOneEighth,
  :name          => _INTL("1/8雌性"),
  :female_chance => 32
})

GameData::GenderRatio.register({
  :id            => :Female25Percent,
  :name          => _INTL("1/4雌性"),
  :female_chance => 64
})

GameData::GenderRatio.register({
  :id            => :Female50Percent,
  :name          => _INTL("1/2雌性"),
  :female_chance => 128
})

GameData::GenderRatio.register({
  :id            => :Female75Percent,
  :name          => _INTL("3/4雌性"),
  :female_chance => 192
})

GameData::GenderRatio.register({
  :id            => :FemaleSevenEighths,
  :name          => _INTL("7/8雌性"),
  :female_chance => 224
})
