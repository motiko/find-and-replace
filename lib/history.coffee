_ = require 'underscore-plus'
{Emitter} = require 'atom'

HISTORY_MAX = 25

class History
  constructor: (@items=[]) ->
    @emitter = new Emitter
    @length = @items.length

  onDidAddItem: (callback) ->
    @emitter.on 'did-add-item', callback

  serialize: ->
    @items[-HISTORY_MAX..]

  getLast: ->
    _.last(@items)

  getAtIndex: (index) ->
    @items[index]

  getFiltered: (filterBy, fromIndex) ->
    @items.map((text, index) -> {originalIndex: index, text: text})
          .filter((item) -> item.text.search(filterBy) > -1 and item.originalIndex <= fromIndex)

  add: (text) ->
    @items.push(text)
    @length = @items.length
    @emitter.emit 'did-add-item', text

  clear: ->
    @items = []
    @length = 0

# Adds the ability to cycle through history
class HistoryCycler

  # * `buffer` an {Editor} instance to attach the cycler to
  # * `history` a {History} object
  constructor: (@buffer, @history) ->
    @index = @history.length
    @history.onDidAddItem (text) =>
      @buffer.setText(text) if text isnt @buffer.getText()
    @buffer.onDidChange () =>
      if @buffer.getText() is ''
        @scratch = ''
        console.log(0)

  addEditorElement: (editorElement) ->
    atom.commands.add editorElement,
      'core:move-up': => @previous()
      'core:move-down': => @next()

  previous: ->
    if @history.length is 0 or (@atLastItem() and @buffer.getText() isnt @history.getLast())
      @scratch = @buffer.getText()
    else if @index is @history.length
      @scratch = @buffer.getText()
      @index--
    else if @index > 0
      @index--

    if @scratch and @scratch isnt ''
      filtered = @history.getFiltered(@scratch, @index)
      if filtered.length > 0
        obj = filtered.pop()
        @index = obj.originalIndex
      else
        @index++

    @buffer.setText @history.getAtIndex(@index) ? ''

  next: ->
    if @index < @history.length - 1
      @index++
      item = @history.getAtIndex(@index)
    else if @scratch
      item = @scratch
    else
      item = ''

    @buffer.setText item

  atLastItem: ->
    @index is @history.length - 1

  store: ->
    text = @buffer.getText()
    return if not text or text is @history.getLast()
    @scratch = null
    @history.add(text)
    @index = @history.length - 1

module.exports = {History, HistoryCycler}
