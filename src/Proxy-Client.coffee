http         = require('http')
url          = require('url')

class Proxy_Client
  constructor: (options)->
    @.options         = options || {}
    @.port            = @.options.port
    @.host            = @.options.host
    @.request_Headers = {} || @.options.request_Headers


  GET: (target, callback)=>

    @.request_Headers.host = url.parse(target).host

    get_Options =
      host   : @.host
      port   : @.port
      path   : target
      method : 'GET'
      headers: @.request_Headers

    req = http.request get_Options, (res)->

      data = ''
      res.on 'data', (chunk)->
        data += chunk
      res.on 'end', ->
        callback data, res.headers

    req.on 'error', (error) ->
        console.log 'error'  + error.message
    req.end()

module.exports = Proxy_Client