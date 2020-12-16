//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;
import "../libraries/LibDiamond.sol";
import "../storageContracts/KeyManagerStorage.sol";

/// @title KeyManager - A contract that manages owner keys associated to a Qaxh Module.
/// @author Loup Federico
/// @author Mickael Proust
/// @author Kevin Nzeng

contract KeyManagerFacet is KeyManagerStorage {

    constructor(){
        KeyStorage storage keystore = keyManagerStorage();
        keystore.MAX_KEYS = 10;
        keystore.SENTINEL_KEYS = address(0x1);
    }


     // ACTIVATE, FREEZE AND REMOVE KEYS

    /// @dev Activate the key given as a parameter. It can be called by:
    ///         1.) Any active key.
    ///         2.) The Qaxh address.
    ///      NB: only the Qaxh address can create a new key
    /// @param _key The key to activate.

    function activateKey(address _key, uint deadline) public filterAndRefundOwner(true) {
        KeyStorage storage keystore = keyManagerStorage();

        require(isValidKey(_key), "Invalid key");
        require(
                keystore.keyStatus[msg.sender] == Status.Active ||
                msg.sender == keystore.qaxh,
                "Emitter not allowed to activate the key"
               );
        if (keystore.keyStatus[_key] == Status.NotAnOwner) {
            require(msg.sender == keystore.qaxh, "Only Qaxh can add a new key to the safe");
            keystore.keyList[_key] = keystore.keyList[keystore.SENTINEL_KEYS];
            keystore.keyList[keystore.SENTINEL_KEYS] = _key;
        }
        // Deadline
        keystore.appKeysDeadlines[_key] = block.timestamp + (deadline*24*3600);
        keystore.keyStatus[_key] = Status.Active;
    }
   
    /// @dev Delete the key given as a parameter from the safe. It can be called by:
    ///         1.) Any active key (including the key to be deleted).
    ///         2.) The Qaxh address.
    /// @param _key The key to be deleted.
    function removeKey(address _key) public filterAndRefundOwner(true) {
        KeyStorage storage keystore = keyManagerStorage();

        require(keystore.keyStatus[_key] != Status.NotAnOwner, "The safe doesn't contain this key");
        address prev = keystore.SENTINEL_KEYS;
        while (keystore.keyList[prev] != _key)
            prev = keystore.keyList[prev];
        keystore.keyList[prev] = keystore.keyList[_key];
        keystore.keyList[_key] = address(0);
        keystore.keyStatus[_key] = Status.NotAnOwner;
        keystore.keyLabels[_key] = "";
        // Deadline
        delete keystore.appKeysDeadlines[_key];
        assert(this.isInKeyList(_key) == false);
    }

    // VIEWS & PURE FUNCTIONS

    /// @dev Check wether a key is valid or not, i.e. if it is suitable to
    ///      be added to the QaxhSafe. Any key is valid, except :
    ///         1.) The 0x0 address (for implementation reasons).
    ///         2.) The SENTINEL_KEYS address (for implementation reasons).
    function isValidKey(address _key) internal view returns (bool) {
        KeyStorage storage keystore = keyManagerStorage();
        

        return _key != address(0) && _key != keystore.SENTINEL_KEYS;
    }

    // List the safe keys, check for a key status :

    function isActive(address _key) public view returns (bool) {
        KeyStorage storage keystore = keyManagerStorage();
        
        return keystore.keyStatus[_key] == Status.Active;
    }

    function isOwner(address _key) public view returns (bool) {
        return isActive(_key);
    }

    function isNotAnOwner(address _key) public view returns (bool) {
        KeyStorage storage keystore = keyManagerStorage();

        return keystore.keyStatus[_key] == Status.NotAnOwner;
    }

    /// @dev Return a list of the keys added to the safe of the selected types.
    /// @param active Set it to true to list active keys.
    
    function listKeys(bool active) public view returns (address[] memory keys) {
        uint8 index;
        KeyStorage storage keystore = keyManagerStorage();


        for(address key = keystore.keyList[keystore.SENTINEL_KEYS]; key != address(0); key = keystore.keyList[key]) {
            if ((keystore.keyStatus[key] == Status.Active && active)) {
                keys[index] = key;
                index++;
            }
        }
        return keys;
    }

    /// @dev Return true if `key` is present in `keyList`.
    function isInKeyList(address _key) public view returns (bool) {
        KeyStorage storage keystore = keyManagerStorage();

        address curr = keystore.SENTINEL_KEYS;
        while (curr != _key && curr != address(0))
            curr = keystore.keyList[curr];
        return curr == _key;
    }

    /// @dev Return the number of elements in the list before the first null address.
    function listLength(address[] memory list) public pure returns (uint256 length) {
        for(length = 0; list[length] != address(0); length++)
            continue;
    }

    // Get the deadline of an  appAddress from the mapping
    function getAppKeyDeadline(address appAddress) public view returns (uint) {
        KeyStorage storage keystore = keyManagerStorage();


        return keystore.appKeysDeadlines[appAddress];
    }
}