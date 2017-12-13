pragma solidity ^0.4.18;
//
// pour prototypage only
//
// eMindHub
//
//

import "browser/TokenEXPERC20.sol";

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

// Digital Vault smart contract for each talent
// its a kinfd of metadat for only one key (skill).
// limited number of skills to 3 for proto

contract DigitalVault is Owned{

// 
struct Content {
    uint Skill1;   // just 3 skills to be simple and because nested arrays not allowed 
    uint Skill2;
    uint Skill3;
    bytes32 Contentaddress;  // its an IPFS hash here
    }

address factory;
Content [] private Vault;


    function DigitalVault (address _factory) public {
        factory =_factory;
        }
    
// add content to Vault
    function AddContent (bytes32 newcontentaddress, uint s1, uint s2, uint s3) onlyOwner public {
        Content memory NewContent;
        NewContent.Contentaddress=newcontentaddress;
        NewContent.Skill1=s1;
        NewContent.Skill2=s2;
        NewContent.Skill3=s3;
        Vault.push(NewContent);
    }

// remove content
    function RemoveContent (bytes32 content)  onlyOwner public {
    require (msg.sender==factory);
    for (uint i=1; i<= Vault.length; i++){
        if (Vault[i].Contentaddress==content){
            for (uint y =i; y<=Vault.length-1; y++) Vault[y]=Vault[y+1];
            }
        }
    }

// client access to content through factory    
    function GetContent (uint skill) view public returns (bytes32){
        require (msg.sender==factory);
        for (uint i=1; i<= Vault.length; i++){
            if (Vault[i].Skill1==skill || Vault[i].Skill2==skill || Vault[i].Skill3==skill) 
            return (Vault[i].Contentaddress);     
            }        
        return (0x0);    
        }

        
    
}

// This contract deploys DigitalVault contracts
// and allows client to access freelance certfcates

contract DigitalVaultFactory is Owned {
// for test only
    address public newvault;

    MyAdvancedToken token;   
    // freelance=>vault
    mapping (address=>address) public FreelanceVault; 
    
    event VaultCreation (address indexed talent, address vaultcontract);

    function DigitalVaultFactory(address _token) public {
        token =MyAdvancedToken(_token);
    }



    function verify(address contractaddress) public constant returns (address owner){
        DigitalVault _Vault = DigitalVault (contractaddress);
        owner = _Vault.owner();    
        }

// client access to get Contentaddress    
    function GetFreelanceContent (address freelance, uint skill) constant public returns (bytes32){
        require (token.AccessAllowance(msg.sender, freelance)==true);
        return (DigitalVault(FreelanceVault[freelance]).GetContent(skill));     
                    
            
        }



    // Talent can call this method to create a new Digital Vault contract
    // with the maker being the owner of this new contract
              
    function CreateVaultContract () public {
         
        address myvault = new DigitalVault(owner);
        
        // pour test
        newvault=myvault;
        
            
        FreelanceVault[msg.sender]=myvault;
        
        // Set the owner to whoever called the function
        DigitalVault(myvault).transferOwnership(msg.sender);
        VaultCreation (msg.sender, myvault);
        }

  
}



