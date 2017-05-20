async     = require 'async'
moment    = require 'moment-timezone'
mongoose  = require 'mongoose'
Customer  = require '../models/customer'


generateAccessTokenFromRefreshToken = ({client, refreshToken}, done) ->
  async.waterfall [
    (n) ->
      Customer.findOne {"refresh_token.token" : refreshToken}, n
    (user, n) ->
      return n() unless user?
      if user.refresh_token.expiry.getTime() < new Date().getTime()
        n("access_token_expired" , null)
      else
        generateAccessToken { user, client }, n
  ], done


# gets an access token for the client/user pair, or creates it if it doesn't exist
generateAccessToken = ({user, client, options}, done) ->
  if user.access_token?.token? and user.access_token.expiry > new Date() and not options?.forceNewToken
    done null, user.access_token.token, user.refresh_token.token
  else
    accessToken = new Buffer(mongoose.Types.ObjectId().toString()).toString('base64')
    user.access_token =
      token: accessToken
      expiry: moment().add("hours", client.access_token_expiry).toDate()

    if !user.refresh_token?.token?
      refreshToken = new Buffer(mongoose.Types.ObjectId().toString()).toString('base64')
      user.refresh_token =
        token: refreshToken
        expiry: moment().add("days", client.refresh_token_expiry).toDate()
    else
      refreshToken = user.refresh_token?.token
      user.refresh_token.expiry = moment().add("days", client.refresh_token_expiry).toDate()

    user.save -> done null, accessToken, refreshToken


module.exports = {
  generateAccessToken
  generateAccessTokenFromRefreshToken

}
