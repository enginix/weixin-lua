-- vim:et ts=2 sw=2:

local md5
if ngx
  {:md5} = ngx
else
  crypto = require "crypto"
  md5 = (str) ->
    crypto.digest "md5", str

sign = (params, key) ->
  sorted_params = do
    res = {}
    for k, v in pairs params
      if v ~= ''
        table.insert res, {:k, :v}

    res

  table.sort sorted_params, (a, b) ->
    return a.k < b.k
  
  table.insert sorted_params, {k: "key", v:key}
  msg = ["#{p.k}=#{p.v}" for p in *sorted_params]
  msg = table.concat msg, '&'
  md5(msg)\upper!

verify = (params, key, signature) ->
  signature == sign params, key

extend = (a, ...) ->
  for t in *{...}
    if t
      a[k] = v for k,v in pairs t
  a

to_kv = (in_obj) ->
  res = {}
  for item in *in_obj
    if type(item[1]) == "table"
      res[item.xml] = to_kv item[1]
    else
      res[item.xml] = item[1]
  res

to_xml = (kv_obj) ->
  res = {}
  for k, v in pairs kv_obj
    item = {}
    item.xml = k
    if type(v) == "table"
      item[1] = to_xml v
    else
      item[1] = v
    table.insert res, item
  res

parse_xml = (text) ->
  xml = require "xml"
  obj = xml.load text
  return nil, "Malformed xml." unless obj
  to_kv obj

encode_xml = (kv_obj) ->
  xml = require "xml"
  xml_obj = to_xml kv_obj
  xml_obj.xml = "xml"
  xml.dump xml_obj

generate_key = do
  import random from math
  random_char = ->
    switch random 1,3
      when 1
        random 65, 90
      when 2
        random 97, 122
      when 3
        random 48, 57

  (length) ->
    string.char unpack [ random_char! for i=1,length ]

stringify_field = (t) ->
  for k,v in pairs t
    if type(v) ~= 'string'
      t[k] = tostring v

{:sign, :verify, :extend, :parse_xml, :encode_xml, :generate_key, :stringify_field}

