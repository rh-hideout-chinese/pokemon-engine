#===============================================================================
# Battle class.
#===============================================================================
class Battle
  attr_accessor :sosBattle
  attr_accessor :totemBattle
  attr_accessor :primarySOS
  attr_accessor :secondarySOS
  attr_accessor :sos_chain
  attr_accessor :adrenalineOrb
  attr_accessor :originalCaller
  attr_accessor :lastTurnCalled
  attr_accessor :lastCallAnswered
  attr_accessor :doubleEVGainSOS
  
  #-----------------------------------------------------------------------------
  # Aliased to initialize SOS properties.
  #-----------------------------------------------------------------------------
  alias sos_initialize initialize
  def initialize(scene, p1, p2, player, opponent)
    sos_initialize(scene, p1, p2, player, opponent)
    @sosBattle         = $game_switches[Settings::SOS_CALL_SWITCH]
    @totemBattle       = nil
    @primarySOS        = nil
    @secondarySOS      = nil
    @sos_chain         = 0
    @adrenalineOrb     = false
    @originalCaller    = nil
    @lastTurnCalled    = 0
    @lastCallAnswered  = nil
    @doubleEVGainSOS   = false
  end
  
  #-----------------------------------------------------------------------------
  # Main initialize method for any type of new battler and/or trainer joining battle.
  #-----------------------------------------------------------------------------
  def pbInitializeNewBattler(battler, trainer = [], fullUpdate = false)
    if fullUpdate
      pbInitGenerateNewBattler(*battler, *trainer)
    else
      pbInitReplaceOldBattler(*battler, *trainer)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Initializes a new battler and/or trainer who joins the battle.
  #-----------------------------------------------------------------------------
  def pbInitGenerateNewBattler(idxBattler, pkmn, idxTrainer = nil, trainer = nil)
    if idxTrainer
      #-------------------------------------------------------------------------
      # Determines new party (trainer)
      #-------------------------------------------------------------------------
      @opponent[idxTrainer] = trainer
      @party2starts[idxTrainer] = @party2.length
      idxParty = @party2starts[idxTrainer]
      @opponent[idxTrainer].party.each { |p| @party2.push(p) }
      partyToAdd = @opponent[idxTrainer].party
      @battleAI.create_new_ai_trainer(idxTrainer)
    else
      #-------------------------------------------------------------------------
      # Determines new party (wild)
      #-------------------------------------------------------------------------
      @party2.push(pkmn)
      idxParty = @party2.length - 1
      partyToAdd = [pkmn]
    end
    #---------------------------------------------------------------------------
    # Initializes new battler and party.
    #---------------------------------------------------------------------------
    @party2order = Array.new(@party2.length) { |i| i }
    pbCreateBattler(idxBattler, pkmn, idxParty)
    @battleAI.create_new_ai_battler(idxBattler)
    pbInitializeSpecialActions(idxTrainer)
    partyToAdd.each_with_index do |p, i|
      @initialItems[1].push(p.item_id)
      @recycleItems[1].push(nil)
      @belch[1].push(false)
      @battleBond[1].push(false)
      @corrosiveGas[1].push(false)
      @usedInBattle[1].push(true)
      @abils_triggered[1].push(false) if defined?(@abils_triggered)
      @rage_hit_count[1].push(0)      if defined?(@rage_hit_count)
      if defined?(@wonderLauncher) && trainerBattle?
        @launcherPoints[1].push(0)
        @launcherCounter[1].push(launcherBattle?)
      end
    end
    @battlers[idxBattler].lastRoundMoved = @turnCount
    @battlers[idxBattler].totemBattler = false
  end
  
  #-----------------------------------------------------------------------------
  # Initializes a new battler and/or trainer who is replacing a previous one.
  #-----------------------------------------------------------------------------
  def pbInitReplaceOldBattler(idxBattler, pkmn, idxTrainer = nil, trainer = nil)
    if idxTrainer
      #-------------------------------------------------------------------------
      # Determines new party (trainer)
      #-------------------------------------------------------------------------
      # Compiles each individual trainer's party.
      trainer_parties = []
      @opponent.length.times do |i|
	    party = []
	    eachInTeam(1, i) { |p| party.push(p) }
        trainer_parties.push(party)
      end
      # Determines the new party to replace the previous one with.
      idxParty = 0
      partyToAdd = []
      @opponent[idxTrainer] = trainer
      trainer_parties[idxTrainer] = trainer.party
      trainer_parties.each_with_index do |tr_party, tr_idx|
	    @party2starts[tr_idx] = idxParty
        tr_party.each do |p|
          idxParty += 1
          if tr_idx == idxTrainer
            partyToAdd.push([p, idxParty])
          end
        end
      end
      @party2 = trainer_parties.flatten
    else
      #-------------------------------------------------------------------------
      # Determines new party (wild)
      #-------------------------------------------------------------------------
      idxParty = 0
      partyToAdd = []
      @battlers.each do |b|
        next if !b || !b.fainted? || b.opposes?(idxBattler)
        idxParty = b.pokemonIndex
        break
      end
      @party2[idxParty] = pkmn
      partyToAdd.push([pkmn, idxParty])
    end
    #---------------------------------------------------------------------------
    # Initializes new battler and party.
    #---------------------------------------------------------------------------
    @party2order = Array.new(@party2.length) { |i| i }
    @battlers[idxBattler].pbInitialize(pkmn, partyToAdd[0][1])
    pbInitializeSpecialActions(idxTrainer)
    partyToAdd.each do |p, i|
      @initialItems[1][i]    = p.item_id
      @recycleItems[1][i]    = nil
      @belch[1][i]           = false
      @battleBond[1][i]      = false
      @corrosiveGas[1][i]    = false
      @usedInBattle[1][i]    = true
      @abils_triggered[1][i] = false if defined?(@abils_triggered)
      @rage_hit_count[1][i]  = 0     if defined?(@rage_hit_count)
      if defined?(@wonderLauncher) && trainerBattle?
        @launcherPoints[1][i]  = 0
        @launcherCounter[1][i] = launcherBattle?
      end
    end
    @battlers[idxBattler].lastRoundMoved = @turnCount
    @battlers[idxBattler].totemBattler = false
  end
  
  #-----------------------------------------------------------------------------
  # Returns an available battler index to be used by the called Pokemon.
  #-----------------------------------------------------------------------------
  def pbFindNewBattlerIndex(caller, answered = true)
    idxNewBattler = -1
    return idxNewBattler if !answered
    changeSize = false
    size = pbSideSize(caller.index)
    6.times do |i|
      b = @battlers[i]
      next if b && !b.fainted?
      next if caller.opposes?(i)
      idxNewBattler = i
      changeSize = b.nil?
      break
    end
    if idxNewBattler < 0 && size < 3
      idxNewBattler = caller.index + (2 * ([1, size - 1].max))
      changeSize = true
    end
    if changeSize
      @sideSizes[caller.idxOwnSide] = size + 1
    end
    return idxNewBattler
  end
  
  #-----------------------------------------------------------------------------
  # Determines the species of the called SOS Pokemon.
  # Certain maps may force unique SOS encounters based on weather/terrain/time.
  # Certain species may call for unique SOS encounters based on species data.
  # Certain SOS encounters may be forced or added due to a set Battle Rule.
  #-----------------------------------------------------------------------------
  def pbGenerateSOSSpecies(caller, roll)
    primarySOS   = (@primarySOS.is_a?(Hash))   ? @primarySOS[:species]   : @primarySOS
    secondarySOS = (@secondarySOS.is_a?(Hash)) ? @secondarySOS[:species] : @secondarySOS
    if caller.totemBattler
      case @sos_chain
      when 1 then return primarySOS   if GameData::Species.exists?(primarySOS)
      when 2 then return secondarySOS if GameData::Species.exists?(secondarySOS)
      end
    end
    sos_species = []
    if GameData::Species.exists?(primarySOS)
      sos_species.push(primarySOS)
    else
      map_data = GameData::MapMetadata.try_get($game_map.map_id)
      if $game_map && map_data&.special_sos.length > 0
        map_data.special_sos.each do |sos|
          next if roll > sos[1]
          case sos[2] # Time of day
          when 1 then next if !PBDayNight.isDay?
          when 2 then next if !PBDayNight.isNight?
          when 3 then next if !PBDayNight.isMorning?
          when 4 then next if !PBDayNight.isAfternoon?
          when 5 then next if !PBDayNight.isEvening?
          end
          case sos[3] # Weather, Terrain, Environment
          when 1 then next if sos[4] != @field.weather
          when 2 then next if sos[4] != @field.terrain
          when 3 then next if sos[4] != @environment
          end
          sos_species.push(sos[0])
          if sos[3] == 1 && GameData::Species.exists?(:CASTFORM) &&
             [:Sun, :HarshSun, :Rain, :HeavyRain, :Hail].include?(sos[4])
            sos_species.push(:CASTFORM)
          end
        end
      end
      if sos_species.empty?
        sp_dat = caller.pokemon.species_data
        check_species = sp_dat.sos_species.clone
        sp_dat.sos_conditional.each do |sos|
          next if sos[1] && sos[1] != $game_temp.encounter_type
          next if sos[2] && $game_map && sos[2] != map_data&.id
          check_species.push(sos[0])
        end
        check_species.each do |sp|
          data = GameData::Species.try_get(sp)
          next if !data
          form = data.base_form
          if data.sos_form >= 0
            form = data.sos_form
          elsif caller.species == data.species
            form = caller.form
            if data.mega_stone || data.mega_move
              form = data.unmega_form
            elsif caller.primal?
              form = caller.getUnprimalForm
            elsif defined?(data.gmax_move) && data.gmax_move
              form = data.ungmax_form
            elsif MultipleForms.hasFunction?(data.species, "getForm") ||
                  MultipleForms.hasFunction?(data.species, "onSetForm") ||
                  MultipleForms.hasFunction?(data.species, "getFormOnCreation")
              form = 0
            elsif MultipleForms.hasFunction?(data.species, "getFormOnLeavingBattle")
              f = MultipleForms.call("getFormOnLeavingBattle", caller.pokemon, self, false, true)
              form = f if !f.nil?
            elsif data.species == :BASCULIN && form < 2
              form = [0, 1].sample
            end
          end
          species = GameData::Species.get_species_form(data.species, form)
          sos_species.push(species.id)
        end
      end
    end
    sos_species.push(secondarySOS) if GameData::Species.exists?(secondarySOS)
    sos_species.compact!
    case sos_species.length
    when 1 then ret = sos_species.first
    when 2 then ret = (roll < 15) ? sos_species.last : sos_species.first
    else        ret = (roll < 15) ? sos_species[2..-1].sample : sos_species.first 
    end
    ret = sos_species.sample if ret.nil?
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Generates the Pokemon object to be called.
  # IV quality, Hidden Ability chance, and shininess determined by SOS chain.
  #-----------------------------------------------------------------------------
  def pbGenerateSOSPokemon(species, level)
    sos_pkmn = pbGenerateWildPokemon(species, level)
    sos_pkmn.form_simple = sos_pkmn.form
    @peer.pbOnStartingBattle(self, sos_pkmn, true)
    if @sos_chain >= 5
      case @sos_chain
      when 5..9    then ratios = [1,  0,  1]
      when 10      then ratios = [2,  5,  1]
      when 11..19  then ratios = [2,  5,  5]
      when 20      then ratios = [3, 10,  5]
      when 21..29  then ratios = [3, 10,  9]
      when 30      then ratios = [4, 15,  9]
      when 31..255 then ratios = [4, 15, 13]
      end
      stats = []
      GameData::Stat.each_main { |s| stats.push(s.id) }
      stats.shuffle.each_with_index do |stat, i|
        break if i >= ratios[0]
        sos_pkmn.iv[stat] = Pokemon::IV_STAT_LIMIT
      end
      sos_pkmn.ability_index = 2 if pbRandom(100) < ratios[1]
      if !sos_pkmn.shiny?
        shiny_retries = ratios[2] * Settings::SOS_CHAIN_SHINY_MULTIPLIER
        if shiny_retries > 1
          shiny_retries += 2 if $bag.has?(:SHINYCHARM)
          shiny_retries.times do
            break if sos_pkmn.shiny?
            sos_pkmn.shiny = nil
            sos_pkmn.personalID = rand(2**16) | (rand(2**16) << 16)
          end
        end
      end
    end
    [@primarySOS, @secondarySOS].each do |data|
      next if !data.is_a?(Hash) || data.empty?
      next if sos_pkmn.species != data[:species]
      EventHandlers.trigger(:on_sos_pokemon_created, sos_pkmn, data)
    end
    return sos_pkmn
  end
  
  #-----------------------------------------------------------------------------
  # Generates the battler object to be called, based on the species/Pokemon.
  #-----------------------------------------------------------------------------
  def pbGenerateSOSBattler(idxBattler, caller, roll)
    species = pbGenerateSOSSpecies(caller, roll)
    level   = [(@originalCaller.level - (pbRandom(5) + 1)), 1].max
    pokemon = pbGenerateSOSPokemon(species, level)
    fullUpdate = @battlers[idxBattler].nil?
    pbInitializeNewBattler([idxBattler, pokemon], [], fullUpdate)
    battler = @battlers[idxBattler]
    @peer.pbOnEnteringBattle(self, battler, pokemon, true)
    return battler
  end
  
  #-----------------------------------------------------------------------------
  # Determines whether to continue or reset the SOS chain based on the caller.
  #-----------------------------------------------------------------------------
  def pbSetSOSChain(caller)
    old_chain = @sos_chain
    if @originalCaller.nil?
      @originalCaller = caller.pokemon
      @sos_chain += 1
      PBDebug.log("[SOS] SOS chain increased (#{old_chain} -> #{@sos_chain})")
    else
      family = @originalCaller.species_data.get_family_species
      if !family.include?(caller.species)
        @originalCaller = caller.pokemon
        @sos_chain = 0
        PBDebug.log("[SOS] SOS chain reset (#{old_chain} -> #{@sos_chain})")
      elsif @sos_chain < 255
        @sos_chain += 1
        PBDebug.log("[SOS] SOS chain increased (#{old_chain} -> #{@sos_chain})")
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Used for actually calling an SOS ally.
  #-----------------------------------------------------------------------------
  def pbCallForHelp(caller)
    roll = pbRandom(100)
    answer_rate  = caller.sos_call_rate * 4.0
    answer_rate *= 1.2 if pbCheckOpposingAbility([:INTIMIDATE, :UNNERVE, :PRESSURE], caller.index, true)
    answer_rate *= 1.5 if @lastTurnCalled == @turnCount - 1
    answer_rate *= 2.0 if caller.tookSuperEffectiveDamage
    answer_rate *= 3.0 if @lastCallAnswered == false
    answered = roll < answer_rate.round || $DEBUG && Input.press?(Input::CTRL)
    pbDeluxeTriggers(caller, nil, "BeforeSOS", caller.species, *caller.pokemon.types)
    if caller.totemBattler
      pbDisplay(_INTL("{1} called its ally Pokémon!", caller.pbThis))
    else
      pbDisplay(_INTL("{1} called for help!", caller.pbThis))
    end
    @scene.pbAnimation(:GROWL, caller, caller.pbDirectOpposing(true))
    pbDisplayPaused(_INTL("... ... ..."))
    idxNewBattler = pbFindNewBattlerIndex(caller, answered)
    if idxNewBattler >= 0
      PBDebug.log("[SOS] #{caller.pbThis}'s (#{caller.index}) call succeeded (Answer rate = #{answer_rate})")
      @lastCallAnswered = true
      @doubleEVGainSOS = true
      pbSetSOSChain(caller)
      battler = pbGenerateSOSBattler(idxNewBattler, caller, roll)
      @scene.pbSOSJoin(idxNewBattler)
      pbDisplay(_INTL("{1} appeared!", battler.name))
      pbCalculatePriority(true)
      pbOnBattlerEnteringBattle(idxNewBattler)
      battler.pbCheckForm
      pbSetSeen(battler)
      pbDeluxeTriggers(caller, nil, "AfterSOS", caller.species, *caller.pokemon.types)
    else
      PBDebug.log("[SOS] #{caller.pbThis}'s (#{caller.index}) call failed (Answer rate = #{answer_rate})")
      @lastCallAnswered = false
      pbDisplay(_INTL("Its help didn't appear!"))
      pbDeluxeTriggers(caller, nil, "FailedSOS", caller.species, *caller.pokemon.types)
    end
    @lastTurnCalled = @turnCount
  end
  
  #-----------------------------------------------------------------------------
  # A simplified version of the method above. Call is guaranteed to be answered.
  #-----------------------------------------------------------------------------
  def pbCallForHelpSimple(caller)
    if caller.totemBattler
      pbDisplay(_INTL("{1} called its ally Pokémon!", caller.pbThis))
    else
      pbDisplay(_INTL("{1} called for help!", caller.pbThis))
    end
    @scene.pbAnimation(:GROWL, caller, caller.pbDirectOpposing(true))
    pbDisplayPaused(_INTL("... ... ..."))
    idxNewBattler = pbFindNewBattlerIndex(caller)
    if idxNewBattler >= 0
      PBDebug.log("[SOS] #{caller.pbThis}'s (#{caller.index}) call succeeded (Answer rate = 100)")
      @lastCallAnswered = true
      battler = pbGenerateSOSBattler(idxNewBattler, caller, pbRandom(100))
      @scene.pbSOSJoin(idxNewBattler)
      pbDisplay(_INTL("{1} appeared!", battler.name))
      pbCalculatePriority(true)
      pbOnBattlerEnteringBattle(idxNewBattler)
      battler.pbCheckForm
    else
      PBDebug.log("[SOS] #{caller.pbThis}'s (#{caller.index}) call failed (Answer rate = 100)")
      @lastCallAnswered = false
      pbDisplay(_INTL("Its help didn't appear!"))
    end
    @lastTurnCalled = @turnCount
  end
  
  #-----------------------------------------------------------------------------
  # Forces a new battler to join the battle, independent of SOS mechanics.
  #-----------------------------------------------------------------------------
  def pbAddNewBattler(species = nil, level = nil)
    return if !wildBattle?
    caller = @battlers[1] || @battlers[3] || @battlers[5]
    idxBattler = pbFindNewBattlerIndex(caller)
    return if idxBattler < 0
    case species
    when Pokemon         then pokemon = species
    when Battle::Battler then pokemon = species.pokemon
    else
      if !species.is_a?(Symbol) || !GameData::Species.exists?(species)
        species = pbGenerateSOSSpecies(caller, pbRandom(100))
      end
      level = [(caller.level - (pbRandom(5) + 1)), 1].max if !level
      pokemon = pbGenerateWildPokemon(species, level)
      pokemon.form_simple = pokemon.form
      @peer.pbOnStartingBattle(self, pokemon, true)
    end
    [@primarySOS, @secondarySOS].each do |data|
      next if !data.is_a?(Hash) || data.empty?
      next if pokemon.species != data[:species]
      EventHandlers.trigger(:on_sos_pokemon_created, pokemon, data)
    end
    fullUpdate = @battlers[idxBattler].nil?
    pbInitializeNewBattler([idxBattler, pokemon], [], fullUpdate)
    battler = @battlers[idxBattler]
    @peer.pbOnEnteringBattle(self, battler, pokemon, true)
    @scene.pbSOSJoin(idxBattler)
    pbDisplay(_INTL("{1} appeared!", battler.name))
    pbCalculatePriority(true)
    pbOnBattlerEnteringBattle(idxBattler)
    battler.pbCheckForm
    pbSetSeen(battler)
  end
  
  #-----------------------------------------------------------------------------
  # Adds a new trainer to the battle.
  #-----------------------------------------------------------------------------
  def pbAddNewTrainer(tr_type, tr_name, version = 0)
    return if !trainerBattle?
    caller = @battlers[1] || @battlers[3] || @battlers[5]
    idxBattler = pbFindNewBattlerIndex(caller)
    return if idxBattler < 0
    idxTrainer = -1
    3.times do |i|
      sideCounts = pbAbleTeamCounts(1)[i]
      next if sideCounts && sideCounts > 0
      idxTrainer = i
      break
    end
    return if idxTrainer < 0 
    trainer = pbLoadTrainer(tr_type, tr_name, version)
    EventHandlers.trigger(:on_trainer_load, trainer)
    pokemon = trainer.party.first
    fullUpdate = @battlers[idxBattler].nil?
    pbInitializeNewBattler([idxBattler, pokemon], [idxTrainer, trainer], fullUpdate)
    @items[idxTrainer] = trainer.items
    pbSetLauncherItems(1, idxTrainer) if launcherBattle?
    battler = @battlers[idxBattler]
    @scene.pbTrainerJoin(idxBattler, idxTrainer)
    pbCalculatePriority(true)
    pbOnBattlerEnteringBattle(idxBattler)
    battler.pbCheckForm
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so eligible wild Pokemon may SOS call at the end of each round.
  #-----------------------------------------------------------------------------
  alias sos_pbEndOfRoundPhase pbEndOfRoundPhase
  def pbEndOfRoundPhase
    sos_pbEndOfRoundPhase
    if wildBattle?
      pbPriority(true).each do |b|
        next if !b || b.fainted? || !b.wild?
        next if !b.canSOSCall?
        pbCallForHelp(b)
        b.tookSuperEffectiveDamage = false
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # Edited so that EV gains are doubled after a successful SOS call.
  #-----------------------------------------------------------------------------
  def pbGainEVsOne(idxParty, defeatedBattler)
    pkmn = pbParty(0)[idxParty]
    evYield = defeatedBattler.pokemon.evYield
    evTotal = 0
    GameData::Stat.each_main { |s| evTotal += pkmn.ev[s.id] }
    if !Battle::ItemEffects.triggerEVGainModifier(pkmn.item, pkmn, evYield)
      Battle::ItemEffects.triggerEVGainModifier(@initialItems[0][idxParty], pkmn, evYield)
    end
    if pkmn.pokerusStage >= 1
      evYield.each_key { |stat| evYield[stat] *= 2 }
    end
    if @doubleEVGainSOS
      evYield.each_key { |stat| evYield[stat] *= 2 }
    end
    if pkmn.shadowPokemon? && pkmn.heartStage <= 3 && pkmn.saved_ev
      pkmn.saved_ev.each_value { |e| evTotal += e }
      GameData::Stat.each_main do |s|
        evGain = evYield[s.id].clamp(0, Pokemon::EV_STAT_LIMIT - pkmn.ev[s.id] - pkmn.saved_ev[s.id])
        evGain = evGain.clamp(0, Pokemon::EV_LIMIT - evTotal)
        pkmn.saved_ev[s.id] += evGain
        evTotal += evGain
      end
    else
      GameData::Stat.each_main do |s|
        evGain = evYield[s.id].clamp(0, Pokemon::EV_STAT_LIMIT - pkmn.ev[s.id])
        evGain = evGain.clamp(0, Pokemon::EV_LIMIT - evTotal)
        pkmn.ev[s.id] += evGain
        evTotal += evGain
      end
    end
  end
end