//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.7.0 < 0.8.0;


library LibSafe {
    uint256 constant internal smallTransactionThreshold = 5000000000;

    struct EventTag {
        uint256 dateStatusModif;
        uint256 etagIndex;
        uint8 etagStatus;
        string etagData;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
}
