-- vim: et ts=2 sw=2:
ltn12 = require "ltn12"
import concat from table

import types from require "tableshape"
import
  extend
  parse_xml
  encode_xml
  sign
  verify
  generate_key
  stringify_field
  from require "payments.weixin.helpers"

class WeixinBase extends require "payments.base_client"
  @urls: {
    live: {
      base: "https://api.mch.weixin.qq.com/pay"
      sec_base: "https://api.mch.weixin.qq.com/secapi/pay"
    }
    sandbox: {
      base: "https://api.mch.weixin.qq.com/sandboxnew/pay"
      sec_base: "https://api.mch.weixin.qq.com/sandboxnew/secapi/pay"
    }
  }

  @bill_types: types.one_of {
    "ALL"
    "SUCCESS"
    "REFUND"
    "RECHARGE_REFUND"
  }

  new: (@opts) =>
    @appid = assert @opts.appid, "missing app id"
    @mch_id = assert @opts.mch_id, "missing mch id"
    @key = assert @opts.key, "missing app key"
    @trade_type = assert @opts.trade_type, "missing trade type"
    urls = @opts.sandbox and @@urls.sandbox or @@urls.live
    @base_url = urls.base
    @sec_base_url = urls.sec_base
    super @opts

  _method: (action, params, secapi=false) =>
    base_url = secapi and @sec_base_url or @base_url
    nonce_str = generate_key 32
    stringify_field params

    params = extend {
      appid: @appid
      mch_id: @mch_id
      :nonce_str
    }, params

    params.sign = sign params, @key
    body = encode_xml params

    parse_url = require("socket.url").parse
    host = assert parse_url(base_url).host
    headers = {
      Host: host
      "Content-Length": tostring #body
      "Content-Type": "text/xml, application/xml"
    }

    out = {}
    _, code, res_headers = assert @http!.request {
      :headers
      url: "#{base_url}/#{action}"
      source: ltn12.source.string body
      method: "POST"
      sink: ltn12.sink.table out
    }

    if not code or code ~= 200
      return nil, 'http error'

    text = concat out
    res, err = parse_xml text
    return nil, err unless res
    -- XXX: verify sign
    signature = res.sign
    res.sign = nil
    unless verify res, @key, signature
      return nil, 'Bad signature'
    @_extract_error res, res_headers

  _extract_error: (res={}, msg="weixin failed") =>
    unless res.return_code == 'SUCCESS'
      return nil, res.return_msg
    unless not res.result_code or res.result_code == 'SUCCESS'
      return nil, res.err_code_des, res.err_code
    res

  unified_order: (params={}) =>
    params.trade_type = @trade_type
    @_method 'unifiedorder', params

  query_order: (params={}) =>
    assert params.transaction_id or params.out_trade_no, "Missing transaction_id, out_trade_no"
    @_method 'orderquery', params

  close_order: (params={}) =>
    assert params.out_trade_no, "Missing out_trade_no"
    @_method 'closeorder', params

  refund: (params={}) =>
    assert params.transaction_id or params.out_trade_no, "Missing transaction_id, out_trade_no"
    @_method 'refund', params, true

  query_refund: (params={}) =>
    assert params.transaction_id or params.out_trade_no or params.out_refund_no or params.refund_id,
      "Missing transaction_id, out_trade_no, out_refund_no, refund_id"
    @_method 'refundquery', params

  download_bill: (params={}) =>
    assert @@.bill_types @bill_type
    @_method "downloadbill", params

  get_sign_key: =>
    unless @opts.sandbox
      return nil, "Not supported in live mode."
    
    base_url = secapi and @sec_base_url or @base_url
    nonce_str = generate_key 32
    params = {
      mch_id: @mch_id
      :nonce_str
    }
    params.sign = sign params, @key
    body = encode_xml params

    parse_url = require("socket.url").parse
    host = assert parse_url(base_url).host
    headers = {
      Host: host
      "Content-Length": tostring #body
      "Content-Type": "text/xml, application/xml"
    }

    out = {}
    _, code, res_headers = assert @http!.request {
      :headers
      url: "#{base_url}/getsignkey"
      source: ltn12.source.string body
      method: "POST"
      sink: ltn12.sink.table out
    }

    if not code or code ~= 200
      return nil, 'http error'

    text = concat out
    res, err = parse_xml text
    return nil, err unless res
    @_extract_error res, res_headers
