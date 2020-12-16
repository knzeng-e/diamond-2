//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.7.0 < 0.8.0;

library LibEtags {

    struct EventTag {
        uint256 dateStatusModif;
        uint256 etagIndex;
        uint8 etagStatus;
        string etagData;
    }
}