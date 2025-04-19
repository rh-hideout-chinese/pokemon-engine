#===============================================================================
# Adds a new effect to store the data of the Pokemon the user transformed into.
#===============================================================================
module PBEffects
  TransformPokemon = 200 
end

#===============================================================================
# GameData utilities.
#===============================================================================
module GameData
  class Species
    def has_special_form?
      return true if @mega_stone || @mega_move
      return true if defined?(@gmax_move) && @gmax_move
      ["getPrimalForm", "getUltraForm", "getEternamaxForm", "getTerastalForm"].each do |function|
        return true if MultipleForms.hasFunction?(@species, function)
      end
      return false
    end
  end
  
  class Move
    def powerMove?
      return true if defined?(zMove?) && zMove?
      return true if defined?(dynamaxMove?) && dynamaxMove?
      return false
    end
  end
end

#===============================================================================
# Battle::Move utilities.
#===============================================================================
class Battle::Move
  attr_accessor :short_name
  
  #-----------------------------------------------------------------------------
  # Initializes shortened move names for moves with very long names.
  #-----------------------------------------------------------------------------
  alias dx_initialize initialize
  def initialize(battle, move)
    dx_initialize(battle, move)
    @short_name = (Settings::SHORTEN_MOVES && @name.length > 16) ? @name[0..12] + "..." : @name
  end
  
  #-----------------------------------------------------------------------------
  # Utility used for checking for Z-Moves/Dynamax moves, if any exist.
  #-----------------------------------------------------------------------------
  def powerMove?
    return true if defined?(zMove?) && zMove?
    return true if defined?(dynamaxMove?) && dynamaxMove?
    return false
  end
end

#===============================================================================
# Battle utilities.
#===============================================================================
class Battle
  #-----------------------------------------------------------------------------
  # Utility for checking if any battler on a particular side is at low HP.
  #-----------------------------------------------------------------------------
  def pbAnyBattlerLowHP?(idxBattler)
    allSameSideBattlers(idxBattler).each { |b| return true if b.hasLowHP? }
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Utility for checking if a trainer has any available Pokemon left in the party.
  #-----------------------------------------------------------------------------
  def pbTeamAllFainted?(idxSide, idxTrainer)
    teamCount = 0
    eachInTeam(idxSide, idxTrainer) { |pkmn, _i| teamCount += 1 if pkmn.able? }
    return teamCount == 0
  end
  
  #-----------------------------------------------------------------------------
  # Utility for returning an array of each battler owned by a particular trainer.
  #-----------------------------------------------------------------------------
  def allOwnedByTrainer(idxBattler)
    idxTrainer = pbGetOwnerIndexFromBattlerIndex(idxBattler)
    allies = allSameSideBattlers(idxBattler)
    allies.select { |b| b && !b.fainted? && pbGetOwnerIndexFromBattlerIndex(b.index) == idxTrainer }
  end
  
  #-----------------------------------------------------------------------------
  # Edits item messages for more descriptive use.
  #-----------------------------------------------------------------------------
  def pbUseItemMessage(item, trainerName, pkmn = nil)
    item_data = GameData::Item.get(item)
    itemName = item_data.portion_name
    if pkmn.is_a?(Battle::Battler) && item_data.battle_use < 4
      pbDisplayBrief(_INTL("{1}对{3}使用了{2}。", trainerName, itemName, pkmn.pbThis(true)))
    elsif pkmn.is_a?(Pokemon) && item_data.battle_use < 4
      pbDisplayBrief(_INTL("{1}对{3}使用了{2}。", trainerName, itemName, pkmn.name))
    else
      pbDisplayBrief(_INTL("{1}使用了{2}。", trainerName, itemName))
    end
  end
end

