pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


/**
 * @title ParameterBase
 * @dev Base contract for handling data. May later generalize to types other
 * than uint.
 */
contract ParameterBase {
    function get() public view returns (uint);
    function set(uint _new) public returns (bool);
}

/**
 * @title Parameter
 * @dev Ownable parameter which implements the ParameterBase abstract contract ;
 * only the owner can modify the value of the parameter, so that it may be the
 * property of some higher order contract which will decide on a modification
 * protocol -- such as a vote.
 */
contract Parameter is ParameterBase, Ownable {
    bytes32 public description;
    uint private value;

    function Parameter(bytes32 _description, uint initial) Ownable() public {
        description = _description;
        value = initial;
    }

    function get() public view returns (uint) {
        return value;
    }

    function set(uint _new) onlyOwner public returns (bool) {
        value = _new;
        return true;
    }
}
