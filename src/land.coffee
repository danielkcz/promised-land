"use strict"

Promise = require 'bluebird'
Bacon = require 'baconjs'
EventEmitter = require('eventemitter2').EventEmitter2

PromisedLand = ->
	# Base object is based on eventemitter prototype
	land = Object.create EventEmitter.prototype

	# Store the constructor 
	land.constructor = PromisedLand

	# Initialize emitter
	EventEmitter.call land, {wildcard: false}
	
	# List of promises created in the past
	promises = Object.create null

	# Purpose of this method is to return Promise, that is following
	# first emit of given event. Any subsequent emits are ignored
	# by this. Obvious use is one time event used to track some 
	# (usually async) state in the application.
	land.promise = (ev, customEmitter) ->
		unless arguments.length and ev isnt null
			return Promise.reject new TypeError 'missing event argument for promise call'

		# With customEmitter specified, promise is following event from there
		if typeof customEmitter is "object"
			unless typeof customEmitter.once is "function"
				throw new TypeError 'specified emitter is missing once method'
			return new Promise (resolve, reject) ->
				customEmitter.once ev, (val) -> promiseResolver val, resolve, reject

		# Promise was requested in the past, return it immediately
		return promises[ev] if promises[ev]

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