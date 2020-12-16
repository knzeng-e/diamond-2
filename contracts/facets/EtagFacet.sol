//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.1;

import "../libraries/LibDiamond.sol";
import "../qaxhioContracts/Libraries/SafeMath.sol";
import "../libraries/LibEtags.sol";
import "../interfaces/IUsersafeEvents.sol";

contract EtagFacet is IUsersafeEvents {

    using SafeMath for uint256;

    function userEtagSign(string memory _etagData, uint8 _etagStatus) public /*filterAndRefundOwner(false)*/ {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        uint256 nextIndex = ds.currentEtagIndex.add(1);

        uint256 horodatage = block.timestamp;

        LibEtags.EventTag memory newEtag = LibEtags.EventTag(
            horodatage,
            nextIndex,
            _etagStatus,
            _etagData
        );

        ds.Etags[nextIndex] = newEtag;
        ds.currentEtagIndex = nextIndex;
        emit EtagCreated(_etagData, _etagStatus, nextIndex, horodatage);
    }
    
    function userEtagDataGet(uint256  _etagIndex) public view returns (string memory, uint8, uint256){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        return (
            ds.Etags[_etagIndex].etagData,
            ds.Etags[_etagIndex].etagStatus,
            ds.Etags[_etagIndex].dateStatusModif
        );
    }
    
    function getEtagData(uint256 _etagIndex) public view returns (string memory){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        return ds.Etags[_etagIndex].etagData;
    }

    function getEtagStatus(uint256 _etagIndex) public view returns (uint8){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        return ds.Etags[_etagIndex].etagStatus;
    }

    function getEtagTimeStamp(uint256 _etagIndex) public view returns (uint256){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        return ds.Etags[_etagIndex].dateStatusModif;
    }

    function userEtagStatusModify(uint256 _etagIndex, uint8 _newEtagStatus) public {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        require(ds.Etags[_etagIndex].etagIndex != 0);
        ds.Etags[_etagIndex].etagStatus = _newEtagStatus;
        emit etagStatusModify(_etagIndex, _newEtagStatus);
    }

    function userEtagLastIndexGet() public view returns(uint256 lastIndex){
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        return (ds.currentEtagIndex);
    }
}