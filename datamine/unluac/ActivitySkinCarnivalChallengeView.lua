local ActivitySkinCarnivalChallengeView = class("ActivitySkinCarnivalChallengeView", function()
  local node = CLayout:create(display.size)
  node.name = "Game.views.activity.skinCarnival.ActivitySkinCarnivalChallengeView"
  node:enableNodeEvents()
  return node
end)
local CELL_TYPE = {
  FINISHED = 1,
  CURRENT = 2,
  UNFINISHED = 3
}
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
  CHALLENGE_TEAM_BG = _res("ui/home/activity/skinCarnival/story_prince_bg_challenge.png"),
  CHALLENGE_TEAM_LINE = _res("ui/home/activity/skinCarnival/story_prince_line_challenge.png"),
  COMMON_BTN_ORANGE = _res("ui/common/common_btn_orange.png"),
  COMMON_BTN_ORANGE_D = _res("ui/common/common_btn_orange_disable.png"),
  FIGHT_POINT_BG = _res("ui/home/activity/skinCarnival/maps_fight_bg_sword1.png"),
  CELL_BG_FINISHED = _res("ui/home/activity/skinCarnival/story_prince_bg_list_gray.png"),
  CELL_BG_CURRENT = _res("ui/home/activity/skinCarnival/story_prince_bg_list_buy.png"),
  CELL_BG_UNFINISHED = _res("ui/home/activity/skinCarnival/story_prince_bg_list_not.png"),
  CELL_DISCOUNT_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_money.png"),
  CELL_DISCOUNT_BG_GRAY = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_money_gray.png"),
  CELL_FINISHED_ICON = _res("ui/home/activity/skinCarnival/story_cinderella_ico_completed.png"),
  COMMON_BTN_GREEN = _res("ui/common/common_btn_green.png"),
  SKIN_GET_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_buy_get.png"),
  SKIN_GET_TEXT_BG = _res("ui/home/activity/skinCarnival/story_cap_bg_get_name.png"),
  SKIN_GET_BTN_TEXT_BG = _res("ui/home/activity/skinCarnival/story_prince_bg_get.png"),
  BUY_BTN_LINE = _res("ui/home/activity/skinCarnival/story_common_line_buy.png"),
  BATTLE_FIGHT_SPINE = _spn("effects/fire/skeleton")
}
function ActivitySkinCarnivalChallengeView:ctor(...)
  local args = unpack({
    ...
  })
  self.theme = checkint(args.group)
  self:InitUI()
