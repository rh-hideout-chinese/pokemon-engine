#===============================================================================
# Global midbattle script for species-specific animations.
#===============================================================================
MidbattleHandlers.add(:midbattle_global, :sprite_animations,
  proc { |battle, idxBattler, idxTarget, trigger|
    battler = battle.battlers[idxBattler]
    next if !battler || battler.fainted?
    case trigger
      when "TargetWeakToMove_WATER"
      if battler.isSpecies?(:SUDOWOODO)
        next if battler.effects[PBEffects::Transform] || battler.effects[PBEffects::Illusion]
        next if [:SLEEP, :FROZEN].include?(battler.status)
        sprite, shadow = battle.scene.pbGetBattlerSprites(battler.index)
        if sprite.iconBitmap.speed == 0
          sprite.iconBitmap.speed = 1 
          sprite.update
          shadow.iconBitmap.speed = 1 
          shadow.update
          battle.scene.pbPauseScene
          sprite.iconBitmap.speed = 0
          sprite.iconBitmap.deanimate
          sprite.update
          shadow.iconBitmap.speed = 0
          shadow.iconBitmap.deanimate
          shadow.update
        end
      end
    when "AfterMove_SHIFTGEAR"
      if battler.isSpecies?(:KLINK) || battler.isSpecies?(:KLANG) || battler.isSpecies?(:KLINKLANG)
        next if battler.effects[PBEffects::Transform] || battler.effects[PBEffects::Illusion]
        sprite, shadow = battle.scene.pbGetBattlerSprites(battler.index)
        sprite.reversed = !sprite.reversed
        shadow.reversed = !shadow.reversed
      end
    end
  }
)

#===============================================================================
# Forces a sprite to animate at a desired speed.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteSpeed",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler
    sprite, shadow = battle.scene.pbGetBattlerSprites(idxBattler)
    next if sprite.substitute || battler.vanished
    params = 0 if params < 0
    params = 4 if params > 4
    sprite.speed = params
    sprite.update
    shadow.speed = params
    shadow.update
    PBDebug.log("     'spriteSpeed': setting sprite animation speed for #{battler.name} (#{battler.index})")
  }
)

#===============================================================================
# Forces a sprite to reverse its animation.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteReverse",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler
    sprite, shadow = battle.scene.pbGetBattlerSprites(idxBattler)
    next if sprite.substitute || battler.vanished
    sprite.reversed = params
    sprite.update
    shadow.reversed = params
    shadow.update
    PBDebug.log("     'spriteReverse': reversing sprite animation for #{battler.name} (#{battler.index})")
  }
)

#===============================================================================
# Manually sets a sprite's hue.
#===============================================================================
MidbattleHandlers.add(:midbattle_triggers, "spriteHue",
  proc { |battle, idxBattler, idxTarget, params|
    battler = battle.battlers[idxBattler]
    next if !battler
    sprite, shadow = battle.scene.pbGetBattlerSprites(idxBattler)
    next if sprite.substitute || battler.vanished
    params = 255  if params > 255
    params = -255 if params < -255
    sprite.hue = params
    sprite.iconBitmap.setPokemon(battler, idxBattler.even?, params)
    PBDebug.log("     'spriteHue': setting sprite hue for #{battler.name} (#{battler.index})")
  }
)