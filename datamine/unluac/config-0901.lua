DEBUG = 0
CC_USE_FRAMEWORK = true
CC_LOAD_DEPRECATED_API = false
DEBUG_MEM = true
NETWORK_LOCAL = false
SS_SHOW_INVITECODE = false
USE_SSL = false
HTTP_USE_SSL = false
SHOW_LOGO_TIME = 1.5
SHOW_LAUNCH_LOGO = true
SHOW_LOGIN_NOTICE = true
KEYBOARD_LOGIN_NOTICE = true
DEBUG_FPS = false
SIGN_KEY = "2c494560e450dcc9fe1415b220a6f706"
DYNAMIC_LOAD_MODE = false
SUBPACKAGE_LEVEL = 0
PRE_RELEASE_SERVER = false
ZM_SMALL_PACKAGE = false
if _G.FOR_REVIEW == nil then
  FOR_REVIEW = false
end
AppStore = 2003
TapTap = 2004
BetaAndroid = 2005
BetaIos = 2006
Android = 1002
Test = 1001
Fondant = 2002
KuaiKan = 2001
PreAndroid = 2007
PreIos = 2008
XipuNewAndroid = 2009
XipuAndroid = 2000
EfunAndroid = 4001
EfunIos = 4002
ElexAndroid = 4003
ElexIos = 4004
EliteOneAndorid = 2010
EliteTwoAndorid = 2011
ElexAmazon = 4005
ElexThirdPay = 4006
JapanAndroid = 4009
JapanIos = 4010
JapanAmazonAndroid = 4011
NewUsIos = 4012
NewUsAndroid = 4013
KoreanAndroid = 4007
KoreanIos = 4008
BestvAndroid = 3001
MaimengAndroid = 3002
InviteCodeChannel = 9999
QuickVirtualChannel = 99999
local channelId = 1001
local channel = tostring(channelId)
local payCallbackURL = ""
local cjson = require("cjson")
local filepath = "config.json"
if FTUtils:isPathExistent(filepath) then
  local data = FTUtils:getFileDataWithoutDec(filepath)
  if data then
    local status, result = pcall(cjson.decode, data)
    if result then
      if result.channelId then
        channelId = tonumber(result.channelId, 10)
        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        if channelId == QuickVirtualChannel then
          channelId = FTUtils:getChannelId()
        end
        channel = tostring(channelId)
      end
      if result.pre_release then
        PRE_RELEASE_SERVER = true
      end
      if result.small_package then
        ZM_SMALL_PACKAGE = true
      end
      if result.subLevel then
        SUBPACKAGE_LEVEL = tonumber(result.subLevel, 10)
      end
      if result.dynamicLoad then
        DYNAMIC_LOAD_MODE = result.dynamicLoad == true
        print(DYNAMIC_LOAD_MODE)
      end
    end
  end
end
i18n.defaultLang = "en-us"
i18n.supportLangs = {
  "en-us",
  "zh-tw",
  "th-th",
  "ms-my",
  "id-id",
  "tl-ph",
  "ru-ru",
  "tr-tr"
}
local serverHost = "foodtest.elexapp.com"
NOTICE_HOST = serverHost
if DEBUG and DEBUG == 0 then
  serverHost = "foodss.elexapp.com"
  if channelId == ElexIos or channelId == ElexAndroid or channelId == ElexAmazon or channelId == ElexThirdPay then
    serverHost = "zmfoodapi.17atv.elexapp.com"
    if PRE_RELEASE_SERVER then
      serverHost = "zmfoodimage.17atv.elexapp.com"
    end
    if ZM_SMALL_PACKAGE then
      serverHost = "foodxiaobao.elexapp.com"
    end
    NOTICE_HOST = serverHost
    if not PRE_RELEASE_SERVER and not ZM_SMALL_PACKAGE and ZM_MIN_TTL_IP and ZM_MIN_TTL_IP["80"] then
      serverHost = ZM_MIN_TTL_IP["80"]
    end
  end
end
local oldPlatform = Platform
if oldPlatform then
  table.merge(oldPlatform, {
    id = channelId,
    channel = channel,
    maxStar = 5,
    ip = serverHost,
    serverHost = serverHost
  })
else
  Platform = {
    id = channelId,
    channel = channel,
    maxStar = 5,
    ip = serverHost,
    serverHost = serverHost
  }
end
local currentLang = cc.UserDefault:getInstance():getStringForKey(i18n.LANG_CACHE_KEY, "")
local deviceLagn = FTUtils:getDeviceLanguage()
if currentLang and 0 < string.len(currentLang) then
  if i18n.defaultLang then
    if #(i18n.supportLangs or {}) == 0 then
      i18n.setLang(i18n.defaultLang)
    end
  else
    i18n.setLang(currentLang)
  end
