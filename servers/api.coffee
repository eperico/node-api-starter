cluster      = require 'cluster'
control      = require 'strong-cluster-control'
server       = require './server'
logger       = require '../helpers/logger'


if process.env.NODE_ENV is "production"
  control.start(size: control.CPUS).on 'error', (err) ->
    logger.error(err)

  control.on 'startWorker', (w) ->
    logger.info 'start worker', w.id

  if cluster.isWorker
    server.init
      root: 'api'
      root_path: __dirname
else
  server.init
    root: 'api'
    root_path: __dirname
