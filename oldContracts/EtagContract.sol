//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "./EtagStorage.sol";
// import "./EventsManager.sol";
import "./IdentityManager.sol";
import "./EventsManager/UsersafeEventsManager/UsersafeEvents.sol";

contract EtagContract is UsersafeEvents {

    address public etagStorageContract; //Link that storage to my UpgradeStorageFunction
    address public etagContractAddress;
    address public owner = msg.sender;
    
    address[] public listEtagStorage; //Keeps track of past storage contracts
    address[] public listEtagContractAddresses; // Keeps track of past upgradable contracts
    address private proxyParentContract;
    

    constructor(address _storageContract) {
        proxyParentContract = msg.sender;
        etagStorageContract = _storageContract;
    }
    
    function userEtagSign(string memory _etagData, uint8 _etagStatus) public returns(uint256 nextIndex)/*filterAndRefundOwner(false)*/ {
        Storage etagStorage = Storage(etagStorageContract);

        nextIndex = etagStorage.incrementCurrentEtagIndex();
        uint256 horodatage = block.timestamp;


        etagStorage.addEtag(horodatage, nextIndex, _etagStatus, _etagData);
       
        emit UsersafeEvents.EtagCreated(_etagData, _etagStatus, nextIndex, horodatage);
    }

    function userEtagDataGet(uint256  _etagIndex) external view returns (string memory, uint8, uint256){
        return (
            getEtagData(_etagIndex),
            getEtagStatus(_etagIndex),
            getEtagDate(_etagIndex)
        );
    }

    function getEtagData(uint256 _etagIndex) public view returns (string memory){
        Storage etagStorage = Storage(etagStorageContract);

        return etagStorage.getEtagData(_etagIndex);
    }

    function getEtagStatus(uint256 _etagIndex) public view returns (uint8 ){
        Storage etagStorage = Storage(etagStorageContract);

        return etagStorage.getEtagStatus(_etagIndex);
    }

    function getEtagDate(uint256 _etagIndex) public view returns (uint256 ){
        Storage etagStorage = Storage(etagStorageContract);

        return etagStorage.getEtagDate(_etagIndex);
    }

    function updateEtagStorage(address _newStorageAddress) external {
        require(msg.sender == proxyParentContract);
        etagStorageContract = _newStorageAddress;
    }
}