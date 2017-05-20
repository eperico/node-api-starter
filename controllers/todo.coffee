Todo    = require '../models/todo'
logger  = require '../helpers/logger'

get_all = (params, done) ->
  logger.info "get all todos"
  # Todo.find {}, done
  # return fake data here
  list = [
    { title: 'Todo1', description: 'description todo 1'}
    { title: 'Todo2', description: 'description todo 2'}
    { title: 'Todo3', description: 'description todo 3'}
  ]
  done null, list


get_by_id = ({ id }, done) ->
  logger.info "get todo with id", id
  # Todo.finById id, done
  # return fake data here
  done null, { title: 'Todo2', description: 'description todo 2'}

module.exports = {
  get_all
  get_by_id
}
