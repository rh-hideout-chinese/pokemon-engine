#===============================================================================
# Midbattle Scripts
#===============================================================================
# This module stores all custom battle scripts that can be called upon with the
# battle rule "midbattleScript" if you don't want to input the entire script in
# the event script itself, due to it being too long or if you just find it neater
# this way.
#
# Note that when calling one of the scripts here, you do so in the event by
# setting the constant you defined here as a battle rule.
#
# 	For example:  
#   setBattleRule("midbattleScript", :DEMO_SPEECH)
#
#   *Note that a semi-colon is required in front of the constant when called, 
#    but not when defined below.
#-------------------------------------------------------------------------------
module MidbattleScripts
  #-----------------------------------------------------------------------------
  # Demo for displaying each of the main triggers and when they activate.
  #-----------------------------------------------------------------------------
  DEMO_SPEECH = {
    #---------------------------------------------------------------------------
    # Round phases
    "RoundStartCommand_foe" => "Trigger: 'RoundStartCommand'\n({2}, {1})",
    "RoundStartAttack_foe"  => "Trigger: 'RoundStartAttack'\n({2}, {1})",
    "RoundEnd_foe"          => "Trigger: 'RoundEnd'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Battler turns
    "TurnStart_foe"         => "Trigger: 'TurnStart'\n({2}, {1})",
    "TurnEnd_foe"           => "Trigger: 'TurnEnd'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Item usage
    "BeforeItemUse"         => "Trigger: 'BeforeItemUse'\n({2}, {1})",
    "AfterItemUse"          => "Trigger: 'AfterItemUse'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Wild capture
    "BeforeCapture"         => "Trigger: 'BeforeCapture'\n({2}, {1})",
    "AfterCapture"          => "Trigger: 'AfterCapture'\n({2}, {1})",
    "FailedCapture"         => "Trigger: 'FailedCapture'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Switching
    "BeforeSwitchOut"       => "Trigger: 'BeforeSwitchOut'\n({2}, {1})",
    "BeforeSwitchIn"        => "Trigger: 'BeforeSwitchIn'\n({2}, {1})",
    "BeforeLastSwitchIn"    => "Trigger: 'BeforeLastSwitchIn'\n({2}, {1})",
    "AfterSwitchIn"         => "Trigger: 'AfterSwitchIn'\n({2}, {1})",
    "AfterLastSwitchIn"     => "Trigger: 'AfterLastSwitchIn'\n({2}, {1})",
    "AfterSendOut"          => "Trigger: 'AfterSendOut'\n({2}, {1})",
    "AfterLastSendOut"      => "Trigger: 'AfterLastSendOut'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Megas & Primals
    "BeforeMegaEvolution"   => "Trigger: 'BeforeMegaEvolution'\n({2}, {1})",
    "AfterMegaEvolution"    => "Trigger: 'AfterMegaEvolution'\n({2}, {1})",
    "BeforePrimalReversion" => "Trigger: 'BeforePrimalReversion'\n({2}, {1})",
    "AfterPrimalReversion"  => "Trigger: 'AfterPrimalReversion'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Move usage
    "BeforeMove"            => "Trigger: 'BeforeMove'\n({2}, {1})",
    "BeforeDamagingMove"    => "Trigger: 'BeforeDamagingMove'\n({2}, {1})",
    "BeforePhysicalMove"    => "Trigger: 'BeforePhysicalMove'\n({2}, {1})",
    "BeforeSpecialMove"     => "Trigger: 'BeforeSpecialMove'\n({2}, {1})",
    "BeforeStatusMove"      => "Trigger: 'BeforeStatusMove'\n({2}, {1})",
    "AfterMove"             => "Trigger: 'AfterMove'\n({2}, {1})",
    "AfterDamagingMove"     => "Trigger: 'AfterDamagingMove'\n({2}, {1})",
    "AfterPhysicalMove"     => "Trigger: 'AfterPhysicalMove'\n({2}, {1})",
    "AfterSpecialMove"      => "Trigger: 'AfterSpecialMove'\n({2}, {1})",
    "AfterStatusMove"       => "Trigger: 'AfterStatusMove'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Damage results
    "UserDealtDamage"       => "Trigger: 'UserDealtDamage'\n({2}, {1})",
    "UserDamagedSub"        => "Trigger: 'UserDamagedSub'\n({2}, {1})",
    "UserBrokeSub"          => "Trigger: 'UserBrokeSub'\n({2}, {1})",
    "UserDealtCriticalHit"  => "Trigger: 'UserDealtCriticalHit'\n({2}, {1})",
    "UserMoveEffective"     => "Trigger: 'UserMoveEffective'\n({2}, {1})",
    "UserMoveResisted"      => "Trigger: 'UserMoveResisted'\n({2}, {1})",
    "UserMoveNegated"       => "Trigger: 'UserMoveNegated'\n({2}, {1})",
    "UserMoveDodged"        => "Trigger: 'UserMoveDodged'\n({2}, {1})",
    "UserHPHalf"            => "Trigger: 'UserHPHalf'\n({2}, {1})",
    "UserHPLow"             => "Trigger: 'UserHPLow'\n({2}, {1})",
    "LastUserHPHalf"        => "Trigger: 'LastUserHPHalf'\n({2}, {1})",
    "LastUserHPLow"         => "Trigger: 'LastUserHPLow'\n({2}, {1})",
    "TargetTookDamage"      => "Trigger: 'TargetTookDamage'\n({2}, {1})",
    "TargetSubDamaged"      => "Trigger: 'TargetSubDamaged'\n({2}, {1})",
    "TargetSubBroken"       => "Trigger: 'TargetSubBroken'\n({2}, {1})",
    "TargetTookCriticalHit" => "Trigger: 'TargetTookCriticalHit'\n({2}, {1})",
    "TargetWeakToMove"      => "Trigger: 'TargetWeakToMove'\n({2}, {1})",
    "TargetResistedMove"    => "Trigger: 'TargetResistedMove'\n({2}, {1})",
    "TargetNegatedMove"     => "Trigger: 'TargetNegatedMove'\n({2}, {1})",
    "TargetDodgedMove"      => "Trigger: 'TargetDodgedMove'\n({2}, {1})",
    "TargetHPHalf"          => "Trigger: 'TargetHPHalf'\n({2}, {1})",
    "TargetHPLow"           => "Trigger: 'TargetHPLow'\n({2}, {1})",
    "LastTargetHPHalf"      => "Trigger: 'LastTargetHPHalf'\n({2}, {1})",
    "LastTargetHPLow"       => "Trigger: 'LastTargetHPLow'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # Battler condition
    "BattlerHPRecovered"    => "Trigger: 'BattlerHPRecovered'\n({2}, {1})",
    "BattlerHPFull"         => "Trigger: 'BattlerHPFull'\n({2}, {1})",
    "BattlerHPReduced"      => "Trigger: 'BattlerHPReduced'\n({2}, {1})",
    "BattlerHPCritical"     => "Trigger: 'BattlerHPCritical'\n({2}, {1})",
    "BattlerFainted"        => "Trigger: 'BattlerFainted'\n({2}, {1})",
    "LastBattlerFainted"    => "Trigger: 'LastBattlerFainted'\n({2}, {1})",
    "BattlerReachedHPCap"   => "Trigger: 'BattlerReachedHPCap'\n({2}, {1})",
    "BattlerStatusChange"   => "Trigger: 'BattlerStatusChange'\n({2}, {1})",
    "BattlerStatusCured"    => "Trigger: 'BattlerStatusCured'\n({2}, {1})",
    "BattlerConfusionStart" => "Trigger: 'BattlerConfusionStart'\n({2}, {1})",
    "BattlerConfusionEnd"   => "Trigger: 'BattlerConfusionEnd'\n({2}, {1})",
    "BattlerAttractStart"   => "Trigger: 'BattlerAttractStart'\n({2}, {1})",
    "BattlerAttractEnd"     => "Trigger: 'BattlerAttractEnd'\n({2}, {1})",
    "BattlerStatRaised"     => "Trigger: 'BattlerStatRaised'\n({2}, {1})",
    "BattlerStatLowered"    => "Trigger: 'BattlerStatLowered'\n({2}, {1})",
    "BattlerMoveZeroPP"     => "Trigger: 'BattlerMoveZeroPP'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # End of effects
    "WeatherEnded"          => "Trigger: 'WeatherEnded'\n({2}, {1})",
    "TerrainEnded"          => "Trigger: 'TerrainEnded'\n({2}, {1})",
    "FieldEffectEnded"      => "Trigger: 'FieldEffectEnded'\n({2}, {1})",
    "TeamEffectEnded"       => "Trigger: 'TeamEffectEnded'\n({2}, {1})",
    "BattlerEffectEnded"    => "Trigger: 'BattlerEffectEnded'\n({2}, {1})",
    #---------------------------------------------------------------------------
    # End of battle
    "BattleEnd"             => "Trigger: 'BattleEnd'\n({2}, {1})",
    "BattleEndWin"          => "Trigger: 'BattleEndWin'\n({2}, {1})",
    "BattleEndLoss"         => "Trigger: 'BattleEndLoss'\n({2}, {1})",
    "BattleEndDraw"         => "Trigger: 'BattleEndDraw'\n({2}, {1})",
    "BattleEndForfeit"      => "Trigger: 'BattleEndForfeit'\n({2}, {1})",
    "BattleEndRun"          => "Trigger: 'BattleEndRun'\n({2}, {1})",
    "BattleEndFled"         => "Trigger: 'BattleEndFled'\n({2}, {1})",
    "BattleEndCapture"      => "Trigger: 'BattleEndCapture'\n({2}, {1})"
  } 
  
  #-----------------------------------------------------------------------------
  # Demo trainer speech when triggering Mega Evolution.
  #-----------------------------------------------------------------------------
  DEMO_MEGA_EVOLUTION = {
    "BeforeMegaEvolution_foe"           => "C'mon, {1}!\nLet's blow them away with Mega Evolution!",
    "AfterMegaEvolution_GYARADOS_foe"   => "Behold the serpent of the darkest depths!",
    "AfterMegaEvolution_GENGAR_foe"     => "Good luck escaping THIS nightmare!",
    "AfterMegaEvolution_KANGASKHAN_foe" => "Parent and child fight as one!",
    "AfterMegaEvolution_AERODACTYL_foe" => "Prepare yourself for my prehistoric beast!",
    "AfterMegaEvolution_FIRE_foe"       => "Maximum firepower!",
    "AfterMegaEvolution_ELECTRIC_foe"   => "Prepare yourself for a mighty force of nature!",
    "AfterMegaEvolution_BUG_foe"        => "My mighty insect has emerged from its cacoon!"
  }
  
  #-----------------------------------------------------------------------------
  # Demo trainer speech when triggering Primal Reversion.
  #-----------------------------------------------------------------------------
  DEMO_PRIMAL_REVERSION = {
    "BeforePrimalReversion_foe"        => "Prepare yourself for an ancient force beyond imagination!",
    "AfterPrimalReversion_KYOGRE_foe"  => "{1}!\nLet the seas burst forth from your mighty presence!",
    "AfterPrimalReversion_GROUDON_foe" => "{1}!\nLet the ground crack beneath your mighty presence!",
    "AfterPrimalReversion_WATER_foe"   => "Flood the world with your majesty!",
    "AfterPrimalReversion_GROUND_foe"  => "Shatter the world with your majesty!"
  }
  
  
