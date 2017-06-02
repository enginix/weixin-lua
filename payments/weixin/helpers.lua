local md5
if ngx then
  md5 = ngx.md5
else
  local crypto = require("crypto")
  md5 = function(str)
    return crypto.digest("md5", str)
  end
end
local sign
sign = function(params, key)
  local sorted_params
  do
    local res = { }
    for k, v in pairs(params) do
      if v ~= '' then
        table.insert(res, {
          k = k,
          v = v
        })
      end
    end
    sorted_params = res
  end
  table.sort(sorted_params, function(a, b)
    return a.k < b.k
  end)
  table.insert(sorted_params, {
    k = "key",
    v = key
  })
  local msg
  do
    local _accum_0 = { }
    local _len_0 = 1
    for _index_0 = 1, #sorted_params do
      local p = sorted_params[_index_0]
      _accum_0[_len_0] = tostring(p.k) .. "=" .. tostring(p.v)
      _len_0 = _len_0 + 1
    end
    msg = _accum_0
  end
  msg = table.concat(msg, '&')
  return md5(msg):upper()
end
local verify
verify = function(params, key, signature)
  return signature == sign(params, key)
end
local extend
extend = function(a, ...)
  local _list_0 = {
    ...
  }
  for _index_0 = 1, #_list_0 do
    local t = _list_0[_index_0]
    if t then
      for k, v in pairs(t) do
        a[k] = v
      end
    end
  end
  return a
end
local to_kv
to_kv = function(in_obj)
  local res = { }
  for _index_0 = 1, #in_obj do
    local item = in_obj[_index_0]
    if type(item[1]) == "table" then
      res[item.xml] = to_kv(item[1])
    else
      res[item.xml] = item[1]
    end
  end
  return res
end
local to_xml
to_xml = function(kv_obj)
  local res = { }
  for k, v in pairs(kv_obj) do
    local item = { }
    item.xml = k
    if type(v) == "table" then
      item[1] = to_xml(v)
    else
      item[1] = v
    end
    table.insert(res, item)
  end
  return res
end
local parse_xml
parse_xml = function(text)
  local xml = require("xml")
  local obj = xml.load(text)
  if not (obj) then
    return nil, "Malformed xml."
  end
  return to_kv(obj)
end
local encode_xml
encode_xml = function(kv_obj)
  local xml = require("xml")
  local xml_obj = to_xml(kv_obj)
  xml_obj.xml = "xml"
  return xml.dump(xml_obj)
end
local generate_key
do
  local random
  random = math.random
  local random_char
  random_char = function()
    local _exp_0 = random(1, 3)
    if 1 == _exp_0 then
      return random(65, 90)
    elseif 2 == _exp_0 then
      return random(97, 122)
    elseif 3 == _exp_0 then
      return random(48, 57)
    end
  end
  generate_key = function(length)
    return string.char(unpack((function()
      local _accum_0 = { }
      local _len_0 = 1
      for i = 1, length do
        _accum_0[_len_0] = random_char()
        _len_0 = _len_0 + 1
      end
      return _accum_0
    end)()))
  end
end
local stringify_field
stringify_field = function(t)
  for k, v in pairs(t) do
    if type(v) ~= 'string' then
      t[k] = tostring(v)
    end
  end
end
return {
  sign = sign,
  verify = verify,
  extend = extend,
  parse_xml = parse_xml,
  encode_xml = encode_xml,
  generate_key = generate_key,
  stringify_field = stringify_field
}
