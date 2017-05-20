mongoose = require 'mongoose'
utils    = require './utils'
config   = require 'config'
crypto   = require 'crypto'


Customer = new mongoose.Schema
  identifier: String
  first_name: String
  last_name: String
  email: String
  password: String
  phone: String
  dates: utils.Dates

  access_token :
    token :
      type: String
    expiry :
      type: Date

  refresh_token :
    token :
      type: String
    expiry :
      type: Date


Customer.index { email : 1 }
Customer.index { identifier : 1 }
Customer.index { "dates.created": 1 }
Customer.index { "password_reset.token": 1 }

Customer.methods.hash_password = () ->
  shasum = crypto.createHash('sha256')
  shasum.update(@password + config.security.customer_hash)
  hash = shasum.digest('hex').toUpperCase()
  @password = hash

Customer.methods.validate_password = (password, done) ->
  shasum = crypto.createHash('sha256')
  shasum.update(password + config.security.customer_hash)
  hash = shasum.digest('hex').toUpperCase()
  if @password isnt hash.toString()
    done new Error("invalid password")
  else

module.exports = mongoose.model "customer", Customer
