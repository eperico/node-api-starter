winston = require 'winston'

logger = new (winston.Logger)
  transports: [
    new (winston.transports.Console)({
      timestamp: true
      level: 'debug'
      humanReadableUnhandledException: true
      colorize: true
      prettyPrint: (meta) ->
        JSON.stringify meta, null, 2
    })
  ]

module.exports = {
  debug: logger.debug
  info:  logger.info
  warn:  logger.warn
  error: logger.error
}