################################################################################
# Example demo of a generic capture tutorial battle.
################################################################################

  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "autoBattle"
  #   "alwaysCapture"
  #   "tutorialCapture"
  #   "tempPlayer"
  #   "tempParty"
  #   "noExp"
  #-----------------------------------------------------------------------------
  
  DEMO_CAPTURE_TUTORIAL = {
    #---------------------------------------------------------------------------
    # General speech events.
    #---------------------------------------------------------------------------
    "RoundStartCommand_player"  => "Hey! A wild Pokémon!\nPay attention, now. I'll show you how to capture one of your own!",
    "BeforeDamagingMove_player" => ["Weakening a Pokémon through battle makes them much easier to catch!",
                                    "Be careful though - you don't want to knock them out completely!\nYou'll lose your chance if you do!",
                                    "Let's try dealing some damage.\nGet 'em, {1}!"],
    "BattlerStatusChange_foe"   => [:Opposing, "It's always a good idea to inflict status conditions like Sleep or Paralysis!",
                                    "This will really help improve your odds at capturing the Pokémon!"],
    #---------------------------------------------------------------------------
    # Turn 1 - Uses a status move on the opponent, if possible.
    #---------------------------------------------------------------------------
    "TurnStart_player" => {
      "useMove"      => "Status_foe",
      "setBattler"   => :Opposing,
      "battlerHPCap" => -1
    },
    #---------------------------------------------------------------------------
    # Continuous - Checks if the wild Pokemon's HP is low. If so, initiates the
    #              capture sequence.
    #---------------------------------------------------------------------------
    "RoundEnd_player_repeat" => {
      "ignoreUntil" => ["TargetTookDamage_foe", "RoundEnd_player_2"],
      "speech_A"    => "The Pokémon is weak!\nNow's the time to throw a Poké Ball!",
      "useItem"     => :POKEBALL,
      "speech_B"    => "Alright, that's how it's done!"
    }
  }
  
  
