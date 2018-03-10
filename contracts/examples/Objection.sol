/** Implementation of the Objection contract.
 *
 * An objection is used to control the value of a parameter (see Parameter.sol)
 * through a voting mechanism.
 *
 * The flow goes as follows:
 *  1. Someone suggests a new valule for the parameter through the `object`
 *     method,
 *  2. If nobody disputes the suggestion, it is executable after a delay. Else,
 *     a vote is launched.
 *  3. If the vote indicates a yea, the modification is executable, else it is
 *     discarded.
 */

pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../objections/Parameter.sol";
import "../votes/BinaryBallot.sol";


/**
 * @title Token
 * @dev dummy token as a way to weigh votes.
 */
contract DummyToken is StandardToken {
    string public name = "Token";
    string public symbol = "T";
    uint8 public decimals = 18;

    // 100 dummy tokens
    function DummyToken(address initialAccount, uint256 _totalSupply) public {
        uint totalSupply = _totalSupply * 10 ** uint256(decimals);
        balances[initialAccount] = totalSupply;
    }
}

/**
 * @title Objectionable
 * @dev handles a parameter contract by orchestrating its modifications (`set`
 * calls) through a token weighted binary vote.
 */
contract Objectionable {
    // references to other contracts
    Parameter public param;
    address public token;
    address public ballot;

    /**
     * @dev see state transition functions below.
     */
    enum State {
        Waiting,
        Objecting,
        Disputing
    }

    State public state = State.Waiting;

    // meaning depends on state
    uint public delay = 3 days;
    uint public suggested;
    uint public deadline;

    // event to indicate the modification of a parameter
    event Modification(address indexed parameter, uint newValue);
    event Objection(address indexed objector, uint suggestedValue);
    event Dispute(address indexed disputor);

    modifier when(State _state) {
        require(state == _state);
        _;
    }

    modifier beforeDeadline {
        require(now <= deadline);
        _;
    }

    modifier afterDeadline {
        require(now > deadline);
        _;
    }

    modifier beforeExpiration {
        require(now <= deadline + delay);
        _;
    }

    modifier afterExpiration {
        require(now > deadline + delay);
        _;
    }

    function Objectionable(bytes32 description, uint initial, address _token) public {
        // initialize our parameter and the token we will weigh our votes with
        param = new Parameter(description, initial);
        token = _token;
    }

    /**
     * @dev reset the contract's state to `State.Waiting` after expiration of
     * the state transition function's validity.
     */
    function reset() afterExpiration() public returns (bool) {
        state = State.Waiting;
        return true;
    }

    /**
     * @dev launch a new objection, suggesting a new value for the concerned
     * parameter.
     */
    function object(uint suggestedValue) when(State.Waiting) public returns (bool) {
        state = State.Objecting;
        suggested = suggestedValue;
        deadline = now + delay;

        Objection(msg.sender, suggestedValue);
        return true;
    }

    /**
     * @dev dispute the current objection by starting a vote whose outcome will
     * decide on whether the objection's suggestion is adopted.
     */
    function dispute() when(State.Objecting) beforeDeadline() public returns (bool) {
        state = State.Disputing;
        deadline = now + delay;  // voting deadline

        Dispute(msg.sender);
        MajorityBallot ball = new MajorityBallot(param.description(), delay, token);
        ballot = address(ball);
        return true;
    }

    /**
     * @dev executes the suggested change of an objection without vote as no
     * dispute was launched during the allowed period.
     */
    function executeWithoutVote() when(State.Objecting) afterDeadline() beforeExpiration() public returns (bool) {
        state = State.Waiting;
        require(param.set(suggested));
        Modification(address(param), suggested);
        return true;
    }

    /**
     * @dev check the results of a vote following a dispute ; whether a change
     * in the parameter's value is effected depends in the results of said vote.
     */
    function checkResults() when(State.Disputing) afterDeadline() beforeExpiration() public returns (bool) {
        state = State.Waiting;
        if (MajorityBallot(ballot).elect()) {
            require(param.set(suggested));
            Modification(address(param), suggested);
        }
    }
}
