EventEmitter = require('events').EventEmitter
https        = require('https')
http         = require('http')
url          = require('url')

class Proxy
  constructor: (options)->
    @.emitter    = new EventEmitter()
    @.httpServer = null
    @.options    = options || {}


  create_Server: =>
    config = @.server_Config()

    @.httpServer = http.createServer(@.get_Request_Listener());
    @.httpServer.listen(config.port, config.host);
    @.httpServer.on 'clientError',  (error)=>
      console.log error
      @.emitter.emit('clientError', error, 'proxyClient')
    @.httpServer.on 'error'      ,  (error)=>
      console.log error
      @.emitter.emit('error'      , error, 'proxyServer')



    console.log "Server created at http://#{config.host}:#{config.port}"


  get_Request_Info: (req)=>
    parsedUrl              = url.parse(req.url);
    #isSsl                  = false
    headers                = req.headers
    parsedHost             = url.parse('http://' + headers['host']);

    headers['x-xss-proxy'] = 'enabled'

    #if headers['x-xss-proxy'] and headers['x-xss-proxy'].indexOf('text') >  -1
    headers['accept-encoding'] = ''

    requestInfo =
      host   : parsedUrl.hostname || parsedHost.hostname,
      port   : parsedUrl.port  #|| if isSsl then 443 else 80
      path   : parsedUrl.pathname + (parsedUrl.search || '') + (parsedUrl.hash || ''),
      method : req.method,
      headers: headers


    return @.on_Get_Request_Info(requestInfo, parsedUrl, parsedHost)


  get_Request_Listener: =>
    (req,res)=>
      if req.headers['x-xss-proxy']
        res.write('xss proxy is here')
        res.end()


      requestInfo = @.get_Request_Info(req)

      engine = if @.use_SSL(requestInfo) then https else http
      proxy_Req = engine.request requestInfo,  (proxy_Res)=>
        res.writeHead proxy_Res.statusCode, proxy_Res.headers

        if (@.intercept_Request(requestInfo, proxy_Res.headers))
          @.proxy_Data_Intercept(res, proxy_Res)
        else
          @.proxy_Data_Transparent(res,proxy_Res)

      proxy_Req.on 'error', (error) ->
        console.log 'error'  + error.message

      proxy_Req.end()


  intercept_Request: (requestInfo, proxy_Res_Headers)=>
    if proxy_Res_Headers['content-type']
      return proxy_Res_Headers['content-type'].indexOf('text/html') > -1
    return false

  on_Get_Request_Info : (request_Info, parsedUrl, parsedHost)=>
    console.log parsedUrl.hostname , parsedUrl.pathname
    request_Info

  proxy_Data_Transparent: (res, proxy_Res)=>
    proxy_Res.on 'data' , (chunk)->
      res.write(chunk)
    proxy_Res.on 'end' , ()=>
      res.end()

  proxy_Data_Intercept: (res,proxy_Res)=>
    data = ''
    proxy_Res.on 'data' , (chunk)->
      data += chunk
    proxy_Res.on 'end' , ()=>
      @.send_Data res, data

  send_Data: (res, data)=>
    data = data.replace /JADE/g, 'aaa12aaa'
    res.write data
    res.end()


  server_Config: =>
    config =
      port: @.options.port || 8888
      host: 'localhost'
    return config

  use_SSL: (requestInfo)=>
    requestInfo.port is 80

module.exports = Proxy