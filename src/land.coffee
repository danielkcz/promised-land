Promise = require 'bluebird'
Bacon = require 'baconjs'
EventEmitter = require('eventemitter2').EventEmitter2

PromisedLand = ->
	# Base object is based on eventemitter prototype
	land = Object.create EventEmitter.prototype

	# Store the constructor 
	land.constructor = PromisedLand

	# Pass in the configuration object
	EventEmitter.call land, {wildcard: false}
	
	# List of promises created in the past
	promises = Object.create null

	# Purpose of this method is to return Promise, that is following
	# first emit of given event. Any subsequent emits are ignored
	# by this. Obvious use is one time event used to track some 
	# (usually async) state in the application.
	land.promise = (ev) ->
		unless arguments.length and ev isnt null
			return Promise.reject new TypeError 'missing event argument'

		# Promise was requested in the past, return it immediately
		return promises[ev] if promises[ev]

		# When promise is requested before event was emitted
		# new one has to be created and attach handler to wait for the vent
		return promises[ev] = new Promise (resolve, reject) ->
			land.once ev, (val) -> promiseResolver val, resolve, reject

	land.promiseAll = (evs...) ->
		return Promise.all evs.map (ev) -> land.promise(ev)

	# Decide if promise should be resolved or rejected based on value
	promiseResolver = (value, resolve, reject) ->
		if value instanceof Error
			reject value
		else
			resolve value

	# Very basic support for the streams (FRP)
	land.stream = (ev) ->
		return Bacon.fromEventTarget this, ev

	$emit = land.emit
	land.emit = (ev) ->
		unless promises[ev]
			# Multiple event arguments should be packed into array
			# as Promise can be resolved only with one value
			value = if arguments.length > 2
				Array.prototype.slice.call arguments, 1
			else
				arguments[1]

			# Create new promise, that gets resolved right away
			promises[ev] = new Promise promiseResolver.bind null, value

		# Call original emit			
		$emit.apply land, arguments

	return land

# Module returns default instance to be used globally
module.exports = PromisedLand()

# Export function to create separate promised land for custom use
module.exports.create = ->
	PromisedLand()

module.exports.Promise = Promise
module.exports.Bacon = Bacon