var Objectionable = artifacts.require('Objectionable');
var DummyToken = artifacts.require('DummyToken');
var Parameter = artifacts.require('Parameter');
var MajorityBallot = artifacts.require('MajorityBallot');

contract('Objectionable', function(accounts) {
    var token, objectionable, ballot, param;
    const suggested = 5;

    before(async function() {
        // deploy token with which we will weigh votes
        token = await DummyToken.new(accounts[0], 100);
        for (acc of accounts) {
            await token.transfer(acc, 10 ** 18, {from: accounts[0]});
        }

        // deploy objectionable contract
        objectionable = await Objectionable.new('parameter', 0, token.address);
    });

    it('should distribute tokens without fault', async function() {
        balance = await token.balanceOf(accounts[1]);
        assert.equal(balance.valueOf(), 10 ** 18, 'wrong balance');
    });

    it('should record the right token address', async function() {
        tokenaddr = await objectionable.token.call();
        assert.equal(tokenaddr, token.address, 'wrong token address recorded');
    });

    it('should own its parameter', async function() {
        param = Parameter.at(await objectionable.param.call());
        owner = await param.owner.call();
        assert.equal(objectionable.address, owner, 'objectionable contract does not own parameter');
    });

    it('should `object` and effect the consequences successfully', async function() {
        success = await objectionable.object(suggested, {from: accounts[0]});
        assert(success, 'could not object');
        assert(await objectionable.voting.call(), 'did not set voting to true');
        ballot = MajorityBallot.at(await objectionable.ballot.call());
    });

    it('should allow votes during the allocated period', async function() {
        // approve token transfer so that accounts[1] can vote
        success = await token.approve(ballot.address, 5 * 10 ** 17, {from: accounts[1]});
        assert(success, 'could not approve transfer although balance is high enough');
        await ballot.vote(true, {from: accounts[1]});
    });

    it('should allow executing when the vote deadline is passed', async function() {
        await new Promise(resolve => setTimeout(resolve, 2000));
        await objectionable.execute();
        assert.equal(await param.get(), suggested);
    });
});
