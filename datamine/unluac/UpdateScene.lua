function compareBigVersion(oldVer, newVer)
  local t1 = string.split(oldVer, ".")
  local t2 = string.split(newVer, ".")
  local targetOldVer = ""
  local targetNewVer = ""
  if #t1 < 2 then
    targetOldVer = table.concat({
      t1[1],
      0
    }, ".")
  else
    targetOldVer = table.concat({
      t1[1],
      t1[2]
    }, ".")
  end
  if #t2 < 2 then
    targetNewVer = table.concat({
      t2[1],
      0
    }, ".")
  else
    targetNewVer = table.concat({
      t2[1],
      t2[2]
    }, ".")
  end
  return compareVersion(targetOldVer, targetNewVer)
end
function compareVersion(ov, nv)
  local t1 = string.split(ov, ".")
  local t2 = string.split(nv, ".")
  local len1 = #t1
  local len2 = #t2
  local result = 0
  local len = len1
  if len1 < len2 then
    len = len2
  end
  for i = 1, len do
    local a, b = 0, 0
    if i <= len1 then
      a = tonumber(t1[i], 10)
    end
    if i <= len2 then
      b = tonumber(t2[i], 10)
    end
    if a > b then
      result = 1
      break
    elseif a < b then
      result = -1
      break
    end
  end
  return result
end
local updater = require("update.updater")
local sharedDirector = cc.Director:getInstance()
local tabletourlencode = function(t)
  local args = {}
  local i = 1
  for key, value in pairs(t) do
    args[i] = string.urlencode(key) .. "=" .. string.urlencode(value)
    i = i + 1
  end
  return table.concat(args, "&")
end
local PROGRESS_TIMER_BAR = 1
local PROGRESS_TIMER_RADIAL = 0
local us = class("UpdateScene", function()
  local ret = CLayout:create(display.size)
  ret.name = "UpdateScene"
  return ret
end)
local getFileName = function(name)
  if string.find(name, ".ccz") then
    return name
  else
    local fname = FTUtils:deletePathExtension(name)
    if FTUtils:isPathExistent(string.format("%s.png", fname)) then
      return string.format("%s.png", fname)
    elseif FTUtils:isPathExistent(string.format("%s.pvr.ccz", fname)) then
      return string.format("%s.pvr.ccz", fname)
    elseif FTUtils:isPathExistent(string.format("%s.jpg", fname)) then
      return string.format("%s.jpg", fname)
    end
  end
end
local DICT = {
  BG = checktable(HOME_THEME_STYLE_DEFINE).LOGIN_BG or "update/update_bg.png",
  BTN_NORMAL = "update/common_btn_orange.png",
  BTN_PRESS = "update/common_btn_orange_disable.png",
  Progress_Bg = "update/update_bg_loading.png",
  Progress_Image = "update/update_ico_loading.png",
  Progress_Top = "update/update_ico_loading_fornt.png",
  Progress_Descr = "update/update_bg_refresh_number.png",
  Dialog_Bg = "update/common_bg_2.png"
}
local CreateScrollView = function()
  local view = CLayout:create(display.size)
  view:setName("SCROLL_VIEW")
  local touchLayout = CColorView:create(cc.c4b(0, 0, 0, 0))
  touchLayout:setContentSize(display.size)
  touchLayout:setTouchEnabled(true)
  touchLayout:setPosition(display.center)
  local bg = display.newImageView(_res("update/notice_bg"), 0, 0)
  local cview = CLayout:create(bg:getContentSize())
  cview:setName("CVIEW")
  display.commonUIParams(cview, {
    po = display.center
  })
  view:addChild(cview)
  bg:setPosition(FTUtils:getLocalCenter(cview))
  cview:addChild(bg)
  local button = display.newButton(1100, 624, {
    n = _res("update/notice_btn_quit")
  })
  cview:addChild(button, 2)
  local csize = bg:getContentSize()
  local titleImage = display.newImageView(_res("update/notice_title_bg"), csize.width * 0.5, 616)
  cview:addChild(titleImage, 3)
  local loadingTipsLabel = display.newLabel(csize.width * 0.5, 615, {
    text = __("\230\184\184\230\136\143\229\133\172\229\145\138"),
    fontSize = 28,
    color = "ffdf89",
    hAlign = display.TAC,
    ttf = true,
    font = TTF_GAME_FONT,
    outline = "5d3c25",
    outlineSize = 1
  })
  cview:addChild(loadingTipsLabel)
  if device.platform == "ios" or device.platform == "android" then
    local _webView = ccexp.WebView:create()
    _webView:setAnchorPoint(cc.p(0.5, 0))
    _webView:setPosition(csize.width * 0.5, 44)
    _webView:setContentSize(cc.size(1014, 536))
    _webView:setTag(2345)
    _webView:setScalesPageToFit(true)
    _webView:setOnShouldStartLoading(function(sender, url)
      if string.find(url, "publicNotice.html") then
        return true
      else
        FTUtils:openUrl(url)
        return false
      end
    end)
    _webView:setOnDidFinishLoading(function(sender, url)
      cclog("onWebViewDidFinishLoading, url is ", url)
    end)
    _webView:setOnDidFailLoading(function(sender, url)
      cclog("onWebViewDidFinishLoading, url is ", url)
    end)
    _webView:setName("WEBVIEW")
    cview:addChild(_webView, 2)
    if not tolua.isnull(_webView) then
      local originalURL = string.format("http://notice-%s/publicNotice.html?timestamp=%s&channelId=%d&lang=%s&host=%s", NOTICE_HOST, tostring(os.time()), checkint(Platform.id), i18n.getLang(), Platform.serverHost)
      _webView:loadURL(originalURL)
    end
    return {
      view = view,
      button = button,
      _webView = _webView
    }
  else
    return {view = view, button = button}
  end
