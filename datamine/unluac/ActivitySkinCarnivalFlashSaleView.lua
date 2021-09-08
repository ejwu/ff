local ActivitySkinCarnivalFlashSaleView = class("ActivitySkinCarnivalFlashSaleView", function()
  local node = CLayout:create(display.size)
  node.name = "Game.views.activity.skinCarnival.ActivitySkinCarnivalFlashSaleView"
  node:enableNodeEvents()
  return node
end)
local RES_DICT = {
  BG_ORNAMENT_L = _res("ui/home/activity/skinCarnival/story_common_bg_diaoshi_1.png"),
  BG_ORNAMENT_R = _res("ui/home/activity/skinCarnival/story_common_bg_diaoshi_2.png"),
  BG = _res("ui/home/activity/skinCarnival/story_cap_bg.png"),
  TITLE_BG = _res("ui/home/activity/skinCarnival/story_common_bg_head.png"),
  TIPS_ICON = _res("ui/common/common_btn_tips.png"),
  SWITCH_BTN = _res("ui/home/activity/skinCarnival/story_common_btn_q.png"),
  SWITCH_BTN_L2D = _res("ui/home/activity/skinCarnival/story_common_btn_L2D.png"),
  STORY_BTN = _res("ui/home/activity/skinCarnival/story_common_btn_story.png"),
  STORY_BTN_LOCK_MASK = _res("ui/home/activity/skinCarnival/story_common_btn_story_lock.png"),
  STORY_BTN_LOCK = _res("ui/common/common_ico_lock.png"),
  BUY_BTN = _res("ui/home/activity/skinCarnival/story_cap_btn_buy.png"),
  SKIN_NAME_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_name.png"),
  SKIN_NAME_LINE = _res("ui/home/activity/skinCarnival/story_cap_line_name.png"),
  LIST_TITLE_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_head.png"),
  REWARD_DESCR_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_box.png"),
  REWARD_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_box_fire.png"),
  REWARD_BTN = _res("ui/home/activity/skinCarnival/story_cap_btn_box.png"),
  CELL_BG_N = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_gray.png"),
  CELL_BG_S = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_light.png"),
  CELL_BG_N_SMALL = _res("ui/home/activity/skinCarnival/story_cap_bg_stop.png"),
  CELL_DISCOUNT_BG_N = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_money_gray.png"),
  CELL_DISCOUNT_BG_S = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_money.png"),
  CELL_TIME_BG_N = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_time_gray.png"),
  CELL_TIME_BG_S = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_time.png"),
  COMMON_BTN_GREEN = _res("ui/common/common_btn_green.png"),
  COMMON_BTN_DISABLE = _res("ui/common/common_btn_orange_disable.png"),
  SKIN_GET_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_get.png"),
  SKIN_GET_TEXT_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_get_name.png"),
  CHEST_BTN_LIGHT = _res("ui/home/activity/skinCarnival/story_home_light_box.png"),
  BUY_BTN_LINE = _res("ui/home/activity/skinCarnival/story_common_line_buy.png"),
  REMIND_ICON = _res("ui/common/common_hint_circle_red_ico.png")
}
function ActivitySkinCarnivalFlashSaleView:ctor(...)
  local args = unpack({
    ...
  })
  self.theme = checkint(args.group)
  self:InitUI()
