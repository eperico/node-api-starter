bodyParser    = require 'body-parser'
config        = require 'config'
cookieParser  = require 'cookie-parser'
express       = require 'express'
helmet        = require 'helmet'
moment        = require 'moment-timezone'
mongoose      = require 'mongoose'
# session       = require 'express-session'
# MongoStore    = require('connect-mongo')(session)
passport      = require 'passport'

api_auth      = require '../controllers/authentication'
logger        = require '../helpers/logger'


process.env.TZ = 'Australia/Sydney'
moment.tz.setDefault process.env.TZ


if config.database?.connection?
  logger.info "Connecting to #{config.database.connection}"
  options = { server: { auto_reconnect: true, socketOptions: { keepAlive: 1, connectTimeoutMS: 30000 } } }
  mongoose.connect config.database.connection, options

  mongoose.connection.on 'connected', ->
  mongoose.connection.on 'error', (err) ->
    logger.warn "Mongoose default connection error: ", err
    mongoose.connect config.database.connection, options

  mongoose.connection.on 'disconnected', ->
    logger.info 'Mongoose default connection disconnected'


init = ({ root, root_path }) ->
  global.__root_path = root_path

  passport.serializeUser   api_auth.serializeUser
  passport.deserializeUser api_auth.deserializeUser

  app  = express()
  app.use helmet()
  app.use express.static("#{root_path}/../public/#{root}")
  app.use express.static("#{root_path}/../public/")


  # Log correctly uncaught exception
  process.on 'uncaughtException', (er) ->
    if er?.stack?
      logger.error(moment().format("DD/MM/YYYY - HH:MM:SS"))
      logger.error(er.stack)
    else if er?
      logger.error(moment().format("DD/MM/YYYY - HH:MM:SS"))
      logger.error(er)

  process.on 'SIGINT', -> process.exit()

  app.use cookieParser()
  app.use bodyParser.urlencoded({ limit: '500mb', extended: true })
  app.use bodyParser.json()

  # if config.web[root].session_database?
  #   logger.info "Start session with #{config.web[root].session_database}"
  #
  #   cookie_config = { maxAge: 15 * 24 * 60 * 60 * 1000 }
  #   if config?.web[root]?.cookie_domain?
  #     logger.info "setup cooking domain to ",
  #     cookie_config.domain = config.web[root].cookie_domain
  #
  #   app.use session
  #     cookie:
  #       maxAge: 15 * 24 * 60 * 60 * 1000
  #       secure: false
  #     secret: config.web[root].session_secret
  #     store: new MongoStore url: config.web[root].session_database
  #
  #   app.use passport.initialize()

  app.locals.config        = require 'config'
  app.locals.moment        = require 'moment'
  app.locals._             = require 'underscore'

  # enable CORS
  app.all '*', (req, res, next) ->
    origins = if config?.api?.allowed_domain? then config.api.allowed_domain else "*"
    # logger.info "allow-origin", origins
    res.header "Access-Control-Allow-Origin", origins
    res.header "Access-Control-Allow-Methods", "GET, POST, OPTIONS, PUT, PATCH, DELETE, OPTIONS"
    res.header "Access-Control-Allow-Headers", "X-Requested-With,content-type,Authorization"
    res.header "Access-Control-Allow-Credentials", true

    res.locals.sessionID = req.sessionID
    if req.method is 'OPTIONS' then return res.sendStatus 200
    next()

  app = (require "#{root_path}/../routers/#{root}").applyTo app

  port = config.web[root].port
  app.listen port
  logger.info "Server fork started on port #{port}, #{new Date()}"
  app

module.exports = {
  init
}
