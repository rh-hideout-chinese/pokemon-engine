#-------------------------------------------------------------------------------
# Game stat tracking for terastallization.
#-------------------------------------------------------------------------------
class GameStats
  alias tera_initialize initialize
  def initialize
    tera_initialize
    @terastallize_count       = 0
    @wild_tera_battles_won    = 0
    @total_tera_types_changed = 0
  end
  
  def terastallize_count
    return @terastallize_count || 0
  end
  
  def terastallize_count=(value)
    @terastallize_count = 0 if !@terastallize_count
    @terastallize_count = value
  end
  
  def wild_tera_battles_won
    return @wild_tera_battles_won || 0
  end
  
  def wild_tera_battles_won=(value)
    @wild_tera_battles_won = 0 if !@wild_tera_battles_won
    @wild_tera_battles_won = value
  end
  
  def total_tera_types_changed
    return @total_tera_types_changed || 0
  end
  
  def total_tera_types_changed=(value)
    @total_tera_types_changed = 0 if !@total_tera_types_changed
    @total_tera_types_changed = value
  end
end

#-------------------------------------------------------------------------------
# Player Tera-related methods.
#-------------------------------------------------------------------------------
class Player < Trainer
  attr_accessor :tera_charge
  
  def tera_charged?
    @tera_charge = true if @tera_charge.nil?
    return @tera_charge
  end
  
  def tera_charged=(value)
    @tera_charge = value
  end
  
  def has_pokemon_tera_type?(type)
    return false if !GameData::Type.exists?(type)
    type = GameData::Type.get(type).id
    return pokemon_party.any? { |p| p&.tera_type == type }
  end
end

#-------------------------------------------------------------------------------
# Recharges player's Tera Orb when healing at a Pokemon Center.
#-------------------------------------------------------------------------------
class Interpreter
  alias tera_command_314 command_314
  def command_314
    $player.tera_charged = true
    return tera_command_314
  end
end

#-------------------------------------------------------------------------------
# Adds Tera types as a property for NPC trainer's Pokemon.
#-------------------------------------------------------------------------------
module GameData
  class Trainer
    SUB_SCHEMA["NoTera"]   = [:no_tera,   "b"]
    SUB_SCHEMA["TeraType"] = [:tera_type, "e", :Type]
	
    alias tera_to_trainer to_trainer
    def to_trainer
      trainer = tera_to_trainer
      trainer.party.each_with_index do |pkmn, i|
	    if pkmn.shadowPokemon? || @pokemon[i][:no_tera]
        pkmn.tera_type = nil
        pkmn.terastal_able = false
      else
        pkmn.tera_type = @pokemon[i][:tera_type]
      end
        pkmn.calc_stats
      end
      return trainer
    end
  end
end

module TrainerPokemonProperty
  TrainerPokemonProperty.singleton_class.alias_method :tera_editor_settings, :editor_settings
  def self.editor_settings(initsetting)
    initsetting = {:species => nil, :level => 10} if !initsetting
    oldsetting, keys = self.tera_editor_settings(initsetting)
    [:no_tera, :tera_type].each do |sym|
      oldsetting.push(initsetting[sym])
      keys.push(sym)
    end
    return oldsetting, keys
  end
  
  TrainerPokemonProperty.singleton_class.alias_method :tera_editor_properties, :editor_properties
  def self.editor_properties(oldsetting)
    properties = self.tera_editor_properties(oldsetting)
    properties.concat([
      [_INTL("No Tera"),   BooleanProperty2,            _INTL("If set to true, the trainer will never Terastallize this Pokémon.")],
      [_INTL("Tera Type"), GameDataProperty.new(:Type), _INTL("Tera type of the Pokémon.")]
    ])
    return properties
  end
end

#-------------------------------------------------------------------------------
# Battle Rules.
#-------------------------------------------------------------------------------
class Game_Temp
  alias tera_add_battle_rule add_battle_rule
  def add_battle_rule(rule, var = nil)
    rules = self.battle_rules
    case rule.to_s.downcase
    when "wildterastallize" then rules["wildBattleMode"] = :tera
    when "noterastallize"   then rules["noTerastallize"] = var
    else
      tera_add_battle_rule(rule, var)
    end
  end
end

alias tera_additionalRules additionalRules
def additionalRules
  rules = tera_additionalRules
  rules.push("noterastallize")
  return rules
end

#-------------------------------------------------------------------------------
# Used for wild Tera battles.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_global, :wild_tera_battle,
  proc { |battle, idxBattler, idxTarget, trigger|
    next if !battle.wildBattle? || pbInSafari?
    next if battle.wildBattleMode != :tera
    foe = battle.battlers[1]
    next if !foe.wild?
    logname = _INTL("{1} ({2})", foe.pbThis, foe.index)
    case trigger
    when "RoundStartCommand_1_foe"
      if battle.pbCanTerastallize?(foe.index)
        PBDebug.log("[Midbattle Global] #{logname} will Terastallize.")
        battle.pbTerastallize(foe.index)
        battle.disablePokeBalls = true
        battle.sosBattle = false if defined?(battle.sosBattle)
        battle.totemBattle = nil if defined?(battle.totemBattle)
        foe.damageThreshold = 20
      else
        battle.wildBattleMode = nil
      end
    when "BattlerReachedHPCap_foe"
      PBDebug.log("[Midbattle Global] #{logname} damage cap reached.")
      foe.unTera(true)
      battle.noBag = false
      battle.disablePokeBalls = false
      battle.pbDisplayPaused(_INTL("{1}'s Tera Jewel shattered!\nIt may now be captured!", foe.pbThis))
    when "BattleEndWin"
      if battle.wildBattleMode == :tera
        $stats.wild_tera_battles_won += 1
      end
    end
  }
)

#-------------------------------------------------------------------------------
# Forces a trainer to Terastallize.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "terastallize",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !params || !battler || battler.fainted? || battle.decision > 0
    ch = battle.choices[battler.index]
    next if ch[0] != :UseMove
    oldMode = battle.wildBattleMode
    battle.wildBattleMode = :tera if battler.wild? && oldMode != :tera
    $player.tera_charged = true if battler.pbOwnedByPlayer?
    if battle.pbCanTerastallize?(battler.index)
      PBDebug.log("     'terastallize': #{battler.name} (#{battler.index}) set to Terastallize")
      battle.scene.pbForceEndSpeech
      battle.pbDisplay(params.gsub(/\\PN/i, battle.pbPlayer.name)) if params.is_a?(String)
      battle.pbTerastallize(battler.index)
    end
    battle.wildBattleMode = oldMode
  }
)

#-------------------------------------------------------------------------------
# Toggles the availability of Terastallization for trainers.
#-------------------------------------------------------------------------------
MidbattleHandlers.add(:midbattle_triggers, "disableTera",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler 
    side = (battler.opposes?) ? 1 : 0
    owner = battle.pbGetOwnerIndexFromBattlerIndex(idxBattler)
    battle.terastallize[side][owner] = (params) ? -2 : -1
    $player.tera_charged = !params if battler.pbOwnedByPlayer?
    value = (params) ? "disabled" : "enabled"
    trainerName = battle.pbGetOwnerName(idxBattler)
    PBDebug.log("     'disableTera': Terastallization #{value} for #{trainerName}")
  }
)