//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

// import "./EventsManager.sol";
import "./Libraries/SafeMath.sol";
import "./Libraries/LibSafe.sol";
import "./EventsManager/UsersafeEventsManager/UsersafeEvents.sol";

contract TagManager is UsersafeEvents {

    using SafeMath for uint256;


    uint256 private currentEtagIndex;
    
    // struct EventTag {
    //     uint256 dateStatusModif;
	// 	uint256 etagIndex;
	// 	uint8 etagStatus;
    //     string etagData;
	// }

	mapping (uint256 => LibSafe.EventTag) public Etags; //it allows to retrieve an Etag, knowing its index, with a simple "return ETags[index]

    function userEtagSign(string memory _etagData, uint8 _etagStatus) public /*filterAndRefundOwner(false)*/ {
        uint256 nextIndex = currentEtagIndex.add(1);
        uint256 horodatage = block.timestamp;

        LibSafe.EventTag memory newEtag = LibSafe.EventTag(
            horodatage,
            nextIndex,
            _etagStatus,
            _etagData
        );

        Etags[nextIndex] = newEtag;
        currentEtagIndex = nextIndex;
        emit UsersafeEvents.EtagCreated(_etagData, _etagStatus, nextIndex, horodatage);
    }
    
    function userEtagDataGet(uint256  _etagIndex) public view returns (string memory, uint8, uint256){
        return (
            Etags[_etagIndex].etagData,
            Etags[_etagIndex].etagStatus,
            Etags[_etagIndex].dateStatusModif
        );
    }
    
    function getEtagData(uint256 _etagIndex) public view returns (string memory){
        return Etags[_etagIndex].etagData;
    }

    function getEtagStatus(uint256 _etagIndex) public view returns (uint8){
        return Etags[_etagIndex].etagStatus;
    }

    function getEtagTimeStamp(uint256 _etagIndex) public view returns (uint256){
        return Etags[_etagIndex].dateStatusModif;
    }

    function userEtagStatusModify(uint256 _etagIndex, uint8 _newEtagStatus) public {
        require(Etags[_etagIndex].etagIndex != 0);
        Etags[_etagIndex].etagStatus = _newEtagStatus;
        emit UsersafeEvents.etagStatusModify(_etagIndex, _newEtagStatus);
    }

    function userEtagLastIndexGet() public view returns(uint256 lastIndex){
        return (currentEtagIndex);
    }
}