################################################################################
# Demo scenario vs. wild Rotom that shifts forms.
################################################################################
  
  DEMO_WILD_ROTOM = {
    #---------------------------------------------------------------------------
    # Turn 1 - Disables Poke Balls from being used.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "text_A"       => "{1} emited a powerful magnetic pulse!",
      "playAnim"     => [:CHARGE, :Self, :Self],
      "playSE"       => "Anim/Paralyze3",
      "text_B"       => "Your Poké Balls short-circuited!\nThey cannot be used this battle!",
      "disableBalls" => true
    },
    #---------------------------------------------------------------------------
    # Continuous - Shifts into random form, heals HP/status, and gains new item/ability.
    #---------------------------------------------------------------------------
    "RoundEnd_foe_repeat" => {
      "ignoreUntil"    => "TargetWeakToMove_foe",
      "playAnim"       => [:NIGHTMARE, :Opposing, :Self],
      "battlerForm"    => [:Random, "{1} possessed a new appliance!"],
      "battlerHP"      => 4,
      "battlerStatus"  => :NONE,
      "battlerAbility" => [:MOTORDRIVE, true],
      "battlerItem"    => [:CELLBATTERY, "{1} equipped a Cell Battery it found in the appliance!"]
    },
    #---------------------------------------------------------------------------
    # When Rotom's HP drops to 50% or lower, applies Charge, Magnet Rise, and Electric Terrain.
    #---------------------------------------------------------------------------
    "TargetHPHalf_foe" => {
	  "playAnim"       => [:CHARGE, :Self, :Self],
      "battlerEffects" => [
        [:Charge,     5, "{1} began charging power!"],
        [:MagnetRise, 5, "{1} levitated with electromagnetism!"],
      ],
      "changeTerrain"  => :Electric
    },
    #---------------------------------------------------------------------------
    # Player's Pokemon becomes paralyzed after dealing supereffective damage. 
    #---------------------------------------------------------------------------
    "UserMoveEffective_player_repeat" => {
      "text"          => [:Opposing, "{1} emited an electrical pulse out of desperation!"],
      "battlerStatus" => [:PARALYSIS, true]
    }
  }

