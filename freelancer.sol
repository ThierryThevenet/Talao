// pour prototypage only
//
//
//
//
//

pragma solidity ^0.4.0;
contract Freelancer {
 //
// descriptif d un freelancer  
    struct CommunityMember {
        uint EmindhubIndentifier;        // identifiant du freelance sur EmindHub
        uint CommunityNumber;           // 0 pour OpenExpert Service Provider  1 pour Emindhub    
        uint State;                      // inactif 0 actif 1
        int ContributionRating;        // represente l implication dans la communauté, attention au type uint et int
        int ContributionRatingBlock;   // pour gere la decay, on met le muneto de block last upate
        uint ClientRating1;           // 4 dernieres evaluations clients
        uint ClientRating2;
        uint ClientRating3;
        uint ClientRating4;
    }
    mapping (address => CommunityMember) public freelancerdata ;   // tableau d acces par adresse au freelance
    int BlockPerQuarter = 650000;               // 650000 block mines tous les 3 mois environ
    address [] ArrayFreelancerIndex;         //compteur pour recherceh sequentielle
    uint Index=0;                           // index du compteur
    
// creator, initialisation
// creation en dur du freelancer Thierry sur la communauté OpenExpert Serice Provider (adresse sur sur Ropsten) 
// avec rating de contribtion de 50 et les 4 dernieres evaluations 
// client a 10. La dernier cacul de cntribution avec decay réalisé au block 4400000
    function Freelancer() {
        freelancerdata[0x87B787CD17a8D68db002f806cC0A3DA323EaC25a] = CommunityMember (0,1,50,4400000,10,10,10,10);
        ArrayFreelancerIndex[1]=(0x87B787CD17a8D68db002f806cC0A3DA323EaC25a);
        Index+=1;
    }
//
// mise a jour de la dernieres evaluation client pour un freelance, l eval 4 est recopiée dans la 3 etc
    
    function updateclientrating(address AddressFreelancer, uint LastRating) {
        freelancerdata[AddressFreelancer].ClientRating1=freelancerdata[AddressFreelancer].ClientRating2;
        freelancerdata[AddressFreelancer].ClientRating2=freelancerdata[AddressFreelancer].ClientRating3;       
        freelancerdata[AddressFreelancer].ClientRating3=freelancerdata[AddressFreelancer].ClientRating4;
        freelancerdata[AddressFreelancer].ClientRating4=LastRating;
       
     }
//
//  mise a jour d'une contribution d un freelancer avec prise en compte du decay de 1 point par650000 blocks
    function updatecontribution(address AddressFreelancer, int LastContribution){
        freelancerdata[AddressFreelancer].ContributionRating= freelancerdata[AddressFreelancer].ContributionRating+LastContribution; 
        freelancerdata[AddressFreelancer].ContributionRating-=  (int(block.number)-freelancerdata[AddressFreelancer].ContributionRatingBlock)/BlockPerQuarter;
        freelancerdata[AddressFreelancer].ContributionRatingBlock= int(block.number); // mise a jour de la date du dernier calcul de reputation
    }
// freelancer registration 
// par defaut tout est à 0
// comunitynumber = 1 pour emindhub, 0 pour services providers -founder, etc)    
    function registration(unit EmindhubIdentifier, uint Community){
        freelancerdata[msg.sender].EmindhubIdentifier = EmindhubIdentifier; 
        freelancerdata[msg.sender].CommunityNumber = Community; 
        freelancerdata[msg.sender].ContributionRatingBlock= int(block.number); // mise a jour de la date du dernier calcul de reputation
        freelancerdata[msg.sender].State=1;
        Index+=1;                                       // mise a jour de l index pour recherceh sequentielle
        ArrayFreelancerIndex[Index]=(msg.sender);       // mise a jour de l index
    }

// pour sortir un freelancer de la base
    function firing(address AddressFreelancer){
        freelancerdata[AddressFreelancer].State =0;
        // on ne remet pas l index a jour....
    }


    function getfreelancerdatafromaddress(address AddressFreelancer) constant returns (CommunityMember){
        return freelancerdata[AddressFreelancer];
    }

// pour recherhe sequentielle    
    function getfreelancerdatafromindex(uint MyIndex) constant returns (CommunityMember){
        return freelancerdata[ArrayFreelancerIndex[MyIndex]];
    }
// pour recherche sequentielle
    function getNbFreelancer() constant returns (uint){
        return Index;
    }
    
    





// end of contract
 }
 