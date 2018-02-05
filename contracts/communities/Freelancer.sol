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
// les state variables sont renomm�e avec capStyle
// le nom des fonctions pour la DAO et le vote sont renomm� avec capStyle
// mise a jour compilateur 4.19

pragma solidity ^0.4.18;

import "../../node_modules/zeppelin-solidity/contracts/ownership/Ownable.sol";


contract Freelancer is Ownable {

    struct FreelancerInfo {
        uint userState;                 // inactive 0 active 1 -- make this a bool
        string userName;                // drupal name
        int subscriptionBlock;          // subscribion block 
        int resignationBlock;           // resignation block 
    }

    struct MemberReputation {
        int contributionRating;         // contribution within the community 
        int contributionRatingBlock;    // to compute decay (over time decrease)  
        uint[4] clientRatings;
        uint[4] ratingWeights;
        uint counter;
    }

    int blockPerQuarter;                // 650000 block average 3 months
    address owner;

    // If a newer version of this registry is available, force users to use it cf Drupal
    bool _registrationDisabled;

    // Mapping that matches Drupal generated hash with Ethereum Account address.
    // Drupal Hash => Ethereum address
    mapping(bytes32 => address) _accounts;
    mapping(address => FreelancerInfo) private freelancerData;

    // freelancer => (commmunity => reputation), for voting, weight depend on the community
    mapping(address => mapping(address => MemberReputation)) private freelancerReputation;  
    
    // Drupal Event allowing listening to newly action
    event AccountCreatedEvent(address indexed from, bytes32 indexed hash, int error);

    // DAO Events  
    event RatingUpdated(address indexed user);
    event ContributionUpdated(address indexed user);
    event FreelancerFired(address indexed user);

    /**
     * init owner and delay for decay calculation
     */
    function Freelancer() public {
        owner = msg.sender;
        blockPerQuarter = 650000;      
    }
    
    /**
     * Minimum to join a DAO when non Drupal user
     */
    function joinDao() public {
        require(freelancerData[msg.sender].userState == 0);
        freelancerData[msg.sender].userState = 1;
        freelancerData[msg.sender].subscriptionBlock = int(block.number);
    }

    function fireaFreelancer(address freelance) onlyOwner public {
        require(freelancerData[freelance].userState == 1);
        freelancerData[freelance].userState = 0;
        freelancerData[freelance].resignationBlock = int(block.number);
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
    function registerClientRating(address freelance, address community, uint rating, uint weight) public returns (bool) {
        require(weight != 0);
        require(rating > 0 && rating <= 50);
        require(freelancerData[freelance].userState == 1);

        MemberReputation storage reputation = freelancerReputation[freelance][community];

        // update ratings & counter
        reputation.clientRatings[reputation.counter] = rating;
        reputation.ratingWeights[reputation.counter] = weight;
        reputation.counter = (reputation.counter + 1) % reputation.clientRatings.length;

        RatingUpdated(freelance);
        return true;
    }

    /**
     * Contribution update
     * maximum contribution is 50
     * new contribution number is added to previous contribution
     * Decay with 2 decimals is taken into account to decrease contribution number before adding new contribution
     */
    function updateContribution(address freelance, address community, int lastcontribution) public returns (int) {
        require(lastcontribution <= 50);
        require(freelancerData[freelance].userState == 1);

        MemberReputation storage reputation = freelancerReputation[freelance][community];

        int hundreddecay = (100 * (int(block.number) - reputation.contributionRatingBlock)) / blockPerQuarter;
        reputation.contributionRating -= (hundreddecay * reputation.contributionRating) / 100;
        reputation.contributionRating += lastcontribution;

        if (reputation.contributionRating > 50) {
            reputation.contributionRating = 50;
        }

        reputation.contributionRatingBlock = int(block.number);
        ContributionUpdated(freelance);
        return reputation.contributionRating;
    }

    /**
    * function needed to caculate weighted vote of one user within one community
    * return user state, user contribution and client rating taking into acount weight of each rating
    * at bootstrap if no client rating return rating 0
    * if freelance not in DAO return 0
    * return userState, contributionRating and clientRating
    */
    function getFreelancerDataForVoting(address freelance, address community) constant public returns (uint userState, int contributionRating, uint clientRating) {
        userState = freelancerData[freelance].userState;
        if (userState == 0)
            return (0, 0, 0);

        MemberReputation memory reputation = freelancerReputation[freelance][community];
        contributionRating = reputation.contributionRating;

        for (uint i = 0; i < reputation.clientRatings.length; i++) {
            clientRating += reputation.ratingWeights[i] * reputation.clientRatings[i];
        }
    }

    /******************************************/
    /*   DRUPALtoDAO functions START HERE    */
    /******************************************/

    function accountCreated(address from, bytes32 _hash, int error) public {
        AccountCreatedEvent(from, _hash, error);
    }

    function validateFreelancerByHash (bytes32 drupalUserHash) constant public returns (address) {
        return _accounts[drupalUserHash];
    }

    function joinasafreelancer(bytes32 drupalUserHash, string name) public {
        if (_accounts[drupalUserHash] == msg.sender) {
            // Hash allready registered to address.
            accountCreated(msg.sender, drupalUserHash, 4);
        } else if (_accounts[drupalUserHash] > 0) {
            // Hash allready registered to different address.
            accountCreated(msg.sender, drupalUserHash, 3);
        } else if (drupalUserHash.length > 32) {
            // Hash too long
            accountCreated(msg.sender, drupalUserHash, 2);
        } else if (_registrationDisabled) {
            // Registry is disabled because a newer version is available
            accountCreated(msg.sender, drupalUserHash, 1);
        } else {
            _accounts[drupalUserHash] = msg.sender;
            accountCreated(msg.sender, drupalUserHash, 0);
            freelancerData[msg.sender].subscriptionBlock = int(block.number); 
            freelancerData[msg.sender].userState = 1;
            freelancerData[msg.sender].userName = name;
        }
    }
}