################################################################################
# Demo scenario vs. Rocket Grunt in a collapsing cave.
################################################################################  
  
  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "noMoney"
  #   "canLose"
  #-----------------------------------------------------------------------------
  
  DEMO_COLLAPSING_CAVE = {
    #---------------------------------------------------------------------------
    # Turn 1 - Battle intro.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "playSE"  => "Mining collapse",
      "text_A"  => "The cave ceiling begins to crumble down all around you!",
      "speech"  => ["I am not letting you escape!", "I don't care if this whole cave collapses down on the both of us...haha!"],
      "text_B"  => "Defeat your opponent before time runs out!"
    },
    #---------------------------------------------------------------------------
    # Continuous - Text event at the end of each turn.
    #---------------------------------------------------------------------------
    "RoundEnd_player_repeat" => {
      "playSE" => "Mining collapse",
      "text"   => "The cave continues to collapse all around you!"
    },
    #---------------------------------------------------------------------------
    # Turn 2 - Player's Pokemon takes damage and becomes confused.
    #---------------------------------------------------------------------------
    "RoundEnd_2_player" => {
      "text"          => "{1} was struck on the head by a falling rock!",
      "playAnim"      => [:ROCKSMASH, :Opposing, :Self],
      "battlerHP"     => -4,
      "battlerStatus" => :CONFUSED
    },
    #---------------------------------------------------------------------------
    # Turn 3 - Text event.
    #---------------------------------------------------------------------------
    "RoundEnd_3_player" => {
      "text" => ["You're running out of time!", "You need to escape immediately!"]
    },
    #---------------------------------------------------------------------------
    # Turn 4 - Battle prematurely ends in a loss.
    #---------------------------------------------------------------------------
    "RoundEnd_4_player" => {
      "text_A"    => "You failed to defeat your opponent in time!",
      "playAnim"  => ["Recall", :Self],
      "text_B"    => "You were forced to flee the battle!",
      "playSE"    => "Battle flee",
      "endBattle" => 3
    },
    #---------------------------------------------------------------------------
    # Opponent's final Pokemon is healed and increases its defenses when HP is low.
    #---------------------------------------------------------------------------
    "LastTargetHPLow_foe" => {
      "speech"       => "My {1} will never give up!",
      "endSpeech"    => true,
      "playAnim"     => [:BULKUP, :Self],
      "playCry"      => :Self,
      "battlerHP"    => [2, "{1} is standing its ground!"],
      "battlerStats" => [:DEFENSE, 2, :SPECIAL_DEFENSE, 2]
    },
    #---------------------------------------------------------------------------
    # Speech event upon losing the battle.
    #---------------------------------------------------------------------------
    "BattleEndForfeit" => "Haha...you'll never make it out alive!"
  }
  
  
