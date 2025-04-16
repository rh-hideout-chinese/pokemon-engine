#===============================================================================
# New Pokemon properties.
#===============================================================================
class Pokemon
  attr_accessor :tera_type, :terastal_able, :terastallized

  alias tera_initialize initialize  
  def initialize(*args)
    tera_initialize(*args)
    @tera_type = getTeraType
    @terastal_able = true
    @terastallized = false
  end
  
  #-----------------------------------------------------------------------------
  # Terastal eligibility
  #-----------------------------------------------------------------------------
  def terastal_able?
    return false if !can_terastallize?
    return (@terastal_able.nil?) ? true : @terastal_able
  end
  
  def terastal_able=(value)
    @terastal_able = value
  end
  
  def can_terastallize?
    return false if egg? || shadowPokemon? || mega? || primal? || dynamax? || celestial?
    return species_data.terastal_able?
  end
  
  #-----------------------------------------------------------------------------
  # Tera type.
  #-----------------------------------------------------------------------------
  def tera_type
    return nil if !terastal_able?
    check_type = getTeraType(true)
    if !check_type.nil? && @tera_type != check_type
      @tera_type = check_type
    elsif !@tera_type
      @tera_type = getTeraType
    end
    return @tera_type
  end
  
  def display_tera_type
    return @tera_type
  end
  
  def tera_type=(value)
    return if !getTeraType(true).nil? || [:QMARKS, :SHADOW].include?(value)
    if value == :Random
      @tera_type = pbGetRandomType
    elsif GameData::Type.exists?(value) && !GameData::Type.get(value).pseudo_type
      @tera_type = value
    elsif !species_data.types.include?(@tera_type)
      @tera_type = species_data.types.sample
    end
  end
  
  def getTeraType(forced_type = false)
    type = nil
    return type if !terastal_able?
    species_data.flags.each do |flag|
      next if !flag.include?("TeraType_")
      check_type = $~[1].to_sym if flag[/^TeraType_(\w+)/i]
      type_data = GameData::Type.try_get(check_type)
      if type_data && !type_data.pseudo_type
        next if [:QMARKS, :SHADOW].include?(check_type)
        type = check_type
      elsif check_type == :Random && !@tera_type 
        type = pbGetRandomType
      end
	  break
    end
    return type if forced_type || GameData::Type.exists?(type)
    return pbGetRandomType if $game_switches[Settings::RANDOMIZED_TERA_TYPES]
    return species_data.types.sample
  end
  
  #-----------------------------------------------------------------------------
  # Terastal state.
  #-----------------------------------------------------------------------------
  def tera?
    return @terastallized
  end
  
  def terastallized=(value)
    return if !terastal_able?
    @terastallized = value
    if @terastallized
      self.makeTerastalForm
    else
      self.makeUnterastal
    end
  end
  
  #-----------------------------------------------------------------------------
  # Terastal form.
  #-----------------------------------------------------------------------------
  def tera_form?
    return tera? && hasTerastalForm?
  end
  
  def hasTerastalForm?
    v = MultipleForms.call("getTerastalForm", self)
    return !v.nil?
  end
  
  def getTerastalForm
    v = MultipleForms.call("getTerastalForm", self)
    return v || @form
  end

  def makeTerastalForm
    v = MultipleForms.call("getTerastalForm", self)
    if !v.nil?
      self.form = v
      self.forced_form = nil
    end
  end

  def makeUnterastal
    v = MultipleForms.call("getUnTerastalForm", self)
    if !v.nil?
      self.form = v
      self.forced_form = nil
    end
  end
end

#-------------------------------------------------------------------------------
# Utility for getting a randomly selected type. Excludes Stellar type.
#-------------------------------------------------------------------------------
def pbGetRandomType
  types = [] 
  GameData::Type.each do |t| 
    next if t.pseudo_type
    next if [:QMARKS, :SHADOW, :STELLAR].include?(t.id)
    types.push(t.id)
  end
  return types.sample
end

#===============================================================================
# Species data.
#===============================================================================
module GameData
  class Species
    #---------------------------------------------------------------------------
    # Checks compatibility with Tera Blast.
    #---------------------------------------------------------------------------
    def tutor_moves
      moves = @tutor_moves.clone
      if !moves.include?(:TERABLAST) && !Settings::TERABLAST_BANLIST.include?(@species)
        moves.push(:TERABLAST)
      elsif moves.include?(:TERABLAST) && Settings::TERABLAST_BANLIST.include?(@species)
        moves.delete(:TERABLAST)
      end
      return moves
    end
	
    #---------------------------------------------------------------------------
    # Checks Terastal eligibility.
    #---------------------------------------------------------------------------
    def terastal_able?
      return false if @mega_stone || @mega_move || @gmax_move
      return false if has_flag?("CannotTerastallize")
      return true
    end
  end
end