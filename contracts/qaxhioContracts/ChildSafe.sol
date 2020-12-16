//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./GenisysSafe.sol";
import "./CorporateSafe.sol";
import "../facets/IdentityReaderFacet.sol";

contract ChildSafe is CorporateSafe(3, "3.a") {
        // This is named QGbody to be able to re use the genisys blocks.
	string public QCbody;
        mapping (address => bool) public adminOverride;
        uint public accountCorporateId;

	constructor(address _parent, uint _numberOfAdministrators, uint8 _userTrustLevel, uint8 _commitmentLevel,
		uint8 _delegationLevel, string memory _QCbody)
	{
		qaxhMasterKey = msg.sender;
		parentSafe = _parent;

		numberOfAdministrators = _numberOfAdministrators;
		creatorTrustLevel = _userTrustLevel;
		corporateDelegationLevel = _delegationLevel;
		corporateCommitmentLevel = _commitmentLevel;

                GenisysSafe parent = GenisysSafe(_parent);
                accountCorporateId = parent.accountCorporateId();

                QCbody = _QCbody;
	}

	/* Overrides CorporateSafe */
	function hasOverride(address _addr)
		public
		view
		override
		returns (bool)
	{
		return _addr == parentSafe || adminOverride[_addr];
	}

	// Overrides CorporateSafe
	function isActivated()
		internal
		override
		view
		returns (bool)
	{
		if (corporateDelegationLevel == 6)
			return activatedCount == numberOfAdministrators;
		return activatedCount == corporateDelegationLevel;
	}

	// Overrides Corporate
	function isTransactionExecutable(uint _nVotes, bool _override)
		internal
		override
		view
		returns (bool)
	{
		if (_override)
			return true;
		if (corporateCommitmentLevel == 6)
			return _nVotes == numberOfAdministrators;
		return _nVotes >= corporateCommitmentLevel;
	}

	function removeActivatedKey(address _key) public
	{
		require(msg.sender == _key || msg.sender == parentSafe,
			"not authorized to remove key");
		super._removeActivatedKey(_key);
		activated = isActivated();
                delete adminOverride[_key];
	}

	function activatePendingKey(address _key) public
		checkSender(parentSafe)
	{
		super._activatePendingKey(_key);
		activated = isActivated();
	}

	function addPendingKey(address _key, bool hasOverride_) public
		checkSender(parentSafe)
	{
		IdentityReaderFacet _identity = IdentityReaderFacet(_key);
		require(_identity.identityLevel() >= creatorTrustLevel, "Trust level too low");
		super._addPendingKey(_key);
                adminOverride[_key] = hasOverride_;
	}
}
