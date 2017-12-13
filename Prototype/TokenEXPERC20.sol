

// ptoto eMindHub onlyOwner
// 18 decomals
// symbol EXP 
// nom eMindHub
//

pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract TokenERC20 {
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

  
    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function TokenERC20(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

  
}

/******************************************/
/*   ADVANCED TOKEN STARTS HERE           */
/******************************************/

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    uint256 public unit;
    uint256 public VaultDeposit;
    
    struct FreelanceData {
        uint Price;
        uint ConfidenceIndex;
        address Agent;
        uint SharingPlan;
    }

 // Vault allowance client freelancer  
    mapping (address => mapping (address => bool)) public AccessAllowance;

// freelance data
    mapping (address=>FreelanceData) public Data;

 // This notifies freelance about the access of one client
    event VaultAccess(address client, address freelance, uint errorcode);
// This notifies freelance about Vault creation    
    event VaultOpening(address freelance, uint errorcode);
    
 // This notifies about the Confidence Index
    event ConfidenceIndex(address freelance, uint256 value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyAdvancedToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        Transfer(_from, _to, _value);
    }

    /// @notice Create `mintedAmount` tokens and send it to `target`
    /// @param target Address to receive the tokens
    /// @param mintedAmount the amount of tokens it will receive
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Transfer(0, this, mintedAmount);
        Transfer(this, target, mintedAmount);
    }

   

    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnit) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        unit = newUnit;
    }

    /// @notice Buy tokens from contract by sending ether
    function buy() payable public {
        uint amount = (msg.value / buyPrice) * unit;               // calculates the amount
        _transfer(this, msg.sender, amount);              // makes the transfers
    }

    /// @notice Sell `amount` tokens to contract
    /// @param amount amount of tokens to be sold
    function sell(uint256 amount) public {
        require(this.balance >= amount * sellPrice);      // checks if the contract has enough ether to buy
        _transfer(msg.sender, this, amount);              // makes the transfers
        msg.sender.transfer(amount * sellPrice/unit);          // sends ether to the seller. It's important to do this last to avoid recursion attacks
    }



/******************************************/
/*   EXP ADVANCED TOKEN STARTS HERE      */
/******************************************/


  
// cette fonction permet au freelance de definir le prix d accces de son CV en EXP
// le prix est libre.
// c est l equivalent d un Sell pour le freelance
// par defaut il est agent de lui meme
// peut etre utilisé pour changer le prix
    function CreateVaultAccess (uint myprice) public {
        if (balanceOf[msg.sender]<VaultDeposit){
            VaultOpening(msg.sender,0);            
        }
        else {
            Data[msg.sender].Price=myprice;
            _transfer(msg.sender,this, VaultDeposit);
            VaultOpening(msg.sender, 1);
            AccessAllowance[msg.sender][msg.sender]=true;
            }
}

// cette fontnion permet au freelance de nommer un nouvel agent
// l agent precedent perd son acces
// le nouevl agent est nommé
// le nouvel agent a un accees
// newplan = %

    function AgentApproval (address newagent, uint newplan) public{
        require (newplan<=100);
        AccessAllowance[Data[msg.sender].Agent][msg.sender]=false;
        Data[msg.sender].Agent=newagent;
        Data[msg.sender].SharingPlan=newplan;
        AccessAllowance[newagent][msg.sender]=true;
    }
// cette fonction permet a eMindHub de donner un index de confiance au CV
// c est un nombre de 0 a 100
// cela complete l information du freelancer (Data)
// on informe dela valeur de l index

    function SetUpConfidenceIndex(address freelance, uint index) onlyOwner public {
        require (index<=100);
        Data[freelance].ConfidenceIndex=index;
        ConfidenceIndex(freelance,index);
        
    }
    
// mise a jour de la valeur du VaultDeposit
    function SetVaultDeposit (uint newdeposit) onlyOwner public {
        VaultDeposit=newdeposit;
    }
    
    
// Cette fonction permet au client d acheter un acces
// on imagine le cv anonyme sur internet avec une adresse ethereum et un prix 
// attention le prix doit etre connu par le client parcequ il est débité sans negociation 
// le mieux pour lui est de verifier par un call sur Data le prix et l index de confiance

    function GetVaultAccess (address freelance) public {
// pour eviter d acheter 2 fois
        if (AccessAllowance[msg.sender][freelance]==true) {
            VaultAccess(msg.sender, freelance, 0);
            }
// pour valider que le client dispose des tokens necessaires
        else if (balanceOf[msg.sender]<Data[freelance].Price){
            VaultAccess(msg.sender, freelance, 1);
        }
        else {
// transfert les tokens du client vers le freelance et/ou l'agent en 1 clic
            uint f = (Data[freelance].Price)*Data[freelance].SharingPlan/100;
            uint a = Data[freelance].Price-f;
            _transfer(msg.sender, freelance, f);
            _transfer(msg.sender, Data[freelance].Agent, a);
// on ecrit que le client a acheté l acces   
            AccessAllowance[msg.sender][freelance]=true;
            VaultAccess(msg.sender, freelance, 2);}
    }

}


