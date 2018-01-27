/* TODO:
 *   [ ] import `Owned`, `tokenRecipient`, `tokenERC20` from open-zeppelin
 *   [ ] event Vault uint msg should be enum
 *   [x] clean code
 */

// version 1.1 du token
//
// proto eMindHub onlyOwner
//
// symbol TAL en attendant mieux
// nom eMindHub
//
// ajout version 1.1
// ajout TotalDeposit pour suivre les depoisitr sur le contrat
// initialisation du token en TokenERC20
// confidence index est mis a 0 si user quitte 
// index est uint libre pour evolution
// correction pb refill dans fonction transfer
//
// version 1.2
// rename FOW Future Of Work
// simplification event Vault
// retrait du doublon _transfer
// ajout des fonctions permettant de recuperer les ethers et token du buy/sell
//
// version 1.3
// commentaires
// styles
// changement des majuscules sur le nom des fonctions de gestion du vault
// changement de unit en unitPrice pour le sell et buy

pragma solidity ^0.4.18;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "../zeppelin-solidity/contracts/token/StandardToken.sol";

// is this in zeppelin-solidity?
interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract FOW is StandardToken {
    // Public variables of the token
    string public name = "Future Of Work";
    string public symbol = "FOW";
    uint8 public decimals = 18;

    /**
     * Set initial account's balance to `totalSupply`.
     * Distribution method for tokens will most likely change.
     */
    function FOW(address initialAccount, uint256 totalSupply) public {
        totalSupply = 100000000 * 10 ** uint256(decimals);
        balances[initialAccount] = totalSupply;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}
