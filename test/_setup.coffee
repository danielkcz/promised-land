global.chai = require 'chai'
global.sinon = require 'sinon'

chai.should()
chai.use require 'sinon-chai'
chai.use require 'chai-as-promised'