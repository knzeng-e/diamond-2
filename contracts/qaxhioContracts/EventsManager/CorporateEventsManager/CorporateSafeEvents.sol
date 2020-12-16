//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

contract CorporateSafeEvents {
   
    /*------------------------- CorporateSafe events ---------------------------*/
    event CreatedTransaction(
        uint256 _id,
        address _dest,
        uint256 _amount,
        address token
    );
    event SignedTransaction(uint256 _id, address _signer);
    event ExecutedTransaction(uint256 _id);
	
    //XXX: Remove data field?
    event CreatedCertifyEvent(uint256 _id, uint256 _data);
    event SignedCertifyEvent(uint256 _id, address _signer);
    event ExecutedCertifyEvent(uint256 _id, uint256 _data);
}
