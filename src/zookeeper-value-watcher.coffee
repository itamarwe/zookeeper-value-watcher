EventEmitter = require 'eventemitter3'
Exception = require('node-zookeeper-client').Exception

class ZkValueWatcher extends EventEmitter
    module.exports = ZkValueWatcher

    constructor: (@zk, @path, @transformer)->
      @transformer = @transformer || (val)-> return val

      @ready = false
      @expired = false

      unless @zk?
        throw new Error "Must provide ZK"
      unless @path?
        throw new Error "Must provide path to watch"

      @zk.on 'expired', =>
        @expired = true

      if @zk.connected
        return @_updateAndWatchValue()

      @zk.on 'connected', =>
        if @expired
          @expired = false
          @_updateAndWatchValue()

    get: =>
      return @value

    _updateAndWatchValue: =>
      @zk.client.getData @path, @_eventHandler, (err, data)=>
        if err?.getCode()==Exception.NO_NODE
          @_watchExistance()
        else if err
          return console.error err

        @value = @transformer data
        event = unless @ready then 'ready' else 'updated'
        @ready = true
        @emit event, @get()

    _watchExistance: =>
      @zk.client.exists @path, @_eventHandler, (err, exists)=>
        if err?
          console.error "Error getting exist for #{@path}"
          return console.error err
        if exists
          @_updateAndWatchValue()

    _eventHandler: =>
      @_updateAndWatchValue()
