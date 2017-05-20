BasicStrategy           = require('passport-http').BasicStrategy
BearerStrategy          = require('passport-http-bearer').Strategy
ClientPasswordStrategy  = require('passport-oauth2-client-password').Strategy
config                  = require 'config'
passport                = require 'passport'
logger                  = require '../helpers/logger'
Customer                = require '../models/customer'


serializeUser = (user, done) -> done null, user._id

deserializeUser = (id, done) -> Customer.findById id, done


###
Basic & Client Password strategy

The OAuth 2.0 client password authentication strategy authenticates clients
using a client ID and client secret. The strategy requires a verify callback,
which accepts those credentials and calls done providing a client.
###
clientAuthStrategy = (clientId, clientSecret, done) ->
  if config.api.clients[clientId]?.clientSecret is clientSecret
    done null, config.api.clients[clientId]
  else
    done null, false


findUserByToken = (token, done) ->
  Customer.findOne {"access_token.token": token}, (err, user) ->
    return done(err) if err?
    return done(new Error("access_token_invalid"), false) unless user?
    if new Date() > user.access_token.expiry
      user.access_token = null
      user.save () ->
        done new Error("access_token_expired")
    else
      done null, user

passport.use "clientBasic",     new BasicStrategy clientAuthStrategy
passport.use "clientPassword",  new ClientPasswordStrategy clientAuthStrategy
passport.use "bearer",          new BearerStrategy findUserByToken


authClient = -> passport.authenticate [ "clientBasic", "clientPassword" ], session: false

authUser = (method) ->
  (req, res, next) ->
    passport.authenticate("bearer", { session: false }, (err, user) ->
      # If authentication failed, user will be set to false.
      # If an exception occurred, err will be set.
      # An optional info argument will be passed, containing additional details provided by the strategy's verify callback.
      if err? or not user
        res.status 401
        res.send {error: "unauthorized"}
      else
        # log.debug "user authenticated"
        req.user = user
        method req, res
    )(req, res, next)


login = ({ username, password, scope }, done) ->
  logger.debug "login: ", username, scope
  Customer.getAll { where: email: username }, (err, users) ->
    errMsg = "Invalid login or password. Please, try again."
    return done new Error(errMsg) if err? or not users? or users.length is 0
    return done new Error(errMsg) if users.length > 1 # should never happen here, registration must validate non duplicate
    user = users[0]
    user.validate_password password, (err, valid_pwd) ->
      if not valid_pwd
        # do not give to much information to the user about what's wrong
        done new Error(errMsg)
      else
        done null, user


logout = (req, res) ->
  req.logout()
  # log.debug "user logged out"
  res.send { success: true }


return module.exports = {
  authUser
  authClient
  login
  logout
  serializeUser
  deserializeUser
}