end
function ActivitySkinCarnivalFlashSaleView:InitUI()
  local function CreateView()
    local bg = display.newImageView(RES_DICT.BG, 0, 0)
    local size = bg:getContentSize()
    local view = CLayout:create(size)
    bg:setPosition(size.width / 2, size.height / 2)
    view:addChild(bg, 1)
    local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
    mask:setTouchEnabled(true)
    mask:setContentSize(size)
    mask:setPosition(cc.p(size.width / 2, size.height / 2))
    view:addChild(mask, -1)
    local titleBtn = display.newButton(-10, size.height - 20, {
      n = RES_DICT.TITLE_BG,
      ap = display.LEFT_TOP
    })
    view:addChild(titleBtn, 5)
    local titleLabel = display.newLabel(titleBtn:getContentSize().width / 2 - 20, titleBtn:getContentSize().height / 2, {
      text = "",
      fontSize = 24,
      color = "#ffffff",
      ttf = true,
      font = TTF_GAME_FONT,
      ttf = true,
      font = TTF_GAME_FONT,
      outlineSize = 1,
      outline = "#622A37"
    })
    titleBtn:addChild(titleLabel, 1)
    local tipsIcon = display.newImageView(RES_DICT.TIPS_ICON, titleBtn:getContentSize().width - 50, titleBtn:getContentSize().height / 2)
    titleBtn:addChild(tipsIcon, 3)
    local switchBtn = display.newButton(60, size.height - 155, {
      n = RES_DICT.SWITCH_BTN
    })
    view:addChild(switchBtn, 5)
    local storyBtn = display.newButton(60, size.height - 255, {
      n = RES_DICT.STORY_BTN
    })
    storyBtn:setVisible(false)
    view:addChild(storyBtn, 5)
    local storyBtnLockMask = display.newImageView(RES_DICT.STORY_BTN_LOCK_MASK, storyBtn:getContentSize().width / 2, storyBtn:getContentSize().height / 2)
    storyBtn:addChild(storyBtnLockMask, 1)
    local storyBtnLock = display.newImageView(RES_DICT.STORY_BTN_LOCK, storyBtnLockMask:getContentSize().width / 2, storyBtnLockMask:getContentSize().height / 2)
    storyBtnLockMask:addChild(storyBtnLock, 1)
    local buyBtn = display.newButton(-10, 35, {
      n = RES_DICT.BUY_BTN,
      ap = display.LEFT_BOTTOM
    })
    buyBtn:setVisible(false)
    view:addChild(buyBtn, 5)
    local buyBtnLabel = display.newLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 + 15, {
      text = __("\229\142\159\228\187\183\232\180\173\228\185\176"),
      fontSize = 22,
      color = "#784821",
      ttf = true,
      font = TTF_GAME_FONT
    })
    buyBtn:addChild(buyBtnLabel, 1)
    local buyBtnLine = display.newImageView(RES_DICT.BUY_BTN_LINE, buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2)
    buyBtn:addChild(buyBtnLine, 1)
    local buyBtnConsumeRichLabel = display.newRichLabel(buyBtn:getContentSize().width / 2, buyBtn:getContentSize().height / 2 - 15)
    buyBtn:addChild(buyBtnConsumeRichLabel, 1)
    local cardSkinDrawNode = display.newImageView("empty", 0, 45, {
      ap = display.LEFT_BOTTOM
    })
    view:addChild(cardSkinDrawNode, 3)
    local skinNameBg = display.newImageView(RES_DICT.SKIN_NAME_BG, 290, 180)
    skinNameBg:setCascadeOpacityEnabled(true)
    view:addChild(skinNameBg, 5)
    local skinNameLine = display.newImageView(RES_DICT.SKIN_NAME_LINE, skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height / 2)
    skinNameBg:addChild(skinNameLine, 1)
    local skinDescrLabel = display.newLabel(skinNameBg:getContentSize().width / 2, skinNameBg:getContentSize().height - 30, {
      text = "",
      fontSize = 22,
      color = "#FFB85D",
      ttf = true,
      font = TTF_GAME_FONT,
      outline = "#56120D",
      outlineSize = 1
    })
    skinNameBg:addChild(skinDescrLabel, 1)
    local skinNameLabel = display.newLabel(skinNameBg:getContentSize().width / 2, 30, {
      text = "",
      fontSize = 22,
      color = "#FFEF82",
      ttf = true,
      font = TTF_GAME_FONT,
      outline = "#56120D",
      outlineSize = 1
    })
    skinNameBg:addChild(skinNameLabel, 1)
    local listTitleBg = display.newImageView(RES_DICT.LIST_TITLE_BG, size.width - 330, size.height - 68)
    view:addChild(listTitleBg, 3)
    local listTitleLabel = display.newLabel(size.width - 330, size.height - 68, {
      text = __("\233\153\144\230\151\182\231\137\185\228\187\183\230\138\162\232\180\173"),
      fontSize = 22,
      color = "#FFEF86",
      ttf = true,
      font = TTF_GAME_FONT,
      outline = "#573012",
      outlineSize = 2
    })
    view:addChild(listTitleLabel, 5)
    local flashSaleListViewBg = display.newImageView("empty", size.width - 15, size.height - 55, {
      ap = display.RIGHT_TOP
    })
    view:addChild(flashSaleListViewBg, 3)
    local flashSaleListSize = cc.size(600, 498)
    local flashSaleListView = CListView:create(flashSaleListSize)
    flashSaleListView:setVisible(false)
    flashSaleListView:setPosition(cc.p(size.width - 35, size.height - 105))
    flashSaleListView:setDirection(eScrollViewDirectionVertical)
    flashSaleListView:setAnchorPoint(display.RIGHT_TOP)
    view:addChild(flashSaleListView, 5)
    local skinGetBg = display.newImageView(RES_DICT.SKIN_GET_BG, size.width - 335, size.height / 2 + 50)
    skinGetBg:setVisible(false)
    view:addChild(skinGetBg, 5)
    local skinGetTextBg = display.newImageView(RES_DICT.SKIN_GET_TEXT_BG, skinGetBg:getContentSize().width / 2, skinGetBg:getContentSize().height / 2 - 26)
    skinGetBg:addChild(skinGetTextBg, 1)
    local skinGetTextLabel = display.newLabel(skinGetTextBg:getContentSize().width / 2, skinGetTextBg:getContentSize().height / 2, {
      text = __("\229\189\147\229\137\141\229\164\150\232\167\130\229\183\178\232\142\183\229\190\151"),
      fontSize = 24,
      color = "#F8E2C3",
      ttf = true,
      font = TTF_GAME_FONT
    })
    skinGetTextBg:addChild(skinGetTextLabel, 1)
    local rewardDescrBg = display.newImageView(RES_DICT.REWARD_DESCR_BG, size.width - 78, 82, {
      ap = display.RIGHT_CENTER
    })
    view:addChild(rewardDescrBg, 1)
    local rewardDescrLabel = display.newLabel(size.width - 350, 80, {
      text = "",
      fontSize = 22,
      color = "#ffffff"
    })
    view:addChild(rewardDescrLabel, 5)
    local rewardBg = display.newImageView(RES_DICT.REWARD_BG, size.width - 105, 100)
    view:addChild(rewardBg, 3)
    local rewardBtn = display.newButton(size.width - 105, 92, {
      n = RES_DICT.REWARD_BTN
    })
    view:addChild(rewardBtn, 3)
    local rewardRemindIcon = display.newImageView(RES_DICT.REMIND_ICON, rewardBtn:getContentSize().width - 10, rewardBtn:getContentSize().height - 15)
    rewardRemindIcon:setVisible(false)
    rewardBtn:addChild(rewardRemindIcon, 10)
    local chestLight = display.newImageView(RES_DICT.CHEST_BTN_LIGHT, rewardBtn:getPositionX(), rewardBtn:getPositionY())
    chestLight:setVisible(false)
    view:addChild(chestLight, 2)
    chestLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 30)))
    return {
      view = view,
      titleLabel = titleLabel,
      titleBtn = titleBtn,
      switchBtn = switchBtn,
      storyBtn = storyBtn,
      storyBtnLockMask = storyBtnLockMask,
      buyBtn = buyBtn,
      buyBtnConsumeRichLabel = buyBtnConsumeRichLabel,
      cardSkinDrawNode = cardSkinDrawNode,
      skinDescrLabel = skinDescrLabel,
      skinNameLabel = skinNameLabel,
      skinNameBg = skinNameBg,
      flashSaleListSize = flashSaleListSize,
      flashSaleListView = flashSaleListView,
      rewardBtn = rewardBtn,
      skinGetBg = skinGetBg,
      rewardDescrLabel = rewardDescrLabel,
      chestLight = chestLight,
      flashSaleListViewBg = flashSaleListViewBg,
      rewardRemindIcon = rewardRemindIcon
    }
  end
  local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 153))
  eaterLayer:setTouchEnabled(true)
  eaterLayer:setContentSize(display.size)
  eaterLayer:setPosition(cc.p(display.cx, display.cy))
  self:addChild(eaterLayer, -1)
  self.eaterLayer = eaterLayer
  if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
    local bgOrnamentL = display.newImageView(RES_DICT.BG_ORNAMENT_L, display.cx - 700, display.cy + 700, {
      ap = display.CENTER_TOP
    })
    self:addChild(bgOrnamentL, -1)
    self.bgOrnamentL = bgOrnamentL
    local bgOrnamentR = display.newImageView(RES_DICT.BG_ORNAMENT_R, display.cx + 640, display.cy + 700, {
      ap = display.CENTER_TOP
    })
    self:addChild(bgOrnamentR, -1)
    self.bgOrnamentR = bgOrnamentR
  end
  xTry(function()
    self.viewData = CreateView()
    self:addChild(self.viewData.view)
    self.viewData.view:setPosition(display.center)
    self.viewData.view:setOpacity(0)
  end, __G__TRACKBACK__)
