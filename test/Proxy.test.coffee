require 'fluentnode'

Proxy = require '../src/Proxy'

describe 'Proxy', ->
  proxy   = null
  options = null

  beforeEach ->
    options =
      port: 8000 + 1000.random()

    proxy = new Proxy(options)

  afterEach (done)->
    if proxy.httpServer
      proxy.httpServer.close_And_Destroy_Sockets ->
        done()
    else
      done()
      #proxy.httpServer.close()

  it 'constructor', ->
    Proxy.assert_Is_Function()
    using proxy, ->
      @.emitter.constructor.name.assert_Is 'EventEmitter'
      assert_Is_Null(@.httpServer)

  it 'create_Server', (done)->
    using proxy , ->
      @.create_Server()
      config = @.server_Config()
      url = "http://#{config.host}:#{config.port}"
      url.assert_Is "http://localhost:#{options.port}"
      #console.log url
      url.GET (data)->
        data.assert_Is '"connect ECONNREFUSED 127.0.0.1:80"'
        done()


#  it 'errorWrapper', ->
#    using proxy , ->
#      try
#        console.log @.error_Wrapper(null)()
#      catch error
#        error.str().assert_Is 'TypeError: object is not a function'

  it 'server_Config', ->
    using proxy.server_Config() , ->
      #console.log @
      @.port.assert_Is options.port
      @.host.assert_Is 'localhost'





  it.only 'make raw request', (done)->
    data = 'GET http://www.google.com/bbbbbbbbbbbb?132 HTTP/1.1' + '\n' +
            'Host: www.google.com'                               + '\n' +
            'User-Agent: Mozilla/5.0 '                           + '\n' +
            'Accept: text/html '                                 + '\n' +
            'Accept-Language: en-GB,en;q=0.5 '                   + '\n' +
            'Accept-Encoding: gzip, deflate'                     + '\n' +
            'Connection: keep-alive'                             + '\n' +
            '\n'

    net = require('net');

    using proxy , ->
      @.create_Server()
      config = @.server_Config()
      client = new net.Socket();
      #config.port = 8010
      console.log config

      client.connect config.port, config.host, ()->
        console.log('Connected ...a1...')
        client.write data


      client.on 'data', (data)->
        console.log('Received: ' + data);
        client.destroy()


      client.on 'close', ()->
        console.log('Connection closed')
        done()



