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

	describe '.promise', ->

		Promise = require 'bluebird'

		beforeEach ->
			@land = Land.create()

		it 'should respond to `promise` method', ->
			@land.should.respondTo "promise"

		it 'should return promise', ->
			actual = @land.promise().catch ->
			Promise.is(actual).should.be.true

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