//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./VoteManager.sol";
import "./CorporateKeyManager.sol";

contract QaxhRegistry is VoteManager, CorporateKeyManager {
	mapping (address => address) public userSafes;
	mapping (address => address) public corporateSafes;

	event RegisteredUserSafe(address _safe, address _platform);
	event RegisteredCorporateSafe(address _safe, address _platform);
	event DeletedUserSafe(address _safe, address _platform);
	event DeletedCorporateSafe(address _safe, address _platform);

	uint public platformCount;

	uint public constant ADD_KEY = 0x42;

	constructor() {
		super._addPendingKey(msg.sender);
		super._activatePendingKey(msg.sender);
                platformCount = 1;
	}

	function acceptKey()
	public
	keyPendingValidation(msg.sender)
	{
		uint vote = uint256(keccak256(abi.encodePacked(msg.sender, ADD_KEY)));
		if (countVotes(vote) == activatedCount)
		{
			super._activatePendingKey(msg.sender);
                        platformCount++;
			endVote(vote);
		}
	}

	function deleteKey()
	public
	keyActivated(msg.sender)
	{
		super._removeActivatedKey(msg.sender);
                platformCount--;
	}

	function inviteNewKey(address _key)
	public
	keyActivated(msg.sender)
	{
		uint vote = uint256(keccak256(abi.encodePacked(_key, ADD_KEY)));
		createVote(vote);
		super._addPendingKey(_key);
	}

	function voteForNewKey(address _key)
	public
	keyActivated(msg.sender)
	{
		uint vote = uint256(keccak256(abi.encodePacked(_key, ADD_KEY)));
		castVote(vote, msg.sender);
	}

	function registerUserSafe(address _safe)
	public
	keyActivated(msg.sender)
	{
		require(userSafes[_safe] == address(0x0), "Already registered");
		userSafes[_safe] = msg.sender;
		emit RegisteredUserSafe(_safe, msg.sender);
	}

	function registerCorporateSafe(address _safe)
	public
	keyActivated(msg.sender)
	{
		require(corporateSafes[_safe] == address(0x0), "Already registered");
		corporateSafes[_safe] = msg.sender;
		emit RegisteredCorporateSafe(_safe, msg.sender);
	}

	function deleteUserSafe(address _safe)
	public
	keyActivated(msg.sender)
	{
		require(userSafes[_safe] == msg.sender, "this safe is not the msg sender safe");
		delete userSafes[_safe];
		emit DeletedUserSafe(_safe, msg.sender);
	}

	function deleteCorporateSafe(address _safe)
	public
	keyActivated(msg.sender)
	{
		require(corporateSafes[_safe] == msg.sender, "corporateSafe[safe} is not msg.sender");
		delete corporateSafes[_safe];
		emit DeletedCorporateSafe(_safe, msg.sender);
	}
}
