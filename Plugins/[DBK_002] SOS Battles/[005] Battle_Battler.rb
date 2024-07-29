#===============================================================================
# Battle::Battler class.
#===============================================================================
class Battle::Battler
  attr_accessor :totemBattler
  attr_accessor :tookSuperEffectiveDamage
  
  #-----------------------------------------------------------------------------
  # Aliased to flag wild Pokemon as Totems if this is a Totem battle.
  #-----------------------------------------------------------------------------
  alias totem_pbInitEffects pbInitEffects
  def pbInitEffects(batonPass)
    totem_pbInitEffects(batonPass)
    @totemBattler = !@battle.totemBattle.nil?
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to refer to Totem Pokemon as "Totem __" instead of "The wild __".
  #-----------------------------------------------------------------------------
  alias totem_pbThis pbThis
  def pbThis(lowerCase = false)
    if @totemBattler && opposes? && wild?
      return _INTL("Totem {1}", name)
    else
      return totem_pbThis(lowerCase)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Gets the base SOS call rate for this battler.
  #-----------------------------------------------------------------------------
  def sos_call_rate
    return 100 if @totemBattler
    rate = @pokemon.species_data.sos_call_rate
    rate = 9 if rate <= 0 && (@battle.primarySOS || @battle.secondarySOS)
    return rate
  end
  
  #-----------------------------------------------------------------------------
  # Checks if the battler is capable of using an SOS call.
  #-----------------------------------------------------------------------------
  def canSOSCall?
    return false if !@battle.sosBattle
    return false if @battle.trainerBattle?
    return false if @battle.allSameSideBattlers(@index).length >= 2
    return false if !wild? || !opposes? || fainted? || usingMultiTurnAttack?
    return false if !getActiveState.nil?
    eachAlly { |b| return false if b }
    if @battle.totemBattle
      return false if !@totemBattler
      return false if @battle.sos_chain > 1
      return true if @battle.turnCount == 0
      return true if self.hp < self.totalhp / 3
      return false
    end
    return true if $DEBUG && Input.press?(Input::CTRL)
    return false if sos_call_rate <= 0
    return false if pbHasAnyStatus?
    return false if pbOwnSide.effects[PBEffects::LastRoundFainted] == @battle.turnCount
    if Settings::LIMIT_SOS_CALLS_TO_ONE
      return false if @battle.lastCallAnswered && !@battle.adrenalineOrb
    end
    call_rate = sos_call_rate
    if self.hp <= self.totalhp / 4
      call_rate *= 5
    elsif self.hp <= self.totalhp / 2
      call_rate *= 3
    end
    call_rate *= 2 if @battle.adrenalineOrb
    call = @battle.pbRandom(100) < call_rate
    PBDebug.log("[SOS] #{pbThis} (#{@index}) will call for help (Call rate = #{call_rate})") if call
    return call
  end
  
  #-----------------------------------------------------------------------------
  # Simplified version of the check above. Only checks for the essentials.
  #-----------------------------------------------------------------------------
  def canSOSCallSimple?
    return false if @battle.trainerBattle?
    return false if !@battle.sosBattle
    return false if !wild? || !opposes? || fainted? || usingMultiTurnAttack?
    return false if @battle.allSameSideBattlers(@index).length >= 3
    return true
  end
  
  #-----------------------------------------------------------------------------
  # Utility for checking if two battlers are of rival species.
  #-----------------------------------------------------------------------------
  def isRivalSpecies?(battler)
    user_data = @pokemon.species_data
    targ_data = battler.displayPokemon.species_data
    targ_id = (user_data.has_flag?("AllRivalForms")) ? targ_data.species : targ_data.id
    return user_data.rival_species.include?(targ_id)
  end
end