end
function ActivitySkinCarnivalChallengeView:InitUI()
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
    local challengeTitle = display.newLabel(size.width - 525, size.height - 58, {
      text = __("\232\190\190\230\136\144\230\140\145\230\136\152\231\155\174\230\160\135\239\188\140\232\142\183\229\190\151\230\138\152\230\137\163\232\180\173\228\185\176\232\181\132\230\160\188"),
      color = "#891E1E",
      fontSize = 22,
      ttf = true,
      font = TTF_GAME_FONT
    })
    view:addChild(challengeTitle, 5)
    local challengeListViewBg = display.newImageView("empty", size.width - 15, size.height, {
      ap = display.RIGHT_TOP
    })
    view:addChild(challengeListViewBg, 3)
    local challengeListSize = cc.size(640, 340)
    local challengeListView = CListView:create(challengeListSize)
    challengeListView:setPosition(cc.p(size.width - 45, size.height - 90))
    challengeListView:setDirection(eScrollViewDirectionVertical)
    challengeListView:setAnchorPoint(display.RIGHT_TOP)
    view:addChild(challengeListView, 5)
    local skinGetBg = display.newImageView(RES_DICT.SKIN_GET_BG, size.width - 370, size.height / 2 + 115)
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
    local challengeTeamBg = display.newImageView(RES_DICT.CHALLENGE_TEAM_BG, 0, 0)
    local challengeLayoutSize = challengeTeamBg:getContentSize()
    local challengeLayout = CLayout:create(challengeLayoutSize)
    display.commonUIParams(challengeLayout, {
      po = cc.p(size.width - 45, 52),
      ap = display.RIGHT_BOTTOM
    })
    view:addChild(challengeLayout, 5)
    challengeTeamBg:setPosition(cc.p(challengeLayoutSize.width / 2, challengeLayoutSize.height / 2))
    challengeLayout:addChild(challengeTeamBg, 1)
    local challengeTeamLine = display.newImageView(RES_DICT.CHALLENGE_TEAM_LINE, challengeLayoutSize.width / 2, challengeLayoutSize.height / 2 + 15)
    challengeLayout:addChild(challengeTeamLine, 3)
    local challengeTeamTitle = display.newLabel(challengeLayoutSize.width / 2 + 6, challengeLayoutSize.height - 30, {
      text = __("\230\140\145\230\136\152\229\175\185\232\177\161"),
      fontSize = 24,
      color = "#891E1E",
      font = TTF_GAME_FONT,
      ttf = true
    })
    challengeLayout:addChild(challengeTeamTitle, 5)
    local challengeBtn = display.newButton(challengeListSize.width / 2, 42, {
      n = RES_DICT.COMMON_BTN_ORANGE
    })
    challengeLayout:addChild(challengeBtn, 5)
    display.commonLabelParams(challengeBtn, fontWithColor(14, {
      text = __("\230\140\145\230\136\152")
    }))
    local skinGetBtnBg = display.newImageView(RES_DICT.SKIN_GET_BTN_TEXT_BG, challengeListSize.width / 2, 42)
    skinGetBtnBg:setVisible(false)
    challengeLayout:addChild(skinGetBtnBg, 5)
    local skinGetBtnTextLabel = display.newLabel(skinGetBtnBg:getContentSize().width / 2, skinGetBtnBg:getContentSize().height / 2, {
      text = __("\230\140\145\230\136\152\229\183\178\229\174\140\230\136\144"),
      fontSize = 24,
      color = "#643931"
    })
    skinGetBtnBg:addChild(skinGetBtnTextLabel, 5)
    local fireSpine = sp.SkeletonAnimation:create(RES_DICT.BATTLE_FIGHT_SPINE.json, RES_DICT.BATTLE_FIGHT_SPINE.atlas, 1)
    fireSpine:update(0)
    fireSpine:setAnimation(0, "huo", true)
    fireSpine:setPosition(cc.p(challengeLayoutSize.width - 100, challengeLayoutSize.height - 45))
    challengeLayout:addChild(fireSpine, 3)
    local fightPointLabel = cc.Label:createWithBMFont("font/team_ico_fight_figure.fnt", "")
    display.commonUIParams(fightPointLabel, {
      ap = cc.p(0.5, 0.5),
      po = cc.p(challengeLayoutSize.width - 115, challengeLayoutSize.height - 33)
    })
    fightPointLabel:setHorizontalAlignment(display.TAR)
    fightPointLabel:setScale(0.7)
    challengeLayout:addChild(fightPointLabel, 1)
    local enemyLayout = CLayout:create(cc.size(challengeLayoutSize.width, 124))
    challengeLayout:addChild(enemyLayout, 5)
    enemyLayout:setPosition(cc.p(challengeLayoutSize.width / 2, challengeLayoutSize.height / 2 + 18))
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
      challengeListSize = challengeListSize,
      challengeListView = challengeListView,
      challengeLayout = challengeLayout,
      challengeBtn = challengeBtn,
      fightPointLabel = fightPointLabel,
      enemyLayout = enemyLayout,
      skinGetBg = skinGetBg,
      skinGetBtnTextLabel = skinGetBtnTextLabel,
      skinGetBtnBg = skinGetBtnBg,
      challengeListViewBg = challengeListViewBg
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
function ActivitySkinCarnivalChallengeView:EnterAction(pos)
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
function ActivitySkinCarnivalChallengeView:BackAction(pos)
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
    app:UnRegsitMediator("activity.skinCarnival.ActivitySkinCarnivalChallengeMediator")
  end)))
end
function ActivitySkinCarnivalChallengeView:RefreshTitle(title)
  local viewData = self:GetViewData()
  viewData.titleLabel:setString(tostring(title))
end
function ActivitySkinCarnivalChallengeView:RefreshBuyBtnConsumeRichlabel(consume)
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
function ActivitySkinCarnivalChallengeView:RefreshSkinDrawNode(skinId, effect)
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
  viewData.challengeListViewBg:setTexture(__(string.format("ui/home/activity/skinCarnival/listBg/story_list_bg_%d.png", checkint(skinId))))
end
function ActivitySkinCarnivalChallengeView:RefreshBtnState(hasSkin, discountId)
  local viewData = self:GetViewData()
  viewData.storyBtn:setVisible(true)
  if hasSkin then
    viewData.storyBtnLockMask:setVisible(false)
    viewData.buyBtn:setVisible(false)
    viewData.challengeListView:setVisible(false)
    viewData.skinGetBg:setVisible(true)
    viewData.skinGetBtnBg:setVisible(true)
    viewData.challengeBtn:setVisible(false)
  else
    viewData.challengeListView:setVisible(true)
    viewData.storyBtnLockMask:setVisible(true)
    viewData.buyBtn:setVisible(true)
    viewData.skinGetBg:setVisible(false)
    viewData.skinGetBtnBg:setVisible(false)
    viewData.challengeBtn:setVisible(true)
    if checkint(discountId) > 0 then
      viewData.buyBtn:setEnabled(false)
    else
      viewData.buyBtn:setEnabled(true)
    end
  end