end
function ActivitySkinCarnivalFlashSaleView:EnterAction(pos)
  local viewData = self:GetViewData()
  viewData.view:setPosition(pos)
  viewData.view:setScale(0)
  local spawnAct = {
    cc.FadeIn:create(0.2),
    cc.MoveTo:create(0.2, display.center),
    cc.ScaleTo:create(0.2, 1)
  }
  if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
    table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, -200)))))
    table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackOut:create(cc.MoveBy:create(0.2, cc.p(0, -200)))))
  end
  viewData.view:runAction(cc.Sequence:create(cc.Spawn:create(spawnAct), cc.CallFunc:create(function()
    app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
  end)))
end
function ActivitySkinCarnivalFlashSaleView:BackAction(pos)
  local viewData = self:GetViewData()
  app.uiMgr:GetCurrentScene():AddViewForNoTouch()
  local spawnAct = {
    cc.FadeOut:create(0.2),
    cc.MoveTo:create(0.2, pos),
    cc.ScaleTo:create(0.2, 0)
  }
  if self.theme == SKIN_CASRNIVAL_THEME.FAIRY_TALE then
    table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentL, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
    table.insert(spawnAct, cc.TargetedAction:create(self.bgOrnamentR, cc.EaseBackIn:create(cc.MoveBy:create(0.2, cc.p(0, 200)))))
  end
  viewData.view:runAction(cc.Sequence:create(cc.Spawn:create(spawnAct), cc.CallFunc:create(function()
    app:DispatchObservers(ACTIVITY_SKIN_CARNIVAL_BACK_HOME)
    app:UnRegsitMediator("activity.skinCarnival.ActivitySkinCarnivalFlashSaleMediator")
  end)))
