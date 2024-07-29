#===============================================================================
# Adds new Battle Rules related to SOS calls.
#===============================================================================
class Game_Temp
  alias sos_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "sosbattle"     then rules["SOSBattle"]     = true   # Enables SOS calls
    when "nososbattle"   then rules["SOSBattle"]     = false  # Disables SOS calls
    when "totembattle"   then rules["totemBattle"]   = var    # Sets up a Totem battle
    when "setsospokemon" then rules["setSOSPokemon"] = var    # Replaces SOS species
    when "addsospokemon" then rules["addSOSPokemon"] = var    # Adds an additional SOS species
    else
      sos_add_battle_rule(rule, var)
    end
  end
end

alias sos_additionalRules additionalRules
def additionalRules
  rules = sos_additionalRules
  rules.push("addsospokemon", "setsospokemon", "totembattle")
  return rules
end

module BattleCreationHelperMethods
  module_function
  
  BattleCreationHelperMethods.singleton_class.alias_method :sos_prepare_battle, :prepare_battle
  def prepare_battle(battle)
    BattleCreationHelperMethods.sos_prepare_battle(battle)
    if battle.wildBattle? && !pbInSafari?
      battleRules = $game_temp.battle_rules
      battle.sosBattle    = battleRules["SOSBattle"]     if !battleRules["SOSBattle"].nil?
      battle.primarySOS   = battleRules["setSOSPokemon"] if !battleRules["setSOSPokemon"].nil?
      battle.secondarySOS = battleRules["addSOSPokemon"] if !battleRules["addSOSPokemon"].nil?
      battle.totemBattle  = battleRules["totemBattle"]   if !battleRules["totemBattle"].nil?
    end
  end
end

class SafariBattle
  def totemBattle; return false; end
end

#===============================================================================
# SOS Pokemon editor.
#===============================================================================
EventHandlers.add(:on_sos_pokemon_created, :edit_sos_pokemon,
  proc { |pkmn, data|
    data.each do |property, value|
      next if property == :species
      if pkmn.respond_to?(property.to_s) || [:shiny, :super_shiny].include?(property)
        pkmn.send("#{property}=", value)
      end
    end
  }
)

#===============================================================================
# Midbattle scripts & triggers.
#===============================================================================

#-------------------------------------------------------------------------------
# Used for Totem Battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_global, :wild_totem_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle?
    next if !battle.totemBattle
    next if trigger != "RoundStartCommand_1_foe"
    battle.canRun           = false
    battle.disablePokeBalls = true
    battle.sosBattle        = true
    foe = battle.battlers[1]
    PBDebug.log("[Midbattle Global] #{foe.pbThis} (#{foe.index}) gains a Z-Powered aura")
    battle.pbAnimation(:DRAGONDANCE, foe, foe)
    battle.pbDisplay(_INTL("{1}'s aura flared to life!", foe.pbThis))
    stats = battle.totemBattle 
    if !stats.is_a?(Array)
      stats = []
      GameData::Stat.each_main_battle { |s| stats.push(s.id, 1) }
    end
    showAnim = true
    (stats.length / 2).times do |i|
      foe.pbRaiseStatStage(stats[i * 2], stats[(i * 2) + 1], foe, showAnim)
      showAnim = false
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a wild Pokemon to perform an SOS call.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "sosCall",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battler = battle.battlers[idxBattler]
    if battler && battler.canSOSCallSimple?
      battle.scene.pbForceEndSpeech
	  PBDebug.log("     'sosCall': calling a wild battler")
      battle.pbCallForHelpSimple(battler)
    end
  }
)

#-------------------------------------------------------------------------------
# Toggles the ability for wild Pokemon to call for help.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableSOS",
  proc { |battle, idxBattler, idxTarget, params|
    battle.sosBattle = !params
	value = (battle.sosBattle) ? "enabled" : "disabled"
	PBDebug.log("     'disableSOS': SOS calling has been #{value}")
  }
)

#-------------------------------------------------------------------------------
# Adds a new wild Pokemon in wild battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "addWild",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battle.scene.pbForceEndSpeech
	PBDebug.log("     'addWild': adding a new wild battler")
    battle.pbAddNewBattler(*params)
  }
)

#-------------------------------------------------------------------------------
# Adds a new enemy trainer in trainer battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "addTrainer",
  proc { |battle, idxBattler, idxTarget, params|
    next if battle.decision > 0
    battle.scene.pbForceEndSpeech
	PBDebug.log("     'addWild': adding a new trainer")
    battle.pbAddNewTrainer(*params)
  }
)