end
function ActivitySkinCarnivalChallengeView:ShowCardSkin()
  local viewData = self:GetViewData()
  viewData.cardSkinDrawNode:setVisible(true)
end
function ActivitySkinCarnivalChallengeView:RefreshChallengeListView(listData, discountId, callback)
  local viewData = self:GetViewData()
  viewData.challengeListView:removeAllNodes()
  for i, v in ipairs(listData) do
    local cell
    if v.discountId < checkint(discountId) then
      cell = self:CreateFinishedCell(v)
    elseif v.discountId == checkint(discountId) then
      cell = self:CreateCurrentCell(v, callback)
    elseif v.discountId > checkint(discountId) then
      cell = self:CreateUnfinishedCell(v)
    end
    viewData.challengeListView:insertNodeAtLast(cell)
  end
  viewData.challengeListView:reloadData()
end
function ActivitySkinCarnivalChallengeView:CreateFinishedCell(cellData)
  local viewData = self:GetViewData()
  local layout = CLayout:create()
  local size = cc.size(viewData.challengeListSize.width, 65)
  layout:setContentSize(size)
  local bg = display.newImageView(RES_DICT.CELL_BG_FINISHED, size.width / 2, size.height / 2)
  layout:addChild(bg, 1)
  local discountBg = display.newImageView(RES_DICT.CELL_DISCOUNT_BG_GRAY, 15, size.height / 2, {
    ap = display.LEFT_CENTER,
    ap = display.LEFT_CENTER,
    size = cc.size(125, 50),
    scale9 = true
  })
  discountBg:setCascadeOpacityEnabled(true)
  layout:addChild(discountBg, 3)
  local discountLabel = display.newLabel(discountBg:getContentSize().width / 2 - 4, discountBg:getContentSize().height / 2, {
    text = string.fmt(__("_num_\230\138\152"), {
      _num_ = CommonUtils.GetDiscountOffFromCN(cellData.displayDiscount)
    }),
    fontSize = 22,
    color = "#F8E2C3",
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "#573012",
    outlineSize = 2
  })
  discountBg:addChild(discountLabel, 1)
  local conditionLabel = display.newLabel(150, size.height / 2, {
    text = cellData.condition,
    w = 300,
    hAlign = display.TAL,
    fontSize = 20,
    color = "#76553b",
    ap = display.LEFT_CENTER
  })
  layout:addChild(conditionLabel, 5)
  local finishedIcon = display.newImageView(RES_DICT.CELL_FINISHED_ICON, size.width - 120, size.height / 2)
  layout:addChild(finishedIcon, 5)
  return layout
end
function ActivitySkinCarnivalChallengeView:CreateCurrentCell(cellData, callback)
  local viewData = self:GetViewData()
  local layout = CLayout:create()
  local size = cc.size(viewData.challengeListSize.width, 92)
  layout:setContentSize(size)
  local bg = display.newImageView(RES_DICT.CELL_BG_CURRENT, size.width / 2, size.height / 2)
  layout:addChild(bg, 1)
  local discountBg = display.newImageView(RES_DICT.CELL_DISCOUNT_BG, 15, size.height / 2, {
    ap = display.LEFT_CENTER,
    ap = display.LEFT_CENTER,
    size = cc.size(125, 50),
    scale9 = true
  })
  discountBg:setCascadeOpacityEnabled(true)
  layout:addChild(discountBg, 3)
  local discountLabel = display.newLabel(discountBg:getContentSize().width / 2 - 4, discountBg:getContentSize().height / 2, {
    text = string.fmt(__("_num_\230\138\152"), {
      _num_ = CommonUtils.GetDiscountOffFromCN(cellData.displayDiscount)
    }),
    fontSize = 22,
    color = "#FFEF82",
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "#573012",
    outlineSize = 2
  })
  discountBg:addChild(discountLabel, 1)
  local conditionLabel = display.newLabel(150, size.height / 2, {
    text = cellData.condition,
    w = 300,
    hAlign = display.TAL,
    fontSize = 20,
    color = "#76553b",
    ap = display.LEFT_CENTER
  })
  layout:addChild(conditionLabel, 5)
  local buyBtn = display.newButton(size.width - 120, size.height / 2, {
    n = RES_DICT.COMMON_BTN_GREEN,
    cb = callback
  })
  layout:addChild(buyBtn, 5)
  local priceLabel = cc.Label:createWithBMFont("font/small/common_text_num.fnt", cellData.price)
  priceLabel:setAnchorPoint(display.RIGHT_CENTER)
  priceLabel:setHorizontalAlignment(display.TAR)
  priceLabel:setPosition(size.width - 110, size.height / 2)
  layout:addChild(priceLabel, 5)
  local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(cellData.currency), size.width - 90, size.height / 2)
  goodsIcon:setScale(0.2)
  layout:addChild(goodsIcon, 5)
  return layout
