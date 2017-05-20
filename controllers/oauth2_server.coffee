config         = require 'config'
oauth2orize    = require 'oauth2orize'
oauth2server   = oauth2orize.createServer()
authentication = require "./authentication"
access_token_c = require "./access_token"

allowed_grant_types = [
  'password'
  'refresh_token'
  'registration'
]

# oauth2 server methods
oauth2server.serializeClient (client, done) ->
  done null, client._id

oauth2server.deserializeClient (id, done) ->
  client = config.web?.api?.clients?[id]
  if not client?
    return done "Client not found"
  else
    return done null, client

oauth2server.exchange oauth2orize.exchange.password (client, username, password, scope, done) ->
  if scope?
    try
      scope = JSON.parse scope
    catch
      scope = undefined

  authentication.login { username, password, scope }, (err, customer) ->
    return done(null, true, { error: { code : err.code, message: err.message } }) if err?
    return done(null, false) if not customer? or not customer
    access_token_c.generateAccessToken { user: customer, client }, done


oauth2server.exchange oauth2orize.exchange.refreshToken (client, refreshToken, scope, done) ->
  access_token_c.generateAccessTokenFromRefreshToken {client, refreshToken}, (err, accessToken, refreshToken) ->
    # should double check agains the client
    return done(err) if (err)
    return done(null, false) unless accessToken?
    # should send the token expiration to the client here
    done null, accessToken, refreshToken


check_grant_type = (req, res, next) ->
  grant_type = req.body.grant_type
  if grant_type not in allowed_grant_types
    return res.status(401).send()
  else
    token_handler = oauth2server.token()
    return token_handler req, res, next

###
Token endpoint

`token` middleware handles client requests to exchange authorization grants
for access tokens.  Based on the grant type being exchanged, the above
exchange middleware will be invoked to handle the request.  Clients must
authenticate when making requests to this endpoint.
###
token = [
  authentication.authClient(),
  check_grant_type,
  oauth2server.errorHandler()
]

module.exports = {
  token
}
