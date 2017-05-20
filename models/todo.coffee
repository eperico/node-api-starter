mongoose = require 'mongoose'
utils    = require './utils'

Todo = new mongoose.Schema
  title: String
  description: String
  dates: utils.Dates

Todo.index { "dates.created": -1 }

module.exports = mongoose.model "todo", Todo