end
function ActivitySkinCarnivalFlashSaleView:RefreshTitle(title)
  local viewData = self:GetViewData()
  viewData.titleLabel:setString(tostring(title))
end
function ActivitySkinCarnivalFlashSaleView:RefreshRewardDescrLabel(skinId)
  local viewData = self:GetViewData()
  local skinConfig = CardUtils.GetCardSkinConfig(skinId)
  local cardConfig = CardUtils.GetCardConfig(skinConfig.cardId)
  display.commonLabelParams(viewData.rewardDescrLabel, {
    text = string.fmt(__("\232\142\183\229\190\151_name1_\229\164\150\232\167\130-_name2_\229\143\175\232\142\183\229\190\151\229\165\150\229\138\177\239\188\154"), {
      _name1_ = cardConfig.name,
      _name2_ = skinConfig.name
    }),
    w = 400,
    hAlign = display.TAC
  })
end
function ActivitySkinCarnivalFlashSaleView:RefreshBuyBtnConsumeRichlabel(consume)
  local viewData = self:GetViewData()
  display.reloadRichLabel(viewData.buyBtnConsumeRichLabel, {
    c = {
      {
        text = consume.num,
        fontSize = 22,
        color = "#FFEF82",
        ttf = true,
        font = TTF_GAME_FONT,
        outline = "#56120D",
        outlineSize = 2
      },
      {
        img = CommonUtils.GetGoodsIconPathById(consume.goodsId),
        scale = 0.18
      }
    }
  })
  CommonUtils.AddRichLabelTraceEffect(viewData.buyBtnConsumeRichLabel, "#56120D", 2, {1})
end
function ActivitySkinCarnivalFlashSaleView:RefreshSkinDrawNode(skinId, effect)
  local viewData = self:GetViewData()
  viewData.cardSkinDrawNode:setTexture(__(string.format("ui/home/activity/skinCarnival/skinImg/story_skin_%d.png", checkint(skinId))))
  if CardUtils.IsShowCardLive2d(skinId) then
    viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN_L2D)
    viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN_L2D)
  else
    viewData.switchBtn:setNormalImage(RES_DICT.SWITCH_BTN)
    viewData.switchBtn:setSelectedImage(RES_DICT.SWITCH_BTN)
  end
  local skinConfig = CardUtils.GetCardSkinConfig(skinId)
  local cardConfig = CardUtils.GetCardConfig(skinConfig.cardId)
  viewData.skinDescrLabel:setString(string.fmt(__("_name_\229\164\150\232\167\130"), {
    _name_ = cardConfig.name
  }))
  viewData.skinNameLabel:setString(skinConfig.name)
  if effect and effect ~= "" then
    if viewData.view:getChildByName("skinEffect") then
      viewData.view:getChildByName("skinEffect"):runAction(cc.RemoveSelf:create())
    end
    local skinEffectSpine = sp.SkeletonAnimation:create(string.format("ui/home/activity/skinCarnival/spineEffect/%s.json", effect), string.format("ui/home/activity/skinCarnival/spineEffect/%s.atlas", effect), 1)
    skinEffectSpine:setAnimation(0, "play", true)
    skinEffectSpine:setName("skinEffect")
    skinEffectSpine:setPosition(cc.p(280, 320))
    viewData.view:addChild(skinEffectSpine, 3)
  end
  viewData.flashSaleListViewBg:setTexture(__(string.format("ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png", checkint(skinId))))