elseif string.find(deviceLagn, "en") then
  i18n.setLang("en-us")
elseif string.find(deviceLagn, "zh") then
  i18n.setLang("zh-tw")
elseif i18n.defaultLang then
  i18n.setLang(i18n.defaultLang)
end
local tabletourlencode = function(t)
  local args = {}
  local i = 1
  for key, value in pairs(t) do
    args[i] = string.urlencode(key) .. "=" .. string.urlencode(value)
    i = i + 1
  end
  return table.concat(args, "&")
end
local shareUserDefault = cc.UserDefault:getInstance()
local isSuccess = shareUserDefault:getBoolForKey("User_activiation", false)
if not isSuccess then
  do
    local updateURL = table.concat({
      "http://",
      Platform.ip,
      "/User/activation"
    }, "")
    if USE_SSL then
      updateURL = table.concat({
        "https://",
        Platform.ip,
        "/User/activation"
      }, "")
    end
    local baseversion = FTUtils:getAppVersion()
    local t = FTUtils:getCommParamters({
      channelId = Platform.id,
      appVersion = baseversion
    })
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
    xhr:setRequestHeader("Host", tostring(Platform.serverHost))
    xhr.timeout = 10
    xhr:open("POST", updateURL)
    xhr:registerScriptHandler(function()
      if xhr.readyState == 4 and xhr.status >= 200 and xhr.status < 207 then
        shareUserDefault:setBoolForKey("User_activiation", true)
        shareUserDefault:flush()
      end
    end)
    xhr:send(ret)
  end
