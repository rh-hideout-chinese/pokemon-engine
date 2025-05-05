################################################################################
# 
# New PBEffects.
# 
################################################################################


module PBEffects
  AllySwitch      = 400 # Used to determine if Ally Switch should fail.
  BoosterEnergy   = 401 # Used to flag whether or not ParadoxStat should persist due to Booster Energy.
  Commander       = 402 # Used for storing data related to Commander.
  CudChew         = 403 # Used to count the remaining rounds until Cud Chew triggers.
  DoubleShock     = 404 # Used for removing the user's Electric typing after using Double Shock.
  GlaiveRush      = 405 # Used to count the remaining rounds until vulnerability from Glaive Rush wares off.
  ParadoxStat     = 406 # Used to reference which stat is being boosted by Protosynthesis/Quark Drive.
  OneUseAbility   = 407 # Used to flag a battler's ability to only trigger once per switch-in.
  SaltCure        = 408 # Used to flag a battler as under the effects of Salt Cure.
  SilkTrap        = 409 # Used to flag a battler as under the protection effects of Silk Trap.
  Splinters       = 410 # Used to flag a battler as under the splinters effect.
  SplintersType   = 411 # Used to determine the type effectiveness of splinters damage.
  SuccessiveMove  = 412 # Used to flag a move as unselectable by a battler on consecutive turns.
  SupremeOverlord = 413 # Used to trigger the effects of the Supreme Overlord ability.
  Syrupy          = 414 # Used to track the remaining number of turns until Syrup Bomb's effect wares off.
  SyrupyUser      = 415 # Used to track the Syrup Bomb user so the effect ends if they leave the field.
  BurningBulwark  = 416 # Used for the effect of Burning Bulwark.
end

#-------------------------------------------------------------------------------
# New effects and values to be added to the debug menu.
#-------------------------------------------------------------------------------
module Battle::DebugVariables
  BATTLER_EFFECTS[PBEffects::AllySwitch]      = { name: "本回合已经使出交换场地",                      default: false }
  BATTLER_EFFECTS[PBEffects::CudChew]         = { name: "反刍距离生效的回合数",                            default: 0 }
  BATTLER_EFFECTS[PBEffects::DoubleShock]     = { name: "电光双击使电属性消失",                        default: false }
  BATTLER_EFFECTS[PBEffects::GlaiveRush]      = { name: "巨剑突击脆弱状态剩余回合",                        default: 0 }
  BATTLER_EFFECTS[PBEffects::ParadoxStat]     = { name: "古代活性/夸克充能提升的能力",      default: nil, type: :stat }
  BATTLER_EFFECTS[PBEffects::BoosterEnergy]   = { name: "驱劲能量生效",                               default: false }
  BATTLER_EFFECTS[PBEffects::SaltCure]        = { name: "受到盐腌的影响",                             default: false }
  BATTLER_EFFECTS[PBEffects::SilkTrap]        = { name: "本回合已经使出线阱",                         default: false }
  BATTLER_EFFECTS[PBEffects::Splinters]       = { name: "碎片剩余回合",                                  default: 0 }
  BATTLER_EFFECTS[PBEffects::SplintersType]   = { name: "碎片的属性",                     default: nil, type: :type }
  BATTLER_EFFECTS[PBEffects::SupremeOverlord] = { name: "大将攻击特攻的倍率1 + 0.1*x (0-5)",     default: 0, max: 5  }
  BATTLER_EFFECTS[PBEffects::Syrupy]          = { name: "满身糖剩余回合",                               default: 0  }
  BATTLER_EFFECTS[PBEffects::SyrupyUser]      = { name: "使出糖浆炸弹者",                               default: -1 }
  BATTLER_EFFECTS[PBEffects::BurningBulwark]  = { name: "本回合已经使出火焰守护",                     default: false }
end