end
function ActivitySkinCarnivalFlashSaleView:RefreshBtnState(hasSkin, hasDrawn)
  local viewData = self:GetViewData()
  viewData.storyBtn:setVisible(true)
  if not hasSkin then
    viewData.storyBtnLockMask:setVisible(true)
    viewData.buyBtn:setVisible(true)
    viewData.rewardBtn:setEnabled(true)
    viewData.skinGetBg:setVisible(false)
    viewData.flashSaleListView:setVisible(true)
    return
  end
  viewData.storyBtnLockMask:setVisible(false)
  viewData.buyBtn:setVisible(false)
  viewData.skinGetBg:setVisible(true)
  viewData.flashSaleListView:setVisible(false)
  viewData.rewardDescrLabel:setString(__("\229\165\150\229\147\129\229\183\178\233\162\134\229\143\150"))
  if hasDrawn then
    viewData.rewardBtn:setEnabled(false)
    viewData.chestLight:setVisible(false)
  else
    viewData.rewardBtn:setEnabled(true)
    viewData.chestLight:setVisible(true)
  end
end
function ActivitySkinCarnivalFlashSaleView:RefreshRewardRemindIcon(state)
  local viewData = self:GetViewData()
  viewData.rewardRemindIcon:setVisible(state)
end
function ActivitySkinCarnivalFlashSaleView:ShowCardSkin()
  local viewData = self:GetViewData()
  viewData.cardSkinDrawNode:setVisible(true)
end
function ActivitySkinCarnivalFlashSaleView:RefreshFlashSaleListView(listData, skinId, buyCallback, listCallback)
  local viewData = self:GetViewData()
  viewData.flashSaleListView:removeAllNodes()
  for i, v in ipairs(checktable(listData)) do
    local cell = self:CreateFlashSaleListCell(v, skinId, buyCallback, listCallback)
    viewData.flashSaleListView:insertNodeAtLast(cell)
  end
  viewData.flashSaleListView:reloadData()
