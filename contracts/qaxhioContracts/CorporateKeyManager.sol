//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;
// import "./KeyManager.sol";
// import "./EventsManager.sol";
import "./EventsManager/CorporateEventsManager/CorporateKeyEvents.sol";


contract CorporateKeyManager is CorporateKeyEvents {

	mapping(address => address) private activatedKeys;
	mapping(address => address) private pendingKeys;

	uint public activatedCount;
	uint public pendingCount;

	address public constant KEY_SENTINEL = address(0x42);

	modifier keyPendingValidation(address _key) {
		require(isKeyPending(_key), "Not pending");
		_;
	}

	modifier keyActivated(address _key) {
		require(!isNotAnOwner(_key), "Not activated");
	       _;
	}

	// modifier keyActivated(address _key) {
	// 	require(isActivated(_key), "Not activated");
	//        _;
	// }

	modifier keyNotPendingValidation(address _key) {
		require(!isKeyPending(_key), "Pending");
		_;
	}

	modifier keyNotActivated(address _key) {
		require(isNotAnOwner(_key), "Activated");
		_;
	}

	//kev_modif: modified to take in account the isActivated modified 
	// modifier keyNotActivated(address _key) {
	// 	require(!isActivated(_key), "Activated");
	// 	_;
	// }

	constructor()
	{
		pendingKeys[KEY_SENTINEL] = KEY_SENTINEL;
		activatedKeys[KEY_SENTINEL] = KEY_SENTINEL;
	}

	// TODO: Rename this to isActivated(), and update the blocks
	function isNotAnOwner(address _key) public view returns (bool)//clés du userSafe not EOA
	{
		return _key == KEY_SENTINEL || activatedKeys[_key] == address(0x0);
	}

	// Kev_modif DONE: Renamed the previous isNotAnOwner function to isActivated(); Done --> updated the block in java "isNotAnOwnerCorporateUserAddress" function
	// function isActivated(address _key) public view returns (bool)
	// {
	// 	return _key != KEY_SENTINEL && activatedKeys[_key] != address(0x0);
	// }

	function isKeyPending(address _key) public view returns (bool)
	{
		return _key != KEY_SENTINEL && pendingKeys[_key] != address(0x0);
	}

	function getActiveKeys() public view returns(address[] memory)
	{
		address[] memory ret = new address[](activatedCount);

		address curr = activatedKeys[KEY_SENTINEL];
		for (uint i = 0; i < activatedCount; i++)
		{
			ret[i] = curr;
			curr = activatedKeys[curr];
		}

		return ret;
	}

	function getPendingKeys() public view returns(address[] memory)
	{
		address[] memory ret = new address[](pendingCount);

		address curr = pendingKeys[KEY_SENTINEL];
		for (uint i = 0; i < pendingCount; i++)
		{
			ret[i] = curr;
			curr = pendingKeys[curr];
		}

		return ret;
	}

	// The key is assumed to be a valid Qaxh usersafe.
	function _addPendingKey(address _key) internal
	{
		require(activatedKeys[_key] == address(0x0), "Already activated");
		require(pendingKeys[_key] == address(0x0), "Already pending");

		pendingKeys[_key] = pendingKeys[KEY_SENTINEL];
		pendingKeys[KEY_SENTINEL] = _key;
		pendingCount++;

		emit NewPendingKey(_key);
	}

	// The key is assumed to be a valid Qaxh usersafe.
	function _activatePendingKey(address _key) internal keyPendingValidation(_key)
	{
		require(activatedKeys[_key] == address(0x0), "Already activated");

		_removePendingKey(_key);

		activatedKeys[_key] = activatedKeys[KEY_SENTINEL];
		activatedKeys[KEY_SENTINEL] = _key;

		activatedCount++;

		emit KeyActivated(_key);
	}

	/*
	Code duplication in removePendingKey and removeActivatedKey, because a
	mapping cannot be passed as a function argument...
	*/
	function _removePendingKey(address _key)
		internal
		keyPendingValidation(_key)
	{
		address curr = KEY_SENTINEL;
		for (; curr != address(0x0) && pendingKeys[curr] != _key;
		     curr = pendingKeys[curr])
		{
			/* Search for curr such that the next elemt is _key */
		}
		require(pendingKeys[curr] == _key, "Key not found");

		pendingKeys[curr] = pendingKeys[_key];
		pendingKeys[_key] = address(0x0);

		pendingCount--;
		emit RemovedPendingKey(_key);
	}

	function _removeActivatedKey(address _key)
		internal
		keyActivated(_key)
	{
		address curr = KEY_SENTINEL;
		for (; curr != address(0x0) && activatedKeys[curr] != _key;
		     curr = activatedKeys[curr])
		{
			/* Search for curr such that the next elemt is _key */
		}
		require(activatedKeys[curr] == _key, "Key not found");

		activatedKeys[curr] = activatedKeys[_key];
		activatedKeys[_key] = address(0x0);

		activatedCount--;
		emit RemovedActivatedKey(_key);
	}
}