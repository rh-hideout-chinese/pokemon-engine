#===============================================================================
# Pokemon properties.
#===============================================================================
class Pokemon
  attr_accessor :dynamax_lvl, :gmax_factor, :dynamax, :dynamax_able
  
  alias dynamax_initialize initialize  
  def initialize(*args)
    @gmax_factor   = false
    @dynamax       = false
    @dynamax_able  = true
    @dynamax_lvl   = 0
    @dynamax_phase = 0
    dynamax_initialize(*args)
  end
  
  class Move
    def dynamaxMove?; return GameData::Move.get(@id).dynamaxMove?; end
  end

  #-----------------------------------------------------------------------------
  # Dynamax Levels
  #-----------------------------------------------------------------------------
  def dynamax_lvl
    return @dynamax_lvl || 0
  end
  
  def dynamax_lvl=(value)
    return if !value
    value = value.clamp(0, 10)
    @dynamax_lvl = (dynamax_able?) ? value : 0
  end
  
  #-----------------------------------------------------------------------------
  # G-Max Factor
  #-----------------------------------------------------------------------------  
  def gmax_factor?
    return @gmax_factor
  end
  
  def gmax_factor=(value)
    if dynamax?
      if value
        @gmax_factor = true
        self.makeDynamaxForm
      else
        self.makeUndynamaxForm
        @gmax_factor = false
      end
    else
      @gmax_factor = (dynamax_able?) ? value : false
    end
  end
    
  #-----------------------------------------------------------------------------
  # Dynamax eligibility
  #-----------------------------------------------------------------------------
  def dynamax_able?
    return false if !can_dynamax?
    return (@dynamax_able.nil?) ? true : @dynamax_able
  end
  
  def dynamax_able=(value)
    @dynamax_able = value
  end
  
  def can_dynamax?
    return false if egg? || shadowPokemon? || mega? || primal? || tera? || celestial?
    return species_data.dynamax_able?
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax state
  #-----------------------------------------------------------------------------
  def dynamax?
    return @dynamax
  end
  
  def dynamax=(value)
    return if !dynamax_able?
    if value
      self.makeDynamaxForm
      @dynamax = true
      @dynamax_phase = 2
      calc_stats
    else
      self.makeUndynamaxForm
      @dynamax = false
      @dynamax_phase = 1
      calc_stats
    end
  end
  
  def dynamax_phase=(value)
    @dynamax_phase = value
  end
  
  def makeDynamax
    return if !dynamax_able?
    @dynamax = true
    @dynamax_phase = 2
  end
  
  def makeUndynamax
    @dynamax = false
    @dynamax_phase = 1
  end
  
  def dynamax_force_revert
    if dynamax? && !dynamax_able?
      @dynamax = false
      @gmax_factor = false
      @dynamax_phase = 1
    end
  end
  
  #-----------------------------------------------------------------------------
  # Gigantamax forms.
  #-----------------------------------------------------------------------------
  def gmax?
    return dynamax? && species_data.gmax_move
  end
  
  def getUngmaxForm
    return (gmax?) ? species_data.ungmax_form : -1
  end
  
  def getGmaxForm
    baseForm = GameData::Species.get_species_form(@species, @form).form
    GameData::Species.each do |data|
      next if !data.gmax_move
      next if data.species != @species
      if species_data.has_flag?("AllFormsShareGmax") || data.ungmax_form == baseForm
        return data.form
      end
    end
    return 0
  end
  
  def hasGigantamaxForm?
    gmaxForm = self.getGmaxForm
    return gmaxForm > 0 && gmaxForm != form_simple
  end
  
  #-----------------------------------------------------------------------------
  # Eternamax forms.
  #-----------------------------------------------------------------------------
  def emax?
    return dynamax? && hasEternamaxForm? && self.form == self.getEmaxForm
  end
  
  def getUnemaxForm
    v = MultipleForms.call("getUnmaxForm", self)
    return v || 0
  end
  
  def getEmaxForm
    v = MultipleForms.call("getEternamaxForm", self)
    return v || 0
  end
  
  def hasEternamaxForm?
    v = MultipleForms.call("getEternamaxForm", self)
    return !v.nil?
  end
  
  #-----------------------------------------------------------------------------
  # Setting Dynamax forms.
  #-----------------------------------------------------------------------------
  def getUndynamaxForm
    return getUngmaxForm if gmax?
    return getUnemaxForm if emax?
    return @form
  end
  
  def hasDynamaxForm?
    return false if !dynamax_able?
    return hasEternamaxForm? || hasGigantamaxForm? 
  end
  
  def makeDynamaxForm
    if hasEternamaxForm?
      emaxForm = self.getEmaxForm
      self.form = emaxForm if emaxForm > 0
    elsif hasGigantamaxForm? && gmax_factor?
      @ungmax_form = self.form if species_data.has_flag?("AllFormsShareGmax")
      gmaxForm = self.getGmaxForm
      self.form = gmaxForm if gmaxForm > 0
    end
  end
  
  def makeUndynamaxForm
    if hasEternamaxForm?
      unemaxForm = self.getUnemaxForm
      self.form = unemaxForm if unemaxForm >= 0
    elsif gmax_factor?
      ungmaxForm = (@ungmax_form) ? @ungmax_form : self.getUngmaxForm
      self.form = ungmaxForm if ungmaxForm >= 0
      @ungmax_form = nil
    end
  end
  
  #-----------------------------------------------------------------------------
  # Dynamax HP calcs.
  #-----------------------------------------------------------------------------
  alias dynamax_real_hp real_hp
  def real_hp
    return (dynamax_real_hp / dynamax_boost).floor
  end
  
  alias dynamax_real_totalhp real_totalhp
  def real_totalhp
    return (dynamax_real_totalhp / dynamax_boost).floor
  end
  
  def dynamax_calc
    return 1.5 + (dynamax_lvl.to_f * 0.05)
  end
  
  def dynamax_boost
    return (dynamax?) ? dynamax_calc : 1
  end

  def calc_stats
    dynamax_force_revert
    base_stats = self.baseStats
    this_level = self.level
    this_IV    = self.calcIV
    nature_mod = {}
    GameData::Stat.each_main { |s| nature_mod[s.id] = 100 }
    this_nature = self.nature_for_stats
    if this_nature
      this_nature.stat_changes.each { |change| nature_mod[change[0]] += change[1] }
    end
    stats = {}
    GameData::Stat.each_main do |s|
      if s.id == :HP
        baseHP = calcHP(base_stats[s.id], this_level, this_IV[s.id], @ev[s.id])
        stats[s.id] = (baseHP * dynamax_boost).ceil
      else
        stats[s.id] = calcStat(base_stats[s.id], this_level, this_IV[s.id], @ev[s.id], nature_mod[s.id])
      end
    end
    hp_difference = @totalhp - @hp
    @totalhp = stats[:HP]
    if @hp > 0
      case @dynamax_phase
      when 2
        self.hp = [@totalhp - (hp_difference * dynamax_calc).round, 1].max
      when 1 
        self.hp = [@totalhp - (hp_difference / dynamax_calc).round, 1].max
        @dynamax_lvl = 0 if !dynamax_able?
      else
        self.hp = [@totalhp - hp_difference, 1].max
      end
      @dynamax_phase = 0
    end
    @attack  = stats[:ATTACK]
    @defense = stats[:DEFENSE]
    @spatk   = stats[:SPECIAL_ATTACK]
    @spdef   = stats[:SPECIAL_DEFENSE]
    @speed   = stats[:SPEED]
  end
end


#===============================================================================
# Eternamax Eternatus.
#===============================================================================
MultipleForms.register(:ETERNATUS, {
  "getEternamaxForm" => proc { |pkmn|
    next 1
  },
  "getUnmaxForm" => proc { |pkmn|
    next 0
  },
  "getDataPageInfo" => proc { |pkmn|
    next [pkmn.form, 0] if pkmn.form == 1
  }
})