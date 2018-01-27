/* TODO:
 *   [x] import `Owned` contract from open-zeppelin
 *   [ ] `communityMembers` state variable should be bool map
 *   [ ] `communityState` should be renamed `active` and typed bool
 *   [ ] `communityType` should be either enum or bool (in which case renamed)
 *   [ ] `communityBalanceForVoting` is outdated
 *   [x] clean code
 */

// pour prototypage only
//
// version 1.1
// - suppession commentaires inutiles
// - correction bufg compteur d array
//
// version 1.2 
// mise a jour des styles
// ajout d une fcntion de transfere de token transferFunds
// la fonction getdataforvoting est retirr�e, les data sont publiques donc accessibles avec un getter

pragma solidity ^0.4.18;

import "../zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./AdvancedToken.sol";


contract Community is Ownable {
    string  public communityName;
    uint    public communityState;                          // 0 inactif 1 actif
    uint    public communityType;                           // 0 open, 1 private
    address public communitySponsor;                        // if private community, address client
    uint    public communityBalanceForVoting;               // balance for voting 10 => 10% token and 90% reputation   
    uint    public communityMinimumToken;                   // min tokrn to vote
    uint    public communityMinimumReputation;              // min reputation to vote    
    uint    public communityJobCom;                         // x 1/10000 commission on job = 0 at bootstrap. 100 means 1%      
    uint    public communityMemberFees;                     // fees to join = 0 ;
    address[] public CommunityMembers;                      // freelancer list
    
    MyAdvancedToken public mytoken;
    uint256 public communityTokenBalance;                        //  pour test
    
    event CommunitySubscription(address indexed freelancer, bool msg); 

    function Community(address token, string name, uint comtype, uint balance, uint mintoken, uint minreputation, uint com, uint fees) public {
        mytoken = MyAdvancedToken(token);
        communityName = name;
        communityType = comtype;
        communityState = 1;
        communityBalanceForVoting = balance;
        communityMinimumToken = mintoken;
        communityMinimumReputation = minreputation;
        communityJobCom = com;
        communityMemberFees = fees;
        communityTokenBalance = mytoken.balanceOf(this);
    }
    
    function setupVotingRules(uint balance, uint token, uint reputation) public onlyOwner {
        require(token != 0 && reputation != 0);
        communityBalanceForVoting = balance;
        communityMinimumToken = token;
        communityMinimumReputation = reputation;
    }

    function joinCommunity() public {
        CommunityMembers.push(msg.sender);
        CommunitySubscription(msg.sender, true);
    }

    /**
     * This removes one freelance from the community and updates the array CommunityMembers
     */
    function leaveCommunity() public {
        for (uint i = 0; i < CommunityMembers.length - 1; i++) {
            if (CommunityMembers[i] == msg.sender) {
                for (uint j = i; j < CommunityMembers.length - 1; j++) {
                    CommunityMembers[j] = CommunityMembers[j + 1];
                }
            delete CommunityMembers[CommunityMembers.length-1];
            CommunityMembers.length--;
            CommunitySubscription(msg.sender, false);
            return;
            }
        }    
    }
    
    /**
     * this funciton transfers funds from Community 
     */ 
    function transferFunds(address _to, uint256 amount) public onlyOwner returns(bool) {
        require (amount <= mytoken.balanceOf(this));
        mytoken.transfer(_to, amount);
        return true;
    }
}
//
//
// This contract deploys Community contracts 
//
//
//

contract CommunityFabriq is Ownable {    
    MyAdvancedToken public mytoken;
    Community public newcommunity;            // pour test
  
    event CommunityListing(address community );
    
    function CommunityFabriq (address token) public {
        require (token != address(0x0));
        mytoken = MyAdvancedToken(token);
    }
    
    /**
     * anyone can call this method to create a new Community contract
     * with the maker being the owner of this new contract
     */
    function createCommunityContract(string name, 
                            uint comtype,               // 0 open
                            uint balance,               // % token/reputation
                            uint mintoken,              // minimum token
                            uint minreputation,         // minimum reputation
                            uint com,                   // com on job
                            uint fees) 
                            public onlyOwner returns (Community)
    {
        require (balance<=100);
        require (minreputation <= 100);
        newcommunity = new Community(mytoken, name, comtype, balance, mintoken, minreputation, com, fees);
        newcommunity.transferOwnership(msg.sender);
        CommunityListing(newcommunity);
        return newcommunity;
    }

    /**
     *     Prevents accidental sending of ether to the factory
     */
    function () public {
        throw;
    }
}