end
local isElexSdk = function()
  local platformId = checkint(Platform.id)
  local isQuick = false
  if platformId == ElexIos or platformId == ElexAndroid or platformId == ElexAmazon or platformId == ElexThirdPay then
    isQuick = true
  end
  return isQuick
end
local isRecorded = false
local function appFlyerEventTrack(event_name, params)
  if isElexSdk() then
    local t = {}
    for name, val in pairs(params) do
      table.insert(t, {id = name, value = val})
    end
    if device.platform == "ios" then
      local text = json.encode(t)
      if text then
        luaoc.callStaticMethod("AppFlyerHelper", "trackEvent", {event = event_name, values = text})
      end
    elseif device.platform == "android" then
      local text = json.encode(t)
      if text then
        luaj.callStaticMethod("com.duobaogame.summer.AppFlyerHelper", "trackEvent", {event_name, text})
      end
    end
  end
end
function us:ctor(...)
  self.ipHostPair = {}
  self.ipAddresses = {}
  self.startIndex = 1
  self.tryNum = 1
  self.userUpdateIps = {}
  self.traceHost = true
  self.downloadNo = 1
  local function _sceneHandler(event)
    if event == "enter" then
      self:onEnter()
    elseif event == "cleanup" then
      self:onCleanup()
    elseif event == "exit" then
      self:onExit()
      if DEBUG_MEM then
        print("----------------------------------------")
        print(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
        cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
        print("----------------------------------------")
      end
    end
  end
  self:registerScriptHandler(_sceneHandler)
  local CreateSlashView = function()
    local view = CLayout:create(display.size)
    view:setBackgroundColor(cc.c4b(255, 255, 255, 255))
    local logoImage = display.newImageView(_res("update/splash_ico_funtoy"))
    display.commonUIParams(logoImage, {
      po = cc.p(display.cx, display.cy + 20)
    })
    view:addChild(logoImage)
    return {view = view}
  end
  local function CreateView()
    local __bg = display.newImageView(getFileName(DICT.BG))
    display.commonUIParams(__bg, {
      ap = display.CENTER,
      po = cc.p(display.cx, display.cy)
    })
    self:addChild(__bg)
    local logoAnimate = sp.SkeletonAnimation:create("update/logo.json", "update/logo.atlas", 0.92)
    logoAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 470))
    logoAnimate:setToSetupPose()
    logoAnimate:update(0)
    logoAnimate:setAnimation(0, "logo", false)
    __bg:addChild(logoAnimate)
    logoAnimate:registerSpineEventHandler(function(event)
      if event.animation == "logo" then
        logoAnimate:setAnimation(0, "xunhuan", true)
      end
    end, sp.EventType.ANIMATION_COMPLETE)
    local roleAnimate = sp.SkeletonAnimation:create("update/mifan.json", "update/mifan.atlas", 0.92)
    roleAnimate:setPosition(cc.p(__bg:getContentSize().width * 0.5, __bg:getContentSize().height - 502))
    roleAnimate:setToSetupPose()
    roleAnimate:update(0)
    roleAnimate:setAnimation(0, "idle", true)
    __bg:addChild(roleAnimate)
    local packageVersion = FTUtils:getAppVersion()
    local version = display.newLabel(display.SAFE_L + 10, 40, {
      ap = cc.p(0, 0),
      fontSize = 18,
      color = "ffffff",
      text = "V" .. tostring(packageVersion)
    })
    self:addChild(version)
    local lversion = display.newLabel(display.SAFE_L + 6, 22, {
      ap = cc.p(0, 0),
      fontSize = 18,
      color = "ffffff"
    })
    lversion:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
    lversion:setTag(43333)
    self:addChild(lversion, 2)
    local rversion = display.newLabel(display.SAFE_L + 6, 4, {
      ap = cc.p(0, 0),
      fontSize = 18,
      color = "ffffff"
    })
    rversion:setAlignment(cc.TEXT_ALIGNMENT_LEFT)
    rversion:setTag(43334)
    self:addChild(rversion, 2)
    local colorView = CColorView:create(cc.c4b(100, 100, 100, 0))
    colorView:setAnchorPoint(display.CENTER_BOTTOM)
    colorView:setPosition(cc.p(display.cx, 0))
    colorView:setContentSize(cc.size(display.width, 100))
    self:addChild(colorView, 4)
    local loadingBarBg = display.newImageView(_res("update/update_bg_black.png"), 0, 0, {
      scale9 = true,
      size = cc.size(display.width, 209)
    })
    display.commonUIParams(loadingBarBg, {
      po = cc.p(display.cx, 0),
      ap = cc.p(0.5, 0)
    })
    colorView:addChild(loadingBarBg)
    local loadingBar = CProgressBar:create(_res(DICT.Progress_Image))
    loadingBar:setBackgroundImage(_res(DICT.Progress_Bg))
    loadingBar:setDirection(0)
    loadingBar:setMaxValue(100)
    loadingBar:setValue(0)
    loadingBar:setPosition(cc.p(display.cx, 105))
    colorView:addChild(loadingBar, 1)
    local loadingBarShine = display.newNSprite(_res("update/update_ico_light.png"), 0, loadingBar:getPositionY())
    colorView:addChild(loadingBarShine, 2)
    local percent = loadingBar:getValue() / loadingBar:getMaxValue()
    loadingBarShine:setPositionX(loadingBar:getPositionX() - loadingBar:getContentSize().width * 0.5 + loadingBar:getContentSize().width * percent - 1)
    local loadingTipsBg = display.newImageView(_res("update/loading_bg_tips.png"))
    display.commonUIParams(loadingTipsBg, {
      ap = cc.p(0.5, 1),
      po = cc.p(loadingBar:getPositionX(), loadingBar:getPositionY() - loadingBar:getContentSize().height * 0.5 - 3)
    })
    colorView:addChild(loadingTipsBg, 1)
    local padding = cc.p(20, 7)
    local loadingTipsLabel = display.newLabel(padding.x, loadingTipsBg:getContentSize().height - padding.y, {
      text = "",
      fontSize = 20,
      color = "ffffff",
      ap = cc.p(0, 1),
      hAlign = display.TAC,
      ttf = true,
      font = TTF_GAME_FONT,
      w = loadingTipsBg:getContentSize().width - padding.x * 2,
      h = loadingTipsBg:getContentSize().height - padding.y * 2
    })
    loadingTipsBg:addChild(loadingTipsLabel)
    local padding = cc.p(colorView:getContentSize().width * 0.5, 7)
    local progressTipsLabel = display.newLabel(padding.x, padding.y, {
      text = "",
      fontSize = 20,
      color = "ffffff",
      ap = cc.p(0.5, 0),
      hAlign = display.TAC,
      ttf = true,
      font = TTF_GAME_FONT,
      w = loadingTipsBg:getContentSize().width - padding.x * 2,
      h = loadingTipsBg:getContentSize().height - padding.y * 2
    })
    colorView:addChild(progressTipsLabel, 2)
    local avatarAnimationName = "loading_avatar"
    local animation = cc.AnimationCache:getInstance():getAnimation(avatarAnimationName)
    if nil == animation then
      animation = cc.Animation:create()
      for i = 1, 10 do
        animation:addSpriteFrameWithFile(_res(string.format("update/loading_run_%d.png", i)))
      end
      animation:setDelayPerUnit(0.05)
      animation:setRestoreOriginalFrame(true)
      cc.AnimationCache:getInstance():addAnimation(animation, avatarAnimationName)
    end
    local loadingAvatar = display.newNSprite(_res("update/loading_run_1.png"), 0, 0)
    loadingAvatar:setPositionY(loadingBar:getPositionY() + loadingBar:getContentSize().height * 0.5 + loadingAvatar:getContentSize().width * 0.5 + 10)
    colorView:addChild(loadingAvatar, 5)
    loadingAvatar:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))
    local loadingLabelBg = display.newImageView(_res("update/bosspokedex_name_bg.png"))
    loadingLabelBg:setPositionY(loadingAvatar:getPositionY() - 8)
    colorView:addChild(loadingLabelBg, 4)
    local loadingLabel = display.newLabel(utils.getLocalCenter(loadingLabelBg).x - 20, utils.getLocalCenter(loadingLabelBg).y - 2, {
      text = __("\230\173\163\229\156\168\232\189\189\229\133\165"),
      ttf = true,
      font = TTF_GAME_FONT,
      fontSize = 24,
      color = "#ffffff"
    })
    loadingLabel:enableOutline(ccc4FromInt("290c0c"), 1)
    loadingLabelBg:addChild(loadingLabel)
    local offsetX = -25
    local totalWidth = loadingAvatar:getContentSize().width + loadingLabelBg:getContentSize().width + offsetX
    local baseX = display.cx
    local loadingAvatarX = baseX - totalWidth * 0.5 + loadingAvatar:getContentSize().width * 0.5
    local loadingLabelBgX = loadingAvatarX + loadingAvatar:getContentSize().width * 0.5 + offsetX + loadingLabelBg:getContentSize().width * 0.5
    loadingAvatar:setPositionX(loadingAvatarX)
    loadingLabelBg:setPositionX(loadingLabelBgX)
    return {
      bigVersion = packageVersion,
      lversionLabel = lversion,
      versionLabel = rversion,
      colorView = colorView,
      loadingBar = loadingBar,
      loadingBarShine = loadingBarShine,
      loadingTipsLabel = loadingTipsLabel,
      progressTipsLabel = progressTipsLabel
    }
  end
  self.viewData = CreateView()
  self.viewData.colorView:setVisible(false)
  local function updateRequest()
    if package.loaded["root.AppSDK"] then
      self:_checkUpdate()
    elseif SHOW_LAUNCH_LOGO then
      local slashViewData = CreateSlashView()
      display.commonUIParams(slashViewData.view, {
        po = display.center
      })
      self:addChild(slashViewData.view, 60)
      self:runAction(cc.Sequence:create(cc.DelayTime:create(SHOW_LOGO_TIME), cc.TargetedAction:create(slashViewData.view, cc.FadeOut:create(1)), cc.TargetedAction:create(slashViewData.view, cc.RemoveSelf:create()), cc.CallFunc:create(function()
        self:_checkUpdate()
      end)))
    else
      self:_checkUpdate()
    end
  end
  local function updateLogical()
    if SHOW_LOGIN_NOTICE and not package.loaded["root.AppSDK"] then
      local key = string.format("isShowAnnouncement_%s", os.date("%Y-%m-%d"))
      if cc.UserDefault:getInstance():getBoolForKey(key) == false then
        if SHOW_LAUNCH_LOGO then
          local slashViewData = CreateSlashView()
          display.commonUIParams(slashViewData.view, {
            po = display.center
          })
          self:addChild(slashViewData.view, 60)
          self:runAction(cc.Sequence:create(cc.DelayTime:create(3), cc.TargetedAction:create(slashViewData.view, cc.FadeOut:create(1)), cc.TargetedAction:create(slashViewData.view, cc.RemoveSelf:create()), cc.CallFunc:create(function()
            local viewData = CreateScrollView()
            display.commonUIParams(viewData.button, {
              cb = function(sender)
                sender:setEnabled(false)
                viewData.view:setVisible(false)
                if device.platform == "ios" or device.platform == "android" then
                  viewData._webView:setVisible(false)
                end
                self:_checkUpdate()
              end
            })
            display.commonUIParams(viewData.view, {
              po = display.center
            })
            self:addChild(viewData.view, 20)
          end)))
        else
          do
            local viewData = CreateScrollView()
            display.commonUIParams(viewData.button, {
              cb = function(sender)
                sender:setEnabled(false)
                viewData.view:setVisible(false)
                if device.platform == "ios" or device.platform == "android" then
                  viewData._webView:setVisible(false)
                end
                self:_checkUpdate()
              end
            })
            display.commonUIParams(viewData.view, {
              po = display.center
            })
            self:addChild(viewData.view, 20)
          end
        end
      else
        updateRequest()
      end
    else
      updateRequest()
    end
  end
  updateLogical()
