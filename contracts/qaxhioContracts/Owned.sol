//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

/// @title A contract which creates ownership for a contract (single owner)
/// @author Sébastien PIERRE

import "./Context.sol/";

contract Owned is Context {

    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = _msgSender();
    }

    modifier onlyOwner {
        require(_msgSender() == owner, "you are not the owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(_msgSender() == newOwner, "you are not the new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}