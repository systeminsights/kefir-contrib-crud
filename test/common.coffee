chai = require 'chai'
chaiImmutable = require 'chai-immutable'
chaiAsPromised = require 'chai-as-promised'

chai.use(chaiImmutable)
chai.use(chaiAsPromised)

global.expect = chai.expect

