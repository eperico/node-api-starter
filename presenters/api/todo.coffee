todo_controller = require '../../controllers/todo'


get_todo_list = (params, done) ->
  { id } = params
  if params.id?
    todo_controller.get_by_id {id}, done
  else
    todo_controller.get_all params, done


module.exports = {
  get_todo_list
}
