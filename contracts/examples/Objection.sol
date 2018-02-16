pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";
import "../objections/Parameter.sol";
import "../votes/BinaryBallot.sol";


/**
 * @title Token
 * @dev dummy token as a way to weigh votes.
 */
contract Token is StandardToken {
    string public name = "Token";
    string public symbol = "T";
    uint8 public decimals = 18;

    // 100 dummy tokens
    function Token(address initialAccount, uint256 totalSupply) public {
        totalSupply = 100 * 10 ** uint256(decimals);
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

    // voting indicates if objection is in the works
    bool public voting;
    uint public suggested;  // only has meaning when voting is true

    // event to indicate the modification of a parameter
    event Modification(address indexed parameter, uint newValue);

    modifier whenVotingIs(bool state) {
        require(state == voting);
        _;
    }

    function Objectionable(bytes32 description, uint initial, address _token) public {
        // initialize our parameter and the token we will weigh our votes with
        param = new Parameter(description, initial);
        token = _token;
    }

    /**
     * @dev launch a new objection if none is already there.
     * This will deploy a new binary voting contract and record its address.
     */
    function object(uint suggestedValue) whenVotingIs(false) public returns (bool) {
        voting = true;
        suggested = suggestedValue;

        MajorityBallot ball = new MajorityBallot(param.description(), 1 minutes, token);
        ballot = address(ball);
        return true;
    }

    /**
     * @dev execute objection if the vote indicates a victory.
     * Calling `execute` will publish an event to advertise the modification of
     * our parameter.
     */
    function execute() whenVotingIs(true) public returns (bool) {
        voting = false;

        // if the vote is not over, this will throw (through a `require` call)
        if (MajorityBallot(ballot).elect()) {
            // assert modification was successful & publish event
            require(param.set(suggested));
            Modification(address(param), suggested);
        }

        ballot = address(0);
    }
}
