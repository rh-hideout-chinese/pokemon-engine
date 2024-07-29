#===============================================================================
# Additions to the Battle class.
#===============================================================================
class Battle
  attr_accessor :terastallize, :boosted_tera_types
  
  #-----------------------------------------------------------------------------
  # Aliases for Terastallization.
  #-----------------------------------------------------------------------------
  alias tera_initialize initialize
  def initialize(*args)
    tera_initialize(*args)
    @boosted_tera_types = [
       [[]] * (@player ? @player.length : 1),
       [[]] * (@opponent ? @opponent.length : 1)
    ]
    @terastallize = [
       [-1] * (@player ? @player.length : 1),
       [-1] * (@opponent ? @opponent.length : 1)
    ]
    @tera_orbs = []
    GameData::Item.each { |item| @tera_orbs.push(item.id) if item.has_flag?("TeraOrb") }
  end
  
  alias tera_pbInitializeSpecialActions pbInitializeSpecialActions
  def pbInitializeSpecialActions(idxTrainer)
    return if !idxTrainer
    tera_pbInitializeSpecialActions(idxTrainer)
    @terastallize[1][idxTrainer] = -1
  end
  
  alias tera_pbCanUseAnyBattleMechanic? pbCanUseAnyBattleMechanic?
  def pbCanUseAnyBattleMechanic?(idxBattler)
    return true if pbCanTerastallize?(idxBattler)
    return tera_pbCanUseAnyBattleMechanic?(idxBattler)
  end
  
  alias tera_pbCanUseBattleMechanic? pbCanUseBattleMechanic?
  def pbCanUseBattleMechanic?(idxBattler, mechanic)
    return true if mechanic == :tera && pbCanTerastallize?(idxBattler)
    return tera_pbCanUseBattleMechanic?(idxBattler, mechanic)
  end
  
  alias tera_pbGetEligibleBattleMechanic pbGetEligibleBattleMechanic
  def pbGetEligibleBattleMechanic(idxBattler)
    return :tera if pbCanTerastallize?(idxBattler)
    return tera_pbGetEligibleBattleMechanic(idxBattler)
  end
  
  alias tera_pbUnregisterAllSpecialActions pbUnregisterAllSpecialActions
  def pbUnregisterAllSpecialActions(idxBattler)
    tera_pbUnregisterAllSpecialActions(idxBattler)
    pbUnregisterTerastallize(idxBattler)
  end
  
  alias tera_pbBattleMechanicIsRegistered? pbBattleMechanicIsRegistered?
  def pbBattleMechanicIsRegistered?(idxBattler, mechanic)
    return true if mechanic == :tera && pbRegisteredTerastallize?(idxBattler)
    return tera_pbBattleMechanicIsRegistered?(idxBattler, mechanic)
  end
  
  alias tera_pbToggleSpecialActions pbToggleSpecialActions
  def pbToggleSpecialActions(idxBattler, cmd)
    tera_pbToggleSpecialActions(idxBattler, cmd)
    pbToggleRegisteredTerastallize(idxBattler) if cmd == :tera
  end
  
  alias tera_pbActionCommands pbActionCommands
  def pbActionCommands(side)
    tera_pbActionCommands(side)
    @terastallize[side].each_with_index do |tera, i|
      @terastallize[side][i] = -1 if tera >= 0
    end
  end
  
  alias tera_pbAttackPhaseSpecialActions3 pbAttackPhaseSpecialActions3
  def pbAttackPhaseSpecialActions3
    tera_pbAttackPhaseSpecialActions3
    pbPriority.each do |b|
      next unless @choices[b.index][0] == :UseMove && !b.fainted?
      owner = pbGetOwnerIndexFromBattlerIndex(b.index)
      next if @terastallize[b.idxOwnSide][owner] != b.index
      pbTerastallize(b.index)
    end
  end
  
  alias tera_pbPursuitSpecialActions pbPursuitSpecialActions
  def pbPursuitSpecialActions(battler, owner)
    tera_pbPursuitSpecialActions(battler, owner)
    pbTerastallize(battler.index) if @terastallize[battler.idxOwnSide][owner] == battler.index
  end
  
  #-----------------------------------------------------------------------------
  # Tera Orbs
  #-----------------------------------------------------------------------------
  def pbHasTeraOrb?(idxBattler)
    return true if @battlers[idxBattler].wild?
    if pbOwnedByPlayer?(idxBattler)
      @tera_orbs.each { |item| return true if $bag.has?(item) }
    else
      trainer_items = pbGetOwnerItems(idxBattler)
      return false if !trainer_items
      @tera_orbs.each { |item| return true if trainer_items.include?(item) }
    end
    return false
  end
  
  def pbGetTeraOrbName(idxBattler)
    if !@tera_orbs.empty?
      if pbOwnedByPlayer?(idxBattler)
        @tera_orbs.each { |item| return GameData::Item.get(item).name if $bag.has?(item) }
      else
        trainer_items = pbGetOwnerItems(idxBattler)
        @tera_orbs.each { |item| return GameData::Item.get(item).name if trainer_items&.include?(item) }
      end
    end
    return _INTL("Tera Orb")
  end
  
  #-----------------------------------------------------------------------------
  # Aliased so Illusion fails to copy Terastal forms/Terastal form Terapagos.
  #-----------------------------------------------------------------------------
  alias tera_pbLastInTeam pbLastInTeam
  def pbLastInTeam(idxBattler)
    ret = tera_pbLastInTeam(idxBattler)
    if ret > 0
      pkmn = pbParty(idxBattler)[ret]
      ret = -1 if pkmn.tera_form? || 
                 (pkmn.isSpecies?(:TERAPAGOS) && pkmn.form > 0)
    end
    return ret
  end
  
  #-----------------------------------------------------------------------------
  # Eligibility check.
  #-----------------------------------------------------------------------------
  def pbCanTerastallize?(idxBattler)
    battler = @battlers[idxBattler]
    return false if $game_switches[Settings::NO_TERASTALLIZE]               # Don't Terastallize if switch enabled.
    return false if !battler.hasTera?                                       # Don't Terastallize if ineligible.
    return true if $DEBUG && Input.press?(Input::CTRL) && !battler.wild?    # Allows Terastallization with CTRL in Debug.
    return false if battler.effects[PBEffects::SkyDrop] >= 0                # Don't Terastallize if in Sky Drop.
    return false if !pbHasTeraOrb?(idxBattler)                              # Don't Terastallize if no Tera Orb, unless wild Pokemon.
    return false if pbOwnedByPlayer?(idxBattler) && !$player.tera_charged?  # Don't Terastallize if player and Tera Orb not charged.
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @terastallize[side][owner] == -1
  end
  
  #-----------------------------------------------------------------------------
  # Terastallization.
  #-----------------------------------------------------------------------------
  def pbTerastallize(idxBattler)
    battler = @battlers[idxBattler]
    return if !battler || !battler.pokemon
    return if !battler.hasTera? || battler.tera?
    $stats.terastallize_count += 1 if battler.pbOwnedByPlayer?
    pbDeluxeTriggers(idxBattler, nil, "BeforeTerastallize", battler.species, battler.tera_type)
    @scene.pbAnimateSubstitute(idxBattler, :hide)
    old_ability = battler.ability_id
    if battler.hasActiveAbility?(:ILLUSION)
      illusion = battler.effects[PBEffects::Illusion]
      if illusion && (battler.pokemon.hasTerastalForm? || illusion.hasTerastalForm?)
        Battle::AbilityEffects.triggerOnBeingHit(battler.ability, nil, battler, nil, self)
      end
    end
    pbAnimateTerastallization(battler)
    pbDisplay(_INTL("{1} Terastallized into the {2}-type!", battler.pbThis, GameData::Type.get(battler.tera_type).name))
    if battler.tera_form?
      battler.pbOnLosingAbility(old_ability)
      battler.pbTriggerAbilityOnGainingIt
      pbCalculatePriority(false, [idxBattler]) if Settings::RECALCULATE_TURN_ORDER_AFTER_MEGA_EVOLUTION
    end
    side  = battler.idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @terastallize[side][owner] = -2
    if battler.tera_type == :STELLAR
      GameData::Type.each do |t| 
        next if t.pseudo_type
        next if @boosted_tera_types[side][owner].include?(t.id)
        @boosted_tera_types[side][owner].push(t.id)
      end
    end
    if pbOwnedByPlayer?(idxBattler) && !$game_switches[Settings::TERA_ORB_ALWAYS_CHARGED]
      return if $DEBUG && Input.press?(Input::CTRL)
      # Tera Orb doesn't require recharging in Area Zero.
      map_data = GameData::MapMetadata.try_get($game_map.map_id)
      return if $game_map && map_data&.has_flag?("AreaZero")
      $player.tera_charged = false
    end
    pbDeluxeTriggers(idxBattler, nil, "AfterTerastallize", battler.species, battler.tera_type)
    @scene.pbAnimateSubstitute(idxBattler, :show)
  end
  
  #-----------------------------------------------------------------------------
  # Animates Terastallization and updates the battler's attributes.
  #-----------------------------------------------------------------------------
  def pbAnimateTerastallization(battler)
    if @scene.pbCommonAnimationExists?("Terastallize")
      pbCommonAnimation("Terastallize", battler)
      battler.pokemon.terastallized = true
      battler.form_update
      pbCommonAnimation("Terastallize2", battler)
    else 
      if Settings::SHOW_TERA_ANIM && $PokemonSystem.battlescene == 0
        @scene.pbShowTerastallize(battler.index)
        battler.pokemon.terastallized = true
        battler.form_update
      else
        if battler.wild?
          pbDisplay(_INTL("{1} surrounded itself in Terastal energy!", battler.pbThis))
        else
          trainerName = pbGetOwnerName(battler.index)
          pbDisplay(_INTL("{1} is reacting to {2}'s {3}!", battler.pbThis, trainerName, pbGetTeraOrbName(battler.index)))
        end
        @scene.pbRevertBattlerStart(battler.index)
        battler.pokemon.terastallized = true
        battler.form_update
        @scene.pbRevertTera(battler.index)
      end
    end
    battler.ability_id = battler.pokemon.ability_id
  end
  
  #-----------------------------------------------------------------------------
  # Reverting Terastallization. (End of battle)
  #-----------------------------------------------------------------------------
  alias tera_pbEndOfBattle pbEndOfBattle
  def pbEndOfBattle
    @battlers.each { |b| b.unTera if b&.tera? }
    $player.party.each { |p| p.terastallized = false if p&.tera? }
    tera_pbEndOfBattle
  end
  
  #-----------------------------------------------------------------------------
  # Registering Terastallization.
  #-----------------------------------------------------------------------------
  def pbRegisterTerastallize(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @terastallize[side][owner] = idxBattler
  end

  def pbUnregisterTerastallize(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    @terastallize[side][owner] = -1 if @terastallize[side][owner] == idxBattler
  end
  
  def pbToggleRegisteredTerastallize(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    if @terastallize[side][owner] == idxBattler
      @terastallize[side][owner] = -1
    else
      @terastallize[side][owner] = idxBattler
    end
  end

  def pbRegisteredTerastallize?(idxBattler)
    side  = @battlers[idxBattler].idxOwnSide
    owner = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    return @terastallize[side][owner] == idxBattler
  end
end

#-------------------------------------------------------------------------------
# Reverting Terastallization. (Capture)
#-------------------------------------------------------------------------------
module Battle::CatchAndStoreMixin
  alias tera_pbStorePokemon pbStorePokemon
  def pbStorePokemon(pkmn)
    pkmn.terastallized = false
    tera_pbStorePokemon(pkmn)
  end
end