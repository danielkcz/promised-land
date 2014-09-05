Land = require '../src/land'

describe 'Promised land', ->

	it 'should be an object', ->
		Land.should.be.an "object"

	it 'should have a constructor function', ->
		Land.should.have.ownProperty "constructor"
		Land.constructor.should.be.a "function"

	it 'should respond to `create` function', ->
		Land.should.respondTo "create"

	it 'should return object with same constructor property', ->
		actual = Land.create()
		actual.should.be.an "object"
		actual.should.have.ownProperty "constructor"
		actual.constructor.should.equal Land.constructor

	it 'should respond to `on` method', ->
		Land.should.respondTo "on"

	it 'should respond to `emit` method', ->
		Land.should.respondTo "emit"

	it 'should call handler upon event emit', ->
		Land.on 'test', spy = sinon.spy()
		Land.emit 'test'
		spy.should.have.been.calledOnce

	describe 'base emitter', ->

		beforeEach ->
			@emitter = new (require('eventemitter2').EventEmitter2)
			@land = Land.create @emitter

		it 'should set prototype to passed emitter object', ->
			Object.getPrototypeOf(@land).should.equal @emitter

		it 'should fulfill promise using this emitter', ->
			promise = @land.promise('test').then
			@emitter.emit 'test2'
			return promise

	describe '.promise', ->

		beforeEach ->
			@land = Land.create()

		it 'should respond to `promise` method', ->
			@land.should.respondTo "promise"

		it 'should return promise (aka thenable) object', ->
			(actual = @land.promise('test')).should.respondTo 'then'
			actual.catch? -> # Avoid error for unhandled errors

		it 'should reject promise when no event name passed in', ->
			@land.promise().should.be.rejectedWith(TypeError)

		it 'should reject promise when null passed in', ->
			@land.promise(null).should.be.rejectedWith(TypeError)

		it 'should return identical promise for the same event', ->
			expected = @land.promise 'test'
			expected.should.equal @land.promise 'test'

		it 'should fulfill promise for event emitted in the future', (done) ->
			@land.promise('test').should.become('fulfilled').notify done
			@land.emit 'test', 'fulfilled'
			@land.emit 'test', 'fulfilled2'

		it 'should fulfill promise for event emitted in the past', (done) ->
			@land.emit 'test', 'fulfilled'
			@land.promise('test').should.become('fulfilled').notify done
			@land.emit 'test', 'fulfilled2'

		it 'should fulfill promise with array containing all emitted values', ->
			expected = ["a", 1, true]
			@land.emit 'test', expected...
			@land.promise('test').then (actual) ->
				actual.should.eql expected

		it 'should reject promise when event is emitted with Error instance', ->
			@land.emit 'test', new Error('testing')
			@land.promise('test').should.be.rejectedWith Error, /testing/
			@land.emit 'test2', new TypeError('inherited')
			@land.promise('test2').should.be.rejectedWith Error, /inherited/

		describe ':: custom emitter', ->

			it 'should fulfill promise instead of internal emitter', ->
				emitter = new (require('eventemitter2').EventEmitter2)
				@land.promise('test', emitter).then ->
					throw new chai.AssertionError('promise fulfilled from internal emitter')
				@land.emit 'test'

				promise = @land.promise('test2', emitter).then
				emitter.emit 'test2'
				return promise

			it 'should throw error when missing `once` method', ->
				@land.promise.bind(null, 'test', {}).should.throw TypeError, /missing once/

			it 'should reject promise when event is emitted with Error instance', ->
				emitter = new (require('eventemitter2').EventEmitter2)
				@land.promise('test', emitter).should.be.eventually.rejectedWith TypeError, /custom/
				emitter.emit 'test', new TypeError 'error from custom emitter'

	describe '.promiseAll', ->

		Promise = require 'bluebird'

		beforeEach ->
			@land = Land.create()

		it 'should respond to `promiseAll` method', ->
			@land.should.respondTo "promiseAll"

		it 'should return promise', ->
			actual = @land.promiseAll().catch ->
			Promise.is(actual).should.be.true

		it 'should reject promise when no arguments passed in', ->
			@land.promiseAll().should.be.rejectedWith(TypeError, /no arguments given/)

		it 'should reject promise when all arguments are null', ->
			@land.promiseAll(null, null, null).should.be.rejectedWith(TypeError, /no arguments given/)

		it 'should fulfill promise when all events are emitted', ->
			@land.emit 'test1'
			@land.promiseAll('test1', 'test2', 'test3').should.be.fulfilled
			@land.emit 'test2'
			@land.emit 'test3'

		it 'should skip falsy arguments while fulfilling promise', ->
			@land.emit 'test'
			@land.promiseAll(false, null, 'test').should.be.fulfilled

		it 'should utilize Promise.all method', ->
			spy = sinon.spy Promise, 'all'
			@land.promiseAll('test')
			spy.should.have.been.calledOnce
			spy.restore()

	describe '.stream', ->

		Bacon = require 'baconjs'

		beforeEach ->
			@land = Land.create()

		it 'should respond to `stream` method', ->
			@land.should.respondTo "stream"

		it 'should return Bacon event stream', ->
			@land.stream().should.be.an.instanceof Bacon.EventStream

		it 'should create stream from passed in event', ->
			spy = sinon.spy()
			@land.stream('test').onValue spy
			@land.emit 'test'
			spy.should.have.been.calledOnce