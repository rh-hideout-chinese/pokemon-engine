#===============================================================================
# Species properties.
#===============================================================================
module GameData
  class Species
    attr_accessor :gmax_move, :ungmax_form
	
    #---------------------------------------------------------------------------
    # Aliased to add G-Max properties to species schema.
    #---------------------------------------------------------------------------
    Species.singleton_class.alias_method :gmax_schema, :schema
    def self.schema(compiling_forms = false)
      ret = self.gmax_schema(compiling_forms)
      if compiling_forms
        ret["GmaxMove"]   = [:gmax_move,   "e", :Move]
        ret["UngmaxForm"] = [:ungmax_form, "u"]
      end
      return ret
    end
	
    alias dynamax_get_property_for_PBS get_property_for_PBS
    def get_property_for_PBS(key, writing_form = false)
      ret = dynamax_get_property_for_PBS(key, writing_form)
      case key
      when "UngmaxForm"
        ret = nil if !@gmax_move || ret == 0
      end
      return ret
    end
	
    #---------------------------------------------------------------------------
    # Aliased to initialize G-Max properties.
    #---------------------------------------------------------------------------
    alias gmax_initialize initialize
    def initialize(hash)
      gmax_initialize(hash)
      @gmax_move   = hash[:gmax_move]
      @ungmax_form = hash[:ungmax_form] || 0
    end
	
    #---------------------------------------------------------------------------
    # Checks Dynamax eligibility.
    #---------------------------------------------------------------------------
    def dynamax_able?
      return false if @mega_stone || @mega_move
      return false if has_flag?("CannotDynamax")
      return true
    end
    
    #---------------------------------------------------------------------------
    # Used for checking if this is a special Dynamax form.
    #---------------------------------------------------------------------------
    def dynamax_form?
      return true if @gmax_move
      v = MultipleForms.call("getEternamaxForm", self)
      return @form == v
    end
	
    #---------------------------------------------------------------------------
    # Edited for Dynamax shadow sprites.
    #---------------------------------------------------------------------------
    def self.shadow_bitmap_from_pokemon(pkmn)
      filename = self.shadow_filename(pkmn.species, pkmn.form) || "Graphics/Pokemon/Shadow/1.png"
      filename = self.convert_shadow_file(filename, pkmn.species, pkmn.form) if pkmn.dynamax?
      return (filename) ? AnimatedBitmap.new(filename) : nil
    end
	
    def self.convert_shadow_file(filename, species, form)
      if form > 0
        ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_%d_dmax", species, form))
        return ret if ret
      end
      ret = pbResolveBitmap(sprintf("Graphics/Pokemon/Shadow/%s_dmax", species))
      return ret if ret
      return pbResolveBitmap("Graphics/Pokemon/Shadow/4") if !filename
      file_split = filename.split("/")
      file_split[file_split.length - 1] = "4.png"
      filename = file_split.join("/")
      return filename
    end
  end
end

#===============================================================================
# Species metrics properties.
#===============================================================================
module GameData
  class SpeciesMetrics
    attr_accessor :dmax_back_sprite, :dmax_front_sprite, :dmax_shadow_x
    
    SCHEMA["DmaxBackSprite"]  = [:dmax_back_sprite,  "ii"]
    SCHEMA["DmaxFrontSprite"] = [:dmax_front_sprite, "ii"]
    SCHEMA["DmaxShadowX"]     = [:dmax_shadow_x,     "i"]
    
    alias dynamax_initialize initialize
    def initialize(hash)
      dynamax_initialize(hash)
      if @form > 0 && GameData::SpeciesMetrics.exists?(@species)
        backup = GameData::SpeciesMetrics.get(@species)
        @dmax_back_sprite  = hash[:dmax_back_sprite]  || backup.dmax_back_sprite
        @dmax_front_sprite = hash[:dmax_front_sprite] || backup.dmax_front_sprite
        @dmax_shadow_x     = hash[:dmax_shadow_x]     || backup.dmax_shadow_x
      else
        @dmax_back_sprite  = hash[:dmax_back_sprite]  || @back_sprite.clone
        @dmax_front_sprite = hash[:dmax_front_sprite] || @front_sprite.clone
        @dmax_shadow_x     = hash[:dmax_shadow_x]     || 0
      end
    end
	
    def apply_dynamax_metrics_to_sprite(sprite, index, shadow = false)
      if shadow
        sprite.x += @dmax_shadow_x * 2 if (index & 1) == 1
      elsif (index & 1) == 0
        sprite.x += @dmax_back_sprite[0] * 2
        sprite.y += @dmax_back_sprite[1] * 2
      else
        sprite.x += @dmax_front_sprite[0] * 2
        sprite.y += @dmax_front_sprite[1] * 2
      end
    end
	
    alias dynamax_get_property_for_PBS get_property_for_PBS
    def get_property_for_PBS(key)
      ret = dynamax_get_property_for_PBS(key)
      case key
      when "DmaxBackSprite"
        ret = nil if ret == @back_sprite
      when "DmaxFrontSprite"
        ret = nil if ret == @front_sprite
      when "DmaxShadowX"
        ret = nil if ret == 0
      end
      return ret
    end
  end
end

#-------------------------------------------------------------------------------
# Used to apply Dynamax metrics to sprites.
#-------------------------------------------------------------------------------
def pbApplyMetricsToSprite(shadow = false)
  return if !@pkmn
  metrics_data = GameData::SpeciesMetrics.get_species_form(@pkmn.species, @pkmn.form)
  if Settings::SHOW_DYNAMAX_SIZE && @pkmn.dynamax?
    metrics_data.apply_dynamax_metrics_to_sprite(self, @index, shadow)
  else
    metrics_data.apply_metrics_to_sprite(self, @index, shadow)
  end
end

#-------------------------------------------------------------------------------
# Pokemon bitmaps (In battle)
#-------------------------------------------------------------------------------
class Battle::Scene::BattlerSprite < RPG::Sprite
  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    if @index.even?
      self.z = 50 + (5 * @index / 2)
    else
      self.z = 50 - (5 * (@index + 1) / 2)
    end
    p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
    @spriteX = p[0]
    @spriteY = p[1]
    pbApplyMetricsToSprite
  end
end

#-------------------------------------------------------------------------------
# Shadow sprite for Pokémon (used in battle)
#-------------------------------------------------------------------------------
class Battle::Scene::BattlerShadowSprite < RPG::Sprite
  def pbSetPosition
    return if !@_iconBitmap
    pbSetOrigin
    self.z = 3
    p = Battle::Scene.pbBattlerPosition(@index, @sideSize)
    self.x = p[0]
    self.y = p[1]
    pbApplyMetricsToSprite(true)
  end
end