end
function ActivitySkinCarnivalChallengeView:CreateUnfinishedCell(cellData)
  local viewData = self:GetViewData()
  local layout = CLayout:create()
  local size = cc.size(viewData.challengeListSize.width, 85)
  layout:setContentSize(size)
  local bg = display.newImageView(RES_DICT.CELL_BG_UNFINISHED, size.width / 2, size.height / 2)
  layout:addChild(bg, 1)
  local discountBg = display.newImageView(RES_DICT.CELL_DISCOUNT_BG, 15, size.height / 2, {
    ap = display.LEFT_CENTER,
    size = cc.size(125, 50),
    scale9 = true
  })
  discountBg:setCascadeOpacityEnabled(true)
  layout:addChild(discountBg, 3)
  local discountLabel = display.newLabel(discountBg:getContentSize().width / 2 - 4, discountBg:getContentSize().height / 2, {
    text = string.fmt(__("_num_\230\138\152"), {
      _num_ = CommonUtils.GetDiscountOffFromCN(cellData.displayDiscount)
    }),
    fontSize = 22,
    color = "#FFEF82",
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "#573012",
    outlineSize = 2
  })
  discountBg:addChild(discountLabel, 1)
  local conditionLabel = display.newLabel(150, size.height / 2, {
    text = cellData.condition,
    w = 300,
    hAlign = display.TAL,
    fontSize = 20,
    color = "#76553b",
    ap = display.LEFT_CENTER
  })
  layout:addChild(conditionLabel, 5)
  local buyBtn = display.newButton(size.width - 120, size.height / 2, {
    n = RES_DICT.COMMON_BTN_ORANGE_D
  })
  buyBtn:setEnabled(false)
  layout:addChild(buyBtn, 1)
  local priceLabel = cc.Label:createWithBMFont("font/small/common_text_num.fnt", cellData.price)
  priceLabel:setAnchorPoint(display.RIGHT_CENTER)
  priceLabel:setHorizontalAlignment(display.TAR)
  priceLabel:setPosition(size.width - 110, size.height / 2)
  layout:addChild(priceLabel, 5)
  local goodsIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(cellData.currency), size.width - 90, size.height / 2)
  goodsIcon:setScale(0.2)
  layout:addChild(goodsIcon, 5)
  return layout
end
function ActivitySkinCarnivalChallengeView:RefreshEnemy(enemies)
  local viewData = self:GetViewData()
  viewData.enemyLayout:removeAllChildren()
  local battlePoint = 0
  for i, v in ipairs(checktable(enemies)) do
    do
      local cardHeadNode = require("common.CardHeadNode").new({
        cardData = v,
        showBaseState = true,
        showActionState = false,
        showVigourState = false
      })
      cardHeadNode:setScale(0.5)
      cardHeadNode:setPosition(cc.p(-20 + 108 * i, viewData.enemyLayout:getContentSize().height / 2))
      cardHeadNode:setOnClickScriptHandler(function()
        PlayUIEffects(AUDIOS.UI.ui_click_normal.id)
        local playerCardDetailData = {
          cardData = {
            breakLevel = v.breakLevel,
            cardId = v.cardId,
            favorLevel = v.favorabilityLevel,
            level = v.level,
            skinId = v.defaultSkinId,
            artifactTalent = v.artifactTalent,
            isArtifactUnlock = v.isArtifactUnlock
          },
          petsData = v.pets,
          viewType = 1
        }
        local playerCardDetailView = require("Game.views.raid.PlayerCardDetailView").new(playerCardDetailData)
        playerCardDetailView:setTag(2222)
        display.commonUIParams(playerCardDetailView, {
          ap = cc.p(0.5, 0.5),
          po = cc.p(display.cx, display.cy)
        })
        app.uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)
      end)
      viewData.enemyLayout:addChild(cardHeadNode)
      battlePoint = battlePoint + CardUtils.GetCardStaticBattlePointByCardData(v)
      viewData.fightPointLabel:setString(string.fmt(__("\230\136\152\229\138\155\239\188\154_num_"), {_num_ = battlePoint}))
    end
  end
end
function ActivitySkinCarnivalChallengeView:GetViewData()
  return self.viewData
end
return ActivitySkinCarnivalChallengeView
