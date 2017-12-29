
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
    string public name ="Future Of Work";
    string public symbol ="FOW";
    uint8 public decimals = 18;
    uint256 public totalSupply =100000000 * 10 ** uint256(decimals);
  
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);

    function TokenERC20() public {
        balanceOf[msg.sender] = totalSupply;                
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[_from] -= _value;
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
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowance[_from][msg.sender]);     
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
    function approve(address _spender, uint256 _value) public returns (bool) {
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
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

/******************************************/
/*   ADVANCED TOKEN STARTS HERE           */
/*       ethereum.org/token               */
/******************************************/

contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice;      
    uint256 public buyPrice;
    uint256 public unitPrice;
    uint256 public vaultDeposit;
    uint minBalanceForAccounts;      
    uint256 public totalDeposit;           
    
    struct FreelanceData {
        uint256 accessPrice;
        uint confidenceIndex;
        address appointedAgent;
        uint sharingPlan;
        uint256 userDeposit;
    }

    // Vault allowance client x freelancer  
    mapping (address => mapping (address => bool)) public AccessAllowance;

    // Freelance data is public
    mapping (address=>FreelanceData) public Data;

    // Those event notifies UI about vaults action with msg code
    // msg = 0 Vault access closed  
    // msg = 1 Vault access created
    // msg = 2 Vault access price too high
    // msg = 3 not enough tokens to pay deposit
    // msg = 4 agent removed
    // msg = 5 new agent appointed
    // msg = 6 vault access granted to client
    // msg = 7 client not enough token to pay vault access
    event Vault(address indexed client, address indexed freelance, uint msg);

    // Confidence Index is set to measure certficate vault completion
    event ConfidenceIndex (address freelance, uint index);

    /**
     *Initializes contract with initial supply tokens to the creator of the contract
     * refill is initialized with 5 finneys
     * @param _sell is sell price for 1 _unit to tokens in ether
     * @param _buy price for 1 _unit to token in ethers
     * @param _unit 
     */
    function MyAdvancedToken(uint256 _sell, uint256 _buy, uint256 _unit) TokenERC20() public {
        require (_sell!=0 && _buy!=0 && _unit!=0);
        setPrices (_sell, _buy, _unit);
        setMinBalance(5);
    }

    /**
     * to initialize automatic refill with finneys
     */
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner public {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }
  
    /**
     * basic ERC20 transfer tokens function with ether refill
     *
     * Send `_value` tokens to `_to` from your account
     * ethers refill is included
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
        if(msg.sender.balance < minBalanceForAccounts)     
            sell((minBalanceForAccounts - msg.sender.balance)* unitPrice / sellPrice);
    }
  
    /**
    * Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    * @param newSellPrice Price the users can sell to the contract
    * @param newBuyPrice Price users can buy from the contract
    * @param newUnitPrice to manage decimal issue 0,35 = 35 /100 (100 is unit)
    */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnitPrice) onlyOwner public {
        require (newSellPrice !=0 && newBuyPrice !=0 && newUnitPrice != 0);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        unitPrice = newUnitPrice;
    }

    function buy() payable public returns (uint amount){
        amount = (msg.value / buyPrice)*unitPrice;             
        require(balanceOf[this]- totalDeposit >= amount); 
        balanceOf[msg.sender] += amount;                  
        balanceOf[this] -= amount;                        
        Transfer(this, msg.sender, amount);               
        return amount;                                    
    }

    function sell(uint amount) public returns (uint revenue){
        require(balanceOf[msg.sender] >= amount);         
        balanceOf[this] += amount;                       
        balanceOf[msg.sender] -= amount;                  
        revenue = amount * sellPrice/unitPrice;
        require(msg.sender.send(revenue));                
        Transfer(msg.sender, this, amount);               
        return revenue;                                   
    }

    /**
     * function to get contract ethers back to owner
     */
    function withdrawEther(uint256 ethers) onlyOwner public returns (bool ok) {
        if (this.balance >= ethers) {
            return owner.send(ethers);
        }
    }
    
    /**
     * function to get contract tokens back to owner
     * do not take token vault deposit (totalDeposit) transfeered from user
     */
    function withdrawEToken(uint256 tokens) onlyOwner public  {
        require (balanceOf[this]-totalDeposit > tokens);    
        _transfer(this,msg.sender, tokens);
    }

