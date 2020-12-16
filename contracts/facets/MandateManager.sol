//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "../qaxhioContracts/MandateSafe.sol";
import "../storageContracts/KeyManagerStorage.sol";

contract MandateManagerFacet is KeyManagerStorage {

    ////////////////////// 			MANDATE FUNCTIONS			//////////////////////////

    function mandateSignUrm(address _mandateSafe)
        public
        filterAndRefundOwner(false)
    {
        MandateSafe mandateSafeInstance = MandateSafe(_mandateSafe);
        mandateSafeInstance.debtorSignURM();
    }

    function mandateSignCreate(
        address _mandateSafe,
        uint256 _urm,
        string memory _hash
    ) public filterAndRefundOwner(false) {
        MandateSafe mandateSafeInstance = MandateSafe(_mandateSafe);
        mandateSafeInstance.debtorSignCreate(_urm, _hash);
    }

    function mandateSignRevok(address _mandateSafe, uint256 _urm)
        public
        filterAndRefundOwner(false)
    {
        MandateSafe mandateSafeInstance = MandateSafe(_mandateSafe);
        mandateSafeInstance.debtorSignRevok(_urm);
    }
}