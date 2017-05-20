_ = require 'underscore'

apply_route = (app, http_method, route, presenter_method) ->
  if _.isArray presenter_method
    app[http_method] route, presenter_method[0], presenter_method[1]
  else
    app[http_method] route, presenter_method
  app


applyTo = (route_definitions) ->
  (app) ->
    for definition in route_definitions
      for http_method, routes of definition
        for route, presenter_method of routes
          # We need a closure here, for the method definition that overrides params in migration routes
          # Otherwise presenter_method is not the good value when a call is made
          do (presenter_method) ->
            apply_route app, http_method, route, presenter_method

    app

module.exports = {
  applyTo
}
