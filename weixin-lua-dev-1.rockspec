package = "weixin-lua"
version = "dev-1"

source = {
  url = "git://github.com/enginix/weixin-lua.git",
}

description = {
  summary = "Weixin support for lua, work with openresty.",
  homepage = "https://github.com/enginix/weixin-lua",
  license = "None"
}

dependencies = {
  "payments",
  "luacrypto",
}

build = {
  type = "builtin",
  modules = {
    ["payments.weixin"] = "payments/weixin.lua",
    ["payments.weixin.base"] = "payments/weixin/base.lua",
    ["payments.weixin.helpers"] = "payments/weixin/helpers.lua",
    ["payments.weixin.wx"] = "payments/weixin/wx.lua",
  }
}
