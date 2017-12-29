//
// pour prototypage only
//
// eMindHub
//
//
// version 1.1
// integration du poids economique de la mission pour le calcul du vote
// boolean return for functions
// correction bug calcul dans le decay
// mise a jour pour respect du calcul de reputation comme specififcations du WP
// mise a jour du style et des commentaires
// les state variables sont renommée avec capStyle
// le nom des fonctions pour la DAO et le vote sont renommé avec capStyle
// mise a jour compilateur 4.19

pragma solidity ^0.4.19;

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
    struct FreelancerInfo {
        uint userState;                 // inactive 0 active 1
        string userName;                // drupal name
        int subscriptionBlock;          // subscribion block 
        int resignationBlock;           // resignation block 
    }

    struct MemberReputation {
        int contributionRating;         // contribution within the community 
        int contributionRatingBlock;    // to compute decay (over time decrease)  
        uint clientRating1;             // 4 last client rating
        uint weightRating1;             // economical weight of rating1
        uint clientRating2;
        uint weightRating2;
        uint clientRating3;
        uint weightRating3;
        uint clientRating4;
        uint weightRating4;
    }
        
    int blockPerQuarter;                // 650000 block average 3 months
    address owner;
   
// If a newer version of this registry is available, force users to use it cf Drupal
    bool _registrationDisabled;
    
// Mapping that matches Drupal generated hash with Ethereum Account address.
// Drupal Hash => Ethereum address
    mapping (bytes32 => address) _accounts;
    mapping (address => FreelancerInfo) private FreelancerData ;   
      
// freelancer=>commmunity=>reputation. For voting, weight depend on the community
    mapping (address => mapping(address => MemberReputation)) private FreelancerReputation;  
    
// Drupal Event allowing listening to newly action
    event AccountCreatedEvent (address indexed from, bytes32 indexed hash, int error);

// DAO Events  
    event RatingUpdated (address indexed user);
    event ContributionUpdated(address indexed user);
    event FreelancerFired(address indexed user);

    /**
     * init owner and delay for decay calculation
     */
    function Freelancer() public {
     owner=msg.sender;
     blockPerQuarter = 650000;      
    }
    
    /**
     * Minimum to join a DAO when non Drupal user
     */ 
    function joinDao() public{
        require (FreelancerData[msg.sender].userState == 0);
        FreelancerData[msg.sender].userState =1;
        FreelancerData[msg.sender].subscriptionBlock=int(block.number);
    }

    function fireaFreelancer(address freelance) onlyOwner public {
        require (FreelancerData[freelance].userState ==1);
        FreelancerData[freelance].userState =0;
        FreelancerData[freelance].resignationBlock=int(block.number);
        FreelancerFired(freelance);
    }
    
/******************************************/
/*         DAO functions  START HERE      */
/******************************************/

    /**
     * Update of the last 4 client evaluations and economical weights
     * maximum client rating is 50
     * client rating are stored by community
     * we only need to store the last 4 ratings/community for voting within the DAO
     */ 
    function registeraClientRating(address freelance, address community,uint lastrating, uint weightrating) public returns (bool){
        require (weightrating != 0);
        require (lastrating>0 && lastrating <=50);
        require (FreelancerData[freelance].userState == 1);
        FreelancerReputation[freelance][community].clientRating1=FreelancerReputation[freelance][community].clientRating2;
        FreelancerReputation[freelance][community].weightRating1=FreelancerReputation[freelance][community].weightRating2;
        FreelancerReputation[freelance][community].clientRating2=FreelancerReputation[freelance][community].clientRating3;
        FreelancerReputation[freelance][community].weightRating2=FreelancerReputation[freelance][community].weightRating3;
        FreelancerReputation[freelance][community].clientRating3=FreelancerReputation[freelance][community].clientRating4;
        FreelancerReputation[freelance][community].weightRating3=FreelancerReputation[freelance][community].weightRating4;
        FreelancerReputation[freelance][community].clientRating4=lastrating;
        FreelancerReputation[freelance][community].clientRating4=weightrating;
        RatingUpdated(freelance);
        return true;
     }

    /**
     * Contribution update
     * maximum contribution is 50
     * new contribution number is added to previous contribution
     * Decay with 2 decimals is taken into account to decrease contribution number before adding new contribution 
     */ 
    function updateContribution(address freelance, address community, int lastcontribution) public returns (int){
        require (lastcontribution<=50);
        require (FreelancerData[freelance].userState == 1);
        int hundreddecay = (100*(int(block.number)-FreelancerReputation[freelance][community].contributionRatingBlock))/blockPerQuarter;
        FreelancerReputation[freelance][community].contributionRating-= (hundreddecay*FreelancerReputation[freelance][community].contributionRating)/100;
        FreelancerReputation[freelance][community].contributionRating+=lastcontribution; 
        if (FreelancerReputation[freelance][community].contributionRating>50){
            FreelancerReputation[freelance][community].contributionRating=50;
            }
        FreelancerReputation[freelance][community].contributionRatingBlock= int(block.number);
        ContributionUpdated(freelance);    
        return FreelancerReputation[freelance][community].contributionRating;
    }

    /**
    * function needed to caculate weighted vote of one user within one community
    * return user state, user contribution and client rating taking into acount weight of each rating
    * at bootstrap if no client rating return rating 0 
    * if freelance not in DAO return 0
    * return userState, contributionRating and clientRating
    */ 
    function getFreelancerDataForVoting(address freelance, address community) constant public returns (uint, int, uint){
        if (FreelancerData[freelance].userState == 0) return (0,0,0);
        uint wcr1 =FreelancerReputation[freelance][community].clientRating1*FreelancerReputation[freelance][community].weightRating1;
        uint wcr2 =FreelancerReputation[freelance][community].clientRating2*FreelancerReputation[freelance][community].weightRating2;
        uint wcr3 =FreelancerReputation[freelance][community].clientRating3*FreelancerReputation[freelance][community].weightRating3;
        uint wcr4 =FreelancerReputation[freelance][community].clientRating4*FreelancerReputation[freelance][community].weightRating4;
        if ((wcr1+wcr2+wcr3+wcr4)==0){
            return (1, FreelancerReputation[freelance][community].contributionRating, 0) ;
            }
        uint clientrating = (wcr1+wcr2+wcr3+wcr4)
        / (FreelancerReputation[freelance][community].weightRating1
        + FreelancerReputation[freelance][community].weightRating2
        + FreelancerReputation[freelance][community].weightRating3
        + FreelancerReputation[freelance][community].weightRating4); 
        return (1, FreelancerReputation[freelance][community].contributionRating, clientrating) ;
    }

/******************************************/
/*   DRUPALtoDAO functions STARTS HERE    */
/******************************************/

    function accountCreated(address from, bytes32 hash, int error) public {
    AccountCreatedEvent(from, hash, error);
    }

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
        FreelancerData[msg.sender].subscriptionBlock= int(block.number); 
        FreelancerData[msg.sender].userState=1;
        FreelancerData[msg.sender].userName=name;
        }
    }
 }
 