Barefoot
========

Barefoot is a utility-belt library for Node for asynchronous functions manipulation

To install it

`npm install barefoot`

To use it

`bf = require 'barefoot'`


Module dependencies
-------------------


    lateral   = require 'lateral'
    config    = require 'config'
    _         = require 'lodash'



Let's get started
------------------


**error**

Barefoot error class used to construct consistently formatted error responses

    bfError = class BFError
      constructor: (errorCode, message, statusCode) ->
        @errorCode = errorCode
        @message = message
        @statusCode = parseInt(statusCode) if statusCode?

      sendRes: (res) ->
        if @statusCode?
          res.json @statusCode, { error: { code: @errorCode, message: @message }  }
        else
          res.json { error: { code: @errorCode, message: @message }  }


**toDictionary**

Transform an array of object into a dictionary based on the property passed as a second param

    toDictionary = (array, prop) ->
      dictionary = {}
      array.forEach (elt) ->
        dictionary[elt[prop]] = elt if elt? and elt[prop]?
      return dictionary



**has**

Provides a function which test if parameters object has certain properties

    has = (parameters) ->
      (params, done) ->
        ok = true
        ok = (ok and params? and params[par]?) for par in parameters
        done (if ok then null else new Error("Missing Parameters")), params


**amap**

Asynchronous map
Use the awesome **lateral** module to do the job

    amap = (func, nbProcesses = 1) ->
      (array, done) ->
        results = []
        errors = null
        unit = lateral.create (complete, item) ->
          func item, (err, res) ->
            if err?
              errors ?= []
              errors.push(err)
              results.push null
            else
              results.push res
            complete()
        , nbProcesses

        unit.add(array).when () ->
          done(errors, results) if done?

**chain**

Chain aynschronous methods with signature (val, done) -> done(err, result)
Stop if one of the method has an error in the callback

    chain = (funcs) ->
      (val, done) ->
        if funcs.length == 0
          done null, val
        else
          funcs[0] val, (err, res) =>
            if err?
              done err, res
            else
              chain(funcs[1..])(res, done)

**avoid**

Wrap a void returning function to make it callable in a chain

    avoid = (func) ->
      (params, done) ->
        func(params)
        done null, params


**nothing**

Do nothing but be defined

    nothing = (params, done) -> done null, params


**parallel**

Execute asynchronous functions which take same inputs

    parallel = (funcs) ->
      (params, done) ->

        i = 0
        errors = []
        results = []
        tempDone = (err, result) ->
          i++
          errors.push(err) if err?
          results.push result
          if i == funcs.length
            error = if errors.length > 0  then errors else null
            done error, results

        funcs.forEach (func) ->
          func params, tempDone


**getRequestParams**

    getRequestParams = (req) ->

      params = {}
      for field in ["body", "query", "params", "files", "migrated_params", "session"]
        if req[field]?
          to_extend = req[field]
          to_delete = []
          for f, v of to_extend
            if typeof v is "function"
              to_delete.push f

          delete to_extend[f] for f in to_delete

          for f, v of to_extend
            params[f] = v if v?
      params.user = req.user if req.user?

      error_codes = req.flash?("error_codes")
      # console.log "error_codes flash: ", error_codes
      params.error_codes = error_codes

      params.form_data = req.flash?("form_data")

      params.sessionID = req.sessionID if req.sessionID?
      if params.email? and _.isString(params.email)
        params.email = params.email.toLowerCase()
      params.ip_address = req.headers['x-forwarded-for'] || (req.connection && req.connection.remoteAddress) ||  (req.socket && req.socket.remoteAddress) || (req.connection && req.connection.socket && req.connection.socket.remoteAddress)
      params.api_key = req.headers['api-key']

      params.cookies = req.cookies
      params._url = req.url

      params

**setResCookies**

    setResCookies = (res, cookies) ->
      if !cookies? then return
      for name, cookie of cookies
        res.cookie(name, cookie.value, cookie.options) if(cookie.value?)


**sendFile**

    sendFile = (method) ->
      (req, res) ->
        method getRequestParams(req), (err, {filepath, filename}) ->

          res.download filepath, filename


**webPagePost**

    webPagePost = (method, redirect, error_redirect) ->
      (req, res) ->

        method getRequestParams(req), (err, data) ->
          req.clearTimeout() if req.clearTimeout?
          if err?
            if req.flash?
              req.flash "error_codes", if err.message then err.message else err

            correct_data = {}
            for k, v of data
              if typeof v isnt "function" and [ "flash", "cookie" ].indexOf(k) is -1
                correct_data[k] = v

            if req.flash?
              req.flash "form_data", correct_data
            #res.redirect error_redirect
            redirect_url = error_redirect ? req.headers.referer ? req.url

          else
            data = {} if not data?
            data.user = req.user if req.user? and not data.user?

            if data.session?
              for key, value of data.session
                req.session[key] = value

            redirect_url = redirect ? req.url
            if data?.redirect?
              redirect_url = data.redirect


          #TODO get this code a bit more elegant.
          final_redirect_url = redirect_url
          if url_params = final_redirect_url.match /\:[a-zA-Z\-\_]+/g
            for url_param in url_params
              param_name = url_param.replace(/\:/g, '')
              final_redirect_url = final_redirect_url.replace url_param, data[param_name]
          # Login the new registered user
          if data?.user and (not req.user? or req.user?.IsAnonymous)
            req.user = data.user
            req.session.passport.user = data.user.ID
          res.redirect final_redirect_url




**csv**

    csv = (method) ->
      (req, res) ->
        params = {}
        for field in ["body", "query", "params"]
          if req[field]?
            params = _.extend params, req[field]

        method params, (err, {name, content}) ->
          res.set('Content-Type', 'text/csv')
          res.set('Content-Disposition', "attachment;filename=#{name}.csv")
          res.send(content)

