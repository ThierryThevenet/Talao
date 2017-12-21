pragma solidity ^0.4.18;
// pour prototypage only
//
// version 1.1
// - suppession commentaires inutiles
// - correction bufg compteur d array
//
//
//

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}



contract Community is Owned {
   
        string  public CommunityName;
        bool    public CommunityState;                        // 0 inactif 1 actif
        bool    public CommunityType;                         // 0 open, 1 private
        uint    public CommunitySponsor;                      // si privée reference client
        uint    public CommunityBalanceForVoting;              // balance pour le vote 10 => 10% token et 90% reputation   
        uint    public CommunityMinimumToken;                 // nbn minimum de token pour voter
        uint    public CommunityMinimumReputation;                 //nb minimum de reputation pour voter    
        uint    public CommunityJobCom;                       // % commission on job = 0 at bootstrap      
        uint    public CommunityMemberFees;                     // fees to join = 0 ;
        address [] public CommunityMembers;                // freelancer list
     
  
    
    event CommunitySubscription(address indexed freelancer, bool msg);  //1 join, 0 leave 
   
// initialisation 
    
    function Community (string Name, 
                            bool Type,
                            uint Balance,
                            uint Token,
                            uint Reputation,
                            uint Com,
                            uint Fees) public {
                                
        CommunityName=Name;
        CommunityType=Type;
        CommunityState=true;
        CommunityBalanceForVoting=Balance;
        CommunityMinimumToken=Token;
        CommunityMinimumReputation=Reputation;
        CommunityJobCom=Com;
        CommunityMemberFees=Fees;
        
    }
        
    function setupvotingrules (uint Balance, uint Token, uint Reputation) public onlyOwner {
        CommunityBalanceForVoting = Balance;
        CommunityMinimumToken = Token;
        CommunityMinimumReputation = Reputation;
    }
//
//// fonciton inutile cf Loan pour la retirer, les data sont publiques
    function getdataforvoting () public constant returns(uint,uint,uint){
        uint Balance = CommunityBalanceForVoting;
        uint Token = CommunityMinimumToken;
        uint Reputation = CommunityMinimumReputation;
        return (Balance,Token,Reputation);
    }
    

    function joincommunity() public {
        CommunityMembers.push(msg.sender);
        CommunitySubscription(msg.sender, true);
    }

// remet a jour le compteur de membres de la communauté
    
    function leavecommunity () public {
        for (uint i =0 ; i<CommunityMembers.length-1; i++) {
            if (CommunityMembers[i] == msg.sender){
                for (uint j=i; j<CommunityMembers.length-1; j++){
                    CommunityMembers[j]=CommunityMembers[j+1];
                    }
                delete CommunityMembers[CommunityMembers.length-1];
                CommunityMembers.length--;
                CommunitySubscription(msg.sender, false);
                return;
            }
        }    
              
    }

    
    
// a verifier si fonction inutile (public data) cf Loan si il l utilise    
    function getcommunitymembership() public constant returns (uint){
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
    
    // pour test
    address public newcommunity;
    event CommunityListing(address indexed owner, address indexed community );
    
    mapping(address => bool) _verify;

    // Anyone can call this method to verify the settings of a
    // Community contract. The parameters are:
    //   CommunityCotract  is the address of a Community
    //
    // Return values:
    //   valid        did this contract create the community contract?
    //   owner        is the owner of the Community contract
    
    
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

    // Manager can call this method to create a new Community contract
    // with the maker being the owner of this new contract
   
    function createCommunityContract (string Name, 
                            bool Type,
                            uint Balance,
                            uint Token,
                            uint Reputation,
                            uint Com,
                            uint Fees) public onlyOwner
        
    returns (address mycommunity) {
       
      
        mycommunity = new Community(Name, Type, Balance, Token, Reputation, Com, Fees);
    
        // Record that this factory created the community
        _verify[mycommunity] = true;
        
        // pour test newcommunity est public data et ne pas chercher l adresse dans etherscan!!!
        newcommunity=mycommunity;
    
        // Set the owner to whoever called the function
        Community(mycommunity).transferOwnership(msg.sender);
        CommunityListing(msg.sender, mycommunity);
    }

    

    // Prevents accidental sending of ether to the factory
    function () public {
        throw;
    }
}    
    