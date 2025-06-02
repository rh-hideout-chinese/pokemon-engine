#==============================================================================
# * Scene_Controls
#------------------------------------------------------------------------------
# Shows a help screen listing the keyboard controls.
# Display with:
#      pbEventScreen(ButtonEventScene)
#==============================================================================
class ButtonEventScene < EventScene
  def initialize(viewport = nil)
    super
    Graphics.freeze
    @current_screen = 1
    addImage(0, 0, "Graphics/UI/Controls help/bg")
    @labels = []
    @label_screens = []
    @keys = []
    @key_screens = []

       addImageForScreen(1, 44, 122, _INTL("Graphics/UI/Controls help/help_f1"))
    addImageForScreen(1, 44, 252, _INTL("Graphics/UI/Controls help/help_f8"))
    addLabelForScreen(1, 134, 84, 352, _INTL("\n打开按键设置窗口，在这里为\n每个控制选项选择哪些键位。"))
    addLabelForScreen(1, 134, 244, 352, _INTL("\n截屏，截屏文件被放置在与存\n档文件相同的文件夹中。"))

    addImageForScreen(2, 16, 158, _INTL("Graphics/UI/Controls help/help_arrows"))
    addLabelForScreen(2, 134, 100, 352, _INTL("\n使用方向键移动主角。你还可\n以使用方向键选择项目和导航\n菜单。"))

    addImageForScreen(3, 16, 90, _INTL("Graphics/UI/Controls help/help_usekey"))
    addImageForScreen(3, 16, 236, _INTL("Graphics/UI/Controls help/help_backkey"))
    addLabelForScreen(3, 134, 68, 352, _INTL("\n用于确认选择、与人物和物品\n交互以及在文本中移动。\n（默认：C）"))
	  addLabelForScreen(3, 134, 196, 352, _INTL("\n用于取消、退出一个模式。在\n移动过程中，按住此键可改变\n速度。（默认：X）"))

    addImageForScreen(4, 16, 90, _INTL("Graphics/UI/Controls help/help_actionkey"))
    addImageForScreen(4, 16, 236, _INTL("Graphics/UI/Controls help/help_specialkey"))
    addLabelForScreen(4, 134, 68, 352, _INTL("\n用于打开暂停菜单。根据上下\n文还有其他功能。（默认：Z）"))
	  addLabelForScreen(4, 134, 196, 352, _INTL("\n用于打开备用菜单，可以使用\n已注册的物品和可用的场地移\n动。（默认：D）"))

    set_up_screen(@current_screen)
    Graphics.transition
    # Go to next screen when user presses USE
    onCTrigger.set(method(:pbOnScreenEnd))
  end

  def addLabelForScreen(number, x, y, width, text)
    @labels.push(addLabel(x, y, width, text))
    @label_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def addImageForScreen(number, x, y, filename)
    @keys.push(addImage(x, y, filename))
    @key_screens.push(number)
    @picturesprites[@picturesprites.length - 1].opacity = 0
  end

  def set_up_screen(number)
    @label_screens.each_with_index do |screen, i|
      @labels[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    @key_screens.each_with_index do |screen, i|
      @keys[i].moveOpacity((screen == number) ? 10 : 0, 10, (screen == number) ? 255 : 0)
    end
    pictureWait   # Update event scene with the changes
  end

  def pbOnScreenEnd(scene, *args)
    last_screen = [@label_screens.max, @key_screens.max].max
    if @current_screen >= last_screen
      # End scene
      $game_temp.background_bitmap = Graphics.snap_to_bitmap
      Graphics.freeze
      @viewport.color = Color.black   # Ensure screen is black
      Graphics.transition(8, "fadetoblack")
      $game_temp.background_bitmap.dispose
      scene.dispose
    else
      # Next screen
      @current_screen += 1
      onCTrigger.clear
      set_up_screen(@current_screen)
      onCTrigger.set(method(:pbOnScreenEnd))
    end
  end
end
