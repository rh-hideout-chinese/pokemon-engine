#===============================================================================
# Restructures the trainer Pokemon editor so that plugins may add new properties.
#===============================================================================
module TrainerPokemonProperty
  #-----------------------------------------------------------------------------
  # Returns initial settings and associated keys for a trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.editor_settings(initsetting)
    initsetting = {:species => nil, :level => 10} if !initsetting
    oldsetting = [
      initsetting[:species],
      initsetting[:level],
      initsetting[:real_name],
      initsetting[:form],
      initsetting[:gender],
      initsetting[:shininess],
      initsetting[:super_shininess],
      initsetting[:shadowness]
    ]
    keys = [
      :species, :level, :real_name, :form, :gender, 
      :shininess, :super_shininess, :shadowness
    ]
    Pokemon::MAX_MOVES.times do |i|
      oldsetting.push((initsetting[:moves]) ? initsetting[:moves][i] : nil)
      keys.push(:moves)
    end
    oldsetting.concat([
      initsetting[:ability],
      initsetting[:ability_index],
      initsetting[:item],
      initsetting[:nature],
      initsetting[:iv],
      initsetting[:ev],
      initsetting[:happiness],
      initsetting[:poke_ball]
    ])
    keys.push(
      :ability, :ability_index, :item, :nature,
      :iv, :ev, :happiness, :poke_ball
    )
    return oldsetting, keys
  end
  
  #-----------------------------------------------------------------------------
  # Returns all of the editor properties for a trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.editor_properties(oldsetting)
    max_level = GameData::GrowthRate.max_level
    properties = [
      [_INTL("Species"),    SpeciesProperty,                     _INTL("宝可梦的种类。")],
      [_INTL("Level"),      NonzeroLimitProperty.new(max_level), _INTL("宝可梦的等级(1-{1})。", max_level)],
      [_INTL("Name"),       StringProperty,                      _INTL("宝可梦的昵称。")],
      [_INTL("Form"),       LimitProperty2.new(999),             _INTL("宝可梦的形态。")],
      [_INTL("Gender"),     GenderProperty,                      _INTL("宝可梦的性别。")],
      [_INTL("Shiny"),      BooleanProperty2,                    _INTL("若设为真，则该宝可梦为异色。")],
      [_INTL("SuperShiny"), BooleanProperty2,                    _INTL("宝可梦是否为超闪光（有特殊动画的异色）。")],
      [_INTL("Shadow"),     BooleanProperty2,                    _INTL("若设为真，则该宝可梦为黑暗宝可梦。")]
    ]
    Pokemon::MAX_MOVES.times do |i|
      properties.push([_INTL("招式{1}", i + 1),
                       MovePropertyForSpecies.new(oldsetting), _INTL("宝可梦掌握的招式。如果为空（按Z取消）则依野生宝可梦招式处理。")])
    end
    properties.concat([
      [_INTL("特性"),       AbilityProperty,                         _INTL("宝可梦的特性。会覆盖特性指标。")],
      [_INTL("特性指标"), LimitProperty2.new(99),                  _INTL("特性指标。0=第一特性， 1=第二特性， 2+=隐藏特性。")],
      [_INTL("持有物"),     ItemProperty,                            _INTL("宝可梦携带的道具。")],
      [_INTL("性格"),        GameDataProperty.new(:Nature),           _INTL("宝可梦的性格。")],
      [_INTL("个体值"),           IVsProperty.new(Pokemon::IV_STAT_LIMIT), _INTL("各宝可梦的个体值。")],
      [_INTL("努力值"),           EVsProperty.new(Pokemon::EV_STAT_LIMIT), _INTL("各宝可梦的努力值。")],
      [_INTL("亲密度"),     LimitProperty2.new(255),                 _INTL("宝可梦的亲密度(0-255)。")],
      [_INTL("精灵球"),     BallProperty.new(oldsetting),            _INTL("宝可梦的精灵球的种类。")]
    ])
    return properties
  end
  
  #-----------------------------------------------------------------------------
  # Rewritten editor for trainer's Pokemon.
  #-----------------------------------------------------------------------------
  def self.set(settingname, initsetting)
    oldsetting, keys = self.editor_settings(initsetting)
    pkmn_properties = self.editor_properties(oldsetting)
    pbPropertyList(settingname, oldsetting, pkmn_properties, false)
    return nil if !oldsetting[0]
    ret = {}
    keys.each_with_index do |key, i|
      case key
      when :moves
        ret[key] = [] if !ret[key]
        ret[key].push(oldsetting[i])
      else
        ret[key] = oldsetting[i]
      end
    end
    ret[:moves].uniq!
    ret[:moves].compact!
    return ret
  end
end
