-- vim: et ts=2 sw=2:
import types from require "tableshape"
import extract_params, make_http, assert_shape from require "spec.helpers"

import sign, verify, encode_xml, parse_xml from require "payments.weixin.helpers"

assert_shape = (obj, shape) ->
  assert shape obj

describe "wx", ->
  key = 'your-api-key'
  it "creates a wx object", ->
    import Wx from require "payments.weixin"
    wx = assert Wx {
      :key
      appid: 'your-app-id'
      mch_id: '12345678'
    }

  describe "with client", ->
    local wx, http_requests, http_fn
    local api_response

    api_request = (opts={}, fn) ->
      method = opts.method or "POST"
      spec_name = opts.name or "#{method} #{opts.path}"

      it spec_name, ->
        api_response = encode_xml opts.response_object
        response = { fn! }

        opts.response_object.sign = nil
        assert.same {
          opts.response_object or {hello: "world"}
        }, response

        req = assert http_requests[#http_requests], "expected http request"

        assert_shape req, types.shape {
          :method
          url: "https://api.mch.weixin.qq.com/pay#{assert opts.path, "missing path"}"

          sink: types.function
          source: opts.body and types.function

          headers: types.shape {
            "Host": "api.mch.weixin.qq.com"
            "Content-Type": "text/xml, application/xml"
            "Content-Length": opts.body and types.pattern "%d+"
          }
        }

        if opts.body
          source = req.source!
          source_data = parse_xml source
          expected = {k,v for k,v in pairs source_data when type(k) == "string"}
          signature = expected.sign
          expected.sign = nil
          assert.true verify expected, key, signature

          expected.nonce_str = nil
          assert.same opts.body, expected

    before_each ->
      api_response = nil -- reset to default
      import Wx from require "payments.weixin"
      http_fn, http_requests = make_http (req) ->
        req.sink api_response or '{"hello": "world"}'

      wx = assert Wx {
        :key
        appid: 'your-app-id'
        mch_id: '12345678'
      }
      wx.http = http_fn

    describe "unified order", ->
      response_object = {
        appid: 'your-app-id'
        mch_id: '12345678'
        return_code: 'SUCCESS'
        result_code: 'SUCCESS'
        nonce_str: '1234567890abcdefghijk'
      }
      response_object.sign = sign response_object, key

      api_request {
        method: 'POST'
        path: "/unifiedorder"
        body: {
          out_trade_no: '1234567890'
          total_fee: '1'
          body: 'your body'
          spbill_create_ip: '127.0.0.1'
          notify_url: 'http://www.weixin.qq.com/wxpay/pay.php'
          appid: 'your-app-id'
          mch_id: '12345678'
          trade_type: 'APP'
        }
        :response_object
      }, ->
        wx\unified_order {
          out_trade_no: '1234567890'
          total_fee: 1
          body: 'your body'
          spbill_create_ip: '127.0.0.1'
          notify_url: 'http://www.weixin.qq.com/wxpay/pay.php'
        }

