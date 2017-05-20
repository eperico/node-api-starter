
get_user = ({ user }, done) ->
  return new Error("Unable to found user profile") unless user?
  done null, user


return module.exports = {
  get_user
}
