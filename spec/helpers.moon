
assert_shape = (obj, shape) ->
  assert shape obj

make_http = (handle) ->

  http_requests = {}
  fn = =>
    @http_provider = "test"
    {
      request: (req) ->
        table.insert http_requests, req
        handle req if handle
        1, 200, {}
    }

  fn, http_requests

{:make_http, :assert_shape}
