local ltn12 = require("ltn12")
local concat
concat = table.concat
local types
types = require("tableshape").types
local extend, parse_xml, encode_xml, sign, verify, generate_key, stringify_field
do
  local _obj_0 = require("payments.weixin.helpers")
  extend, parse_xml, encode_xml, sign, verify, generate_key, stringify_field = _obj_0.extend, _obj_0.parse_xml, _obj_0.encode_xml, _obj_0.sign, _obj_0.verify, _obj_0.generate_key, _obj_0.stringify_field
end
local WeixinBase
do
  local _class_0
  local _parent_0 = require("payments.base_client")
  local _base_0 = {
    _method = function(self, action, params, secapi)
      if secapi == nil then
        secapi = false
      end
      local base_url = secapi and self.sec_base_url or self.base_url
      local nonce_str = generate_key(32)
      stringify_field(params)
      params = extend({
        appid = self.appid,
        mch_id = self.mch_id,
        nonce_str = nonce_str
      }, params)
      params.sign = sign(params, self.key)
      local body = encode_xml(params)
      local parse_url = require("socket.url").parse
      local host = assert(parse_url(base_url).host)
      local headers = {
        Host = host,
        ["Content-Length"] = tostring(#body),
        ["Content-Type"] = "text/xml, application/xml"
      }
      local out = { }
      local _, code, res_headers = assert(self:http().request({
        headers = headers,
        url = tostring(base_url) .. "/" .. tostring(action),
        source = ltn12.source.string(body),
        method = "POST",
        sink = ltn12.sink.table(out)
      }))
      if not code or code ~= 200 then
        return nil, 'http error'
      end
      local text = concat(out)
      local res, err = parse_xml(text)
      if not (res) then
        return nil, err
      end
      local signature = res.sign
      res.sign = nil
      if not (verify(res, self.key, signature)) then
        return nil, 'Bad signature'
      end
      return self:_extract_error(res, res_headers)
    end,
    _extract_error = function(self, res, msg)
      if res == nil then
        res = { }
      end
      if msg == nil then
        msg = "weixin failed"
      end
      if not (res.return_code == 'SUCCESS') then
        return nil, res.return_msg
      end
      if not (not res.result_code or res.result_code == 'SUCCESS') then
        return nil, res.err_code_des, res.err_code
      end
      return res
    end,
    unified_order = function(self, params)
      if params == nil then
        params = { }
      end
      params.trade_type = self.trade_type
      return self:_method('unifiedorder', params)
    end,
    query_order = function(self, params)
      if params == nil then
        params = { }
      end
      assert(params.transaction_id or params.out_trade_no, "Missing transaction_id, out_trade_no")
      return self:_method('orderquery', params)
    end,
    close_order = function(self, params)
      if params == nil then
        params = { }
      end
      assert(params.out_trade_no, "Missing out_trade_no")
      return self:_method('closeorder', params)
    end,
    refund = function(self, params)
      if params == nil then
        params = { }
      end
      assert(params.transaction_id or params.out_trade_no, "Missing transaction_id, out_trade_no")
      return self:_method('refund', params, true)
    end,
    query_refund = function(self, params)
      if params == nil then
        params = { }
      end
      assert(params.transaction_id or params.out_trade_no or params.out_refund_no or params.refund_id, "Missing transaction_id, out_trade_no, out_refund_no, refund_id")
      return self:_method('refundquery', params)
    end,
    download_bill = function(self, params)
      if params == nil then
        params = { }
      end
      assert(self.__class.bill_types(self.bill_type))
      return self:_method("downloadbill", params)
    end,
    get_sign_key = function(self)
      if not (self.opts.sandbox) then
        return nil, "Not supported in live mode."
      end
      local base_url = secapi and self.sec_base_url or self.base_url
      local nonce_str = generate_key(32)
      local params = {
        mch_id = self.mch_id,
        nonce_str = nonce_str
      }
      params.sign = sign(params, self.key)
      local body = encode_xml(params)
      local parse_url = require("socket.url").parse
      local host = assert(parse_url(base_url).host)
      local headers = {
        Host = host,
        ["Content-Length"] = tostring(#body),
        ["Content-Type"] = "text/xml, application/xml"
      }
      local out = { }
      local _, code, res_headers = assert(self:http().request({
        headers = headers,
        url = tostring(base_url) .. "/getsignkey",
        source = ltn12.source.string(body),
        method = "POST",
        sink = ltn12.sink.table(out)
      }))
      if not code or code ~= 200 then
        return nil, 'http error'
      end
      local text = concat(out)
      local res, err = parse_xml(text)
      if not (res) then
        return nil, err
      end
      return self:_extract_error(res, res_headers)
    end
  }
  _base_0.__index = _base_0
  setmetatable(_base_0, _parent_0.__base)
  _class_0 = setmetatable({
    __init = function(self, opts)
      self.opts = opts
      self.appid = assert(self.opts.appid, "missing app id")
      self.mch_id = assert(self.opts.mch_id, "missing mch id")
      self.key = assert(self.opts.key, "missing app key")
      self.trade_type = assert(self.opts.trade_type, "missing trade type")
      local urls = self.opts.sandbox and self.__class.urls.sandbox or self.__class.urls.live
      self.base_url = urls.base
      self.sec_base_url = urls.sec_base
      return _class_0.__parent.__init(self, self.opts)
    end,
    __base = _base_0,
    __name = "WeixinBase",
    __parent = _parent_0
  }, {
    __index = function(cls, name)
      local val = rawget(_base_0, name)
      if val == nil then
        local parent = rawget(cls, "__parent")
        if parent then
          return parent[name]
        end
      else
        return val
      end
    end,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  local self = _class_0
  self.urls = {
    live = {
      base = "https://api.mch.weixin.qq.com/pay",
      sec_base = "https://api.mch.weixin.qq.com/secapi/pay"
    },
    sandbox = {
      base = "https://api.mch.weixin.qq.com/sandboxnew/pay",
      sec_base = "https://api.mch.weixin.qq.com/sandboxnew/secapi/pay"
    }
  }
  self.bill_types = types.one_of({
    "ALL",
    "SUCCESS",
    "REFUND",
    "RECHARGE_REFUND"
  })
  if _parent_0.__inherited then
    _parent_0.__inherited(_parent_0, _class_0)
  end
  WeixinBase = _class_0
  return _class_0
end
