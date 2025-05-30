#===============================================================================
# Additions to GameData::TrainerType.
#===============================================================================
module GameData
  class TrainerType
    attr_accessor :sprite_scale
    attr_accessor :sprite_hue
    attr_accessor :shadow_xy
    attr_accessor :hide_shadow
    
    SCHEMA["SpriteScale"]  = [:sprite_scale, "u"]
    SCHEMA["SpriteHue"]    = [:sprite_hue,   "i"]
    SCHEMA["ShadowXY"]     = [:shadow_xy,   "ii"]
    SCHEMA["HideShadow"]   = [:hide_shadow,  "b"]
    
    #---------------------------------------------------------------------------
    # Aliased to include sprite scaling, shadow metrics, and hues.
    #---------------------------------------------------------------------------
    alias animtrainer_initialize initialize
    def initialize(hash)
      animtrainer_initialize(hash)
      @sprite_scale = hash[:sprite_scale]
      @sprite_hue   = hash[:sprite_hue]
      @shadow_xy    = hash[:shadow_xy]   || [0, 0]
      @hide_shadow  = hash[:hide_shadow] || false
    end
  
    alias animtrainer_get_property_for_PBS get_property_for_PBS
    def get_property_for_PBS(key)
      ret = animtrainer_get_property_for_PBS(key)
      case key
      when "SpriteScale"
        ret = nil if ret == Settings::TRAINER_SPRITE_SCALE
      when "SpriteHue"
        ret = nil if ret == 0
      when "ShadowXY"
        ret = nil if ret == [0, 0]
      when "HideShadow"
        ret = nil if !ret
      end
      return ret
    end
	
    #---------------------------------------------------------------------------
    # Returns trainer sprite values.
    #---------------------------------------------------------------------------
    def trainer_sprite_scale
      return @sprite_scale || Settings::TRAINER_SPRITE_SCALE
    end
    
    def trainer_sprite_hue
      return @sprite_hue || 0
    end
    
    def shows_shadow?
      return false if @hide_shadow
      return true
    end
	
    #---------------------------------------------------------------------------
    # Returns a bitmap from an entered trainer or trainer type.
    #---------------------------------------------------------------------------
    def self.sprite_bitmap_from_trainer(trainer, trainerType = nil)
      trainerType = trainer.trainer_type if !trainerType
      trainerType = GameData::TrainerType.try_get(trainerType)
      return nil if !trainerType
      filename = self.front_sprite_filename(trainerType.id) || "Graphics/Trainers/000"
      scale = trainerType.trainer_sprite_scale
      ret = (filename) ? TrainerBitmapWrapper.new(filename, scale) : nil
      ret.compile_strip
      return ret
    end
  end
end