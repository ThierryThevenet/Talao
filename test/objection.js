import increaseTime from "./helpers/increaseTime";

var Objectionable = artifacts.require('Objectionable');
var DummyToken = artifacts.require('DummyToken');
var Parameter = artifacts.require('Parameter');
var MajorityBallot = artifacts.require('MajorityBallot');

contract('Objectionable', function(accounts) {
  var token, objectionable, ballot, param;
  const [totalSupply, partial] = [100, 10];
  const suggested = 5;

  before(async function() {
    // deploy token with which we will weigh votes
    token = await DummyToken.new(accounts[0], totalSupply);
      for (let acc of accounts) {
        await token.transfer(acc, partial * 10**18, {from: accounts[0]});
      }

    // deploy objectionable contract
    objectionable = await Objectionable.new('parameter', 0, token.address);
  });

  describe('basic state initialization', function() {
    it('should distribute tokens without fault', async function() {
      let balance = await token.balanceOf(accounts[1]);
      assert.equal(balance.valueOf(), partial * 10**18, 'wrong balance');
    });

    it('should record the right token address', async function() {
      let tokenaddr = await objectionable.token.call();
      assert.equal(tokenaddr, token.address, 'wrong token address recorded');
    });

    it('should own its parameter', async function() {
      param = await objectionable.param.call();
      let parameter = Parameter.at(param);
      let owner = await parameter.owner.call();
      assert.equal(objectionable.address, owner, 'objectionable contract does not own parameter');
    });
    
    it('should be waiting', async function() {
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 0, 'state should be waiting')
    });
  });
  
  describe('objection without dispute', function() {
    it('should object successfully', async function() {
      let success = await objectionable.object(suggested, {from: accounts[0]});
      assert(success, 'could not object');
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 1, 'state should change to objecting');
    });

    it('should execute successfully after deadline & before expiration', async function() {
      await increaseTime(60 * 60 * 24 * 4);  // time += 4 days -- delay == 3 days
      let success = await objectionable.executeWithoutVote();
      assert(success, 'should execute successfully');
      let parameter = Parameter.at(param);
      assert.equal((await parameter.get()).valueOf(), suggested, 'should change param\'s value to suggested');
    });
  });
});
