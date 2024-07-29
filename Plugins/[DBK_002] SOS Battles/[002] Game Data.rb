#===============================================================================
# Adds new properties to Species and MapMetadata GameData.
#===============================================================================
module GameData
  #-----------------------------------------------------------------------------
  # Additions to the Species class.
  #-----------------------------------------------------------------------------
  class Species
    attr_reader :rival_species
    attr_reader :sos_call_rate, :sos_species, :sos_conditional
    
    Species.singleton_class.alias_method :sos_schema, :schema
    def self.schema(compiling_forms = false)
      ret = self.sos_schema(compiling_forms)
      ret["RivalSpecies"]   = [:rival_species,   "*m"]
      ret["SpeciesSOS"]     = [:sos_species,     "*m"]
      ret["ConditionalSOS"] = [:sos_conditional, "*meU", nil, :EncounterType, nil]
      ret["CallRateSOS"]    = [:sos_call_rate,   "u"]
      return ret
    end
    
    Species.singleton_class.alias_method :sos_editor_properties, :editor_properties
    def self.editor_properties
      properties = self.sos_editor_properties
      properties.concat([
        ["RivalSpecies",   GameDataPoolProperty.new(:Species), _INTL("Species that this wild Pokémon will prioritize attacking, even if on the same side.")],
        ["SpeciesSOS",     GameDataPoolProperty.new(:Species), _INTL("Species that may appear when this wild Pokémon calls for help.")],
        ["ConditionalSOS", SOSEncounterProperty.new,           _INTL("Conditional species that may appear when this wild Pokémon calls for help.")],
        ["CallRateSOS",    LimitProperty.new(100),             _INTL("Base odds of this wild Pokémon calling for help.")],
      ])
      return properties
    end
    
    alias sos_initialize initialize
    def initialize(hash)
      sos_initialize(hash)
      @rival_species   = hash[:rival_species]   || []
      @sos_species     = hash[:sos_species]     || [@species]
      @sos_conditional = hash[:sos_conditional] || []
      @sos_call_rate   = hash[:sos_call_rate]   || 0
    end
    
    def sos_form
      @flags.each { |flag| return $~[1].to_i if flag[/^SOSForm_(\d+)$/i] }
      return -1
    end
	
    alias sos_get_property_for_PBS get_property_for_PBS
    def get_property_for_PBS(key, writing_form = false)
      ret = sos_get_property_for_PBS(key, writing_form)
      case key
      when "SpeciesSOS"
        ret = nil if ret && ret.length == 1 && ret[0] == @species
      when "CallRateSOS"
        ret = nil if ret == 0
      end
      return ret
    end
  end
  
  #-----------------------------------------------------------------------------
  # Additions to the MapMetadata class.
  #-----------------------------------------------------------------------------
  class MapMetadata
    attr_reader :special_sos
    
    SOS_CONDITIONS  = ["Any", "Weather", "Terrain", "Environment"]
    SOS_TIME_OF_DAY = ["Any", "Day", "Night", "Morning", "Afternoon", "Evening"]
    
    SCHEMA["SpecialSOS"] = [:special_sos, "*euEEM",  :Species, nil, SOS_TIME_OF_DAY, SOS_CONDITIONS]
    
    MapMetadata.singleton_class.alias_method :sos_editor_properties, :editor_properties
    def self.editor_properties
      properties = self.sos_editor_properties
      properties.push(
        ["SpecialSOS", SOSMapEncounterProperty.new, _INTL("Exclusive SOS encounters found on this map.")]
      )
      return properties
    end
    
    alias sos_initialize initialize
    def initialize(hash)
      sos_initialize(hash)
      @special_sos = hash[:special_sos] || []
    end
	
    def get_property_for_PBS(key)
      key = "SectionName" if key == "ID"
      ret = __orig__get_property_for_PBS(key)
      if key == "SpecialSOS" && !@special_sos.empty?
        ret[2] = SOS_TIME_OF_DAY[@special_sos[2]] if @special_sos[2]
        ret[3] = SOS_CONDITIONS[@special_sos[3]] if @special_sos[3]
      end
      return ret
    end
  end
end


#===============================================================================
# Adrenaline Orb
#===============================================================================
# Allows this item to be used in battle to increase SOS odds.
#-------------------------------------------------------------------------------
ItemHandlers::CanUseInBattle.add(:ADRENALINEORB, proc { |item, pokemon, battler, move, firstAction, battle, scene, showMessages|
  next true
})

ItemHandlers::UseInBattle.add(:ADRENALINEORB, proc { |item, battler, battle|
  if battle.adrenalineOrb
    battle.pbDisplay(_INTL("But it had no effect!"))
    battle.pbReturnUnusedItemToBag(item, battler.index)
  else
    battle.pbDisplay(_INTL("The {1} makes the wild Pokémon nervous!", GameData::Item.get(item).portion_name))
    battle.adrenalineOrb = true
  end
})