**processDeepObjectFilter**

    processDeepObjectFilter = (data, deepFilterFn) ->
      if(!_.isFunction(deepFilterFn)) then return
      if(_.isArray(data))
        processDeepObjectFilter(value, deepFilterFn) for value, key in data

      else if(_.isPlainObject(data))
        deepFilterFn(data)
        processDeepObjectFilter(value, deepFilterFn) for key, value of data

**webService**

    webService = (method, options) ->
      options = _.extend (options || {}),
        contentType: "application/json"

      (req, res) ->
        method getRequestParams(req), (err, data) ->
          # Clear the timeout -- if there is one.
          req.clearTimeout() if req.clearTimeout?

          if err?
            if (err instanceof BFError) then err.sendRes(res) else res.send 500, err.message
          else
            if data?
              if options.deepObjectFilter?
                processDeepObjectFilter(data, options.deepObjectFilter)
              if data.new_cookies?
                setResCookies res, data.new_cookies
              if data.redirect?
                return res.redirect data.redirect
              if data.session?
                for key, value of data.session
                  req.session[key] = value
              # Login the new registered user
              if data?.user and (not req.user? or req.user?.IsAnonymous)
                req.user = data.user
                req.session.passport.user = data.user.ID

            if options.contentType == "application/json"
              res.send data
            else if options?.contentType? == "jsonp"
              res.jsonp data
            else
              res.contentType(options.contentType) if options?.contentType?
              res.send data.toString()

**webRedirect**

    webRedirect = (method, success_redirect, error_redirect) ->
      error_redirect ?= success_redirect
      (req, res, next) ->
        params = getRequestParams(req)

        method params, (err, data) ->
          redirect = if(err?) then error_redirect else success_redirect
          res.redirect redirect

**webPage**

    webPage = (template, method, code = 200) ->
      (req, res, next) ->
        start = new Date()
        if req.user and req.param "redirect"
          # this is the case when we logged in and we are dedirected.
          res.redirect req.param("redirect")
        if not method? and template?
          data = getRequestParams(req)
          data.__ = {} if not data.__?
          data.__ = _.extend data.__,
            template : template
          res.render template, data
        else
          params = getRequestParams(req)
          method params, (err, data) ->
            # clear the timeout if there is one.
            req.clearTimeout() if req.clearTimeout?
            if err?
              if err.message? and err.message.match /^redirect\:/

                if data.error_codes? and data.error_codes.length > 0
                  if req.flash?
                    req.flash "error_codes", data.error_codes

                url = err.message.replace("redirect:", "")
                res.redirect 301, url
                return

              if err.message? and err.message is "not-found"
                res.status 404
                if next then next() else res.send(404)
                return

              data ?= {}
              data.error_codes = data.error_codes || [ err.message ]

            # Allow the presenter set session values
            if data?.session?
              for key, value of data.session
                req.session[key] = value

            # Allow content pages specify their own template
            if data?.template? and data.template != ""
              template = data.template

            if template?

              data = {} if not data?
              data.error_codes = [] if not data.error_codes?
              data.error_codes = _.union(data.error_codes, params.error_codes) if params.error_codes?
              data.pageparams  = params
              data.user = req.user if req.user? and not data.user?
              data.__ = {} if not data.__?
              data.__ = _.extend data.__,
                template : template
                path: req.path
                cookies: req.cookies
              res.status(code)
              res.render template, data
            else
              res.send data

            end = new Date()


**memoryCache**


    memoize = (method, seconds) ->
      cache = {}

      (params, done) ->
        hash = JSON.stringify(params)
        if cache[hash]? and cache[hash].expiration > new Date()
          done null, cache[hash].result
        else
          method params, (err, res) ->
            if not err?
              cache[hash] =
                result : res
                expiration : (new Date()).setSeconds((new Date()).getSeconds() + seconds)

            done err, res

**Returns in a specific property of the params object**


    returns  = (method, property) ->
      (params, done) ->
        method params, (err, res) ->
          params[property] = res
          done err, params

**Combine with functions that only have a callback**


    mono  = (method) ->
      (params, done) ->
        method(done)


**Prepare**

    prepare = (method, first_arg) ->
      (params, done) ->
        method first_arg, done

**Fail if no result**

    fail_if_empty = (callback) ->
      (method) ->
        (err, entity) ->
          if err?
            callback err
          else if not entity?

            callback new Error("not-found")
          else
            method(err, entity)



    error_if_empty = (method) ->
      (err, entity) ->

        if not entity?
          err = new Error("not-found")
        method err, entity

    array_to_dict = (array, key, value) ->
      dict = {}
      dict[elt[key]] = elt[value] for elt in array
      dict


    acurry = (method) ->
      (n) ->
        method {}, n

    acurry_with = (method) ->
      (params) ->
        (n) ->
          method params, n



    reset_session = (method) ->
      (req, res) ->
        req.sessionID = req.param("session_id")
        method req, res


Export public methods
---------------------

    module.exports =
      error        : bfError
      toDictionary : toDictionary
      has          : has
      amap         : amap
      chain        : chain
      avoid        : avoid
      parallel     : parallel
      csv          : csv
      webService   : webService
      webPage      : webPage
      webPagePost  : webPagePost
      sendFile  : sendFile
      webRedirect  : webRedirect
      memoize      : memoize
      nothing      : nothing
      returns      : returns
      mono         : mono
      prepare      : prepare
      fail_if_empty: fail_if_empty
      error_if_empty: error_if_empty
      array_to_dict: array_to_dict
      acurry:        acurry
      acurry_with:   acurry_with
      resetSession:  reset_session
      getRequestParams: getRequestParams
