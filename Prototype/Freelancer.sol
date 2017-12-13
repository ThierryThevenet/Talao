pragma solidity ^0.4.18;
//
// pour prototypage only
//
// eMindHub
//
//



contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) revert();
        _;
    }

      function transferOwnership(address newOwner) onlyOwner public {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Freelancer is Owned {
 //
//
// freelancer data  

    struct FreelancerInfo {
        uint State;                      // inactif 0 actif 1
        string Name;                    // nom drupal
        int Subscriptionblock;          // subscribion block 
        int Resignationblock;           // resignation block 
          
    }

// reputation for each comunity within DAO
    struct MemberReputation {
        int ContributionRating;        // contribution within the community 
        int ContributionRatingBlock;   // to compute decay (over time decrease)  
        uint ClientRating1;           // 4 last client rating
        uint ClientRating2;
        uint ClientRating3;
        uint ClientRating4;
    
    }
        
    int BlockPerQuarter;               // 650000 block average 3 months
    address owner;
   
  
  // If a newer version of this registry is available, force users to use it cf Drupal
    bool _registrationDisabled;
    
// Mapping that matches Drupal generated hash with Ethereum Account address.
// Drupal Hash => Ethereum address
    mapping (bytes32 => address) _accounts;
//    
    mapping (address => FreelancerInfo) private FreelancerData ;   
      
// freelancer=>commmunity=>reputation
    mapping (address => mapping(address => MemberReputation)) private FreelancerReputation;  // freelancer=>commmunity=>value
//    
//   
// Drupal Event allowing listening to newly action
    event AccountCreatedEvent (address indexedfrom, bytes32 indexedhash, int error);
//  DAO Events  
    event RatingUdated (address indexed user);
    event ContributionUpdated(address indexed user);
    event FreelancerFired(address indexed user);
//     

//
//
// creator, init owner and token
    function Freelancer() public {
     owner=msg.sender;
     BlockPerQuarter = 650000;      
    
 
    }
//
// minimum to join dao 
    function joindao() public{
        FreelancerData[msg.sender].State =1;
        FreelancerData[msg.sender].Subscriptionblock=int(block.number);
    }
// to fire a freelancer
    function fireafreelancer(address freelance) onlyOwner public {
        FreelancerData[freelance].State =0;
        FreelancerData[freelance].Resignationblock=int(block.number);
        FreelancerFired(freelance);
    }
    

//
//
/******************************************/
/*         DAO functions  START HERE      */
/******************************************/
//
//
// mise a jour de la dernieres evaluation client pour un freelance, l eval 4 est recopiée dans la 3 etc
    
    function registeraclientrating(address freelance, address community,uint LastRating) public {
        FreelancerReputation[freelance][community].ClientRating1=FreelancerReputation[freelance][community].ClientRating2;
        FreelancerReputation[freelance][community].ClientRating2=FreelancerReputation[freelance][community].ClientRating3;       
        FreelancerReputation[freelance][community].ClientRating3=FreelancerReputation[freelance][community].ClientRating4;
        FreelancerReputation[freelance][community].ClientRating4=LastRating;
        RatingUdated(freelance);
     }
//
//  mise a jour d'une contribution d un freelancer avec prise en compte du decay de 1 point par650000 blocks
    function updatecontribution(address freelance, address community, int LastContribution) public {
        FreelancerReputation[freelance][community].ContributionRating= FreelancerReputation[freelance][community].ContributionRating+LastContribution; 
        FreelancerReputation[freelance][community].ContributionRating-=  (int(block.number)-FreelancerReputation[freelance][community].ContributionRatingBlock)/BlockPerQuarter;
        FreelancerReputation[freelance][community].ContributionRatingBlock= int(block.number); // mise a jour de la date du dernier calcul de reputation
        ContributionUpdated(freelance);    
        
    }

// function needed to caculate weighted vote
// return state, contribution rating, client rating, 
    function getfreelancerdataforvoting(address AddressFreelancer, address community) constant public returns (uint, int, uint){
        uint ClientRating =(FreelancerReputation[AddressFreelancer][community].ClientRating1+FreelancerReputation[AddressFreelancer][community].ClientRating2+FreelancerReputation[AddressFreelancer][community].ClientRating3+FreelancerReputation[AddressFreelancer][community].ClientRating4)/4;
        return (FreelancerData[AddressFreelancer].State, FreelancerReputation[AddressFreelancer][community].ContributionRating, ClientRating) ;
    }




// 
//
//
/******************************************/
/*   DRUPALtoDAO functions STARTS HERE    */
/******************************************/
//
// Pour Yoann j ai ajouté les infos de creations pour un user de la dao, il n a pas besoin de joinDAO.

    function accountCreated(address from, bytes32 hash, int error) public {
    AccountCreatedEvent(from, hash, error);
    }
// Validate Account for Drupal
    function validateFreelancerByHash (bytes32 drupalUserHash) constant public returns (address){
      return _accounts[drupalUserHash];
    }

    function joinasafreelancer(bytes32 drupalUserHash, string name) public {
       
    if (_accounts[drupalUserHash] == msg.sender) {
      // Hash allready registered to address.
      accountCreated(msg.sender, drupalUserHash, 4);
    }
    else if (_accounts[drupalUserHash] > 0) {
      // Hash allready registered to different address.
      accountCreated(msg.sender, drupalUserHash, 3);
    }
     else if (drupalUserHash.length > 32) {
      // Hash too long
      accountCreated(msg.sender, drupalUserHash, 2);
    }
    else if (_registrationDisabled){
      // Registry is disabled because a newer version is available
      accountCreated(msg.sender, drupalUserHash, 1);
    }
    else {
      _accounts[drupalUserHash] = msg.sender;
      accountCreated(msg.sender, drupalUserHash, 0);
        FreelancerData[msg.sender].Subscriptionblock= int(block.number); // mise a jour de la date du dernier calcul de reputation
        FreelancerData[msg.sender].State=1;
        FreelancerData[msg.sender].Name=name;
        
        }
   ///  
    }


 }
 