/******************************************/
/*      vault functions start here        */
/******************************************/
  
    /** To create a vault access
    * vault is create in another contract
    * Vault deposit is transferred to token contract and sum is stored in totalDeposit
    * myprice must be lower than Vault deposit
    * to change price you need to close and recreate
    * @param myprice to ask clients to pay to access certificate vault
    */
    function createVaultAccess (uint256 myprice) public {
        require (AccessAllowance[msg.sender][msg.sender]=false);
        if (myprice>vaultDeposit) {
            Vault(msg.sender, msg.sender, 2);
            return;
        }
        if (balanceOf[msg.sender]<vaultDeposit) {
            Vault(msg.sender, msg.sender,3);
            return;
        }
        Data[msg.sender].accessPrice=myprice;
        _transfer(msg.sender,this, vaultDeposit);
        totalDeposit += vaultDeposit;
        Data[msg.sender].userDeposit=vaultDeposit;
        Data[msg.sender].sharingPlan=100;
        AccessAllowance[msg.sender][msg.sender]=true;
        Vault(msg.sender, msg.sender, 1);
    }

    /**
    * to close v ault access, deposit is back to freelance wallet
    * total deposit in token contract is reduced by user deposit
    * confidence index is set to 0
    * to change vault access price one needs to close and open a new access
    */
    function closeVaultAccess() public {
        require (AccessAllowance[msg.sender][msg.sender]==true);
        _transfer(this, msg.sender, Data[msg.sender].userDeposit);
        totalDeposit-=Data[msg.sender].userDeposit;
        AccessAllowance[msg.sender][msg.sender]=false;
        Data[msg.sender].confidenceIndex=0;
        Data[msg.sender].sharingPlan=0;
        Vault(msg.sender, msg.sender, 0);
    }
    
    /**
    * to appoint an agent or a new agent
    * former agent is replaced by new agent
    * agent will receive token on behalf freelance
    * @param newagent to appoint
    * @param newplan => sharing plan is %, 100 means 100% for freelance
    */
    function agentApproval (address newagent, uint newplan) public{
        require (newplan<=100);
        require (AccessAllowance[msg.sender][msg.sender]==true);
        AccessAllowance[Data[msg.sender].appointedAgent][msg.sender]=false;
        Vault(Data[msg.sender].appointedAgent, msg.sender, 4);
        Data[msg.sender].appointedAgent=newagent;
        Data[msg.sender].sharingPlan=newplan;
        AccessAllowance[newagent][msg.sender]=true;
        Vault(newagent, msg.sender, 5);
    }

    /**
     * to setup a confidence index to a freelance vault 
     * @ param freelance
     * @ param index is new confidence index
     */
    function setupConfidenceIndex(address freelance, uint index) onlyOwner public returns (bool) {
        require (AccessAllowance[freelance][freelance]==true);
        Data[freelance].confidenceIndex=index;
        ConfidenceIndex(freelance,index);
        return true;
    }
    
    /**
     * to initialize vault Deposit
     * @param newdeposit initializes deposit for vote access creation
     */
    function setVaultDeposit (uint newdeposit) onlyOwner public returns (bool){
        vaultDeposit=newdeposit;
        return true;
    }
    
    /**
    * to buy an access to a freelancer vault
    * vault access  price is transfered from client to agent or freelance
    * depending of the sharing plan
    * if sharing plan is 100 then freelance receives 100% of access price
    */
    function getVaultAccess (address freelance) public returns (bool){
        require( AccessAllowance[freelance][freelance]==true);
        require (AccessAllowance[msg.sender][freelance]!=true);
        if (balanceOf[msg.sender]<Data[freelance].accessPrice){
            Vault(msg.sender, freelance, 7);
            return false;
        }
        uint256 freelance_share = Data[freelance].accessPrice*Data[freelance].sharingPlan/100;
        uint256 agent_share = Data[freelance].accessPrice-freelance_share;
        _transfer(msg.sender, freelance, freelance_share);
        _transfer(msg.sender, Data[freelance].appointedAgent, agent_share);
        AccessAllowance[msg.sender][freelance]=true;
        Vault(msg.sender, freelance, 6);
        return true;
    }
}



