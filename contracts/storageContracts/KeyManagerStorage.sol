// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/IUsersafeEvents.sol";
import "../libraries/LibIdentityManager.sol";

contract KeyManagerStorage {
    bytes32 constant KEY_STORAGE_POSITION = keccak256("qaxh.io.keymanager.storage");

    enum Status { NotAnOwner, Active }
    struct KeyStorage {
        Status status;
        mapping (address => Status) keyStatus;
        mapping (address => string) keyLabels;
        mapping (address => address) keyList;
        mapping(address => uint) appKeysDeadlines;
        address qaxh;
        address SENTINEL_KEYS;
        uint8 MAX_KEYS;
    }
    //event CertifyIdentityEvent(address certifier);
    //event CertifyData(string certifiedData);

    function keyManagerStorage() internal pure returns (KeyStorage storage keystore) {
        bytes32 position = KEY_STORAGE_POSITION;
        assembly {
            keystore.slot := position
        }
    }

    function setupUtils(address _qaxh) internal {
        KeyStorage storage keystore = keyManagerStorage();
        require(keystore.qaxh == address(0), "Qaxh setup can only be done once");
        keystore.qaxh = _qaxh;
    }
    /*

         /******************** 			MODIFIERS			***********************/

    /// @dev Reverts if the function wasn't called by one of the owner's keys.
    ///      After the code executes, refunds the gas spent to the owner's key
    ///      that called the function (i.e. tx.origin).
    /// @param includeQaxh Set to true to allow Qaxh to call this function.
    /************************************************************************/

    modifier filterAndRefundOwner(bool includeQaxh) {
        uint256 startGas = gasleft();
        KeyStorage storage keystore = keyManagerStorage();

        require(keystore.keyStatus[msg.sender] == Status.Active || (includeQaxh && msg.sender == keystore.qaxh),
                "This method can only be called by the owner of the safe");
        _;
    }

    modifier filterQaxh() {
        KeyStorage storage keystore = keyManagerStorage();
        require(msg.sender == keystore.qaxh, "This method can only be called by the qaxh address");
        _;
    }

    modifier alreadySetupModifier {
        LibIdentityManager.IdentityStorage storage identityStore = LibIdentityManager.identityStorage();
        require(identityStore.alreadySetup, "This safe does not have a delared identity");
        _;
    }

    // MODIFIERS

    /// @dev Return true if the indicated identityLevel is valid.
    modifier checkIdentityLevel(uint8 _identityLevel) {
        //TODO Add identityLevel value check once it is clearly defined in the specs
        _;
    }

}