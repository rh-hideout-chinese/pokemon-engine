#===============================================================================
# Trainer sprite (used in battle)
#===============================================================================
class Battle::Scene::TrainerSprite < RPG::Sprite
  attr_reader   :name
  attr_reader   :trainer
  attr_reader   :outfit
  attr_accessor :index
  attr_accessor :numTrainers

  def initialize(viewport, numTrainers, index, battleAnimations)
    super(viewport)
    @name             = ""
    @trainer          = nil
    @outfit           = nil
    @hue              = nil
    @numTrainers      = numTrainers
    @index            = index
    @battleAnimations = battleAnimations
    @_iconBitmap      = nil
    self.visible      = false
  end
  
  #-----------------------------------------------------------------------------
  # General utilities.
  #-----------------------------------------------------------------------------
  def dispose
    @_iconBitmap&.dispose
    @_iconBitmap = nil
    self.bitmap = nil if !self.disposed?
    super
  end

  def width;  return (self.bitmap) ? self.bitmap.width : 0;  end
  def height; return (self.bitmap) ? self.bitmap.height : 0; end
  
  def iconBitmap; return @_iconBitmap; end
  
  def animated?
    return !@_iconBitmap.nil? && @_iconBitmap.is_a?(TrainerBitmapWrapper)
  end
  
  def static?
    return true if !animated?
    return @_iconBitmap.length > 1
  end
  
  #-----------------------------------------------------------------------------
  # Related to animations and frames.
  #-----------------------------------------------------------------------------
  def play
    return if !@_iconBitmap
    @_iconBitmap.play
    self.bitmap = @_iconBitmap.bitmap
  end
  
  def to_first_frame
    return if !@_iconBitmap
    @_iconBitmap.deanimate
    self.bitmap = @_iconBitmap.bitmap
  end
  
  def to_last_frame
    return if !@_iconBitmap
    @_iconBitmap.to_frame("last")
    self.bitmap = @_iconBitmap.bitmap
  end
    
  def finished?
    return true if !@_iconBitmap
    return @_iconBitmap.finished?
  end
  
  def reversed=(value)
    return if !@_iconBitmap
	@_iconBitmap.reversed = value
  end
  
  def update; end # Purposefully left empty.
    
  def pbPlayIntroAnimation(pictureEx = nil)
  end
  
  #-----------------------------------------------------------------------------
  # Related to setting coordinates and position.
  #-----------------------------------------------------------------------------
  def pbSetOrigin
    return if !@_iconBitmap
    self.ox = @_iconBitmap.width / 2
    self.oy = @_iconBitmap.height
  end

  def pbSetPosition(shadow = false)
    return if !@_iconBitmap
    pbSetOrigin
    p = Battle::Scene.pbTrainerPosition(1, @index, @numTrainers)
    offset = (shadow) ? GameData::TrainerType.get(@outfit).shadow_xy : [0, 0]
    self.x = p[0] + offset[0]
    self.y = p[1] + offset[1]
    self.z = (shadow) ? 7 - @index : 10 - @index
    if shadow
      self.zoom_x  = 1.1
      self.zoom_y  = 0.25
      self.tone    = Tone.new(-255, -255, -255, 255)
      self.opacity = 75
    end
  end
  
  def shows_shadow?
    return false if !@_iconBitmap
    data = GameData::TrainerType.try_get(@outfit)
    return false if !data
    return data.shows_shadow?
  end
  
  #-----------------------------------------------------------------------------
  # Used to set the sprite or shadow of a particular trainer or trainer type.
  #-----------------------------------------------------------------------------
  def setTrainerBitmap(trainer, trainerType = nil, shadow = false)
    @trainer = trainer
    @outfit = trainerType || @trainer.trainer_type
    @_iconBitmap&.dispose
    @name = GameData::TrainerType.front_sprite_filename(@outfit)
    @_iconBitmap = GameData::TrainerType.sprite_bitmap_from_trainer(@trainer, @outfit)
    @_iconBitmap.setTrainer(trainer, @hue)
    self.bitmap = (@_iconBitmap) ? @_iconBitmap.bitmap : nil
    pbSetPosition(shadow)
  end
  
  def name=(value)
    return if nil_or_empty?(value)
    split_file = value.split(/[\\\/]/)
    trType = split_file.pop.to_sym
    path = split_file.join("/") + "/"
    return if path != "Graphics/Trainers/"
    return if !GameData::TrainerType.exists?(trType)
    setTrainerBitmap(nil, trType)
  end
end

#===============================================================================
# Adds utilities in the IconSprite class for animated trainer sprites.
#===============================================================================
class IconSprite < Sprite
  #-----------------------------------------------------------------------------
  # Aliased to set new trainer bitmap wrapper if the sprite is a trainer.
  #-----------------------------------------------------------------------------
  alias animtrainer_setBitmap setBitmap
  def setBitmap(file, hue = 0)
    if file
      split_file = file.split(/[\\\/]/)
      filename = split_file.pop
      path = split_file.join("/") + "/"
      if path == "Graphics/Trainers/" && GameData::TrainerType.exists?(filename)
        setTrainerBitmap(filename.to_sym)
      else
        animtrainer_setBitmap(file, hue)
      end
    else
      animtrainer_setBitmap(file, hue)
    end
  end  

  #-----------------------------------------------------------------------------
  # Used to set the sprite or shadow of a particular trainer type.
  #-----------------------------------------------------------------------------
  def setTrainerBitmap(trType, shadow = false)
    oldrc = self.src_rect
    clearBitmaps
    @name = GameData::TrainerType.front_sprite_filename(trType) || "Graphics/Trainers/000"
    if GameData::TrainerType.exists?(trType)
      trData = GameData::TrainerType.get(trType)
      @_iconbitmap = TrainerBitmapWrapper.new(@name, trData.trainer_sprite_scale)
      @_iconbitmap.compile_strip
      @_iconbitmap.hue_change(trData.trainer_sprite_hue) if trData.sprite_hue
      self.bitmap = @_iconbitmap ? @_iconbitmap.bitmap : nil
      self.src_rect = oldrc
      self.ox = @_iconbitmap.width / 2
      self.oy = @_iconbitmap.height
      if shadow
        self.zoom_x  = 1.1
        self.zoom_y  = 0.25
        self.tone    = Tone.new(-255, -255, -255, 255)
        self.opacity = 75
      end
    else
      @_iconbitmap = nil
    end
  end
  
  def iconBitmap; return @_iconbitmap; end
  
  #-----------------------------------------------------------------------------
  # Related to animations and frames.
  #-----------------------------------------------------------------------------
  def play
    return if !@_iconbitmap.is_a?(TrainerBitmapWrapper)
    @_iconbitmap.play
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def to_first_frame
    return if !@_iconbitmap.is_a?(TrainerBitmapWrapper)
    @_iconbitmap.deanimate
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def to_last_frame
    return if !@_iconbitmap.is_a?(TrainerBitmapWrapper)
    @_iconbitmap.to_frame("last")
    self.bitmap = @_iconbitmap.bitmap
  end
  
  def finished?
    return true if !@_iconbitmap.is_a?(TrainerBitmapWrapper)
	return @_iconbitmap.finished?
  end
  
  def reversed=(value)
    return if !@_iconbitmap.is_a?(TrainerBitmapWrapper)
	@_iconbitmap.reversed = value
  end
  
  def update
    return if @_iconbitmap.is_a?(TrainerBitmapWrapper)
    super
  end
end