end
local function CreateTipsWindow(downsize)
  local size = cc.size(742, 640)
  local view = CLayout:create(size)
  local __bg = display.newImageView(getFileName(DICT.Dialog_Bg), 0, 0, {scale9 = true, size = size})
  display.commonUIParams(__bg, {
    po = FTUtils:getLocalCenter(view)
  })
  view:addChild(__bg)
  local titleLabel = display.newButton(size.width * 0.5, size.height - 22, {
    n = _res("update/common_bg_title_2")
  })
  display.commonLabelParams(titleLabel, {
    text = __("\230\155\180\230\150\176\229\133\172\229\145\138"),
    fontSize = 24,
    color = "ffffff",
    ttf = true,
    font = TTF_GAME_FONT
  })
  titleLabel:setEnabled(false)
  view:addChild(titleLabel, 2)
  local bg = display.newImageView(_res("update/commcon_bg_text"), size.width * 0.5, 370, {
    scale9 = true,
    size = cc.size(682, 436)
  })
  view:addChild(bg)
  local remoteInfo = updater.getRemotePackageInfo()
  local localResInfo = updater.getLocalResInfo()
  local title = remoteInfo.title or ""
  local __titleLabel = display.newLabel(size.width * 0.5, size.height - 78, {
    text = title,
    fontSize = 26,
    color = "5c5c5c",
    ttf = true,
    font = TTF_GAME_FONT
  })
  view:addChild(__titleLabel, 2)
  local scrollView = cc.ScrollView:create()
  scrollView:setViewSize(cc.size(600, 380))
  scrollView:setDirection(2)
  scrollView:setBounceable(false)
  scrollView:setAnchorPoint(cc.p(0, 0))
  scrollView:setPosition(cc.p(80, 150))
  view:addChild(scrollView)
  local msgLabel = cc.Label:create()
  msgLabel:setLineBreakWithoutSpace(true)
  msgLabel:setSystemFontSize(24)
  msgLabel:setWidth(600)
  msgLabel:setColor(cc.c3b(100, 100, 100))
  msgLabel:setAnchorPoint(cc.p(0, 0))
  scrollView:setContainer(msgLabel)
  local __descrLabel = display.newLabel(size.width * 0.5, 130, {
    ap = cc.p(0.5, 1),
    color = "6c6c6c",
    fontSize = 20,
    text = "",
    w = 600,
    h = 100,
    ttf = true,
    font = TTF_GAME_FONT
  })
  __descrLabel:setLineBreakWithoutSpace(true)
  __descrLabel:setTag(334)
  view:addChild(__descrLabel, 2)
  local viewData = {
    view = view,
    scrollView = scrollView,
    contentView = msgLabel,
    __descrLabel = __descrLabel
  }
  if localResInfo and remoteInfo and type(remoteInfo) == "table" and remoteInfo.version then
    if remoteInfo.isMaintain and remoteInfo.isMaintain == true then
      __descrLabel:setString(__("\229\189\147\229\137\141\230\156\141\229\138\161\229\153\168\230\173\163\229\156\168\231\187\180\230\138\164\228\184\173\239\188\140\231\168\141\229\144\142\230\137\141\232\131\189\230\132\137\229\191\171\231\154\132\231\142\169\232\128\141\229\147\159~~"))
    elseif compareBigVersion(FTUtils:getAppVersion(), remoteInfo.appVersion) == -1 then
      __descrLabel:setString(__("\229\189\147\229\137\141\231\137\136\230\156\172\232\191\135\228\189\142\239\188\140\228\184\141\232\131\189\229\134\141\230\132\137\229\191\171\231\154\132\231\142\169\232\128\141\228\186\134\239\188\140\229\137\141\229\142\187\228\184\139\232\189\189\230\150\176\231\137\136\230\156\172\229\144\167"))
      local __gotoDownBtn = display.newButton(0, 0, {
        n = getFileName(DICT.BTN_NORMAL),
        s = getFileName(DICT.BTN_PRESS),
        cb = function(sender)
          FTUtils:openUrl(remoteInfo.forceUpdateURL)
        end
      })
      display.commonLabelParams(__gotoDownBtn, {
        fontSize = 26,
        color = "4c4c4c",
        text = __("\229\137\141 \229\190\128"),
        ttf = true,
        font = TTF_GAME_FONT
      })
      display.commonUIParams(__gotoDownBtn, {
        po = cc.p(size.width * 0.5, 50)
      })
      view:addChild(__gotoDownBtn, 2)
    else
      local s = ""
      if downsize <= 102400 then
        s = string.fmt(__("_num_\228\187\165\228\184\139"), {_num_ = "100K"})
      elseif downsize > 1048576 then
        s = string.format("%dM", downsize / 1048576)
      else
        s = string.format("%dK", downsize / 1024)
      end
      local desrc = string.format(__("\230\163\128\230\181\139\229\136\176\230\150\176\231\137\136\230\156\172\230\173\164\230\172\161\230\155\180\230\150\176\229\140\133\229\164\167\229\176\143\228\184\186%s\239\188\140\232\175\183\229\156\168\232\137\175\229\165\189\231\189\145\231\187\156\228\184\139\232\191\155\232\161\140\230\155\180\230\150\176~~"), s)
      __descrLabel:setString(desrc)
      local __gotoDownBtn = display.newButton(0, 0, {
        n = getFileName(DICT.BTN_NORMAL),
        s = getFileName(DICT.BTN_PRESS)
      })
      display.commonUIParams(__gotoDownBtn, {
        po = cc.p(checkint(size.width * 0.5), 50)
      })
      display.commonLabelParams(__gotoDownBtn, {
        fontSize = 26,
        color = "4c4c4c",
        text = __("\231\161\174 \229\174\154"),
        ttf = true,
        font = TTF_GAME_FONT
      })
      view:addChild(__gotoDownBtn, 2)
      viewData.startDownButton = __gotoDownBtn
    end
    local introText = viewData.contentView
    introText:setString(remoteInfo.updateContent or "")
    local scrollView = viewData.scrollView
    local scrollTop = scrollView:getViewSize().height - scrollView:getContainer():getContentSize().height
    scrollView:setContentOffset(cc.p(0, scrollTop))
  end
  return viewData
