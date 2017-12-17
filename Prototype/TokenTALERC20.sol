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


pragma solidity ^0.4.19;

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
    string public name ="eMindHub";
    string public symbol ="TAL";
    uint8 public decimals = 18;
    uint256 public totalSupply =100000000 * 10 ** uint256(decimals);
  
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
    function TokenERC20()    public {
        
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. 
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        
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

    uint256 public sellPrice;       // sell price = sellPrice/unit 0,35 = 35(/100)
    uint256 public buyPrice;
    uint256 public unit;
    uint256 public VaultDeposit;
    uint minBalanceForAccounts;    // automatic refill at 5 finneys  
    uint256 public TotalDeposit;           // to follow savings on contract
    
    struct FreelanceData {
        uint256 Price;
        uint ConfidenceIndex;
        address Agent;
        uint SharingPlan;
        uint256 Deposit;
    }

 // Vault allowance client x freelancer  
    mapping (address => mapping (address => bool)) public AccessAllowance;

// freelance data is public
    mapping (address=>FreelanceData) public Data;

 // Those event notifies about vaults
    event VaultAccess(address indexed client, address indexed freelance, bool error);
    event VaultOpening(address indexed freelance, bool error);
    event VaultClosing(address indexed freelance, bool error);
    event AgentAppointment(address indexed agent, address indexed freelance, bool error);
    event ConfidenceIndex(address indexed freelance, uint value);


    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyAdvancedToken(uint256 _sell, uint256 _buy, uint256 _unit) TokenERC20() public {
        require (_sell!=0 && _buy!=0 && _unit!=0);
        setPrices (_sell, _buy, _unit);
        setMinBalance(5);
    }

    // to initialize automatic refill 
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner public {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
    
    
    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);                               // Prevent transfer to 0x0 address        require (balanceOf[_from] > _value);                // Check if the sender has enough
        require (balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[_from] -= _value;                         // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
       /* Send coins */
        Transfer(_from, _to, _value);
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
              if(msg.sender.balance < minBalanceForAccounts)      // auto refill ether with token
            sell((minBalanceForAccounts - msg.sender.balance)* unit / sellPrice);
    }


  
    /// @notice Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    /// @param newSellPrice Price the users can sell to the contract
    /// @param newBuyPrice Price users can buy from the contract
    // unit to manage decimal issue 0,35 = 35 /100 (100 is unit)
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnit) onlyOwner public {
        require (newSellPrice !=0 && newBuyPrice !=0 && newUnit != 0);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        unit = newUnit;
    }

    function buy() payable public returns (uint amount){
        amount = (msg.value / buyPrice)*unit;                    // calculates the amount
        require(balanceOf[this] >= amount);               // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                  // adds the amount to buyer's balance
        balanceOf[this] -= amount;                        // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);               // execute an event reflecting the change
        return amount;                                    // ends function and returns
    }

   

    function sell(uint amount) public returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         // checks if the sender has enough to sell
        balanceOf[this] += amount;                        // adds the amount to owner's balance
        balanceOf[msg.sender] -= amount;                  // subtracts the amount from seller's balance
        revenue = amount * sellPrice/unit;
        require(msg.sender.send(revenue));                // sends ether to the seller: it's important to do this last to prevent recursion attacks
        Transfer(msg.sender, this, amount);               // executes an event reflecting on the change
        return revenue;                                   // ends function and returns
    }




/******************************************/
/*   eMindHub ADVANCED TOKEN STARTS HERE  */
/******************************************/


  
// To create a vault access
// vault is create in another contract
// Vault deposit is transferred to token contract
// myprice is lower than Vault deposit
// to change price you need to close and recreate

    function CreateVaultAccess (uint256 myprice) public {
        require (AccessAllowance[msg.sender][msg.sender]=false);
        require (myprice<=VaultDeposit);
        require (balanceOf[msg.sender]<VaultDeposit);            
        Data[msg.sender].Price=myprice;
        // deposit transferred to token contract
        _transfer(msg.sender,this, VaultDeposit);
        TotalDeposit += VaultDeposit;
        // to store current deposit value
        Data[msg.sender].Deposit=VaultDeposit;
        AccessAllowance[msg.sender][msg.sender]=true;
        VaultOpening(msg.sender, true);
    }

// to close access, deposit is back to freelance wallet
    function CloseVaultAccess() public {
        require (AccessAllowance[msg.sender][msg.sender]==true);
        _transfer(this, msg.sender, Data[msg.sender].Deposit);
        TotalDeposit-=Data[msg.sender].Deposit;
        AccessAllowance[msg.sender][msg.sender]=false;
        Data[msg.sender].ConfidenceIndex=0;
        VaultClosing(msg.sender, true);
    }
    
// to appoint an Agent
// former agent is replaced by new agent
// agent will receive token on behalf freelancer
// sharing plan is %

    function AgentApproval (address newagent, uint newplan) public{
        // plan is %
        require (newplan<=100);
        // vault access has to be opened first
        require (AccessAllowance[msg.sender][msg.sender]==true);
        // former agent removed
        AccessAllowance[Data[msg.sender].Agent][msg.sender]=false;
        AgentAppointment(Data[msg.sender].Agent, msg.sender, false);
        //new agent appointed
        Data[msg.sender].Agent=newagent;
        Data[msg.sender].SharingPlan=newplan;
        AccessAllowance[newagent][msg.sender]=true;
        AgentAppointment(newagent, msg.sender, true);
    }

// to setup a confidence index to a freelance vault 
    function SetUpConfidenceIndex(address freelance, uint index) onlyOwner public {
         // need vault access opened
        require (AccessAllowance[freelance][freelance]==true);
        Data[freelance].ConfidenceIndex=index;
        ConfidenceIndex(freelance,index);
    }
    
// to initialize Vault Deposit
    function SetVaultDeposit (uint newdeposit) onlyOwner public {
        VaultDeposit=newdeposit;
    }
    
    
// to buy an access to a freelancer vault
    function GetVaultAccess (address freelance) public {
        // to check Vault access is allowed
        require( AccessAllowance[freelance][freelance]==true);
        // to avoid multiple buys
        require (AccessAllowance[msg.sender][freelance]!=true);
        require (balanceOf[msg.sender]>=Data[freelance].Price);
        // sharng plan calculation
        uint256 freelance_share = Data[freelance].Price*Data[freelance].SharingPlan/100;
        uint256 agent_share = Data[freelance].Price-freelance_share;
        _transfer(msg.sender, freelance, freelance_share);
        _transfer(msg.sender, Data[freelance].Agent, agent_share);
        // client is now allowed to access. it is an unlimited access  
        AccessAllowance[msg.sender][freelance]=true;
        VaultAccess(msg.sender, freelance, true);
    }

}


