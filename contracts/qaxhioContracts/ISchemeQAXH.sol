//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

// @title An interface contract for SchemeQAXH.
// @description: An interface of Scheme that allow other contracts to interact with Scheme's functions
// @author Sébastien PIERRE

interface ISchemeQAXH {

    function isInScheme (address addr) external view returns (bool);

    function getLinkedPlatform (address addr) external view returns (address);

    function getCustomerId (address addr) external view returns (uint256);

    function getMoney (address addr) external view returns (uint256);

    function getSafeType (address addr) external view returns (uint256);

    function addSafe (address addr, uint256 _safeType, uint256 _customerId, uint256 _money) external returns (bool);

    function getAllMoney () external view returns (address[] memory);

    function addMoney (address addrMoney, address platform) external returns (bool);

    function acceptMoney (address addrMoney) external returns (bool);

    function isTypeMoney (address addrMoney) external view returns (uint8);

    function getMoneyLinkedPlatform (address addrMoney) external view returns (address);

    function deleteMoney () external returns (bool);

    //Administration

    function createNewOwnership(address _newOwner) external returns (bool);

    function votingOwner() external returns (bool);

    function acceptOwnership() external returns (bool);

    function transferNewOwnership(address _newOwner) external returns (bool);

    function acceptTransferOwnership() external returns (bool);

    function existingVote () external view returns (bool);

    function alreadyVoted (address _voter) external view returns (bool);

    function numberVotes () external view returns (uint256);
}