end
local split = function(input, delimiter)
  input = tostring(input)
  delimiter = tostring(delimiter)
  if delimiter == "" then
    return false
  end
  local pos = 0
  local arr = {}
  for st, sp in function()
    return string.find(input, delimiter, pos, false)
  end, nil, nil do
    table.insert(arr, string.sub(input, pos, st - 1))
    pos = sp + 1
  end
  table.insert(arr, string.sub(input, pos))
  return arr
end
function startParseIp(hosts, cb)
  local ipHostPair = {}
  local ipAddr = {}
  if type(hosts) == "table" and #hosts > 0 then
    local tdomains = {}
    for index, val in pairs(hosts) do
      table.insert(tdomains, {domain = val, cname = true})
    end
    local dd = {
      appId = "6416",
      appKey = "OBcwkefk",
      domains = tdomains
    }
    local jsonStr = json.encode(dd)
    if jsonStr then
      local function parseCallback(event)
        if event.event == "state" then
          local t = event.ips
          local tt = json.decode(t)
          for name, host in pairs(hosts) do
            if checktable(tt)[host] then
              for idx, ip in ipairs(tt[host]) do
                table.insert(ipAddr, ip)
                ipHostPair[tostring(ip)] = host
              end
            else
              table.insert(ipAddr, host)
              ipHostPair[tostring(host)] = host
            end
          end
          if cb and type(cb) == "function" then
            cb(ipAddr, ipHostPair)
          end
        elseif event.event == "error" then
          showAlert(__("\232\173\166\229\145\138"), __("\228\188\160\229\133\165\231\154\132\229\159\159\229\144\141\228\191\161\230\129\175\228\184\141\232\131\189\228\184\186\231\169\186"), __("\231\161\174\229\174\154"))
        end
      end
      updater.parseDomains(jsonStr, parseCallback)
    else
      for name, host in pairs(hosts) do
        table.insert(ipAddr, host)
        ipHostPair[tostring(host)] = host
      end
      if cb and type(cb) == "function" then
        cb(ipAddr, ipHostPair)
      end
    end
  end
