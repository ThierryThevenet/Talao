
pragma solidity ^0.4.0;
contract Community {
    struct CommunityStruct {
        string CommunityName;
        uint CommunityState;                        // 0 inactif 1 actif
        uint CommunityType;                         // 0 open, 1 private
        uint CommunitySponsor;                      // si privée reference client
        uint CommunityBalanceForVoting;              // balance pour le vote 10 => 10% token et 90% reputation   
        uint CommunityMinimumToken;                 // nbn minimum de token pour voter
        uint CommunityMinimumReputation;                 //nb minimum de reputation pour voter    
    } 
    
    mapping(address => CommunityStruct) MapCommunityStruct;
    uint Index=0;                                   // pour recherche sequentielle
    address [] Group;
    
    function setcommunity (address AddressCommunity, uint Type){
        MapCommunityStruct[AddressCommunity].CommunityType=Type;
        MapCommunityStruct[AddressCommunity].CommunityState=1;
        Group[Index]=AddressCommunity;
        Index+=1;
    }
        
    function setforvoting (address AddressCommunity, uint Balance, uint Token, uint Reputation) {
        MapCommunityStruct[AddressCommunity].CommunityBalanceForVoting = Balance;
        MapCommunityStruct[AddressCommunity].CommunityMinimumToken = Token;
        MapCommunityStruct[AddressCommunity].CommunityMinimumReputation = Reputation;
    }
           
    function getdataforvoting (address AddressCommunity) constant returns(uint Balance,uint Token,uint Reputation){
        Balance = MapCommunityStruct[AddressCommunity].CommunityBalanceForVoting;
        Token = MapCommunityStruct[AddressCommunity].CommunityMinimumToken;
        Reputation = MapCommunityStruct[AddressCommunity].CommunityMinimumReputation;
        return (Balance,Token,Reputation);
            }
    
    function getcommunigtydata (address AddressCommunity) constant returns (CommunityStruct ){
        return MapCommunityStruct[AddressCommunity];
    }
    
// end of contract    
}
    
