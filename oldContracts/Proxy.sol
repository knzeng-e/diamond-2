//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;


import "./EtagStorage.sol";
import "./EtagContract.sol";


contract Proxy {
    
    address public etagStorageContract; //
    address public etagContractAddress;
    address public owner = msg.sender;

    address[] public listEtagStorage; //Keeps track of past storage contracts
    address[] public listEtagContractAddresses; // Keeps track of past upgradable contracts

    modifier onlyOwner(){
        require(msg.sender == owner, "Seul l'administrateur peut effectuer cette action");
        _;
    }
    
    mapping(bytes4 => address) public selectorToFacet;

    constructor() {
        etagStorageContract = address(new Storage());
        etagContractAddress = address(new EtagContract(etagStorageContract));
        listEtagStorage.push(etagStorageContract);
        listEtagContractAddresses.push(etagContractAddress);
        selectorToFacet[bytes4(0x47d990cb)] = etagContractAddress;
    }

    fallback () external {
        address facet = selectorToFacet[msg.sig];
         require(facet != address(0), "This function doesn't exist");    
        
        (bool isSuccessful,) = facet.delegatecall(msg.data);

        require(isSuccessful, "L'execution d'une fonction n'a pas aboutie");
    }
    
    function upgradeEtagStorage(address _newEtagStorageAddress) public onlyOwner {
        bool storageUpdateSuccess;
        bytes memory updateReturn;

        require(etagStorageContract != _newEtagStorageAddress, "Cannot use the existing storage address.. Enter a new one");
        (storageUpdateSuccess, updateReturn) = etagContractAddress.delegatecall(abi.encodeWithSignature("updateEtagStorage(address)", _newEtagStorageAddress));
        etagStorageContract = _newEtagStorageAddress;
        listEtagStorage.push(_newEtagStorageAddress);
    }

    function upgradreEtagContract(address _newEtagContract) public onlyOwner {
        require(etagContractAddress != _newEtagContract, "Cannot set to an existing etagContract address.. Enter a new one");
        etagContractAddress = _newEtagContract;
        listEtagContractAddresses.push(_newEtagContract);
        selectorToFacet[bytes4(0x47d990cb)] = _newEtagContract;
    }
    
    function getModules() public view returns (address[] memory) {
        address[] memory ret = new address[](1);
        ret[0] = address(this);
        return ret;
    }
}