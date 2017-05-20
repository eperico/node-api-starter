bf               = require '../helpers/barefoot'
router_helper    = require './helper'
auth             = require '../controllers/authentication'
oauth2server     = require '../controllers/oauth2_server'
checkAuth        = auth.authUser

presenters = {}
[
  'todo'
  'user'
].forEach (p) -> presenters[p] = require "../presenters/api/#{p}"

default_routes =
  get:
    "/":                (req, res) -> res.send "Running Node Server Starter API"

user_routes =
  get:
    "/user/me":         checkAuth bf.webService presenters.user.get_user

authentication_routes =
  post:
    "/auth/token":      oauth2server.token
    "/logout":          auth.logout

todo_routes =
  get:
    "/todos/:id?":      bf.webService presenters.todo.get_todo_list



route_definitions = [
  authentication_routes
  default_routes
  user_routes
  todo_routes
]


module.exports = {
  applyTo: router_helper.applyTo(route_definitions)
}
