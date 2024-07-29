#-------------------------------------------------------------------------------
# Special hold item on a map which includes battle in the name  全代树果，和部分道具
#----翻译BY:IFRIT-------------------------------------------------------------------
EventHandlers.add(:following_pkmn_item, :battle_map, proc { |_pkmn, _random_val|
  if $game_map.name.include?(_INTL("Battle"))
    items = [:POKEBALL, :POKEBALL, :POKEBALL, :GREATBALL, :GREATBALL, :ULTRABALL,:ROWAPBERRY,        :KEEBERRY,  :MARANGABERRY,    :CHERIBERRY,        :CHESTOBERRY,
    :PECHABERRY,         :RAWSTBERRY,    :ASPEARBERRY,          :LEPPABERRY,      :ORANBERRY,
    :PERSIMBERRY,         :LUMBERRY, :SITRUSBERRY,          :FIGYBERRY,        :WIKIBERRY,
    :MAGOBERRY,     :AGUAVBERRY, :IAPAPABERRY,      :RAZZBERRY,      :BLUKBERRY,
    :QUALOTBERRY,   :HONDEWBERRY, :GREPABERRY, :TAMATOBERRY, :CORNNBERRY,
    :MAGOSTBERRY, :RABUTABERRY,  :NOMELBERRY,        :SPELONBERRY,  :PAMTREBERRY,    :WATMELBERRY,        :DURINBERRY,
    :BELUEBERRY,         :OCCABERRY,    :PASSHOBERRY,          :WACANBERRY,      :RINDOBERRY,
    :CHOPLEBERRY,         :KEBIABERRY, :SHUCABERRY,          :COBABERRY,        :PAYAPABERRY,
    :TANGABERRY,     :CHARTIBERRY, :KASIBBERRY,      :HABANBERRY,      :COLBURBERRY,
    :BABIRIBERRY,   :ROSELIBERRY, :CHILANBERRY, :LIECHIBERRY, :GANLONBERRY,
    :SALACBERRY, :PETAYABERRY,    :APICOTBERRY,          :LANSATBERRY,      :STARFBERRY,
    :ENIGMABERRY,         :MICLEBERRY, :CUSTAPBERRY,          :JABOCABERRY,        :REDAPRICORN,
    :YELLOWAPRICORN,     :BLUEAPRICORN, :GREENAPRICORN,      :PINKAPRICORN,      :WHITEAPRICORN,
    :BLACKAPRICORN,   :ULTRABALL, :GREATBALL, :POKEBALL, :REPEL,
    :SUPERREPEL, :MAXREPEL, :FIRESTONE,          :THUNDERSTONE,        :WATERSTONE,
    :LEAFSTONE,     :MOONSTONE, :SUNSTONE,      :DUSKSTONE,      :DAWNSTONE,
    :SHINYSTONE,   :ICESTONE, :TINYMUSHROOM, :BIGMUSHROOM, :BALMMUSHROOM,
    :PEARL, :BIGPEARL,    :PEARLSTRING,     :STARDUST, :STARPIECE,      :COMETSHARD,      :NUGGET,
    :BIGNUGGET,   :HEARTSCALE, :POTION, :SUPERPOTION, :HYPERPOTION,
    :MAXPOTION, :FULLRESTORE,  :SACREDASH,        :AWAKENING,  :ANTIDOTE,    :BURNHEAL,        :PARALYZEHEAL,
    :ICEHEAL,         :FULLHEAL,     :ETHER, :MAXETHER,      :ELIXIR,      :MAXELIXIR,
    :PPUP,   :PPMAX, :EXPCANDYXS, :EXPCANDYS, :EXPCANDYM,
    :EXPCANDYL, :EXPCANDYXL,  :RARECANDY]
    # 以上方框内可随意添加，宝可梦会给你其中2个，然后出现下面的对话。
    # 原文是 圆圆的东西。但我改为了更通用的对话。
    next true if FollowingPkmn.item(items.sample, 2, _INTL("{1} 好像找到了什么？"))
  end
})
#-------------------------------------------------------------------------------
# Generic Item Dialogue 全代树果，和部分道具
#-------------------------------------------------------------------------------
EventHandlers.add(:following_pkmn_item, :regular, proc { |_pkmn, _random_val|
  items = [
    :ROWAPBERRY,        :KEEBERRY,  :MARANGABERRY,    :CHERIBERRY,        :CHESTOBERRY,
    :PECHABERRY,         :RAWSTBERRY,    :ASPEARBERRY,          :LEPPABERRY,      :ORANBERRY,
    :PERSIMBERRY,         :LUMBERRY, :SITRUSBERRY,          :FIGYBERRY,        :WIKIBERRY,
    :MAGOBERRY,     :AGUAVBERRY, :IAPAPABERRY,      :RAZZBERRY,      :BLUKBERRY,
    :QUALOTBERRY,   :HONDEWBERRY, :GREPABERRY, :TAMATOBERRY, :CORNNBERRY,
    :MAGOSTBERRY, :RABUTABERRY,  :NOMELBERRY,        :SPELONBERRY,  :PAMTREBERRY,    :WATMELBERRY,        :DURINBERRY,
    :BELUEBERRY,         :OCCABERRY,    :PASSHOBERRY,          :WACANBERRY,      :RINDOBERRY,
    :CHOPLEBERRY,         :KEBIABERRY, :SHUCABERRY,          :COBABERRY,        :PAYAPABERRY,
    :TANGABERRY,     :CHARTIBERRY, :KASIBBERRY,      :HABANBERRY,      :COLBURBERRY,
    :BABIRIBERRY,   :ROSELIBERRY, :CHILANBERRY, :LIECHIBERRY, :GANLONBERRY,
    :SALACBERRY, :PETAYABERRY,    :APICOTBERRY,          :LANSATBERRY,      :STARFBERRY,
    :ENIGMABERRY,         :MICLEBERRY, :CUSTAPBERRY,          :JABOCABERRY,        :REDAPRICORN,
    :YELLOWAPRICORN,     :BLUEAPRICORN, :GREENAPRICORN,      :PINKAPRICORN,      :WHITEAPRICORN,
    :BLACKAPRICORN,   :ULTRABALL, :GREATBALL, :POKEBALL, :REPEL,
    :SUPERREPEL, :MAXREPEL, :FIRESTONE,          :THUNDERSTONE,        :WATERSTONE,
    :LEAFSTONE,     :MOONSTONE, :SUNSTONE,      :DUSKSTONE,      :DAWNSTONE,
    :SHINYSTONE,   :ICESTONE, :TINYMUSHROOM, :BIGMUSHROOM, :BALMMUSHROOM,
    :PEARL, :BIGPEARL,    :PEARLSTRING,     :STARDUST, :STARPIECE,      :COMETSHARD,      :NUGGET,
    :BIGNUGGET,   :HEARTSCALE, :POTION, :SUPERPOTION, :HYPERPOTION,
    :MAXPOTION, :FULLRESTORE,  :SACREDASH,        :AWAKENING,  :ANTIDOTE,    :BURNHEAL,        :PARALYZEHEAL,
    :ICEHEAL,         :FULLHEAL,     :ETHER, :MAXETHER,      :ELIXIR,      :MAXELIXIR,
    :PPUP,   :PPMAX, :EXPCANDYXS, :EXPCANDYS, :EXPCANDYM,
    :EXPCANDYL, :EXPCANDYXL,  :RARECANDY
  ]
  # 如果不指定以上道具的数量和信息，则默认为1，应该也不会出现对话。
  next true if FollowingPkmn.item(items.sample)
})
#-------------------------------------------------------------------------------
