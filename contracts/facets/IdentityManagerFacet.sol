//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;
pragma experimental ABIEncoderV2;


/// @title IdentityManager- A contract that handles identity certification for the QaxhModule
/// @author Loup Federico & Mickael Proust

import "../interfaces/IUsersafeEvents.sol";
import "../libraries/LibIdentityManager.sol";
import "../storageContracts/KeyManagerStorage.sol";

contract IdentityManagerFacet is KeyManagerStorage, IUsersafeEvents {

    constructor(){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        identityStore.safeType = 1;
        identityStore.safeVersion = "6.8";
        identityStore.checkHash = "None";
    }

    /// @dev Emits an event that proves the validation and approval of the identity contained
    ///      in the contract by the sender of the transaction `tx.origin.
    ///      N.B: This function must remain internal and all required precautions from the QaxhModule
    ///      must be taken outside of it.
    function certifyIdentity() internal {
        emit CertifyIdentity(msg.sender);
    }

      // AUTHENTICATION PROCESS

    /// @dev If all conditions are met, emit the countersignature event containing the Qaxh client's public key.
    ///      Only an active key can accept the safe identity.
    function acceptIdentity() public filterAndRefundOwner(false) {
        certifyIdentity();
    }

    

    /// Update the checkHash value from the safe
    function updateCheckHash(string memory _checkHash) public filterAndRefundOwner(false) alreadySetupModifier {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        identityStore.checkHash = _checkHash;
    }

    /// Add or modify a QB of the userSafe

    function addQB(string memory _QB_hash, uint8 _ibanTrustLevel) public filterAndRefundOwner(true) alreadySetupModifier{
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        identityStore.QB_structs[identityStore.QB_index].QB_hash = _QB_hash;
        identityStore.QB_structs[identityStore.QB_index].ibanTrustLevel = _ibanTrustLevel;
        identityStore.QB_structs[identityStore.QB_index].status = 2;
        identityStore.QB_index++;
        identityStore.QB_number++;
    }

    // Remove a QB by replacing its value in the mapping by "removed", and update his ibanTrustLevel

    function removeQB(uint256 _QB_index) public filterAndRefundOwner(false) alreadySetupModifier{
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        identityStore.QB_structs[_QB_index].QB_hash = "removed";
        identityStore.QB_structs[_QB_index].ibanTrustLevel = 0;
        identityStore.QB_structs[_QB_index].status = 0;
        identityStore.QB_number--;
    }

    /// Activate a QB by updating its status to 1, only usable by the owner

    function activateQB(uint256 _QB_index) public filterAndRefundOwner(false) alreadySetupModifier{
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        identityStore.QB_structs[_QB_index].status = 1;
    }

    // List all of the QBs from the QBh

    function getActiveQBIndexList () public view alreadySetupModifier returns (uint256[] memory) {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        
        uint256[] memory indexList = new uint256[](identityStore.QB_number);
        uint256 i;
        uint8 j = 0;
        for (i = 0; i < identityStore.QB_index; i++){
            if (keccak256(abi.encodePacked(identityStore.QB_structs[i].QB_hash)) != keccak256(abi.encodePacked("removed"))){
                indexList[j] = i;
                j++;
            }
        }
        return indexList;
    }

    // Get QB_hash from Index

    function getQBfromIndex (uint256 _QB_index) public view alreadySetupModifier returns (string memory) {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        
        return identityStore.QB_structs[_QB_index].QB_hash;
    }

    // Get ibanTrustLevel from Index

    function getIbanTrustLevelFromIndex(uint256 _QB_index) public view alreadySetupModifier returns (uint8) {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        
        return identityStore.QB_structs[_QB_index].ibanTrustLevel;
    }

    // Get status from Index

    function getStatusFromIndex(uint256 _QB_index) public view alreadySetupModifier returns (uint8){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        
        return identityStore.QB_structs[_QB_index].status;
    }

    // Update the ibanTrustLevel of a QB

    function updateIbanTrustLevel(uint256 _QB_index, uint8 _ibanTrustLevel) public filterAndRefundOwner(true) alreadySetupModifier {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        
        identityStore.QB_structs[_QB_index].ibanTrustLevel = _ibanTrustLevel;
    }

    modifier isAdministrator(address _key) {
        KeyStorage storage keystore = keyManagerStorage();

        require(_key == address(0) || _key == keystore.SENTINEL_KEYS, "Not an administrator");
        //require(!isValidKey(_key), "Not an administrator");
        _;
    }   
}
