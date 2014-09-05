'use strict'

PromisedLand = (opts) ->

	# If unsupported object is passed in, create own one
	unless typeof emitter?.emit is 'function'
		land = emitter = Object.create EventEmitter.prototype
		EventEmitter.call land, {wildcard: false}

	# Otherwise use emitter object as prototype
	else
		land = Object.create emitter

	land.constructor = PromisedLand

	# List of promises created so far
	promises = Object.create null

	# Purpose of this method is to return Promise, that is following
	# first emit of given event. Any subsequent emits are ignored
	# by this. Obvious use is for one time events to track some
	# (usually async) state in the application.
	land.promise = (ev) ->
		unless arguments.length and ev isnt null
			return Promise.reject new TypeError 'missing event argument for promise call'

		# Promise was requested in the past, return it immediately
		return promise if promise = promises[ev]

		# When promise is requested before event was emitted
		# new one has to be created and attach handler to wait for the event
		return promises[ev] = new Promise (resolve, reject) ->
			land.once ev, (val) -> promiseResolver val, resolve, reject

	land.promiseAll = ->
		# Get promises for string
		Array.prototype.reduce.call arguments, (list, ev) ->
			ev and list.push(land.promise ev)
			return list
		, list = []

		unless list.length
			return Promise.reject new TypeError 'no arguments given for promiseAll call'

		return Promise.all list

	# Simple convenience method to transform some event to promise
	# Supply emitter object that supports `once` or `on` method and
	# get promise back. Result of this is not stored anywhere.
	land.promiseNow = (ev, customEmitter) ->
		unless typeof customEmitter is "object"
			throw new TypeError 'missing emitter object'
		unless hasOnce = (typeof customEmitter.once is "function") and hasOn = (typeof customEmitter.on is "function")
			throw new TypeError 'specified emitter is missing once or on method'
		return new Promise (resolve, reject) ->
			handler = (val) -> promiseResolver val, resolve, reject
			if hasOnce
				customEmitter.once ev, handler
			else if hasOn
				customEmitter.on ev, handler

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
module.exports.create = (emitter) ->
	PromisedLand emitter
