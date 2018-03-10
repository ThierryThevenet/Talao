import increaseTime from "./helpers/increaseTime";
import expectThrow from "./helpers/expectThrow";

var Objectionable = artifacts.require('Objectionable');
var DummyToken = artifacts.require('DummyToken');
var Parameter = artifacts.require('Parameter');
var MajorityBallot = artifacts.require('MajorityBallot');

contract('Objectionable', function(accounts) {
  var token, objectionable, param, ballot;
  const [totalSupply, partial, vote] = [100, 10, 1];
  var suggested = 1;
  const days = 60**2 * 24;

  before(async function() {
    // deploy token with which we will weigh votes
    token = await DummyToken.new(accounts[0], totalSupply);
      for (let acc of accounts) {
        await token.transfer(acc, partial * 10**18, {from: accounts[0]});
      }

    // deploy objectionable contract
    objectionable = await Objectionable.new('parameter', 0, token.address);
  });

  // contract deployment tests & set up
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


  // function to reset contract to waiting state
  let reset = async function() {
    await increaseTime(7 * days);  // expiration == 6 days
    let success = await objectionable.reset();
    assert(success, 'could not reset');
    let state = await objectionable.state.call();
    assert.equal(state.valueOf(), 0, 'should be waiting');
  };

  // function to set contract to objecting state
  let object = async function() {
    let success = await objectionable.object(++suggested);
    assert(success, 'could not object');
    let state = await objectionable.state.call();
    assert.equal(state.valueOf(), 1, 'should be objecting');
  };

  // function to set contract to disputing state
  let dispute = async function() {
    await object();
    let success = await objectionable.dispute();
    assert(success, 'could not dispute');
    let state = await objectionable.state.call();
    assert.equal(state.valueOf(), 2, 'should be disputing');
  };

  // expect throws on all protocols
  let describeOthers = function(protocols) {
    describe('other methods...', function() {
      for (let protocol of protocols) {
        it('should fail to call ' + protocol, async function() {
          await expectThrow(objectionable[protocol]());
          await increaseTime(4 * days);  // see after delay
          await expectThrow(objectionable[protocol]());
        });
      }
    });
  };

  describe('state: Waiting', function() {
    afterEach(reset);

    describe('#object', function() {
      it('should object successfully whenever', object);
    });

    describeOthers(['dispute', 'executeWithoutVote', 'checkResults']);
  });

  describe('state: Objecting', function() {
    beforeEach(object);
    afterEach(reset);

    describe('#executeWithoutVote', function() {
      it('should fail to execute when (now < delay)', async function() {
        await expectThrow(objectionable.executeWithoutVote());
      });
  
      it('should execute successfully when (delay < now < expiration)', async function() {
        await increaseTime(4 * days);  // delay == 3 days
        let success = await objectionable.executeWithoutVote();
        assert(success, 'should execute successfully');
        assert.equal((await param.get()).valueOf(), suggested, 'should change param\'s value to suggested');
      });
  
      it('should fail to execute when (expiration < now)', async function() {
        // expect a throw on a late execution
        await increaseTime(7 * days);  // time += 7 days -- expiration == 6 days
        await expectThrow(objectionable.executeWithoutVote());
      });
    });

    describe('#dispute', function() {
      it('should dispute successfully when (now < delay)', async function() {
        // dispute, check success & change of state
        let success = await objectionable.dispute();
        assert(success, 'could not dispute');
        let state = await objectionable.state.call();
        assert.equal(state.valueOf(), 2, 'state should be Disputing');
      });

      it('should fail to dispute when (delay < now)', async function() {
        await increaseTime(4 * days);
        await expectThrow(objectionable.dispute());
      });
    });

    describeOthers(['object', 'checkResults', 'reset']);
  });

  describe('state: Disputing', function() {
    beforeEach(dispute);
    afterEach(reset);

    describe('#checkResults', function() {
      it('should execute results if yea when (delay < now < expiration)', async function() {
        let ballotaddr = await objectionable.ballot.call();
        let ballot = MajorityBallot.at(ballotaddr);

        await token.approve(ballot.address, vote, {from: accounts[0]});
        await ballot.vote(true, {from: accounts[0]});  // yea

        await increaseTime(4 * days);
        await objectionable.checkResults();
        let val = await param.get();
        assert.equal(val.valueOf(), suggested, 'parameter did not change');
      });
    });
  });
});
