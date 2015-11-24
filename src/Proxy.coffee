EventEmitter = require('events').EventEmitter
https        = require('https')
http         = require('http')
url          = require('url')
zlib         = require('zlib')

class Proxy
  constructor: (options)->
    @.emitter    = new EventEmitter()
    @.httpServer = null
    @.options    = options || {}
    @.port       = @.options.port || 30000 + 5000.random()
    @.host       = @.options.host || 'localhost'
    @.test       = 125


  create_Server: (callback)=>

    @.httpServer = http.createServer(@.get_Request_Listener());

    @.httpServer.on 'clientError',  (error)=>
      console.log '[clientError] ' + error
      #@.emitter.emit('clientError', error, 'proxyClient')
    @.httpServer.on 'error'      ,  (error)=>
      console.log '[error] ' + error
      #@.emitter.emit('error :'      , error, 'proxyServer')

    @.httpServer.listen @.port, @.host, =>
      console.log "Server created at http://#{@.host}:#{@.port}"
      callback() if callback


  get_Request_Info: (req)=>
    parsedUrl   = url.parse(req.url);
    headers     = req.headers
    parsedHost  = url.parse('http://' + headers['host']);

    #if headers['x-xss-proxy'] and headers['x-xss-proxy'].indexOf('text') >  -1
    #headers['accept-encoding'] = ''

    requestInfo =
      host   : parsedUrl.hostname || parsedHost.hostname,
      port   : parsedUrl.port  #|| if isSsl then 443 else 80
      path   : parsedUrl.pathname + (parsedUrl.search || '') + (parsedUrl.hash || ''),
      method : req.method,
      headers: headers

    headers['x-xss-proxy'] = 'enabled'

    return @.on_Get_Request_Info(requestInfo, parsedUrl, parsedHost)


  get_Request_Listener: =>
    (req,res)=>

      @.on_Request(req,res)

      if req.headers['x-xss-proxy']
        res.write 'xss proxy is here'
        res.end()
        return

      requestInfo = @.get_Request_Info(req)

      if @.skip_Request(req.url, requestInfo)
        res.writeHead(201,  {'xss-proxy':'request skipped'})
        res.write 'no request'
        res.end()
        return

      #if req.url is '/'
      #  res.write('direct requests are not supported')
      #  res.end()



      engine = if @.use_SSL(requestInfo) then https else http

      proxy_Req = engine.request requestInfo,  (proxy_Res)=>

        @.on_Proxy_Response proxy_Res
        @.on_Proxy_Response_Headers proxy_Res.headers

        res.writeHead proxy_Res.statusCode, proxy_Res.headers

        if (@.intercept_Request(req.url, requestInfo, proxy_Res.headers))
          @.proxy_Data_Intercept(res, proxy_Res)
        else
          @.proxy_Data_Transparent(res,proxy_Res)

      proxy_Req.on 'error', (error) ->
        console.log 'error'  + error.message

      proxy_Req.end()


  intercept_Request: (url, requestInfo, proxy_Res_Headers)=>
    return false

  on_Get_Request_Info : (request_Info, parsedUrl, parsedHost)=>
    #console.log parsedUrl.hostname , parsedUrl.pathname
    request_Info

  on_Request: (req, res)->
    return

  on_Proxy_Response: (res)->
    return

  on_Proxy_Response_Headers: (headers)->
    return

  proxy_Data_Transparent: (res, proxy_Res)=>
#    if false and proxy_Res.headers['content-encoding'] is 'gzip'
#      proxy_Res.headers
#      gunZip = zlib.createGunzip()
#      proxy_Res.pipe(gunZip)
#
#      data = ''
#      gunZip.on 'data', (chunk)->
#        data += chunk
#
#      proxy_Res.on 'end' , ()=>
#        data = data.replace(/API/g,'aaaaaaa')
#
#        buf = new Buffer(data, 'utf-8');
#        zlib.gzip buf,  (error, result) ->
#          res.end(result);
#    else
    proxy_Res.pipe res

  proxy_Data_Intercept: (res,proxy_Res)=>
    data = ''
    if proxy_Res.headers['content-encoding'] is 'gzip'

      proxy_Res.headers
      gunZip = zlib.createGunzip()
      proxy_Res.pipe(gunZip)

      gunZip.on 'data', (chunk)->
        data += chunk.toString('utf-8')

      gunZip.on 'end' , ()=>
        buf = new Buffer(@.modify_Data(data), 'utf-8');
        zlib.gzip buf,  (error, result) ->
          res.end(result);
    else
      proxy_Res.on 'data' , (chunk)->
        data += chunk
      proxy_Res.on 'end' , ()=>
        res.write @.modify_Data(data)
        res.end()

  modify_Data: (data)=>
    data

  skip_Request: (data)=>
    return false

  stop: (callback)=>
    if @.httpServer
      @.httpServer.close_And_Destroy_Sockets ->
        callback() if callback
    else
      callback()

  use_SSL: (requestInfo)=>
    requestInfo.port is 80

module.exports = Proxy