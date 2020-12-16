//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./GenisysSafe.sol";
import "./CorporateSafe.sol";

/// @title UserSafeExtension - A smart contract which contains methods to extend user safe
/// @author Mehdi Mobarek & Robin Jeanne

contract UserSafeExtension {

/*
    function addPendingKey(address _corporateSafe_address, uint8 _administratorRank, uint8 _userTrustLevel, string memory _label) public {
	bool success = _corporateSafe_address.call(
		abi.encodeWithSignature("addPendingKey(address, uint8, uint8, string)",
				       address(this),
				       _administratorRank,
				       _userTrustLevel,
				       _label));
	require(success, "Call to addPendingKey failed");
    } */

	function addPendingKey(address _corporateSafe_address, uint8 _administratorRank, uint8 _userTrustLevel, string memory _label) public {
		_corporateSafe_address.call(abi.encodeWithSignature("addPendingKey(address, uint8, uint8, string)",
				       address(this),
				       _administratorRank,
				       _userTrustLevel,
				       _label));
    }

    function acceptKey(address _corporateSafe_address) public {
        GenisysSafe s = GenisysSafe(_corporateSafe_address);
        s.acceptUserSafeKey();
    }

    function createTransaction(
        address _corpo, address _to, uint _amount, address _token)
        public
		returns (uint)
    {
        CorporateSafe c = CorporateSafe(_corpo);
        return c.createTransaction(_to, _amount, _token);
    }

    function signTransaction(
        address _corpo, uint _tx)
        public
    {
        CorporateSafe c = CorporateSafe(_corpo);
        c.signTransaction(_tx);
    }

    function unsafeExecuteTransaction(
        address _corpo, uint _tx)
        public
    {
        CorporateSafe c = CorporateSafe(_corpo);
        c.unsafeExecuteTransaction(_tx);
    }

    function withdrawTransactionFrom(
        address _corpo, address _other, uint _tx)
        public
    {
        CorporateSafe c = CorporateSafe(_corpo);
        c.withdrawTransactionFrom(_other, _tx);
    }

    function createCertifyEvent(address _corpo, uint _data)
    	public
		returns (uint)
	{
		CorporateSafe c = CorporateSafe(_corpo);
		return c.createCertifyEvent(_data);
	}

    function signCertifyEvent(address _corpo, uint _id)
        public
    {
        CorporateSafe c = CorporateSafe(_corpo);
        c.signCertifyEvent(_id);
    }

	function executeCertifyEvent(address _corpo, uint _id)
		public
	{
		CorporateSafe c = CorporateSafe(_corpo);
		c.executeCertifyEvent(_id);
	}

	function addChild(address _corpo, address _child)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.addChild(_child);
	}

	function acceptChildAdminRequest(address _corpo, address _child)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.acceptChildAdminRequest(_child);
	}

	function startVoteAddKeyInChild(address _corpo, address _child,
					address _newkey, bool _hasOverride)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.startVoteAddKeyInChild(_child, _newkey, _hasOverride);
	}

	function voteAcceptKeyInChild(address _corpo, address _child, address _key)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.voteAcceptKeyInChild(_child, _key);
	}

	function removeKeyFromChild(address _corpo, address _child, address _key)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.removeKeyFromChild(_child, _key);
	}

	function deleteCorporateTransaction(address _corpo, uint _txid)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.deleteTransaction(_txid);
	}

	function deleteCorporateCertifyEvent(address _corpo, uint _eventid)
		public
	{
		GenisysSafe g = GenisysSafe(_corpo);
		g.deleteCertifyEvent(_eventid);
	}
}
