#===============================================================================
# Edits the Trainer Card UI to animate the player's sprite.
#===============================================================================
class PokemonTrainerCard_Scene
  alias animtrainer_pbUpdate pbUpdate
  def pbUpdate
    animtrainer_pbUpdate
    return if !@sprites["trainer"]
    @sprites["trainer"].play
  end
  
  alias animtrainer_pbDrawTrainerCardFront pbDrawTrainerCardFront
  def pbDrawTrainerCardFront
    @sprites["trainer"].ox = 0
    @sprites["trainer"].oy = 0
    animtrainer_pbDrawTrainerCardFront
  end
end

#===============================================================================
# Edits the Hall of Fame UI to animate the player's sprite.
#===============================================================================
class HallOfFame_Scene
  alias animtrainer_pbUpdate pbUpdate
  def pbUpdate
    animtrainer_pbUpdate
    return if !@sprites["trainer"]
    @sprites["trainer"].play
  end
end

#===============================================================================
# Rewrites debug list handlers to animate trainer sprites.
#===============================================================================
def pbListScreen(title, lister)
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  list = pbListWindow([])
  list.viewport = viewport
  list.z        = 2
  title = Window_UnformattedTextPokemon.newWithSize(
    title, Graphics.width / 2, 0, Graphics.width / 2, 64, viewport
  )
  title.z = 2
  lister.setViewport(viewport)
  selectedmap = -1
  commands = lister.commands
  selindex = lister.startIndex
  if commands.length == 0
    value = lister.value(-1)
    lister.dispose
    title.dispose
    list.dispose
    viewport.dispose
    return value
  end
  list.commands = commands
  list.index    = selindex
  loop do
    Graphics.update
    Input.update
    list.update
    lister.update if defined?(lister.update)
    if list.index != selectedmap
      lister.refresh(list.index)
      selectedmap = list.index
    end
    if Input.trigger?(Input::BACK)
      selectedmap = -1
      break
    elsif Input.trigger?(Input::USE)
      break
    end
  end
  value = lister.value(selectedmap)
  lister.dispose
  title.dispose
  list.dispose
  viewport.dispose
  Input.update
  return value
end

def pbListScreenBlock(title, lister)
  viewport = Viewport.new(0, 0, Graphics.width, Graphics.height)
  viewport.z = 99999
  list = pbListWindow([], Graphics.width / 2)
  list.viewport = viewport
  list.z        = 2
  title = Window_UnformattedTextPokemon.newWithSize(
    title, Graphics.width / 2, 0, Graphics.width / 2, 64, viewport
  )
  title.z = 2
  lister.setViewport(viewport)
  selectedmap = -1
  commands = lister.commands
  selindex = lister.startIndex
  if commands.length == 0
    value = lister.value(-1)
    lister.dispose
    title.dispose
    list.dispose
    viewport.dispose
    return value
  end
  list.commands = commands
  list.index = selindex
  loop do
    Graphics.update
    Input.update
    list.update
    lister.update if defined?(lister.update)
    if list.index != selectedmap
      lister.refresh(list.index)
      selectedmap = list.index
    end
    if Input.trigger?(Input::ACTION)
      yield(Input::ACTION, lister.value(selectedmap))
      list.commands = lister.commands
      list.index = list.commands.length if list.index == list.commands.length
      lister.refresh(list.index)
    elsif Input.trigger?(Input::BACK)
      break
    elsif Input.trigger?(Input::USE)
      yield(Input::USE, lister.value(selectedmap))
      list.commands = lister.commands
      list.index = list.commands.length if list.index == list.commands.length
      lister.refresh(list.index)
    end
  end
  lister.dispose
  title.dispose
  list.dispose
  viewport.dispose
  Input.update
end

#===============================================================================
# Edits the Trainer Type and Trainer Battle listers to set animated sprites.
#===============================================================================
class TrainerTypeLister
  def refresh(index)
    @sprite.bitmap&.dispose
    return if index < 0
    begin
      if @ids[index].is_a?(Symbol)
        @sprite.setTrainerBitmap(@ids[index])
      else
        @sprite.setBitmap(nil)
      end
    rescue
      @sprite.setBitmap(nil)
    end
    if @sprite.bitmap
      @sprite.ox = @sprite.bitmap.width / 2
      @sprite.oy = @sprite.bitmap.height / 2
    end
  end
  
  def update; @sprite.play; end
end

class TrainerBattleLister
  def refresh(index)
    @sprite.bitmap&.dispose
    return if index < 0
    begin
      if @ids[index].is_a?(Array)
        @sprite.setTrainerBitmap(@ids[index][0])
      else
        @sprite.setBitmap(nil)
      end
    rescue
      @sprite.setBitmap(nil)
    end
    if @sprite.bitmap
      @sprite.ox = @sprite.bitmap.width / 2
      @sprite.oy = @sprite.bitmap.height
    end
    text = ""
    if !@includeNew || index > 0
      tr_data = GameData::Trainer.get(@ids[index][0], @ids[index][1], @ids[index][2])
      if tr_data
        tr_data.pokemon.each_with_index do |pkmn, i|
          text += "\n" if i > 0
          text += sprintf("%s Lv.%d", GameData::Species.get(pkmn[:species]).real_name, pkmn[:level])
        end
      end
    end
    @pkmnList.text = text
    @pkmnList.resizeHeightToFit(text, Graphics.width / 2)
    @pkmnList.y = Graphics.height - @pkmnList.height
  end
  
  def update; @sprite.play; end
end