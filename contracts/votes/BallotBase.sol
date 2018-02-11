/** Abstract Contracts for ballots
 *
 * Abstract Contracts which differentiate between two branches of voting theory:
 *   - Binary voting (2 alternatives)
 *   - Ranked voting (3+ alternatives)
 *
 * Other contracts are implemented which allow for a vote weighting mechanism.
 */

pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";


// Choose between two alternatives
contract BinaryBallotBase {
    /* EVENTS */
    event Vote;
    event Elect;

    /* METHODS */
    function vote(bool approval) public;
    function elect() public returns (bool approval);
}

// Choose between 3 or more alternatives
contract RankedBallotBase {
    /* EVENTS */
    event Vote;
    event Elect;

    /* METHODS */
    function vote(uint8[] ranking) public;
    function elect() public returns (uint winnerId);
}

// Weight votes according to some method
contract WeightedBallotBase {
    // this mapping is a memory for withdrawals
    mapping(address => uint) weights;

    // can have side effects to enforce single vote
    function ensureWeight(address voter) internal returns (uint weight);
}

// modifiers to restrict method access according to a deadline
contract Deadlined {
    /* STATE */
    uint public deadline;
    bool public ended;

    /* MODIFIERS */
    modifier onlyBefore() {
        require(now < deadline);
        _;
    }

    modifier onlyAfter() {
        require(now >= deadline);
        _;
    }
}

// Inheriting contracts may use the provided methods to weigh votes
// votes are weighed by blocking voters' tokens
// this contract allows multiple votes, but votes may not be taken back
contract TokenWeighted is WeightedBallotBase, Deadlined {
    ERC20 public token;

    function TokenWeighted(address _token) public {
        token = ERC20(_token);
    }

    function ensureWeight(address voter) internal returns (uint weight) {
        // get voter's weight through interaction - Weight contract should be safe
        weight = token.allowance(voter, address(this));

        // check voter can vote & vote is legal
        require(weight > 0);
        require(token.transferFrom(voter, address(this), weight));

        // remember weight for withdrawals
        // "+=" in case this is not the voter's first vote
        // inheriting contracts must enforce single votes if they need to
        weights[msg.sender] += weight;
        return weight;
    }

    // this should be protected from reentrancy
    function withdraw() public onlyAfter {
        // check & effects
        uint weight = weights[msg.sender];
        weights[msg.sender] = 0;

        // interaction
        bool success = token.approve(msg.sender, weight);
        require(success);
    }
}
