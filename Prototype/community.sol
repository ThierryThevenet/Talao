// pour prototypage only
//
//
//
//
//

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
        uint CommunityMembership;                           // nb de freelancer
    } 
    
    mapping(address => CommunityStruct) MapCommunityStruct;
    mapping(address=>mapping(uint=>address))  MapFreelancer;        //address des freelancer par comunauté

   
// initialisation avec 2 communautés
// creator
    function Community(){
        address OpenExpert = (0xF82076776FeF59Ad28d4E1dEa91f366deCef0CA6);  // la communauté OpenExpert Serive Providr
        address Aerospace = (0xD53F199C942638BaC5E65C48B6D1555c1e226140);    // la communauté aerospace Emindhub
      
        MapCommunityStruct[OpenExpert]= CommunityStruct ('OpenExpert Serice Provider',1,1,0,100,0,0,0);
        MapCommunityStruct[Aerospace]= CommunityStruct ('Aerospace Experts',1,1,0,10,10,10,0);
        
        
    }
    
    function setupacommunity (address AddressCommunity, string Name, uint Type){
        MapCommunityStruct[AddressCommunity].CommunityName=Name;
        MapCommunityStruct[AddressCommunity].CommunityType=Type;
        MapCommunityStruct[AddressCommunity].CommunityState=1;
        
    }
        
    function setupvotingrules (address AddressCommunity, uint Balance, uint Token, uint Reputation) {
        MapCommunityStruct[AddressCommunity].CommunityBalanceForVoting = Balance;
        MapCommunityStruct[AddressCommunity].CommunityMinimumToken = Token;
        MapCommunityStruct[AddressCommunity].CommunityMinimumReputation = Reputation;
    }
//
//
    function getdataforvoting (address AddressCommunity) constant returns(uint Balance,uint Token,uint Reputation){
        Balance = MapCommunityStruct[AddressCommunity].CommunityBalanceForVoting;
        Token = MapCommunityStruct[AddressCommunity].CommunityMinimumToken;
        Reputation = MapCommunityStruct[AddressCommunity].CommunityMinimumReputation;
        return (Balance,Token,Reputation);
            }
    
    function joinacommunity(address community){
        uint c= MapCommunityStruct[community].CommunityMembership+=1;    
        MapFreelancer[community][c]=msg.sender;    
    }
     
    function getcommunitymembership(address community) constant returns (uint){
        return MapCommunityStruct[community].CommunityMembership;
        
        
    }
// end of contract    
}
    
