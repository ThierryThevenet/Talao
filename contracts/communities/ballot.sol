// emindhub proto only
// one ballot smart contract pour chaque vote
// version 1.0
//
//
pragma solidity ^0.4.19;

import "browser/Owned.sol";
import "browser/TokenFOWERC20.sol";
import "browser/Community_v12.sol";
import "browser/Freelancer_v11.sol";

contract Ballot is Owned{

    struct Voter {
        uint tokenbalance;                      // for convenience, comes from token smart contract
        uint reputation;                        // for convenience, comes from Freelancer smart contract
        uint weightedvote;                      // for convenience,  will be calculated
        bool voted;
        uint8 vote;
        address delegate;
    }

    struct Proposal {
        uint voteWeight;
    }
    
    // for convenience, come from Community smart contract. community state variable needed to vote
    uint minimumToken;
    uint minimumReputation;
    uint balanceForVoting;
    
    address chairperson;
    
    // contract address
    MyAdvancedToken mytoken;
    Freelancer myfreelancer;
    Community mycommunity;
    
    mapping(address => Voter) voters;
    
    Proposal[] proposals;
    
    // msg=0 user not within this community
    // msg=1 user does not have enough token to vote
    // msg=2 user is not active
    // msg=3 user does not have enough reputation to vote
    // msg=4 user has already voted
    event MyBallot(address indexed user, uint msg);

    /**
     * Create a new ballot with $(_numProposals) different proposals.
     * chairperson does not vote
     */ 
    function Ballot(uint8 _numProposals,
                    address token_contract,
                    address community_contract,
                    address freelancer_contract) public {
        chairperson = msg.sender;
        proposals.length = _numProposals;
        
        // local smart contract address init for future calls
        mytoken = MyAdvancedToken(token_contract);
        myfreelancer = Freelancer (freelancer_contract);
        mycommunity = Community (community_contract);
        
        // Community state variable init, those data are public in contract Community
        minimumToken = mycommunity.communityMinimumToken();
        minimumReputation=mycommunity.communityMinimumReputation();
        balanceForVoting = mycommunity.communityBalanceForVoting();
    }

    /**
     * Give $(toVoter) the right to vote on this ballot.
     * May only be called by $(chairperson).
     */ 
    function giveRightToVote(address toVoter) public {
        require (msg.sender == chairperson);
        // to check this user belongs to community
        if (mycommunity.check(toVoter)==false){
            MyBallot(toVoter,0);
            return;
        }
        // to check this user has enough token to vote
        if (mytoken.balanceOf(toVoter)<minimumToken){
            MyBallot(toVoter,1);
            return;
        }
        uint a; int b; uint c;
        // we use external function as those state variables are not public in Freelancer contract
        (a,b,c)= myfreelancer.getFreelancerDataForVoting(toVoter,mycommunity);
        if (a==0) {
            MyBallot(toVoter,2);
            return;
        }
        // to check this user has ebnough reputation to vote
        if ((uint(b)+uint(c)) < minimumReputation) {
            MyBallot(toVoter,3);
            return;
        }
        if (voters[toVoter].voted){
            MyBallot(toVoter,4);
            return;
        }
        voters[toVoter].reputation=uint(b)+uint(c);
        voters[toVoter].tokenbalance=mytoken.balanceOf(toVoter);
        voters[toVoter].weightedvote=balanceForVoting*voters[toVoter].tokenbalance+
                                    ((100-balanceForVoting)*voters[toVoter].reputation)/100;
    }

    /**
     * Delegate your vote to the voter $(to).
     */ 
    function delegate(address to) public {
        Voter storage sender = voters[msg.sender]; // assigns reference
        if (sender.voted) return;
        while (voters[to].delegate != address(0) && voters[to].delegate != msg.sender)
            to = voters[to].delegate;
        if (to == msg.sender) return;
        sender.voted = true;
        sender.delegate = to;
        Voter storage delegateTo = voters[to];
        if (delegateTo.voted){
            proposals[delegateTo.vote].voteWeight += sender.weightedvote;}
        else {
            delegateTo.weightedvote += sender.weightedvote;}
    }

    /**
     * Give a single vote to proposal $(toProposal).
     */
    function vote(uint8 toProposal) public {
        Voter storage sender = voters[msg.sender];
        if (sender.voted || toProposal >= proposals.length) return;
        sender.voted = true;
        sender.vote = toProposal;
        proposals[toProposal].voteWeight += sender.weightedvote;
    }

    function winningProposal() public constant returns (uint8 _winningProposal) {
        uint256 winningVoteWeight =0;
        for (uint8 prop = 0; prop < proposals.length; prop++)
            if (proposals[prop].voteWeight > winningVoteWeight) {
                winningVoteWeight = proposals[prop].voteWeight;
                _winningProposal = prop;
            }
    }

    /**
     * self desctruct when ballot is over
     */ 
    function kill() public  {
        require (msg.sender == chairperson);
        selfdestruct(owner); 
    }
    
    /**
     *     Prevents accidental sending of ether to the factory
     */
    function () public {
        throw;
    }
}
