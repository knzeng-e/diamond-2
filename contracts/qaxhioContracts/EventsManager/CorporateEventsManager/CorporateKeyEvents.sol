//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

contract CorporateKeyEvents {
  
    /*------------------------- CorporateKeyManager events ---------------------------*/

    event NewPendingKey(address _key);
    event RemovedPendingKey(address _key);

    event KeyActivated(address _key);
    event RemovedActivatedKey(address _key);
}
