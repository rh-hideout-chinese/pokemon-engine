#===============================================================================
# Allows for setting up and editing Dynamax attributes on NPC Pokemon.
#===============================================================================
module TrainerPokemonProperty
  TrainerPokemonProperty.singleton_class.alias_method :dynamax_editor_settings, :editor_settings
  def self.editor_settings(initsetting)
    initsetting = {:species => nil, :level => 10} if !initsetting
    oldsetting, keys = self.dynamax_editor_settings(initsetting)
    [:no_dynamax, :dynamax_lvl, :gmax_factor].each do |sym|
      oldsetting.push(initsetting[sym])
      keys.push(sym)
    end
    return oldsetting, keys
  end
  
  TrainerPokemonProperty.singleton_class.alias_method :dynamax_editor_properties, :editor_properties
  def self.editor_properties(oldsetting)
    properties = self.dynamax_editor_properties(oldsetting)
    properties.concat([
      [_INTL("No Dynamax"), BooleanProperty2,       _INTL("If set to true, the trainer will never Dynamax this Pokémon.")],
      [_INTL("Dynamax Lv"), LimitProperty2.new(10), _INTL("Dynamax level of the Pokémon (0-10).")],
      [_INTL("Gigantamax"), BooleanProperty2,       _INTL("If set to true, the Pokémon will have G-Max Factor.")]
    ])
    return properties
  end
end

module GameData
  class Trainer
    SUB_SCHEMA["NoDynamax"]  = [:no_dynamax,  "b"]
    SUB_SCHEMA["DynamaxLv"]  = [:dynamax_lvl, "u"]
    SUB_SCHEMA["Gigantamax"] = [:gmax_factor, "b"]
	
    alias dynamax_to_trainer to_trainer
    def to_trainer
      trainer = dynamax_to_trainer
      trainer.party.each_with_index do |pkmn, i|
	    if pkmn.shadowPokemon? || @pokemon[i][:no_dynamax]
		  pkmn.dynamax_lvl = 0
		  pkmn.gmax_factor = false
		  pkmn.dynamax_able = false
	    else
		  pkmn.dynamax_lvl = @pokemon[i][:dynamax_lvl]
		  pkmn.gmax_factor = (@pokemon[i][:gmax_factor]) ? true : false
	    end
        pkmn.calc_stats
      end
      return trainer
    end
  end
end


