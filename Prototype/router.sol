pragma solidity ^0.4.9;
// Prototype only
//
// router d address pour Openexpert
// c ets le premier smart conract a deployer
//
// adresse router 0x9eb3b6ff4563e68fd0e38f106fd7124efbc8300f

contract Router{
    struct AddressStruct{
        string Name;
        address Route;
        address Creator;
        uint Time;
        
    } 
    AddressStruct[50] OpenExpertAddress;
    uint Index;
   
// initialisation du router au 31 octobre 2017    
    function Router(){
        
        OpenExpertAddress[1].Name="smart contract EXP token";              
        OpenExpertAddress[1].Route=(0x5ABAE5Bf48c44874A3aa85137A9500130BF4Ac29);
    
        OpenExpertAddress[2].Name="smart contract Freelancer";              
        OpenExpertAddress[2].Route=(0x2ABAE5Bf48c44874A3aa85137A9500130BF4Ac29);
        
        OpenExpertAddress[3].Name="smart contract Community";              
        OpenExpertAddress[3].Route=(0x3ABAE5Bf48c44874A3aa85137A9500130BF4Ac29);
        
        OpenExpertAddress[4].Name="OpenExperts Community Fund";              
        OpenExpertAddress[4].Route=(0xF82076776FeF59Ad28d4E1dEa91f366deCef0CA6);
       
       
        Index=4;
        
    }
    function setnewroute(string NewRouteName, address NewRouteAddress) public returns (uint ){
    
        Index+=1;
        OpenExpertAddress[Index].Name=NewRouteName;
        OpenExpertAddress[Index].Route=NewRouteAddress;
        OpenExpertAddress[Index].Creator=msg.sender;
        OpenExpertAddress[Index].Time=block.timestamp;
        return Index;
    } 
    function updateroute(uint p, address route){
        if (p<=Index){
        OpenExpertAddress[p].Route=route;
        OpenExpertAddress[p].Creator=msg.sender;
        OpenExpertAddress[p].Time=block.timestamp; 
        return;
        }
        throw;
    }
    
    function getroute(uint p)  constant returns (string , address, address, uint ){              
         
        if (p < Index+1){
          
          return (OpenExpertAddress[p].Name , OpenExpertAddress[p].Route, OpenExpertAddress[p].Creator, OpenExpertAddress[p].Time);  
        }
            throw;
        } 
        
        
      
    
}