end
function us:startUpdateRequest()
  local remoteResourcesInfo = updater.getRemotePackageInfo()
  local zipInfoUrl = remoteResourcesInfo.patchBaseURL
  local URL = require("cocos.cocos2d.URL")
  local t = URL.parse(zipInfoUrl)
  local lhost = t.host
  local hosts = {lhost}
  if remoteResourcesInfo.backupPatchBaseURL and string.find(remoteResourcesInfo.backupPatchBaseURL, "http") then
    local n = URL.parse(remoteResourcesInfo.backupPatchBaseURL)
    table.insert(hosts, n.host)
  end
  self.ipAddresses = hosts
  appFlyerEventTrack("DownloadStart", {
    af_event_start = "downloadStart"
  })
  self:startDownloadZIP()
end
function us:startDownloadZIP()
  local targetHost = self.ipAddresses[self.startIndex]
  if targetHost then
    updater.update(handler(self, self._updateHandler), targetHost, targetHost)
  else
    device.showAlert(__("\232\173\166\229\145\138"), __("\229\189\147\229\137\141\231\189\145\231\187\156\228\184\141\229\143\175\231\148\168\239\188\140\228\184\141\232\131\189\232\191\155\229\133\165\230\184\184\230\136\143~~"), __("\231\161\174\229\174\154"))
  end
end
function us:Traceroot(host)
  local SDK_CLASS_NAME = "TracerootSDK"
  local app = cc.Application:getInstance()
  local target = app:getTargetPlatform()
  if target == 3 then
    SDK_CLASS_NAME = "com.duobaogame.summer.TracerootSDK"
  end
  if target ~= 0 then
    if target == 2 or target == 4 or target == 5 then
      LuaObjcBridge.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {
        listener = handler(self, self.UploadExceptionLog)
      })
      LuaObjcBridge.callStaticMethod(SDK_CLASS_NAME, "traceroot", {host = host})
    elseif target == 3 then
      LuaJavaBridge.callStaticMethod(SDK_CLASS_NAME, "addScriptListener", {TraceInvoke}, "(I)V")
      LuaJavaBridge.callStaticMethod(SDK_CLASS_NAME, "traceroot", {host}, "(Ljava/lang/String;)V")
    end
  end
