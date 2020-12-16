//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./ChildSafe.sol";
import "./CorporateSafe.sol";

/// @title Genisys CorporateSafe - A multisignature safe for corporates
/// @author Mehdi Mobarek
contract GenisysSafe is CorporateSafe(2, "3.a") {
	//VARIABLES
	uint public accountCorporateId;
	string public QGbody;

	address public constant CHILDREN_SENTINEL = address(0x44);

	enum KEY_ACTION {
		KEY_ADD,
		KEY_REMOVE
	}

	mapping (address => address) public children;
	uint public childrenCount;

	event AddedChild(address child);

	//CONSTRUCTOR
	constructor(address _safeKey,
		    uint8 _userTrustLevel,
		    uint _accountCorporateId,
		    uint _numberOfAdministrators,
                    string memory _QGbody)
	{
		parentSafe = PARENT_SENTINEL;
		qaxhMasterKey = msg.sender;

		accountCorporateId = _accountCorporateId;
		creatorTrustLevel = _userTrustLevel;
		numberOfAdministrators = _numberOfAdministrators;

		children[CHILDREN_SENTINEL] = CHILDREN_SENTINEL;

                QGbody = _QGbody;

		// Register the User Safe Key
		addPendingKey(_safeKey, _userTrustLevel);
	}

	// Overrides CorporateSafe
	function isActivated()
		internal
		override
		view
		returns (bool)
	{
		return activatedCount == numberOfAdministrators;
	}

	//un corporate safe (genisys doit toujours avoir "hasOverride" false)
	function hasOverride(address)
		public
		override
		view
		returns (bool)
	{
		return false;
		//this; // Silence state mutability warning
	}

	/* Check that a child is in the list of children, and that it points
	   to us. */
	modifier validChild(address _child)
	{
		require(children[_child] != address(0x0), "no child");
		ChildSafe childSafe = ChildSafe(_child);
		require(childSafe.parentSafe() == address(this), "not the parent");
		_;
	}

	function addPendingKey(address _safeKey, uint8 _userTrustLevel)
		public
		checkSender(qaxhMasterKey)
		minTrustLevel(_userTrustLevel)
	{
		require(activatedCount + pendingCount + 1 <= numberOfAdministrators,
			"More keys than admins.");
		super._addPendingKey(_safeKey);
	}

	/* TODO: Should the pending key be able to remove itself? */
	function removePendingKey(address _safeKey)
		public
		checkSender(qaxhMasterKey)
	{
		super._removePendingKey(_safeKey);
	}

	function acceptUserSafeKey()
		public
		keyPendingValidation(msg.sender)
	{
		super._activatePendingKey(msg.sender);
		activated = isActivated();
	}

	function deleteUserSafeKey(address _safeKey)
		public
		checkSender(qaxhMasterKey)
	{
		super._removeActivatedKey(_safeKey);
		activated = isActivated();
	}

	function addChild(address _child)
		public
		checkActivation
		isAdministrator(msg.sender)
	{
		ChildSafe c = ChildSafe(_child);
		require(c.parentSafe() == address(this), "Child parent not us.");

		children[_child] = children[CHILDREN_SENTINEL];
		children[CHILDREN_SENTINEL] = _child;
		childrenCount++;

		emit AddedChild(_child);
	}

	function getChildren()
		public
		view
		returns (address[] memory)
	{
		address[] memory ret = new address[](childrenCount);

		address curr = children[CHILDREN_SENTINEL];
		for (uint i = 0; i < childrenCount; i++)
		{
			ret[i] = curr;
			curr = children[CHILDREN_SENTINEL];
		}

		return ret;
	}

	/* Anyone could call this function, but this is not a problem because
	   of the way the vote is derived from the sender, and because castVote
	   checks that the vote exists.
	   Administrators that want to admin a ChildSafe don't need to call
	   this function.
	*/
	function acceptChildAdminRequest(address _child)
		public
		checkActivation
		validChild(_child)
	{
		if (!isNotAnOwner(msg.sender))
			return;

		uint256 vote = uint256(
			keccak256(abi.encodePacked(_child, msg.sender, KEY_ACTION.KEY_ADD))
		);
		castVote(vote, msg.sender);
	}

        function startVoteAddKeyInChild(address _child, address _key,
					bool hasOverride_)
            public
            checkActivation
            isAdministrator(msg.sender)
            validChild(_child)
        {
		ChildSafe c = ChildSafe(_child);
		c.addPendingKey(_key, hasOverride_);
		uint256 vote = uint256(
			keccak256(abi.encodePacked(_child, _key,
                                                   KEY_ACTION.KEY_ADD))
		);
                createVote(vote);
        }

	/* TODO: Compute the vote on the server to (maybe) save gas */
	function voteAcceptKeyInChild(address _child, address _key)
		public
		checkActivation
		isAdministrator(msg.sender)
		validChild(_child)
	{
		uint256 vote = uint256(
			keccak256(abi.encodePacked(_child, _key, KEY_ACTION.KEY_ADD))
		);
		ChildSafe child = ChildSafe(_child);
		castVote(vote, msg.sender);

		if (countVotes(vote) >= numberOfAdministrators)
		/* >= Because the has to vote for itself, but an administrator might want to
	        admin a ChildSafe
	        */
		{
			require(!isNotAnOwner(_key) || hasVoted(vote, _key),
				"waiting for key to accept itself");
			endVote(vote);
			child.activatePendingKey(_key);
		}
	}

	function removeKeyFromChild(address _child, address _key)
		public
		checkActivation
		isAdministrator(msg.sender)
		validChild(_child)
	{
		ChildSafe c = ChildSafe(_child);
		c.removeActivatedKey(_key);
	}

	// Overrides Corporate
	function isTransactionExecutable(uint _nVotes, bool)
		internal
		override
		view
		returns (bool)
	{
		// No need to check override, because all admins must sign in
		// a GenisysSafe
		return _nVotes == numberOfAdministrators;
	}
}