#===============================================================================
# Battle::Battler utilities.
#===============================================================================
class Battle::Battler
  attr_accessor :baseMoves
  attr_accessor :powerMoveIndex
  attr_accessor :hpThreshold, :damageThreshold
  attr_accessor :stopBoostedHPScaling
  
  #-----------------------------------------------------------------------------
  # Initializes properties used by various plugin features.
  #-----------------------------------------------------------------------------
  alias dx_pbInitEffects pbInitEffects  
  def pbInitEffects(batonPass)
    @baseMoves            = []
    @powerMoveIndex       = -1
    @hpThreshold          = 0
    @damageThreshold      = 0
    @stopBoostedHPScaling = false
    dx_pbInitEffects(batonPass)
    @effects[PBEffects::TransformPokemon] = nil
  end
  
  #-----------------------------------------------------------------------------
  # Utility for getting the Pokemon a battler is displaying as.
  #-----------------------------------------------------------------------------
  def visiblePokemon
    return @effects[PBEffects::TransformPokemon] if @effects[PBEffects::TransformPokemon]
    return displayPokemon
  end
  
  #-----------------------------------------------------------------------------
  # Utility for checking if the battler is at low HP.
  #-----------------------------------------------------------------------------
  def hasLowHP?
    return false if fainted?
    return @hp <= (@totalhp / 4).floor
  end
  
  #-----------------------------------------------------------------------------
  # Aliased to update BGM when the HP of the player's battler updates.
  #-----------------------------------------------------------------------------
  alias dx_pbUpdate pbUpdate
  def pbUpdate(fullChange = false)
    dx_pbUpdate(fullChange)
    pbUpdateLowHPMusic if @pokemon
  end
  
  def pbUpdateLowHPMusic
    return if !Settings::PLAY_LOW_HP_MUSIC
    return if !pbOwnedByPlayer?
    track = pbGetBattleLowHealthBGM
    return if !track.is_a?(RPG::AudioFile)
    if @battle.pbAnyBattlerLowHP?(@index)
      if @battle.playing_bgm != track.name
        @battle.pbPauseAndPlayBGM(track)
      end
    elsif @battle.playing_bgm == track.name
      @battle.pbResumeBattleBGM
    end
  end
  
  #-----------------------------------------------------------------------------
  # Utility for resetting a battler's moves back to its original moveset.
  #-----------------------------------------------------------------------------
  def display_base_moves
    return if @baseMoves.empty?
    for i in 0...@moves.length
      next if !@baseMoves[i]
      if @baseMoves[i].is_a?(Battle::Move)
        @moves[i] = @baseMoves[i]
      else
        @moves[i] = Battle::Move.from_pokemon_move(@battle, @baseMoves[i])
      end
    end
    @baseMoves.clear
  end
  
  #-----------------------------------------------------------------------------
  # Utilities for checking compatibility with special actions.
  #-----------------------------------------------------------------------------
  def getActiveState
    return :mega      if mega?
    return :primal    if primal?
    return :ultra     if ultra?
    return :dynamax   if dynamax?
    return :style     if style?
    return :tera      if tera?
    return :celestial if celestial?
    return nil
  end
  
  def hasEligibleAction?(*args)
    args.each do |arg|
      case arg
      when :mega    then return true if hasMega?
      when :primal  then return true if hasPrimal?
      when :zmove   then return true if hasZMove?
      when :ultra   then return true if hasUltra?
      when :dynamax then return true if hasDynamax?
      when :style   then return true if hasStyle?
      when :tera    then return true if hasTera?
      when :zodiac  then return true if hasZodiacPower?
      end
    end
    return false	
  end

  #-----------------------------------------------------------------------------
  # Utility for refreshing a battler's form.
  #-----------------------------------------------------------------------------
  def form_update(fullupdate = false)
    if self.form != @pokemon.form
      self.form = @pokemon.form
    end
    pbUpdate(fullupdate)
    pkmn = @effects[PBEffects::TransformPokemon] || displayPokemon
    @battle.scene.pbChangePokemon(self, pkmn)
    @battle.scene.pbRefreshOne(@index)
  end
  
  #-----------------------------------------------------------------------------
  # Used to check if the battler is able to protect against a specified move.
  #-----------------------------------------------------------------------------
  def isProtected?(user, move)
    return false if move.function_code == "IgnoreProtections"
    return false if user.hasActiveAbility?(:UNSEENFIST) && move.contactMove?
    return true if @damageState.protected
    return true if pbOwnSide.effects[PBEffects::MatBlock]
    return true if pbOwnSide.effects[PBEffects::WideGuard] && 
                   GameData::Target.get(move.target).num_targets > 1
    [:Protect, :KingsShield, :SpikyShield, :BanefulBunker, :Obstruct, 
     :SilkTrap, :BurningBulwark].each do |id|
      next if !PBEffects.const_defined?(id)
      effect = PBEffects.const_get(id)
      return true if @effects[effect]
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Identical to pbChangeForm except it ignores learning new moves for certain species.
  #-----------------------------------------------------------------------------
  def pbSimpleFormChange(newForm, msg)
    return if fainted? || @effects[PBEffects::Transform] || @form == newForm
    @battle.scene.pbAnimateSubstitute(self, :hide)
    oldForm = @form
    oldDmg = @totalhp - @hp
    @form = newForm
    @pokemon.form_simple = newForm if @pokemon
    pbUpdate(true)
    @hp = @totalhp - oldDmg
    @effects[PBEffects::WeightChange] = 0 if Settings::MECHANICS_GENERATION >= 6
    @mosaicChange = true if defined?(@mosaicChange)
    @battle.scene.pbChangePokemon(self, @pokemon)
    @battle.scene.pbRefreshOne(@index)
    @battle.pbDisplay(msg) if msg && msg != ""
    PBDebug.log("[Form changed] #{pbThis} changed from form #{oldForm} to form #{newForm}")
    @battle.pbSetSeen(self)
    @battle.scene.pbAnimateSubstitute(self, :show)
  end
  
  #-----------------------------------------------------------------------------
  # Checks for form changes upon changing the battler's held item.
  #-----------------------------------------------------------------------------
  def pbCheckFormOnHeldItemChange
    return if fainted? || @effects[PBEffects::Transform]
    #---------------------------------------------------------------------------
    # Dialga - holding Adamant Crystal
    if isSpecies?(:DIALGA)
      newForm = 0
      newForm = 1 if self.item_id == :ADAMANTCRYSTAL
      pbSimpleFormChange(newForm, _INTL("{1}变成其他样子了！", pbThis))
    end
    #---------------------------------------------------------------------------
    # Palkia - holding Lustrous Globe
    if isSpecies?(:PALKIA)
      newForm = 0
      newForm = 1 if self.item_id == :LUSTROUSGLOBE
      pbSimpleFormChange(newForm, _INTL("{1}变成其他样子了！", pbThis))
    end
    #---------------------------------------------------------------------------
    # Giratina - holding Griseous Orb/Core
    if isSpecies?(:GIRATINA)
      return if $game_map && GameData::MapMetadata.get($game_map.map_id)&.has_flag?("DistortionWorld")
      newForm = 0
      newForm = 1 if Settings::MECHANICS_GENERATION <= 8 && self.item_id == :GRISEOUSORB
      newForm = 1 if Settings::MECHANICS_GENERATION >= 9 && self.item_id == :GRISEOUSCORE
      pbSimpleFormChange(newForm, _INTL("{1}变成其他样子了！", pbThis))
    end
    #---------------------------------------------------------------------------
    # Arceus - holding a Plate with Multi-Type
    if isSpecies?(:ARCEUS) && self.ability == :MULTITYPE
      newForm = 0
      type = GameData::Type.get(:NORMAL)
      if self.item_id
        typeArray = {
          1  => [:FIGHTING, [:FISTPLATE,   :FIGHTINIUMZ]],
          2  => [:FLYING,   [:SKYPLATE,    :FLYINIUMZ]],
          3  => [:POISON,   [:TOXICPLATE,  :POISONIUMZ]],
          4  => [:GROUND,   [:EARTHPLATE,  :GROUNDIUMZ]],
          5  => [:ROCK,     [:STONEPLATE,  :ROCKIUMZ]],
          6  => [:BUG,      [:INSECTPLATE, :BUGINIUMZ]],
          7  => [:GHOST,    [:SPOOKYPLATE, :GHOSTIUMZ]],
          8  => [:STEEL,    [:IRONPLATE,   :STEELIUMZ]],
          10 => [:FIRE,     [:FLAMEPLATE,  :FIRIUMZ]],
          11 => [:WATER,    [:SPLASHPLATE, :WATERIUMZ]],
          12 => [:GRASS,    [:MEADOWPLATE, :GRASSIUMZ]],
          13 => [:ELECTRIC, [:ZAPPLATE,    :ELECTRIUMZ]],
          14 => [:PSYCHIC,  [:MINDPLATE,   :PSYCHIUMZ]],
          15 => [:ICE,      [:ICICLEPLATE, :ICIUMZ]],
          16 => [:DRAGON,   [:DRACOPLATE,  :DRAGONIUMZ]],
          17 => [:DARK,     [:DREADPLATE,  :DARKINIUMZ]],
          18 => [:FAIRY,    [:PIXIEPLATE,  :FAIRIUMZ]]
        }
        typeArray.each do |form, data|
          next if !data.last.include?(self.item_id)
          type = GameData::Type.get(data.first)
          newForm = form
        end
      end
      pbSimpleFormChange(newForm, _INTL("{1}变成了{2}属性！", pbThis, type.name))
    end
    #---------------------------------------------------------------------------
    # Genesect - holding a Drive
    if isSpecies?(:GENESECT)
      newForm = 0
      drives = [:SHOCKDRIVE, :BURNDRIVE, :CHILLDRIVE, :DOUSEDRIVE]
      drives.each_with_index do |drive, i|
        newForm = i + 1 if self.item_id == drive
      end
      pbSimpleFormChange(newForm, nil)
    end
    #---------------------------------------------------------------------------
    # Silvally - holding a Memory with RKS System
    if isSpecies?(:SILVALLY) && self.ability == :RKSSYSTEM
      newForm = 0
      type = GameData::Type.get(:NORMAL)
      if self.item
        typeArray = {
          1  => [:FIGHTING, [:FIGHTINGMEMORY]],
          2  => [:FLYING,   [:FLYINGMEMORY]],
          3  => [:POISON,   [:POISONMEMORY]],
          4  => [:GROUND,   [:GROUNDMEMORY]],
          5  => [:ROCK,     [:ROCKMEMORY]],
          6  => [:BUG,      [:BUGMEMORY]],
          7  => [:GHOST,    [:GHOSTMEMORY]],
          8  => [:STEEL,    [:STEELMEMORY]],
          10 => [:FIRE,     [:FIREMEMORY]],
          11 => [:WATER,    [:WATERMEMORY]],
          12 => [:GRASS,    [:GRASSMEMORY]],
          13 => [:ELECTRIC, [:ELECTRICMEMORY]],
          14 => [:PSYCHIC,  [:PSYCHICMEMORY]],
          15 => [:ICE,      [:ICEMEMORY]],
          16 => [:DRAGON,   [:DRAGONMEMORY]],
          17 => [:DARK,     [:DARKMEMORY]],
          18 => [:FAIRY,    [:FAIRYMEMORY]]
        }
        typeArray.each do |form, data|
          next if !data.last.include?(self.item_id)
          type = GameData::Type.get(data.first)
          newForm = form
        end
      end
      pbSimpleFormChange(newForm, _INTL("{1}变成了{2}属性！", pbThis, type.name))
    end
    #---------------------------------------------------------------------------
    # Zacian - holding Rusted Sword
    if isSpecies?(:ZACIAN)
      newForm = 0
      newForm = 1 if self.item_id == :RUSTEDSWORD
      moves = [:IRONHEAD, :BEHEMOTHBLADE]
      @moves.each_with_index do |m, i|
        next if m.id != moves[self.form]
        move = Pokemon::Move.new(moves.reverse[self.form])
        move.pp = m.pp
        @moves[i] = Battle::Move.from_pokemon_move(@battle, move)
      end
      pbSimpleFormChange(newForm, _INTL("{1} transformed!", pbThis))
    end
    #---------------------------------------------------------------------------
    # Zamazenta - holding Rusted Shield
    if isSpecies?(:ZAMAZENTA)
      newForm = 0
      newForm = 1 if self.item_id == :RUSTEDSHIELD
      moves = [:IRONHEAD, :BEHEMOTHBASH]
      @moves.each_with_index do |m, i|
        next if m.id != moves[self.form]
        move = Pokemon::Move.new(moves.reverse[self.form])
        move.pp = m.pp
        @moves[i] = Battle::Move.from_pokemon_move(@battle, move)
      end
      pbSimpleFormChange(newForm, _INTL("{1}变成其他样子了！", pbThis))
    end
    #---------------------------------------------------------------------------
    # Ogerpon - holding masks
    if isSpecies?(:OGERPON)
      newForm = (self.tera?) ? 8 : 4
      maskName = GameData::Item.get(:TEALMASK).name
      masks = [:TEALMASK, :WELLSPRINGMASK, :HEARTHFLAMEMASK, :CORNERSTONEMASK]
      masks.each_with_index do |mask, i|
        next if self.item_id != mask
        newForm += i
        maskName = GameData::Item.get(mask).name
        break
      end
      pbSimpleFormChange(newForm, _INTL("{1}戴上了{2}！", pbThis, maskName))
    end
  end
