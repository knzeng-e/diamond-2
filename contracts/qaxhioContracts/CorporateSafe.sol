//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

/* TODO: Add activation checking everywhere */
/* TODO: Replace comparisons to numberOfAdministrators by an overridable function call */

import "./IERC20.sol";
import "./VoteManager.sol";
import "./CorporateKeyManager.sol";
import "./EventsManager/CorporateEventsManager/CorporateSafeEvents.sol";

abstract contract CorporateSafe is
    CorporateKeyManager,
    VoteManager,
    CorporateSafeEvents
{
    address public qaxhMasterKey;
    address public parentSafe; // = PARENT_SENTINEL for a genisys safe

    address public constant PARENT_SENTINEL = address(0x45);

    uint256 public numberOfAdministrators;
    bool public activated;

    /* TODO: Optimize this into a single field */
    uint8 public creatorTrustLevel; /* Minimum administrator trust level */
    uint8 public corporateDelegationLevel;
    uint8 public corporateCommitmentLevel;
    uint8 public corporateRankLevel;

    uint8 public safeType;
    /* TODO: Make this an integer, or/and move it to safeType */
    string public safeVersion;

    /* Starts at one so that a Transaction that doesn't exist (is not
     * in the mapping) can be detected
     */
    uint256 public txNonce;
    uint256 public pendingTxCount;
    uint256 public constant TX_VOTE_SALT = 0xDEAD;
    uint256 public constant TX_SENTINEL = 0x0;
    struct Transaction {
        uint256 txId;
        address dest;
        uint256 amount;
        address token;
        bool overriden;
        uint256 next;
    }
    mapping(uint256 => Transaction) public transactionsList;
    uint256 public lastTx;

    uint256 public certifyEventNonce;
    uint256 public pendingCertifyEventCount;
    uint256 public constant EVENT_VOTE_SALT = 0xB33F;
    uint256 public constant EVENT_SENTINEL = 0x0;
    struct CertifyEvent {
        uint256 id;
        uint256 data;
        bool overridden;
        uint256 next;
    }
    mapping(uint256 => CertifyEvent) public certifyEvents;
    uint256 public lastEv;

    uint8 public constant EXECUTIVE_RANK = 0x1;

    modifier checkActivation() {
        require(activated, "Not activated");
        _;
    }

    modifier minTrustLevel(uint8 _trustLevel) {
        require(_trustLevel >= creatorTrustLevel, "Low trust level");
        _;
    }

    modifier isAdministrator(address _key) {
        require(!isNotAnOwner(_key) || _key == parentSafe, "Not administrator");
        _;
    }

    modifier checkSender(address _sender) {
        require(msg.sender == _sender, "Wrong sender");
        _;
    }

    modifier txExists(uint256 _tx) {
        require(
            _tx != TX_SENTINEL && transactionsList[_tx].txId == _tx,
            "Transaction doesn't exist"
        );
        _;
    }

    modifier eventExists(uint256 _id) {
        require(
            _id != 0x0 && certifyEvents[_id].id == _id,
            "Transaction doesn't exist"
        );
        _;
    }

    constructor(uint8 _safeType, string memory _safeVersion) {
        safeType = _safeType;
        safeVersion = _safeVersion;
        activated = false;
        txNonce = 0;
        certifyEventNonce = 0;
        lastTx = TX_SENTINEL;
    }

    // Used to disable the safe before updating the admins in /genupdate
    function setActivated(bool new_) public checkSender(qaxhMasterKey) {
        activated = new_;
    }

    /*
     * Use the safe parameters, and decide if the safe is activated.
     * Impelmented in ChildSafe.sol
     */
    function isActivated() internal virtual view returns (bool);

    /*
     * hasOverride: implemented in ChildSafe.sol
     */
    function hasOverride(address) public virtual view returns (bool);

    function updateNumberOfAdministrators(uint256 new_)
        public
        checkSender(qaxhMasterKey)
    {
        numberOfAdministrators = new_;
        activated = isActivated();
    }

    /* number of votes, tx overriden.
     * Implemented in ChildSafe.sol
     */
    function isTransactionExecutable(uint256, bool)
        internal
        virtual
        view
        returns (bool);

    function createTransaction(
        address _to,
        uint256 _amount,
        address _token
    ) public checkActivation isAdministrator(msg.sender) returns (uint256) {
        uint256 id = ++txNonce;

        uint256 vote = uint256(keccak256(abi.encodePacked(id, TX_VOTE_SALT)));
        createVote(vote);
        transactionsList[id] = Transaction(
            id,
            _to,
            _amount,
            _token,
            false,
            lastTx
        );
        lastTx = id;
        pendingTxCount++;

        emit CreatedTransaction(id, _to, _amount, _token);

        return id;
    }

    function signTransaction(uint256 _tx)
        public
        checkActivation
        isAdministrator(msg.sender)
        txExists(_tx)
    {
        uint256 vote = uint256(keccak256(abi.encodePacked(_tx, TX_VOTE_SALT)));

        castVote(vote, msg.sender);
        if (hasOverride(msg.sender)) transactionsList[_tx].overriden = true;

        emit SignedTransaction(_tx, msg.sender);
    }

    function _executeTx(
        address _dest,
        uint256 _amount,
        address _token
    ) internal returns (bool) {
        /*
        if (_token == address(0x0)){
			return _dest.send(_amount);
		}*/
        (bool _isExecuted,) = _token.call(
            abi.encodeWithSignature("transfer(address,uint256)", _dest, _amount)
        );
        require(_isExecuted, "Transfer call failed");
        return _isExecuted;
    }

    function withdrawTransaction(uint256 _tx)
        public
        checkActivation
        txExists(_tx)
    {
        require(
            transactionsList[_tx].dest == msg.sender,
            "Not the destination"
        );

        uint256 vote = uint256(keccak256(abi.encodePacked(_tx, TX_VOTE_SALT)));
        require(
            isTransactionExecutable(
                countVotes(vote),
                transactionsList[_tx].overriden
            )
        );
        require(
            transactionsList[_tx].amount <= address(this).balance,
            "Not enough funds"
        );

        Transaction storage tr = transactionsList[_tx];
        uint256 amount = tr.amount;
        address token = tr.token;

        // Prevent re entrency attack.
        deleteTransaction(_tx);
        require(_executeTx(msg.sender, amount, token));
        emit ExecutedTransaction(_tx);
    }

    function withdrawTransactionFrom(address _other, uint256 _tx)
        public
        checkActivation
        isAdministrator(msg.sender)
    {
        CorporateSafe other = CorporateSafe(_other);
        other.withdrawTransaction(_tx);
    }

    function _deleteTransaction(uint256 _tx) internal {
        if (lastTx == _tx) lastTx = transactionsList[lastTx].next;
        else {
            uint256 curr = lastTx;
            for (
                ;
                curr != TX_SENTINEL && transactionsList[curr].next != _tx;
                curr = transactionsList[curr].next
            ) {}
            assert(transactionsList[curr].next == _tx);

            transactionsList[curr].next = transactionsList[_tx].next;
        }

        delete transactionsList[_tx];
        pendingTxCount--;
    }

    function deleteTransaction(uint256 _tx)
        public
        checkActivation
        isAdministrator(msg.sender)
        txExists(_tx)
    {
        uint256 vote = uint256(keccak256(abi.encodePacked(_tx, TX_VOTE_SALT)));
        endVote(vote);

        _deleteTransaction(_tx);
    }

    function _deleteCertifyEvent(uint256 _eventid) internal {
        if (lastEv == _eventid) lastEv = transactionsList[lastEv].next;
        else {
            uint256 curr = lastEv;
            for (
                ;
                curr != EVENT_SENTINEL && certifyEvents[curr].next != _eventid;
                curr = certifyEvents[curr].next
            ) {}
            assert(certifyEvents[curr].next == _eventid);

            certifyEvents[curr].next = certifyEvents[_eventid].next;
        }

        delete certifyEvents[_eventid];
        pendingCertifyEventCount--;
    }

    function deleteCertifyEvent(uint256 _eventid)
        public
        checkActivation
        isAdministrator(msg.sender)
        eventExists(_eventid)
    {
        uint256 vote = uint256(
            keccak256(abi.encodePacked(_eventid, EVENT_VOTE_SALT))
        );
        endVote(vote);

        _deleteCertifyEvent(_eventid);
    }

    function unsafeExecuteTransaction(uint256 _tx)
        public
        checkActivation
        isAdministrator(msg.sender)
        txExists(_tx)
    {
        uint256 vote = uint256(keccak256(abi.encodePacked(_tx, TX_VOTE_SALT)));
        require(
            isTransactionExecutable(
                countVotes(vote),
                transactionsList[_tx].overriden
            )
        );
        require(
            transactionsList[_tx].amount <= address(this).balance,
            "Not enough funds"
        );

        Transaction storage tr = transactionsList[_tx];
        address dest = tr.dest;
        uint256 amount = tr.amount;
        address token = tr.token;

        // Prevent re entrency attack.
        deleteTransaction(_tx);
        require(_executeTx(dest, amount, token));
        emit ExecutedTransaction(_tx);
    }

    function getPendingTransactions()
        public
        view
        checkActivation
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](pendingTxCount);

        uint256 curr = lastTx;
        for (uint256 idx = 0; idx != pendingTxCount; idx++) {
            ret[idx] = transactionsList[curr].txId;
            curr = transactionsList[curr].next;
        }

        return ret;
    }

    //function () public payable {}

    function getPendingCertifyEvents()
        public
        view
        checkActivation
        returns (uint256[] memory)
    {
        uint256[] memory ret = new uint256[](pendingCertifyEventCount);

        uint256 curr = lastEv;
        for (uint256 idx = 0; idx != pendingCertifyEventCount; idx++) {
            ret[idx] = certifyEvents[curr].id;
            curr = certifyEvents[curr].next;
        }

        return ret;
    }

    function createCertifyEvent(uint256 _data)
        public
        checkActivation
        isAdministrator(msg.sender)
        returns (uint256)
    {
        uint256 id = ++certifyEventNonce;

        uint256 vote = uint256(
            keccak256(abi.encodePacked(id, EVENT_VOTE_SALT))
        );
        createVote(vote);
        certifyEvents[id] = CertifyEvent(id, _data, false, lastEv);
        lastEv = id;
        pendingCertifyEventCount++;

        emit CreatedCertifyEvent(id, _data);

        return id;
    }

    function signCertifyEvent(uint256 _id)
        public
        checkActivation
        isAdministrator(msg.sender)
        eventExists(_id)
    {
        uint256 vote = uint256(
            keccak256(abi.encodePacked(_id, EVENT_VOTE_SALT))
        );

        castVote(vote, msg.sender);
        if (hasOverride(msg.sender)) certifyEvents[_id].overridden = true;

        emit SignedCertifyEvent(_id, msg.sender);
    }

    function executeCertifyEvent(uint256 _id)
        public
        checkActivation
        isAdministrator(msg.sender)
        eventExists(_id)
    {
        uint256 vote = uint256(
            keccak256(abi.encodePacked(_id, EVENT_VOTE_SALT))
        );

        require(
            isTransactionExecutable(
                countVotes(vote),
                certifyEvents[_id].overridden
            )
        );
        endVote(vote);
        delete certifyEvents[_id];
        pendingCertifyEventCount--;

        emit ExecutedCertifyEvent(_id, certifyEvents[_id].data);
    }

    // Getters for AppInventor blocks

    function isCorporateTransactionExecutable(uint256 _id)
        public
        view
        checkActivation
        txExists(_id)
        returns (bool)
    {
        address token = transactionsList[_id].token;
        uint256 amount = transactionsList[_id].amount;

        // Check that we have enough funds.
        if (token == address(0x0)) {
            if (amount > address(this).balance) return false;
        } else {
            IERC20 tok = IERC20(token);
            if (amount > tok.balanceOf(address(this))) return false;
        }

        uint256 vote = uint256(keccak256(abi.encodePacked(_id, TX_VOTE_SALT)));
        return
            isTransactionExecutable(
                countVotes(vote),
                transactionsList[_id].overriden
            );
    }

    function isCorporateCertifyEventExecutable(uint256 _id)
        public
        view
        checkActivation
        eventExists(_id)
        returns (bool)
    {
        uint256 vote = uint256(
            keccak256(abi.encodePacked(_id, EVENT_VOTE_SALT))
        );
        return
            isTransactionExecutable(
                countVotes(vote),
                certifyEvents[_id].overridden
            );
    }

    function getVoteId(uint256 _id, bool isTransactionVote_)
        public
        pure
        returns (uint256)
    {
        if (isTransactionVote_)
            return uint256(keccak256(abi.encodePacked(_id, TX_VOTE_SALT)));
        else return uint256(keccak256(abi.encodePacked(_id, EVENT_VOTE_SALT)));
    }
}
