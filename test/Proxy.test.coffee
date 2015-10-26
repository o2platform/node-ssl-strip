require 'fluentnode'

net   = require('net');
Proxy = require '../src/Proxy'

describe 'Proxy', ->
  proxy   = null
  options = null

  beforeEach ->
    #options =
    #  port: 8000 + 1000.random()

    proxy = new Proxy()

  afterEach (done)->
    proxy.stop done

  it 'constructor', ->
    Proxy.assert_Is_Function()
    using proxy, ->
      @.emitter.constructor.name.assert_Is 'EventEmitter'
      assert_Is_Null(@.httpServer)

  it 'create_Server', (done)->
    using proxy , ->
      @.create_Server()
      url = "http://#{@.host}:#{@.port}"
      #url.assert_Is "http://localhost:#{config.port}"
      #console.log url
      #console.log url


      client = new net.Socket();

      client.connect @.port, @.host, ->
        self_Request = "GET #{url}/ HTTP/1.1\n\n"
        client.write self_Request

      client.on 'data', (data)->
        data.str().assert_Contains 'xss proxy is here'
      client.on 'close', ->
        done()


  it 'stop', (done)->
    proxy.stop ->
      done()

#  it 'make raw request', (done)->
#    data = 'GET http://www.google.com/bbbbbbbbbbbb?132 HTTP/1.1' + '\n' +
#            'Host: www.google.com'                               + '\n' +
#            'User-Agent: Mozilla/5.0 '                           + '\n' +
#            'Accept: text/html '                                 + '\n' +
#            'Accept-Language: en-GB,en;q=0.5 '                   + '\n' +
#            'Accept-Encoding: gzip, deflate'                     + '\n' +
#            'Connection: keep-alive'                             + '\n' +
#            '\n'
#
#
#
#    using proxy , ->
#      @.create_Server()
#      client = new net.Socket();
#      #config.port = 8010
#
#      client.connect @.port, @.host, ()->
#        console.log('Connected ...a1...')
#        client.write data
#
#
#      client.on 'data', (data)->
#        console.log('Received: ' + data);
#        client.destroy()
#
#
#      client.on 'close', ()->
#        console.log('Connection closed')
#        done()