end
function ActivitySkinCarnivalFlashSaleView:CreateFlashSaleListCell(cellData, skinId, buyCallback, listCallback)
  local viewData = self:GetViewData()
  local flashSaleConfig = CommonUtils.GetConfig("skinCarnival", "flashSale", cellData.flashSaleId)
  local size = cc.size(viewData.flashSaleListSize.width, 168)
  local bg
  if checkint(cellData.status) == 3 then
    size.height = 130
    bg = display.newImageView(RES_DICT.CELL_BG_N_SMALL, size.width / 2, size.height / 2)
  else
    bg = display.newImageView(RES_DICT.CELL_BG_N, size.width / 2, size.height / 2)
  end
  local layout = CLayout:create(size)
  layout:addChild(bg, 1)
  local discountBg = display.newImageView(RES_DICT.CELL_DISCOUNT_BG_N, 38, size.height - 25, {
    scale9 = true,
    size = cc.size(120, 50),
    ap = display.LEFT_TOP
  })
  layout:addChild(discountBg, 3)
  local discountLabelColor = "#F8E2C3"
  if checkint(cellData.status) == 2 then
    discountLabelColor = "#FFEF82"
  end
  local discountLabel = display.newLabel(40, size.height - 35, {
    text = string.fmt(__("_num_\230\138\152"), {
      _num_ = CommonUtils.GetDiscountOffFromCN(flashSaleConfig.displayDiscount)
    }),
    fontSize = 22,
    color = discountLabelColor,
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "#573012",
    outlineSize = 2,
    ap = display.LEFT_TOP
  })
  layout:addChild(discountLabel, 5)
  local timeBg = display.newImageView(RES_DICT.CELL_TIME_BG_N, size.width - 40, size.height - 28, {
    ap = display.RIGHT_CENTER
  })
  layout:addChild(timeBg, 3)
  local timeTable = os.date("*t", checkint(cellData.startTime))
  local timeStr = string.fmt(__("_num1_\229\185\180_num2_\230\156\136_num3_\230\151\165 _time_"), {
    _num1_ = timeTable.year,
    _num2_ = timeTable.month,
    _num3_ = timeTable.day,
    _time_ = os.date("%X", checkint(cellData.startTime))
  })
  local timeLabel = display.newLabel(size.width - 55, size.height - 28, {
    text = timeStr,
    fontSize = 20,
    color = "#ffffff",
    ap = display.RIGHT_CENTER
  })
  layout:addChild(timeLabel, 5)
  if checkint(cellData.status) == 3 then
    local finishedLabel = display.newLabel(size.width / 2, size.height / 2 - 15, {
      text = __("\229\183\178\231\187\147\230\157\159"),
      fontSize = 26,
      color = "#76553b"
    })
    layout:addChild(finishedLabel, 5)
    local listBtn = display.newButton(size.width / 2, size.height / 2, {
      n = "empty",
      size = size,
      cb = listCallback
    })
    listBtn:setTag(cellData.flashSaleId)
    layout:addChild(listBtn, 5)
  else
    local buyBtn
    if checkint(cellData.status) == 1 then
      buyBtn = display.newButton(size.width - 150, size.height / 2, {
        size = cc.size(140, 59),
        scale9 = true,
        n = RES_DICT.COMMON_BTN_DISABLE,
        enable = false
      })
      display.commonLabelParams(buyBtn, fontWithColor(14, {
        text = __("\230\156\170\229\188\128\229\167\139")
      }))
      layout:addChild(buyBtn, 5)
    elseif checkint(cellData.status) == 2 then
      bg:setTexture(RES_DICT.CELL_BG_S)
      discountBg:setTexture(RES_DICT.CELL_DISCOUNT_BG_S)
      timeBg:setTexture(RES_DICT.CELL_TIME_BG_S)
      buyBtn = display.newButton(size.width - 150, size.height / 2, {
        size = cc.size(140, 59),
        scale9 = true,
        n = RES_DICT.COMMON_BTN_GREEN,
        cb = buyCallback
      })
      buyBtn:setTag(cellData.flashSaleId)
      layout:addChild(buyBtn, 5)
      local prize = display.newLabel(buyBtn:getContentSize().width / 2 + 15, buyBtn:getContentSize().height / 2, fontWithColor(14, {
        text = flashSaleConfig.price,
        ap = display.RIGHT_CENTER
      }))
      buyBtn:addChild(prize, 5)
      local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(flashSaleConfig.currency), buyBtn:getContentSize().width / 2 + 35, buyBtn:getContentSize().height / 2)
      goodsIcon:setScale(0.18)
      buyBtn:addChild(goodsIcon, 5)
    end
    local rewardGoodsNode = require("common.GoodNode").new({
      id = skinId,
      callBack = function(sender)
        app.uiMgr:ShowInformationTipsBoard({
          targetNode = sender,
          iconId = checkint(skinId),
          type = 1
        })
      end
    })
    rewardGoodsNode:setScale(0.8)
    display.commonUIParams(rewardGoodsNode, {
      po = cc.p(size.width / 2 - 10, size.height / 2 - 14)
    })
    layout:addChild(rewardGoodsNode, 5)
    local richLabel = display.newRichLabel(size.width - 150, 35, {
      c = {
        {text = ""}
      }
    })
    display.reloadRichLabel(richLabel, {
      width = 210,
      r = true,
      c = {
        {
          text = __("\229\133\168\230\156\141\233\153\144\233\135\143\239\188\154"),
          fontSize = 20,
          color = "#5c5c5c"
        },
        {
          text = tostring(cellData.left),
          fontSize = 20,
          color = "#d23d3d"
        },
        {
          text = string.format("/%d", checkint(cellData.limit)),
          fontSize = 20,
          color = "#5c5c5c"
        }
      }
    })
    layout:addChild(richLabel, 5)
  end
  return layout
end
function ActivitySkinCarnivalFlashSaleView:GetViewData()
  return self.viewData
end
return ActivitySkinCarnivalFlashSaleView
