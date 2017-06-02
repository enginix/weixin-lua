-- vim: et ts=2 sw=2:

class Wx extends require "payments.weixin.base"
  new: (@opts={}) =>
    @opts.trade_type = 'APP'
    super @opts