end

#===============================================================================
# Battle::AI utilities.
#===============================================================================
class Battle::AI
  def pbAbleToTarget?(user, target, target_data)
    return false if user.index == target.index
    return false if target_data.num_targets == 0
    return false if !@battle.pbMoveCanTarget?(user.index, target.index, target_data)
    if target_data.targets_foe
      return true if user.wild? && !user.opposes?(target) && user.isRivalSpecies?(target)
      return false if !user.opposes?(target)
    end
    return true
  end
  
  def pbShouldInvertScore?(target_data)
    if target_data.targets_foe && !@target.opposes?(@user) && @target.index != @user.index
      return false if @user.battler.wild? && @user.battler.isRivalSpecies?(@target.battler)
      return true
    end
    return false
  end
  
  def pbGetMoveScoreAgainstTarget
    if @trainer.has_skill_flag?("PredictMoveFailure") && pbPredictMoveFailureAgainstTarget
      PBDebug.log("     move will not affect #{@target.name}")
      return -1
    end
    score = MOVE_BASE_SCORE
    if @trainer.has_skill_flag?("ScoreMoves")
      old_score = score
      score = Battle::AI::Handlers.apply_move_effect_against_target_score(@move.function_code,
         MOVE_BASE_SCORE, @move, @user, @target, self, @battle)
      PBDebug.log_score_change(score - old_score, "function code modifier (against target)")
      score = Battle::AI::Handlers.apply_general_move_against_target_score_modifiers(
        score, @move, @user, @target, self, @battle)
    end
    target_data = @move.pbTarget(@user.battler)
    if pbShouldInvertScore?(target_data)
      if score == MOVE_USELESS_SCORE
        PBDebug.log("     move is useless against #{@target.name}")
        return -1
      end
      old_score = score
      score = ((1.85 * MOVE_BASE_SCORE) - score).to_i
      PBDebug.log_score_change(score - old_score, "score inverted (move targets ally but can target foe)")
    end
    return score
  end