end
function us:UploadExceptionLog()
  local fileUtils = cc.FileUtils:getInstance()
  local filePath = fileUtils:getWritablePath() .. "log/trace.log"
  if fileUtils:isFileExist(filePath) then
    local content = FTUtils:getFileDataWithoutDec(filePath)
    content = content and CCCrypto:encodeBase64Lua(content, string.len(content))
    if content then
      do
        local updateURL = table.concat({
          "http://",
          Platform.ip,
          "/User/exceptionLog"
        }, "")
        if USE_SSL then
          updateURL = table.concat({
            "https://",
            Platform.ip,
            "/User/exceptionLog"
          }, "")
        end
        local baseversion = FTUtils:getAppVersion()
        local t = FTUtils:getCommParamters({
          channelId = Platform.id,
          appVersion = baseversion
        })
        t.exceptionLog = content
        if DEBUG > 0 then
          dump(t)
        end
        local zlib = require("zlib")
        local tData = json.encode(t)
        local compressed = zlib.deflate(5, 31)(tData, "finish")
        local ret = tabletourlencode(t)
        local xhr = cc.XMLHttpRequest:new()
        xhr.responseType = 4
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        xhr:setRequestHeader("User-Agent", table.concat({
          CCNative:getOpenUDID(),
          baseversion,
          CCNative:getDeviceName(),
          target
        }, ";"))
        xhr:setRequestHeader("Content-Type", "application/json")
        xhr.timeout = 60
        xhr:open("POST", updateURL)
        xhr:registerScriptHandler(function()
          if xhr.readyState == 4 and xhr.status >= 200 and xhr.status < 207 then
            FTUtils:deleteFile(filePath)
          end
        end)
        xhr:send(compressed)
      end
    end
  end
end
function us:createRetryView(text, isCheckUpdate)
  local view = self:getChildByName("RetryDownloader")
  if not view then
    local size = cc.size(592, 512)
    view = CLayout:create(size)
    display.commonUIParams(view, {
      po = display.center
    })
    view:setName("RetryDownloader")
    local bg = display.newImageView(_res("update/common_bg_2"), 296, 256)
    bg:setScale(0.8)
    view:addChild(bg)
    local descrLabel = display.newLabel(296, 276, {
      fontSize = 26,
      color = "6c6c6c",
      text = tostring(text),
      w = 540
    })
    descrLabel:setName("LABEL")
    view:addChild(descrLabel, 1)
    local okButton = display.newButton(296, 64, {
      n = _res("update/common_btn_orange"),
      s = _res("update/common_btn_orange"),
      cb = function(sender)
        view:setVisible(false)
        self.viewData.loadingTipsLabel:setString(__("\229\188\128\229\167\139\230\163\128\230\181\139\230\155\180\230\150\176\228\184\173\239\188\140\232\175\183\231\168\141\229\144\142..."))
        self:UpdateRequest()
      end
    })
    display.commonLabelParams(okButton, {
      fontSize = 28,
      text = __("\233\135\141\232\175\149"),
      color = "4c4c4c"
    })
    view:addChild(okButton, 2)
    self:addChild(view, 100)
  end
  view:setVisible(true)
end
function us:UpdateRequest()
  local serverIp = Platform.serverHost
  local lresinfo = updater.getLocalResInfo()
  local ipLen = #self.userUpdateIps
  if ipLen > 0 then
    serverIp = self.userUpdateIps[self.tryNum]
    Platform.ip = serverIp
  else
    Platform.ip = serverIp
  end
  local updateURL = table.concat({
    "http://",
    serverIp,
    "/User/update/t/",
    os.time()
  }, "")
  if USE_SSL and not FOR_REVIEW then
    updateURL = table.concat({
      "https://",
      serverIp,
      "/User/update/t/",
      os.time()
    }, "")
  end
  funLog(Logger.DEBUG, "updateURL " .. updateURL)
  local cversion = lresinfo.version
  local baseversion = FTUtils:getAppVersion()
  local t = FTUtils:getCommParamters({
    channelId = Platform.id,
    version = cversion,
    appVersion = baseversion,
    lang = i18n.getLang()
  })
  if 0 < DEBUG then
    dump(t)
  end
  if not EVENTLOG then
    EVENTLOG = require("root.EventLog")
  end
  local ret = tabletourlencode(t)
  local xhr = cc.XMLHttpRequest:new()
  xhr.responseType = 0
  local app = cc.Application:getInstance()
  local target = app:getTargetPlatform()
  xhr:setRequestHeader("User-Agent", table.concat({
    CCNative:getOpenUDID(),
    baseversion,
    CCNative:getDeviceName(),
    target
  }, ";"))
  xhr.timeout = 8
  xhr:open("POST", updateURL)
  xhr:registerScriptHandler(function()
    if xhr.readyState == 4 and xhr.status >= 200 and xhr.status < 207 then
      local responseStr = xhr.response
      local reslua = json.decode(responseStr)
      if reslua then
        if checkint(reslua.errcode) == 0 and reslua.data and reslua.data.version and 0 < string.len(reslua.data.version) then
          self:promoteDownload(reslua.data)
        else
          EVENTLOG.Log(EVENTLOG.EVENTS.update, {
            action = "userUpdate",
            errmsg = tostring(responseStr),
            status = tostring(xhr.status),
            readyState = tostring(xhr.readyState)
          })
          self:createRetryView(string.fmt(__("\230\163\128\230\181\139\230\155\180\230\150\176\232\191\148\229\155\158\230\149\176\230\141\174\230\160\188\229\188\143\228\184\141\230\173\163\231\161\174_error_~~server"), {
            _error_ = string.urldecode(responseStr)
          }))
          self.viewData.loadingTipsLabel:setString(string.fmt(__("\230\163\128\230\181\139\230\155\180\230\150\176\232\191\148\229\155\158\230\149\176\230\141\174\230\160\188\229\188\143\228\184\141\230\173\163\231\161\174_error_~~"), {
            _error_ = string.urldecode(responseStr)
          }))
        end
      else
        EVENTLOG.Log(EVENTLOG.EVENTS.update, {
          action = "userUpdate",
          errmsg = tostring(responseStr),
          status = tostring(xhr.status),
          readyState = tostring(xhr.readyState)
        })
        self:createRetryView(string.fmt(__("\230\163\128\230\181\139\230\155\180\230\150\176\232\191\148\229\155\158\230\149\176\230\141\174\230\160\188\229\188\143\228\184\141\230\173\163\231\161\174_error_~~data"), {
          _error_ = string.urldecode(responseStr)
        }))
        self.viewData.loadingTipsLabel:setString(string.fmt(__("\230\163\128\230\181\139\230\155\180\230\150\176\232\191\148\229\155\158\230\149\176\230\141\174\230\160\188\229\188\143\228\184\141\230\173\163\231\161\174_error_~~"), {
          _error_ = string.urldecode(responseStr)
        }))
      end
    else
      self.tryNum = self.tryNum + 1
      if self.tryNum > ipLen then
        self.tryNum = 1
        self:createRetryView(__("\229\189\147\229\137\141\231\189\145\231\187\156\228\184\141\229\143\175\231\148\168\239\188\140\228\184\141\232\131\189\232\191\155\229\133\165\230\184\184\230\136\143~~") .. tostring(xhr.status))
        EVENTLOG.Log(EVENTLOG.EVENTS.update, {
          action = "userUpdate",
          status = tostring(xhr.status),
          readyState = tostring(xhr.readyState),
          msg = tostring(xhr.response)
        })
        self.viewData.loadingTipsLabel:setString(__("\229\189\147\229\137\141\231\189\145\231\187\156\228\184\141\229\143\175\231\148\168\239\188\140\228\184\141\232\131\189\232\191\155\229\133\165\230\184\184\230\136\143~~"))
      else
        self:UpdateRequest()
      end
    end
  end)
  xhr:send(ret)
