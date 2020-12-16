//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

/// @title IdentityManager- A contract that handles identity certification for the QaxhModule
/// @author Loup Federico & Mickael Proust

library LibIdentityManager {
    bytes32 constant IDENTITY_STORAGE_POSITION = 0xd5892ab02db8dccd4f196bd3f3ee1b00751eb14e6af302cbe02836b6e1fc2126; //keccak256("qaxh.io.identity.storage");

    struct IdentityStorage {
        uint8 QB_number; // Number of active and inactive QBs (status 1 & 2)
        uint8 identityLevel;
        uint8 ageOfMajority;
        uint8 safeType;
        uint256 QB_index;
        bool alreadySetup;
        string QI_hash;
        string QE_hash;
        string safeVersion;
        string checkHash;
        string customerId;
        QB_struct[] QB_structs;
        // mapping (uint256 => QB_struct) QB_structs;
    }

    struct QB_struct{
        string QB_hash; // QB_hash of the QB_data of the user
        uint8 ibanTrustLevel; // 0 undeclared ou QB "removed", 1 declared by the user, for now
        uint8 status; // status variable : 0 undefined, 1 active, 2 inactive
    }

    function identityStorage() internal pure returns (IdentityStorage storage identityStore) {
        bytes32 position = IDENTITY_STORAGE_POSITION;
        assembly {
            identityStore.slot := position
        }
    }

     function setupIdentity(
         string memory _QI_hash,
         string memory _QE_hash,
         uint8 _identityLevel,
         uint8 _ageOfMajority,
         string memory _customerId
         ) internal {

            IdentityStorage storage identityStore = identityStorage();
             
            require(!identityStore.alreadySetup, "This safe has already a declared identity");
            identityStore.QI_hash = _QI_hash;
            identityStore.QE_hash = _QE_hash;
            identityStore.QB_index = 0;
            identityStore.QB_number = 0;
            identityStore.identityLevel = _identityLevel;
            identityStore.ageOfMajority = _ageOfMajority;
            identityStore.customerId = _customerId;
            identityStore.alreadySetup = true;
    }

    /// Update the ageOfMajority value from the safe
    function updateAgeOfMajority(uint8 _ageOfMajority) internal {
        IdentityStorage storage identityStore = identityStorage();
        identityStore.ageOfMajority = _ageOfMajority;
    }
}