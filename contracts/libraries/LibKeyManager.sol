// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";

library LibKeyManager {
    // bytes32 constant KEY_STORAGE_POSITION = keccak256("qaxh.io.usersafe.storage");

    // enum Status { NotAnOwner, Active }
    // struct KeyStorage {
    //     Status status;
    //     mapping (address => Status) keyStatus;
    //     mapping (address => string) keyLabels;
    //     mapping (address => address) keyList;
    //     mapping(address => uint) appKeysDeadlines;
    //     address qaxh;
    //     address constant SENTINEL_KEYS;
    //     uint8 constant MAX_KEYS;
    // }

    // function keyManagerStorage() public pure returns (KeyStorage storage keystore) {
    //     bytes32 position = KEY_STORAGE_POSITION;
    //     assembly {
    //         keystore.slot := position
    //     }
    // }
}