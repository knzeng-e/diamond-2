//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.4.21 < 0.8.0;

contract UsersafeEvents {
    event CertifyIdentity(address certifier);
    event CertifyData(string certifiedData);
    event EtagCreated(
        string certifiedData,
        uint8 etagStatus,
        uint256 etagIndex,
        uint256 etagTimeStamp
    );
    event etagStatusModify(
        uint256 indexed _etagIndex,
        uint8 indexed newEtagStatus
    );
}