end

#===============================================================================
# Battle::AI::Trainer
#===============================================================================
class Battle::AI::AITrainer
  #-----------------------------------------------------------------------------
  # Aliased to give wild Pokemon better AI when a wild battle mode is enabled.
  #-----------------------------------------------------------------------------
  alias dx_set_up_skill set_up_skill
  def set_up_skill
    dx_set_up_skill
    if !@trainer && @skill == 0
      @skill = 32 if !@ai.battle.wildBattleMode.nil?
    end
  end
end

#===============================================================================
# Battle::AI::AIBattler utilities.
#===============================================================================
class Battle::AI::AIBattler
  #-----------------------------------------------------------------------------
  # Utilities for running checks on opposing battlers.
  #-----------------------------------------------------------------------------
  def opponent_side_has_move_flags?(*flags)
    @ai.each_foe_battler(@side) do |b, i|
      flags.each do |flag|
        return true if b.check_for_move { |m| m.flags.include?(flag) }
      end
    end
    return false
  end
  
  def opponent_side_has_function?(*functions)
    @ai.each_foe_battler(@side) do |b, i|
      return true if b.has_move_with_function?(*functions)
    end
    return false
  end
  
  def opponent_side_has_ability?(ability, near = false)
    if ability.is_a?(Array)
      ability.each do |abil|
        bearer = @ai.battle.pbCheckOpposingAbility(abil, @index, near)
        return true if !bearer.nil?
      end
    else
      bearer = @ai.battle.pbCheckOpposingAbility(ability, @index, near)
      return true if !bearer.nil?
    end
    return false
  end
  
  #-----------------------------------------------------------------------------
  # Utility for checking if a battler is at risk of obtaining a status effect.
  #-----------------------------------------------------------------------------
  def risks_getting_status?(status, *functions)
    return false if self.status != :NONE
    types = self.pbTypes(true)
    return false if status == :BURN && types.include?(:FIRE)
    return false if status == :POISON && (types.include?(:POISON) || types.include?(:STEEL))
    return false if status == :PARALYSIS && Settings::MORE_TYPE_EFFECTS && types.include?(:ELECTRIC)
    return false if [:FROZEN, :FROSTBITE].include?(status) && types.include?(:ICE)
    return false if !opponent_side_has_function?(*functions)
    return false if self.effects[PBEffects::Substitute] > 0
    return false if @ai.battle.sides[@side].effects[PBEffects::Safeguard] > 0
    return false if @ai.battle.field.terrain == :Misty && @battler.affectedByTerrain?
    return false if [:FROZEN, :FROSTBITE].include?(status) && 
                    [:Sun, :HarshSun].include?(@battler.effectiveWeather)
    return false if wants_status_problem?(status)
    return false if Battle::AbilityEffects.triggerStatusImmunityNonIgnorable(self.ability_id, @battler, status)
    if ability_active? && !@ai.battle.moldBreaker
      return false if Battle::AbilityEffects.triggerStatusImmunity(self.ability_id, @battler, status)
      @ai.each_ally(@index) do |b, i|
        next if !b.ability_active?
        return false if Battle::AbilityEffects.triggerStatusImmunityFromAlly(b.ability_id, b.battler, status)
      end
    end
    return true
  end
end