################################################################################
# Demo scenario vs. Battle Quizmaster.
################################################################################ 
  
  #-----------------------------------------------------------------------------
  # Suggested Battle Rules:
  #-----------------------------------------------------------------------------
  #   "canLose"
  #   "noExp"
  #   "noMoney"
  #-----------------------------------------------------------------------------
  
  DEMO_BATTLE_QUIZMASTER = {
    #---------------------------------------------------------------------------
    # Intro speech event.
    #---------------------------------------------------------------------------
    "RoundStartCommand_1_foe" => {
      "speech_A" => ["Welcome to another episode of Pokémon Battle Quiz!", 
                     "The show where trainers must battle with both Pokémon and trivia at the same time!",
                     "You gain one point each time you answer a question correctly, and a bonus point if you knock out a Pokémon!",
                     "If you can reach six points within six turns, you win a prize!",
                     "Is our new challenger up to the task? Let's hear some noise for \\PN!"],
      "playSE"   => "Anim/Applause", 
      "speech_B" => "Now, \\PN!\nLet us begin!"
    },
    #---------------------------------------------------------------------------
    # Speech events.
    #---------------------------------------------------------------------------
    "Variable_1" => {
      "playSE" => "Pkmn move learnt", 
      "speech" => "You've earned yourself your first point!\nKeep your eye on the prize!",
    },
    "Variable_2" => {
      "playSE" => "Pkmn move learnt", 
      "speech" => "Two points - hey, not bad!\nCan our new challenger keep it going?",
    },
    "Variable_3" => {
      "playSE" => "Pkmn move learnt", 
      "speech" => "You've claimed your third point!\nYou're on fire! Keep it up, kid!",
    },
    "Variable_4" => {
      "playSE" => "Pkmn move learnt", 
      "speech" => "Four points on the board!\nDo you think you got what it takes to win?",
    },
    "Variable_5" => {
      "playSE" => "Pkmn move learnt", 
      "speech" => "Just one more point to go!\nCan our up-and-coming star clear a perfect game?",
    },
    "BattleEndLoss" => "Nice try, kid. On to the next challenger!",
    #---------------------------------------------------------------------------
    # Automatically ends the battle as a win if enough points have been earned.
    #---------------------------------------------------------------------------
    "VariableOver_5" => {
      "playSE_A"  => "Pkmn move learnt",
      "speech"    => ["Aaaand there we have it, folks! Point number six!",
                      "Do you know what that means? It looks like we've got a winner!",	  
                      "Let's hear it for our brand new Battle Quiz-wiz - \\PN!"],
      "playSE_B"  => "Anim/Applause", 
      "text"      => "You gracefully bow at the audience to a burst of applause!",
      "endBattle" => 1
    },
    #---------------------------------------------------------------------------
    # Continuous - Adds a bonus point whenever the opponent's Pokemon is KO'd.
    #---------------------------------------------------------------------------
    "BattlerFainted_foe_repeat" => {
      "addVariable" => 1
    },
    #---------------------------------------------------------------------------
    # Continuous - Opponent's final Pokemon always Endures damaging moves.
    #---------------------------------------------------------------------------
    "BeforeDamagingMove_player_repeat" => {
      "ignoreUntil"    => "AfterLastSwitchIn_foe",
      "setBattler"     => :Opposing,
      "battlerEffects" => [:Endure, true]
    },
    #---------------------------------------------------------------------------
    # Turn 1 - Multiple choice question (Region).
    #---------------------------------------------------------------------------
    "RoundEnd_1_foe" => {
      "playSE"     => "Voltorb Flip gain coins", 
      "setChoices" => [:region, 3, {
                        "Kalos" => "Ouch, that's a miss, my friend!",
                        "Johto" => "Close! Well, at least geographically speaking...",
                        "Kanto" => "Ah, good ol' Kanto!\nWhat a classic! Correct!",
                        "Galar" => "Unless you're Champion Leon, that's incorrect!\nI'm afraid you're NOT having a champion time!"
                      }],
      "speech"     => ["Time for our first question!",
                       "In which region do new trainers typically have the option to select Charmander as thier first Pokémon?", :Choices]
    },
    "ChoiceRight_region" => {
      "addVariable"  => 1,
      "playSE"       => "Anim/Applause",
      "text"         => "The crowd politely applauded for you!",
      "setBattler"   => :Opposing,
      "battlerStats" => [:ACCURACY, 1]
    },
    "ChoiceWrong_region" => {
      "setBattler"     => :Opposing,
      "battlerStats"   => [:ACCURACY, -2],
      "battlerEffects" => [:NoRetreat, true, "{1} became nervous!\nIt may no longer escape!"]
    },
    #---------------------------------------------------------------------------
    # Turn 2 - Multiple choice question (Poke Ball).
    #---------------------------------------------------------------------------
    "RoundEnd_2_foe" => {
      "playSE"     => "Voltorb Flip gain coins", 
      "setChoices" => [:pokeball, 4, {
                        "Fast Ball"  => "Perhaps you were a little too fast to answer, because I'm afraid that's incorrect!",
                        "Love Ball"  => "I'm sorry to break your heart, but that's incorrect!", 
                        "Quick Ball" => "Ah, you're a quick-witted one...\nBut unfortunately, not quite quick enough! You're incorrect!",
                        "Heavy Ball" => "Not even a Heavy Ball could contain that huge brain of yours! You're correct!"
                      }],
      "speech"     => ["It's time for our second question!",
                       "Which type of Poké Ball would be most effective if thrown on the first turn at a wild Metagross?", :Choices]
    },
    "ChoiceRight_pokeball" => {
      "addVariable" => 1,
      "playSE"      => "Anim/Applause",
      "text"        => "The crowd began to root for you to win!",
      "setBattler"  => :Opposing,
      "teamEffects" => [:LuckyChant, 5, "The Lucky Chant shields {1} from critical hits!"]
    },
    "ChoiceWrong_pokeball" => {
      "setBattler"   => :Opposing,
      "battlerMoves" => [:SPLASH, :METRONOME, nil, nil],
      "text"         => "{1} became embarassed and forgot its moves!"
    },
    #---------------------------------------------------------------------------
    # Turn 3 - Branching path question.
    #---------------------------------------------------------------------------
    "RoundEnd_3_foe" => {
      "setChoices" => [:topic, nil, "Battling", "Evolution", "Breeding"],
      "speech"     => ["Ah, we've made it to our wild card round!",
                       "This turn, you may choose one of three topics related to Pokémon.",
                       "Our Quiz-A-Tron 3000 will then generate a stumper of a question related to your chosen topic.",
                       "This will be a simple yes or no question, but it will be worth two points, so choose wisely!",
                       "So then, which topic will it be?", :Choices, 
                       "Interesting choice!", 
                       "Let's see what our Quiz-A-Tron comes up with!"],
      "endSpeech"  => true,
      "playSE"     => "PC Access", 
      "text"       => "The Quiz-A-Tron 3000 beeps and whirrs as it prints out a question."
    },
    #---------------------------------------------------------------------------
    # Branch 1 - Multiple choice question (Battle).
    #---------------------------------------------------------------------------
    "Choice_topic_1" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:battling, 2, {
                        "Yes" => "I'm sorry. I guess not everyone can have a Natural Gift for quizzes...",
                        "No"  => "Hey, looks like you've got a Natural Gift for this!"
                      }],
      "speech"     => ["Question time!",
                       "Would the move Nature Power become an Ice-type move if the user is holding a Yache Berry?", :Choices]
    },
    "ChoiceRight_battling" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "The crowd roared with excitement!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "{1} was energized from the crowd's cheering!"],
      "battlerStats" => [:ATTACK, 1, :SPECIAL_ATTACK, 1]
    },
    "ChoiceWrong_battling" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} became discouraged by the silence of the crowd...",
      "battlerStats" => [:ATTACK, -2, :SPECIAL_ATTACK, -2]
    },
    #---------------------------------------------------------------------------
    # Branch 2 - Multiple choice question (Evolution).
    #---------------------------------------------------------------------------
    "Choice_topic_2" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:evolution, 1, {
                        "Yes" => "It was critical that you got that question right! Good job!",
                        "No"  => "Oh no! You should have thought about that one more critically..."
                      }],
      "speech"     => ["Question time!",
                       "Would holding a Leek item be directly useful in some way with helping a Galarian Farfetch'd evolve?", :Choices]
    },
    "ChoiceRight_evolution" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "The crowd roared with excitement!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "{1} was energized from the crowd's cheering!"],
      "battlerStats" => [:SPEED, 1, :EVASION, 1]
    },
    "ChoiceWrong_evolution" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} became discouraged by the silence of the crowd...",
      "battlerStats" => [:SPEED, -2, :EVASION, -2]
    },
    #---------------------------------------------------------------------------
    # Branch 3 - Multiple choice question (Breeding).
    #---------------------------------------------------------------------------
    "Choice_topic_3" => {
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:breeding, 1, {
                        "Yes" => "Whoa! You Volbeat that question without breaking a sweat!",
                        "No"  => "Ouch! Looks you got Volbeat by that question..."
	                    }],
      "speech"     => ["Question time!",
                       "Is Illumise able to produce eggs of a different species from itself?", :Choices]
    },
    "ChoiceRight_breeding" => {
      "addVariable"  => 2,
      "playSE"       => "Anim/Applause",
      "text"         => "The crowd roared with excitement!",
      "setBattler"   => :Opposing,
      "battlerHP"    => [1, "{1} was energized from the crowd's cheering!"],
      "battlerStats" => [:DEFENSE, 1, :SPECIAL_DEFENSE, 1]
    },
    "ChoiceWrong_breeding" => {
      "setBattler"   => :Opposing,
      "text"         => "{1} became discouraged by the silence of the crowd...",
      "battlerStats" => [:DEFENSE, -2, :SPECIAL_DEFENSE, -2]
    },
    #---------------------------------------------------------------------------
    # Turn 4 - Final question. 
    #---------------------------------------------------------------------------
    "RoundEnd_4_foe" => {
      "speech_A"   => ["I'm afraid we've reached our final round of questions!",
                       "Can our challenger pull out a win here?\nLet's find out!"],
      "playSE"     => "Voltorb Flip gain coins",
      "setChoices" => [:final, 1, {
                        "Hold the Ctrl key"      => "Yes, it's Ctrl! You got it!\nHey, you must be a pro at this!",
                        "Hold the Shift key"     => "Close! Holding Shift will only recompile plugins!\nThe correct key is Ctrl!",
                        "Hold your face and cry" => "Huh? C'mon now, it's not that hard... Just hold the Ctrl key.",
                        "Ask someone else how"   => "Well now you won't have to, because the answer is 'Hold the Ctrl key'."
                      }],
      "speech_B"   => ["Here it is, the final question:",
                       "When loading Pokémon Essentials in Debug mode and the game window is in focus, how do you manually trigger the game to recompile?", :Choices]
    },
    "ChoiceRight_final" => {
      "addVariable" => 1,
      "playSE"      => "Anim/Applause",
      "text"        => "The crowd gave you a standing ovation!"
    },
    "ChoiceWrong_final" => {
      "text"       => "You can hear disappointed murmurings from the crowd...",
      "setBattler" => :Opposing,
      "battlerHP"  => [0, "{1} fainted from embarassment..."]
    },
    #---------------------------------------------------------------------------
    # Turn 6 - Ends the battle as a loss if not enough points have been earned.
    #---------------------------------------------------------------------------
    "RoundEnd_6_foe" => {
      "playSE_A"   => "Slots stop",
      "speech_A"   => ["Oh no! That sound means we've reached the end of our game...",
                       "Our challenger \\PN showed much promise, but came up a tad short in the end.",
                       "But we still had fun, didn't we, folks?"], 
      "playSE_B"   => "Anim/Applause",
      "speech_B"   => "That's right! Well, that's all for today!\nTake a bow, \\PN! You and your Pokémon fought hard!",
      "text"       => "You awkwardly bow at the audience as staff begin to direct you off stage...",
      "endBattle"  => 2
    }
  }
end