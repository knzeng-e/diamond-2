//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

import "../interfaces/IUsersafeEvents.sol";
import "../libraries/LibIdentityManager.sol";
import "../storageContracts/KeyManagerStorage.sol";


/// @title QaxhModule - A contract that allows its associated Gnosis Safe to be Qaxh compliant if owned by the Qaxh address.
/// @author Clémence Gardelle
/// @author Loup Federico
/// @author Nzeng Kevin

contract UsersafeFacet is KeyManagerStorage, IUsersafeEvents /*is /*UserSafeExtension, IdentityManager */{

    /// @dev Setup qaxh and QaxhMasterLedger addresses references upon module creation.
    ///      this function must be called in the same transaction that creates the Gnosis
    ///      safe with CreateAndAddModules for security purposes.
    // constructor(address _qaxh, address _ledger) public { //Removedthe masterLedger address
    constructor(
        address _qaxh,
        string memory _QI_hash,
        string memory _QE_hash,
        uint8 _identityLevel,
        uint8 _ageOfMajority,
        string memory _customerId
    ){
        LibIdentityManager.IdentityStorage storage _identityStore = LibIdentityManager.identityStorage();
        
        setupUtils(_qaxh);
        _identityStore.safeType = 1;
        LibIdentityManager.setupIdentity(
            _QI_hash,
            _QE_hash,
            _identityLevel,
            _ageOfMajority,
            _customerId
        );
    }

    function getSafeType() external returns(uint8) {
        LibIdentityManager.IdentityStorage storage _identityStore = LibIdentityManager.identityStorage();

        return _identityStore.safeType;

    }

    /// @dev Update the age of Majority if tx.origin has the appropriate rights.
    function callUpdateAgeOfMajority(uint8 _ageOfMajority) public filterQaxh filterAndRefundOwner(true) alreadySetupModifier {
        LibIdentityManager.updateAgeOfMajority(_ageOfMajority);
    }

  
    // SENDING AND RECEIVING ETHERS AND TOKENS

    // TODO: Change this if we want to disable ether transactions.
    //function() public payable /* filterQaxh */ {}

    // KEY MANAGEMENT

    /// @dev Ask the GnosisSafe to send ERC20 tokens and revert on failure.
    /// @param to The receiver address.
    /// @param amount The amount of the transaction in Weis.
    /// @param token If set to 0, it is an Ether transaction, else it is a token transaction.
    function sendFromSafe(
        address to,
        uint256 amount,
        address token
    ) public {
        KeyStorage storage keystore = keyManagerStorage();

        require(keystore.keyStatus[msg.sender] == Status.Active, "Only active keys can transact");
        /*
        if (token == address(0x0))
            to.transfer(amount);
        else*/
        (bool isExecuted,) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        require(isExecuted, "This token couldn't be sent");
    }

    // DATA CERTIFICATION

    /// @dev Emit an event certifying data.
    /// @param data Data to be certified. Example : transaction D1, hash of an image, etc.
    function certifyData(string memory data)
        public
        filterAndRefundOwner(false)
    {
        // TODO: Change this to bytes

        emit CertifyData(data);
    }

    // TODO: Fix AppInventor and remove this
    function getModules() public view returns (address[] memory) {
        address[] memory ret = new address[](1);
        ret[0] = address(this);
        return ret;
    }
}
