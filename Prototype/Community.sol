pragma solidity ^0.4.18;
// pour prototypage only
//
//
//
//
//

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



contract Community is Owned {
   
        string public CommunityName;
        uint public CommunityState;                        // 0 inactif 1 actif
        uint public CommunityType;                         // 0 open, 1 private
        uint public CommunitySponsor;                      // si privée reference client
        uint public CommunityBalanceForVoting;              // balance pour le vote 10 => 10% token et 90% reputation   
        uint public CommunityMinimumToken;                 // nbn minimum de token pour voter
        uint public CommunityMinimumReputation;                 //nb minimum de reputation pour voter    
        uint public CommunityJobCom;                       // % commission on job = 0 at bootstrap      
        uint public CommunityMemberFees;                     // fees to join = 0 ;
        address [] public CommunityMembers;                // freelancer list
     
    
    
    event joined(address freelancer); 
   
// initialisation 
    
    function Community (string Name, 
                            uint Type,
                            uint Balance,
                            uint Token,
                            uint Reputation,
                            uint Com,
                            uint Fees) public {
                                
        CommunityName=Name;
        CommunityType=Type;
        CommunityState=1;
        CommunityBalanceForVoting=Balance;
        CommunityMinimumToken=Token;
        CommunityMinimumReputation=Reputation;
        CommunityJobCom=Com;
        CommunityMemberFees=Fees;
        
    }
        
    function setupvotingrules (uint Balance, uint Token, uint Reputation) public {
        CommunityBalanceForVoting = Balance;
        CommunityMinimumToken = Token;
        CommunityMinimumReputation = Reputation;
    }
//
//
    function getdataforvoting () public constant returns(uint,uint,uint){
        uint Balance = CommunityBalanceForVoting;
        uint Token = CommunityMinimumToken;
        uint Reputation = CommunityMinimumReputation;
        return (Balance,Token,Reputation);
            }
    
    function joincommunity() public {
        CommunityMembers.push(msg.sender);
        joined(msg.sender);
    }
    function leavecommunity (address freelancer) public {
        for (uint i =1 ; i<CommunityMembers.length; i++) {
            if (CommunityMembers[i]== freelancer)
            CommunityMembers[i]=0x0;
        }
    }
    
    function getcommunitymembership(address community) public constant returns (uint){
        return CommunityMembers.length;
        
    }
}
    
//
//
// This contract deploys Community contracts and logs the event
//
//
//

contract CommunityFactory is Owned {
    event CommunityListing(address owner, address community );
    mapping(address => bool) _verify;

    // Anyone can call this method to verify the settings of a
    // Community contract. The parameters are:
    //   CommunityCotract  is the address of a Community
    //
    // Return values:
    //   valid        did this TokenTraderFactory create the TokenTrader contract?
    //   owner        is the owner of the TokenTrader contract
    
    
    function verify(address CommunityContract) constant public  returns (
        bool    valid,
        address owner,
        uint balance,
        uint token,
        uint reputation,
        uint com,
        uint fees) {

        valid = _verify[CommunityContract];
        if (valid) {
            Community C = Community (CommunityContract);
            owner = C.owner();
            balance=C.CommunityBalanceForVoting();
            token=C.CommunityMinimumToken();
            reputation=C.CommunityMinimumReputation();
            com = C.CommunityJobCom();
            fees =C.CommunityMemberFees();
        }
    }

    // Maker can call this method to create a new Community contract
    // with the maker being the owner of this new contract
   
    function createCommunityContract (string Name, 
                            uint Type,
                            uint Balance,
                            uint Token,
                            uint Reputation,
                            uint Com,
                            uint Fees) public
        
    returns (address mycommunity) {
        // Cannot have invalid asset
    //  if (asset == 0x0) throw;
      
        mycommunity = new Community(Name, Type, Balance, Token, Reputation, Com, Fees);
        // Record that this factory created the community
        _verify[mycommunity] = true;
        
        // Set the owner to whoever called the function
        Community(mycommunity).transferOwnership(msg.sender);
        CommunityListing(msg.sender, mycommunity);
    }

    

    // Prevents accidental sending of ether to the factory
    function () {
        throw;
    }
}    
    