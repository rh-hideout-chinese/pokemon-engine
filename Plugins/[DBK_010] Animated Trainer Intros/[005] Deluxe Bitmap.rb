#===============================================================================
# Animated bitmap wrapper for trainer sprites.
#===============================================================================
class TrainerBitmapWrapper
  attr_reader :width, :height, :total_frames, :frame_idx
  attr_accessor :trainer, :scale, :reversed
  
  def initialize(file, scale = 1)
    raise "TrainerBitmapWrapper filename is nil." if file.nil?
    @bitmaps      = []
    @bmp_file     = file
    @scale        = scale
    @trainer      = nil
    @changed_hue  = false
    @reversed     = false
    @width        = 0
    @height       = 0
    @total_frames = 0
    @frame_idx    = 0
    @last_uptime  = 0
    self.refresh
  end
  
  def name
    return nil if !@bmp_file.is_a?(String)
    return nil if nil_or_empty?(@bmp_file)
    return @bmp_file
  end
  
  def length; return @total_frames; end
  def copy;   return @bitmaps[@frame_idx].clone; end
  def each;   end
  
  #-----------------------------------------------------------------------------
  # Assigns a Trainer object to this bitmap. 
  #-----------------------------------------------------------------------------
  def setTrainer(trainer, hue = nil)
    case trainer
    when Symbol, String
      @trainer = nil
      tr_data = GameData::TrainerType.get(trainer)
    else
      @trainer = trainer
      tr_data = GameData::TrainerType.get(trainer.trainer_type)
    end
    @scale = tr_data.trainer_sprite_scale
    refresh
    tr_hue = tr_data.trainer_sprite_hue
    hue_change(tr_hue) if tr_hue != 0
    hue_change(hue) if hue && !changedHue?
  end
  
  #-----------------------------------------------------------------------------
  # Compiles a spritesheet.
  #-----------------------------------------------------------------------------
  def compile_strip
    strip = []
    bmp = Bitmap.new(@bmp_file)
    @total_frames.times do |i|
      bitmap = Bitmap.new(@width, @height)
      bitmap.stretch_blt(Rect.new(0, 0, @width, @height), bmp, Rect.new((@width / @scale) * i, 0, @width / @scale, @height / @scale))
      strip.push(bitmap)
    end
    self.refresh(strip)
  end
  
  #-----------------------------------------------------------------------------
  # Refreshes bitmap parameters.
  #-----------------------------------------------------------------------------
  def refresh(bitmaps = nil)
    self.dispose
    if bitmaps.nil? && @bmp_file.is_a?(String)
      f_bmp = Bitmap.new(@bmp_file)
      if f_bmp.animated?
        @width = f_bmp.width * @scale
        @height = f_bmp.height * @scale
        f_bmp.frame_count.times do |i|
          f_bmp.goto_and_stop(i)
          bitmap = Bitmap.new(@width, @height)
          bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(0, 0, f_bmp.width, f_bmp.height))
          @bitmaps.push(bitmap)
        end
      elsif f_bmp.width > (f_bmp.height * 2)
        @width = f_bmp.height * @scale
        @height = f_bmp.height * @scale
        (f_bmp.width.to_f / f_bmp.height).ceil.times do |i|
          x = i * f_bmp.height
          bitmap = Bitmap.new(@width, @height)
          bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(x, 0, f_bmp.height, f_bmp.height))
          @bitmaps.push(bitmap)
        end
      else
        @width = f_bmp.width * @scale
        @height = f_bmp.height * @scale
        bitmap = Bitmap.new(@width, @height)
        bitmap.stretch_blt(Rect.new(0, 0, @width, @height), f_bmp, Rect.new(0, 0, f_bmp.width, f_bmp.height))
        @bitmaps.push(bitmap)
      end
      f_bmp.dispose
    else
      @bitmaps = bitmaps
    end
    if @bitmaps.length < 1 && !self.is_bitmap?
      raise "从指定资源构建位图图集失败 `#{@bmp_file}`"
    end
    if !self.is_bitmap?
      @total_frames = @bitmaps.length
      @temp_bmp = Bitmap.new(@bitmaps[0].width, @bitmaps[0].width)
    end
  end
  
  #-----------------------------------------------------------------------------
  # Animation related utilities.
  #-----------------------------------------------------------------------------
  def update
    return if disposed? || @total_frames <= 1
    timer = System.uptime
    delay = Settings::TRAINER_ANIMATION_SPEED / @total_frames
    return if timer - @last_uptime < delay
    (@reversed) ? @frame_idx -= 1 : @frame_idx += 1
    @frame_idx = 0 if @frame_idx >= @total_frames
    @frame_idx = @total_frames - 1 if @frame_idx < 0
    @last_uptime = timer
  end
  
  def to_frame(frame)
    frame = frame == "last" ? @total_frames - 1 : 0 if frame.is_a?(String)
    frame = @total_frames - 1 if frame >= @total_frames
    frame = 0 if frame < 0
    @frame_idx = frame
  end
  
  def play
    return if finished?
    update
  end
  
  def deanimate
    @frame_idx = 0
  end
  
  def finished?
    if @reversed
	  return (@frame_idx == 0)
	else
	  return (@frame_idx >= @total_frames - 1)
	end
  end

  #-----------------------------------------------------------------------------
  # Bitmap related utilities.
  #-----------------------------------------------------------------------------
  def bitmap
    return @bmp_file if self.is_bitmap? && !@bmp_file.disposed?
    return nil if self.disposed?
    @temp_bmp.clear
    @temp_bmp.blt(0, 0, @bitmaps[@frame_idx], Rect.new(0, 0, @width, @height))
    return @temp_bmp
  end
  
  def bitmap=(value)
    return if !value.is_a?(String)
    @bmp_file = value
    self.refresh
  end
  
  def is_bitmap?
    return @bmp_file.is_a?(BitmapWrapper) || @bmp_file.is_a?(Bitmap)
  end
  
  #-----------------------------------------------------------------------------
  # Hue related utilities.
  #-----------------------------------------------------------------------------
  def hue_change(value)
    @bitmaps.each { |bmp| bmp.hue_change(value) }
    @changed_hue = true
  end
  
  def changedHue?; return @changed_hue; end
  
  #-----------------------------------------------------------------------------
  # Dispose related utilities.
  #-----------------------------------------------------------------------------
  def dispose
    @bitmaps.each { |bmp| bmp.dispose }
    @bitmaps.clear
    @temp_bmp.dispose if @temp_bmp && !@temp_bmp.disposed?
  end
  
  def disposed?; return @bitmaps.empty?; end
end