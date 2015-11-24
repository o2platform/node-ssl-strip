require 'fluentnode'
cheerio      = require 'cheerio'
Proxy        = require '../src/Proxy'
Proxy_Client = require '../src/Proxy-Client'

describe 'Proxy_Client', ->

  proxy        = null
  proxy_Client = null
  options      = null

  beforeEach (done)->
    proxy = new Proxy()
    proxy_Client = new Proxy_Client(port: proxy.port, host: proxy.host)
    proxy.create_Server done

  afterEach (done)->
    proxy.stop done


  it 'constructor', ->
    using proxy_Client, ->
      @.port.assert_Is proxy.port
      @.host.assert_Is proxy.host

  it 'GET google (no ssl proxy)', (done)->

    using proxy_Client, ->

      @.GET 'http://www.google.com', (data, headers)->
        data.assert_Contains '302 Moved'
        headers.location.assert_Contains 'http://'

        done()

  it 'GET google (with ssl proxy)', (done)->

    proxy.use_SSL = (requestInfo)->
      requestInfo.host.assert_Contains 'www.google'
      return true

    using proxy_Client, ->
      @.GET 'http://www.google.com', (data, headers)=>
        url2 = headers.location.replace('https','http')
        console.log url2
        @.GET url2, (data, headers)->

          $ = cheerio.load(data)
          $('title').html().assert_Is 'Google'
          assert_Is_Undefined headers.location
          done()

  it 'GET (with gzip)', (done)->
    proxy.use_SSL  = -> true

    using proxy_Client, ->
      #proxy_Client.request_Headers['accept-encoding'] = 'gzip,deflate'
      proxy_Client.request_Headers['accept-encoding'] = 'gzip'
      #proxy_Client.request_Headers['accept'         ] = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
      #proxy_Client.request_Headers['user-agent'     ] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.13+ (KHTML, like Gecko) Version/5.1.7 Safari/534.57.2'

      @.GET 'http://github.com', (data, headers)->
        #console.log data
        #console.log headers
        #console.log headers['content-encoding']
        headers['content-encoding'].assert_Is 'gzip'
        #buf = new Buffer(data, 'utf-8');
        #zlib = require('zlib')
        #zlib.gunzip buf,  (error, result) ->
        #  console.log error
        #data.assert_Contains '302 Moved'
        #headers.location.assert_Contains 'http://'

        done()



