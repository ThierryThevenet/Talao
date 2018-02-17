import increaseTime from "./helpers/increaseTime";
import expectThrow from "./helpers/expectThrow";

var Objectionable = artifacts.require('Objectionable');
var DummyToken = artifacts.require('DummyToken');
var Parameter = artifacts.require('Parameter');
var MajorityBallot = artifacts.require('MajorityBallot');

contract('Objectionable', function(accounts) {
  var token, objectionable, ballot, param;
  const [totalSupply, partial, vote] = [100, 10, 1];
  var suggested = 1;

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
      param = Parameter.at(await objectionable.param.call());
      let owner = await param.owner.call();
      assert.equal(objectionable.address, owner, 'objectionable contract does not own parameter');
    });
    
    it('should be waiting', async function() {
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 0, 'state should be waiting')
    });
  });
  
  describe('different objection paths', function() {
    // object with new suggestion before each new path
    beforeEach(async function() {
      let success = await objectionable.object(++suggested, {from: accounts[0]});
      assert(success, 'could not object');
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 1, 'state should change to objecting');
    });

    // assert contract is in waiting state at the end of each path
    afterEach(async function() {
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 0, 'should be waiting');
    });

    // flow: object without dispute, confirm before expiration
    it('should execute successfully after deadline & before expiration', async function() {
      await increaseTime(60 * 60 * 24 * 4);  // time += 4 days -- delay == 3 days
      let success = await objectionable.executeWithoutVote();
      assert(success, 'should execute successfully');
      assert.equal((await param.get()).valueOf(), suggested, 'should change param\'s value to suggested');
    });

    // flow: object without dispute, confirm after expiration
    it('should be rejected after expiration', async function() {
      // expect a throw on a late execution
      await increaseTime(60 * 60 * 24 * 7);  // time += 7 days -- expiration == 6 days
      await expectThrow(objectionable.executeWithoutVote({from: accounts[0]}));

      // reset at the end of our flow
      let success = await objectionable.reset({from: accounts[4]});
      assert(success, 'should reset');
    });

    // flow: object with dispute, win vote, confirm before expiration
    it('change to the suggested value upon a ballot victory', async function() {
      let success = await objectionable.dispute({from: accounts[1]});
      assert(success, 'should dispute successfully');

      // expect a change in state
      let state = await objectionable.state.call();
      assert.equal(state.valueOf(), 2, 'should be disputing');
      ballot = MajorityBallot.at(await objectionable.ballot.call());

      // schedule vote(s)
      let acc = accounts[2];
      await token.approve(ballot.address, vote * (10**18), {from: acc});
      await ballot.vote(true, {from: acc});

      // check vote result & execute
      await increaseTime(60 * 60 * 24 * 4);  // deadline == 3 days
      await objectionable.checkResults({from: accounts[0]});
      assert.equal((await param.get()).valueOf(), suggested, 'should change param\'s value to suggested');
    });
  });
});
