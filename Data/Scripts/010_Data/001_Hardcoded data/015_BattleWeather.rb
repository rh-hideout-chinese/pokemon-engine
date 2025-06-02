module GameData
  class BattleWeather
    attr_reader :id
    attr_reader :real_name
    attr_reader :animation

    DATA = {}

    extend ClassMethodsSymbols
    include InstanceMethods

    def self.load; end
    def self.save; end

    def initialize(hash)
      @id        = hash[:id]
      @real_name = hash[:name] || "Unnamed"
      @animation = hash[:animation]
    end

    # @return [String] the translated name of this battle weather
    def name
      return _INTL(@real_name)
    end
  end
end

#===============================================================================

GameData::BattleWeather.register({
  :id   => :None,
  :name => _INTL("无")
})

GameData::BattleWeather.register({
  :id        => :Sun,
  :name      => _INTL("晴朗"),
  :animation => "Sun"
})

GameData::BattleWeather.register({
  :id        => :Rain,
  :name      => _INTL("下雨"),
  :animation => "Rain"
})

GameData::BattleWeather.register({
  :id        => :Sandstorm,
  :name      => _INTL("沙暴"),
  :animation => "Sandstorm"
})

GameData::BattleWeather.register({
  :id        => :Hail,
  :name      => _INTL("冰雹"),
  :animation => "Hail"
})

GameData::BattleWeather.register({
  :id        => :HarshSun,
  :name      => _INTL("大日照"),
  :animation => "HarshSun"
})

GameData::BattleWeather.register({
  :id        => :HeavyRain,
  :name      => _INTL("大雨"),
  :animation => "HeavyRain"
})

GameData::BattleWeather.register({
  :id        => :StrongWinds,
  :name      => _INTL("强风"),
  :animation => "StrongWinds"
})

GameData::BattleWeather.register({
  :id        => :ShadowSky,
  :name      => _INTL("暗空"),
  :animation => "ShadowSky"
})
