pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./FOWToken.sol";


contract MyAdvancedToken is Ownable, FOW {

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
    mapping(address => mapping(address => bool)) public AccessAllowance;

    // Freelance data is public
    mapping(address => FreelanceData) public Data;

    // Those event notifies UI about vaults action with msg code
    enum Message {
        VaultAccessClosed,
        VaultAccessCreated,
        VaultAccessPriceTooHigh,
        NotEnoughTokensForDeposit,
        AgentRemoved,
        AgentAppointed,
        AccessGranted,
        NotEnoughTokensForAccess
    }

    event Vault(address indexed client, address indexed freelance, Message msg);

    // Confidence Index is set to measure certficate vault completion
    event ConfidenceIndex(address freelance, uint index);

    /**
     *Initializes contract with initial supply tokens to the creator of the contract
     * refill is initialized with 5 finneys
     * @param _sell is sell price for 1 _unit to tokens in ether
     * @param _buy price for 1 _unit to token in ethers
     * @param _unit 
     */
    function MyAdvancedToken(uint256 _sell, uint256 _buy, uint256 _unit) FOW(msg.sender, 10**8) public {
        require(_sell != 0 && _buy != 0 && _unit != 0);
        setPrices(_sell, _buy, _unit);
        setMinBalance(5);
    }

    /**
     * to initialize automatic refill with finneys
     */
    function setMinBalance(uint minimumBalanceInFinney) onlyOwner public {
         minBalanceForAccounts = minimumBalanceInFinney * 1 finney;
    }

    /**
    * @dev transfer token from a specific address to a specified address
    * @param _from the address to transfer from
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    *
    * This functions violates encapsulation and should not exist. Instead, all
    * transfers from a non-msg.sender address should go through the approve
    * token mechanism.
    */
    function _transfer(address _from, address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * basic ERC20 transfer tokens function with ether refill
     *
     * Send `_value` tokens to `_to` from `msg.sender`'s account
     * ethers refill is included  // should this be managed in JS?
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        success = _transfer(msg.sender, _to, _value);
        if (msg.sender.balance < minBalanceForAccounts)
            sell((minBalanceForAccounts - msg.sender.balance) * unitPrice / sellPrice);
    }

    /**
    * Allow users to buy tokens for `newBuyPrice` eth and sell tokens for `newSellPrice` eth
    * @param newSellPrice Price the users can sell to the contract
    * @param newBuyPrice Price users can buy from the contract
    * @param newUnitPrice to manage decimal issue 0,35 = 35 /100 (100 is unit)
    */
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice, uint256 newUnitPrice) onlyOwner public {
        require(newSellPrice != 0 && newBuyPrice != 0 && newUnitPrice != 0);
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        unitPrice = newUnitPrice;
    }

    function buy() payable public returns (uint amount) {
        amount = (msg.value / buyPrice) * unitPrice;
        require(balanceOf(this) - totalDeposit >= amount);
        balances[msg.sender] += amount;
        balances[this] -= amount;
        Transfer(this, msg.sender, amount);
        return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
        require(balanceOf(msg.sender) >= amount);
        balances[this] += amount;
        balances[msg.sender] -= amount;
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
    function withdrawEToken(uint256 tokens) onlyOwner public {
        require(balanceOf(this) - totalDeposit > tokens);    
        _transfer(this, msg.sender, tokens);
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
    function createVaultAccess(uint256 myprice) public {
        require(!AccessAllowance[msg.sender][msg.sender]);
        if (myprice > vaultDeposit) {
            Vault(msg.sender, msg.sender, Message.VaultAccessPriceTooHigh);
            return;
        } else if (balanceOf(msg.sender) < vaultDeposit) {
            Vault(msg.sender, msg.sender, Message.NotEnoughTokensForDeposit);
            return;
        }

        Data[msg.sender].accessPrice = myprice;
        _transfer(msg.sender, this, vaultDeposit);
        totalDeposit += vaultDeposit;
        Data[msg.sender].userDeposit = vaultDeposit;
        Data[msg.sender].sharingPlan = 100;
        AccessAllowance[msg.sender][msg.sender] = true;
        Vault(msg.sender, msg.sender, Message.VaultAccessCreated);
    }

    /**
    * to close v ault access, deposit is back to freelance wallet
    * total deposit in token contract is reduced by user deposit
    * confidence index is set to 0
    * to change vault access price one needs to close and open a new access
    */
    function closeVaultAccess() public {
        require(AccessAllowance[msg.sender][msg.sender]);
        _transfer(this, msg.sender, Data[msg.sender].userDeposit);
        totalDeposit -= Data[msg.sender].userDeposit;
        AccessAllowance[msg.sender][msg.sender] = false;
        Data[msg.sender].confidenceIndex = 0;
        Data[msg.sender].sharingPlan = 0;
        Vault(msg.sender, msg.sender, Message.VaultAccessClosed);
    }
    
    /**
    * to appoint an agent or a new agent
    * former agent is replaced by new agent
    * agent will receive token on behalf freelance
    * @param newagent to appoint
    * @param newplan => sharing plan is %, 100 means 100% for freelance
    */
    function agentApproval (address newagent, uint newplan) public {
        require(newplan <= 100);
        require(AccessAllowance[msg.sender][msg.sender]);
        AccessAllowance[Data[msg.sender].appointedAgent][msg.sender] = false;
        Vault(Data[msg.sender].appointedAgent, msg.sender, Message.AgentRemoved);
        Data[msg.sender].appointedAgent = newagent;
        Data[msg.sender].sharingPlan = newplan;
        AccessAllowance[newagent][msg.sender] = true;
        Vault(newagent, msg.sender, Message.AgentAppointed);
    }

    /**
     * to setup a confidence index to a freelance vault 
     * @ param freelance
     * @ param index is new confidence index
     */
    function setupConfidenceIndex(address freelance, uint index) onlyOwner public returns (bool) {
        require(AccessAllowance[freelance][freelance]);
        Data[freelance].confidenceIndex = index;
        ConfidenceIndex(freelance, index);
        return true;
    }
    
    /**
     * to initialize vault Deposit
     * @param newdeposit initializes deposit for vote access creation
     */
    function setVaultDeposit (uint newdeposit) onlyOwner public returns (bool) {
        vaultDeposit = newdeposit;
        return true;
    }
    
    /**
    * to buy an access to a freelancer vault
    * vault access  price is transfered from client to agent or freelance
    * depending of the sharing plan
    * if sharing plan is 100 then freelance receives 100% of access price
    */
    function getVaultAccess (address freelance) public returns (bool) {
        require(AccessAllowance[freelance][freelance]);
        require(!AccessAllowance[msg.sender][freelance]);
        if (balanceOf(msg.sender) < Data[freelance].accessPrice) {
            Vault(msg.sender, freelance, Message.NotEnoughTokensForAccess);
            return false;
        }

        uint256 freelanceShare = Data[freelance].accessPrice * Data[freelance].sharingPlan / 100;
        uint256 agentShare = Data[freelance].accessPrice - freelanceShare;
        _transfer(msg.sender, freelance, freelanceShare);
        _transfer(msg.sender, Data[freelance].appointedAgent, agentShare);
        AccessAllowance[msg.sender][freelance] = true;
        Vault(msg.sender, freelance, Message.AccessGranted);
        return true;
    }
}