end
HOME_THEME_STYLE_MAP = {
  MID_AUTUMN = {
    descr = "\228\184\173\231\167\139\232\138\130",
    ACTIVITY_BTN = "theme/midAutumn/main_btn_activity.png",
    FRIENDS_BTN = "theme/midAutumn/main_btn_friends.png",
    MAIL_BTN = "theme/midAutumn/main_btn_mail.png",
    TASK_BTN = "theme/midAutumn/main_btn_task.png",
    SHOP_BTN = "theme/midAutumn/main_btn_shop.png",
    FUNC_FRAME = "theme/midAutumn/main_bg_common_disc.png",
    ORDER_PUBLIC = "theme/midAutumn/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/midAutumn/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/midAutumn/main_bg_decorate",
    LOGIN_BG = "theme/midAutumn/update_bg.jpg"
  },
  HALLOWEEN = {
    descr = "\228\184\135\229\156\163\232\138\130",
    ACTIVITY_BTN = "theme/halloween/main_btn_activity.png",
    FRIENDS_BTN = "theme/halloween/main_btn_friends.png",
    MAIL_BTN = "theme/halloween/main_btn_mail.png",
    TASK_BTN = "theme/halloween/main_btn_task.png",
    FUNC_FRAME = "theme/halloween/main_bg_common_disc.png",
    ORDER_PUBLIC = "theme/halloween/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/halloween/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/halloween/main_ico_pet.png",
    LONGXIA_SPINE = "theme/halloween/longxiache",
    WAIMAI_SPINE = "theme/halloween/waimai",
    HOME_DECORATE = "theme/halloween/main_bg_decorate",
    LOGIN_BG = "theme/halloween/update_bg.jpg"
  },
  ANNIVERSARY = {
    descr = "\229\145\168\229\185\180\229\186\1342018",
    ACTIVITY_BTN = "theme/anniversary/main_btn_activity.png",
    FRIENDS_BTN = "theme/anniversary/main_btn_friends.png",
    MAIL_BTN = "theme/anniversary/main_btn_mail.png",
    TASK_BTN = "theme/anniversary/main_btn_task.png",
    SHOP_BTN = "theme/anniversary/main_btn_shop.png",
    FUNC_FRAME = "theme/anniversary/main_bg_common_disc.png",
    ORDER_PUBLIC = "theme/anniversary/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/anniversary/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/anniversary/main_bg_decorate"
  },
  ANNIVERSARY_2019 = {
    descr = "\229\145\168\229\185\180\229\186\1342019",
    ACTIVITY_BTN = "theme/anniversary2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/anniversary2019/main_btn_friends.png",
    MAIL_BTN = "theme/anniversary2019/main_btn_mail.png",
    FUNC_FRAME = "theme/anniversary2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/anniversary2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/anniversary2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/anniversary2019/main_bg_decorate",
    LOGIN_BG = "theme/anniversary2019/update_bg.jpg"
  },
  CHRISTMAS = {
    descr = "\229\156\163\232\175\158\232\138\1302018",
    ACTIVITY_BTN = "theme/christmas/main_btn_activity.png",
    FRIENDS_BTN = "theme/christmas/main_btn_friends.png",
    MAIL_BTN = "theme/christmas/main_btn_mail.png",
    TASK_BTN = "theme/christmas/main_btn_task.png",
    SHOP_BTN = "theme/christmas/main_btn_shop.png",
    FUNC_FRAME = "theme/christmas/main_bg_common_disc.png",
    ORDER_PUBLIC = "theme/christmas/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/christmas/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/christmas/main_ico_pet.png",
    HOME_DECORATE = "theme/christmas/main_bg_decorate",
    LOGIN_BG = "theme/christmas/update_bg.jpg"
  },
  CHRISTMAS_2019 = {
    descr = "\229\156\163\232\175\158\232\138\1302019",
    ACTIVITY_BTN = "theme/christmas2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/christmas2019/main_btn_friends.png",
    MAIL_BTN = "theme/christmas2019/main_btn_mail.png",
    FUNC_FRAME = "theme/christmas2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/christmas2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/christmas2019/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/christmas2019/main_ico_pet.png",
    HOME_DECORATE = "theme/christmas2019/main_bg_decorate",
    LOGIN_BG = "theme/christmas2019/update_bg.jpg",
    LONGXIA_SPINE = "theme/christmas2019/longxiache",
    WAIMAI_SPINE = "theme/christmas2019/waimai"
  },
  CHINESE_2019 = {
    descr = "\230\152\165\232\138\1302019",
    ACTIVITY_BTN = "theme/chinese2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/chinese2019/main_btn_friends.png",
    MAIL_BTN = "theme/chinese2019/main_btn_mail.png",
    TASK_BTN = "theme/chinese2019/main_btn_task.png",
    FUNC_FRAME = "theme/chinese2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/chinese2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/chinese2019/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/chinese2019/main_ico_pet.png",
    HOME_DECORATE = "theme/chinese2019/main_bg_decorate",
    LOGIN_BG = "theme/chinese2019/update_bg.jpg"
  },
  CHINESE_2020 = {
    descr = "\230\152\165\232\138\1302020",
    ACTIVITY_BTN = "theme/chinese2020/main_btn_activity.png",
    FRIENDS_BTN = "theme/chinese2020/main_btn_friends.png",
    MAIL_BTN = "theme/chinese2020/main_btn_mail.png",
    TASK_BTN = "theme/chinese2020/main_btn_task.png",
    FUNC_FRAME = "theme/chinese2020/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/chinese2020/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/chinese2020/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/chinese2020/main_ico_pet.png",
    HOME_DECORATE = "theme/chinese2020/main_bg_decorate",
    LOGIN_BG = "theme/chinese2020/update_bg.jpg",
    LONGXIA_SPINE = "theme/chinese2020/longxiache",
    WAIMAI_SPINE = "theme/chinese2020/waimai"
  },
  TOMB_SWEEPING_2019 = {
    descr = "\230\184\133\230\152\1422019",
    HOME_DECORATE = "theme/tombSweeping2019/main_bg_decorate"
  },
  EASTER_2019 = {
    descr = "\229\164\141\230\180\187\232\138\1302019",
    ACTIVITY_BTN = "theme/easter2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/easter2019/main_btn_friends.png",
    MAIL_BTN = "theme/easter2019/main_btn_mail.png",
    TASK_BTN = "theme/easter2019/main_btn_task.png",
    FUNC_FRAME = "theme/easter2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/easter2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/easter2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/easter2019/main_bg_decorate"
  },
  DRAGON_BOAT_FESTIVAL_2019 = {
    descr = "\231\171\175\229\141\136\232\138\1302019",
    ACTIVITY_BTN = "theme/dragonBoatFestival2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/dragonBoatFestival2019/main_btn_friends.png",
    MAIL_BTN = "theme/dragonBoatFestival2019/main_btn_mail.png",
    TASK_BTN = "theme/dragonBoatFestival2019/main_btn_task.png",
    SHOP_BTN = "theme/dragonBoatFestival2019/main_btn_shop.png",
    FUNC_FRAME = "theme/dragonBoatFestival2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/dragonBoatFestival2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/dragonBoatFestival2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/dragonBoatFestival2019/main_bg_decorate"
  },
  TANABATA_2019 = {
    descr = "\230\151\165\230\156\172_\228\184\131\229\164\149\232\138\1302019",
    HOME_DECORATE = "theme/tanabata2019/main_bg_decorate"
  },
  SUMMER_FESTIVAL_2019 = {
    descr = "\229\164\143\230\151\165\231\165\1732019",
    ACTIVITY_BTN = "theme/summerFestival2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/summerFestival2019/main_btn_friends.png",
    MAIL_BTN = "theme/summerFestival2019/main_btn_mail.png",
    SHOP_BTN = "theme/summerFestival2019/main_btn_shop.png",
    FUNC_FRAME = "theme/summerFestival2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/summerFestival2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/summerFestival2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/summerFestival2019/main_bg_decorate",
    LOGIN_BG = "theme/summerFestival2019/update_bg.jpg",
    LONGXIA_SPINE = "theme/summerFestival2019/longxiache",
    WAIMAI_SPINE = "theme/summerFestival2019/waimai"
  },
  SUMMER_FESTIVAL_2020 = {
    descr = "\229\164\143\230\151\165\231\165\1732020",
    ACTIVITY_BTN = "theme/summerFestival2020/main_btn_activity.png",
    FRIENDS_BTN = "theme/summerFestival2020/main_btn_friends.png",
    MAIL_BTN = "theme/summerFestival2020/main_btn_mail.png",
    FUNC_FRAME = "theme/summerFestival2020/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/summerFestival2020/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/summerFestival2020/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/summerFestival2020/main_bg_decorate",
    LOGIN_BG = "theme/summerFestival2020/update_bg.jpg",
    LONGXIA_SPINE = "theme/summerFestival2020/longxiache",
    WAIMAI_SPINE = "theme/summerFestival2020/waimai",
    PET_BTN = "theme/summerFestival2020/main_ico_pet.png"
  },
  JP_ANNIVERSARY_2019 = {
    descr = "\230\151\165\230\156\172_\229\145\168\229\185\180\229\186\1342019",
    ACTIVITY_BTN = "theme/jpAnniversary2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/jpAnniversary2019/main_btn_friends.png",
    MAIL_BTN = "theme/jpAnniversary2019/main_btn_mail.png",
    TASK_BTN = "theme/jpAnniversary2019/main_btn_task.png",
    SHOP_BTN = "theme/jpAnniversary2019/main_btn_shop.png",
    FUNC_FRAME = "theme/jpAnniversary2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/jpAnniversary2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/jpAnniversary2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/jpAnniversary2019/main_bg_decorate",
    LOGIN_BG = "theme/jpAnniversary2019/update_bg.jpg",
    LONGXIA_SPINE = "theme/jpAnniversary2019/longxiache",
    WAIMAI_SPINE = "theme/jpAnniversary2019/waimai"
  },
  NATIONAL_DAY_2019 = {
    descr = "\229\155\189\229\186\134\232\138\1302019",
    ACTIVITY_BTN = "theme/nationalDay2019/main_btn_activity.png",
    FRIENDS_BTN = "theme/nationalDay2019/main_btn_friends.png",
    MAIL_BTN = "theme/nationalDay2019/main_btn_mail.png",
    FUNC_FRAME = "theme/nationalDay2019/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/nationalDay2019/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/nationalDay2019/main_maps_bg_branch_line_yellow.png",
    HOME_DECORATE = "theme/nationalDay2019/main_bg_decorate",
    LOGIN_BG = "theme/nationalDay2019/update_bg.jpg",
    LONGXIA_SPINE = "theme/nationalDay2019/longxiache",
    WAIMAI_SPINE = "theme/nationalDay2019/waimai",
    PET_BTN = "theme/nationalDay2019/main_ico_pet.png"
  },
  SPRINGTIME_2020 = {
    descr = "\230\152\165\230\151\165\231\165\1732020",
    ACTIVITY_BTN = "theme/springtime2020/main_btn_activity.png",
    FRIENDS_BTN = "theme/springtime2020/main_btn_friends.png",
    MAIL_BTN = "theme/springtime2020/main_btn_mail.png",
    FUNC_FRAME = "theme/springtime2020/vip_main_bg_function_plate.png",
    ORDER_PUBLIC = "theme/springtime2020/main_maps_bg_branch_line_red.png",
    ORDER_PRIVATE = "theme/springtime2020/main_maps_bg_branch_line_yellow.png",
    PET_BTN = "theme/springtime2020/main_ico_pet.png",
    HOME_DECORATE = "theme/springtime2020/main_bg_decorate",
    LOGIN_BG = "theme/springtime2020/update_bg.jpg"
  }
}
HOME_THEME_STYLE_DEFINE = {}
HOME_THEME_STYLE_DEFINE = HOME_THEME_STYLE_MAP.ANNIVERSARY_2019
