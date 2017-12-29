//
//
// pour prototypage only
//
// eMindHub
//
// version 1.0 
// Pour respecter l architecture du WP le coffre fort de certificats est uniquement un annuaire
// les contenus sont stockes off chain et ont une adresse et un identifiant de storage
// les meta donnees (skills par mots cles, etc) sont stockees off chain et font reference a un contentID
// lelien entre content ID et content address est fait ici
//
pragma solidity ^0.4.19;

import "browser/TokenFOWERC20.sol";

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
// it is a hub
//
contract DigitalVault is Owned{
    struct Content {
        uint    blockcertData;                  // to be defined
        uint    contentType;                    // certificate, ID, etc
        bytes32 contentAddress;                 // storage address it can be an IPFS hash here for instance
        uint    storageID;                      // storage media, IPFS, SWARM or others
        }

    uint public contentNb;
    uint public contentAccess;                  // for statistic

    MyAdvancedToken public mytoken;
    
    // contentID=>Content data
    mapping (bytes32=>Content) Vault;
    
    // msg = 0 addcontent failure as user has no access
    // msg = 1 contentid is added
    // msg = 2 contentid is removed
    // msg =3 content not removed as user has no access
    // msg = 4 contentid location has been delivered to user
    // msg = 5 contentid location note delivered as user has no access
    event DigitalCertificateVault (address indexed user, bytes32 contentid, uint msg);
    
    function DigitalVault (address token) public {
        mytoken=MyAdvancedToken (token);
    }
    
    /**
    * add content to Vault
    * only freelance can add content as owner=msg.sender
    */ 
    function addContent (bytes32 contentid,
                        uint cblockcert,
                        uint ctype,
                        bytes32 caddress,
                        uint cstorage) onlyOwner public returns (bool) {
        require (contentid !=0 && caddress != 0);
        if (mytoken.AccessAllowance(msg.sender, msg.sender)!=true){
            DigitalCertificateVault (msg.sender, contentid,0);
            return false;
        }
        Content memory newcontent = Content (cblockcert,ctype,caddress, cstorage);
        contentNb ++;
        Vault[contentid]=newcontent;
        DigitalCertificateVault (msg.sender, contentid,1);
    }

    /**
     * remove content
     */ 
    function removeContent (bytes32 contentid)  onlyOwner public {
        if (mytoken.AccessAllowance(msg.sender, msg.sender)==true){
            DigitalCertificateVault (msg.sender, contentid,3);
            return;
        }
        contentNb--;
        Vault[contentid]= Content (0,0,0,0);
        DigitalCertificateVault (msg.sender, contentid,2);
    }

    /**
    * Only client or agent or user cand get accees to content address
    * 
    */
    function getContentAddress (bytes32 contentid) public constant returns (bytes32,uint){
        if (mytoken.AccessAllowance(msg.sender, owner)!=true){
//            DigitalCertificateVault (msg.sender,contentid, 5);
            return (0x0,0);
        }
//        DigitalCertificateVault (msg.sender, contentid,4);
//        contentAccess++;
        return (Vault[contentid].contentAddress, Vault[contentid].storageID);   
    }
    
    /**
    *     Prevents accidental sending of ether to vault
    */
    function () public {
        throw;
    }
}
//
// This contract deploys DigitalVault contracts
//
contract DigitalVaultFactory is Owned {
    uint public nbVault;
    address public newvault;                                                    // pour test
    MyAdvancedToken mytoken;   

    mapping (address=>address) public FreelanceVault; 
    
    // msg = 0 user did not open an access to open a vault
    // msg = 1 vault already exists
    // msg = 5 Vault created
    event VaultCreation (address indexed talent, address vaultadddress, uint msg);

    function DigitalVaultFactory(address token) public {
        mytoken =MyAdvancedToken(token);
    }

    /**
     * Talent can call this method to create a new Digital Vault contract
     *  with the maker being the owner of this new vault
     */ 
    function createVaultContract () public {
        if (mytoken.AccessAllowance(msg.sender, msg.sender)==false){
            VaultCreation (msg.sender, myvault, 0);
            return;
        }
        if (FreelanceVault[msg.sender]!=0x0){
            VaultCreation (msg.sender, myvault, 1);
            return;
        }
        DigitalVault myvault = new DigitalVault(mytoken);
        newvault=myvault;                                                       // pour test
        FreelanceVault[msg.sender]=myvault;
        nbVault++;
        myvault.transferOwnership(msg.sender);
        VaultCreation (msg.sender, myvault, 5);
        return;
    }

    /**
     *     Prevents accidental sending of ether to the factory
     */
    function () public {
        throw;
    }
}


