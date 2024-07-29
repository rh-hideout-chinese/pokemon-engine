#===============================================================================
# GameData::Move additions.
#===============================================================================
module GameData
  class Move
    #---------------------------------------------------------------------------
    # Returns true if this move is considered a Dynamax move.
    #---------------------------------------------------------------------------
    def dynamaxMove?
      return self.flags.any? { |f| f.include?("DynamaxMove") || f.include?("GmaxMove") }
    end
	
    #---------------------------------------------------------------------------
    # Returns a hash of the generic Max Move associated with each type.
    #---------------------------------------------------------------------------
    def self.get_generic_dynamax_moves
      hash = {}
      self.each do |move|
        next if !move.dynamaxMove?
        move.flags.each do |flag|
          next if !flag.include?("DynamaxMove_")
          param = flag.split("_").last.to_sym
          next if !GameData::Type.exists?(param)
          hash[param] = move.id
          break
        end
      end
      return hash
    end
  end
end


#===============================================================================
# Battle::Move class additions
#===============================================================================
class Battle::Move
  attr_accessor :index, :power, :category
  
  #-----------------------------------------------------------------------------
  # Returns true if this move object is considered a Dynamax move.
  #-----------------------------------------------------------------------------
  def dynamaxMove?
    move = GameData::Move.try_get(@id)
    return false if !move
    return move.dynamaxMove?
  end
  
  #-----------------------------------------------------------------------------
  # Returns true if the move can hit through Max Guard.
  #-----------------------------------------------------------------------------
  def ignoresMaxGuard?
    return true if ["IgnoreProtections", "RemoveProtections"].include?(@function_code)
    return true if statusMove? && @function_code == "TrapTargetInBattle"
    return @flags.any? { |f| f[/^IgnoresMaxGuard$/i] }
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to prevent Dynamax moves from being affected by Parental Bond.
  #-----------------------------------------------------------------------------
  alias dynamax_pbNumHits pbNumHits
  def pbNumHits(*args)
    return 1 if dynamaxMove?
    return dynamax_pbNumHits(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to allow Dynamax moves to partially hit through Protect.
  #-----------------------------------------------------------------------------
  alias dynamax_pbCalcDamageMultipliers pbCalcDamageMultipliers
  def pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    dynamax_pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    multipliers[:final_damage_multiplier] /= 4 if dynamaxMove? && target.isProtected?(user, self)
  end

  #-----------------------------------------------------------------------------
  # Returns the ID of a compatible Dynamax Move based on the given attributes.
  #-----------------------------------------------------------------------------
  def get_compatible_dynamax_move(battler, hash)
    if statusMove?
      return :MAXGUARD
    elsif battler.gmax_factor?
      if battler.gmax?
        pkmn = battler.pokemon
        gmax_form = pkmn.form
      else
        pkmn = battler.visiblePokemon
        gmax_form = pkmn.getGmaxForm
      end
      gmax_move = GameData::Species.get_species_form(pkmn.species, gmax_form).gmax_move
      move = GameData::Move.try_get(gmax_move)
      return gmax_move if move && @type == move.type
    end
    return hash[@type]
  end
  
  #-----------------------------------------------------------------------------
  # For converting a selected Dynamax move into one of a different type.
  #-----------------------------------------------------------------------------
  def convert_dynamax_move(battler, battle)
    if !statusMove?
      if ["TypeDependsOnUserIVs", 
          "TypeAndPowerDependOnUserBerry"].include?(@function_code)
        newtype = @type
      else
        newtype = pbCalcType(battler)
      end
      if newtype != @type && GameData::Type.exists?(newtype)
        if battler.gmax_factor?
          pkmn = battler.visiblePokemon
          dynamove = pkmn.species_data.gmax_move
          try_move = GameData::Move.try_get(dynamove)
          dynamove = try_move.id if try_move && newtype == try_move.type
        end
        if !dynamove
          dynahash = GameData::Move.get_generic_dynamax_moves
          dynamove = dynahash[newtype]
        end
        idxMove = battler.powerMoveIndex
        return self.make_dynamax_move(dynamove, battle, idxMove)
      end
    end
    return self
  end
  
  #-----------------------------------------------------------------------------
  # Creates a new Dynamax move object based on the attributes of this battle move.
  #-----------------------------------------------------------------------------
  def make_dynamax_move(new_id, battle, idxMove)
    move = Pokemon::Move.new(new_id)
    maxmove = Battle::DynamaxMove.from_pokemon_move(battle, move)
    maxmove.index = idxMove
    if maxmove.category < 2
      maxmove.power = self.calc_dynamax_move_power if maxmove.power == 1
      maxmove.category = self.realMove.category
    end
    return maxmove
  end
  
  #-----------------------------------------------------------------------------
  # Calculates the base power of a Max Move, based on the original move.
  #-----------------------------------------------------------------------------
  DYNAMAX_POWER_CONVERSION = { # Base Move Power => Max Move Power
    :boost  => { 150 => 150, 110 => 140,  
                 75  => 130, 65  => 120,
                 55  => 110, 45  => 100,
                 1   =>  90 },
    :weaken => { 150 => 100, 110 =>  95,  
                 75  =>  90, 65  =>  85,
                 55  =>  80, 45  =>  75,
                 1   =>  70 }
  }
  
  DYNAMAX_POWER_CONVERSION_MULTIHIT = { # Base Move Power => Max Move Power
    :boost  => { 65 => 150, 55 => 140,
                 20 => 130, 18 => 100,
                 1  => 90 },
    :weaken => { 65 => 100, 55 => 90,
                 20 => 80,  18 => 75,
                 1  => 70 }
  }
  
  def calc_dynamax_move_power
    convert = (Settings::DYNAMAX_TYPES_TO_WEAKEN.include?(@type)) ? :weaken : :boost
    if multiHitMove?
      DYNAMAX_POWER_CONVERSION_MULTIHIT[convert].each do |key, val|
        return val if power >= key
      end
    else
      case @function_code
      when "PowerHigherWithUserHP",                 # Eruption, Water Spout, etc.
           "UserFaintsFixedDamageUserHP"            # Final Gambit
        power = 150
      when "PowerHigherWithTargetHP",               # Crush Grip
           "DoublePowerInElectricTerrain"           # Rising Voltage
        power = 110
      when "OHKO",                                  # Horn Drill, Guillotine, etc.
           "OHKOIce",                               # Sheer Cold
           "OHKOHitsUndergroundTarget",             # Fissure
           "PowerLowerWithUserHP",                  # Flail, Reversal, etc.
           "LowerTargetHPToUserHP",                 # Endeavor
           "PowerHigherWithUserFasterThanTarget",   # Electro Ball
           "PowerHigherWithTargetFasterThanUser",   # Gyro Ball
           "PowerHigherWithTargetWeight",           # Grass Knot, Low Kick, etc.
           "TypeAndPowerDependOnWeather",           # Weather Ball
           "TypeAndPowerDependOnTerrain",           # Terrain Pulse
           "HitTwoTimesTargetThenTargetAlly",       # Dragon Darts
           "PowerHigherWithUserHeavierThanTarget",  # Heavy Slam, Heat Crash, etc.
           "PowerHigherWithUserPositiveStatStages"  # Stored Power, Power Trip, etc.
        power = 75
      when "FixedDamageUserLevel",                  # Night Shade, Seismic Toss, etc.
           "FixedDamageUserLevelRandom",            # Psywave
           "FixedDamageHalfTargetHP",               # Super Fang, Nature's Madeness, etc.
           "CounterPhysicalDamage",                 # Counter
           "CounterSpecialDamage",                  # Mirror Coat
           "CounterDamagePlusHalf",                 # Metal Burst
           "ThrowUserItemAtTarget",                 # Fling
           "RandomlyDamageOrHealTarget",            # Present
           "PowerDependsOnUserStockpile"            # Spit Up 
        power = 45
      else
        case @id
        when :DYNAMAXCANNON
          power = 110
        else
          power = @power
        end
      end
    end
    DYNAMAX_POWER_CONVERSION[convert].each do |key, val|
      return val if power >= key
    end
    return @power
  end
end


#===============================================================================
# Battle::DynamaxMove class.
#===============================================================================
class Battle::DynamaxMove < Battle::Move
  def initialize(battle, move)
    validate move => Pokemon::Move
    super(battle, move)
    @index = -1
  end
  
  def dynamaxMove?; return true; end
  def powerMove?;   return true; end
  
  #-----------------------------------------------------------------------------
  # Converts a given Pokemon::Move into a Battle::DynamaxMove.
  #-----------------------------------------------------------------------------
  def self.from_pokemon_move(battle, move)
    validate move => Pokemon::Move
    if move.dynamaxMove?
      code = move.function_code || "None"
      if code[/^\d/]
        class_name = sprintf("Battle::DynamaxMove::Effect%s", code)
      else
        class_name = sprintf("Battle::DynamaxMove::%s", code)
      end
      if Object.const_defined?(class_name)
        return Object.const_get(class_name).new(battle, move)
      end
      return Battle::DynamaxMove::Unimplemented.new(battle, move)
    end
    return super
  end
end