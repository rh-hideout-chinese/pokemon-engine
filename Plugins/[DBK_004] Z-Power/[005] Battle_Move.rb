################################################################################
#
# GameData
#
################################################################################

module GameData
  class Move
    def zMove?
      return self.flags.any? { |f| f.include?("ZMove") }
    end
    
    def self.get_generic_zmoves
      hash = {}
      self.each do |move|
        next if !move.zMove?
        move.flags.each do |flag|
          next if !flag.include?("ZMove_")
          param = flag.split("_").last.to_sym
          next if !GameData::Type.exists?(param)
          hash[param] = move.id
          break
        end
      end
      return hash
    end
    
    #---------------------------------------------------------------------------
    # Edited to display the move name '10,000,000 Volt Thunderbolt' correctly.
    #---------------------------------------------------------------------------
    def name
      ret = pbGetMessageFromHash(MessageTypes::MOVE_NAMES, @real_name)
      ret.gsub!("_", ",")
      return ret
    end
  end
end


################################################################################
#
# Battle::Move
#
################################################################################

class Battle::Move
  attr_accessor :name, :power, :category
  attr_accessor :specialUseZMove, :status_zmove
  
  #-----------------------------------------------------------------------------
  # Returns true if this move is a Z-Move or a Z-Powered status move.
  #-----------------------------------------------------------------------------
  def zMove?
	move = GameData::Move.try_get(@id)
	return false if !move
    return move.zMove? || @status_zmove
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to prevent Z-Moves from being affected by type-changing Abilities.
  #-----------------------------------------------------------------------------
  alias zmove_pbBaseType pbBaseType
  def pbBaseType(user)
    return @type if (user.selectedMoveIsZMove || zMove?) && !statusMove?
    return zmove_pbBaseType(user)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to prevent Z-Moves from being affected by Parental Bond.
  #-----------------------------------------------------------------------------
  alias zmove_pbNumHits pbNumHits
  def pbNumHits(*args)
    return 1 if zMove?
    return zmove_pbNumHits(*args)
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to allow Z-Moves to partially hit through Protect.
  #-----------------------------------------------------------------------------
  alias zmove_pbCalcDamageMultipliers pbCalcDamageMultipliers
  def pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    zmove_pbCalcDamageMultipliers(user, target, numTargets, type, baseDmg, multipliers)
    multipliers[:final_damage_multiplier] /= 4 if zMove? && target.isProtected?(user, self)
  end

  #-----------------------------------------------------------------------------
  # Displays animation and messages when using a Z-Move in battle.
  #-----------------------------------------------------------------------------
  alias zmove_pbDisplayUseMessage pbDisplayUseMessage
  def pbDisplayUseMessage(user)
    if zMove? && !@specialUseZMove
      $stats.total_zmove_count += 1 if user.pbOwnedByPlayer?
      trigger = (@status_zmove) ? "BeforeZStatus" : "BeforeZMove"
      @battle.pbDeluxeTriggers(user, nil, trigger, user.species, @type, @id)
      @battle.pbDisplayBrief(_INTL("{1} surrounded itself with its Z-Power!", user.pbThis))
      if @battle.scene.pbCommonAnimationExists?("ZMove")
        pbCommonAnimation("ZMove", user)
      elsif Settings::SHOW_ZMOVE_ANIM && $PokemonSystem.battlescene == 0
        pbWait(0.5)
        @battle.scene.pbShowZMove(user.index, @id)
      end
      if statusMove? && @status_zmove
        pbWait(0.5)
        pbUseZPowerStatusEffect(user)
      end
      side  = user.idxOwnSide
      owner = @battle.pbGetOwnerIndexFromBattlerIndex(user.index)
      @battle.zMove[side][owner] = -2
      @battle.pbDisplayBrief(_INTL("{1} unleashed its full force Z-Move!", user.pbThis))
    end
    zmove_pbDisplayUseMessage(user)
  end

  
  ##############################################################################
  #
  # Converting Battle::Move objects into Battle::ZMove objects.
  #
  ##############################################################################
 
  
  #-----------------------------------------------------------------------------
  # Returns the ID of a compatible Z-Move based on the given attributes.
  #-----------------------------------------------------------------------------
  def get_compatible_zmove(item, pkmn)
    item = GameData::Item.get(item) if item.is_a?(Symbol)
    if item.has_zmove_combo?
      return nil if !GameData::Move.get(item.zmove).zMove?
      if @id == item.zmove_base_move
        species = (item.has_flag?("UsableByAllForms")) ? pkmn.species : pkmn.species_data.id
        return item.zmove if item.zmove_species.include?(species)
      end
    elsif statusMove? && @type == item.zmove_type
      return @id
    elsif @type == item.zmove_type
      return nil if !GameData::Move.get(item.zmove).zMove?
      return item.zmove
    end
    return nil
  end
  
  #-----------------------------------------------------------------------------
  # For converting a selected Z-Move into a Z-Move of a different type.
  #-----------------------------------------------------------------------------
  def convert_zmove(battler, battle, specialUsage)
    if ["TypeDependsOnUserIVs", 
        "TypeAndPowerDependOnUserBerry"].include?(@function_code)
      newtype = @type
    else
      newtype = pbCalcType(battler)
    end
    if specialUsage || newtype != @type && GameData::Type.exists?(newtype)
      zhash = GameData::Move.get_generic_zmoves
      zmove = zhash[newtype]
      zmove = self.make_zmove(zmove, battle)
      zmove.specialUseZMove = specialUsage
      return zmove
    end
    self.specialUseZMove = specialUsage
    return self
  end
  
  #-----------------------------------------------------------------------------
  # Creates a new Z-Move object based on the attributes of this battle move.
  #-----------------------------------------------------------------------------
  def make_zmove(new_id, battle)
    id = new_id || self.id
    move = Pokemon::Move.new(id)
    zmove = Battle::ZMove.from_pokemon_move(battle, move)
    if zmove.category < 2
      zmove.power = self.calc_zmove_power if zmove.power == 1
      zmove.category = self.realMove.category 
    end
    if statusMove? && id == zmove.id
      zmove.name = "Z-" + @name
      zmove.short_name = (Settings::SHORTEN_MOVES && zmove.name.length > 16) ? zmove.name[0..12] + "..." : zmove.name
    end
    return zmove
  end
  
  #-----------------------------------------------------------------------------
  # Calculates the base power of a Z-Move, based on this original move.
  #-----------------------------------------------------------------------------
  ZMOVE_POWER_CONVERSION = { # Base Move Power => Z-Move Power
    140 => 220,  130 => 195,  
    120 => 190,  110 => 185,  
    100 => 180,  90  => 175,
    80  => 160,  70  => 140,  
    60  => 120,  1   => 100
  }
  
  def calc_zmove_power
    case @function_code 
    when "OHKO",                      # Horn Drill, Guillotine, etc.
         "OHKOIce",                   # Sheer Cold
         "OHKOHitsUndergroundTarget"  # Fissure
      return 180
    end 
    case @id
    when :VCREATE      then return 220
    when :GEARGRIND    then return 180
    when :FLYINGPRESS  then return 170
    when :HEX          then return 160
    when :WEATHERBALL  then return 160
    when :COREENFORCER then return 140
    when :MEGADRAIN    then return 120
    end
    ZMOVE_POWER_CONVERSION.each do |key, val|
      return val if @power >= key
    end
    return @power
  end
  
  
  ##############################################################################
  #
  # For triggering special Z-Powered effects of status moves.
  #
  ##############################################################################
  
  
  #-----------------------------------------------------------------------------
  # Returns true if this status move has a Z-Powered effect.
  #-----------------------------------------------------------------------------
  def has_zpower?
    return !@flags.none? { |f| f[/^ZPower_/i] }
  end
  
  #-----------------------------------------------------------------------------
  # Returns the specific effect of this move's Z-Power.
  #-----------------------------------------------------------------------------
  def get_zpower_effect
    return if !has_zpower?
    @flags.each do |flag|
      next if !flag.include?("ZPower")
      array = flag.split("_")
      if array.length > 2
        effect = array[1..array.length - 2].join("_")
        return effect, array.last
      else
        return array[1], array[2]
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Applies the effect of this move's Z-Power on the user prior to using the move.
  #-----------------------------------------------------------------------------
  def pbUseZPowerStatusEffect(user)
    $stats.status_zmove_count += 1 if user.pbOwnedByPlayer?
    effect, stage = self.get_zpower_effect
    effect = "HealUser" if @id == :CURSE && user.pbHasType?(:GHOST)
    case effect
    #---------------------------------------------------------------------------
    # Z-Powered effects that fully restores the user's HP.
    when "HealUser"
      if user.hp < user.totalhp
        user.pbRecoverHP(user.totalhp, false)
        @battle.pbDisplay(_INTL("{1} restored its HP using its Z-Power!", user.pbThis))
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that fully restores the HP of an incoming Pokemon.
    when "HealSwitch"
      @battle.positions[user.index].effects[PBEffects::ZHealing] = true
    #---------------------------------------------------------------------------
    # Z-Powered effects that boost the user's critical hit ratio.
    when "CriticalHit"
      if user.effects[PBEffects::FocusEnergy] < 4
        user.effects[PBEffects::FocusEnergy] += 2
        user.effects[PBEffects::FocusEnergy] = 4 if user.effects[PBEffects::FocusEnergy] > 4
        @battle.pbDisplay(_INTL("{1} boosted its critical hit ratio using its Z-Power!", user.pbThis))
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that resets the user's lowered stats.
    when "ResetStats"
      if user.hasLoweredStatStages?
        GameData::Stat.each_battle do |s|
          next if user.stages[s.id] >= 0
          user.stages[s.id] = 0
          user.statsRaisedThisRound = true
        end
        @battle.pbDisplay(_INTL("{1} returned its decreased stats to normal using its Z-Power!", user.pbThis))
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that cause misdirection.
    when "FollowMe"
      @battle.pbDisplay(_INTL("{1} became the center of attention using its Z-Power!", user.pbThis))
      user.effects[PBEffects::FollowMe] = 1
      user.eachAlly do |b|
        next if b.effects[PBEffects::FollowMe] < user.effects[PBEffects::FollowMe]
        user.effects[PBEffects::FollowMe] = b.effects[PBEffects::FollowMe] + 1
      end
    #---------------------------------------------------------------------------
    # Z-Powered effects that raise the user's stats.
    else
      if stage
        stats = []
        stage = stage.to_i
        case effect
        when "AllStats"
          GameData::Stat.each_main_battle { |s| stats.push(s.id) }
        else
          stat = GameData::Stat.try_get(effect.to_sym)
          stats.push(stat.id) if stat
        end
        showAnim = true
        stats.each do |stat|
          if user.pbCanRaiseStatStage?(stat, user, nil, false, true)
            user.pbRaiseStatStageBasic(stat, stage, true)
            if showAnim
              @battle.pbCommonAnimation("StatUp", user)
              boost = (stats.length > 1) ? "stats" : GameData::Stat.get(stat).name
              boost += " drastically" if stage >= 3
              boost += " sharply"     if stage == 2
              @battle.pbDisplay(_INTL("{1} boosted its {2} using its Z-Power!", user.pbThis, boost))
              showAnim = false
            end
          end
        end
      end
    end
  end
end


################################################################################
#
# Battle::ZMove
#
################################################################################

class Battle::ZMove < Battle::Move
  def initialize(battle, move)
    validate move => Pokemon::Move
    super(battle, move)
    @status_zmove = false
    @specialUseZMove = false
  end
  
  def zMove?;     return true; end
  def powerMove?; return true; end
  
  #-----------------------------------------------------------------------------
  # Converts a given Pokemon::Move into a Battle::ZMove.
  #-----------------------------------------------------------------------------
  def self.from_pokemon_move(battle, move)
    validate move => Pokemon::Move
    if move.zMove?
      code = move.function_code || "None"
      if code[/^\d/]
        class_name = sprintf("Battle::ZMove::Effect%s", code)
      else
        class_name = sprintf("Battle::ZMove::%s", code)
      end
      if Object.const_defined?(class_name)
        return Object.const_get(class_name).new(battle, move)
      end
      return Battle::ZMove::Unimplemented.new(battle, move)
    else
      ret = super
      ret.status_zmove = true
      return ret
    end
  end
end