end
function us:_checkUpdate()
  self.viewData.colorView:setVisible(true)
  local lresinfo = updater.getLocalResInfo()
  if lresinfo then
    self.viewData.lversionLabel:setString(lresinfo.version)
    self.viewData.loadingTipsLabel:setString(__("\229\188\128\229\167\139\230\163\128\230\181\139\230\155\180\230\150\176\228\184\173\239\188\140\232\175\183\231\168\141\229\144\142..."))
    self.userUpdateIps = {
      Platform.serverHost
    }
    self:UpdateRequest()
  end
  appFlyerEventTrack("CheckUpdate", {
    af_event_start = "checkUpdate"
  })
  self:UploadExceptionLog()
end
function us:promoteDownload(reslua)
  _G.FOR_REVIEW = reslua.isReview
  if reslua.isMaintain and reslua.isMaintain == true then
    self.viewData.colorView:setVisible(false)
    updater.maintainServer(reslua)
    local warningView = CreateTipsWindow()
    display.commonUIParams(warningView.view, {
      po = cc.p(display.width * 0.5, display.height * 0.5)
    })
    self:addChild(warningView.view, 6)
  else
    local result = updater.checkUpdate(reslua)
    local remoteResInfo = updater.getRemotePackageInfo()
    self.viewData.versionLabel:setString(tostring(remoteResInfo.version))
    if result == true then
      do
        local dsize = updater.getNeededDownloadSize()
        if not EVENTLOG then
          EVENTLOG = require("root.EventLog")
        end
        EVENTLOG.Log(EVENTLOG.EVENTS.update, {size = dsize})
        local warningView = CreateTipsWindow(dsize)
        display.commonUIParams(warningView.view, {
          po = cc.p(display.width * 0.5, display.height * 0.5)
        })
        self:addChild(warningView.view, 6)
        if warningView.startDownButton then
          warningView.startDownButton:setOnClickScriptHandler(function(sender)
            sender:setEnabled(false)
            sender:setVisible(false)
            warningView.view:setVisible(false)
            self.viewData.loadingTipsLabel:setString(__("\229\135\134\229\164\135\228\184\139\232\189\189\230\184\184\230\136\143\232\181\132\230\186\144\239\188\140\232\175\183\232\128\144\229\191\131\231\173\137\229\190\133..."))
            self:startUpdateRequest()
          end)
        end
      end
    elseif result == nil then
      self.viewData.loadingTipsLabel:setString(__("\230\163\128\230\181\139\230\155\180\230\150\176\231\137\136\230\156\172\230\175\148\229\175\185\229\164\177\232\180\165~~"))
    elseif result == false then
      self.viewData.loadingTipsLabel:setString(__("\230\163\128\230\181\139\230\184\184\230\136\143\230\155\180\230\150\176\229\174\140\230\136\144"))
      if us._succHandler then
        us._succHandler()
      end
      self.viewData.colorView:setVisible(false)
    end
  end
