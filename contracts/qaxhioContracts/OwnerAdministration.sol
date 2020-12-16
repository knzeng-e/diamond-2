//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

/// @title A contract which creates ownership for a contract (one owner and multiple Admins)
/// @author Sébastien PIERRE

import "./Context.sol/";

contract OwnerAdministration is Context {

// Only one owner which launch the contract, he adds the administrators (other QAXH plateforms) which have less privileges
    address public owner;

//mapping of administrations, they have powerless than the owner (initial QAXH plateform)
    mapping (address => bool) public isAdmin;
    mapping (address => address) public administrations;
    address internal constant SENTINEL_KEYS = address (0x52);
    uint256 countAdmin;

    address public newAdmin;   //use to add new Admin

    event NewAdminPending (address indexed _newAdmin);
    event NewAdminAccepted (address indexed _newAdmin);

    modifier onlyOwner {
        require (_msgSender() == owner, "not the owner");
        _;
    }

    constructor() {}

    //Asking for a new Admin by QAXH
    function createNewAdmin(address _newAdmin) public onlyOwner(){
        newAdmin = _newAdmin;
        emit NewAdminPending(_newAdmin);
    }

    //New Admin need to accept the rights given by QAXH. When it is done, the new admin will automatically be add to admin list.
    function acceptAdmin() public {
        require (_msgSender() == newAdmin, "you are not the new admin");
        isAdmin[newAdmin] == true;
        administrations[newAdmin] = administrations[SENTINEL_KEYS];
        administrations[SENTINEL_KEYS] = newAdmin;
        countAdmin++;
        emit NewAdminAccepted(_msgSender());
        delete newAdmin;
    }

    function deleteAdmin(address delAdmin) public onlyOwner(){
        require (isAdmin[delAdmin] == true, "not an admin");
        //change in ownership whitelist
        isAdmin[delAdmin] == false;

        //search in ownership, the address which leads to the old address (to replace it with the new one)
        address addr = SENTINEL_KEYS;
        while (administrations[addr] != delAdmin){
            addr = administrations[addr];
        }
        administrations[addr] = administrations[delAdmin];
        delete administrations[delAdmin];
    }
}