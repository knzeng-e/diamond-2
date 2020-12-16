//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

// import "./EventsManager.sol";
import "./Libraries/LibSafe.sol";

contract Storage {

    uint256 constant internal smallTransactionThreshold = 5000000000;
    uint256 public currentEtagIndex;

	mapping (uint256 => LibSafe.EventTag) public Etags; //it allows to retrieve an Etag, knowing its index, with a simple "return ETags[index]

    function incrementCurrentEtagIndex() public returns(uint256) {
        uint256 nextIndex = LibSafe.safeAdd(currentEtagIndex, 1);
        currentEtagIndex = nextIndex;
        return nextIndex;
    }

    function addEtag(
        uint256 _horodotage,
        uint256 _etagIndex,
        uint8 _etagStatus,
        string memory _etagData
    ) public {
        LibSafe.EventTag memory newEtag = LibSafe.EventTag(
            _horodotage,
            _etagIndex,
            _etagStatus,
            _etagData
        );

        Etags[_etagIndex] = newEtag; 
    }

    function getEtagData(uint256 _etagIndex) external view returns (string memory){
        return Etags[_etagIndex].etagData;
    }

    function getEtagStatus(uint256 _etagIndex) external view returns (uint8 ){
        return Etags[_etagIndex].etagStatus;
    }

    function getEtagDate(uint256 _etagIndex) external view returns (uint256 ){
        return Etags[_etagIndex].dateStatusModif;
    }

}