#===============================================================================
# Dynamax sprite positioner.
#===============================================================================
class DynamaxSpritePositioner < SpritePositioner
  def refresh
    if !@species
      @sprites["pokemon_0"].visible = false
      @sprites["pokemon_1"].visible = false
      @sprites["shadow_1"].visible = false
      @sprites["pokemon_0"].clear_dynamax_pattern
      @sprites["pokemon_1"].clear_dynamax_pattern
      return
    end
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    2.times do |i|
      pos = Battle::Scene.pbBattlerPosition(i, 1)
      @sprites["pokemon_#{i}"].x = pos[0]
      @sprites["pokemon_#{i}"].y = pos[1]
      metrics_data.apply_dynamax_metrics_to_sprite(@sprites["pokemon_#{i}"], i)
      @sprites["pokemon_#{i}"].set_dynamax_pattern(metrics_data.id, true)
      @sprites["pokemon_#{i}"].visible = true
      next if i != 1
      @sprites["shadow_1"].x = pos[0]
      @sprites["shadow_1"].y = pos[1]
      if @sprites["shadow_1"].bitmap
        @sprites["shadow_1"].x -= @sprites["shadow_1"].bitmap.width / 2
        @sprites["shadow_1"].y -= @sprites["shadow_1"].bitmap.height / 2
      end
      metrics_data.apply_dynamax_metrics_to_sprite(@sprites["shadow_1"], i, true)
      @sprites["shadow_1"].visible = true
    end
  end
  
  def setSpriteFilter(filter)
    @filter = filter  
  end
  
  def setBackSpriteStyle(style)
    @spriteStyle = style
  end

  def pbAutoPosition
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    old_back_y   = metrics_data.dmax_back_sprite[1]
    old_front_y  = metrics_data.dmax_front_sprite[1]
    bitmap1 = @sprites["pokemon_0"].bitmap
    bitmap2 = @sprites["pokemon_1"].bitmap
    new_back_y = (bitmap1.height - (findBottom(bitmap1) + 1)) / 2
    new_back_y += 54 if @spriteStyle == 1
    new_front_y = (bitmap2.height - (findBottom(bitmap2) + 1)) / 2
    new_front_y += (new_front_y * 1.5) - new_front_y
    new_front_y += 6
    if new_back_y != old_back_y || new_front_y != old_front_y
      metrics_data.dmax_back_sprite[1]  = new_back_y
      metrics_data.dmax_front_sprite[1] = new_front_y
      @metricsChanged = true
      refresh
    end
  end

  def pbChangeSpecies(species, form)
    @species = species
    @form = form
    species_data = GameData::Species.get_species_form(@species, @form)
    return if !species_data
    params = [@species, 0, @form, false, false, true]
    2.times do |i|
      params[5] = false if i == 1
      @sprites["pokemon_#{i}"].clear_dynamax_pattern
      @sprites["pokemon_#{i}"].setSpeciesBitmap(*params)
      @sprites["pokemon_#{i}"].set_dynamax_pattern(species_data.id, true)
    end
    shadowfile = GameData::Species.shadow_filename(@species, @form)
    shadowfile = GameData::Species.convert_shadow_file(shadowfile, @species, @form)
    @sprites["shadow_1"].setBitmap(shadowfile)
  end

  def pbSetParameter(param)
    return if !@species
    if param == 3
      pbAutoPosition
      return false
    end
    metrics_data = GameData::SpeciesMetrics.get_species_form(@species, @form)
    case param
    when 0
      sprite = @sprites["pokemon_0"]
      xpos = metrics_data.dmax_back_sprite[0]
      ypos = metrics_data.dmax_back_sprite[1]
    when 1
      sprite = @sprites["pokemon_1"]
      xpos = metrics_data.dmax_front_sprite[0]
      ypos = metrics_data.dmax_front_sprite[1]
    when 2
      sprite = @sprites["shadow_1"]
      xpos = metrics_data.dmax_shadow_x
      ypos = 0
    end
    oldxpos = xpos
    oldypos = ypos
    @sprites["info"].visible = true
    ret = false
    loop do
      sprite.visible = ((System.uptime * 8).to_i % 4) < 3
      Graphics.update
      Input.update
      self.update
      case param
      when 0 then @sprites["info"].setTextToFit("Ally Position = #{xpos},#{ypos}")
      when 1 then @sprites["info"].setTextToFit("Enemy Position = #{xpos},#{ypos}")
      when 2 then @sprites["info"].setTextToFit("Shadow Position = #{xpos}")
      end
      if (Input.repeat?(Input::UP) || Input.repeat?(Input::DOWN)) && param != 2
        ypos += (Input.repeat?(Input::DOWN)) ? 1 : -1
        case param
        when 0 then metrics_data.dmax_back_sprite[1]  = ypos
        when 1 then metrics_data.dmax_front_sprite[1] = ypos
        end
        refresh
      end
      if Input.repeat?(Input::LEFT) || Input.repeat?(Input::RIGHT)
        xpos += (Input.repeat?(Input::RIGHT)) ? 1 : -1
        case param
        when 0 then metrics_data.dmax_back_sprite[0]  = xpos
        when 1 then metrics_data.dmax_front_sprite[0] = xpos
        when 2 then metrics_data.dmax_shadow_x        = xpos
        end
        refresh
      end
      if Input.repeat?(Input::ACTION) && param != 2
        @metricsChanged = true if xpos != oldxpos || ypos != oldypos
        ret = true
        pbPlayDecisionSE
        break
      elsif Input.repeat?(Input::BACK)
        case param
        when 0
          metrics_data.dmax_back_sprite[0] = oldxpos
          metrics_data.dmax_back_sprite[1] = oldypos
        when 1
          metrics_data.dmax_front_sprite[0] = oldxpos
          metrics_data.dmax_front_sprite[1] = oldypos
        when 2
          metrics_data.dmax_shadow_x = oldxpos
        end
        pbPlayCancelSE
        refresh
        break
      elsif Input.repeat?(Input::USE)
        @metricsChanged = true if xpos != oldxpos || (param != 2 && ypos != oldypos)
        pbPlayDecisionSE
        break
      end
    end
    @sprites["info"].visible = false
    sprite.visible = true
    return ret
  end

  def pbMenu
    refresh
    cw = Window_CommandPokemon.new(
      [_INTL("Set Ally Position"),
       _INTL("Set Enemy Position"),
       _INTL("Set Shadow Position"),
       _INTL("Auto-Position Sprites")]
    )
    cw.x        = Graphics.width - cw.width
    cw.y        = Graphics.height - cw.height
    cw.viewport = @viewport
    ret = -1
    loop do
      Graphics.update
      Input.update
      cw.update
      self.update
      if Input.trigger?(Input::USE)
        pbPlayDecisionSE
        ret = cw.index
        break
      elsif Input.trigger?(Input::BACK)
        pbPlayCancelSE
        break
      end
    end
    cw.dispose
    return ret
  end

  def pbChooseSpecies
    if @starting
      pbFadeInAndShow(@sprites) { update }
      @starting = false
    end
    cw = Window_CommandPokemonEx.newEmpty(0, 0, 260, 176, @viewport)
    cw.rowHeight = 24
    pbSetSmallFont(cw.contents)
    cw.x = Graphics.width - cw.width
    cw.y = Graphics.height - cw.height
    allspecies = []
    GameData::Species.each do |sp|
      next if !sp.dynamax_able?
      next if @filter < 0 && !sp.gmax_move
      next if @filter > 0 && sp.generation != @filter
      name = (sp.form == 0) ? sp.name : _INTL("{1} (form {2})", sp.real_name, sp.form)
      allspecies.push([sp.id, sp.species, sp.form, name]) if name && !name.empty?
    end
    if allspecies.empty?
      pbMessage("No species found.\nClosing editor...")
      pbClose
      return
    end
    allspecies.sort! { |a, b| a[3] <=> b[3] }
    commands = []
    allspecies.each { |sp| commands.push(sp[3]) }
    cw.commands = commands
    cw.index    = @oldSpeciesIndex
    ret = false
    oldindex = -1
    loop do
      Graphics.update
      Input.update
      cw.update
      if cw.index != oldindex
        oldindex = cw.index
        pbChangeSpecies(allspecies[cw.index][1], allspecies[cw.index][2])
        refresh
      end
      self.update
      if Input.trigger?(Input::BACK)
        pbChangeSpecies(nil, nil)
        refresh
        break
      elsif Input.trigger?(Input::USE)
        pbChangeSpecies(allspecies[cw.index][1], allspecies[cw.index][2])
        ret = true
        break
      end
    end
    @oldSpeciesIndex = cw.index
    cw.dispose
    return ret
  end
