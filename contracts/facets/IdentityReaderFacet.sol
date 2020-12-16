//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;
pragma experimental ABIEncoderV2;

import "../libraries/LibIdentityManager.sol";

contract IdentityReaderFacet {
        function QB_number() external view returns (uint8){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.QB_number;
    }

    function identityLevel() external view returns (uint8){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.identityLevel;
    }

    function ageOfMajority() external view returns (uint8){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.ageOfMajority;
    }

    function safeType() external view returns (uint8){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.safeType;
    }

    function QB_index() external view returns (uint256){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.QB_index;
    }

    function alreadySetup() external view returns (bool){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.alreadySetup;
    }

    function QI_hash() external view returns (string memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.QI_hash;
    }

    function QE_hash() external view returns (string memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.QE_hash;
    }

    function safeVersion() external view returns (string memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.safeVersion;
    }

    function checkHash() external view returns (string memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.checkHash;
    }

    function customerId() external view returns (string memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.customerId;
    }

    function QB_structs() external view returns (LibIdentityManager.QB_struct[] memory){
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();

        return identityStore.QB_structs;
    }
}
