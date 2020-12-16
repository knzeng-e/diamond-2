//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./ERC20.sol";

contract QAXHU is ERC20 {

    string public name = "QAXHU";     // Set the name for display purposes
    string public symbol = "QXH";
    uint8 public decimals = 2;
    uint256 public initSup = 100000000;

    constructor() {
        _mint(msg.sender, initSup);
    }
}