end

class DynamaxSpritePositionerScreen < SpritePositionerScreen
  def pbStart
    super
  end
end

#-------------------------------------------------------------------------------
# Auto-positions all Dynamax sprites.
#-------------------------------------------------------------------------------
def pbDynamaxAutoPositionAll(spriteStyle = 0)
  t = System.uptime
  GameData::Species.each do |sp|
    if System.uptime - t >= 5
      t += 5
      Graphics.update
    end
    metrics = GameData::SpeciesMetrics.get_species_form(sp.species, sp.form)
    bitmap1 = GameData::Species.sprite_bitmap(sp.species, sp.form, nil, nil, nil, true)
    bitmap2 = GameData::Species.sprite_bitmap(sp.species, sp.form)
    if bitmap1&.bitmap
      metrics.dmax_back_sprite[0] = 0
      metrics.dmax_back_sprite[1] = (bitmap1.height - (findBottom(bitmap1.bitmap) + 1)) / 2
      metrics.dmax_back_sprite[1] += 54 if spriteStyle == 1
    end
    if bitmap2&.bitmap
      metrics.dmax_front_sprite[0] = 0
      metrics.dmax_front_sprite[1] = (bitmap2.height - (findBottom(bitmap2.bitmap) + 1)) / 2
      metrics.dmax_front_sprite[1] += (metrics.dmax_front_sprite[1] * 1.5).round - metrics.dmax_front_sprite[1]
      metrics.dmax_front_sprite[1] += 6
    end
    metrics.dmax_shadow_x = 0
    bitmap1&.dispose
    bitmap2&.dispose
  end
  GameData::SpeciesMetrics.save
  Compiler.write_pokemon_metrics
end