end
function us:_updateHandler(event)
  local state = event.event
  if state == "success" then
    appFlyerEventTrack("DownloadSuccess", {
      af_event_start = "DownloadSuccess"
    })
    updater.updateFinalResInfo()
    self.viewData.colorView:setVisible(false)
    if us._succHandler then
      us._succHandler()
    end
  elseif state == "progress" then
    local total = tonumber(event.total, 10)
    local progress = tonumber(event.progress, 10)
    if total > 0 then
      self.viewData.loadingBar:setValue(progress / total * 100)
      local str = string.format("%.1f %%", progress / total * 100)
      local percent = progress * 0.01
      self.viewData.loadingBarShine:setPositionX(self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 + self.viewData.loadingBar:getContentSize().width * percent - 1)
      self.viewData.loadingTipsLabel:setString(string.fmt(__("\232\181\132\230\186\144\228\184\139\232\189\189\232\191\155\229\186\166_pro_"), {_pro_ = str}))
      if total > 1024 then
        if progress >= 1024 then
          self.viewData.progressTipsLabel:setString(string.format(__("\230\173\163\229\156\168\228\184\139\232\189\189%sk/%sk"), tostring(math.floor(progress / 1024)), tostring(math.floor(total / 1024))))
        else
          self.viewData.progressTipsLabel:setString(__("\230\173\163\229\156\168\228\184\139\232\189\189100K\228\187\165\228\184\139"))
        end
      end
    end
  elseif event.event == "state" then
    local msg = event.msg
    local stateValue
    if msg == "downloadStart" then
      stateValue = __("\229\188\128\229\167\139\228\184\139\232\189\189\230\155\180\230\150\176...") .. tostring(self.downloadNo)
    elseif msg == "downloadDone" then
      stateValue = __("\230\155\180\230\150\176\229\140\133\228\184\139\232\189\189\229\174\140\230\136\144...")
      EVENTLOG.Log(EVENTLOG.EVENTS.updateSuccessful)
    elseif msg == "uncompressStart" then
      stateValue = __("\229\188\128\229\167\139\232\167\163\229\142\139...")
      self.viewData.loadingBar:setValue(100)
      self.viewData.loadingBarShine:setPositionX(self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 + self.viewData.loadingBar:getContentSize().width - 1)
    elseif msg == "uncompressDone" then
      stateValue = __("\232\167\163\229\142\139\229\174\140\230\136\144...")
    else
      stateValue = tostring(event.msg)
    end
    self.viewData.loadingTipsLabel:setString(tostring(stateValue))
  elseif state == "error" then
    EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed)
    if event.msg then
      local lmsg = tostring(event.msg)
      local clientMsg = ""
      if lmsg == "errorCreateFile" then
        clientMsg = __("\229\136\155\229\187\186\230\150\135\228\187\182\229\164\177\232\180\165")
      elseif lmsg == "errorNetwork" then
        clientMsg = __("\231\189\145\231\187\156\229\135\186\231\142\176\229\188\130\229\184\184")
      elseif lmsg == "errorNetworkUpdateMd5" then
        clientMsg = __("\230\163\128\230\181\139\230\155\180\230\150\176\231\189\145\231\187\156\229\135\186\231\142\176\229\188\130\229\184\184")
      elseif lmsg == "errorCurlInit" then
        clientMsg = __("\230\163\128\230\181\139\230\155\180\230\150\176\229\136\157\229\167\139\229\140\150\229\164\177\232\180\165")
      elseif lmsg == "errorNetworkDownload" then
        clientMsg = __("\228\184\139\232\189\189\230\155\180\230\150\176\229\140\133\231\189\145\231\187\156\229\135\186\231\142\176\229\188\130\229\184\184")
      elseif lmsg == "errorUncompress" then
        clientMsg = __("\230\155\180\230\150\176\229\140\133\232\167\163\229\142\139\229\164\177\232\180\165")
        updater.removePatchZip()
      elseif lmsg == "errorUnknown" then
        clientMsg = __("\230\155\180\230\150\176\229\135\186\231\142\176\230\156\170\231\159\165\233\148\153\232\175\175")
      end
      if event.vividMsg then
        clientMsg = string.format("%s%s", clientMsg, tostring(event.vividMsg))
        wwritefile(clientMsg)
      end
      self.viewData.loadingTipsLabel:setString(clientMsg)
      EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed, {errmsg = clientMsg})
    else
      EVENTLOG.Log(EVENTLOG.EVENTS.updateFailed)
    end
    local curIp = self.ipAddresses[self.startIndex]
    wwritefile(curIp)
    if self.traceHost then
      self:Traceroot(tostring(curIp))
    end
    self.startIndex = self.startIndex + 1
    if checkint(self.startIndex) <= table.nums(self.ipAddresses) then
      self:startDownloadZIP()
    else
      self.traceHost = false
      self.startIndex = 1
      self.downloadNo = self.downloadNo + 1
      self:startDownloadZIP()
    end
  end
end
function us.addListener(handler)
  us._succHandler = handler
  return us
end
function us:onEnter()
  if KEYBOARD_LOGIN_NOTICE then
    local layer = cc.Layer:create()
    layer:setKeyboardEnabled(true)
    layer:setName("NOTICE_VIEW")
    self:addChild(layer, -100)
    local target = cc.Application:getInstance():getTargetPlatform()
    if target >= 2 and target < 6 then
      layer:registerScriptKeypadHandler(handler(self, self.KeyboardEvent))
    end
  end
end
function us:KeyboardEvent(callback)
  if callback ~= "menuClicked" then
    local view = self:getChildByName("SCROLL_VIEW")
    local layer = self:getChildByName("NOTICE_VIEW")
    if layer then
      layer:unregisterScriptKeypadHandler()
    end
    if view:isVisible() then
      view:setVisible(false)
      if device.platform == "ios" or device.platform == "android" then
        local cview = view:getChildByName("CVIEW")
        if cview then
          local webView = cview:getChildByName("WEBVIEW")
          webView:setVisible(false)
        end
      end
      self:_checkUpdate()
    end
  end
end
function us:onExit()
  local layer = self:getChildByName("NOTICE_VIEW")
  if layer then
    layer:unregisterScriptKeypadHandler()
  end
end
function us:onCleanup()
  updater.clean()
  cc.Director:getInstance():getTextureCache():removeUnusedTextures()
  self:unregisterScriptHandler()
end
return us
