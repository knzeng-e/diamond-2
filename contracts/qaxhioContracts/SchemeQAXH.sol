//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

// @title A contract which is a new version of the Scheme.
// @description: There is a first essay of administration functions but there is an issue when votes occur.
//               Indeed, if an administrator doesnt wnant to vote, he blocks the mechanism of adding a new administrator
// @author Sébastien PIERRE

//importation of Context and VoteManager (can be change because we use it only for administration of the scheme)
import "./Context.sol/";
import "./VoteManager.sol/";
import "./ISchemeQAXH.sol/";

contract SchemeQAXH is Context, VoteManager, ISchemeQAXH{

///////////////////////////////////////////////////////////////////////////////////////////////////
    //Adminitration of the Scheme Safe (Owner are different plateform (QAXH.IO, QAXH++ ... ))
    mapping (address => bool) public ownership;
    mapping (address => address) public owners;
    address internal constant SENTINEL_KEY = address (0x51);
    uint256 public countOwners;

    address public newOwner;
    address public newOwnerTransferTo;
    address public newOwnerTransferFrom;

    event NewOwnerPending (address indexed _newOwner);
    event NewOwnerAccepted (address indexed _newOwner);
    event NewOwnershipTransferred(address indexed _from, address indexed _to);


///////////////////////////////////////////////////////////////////////////////////////////////

    struct safe {
        uint256 safeType;
        uint256 customerId;
        uint256 money;    // 0 false  -  1 true
        address linkedPlateform;
    }

    mapping (address => safe) internal registeredSafes;

    struct money{
        uint8 state;            //  O => not money  //  1 => pendingMoney  //  2 => Money activated  //  3 => deleted Money
        address linkedPlatform;
    }

    mapping (address => money) internal electronicMoney;
    mapping (address => address) private moneyList;            //mapping de listage:also use SENTINEL KEY
    uint256 public countMoney;

//////////////////////////////////////////////////////////////////////////////////////////////////
//   List of modifier

    modifier onlyOwners {
        require(ownership[_msgSender()] == true, "you are not an owner");
        _;
    }

/////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////                     CONSTRUCTORS                           ////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

    constructor() {
        ownership[_msgSender()] = true;
        owners[SENTINEL_KEY] = _msgSender();
        owners[_msgSender()] = SENTINEL_KEY;
        countOwners++;
        emit NewOwnerAccepted(_msgSender());
    }

///////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////              Scheme Functions               //////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

    function isInScheme (address addr) public override view returns (bool){
        return (registeredSafes[addr].linkedPlateform != address(0x0));
    }

    function getLinkedPlatform (address addr) public override view returns (address){
        require (isInScheme(addr) == true, "not in the scheme");
        return registeredSafes[addr].linkedPlateform;
    }

    function getCustomerId (address addr) public override view returns (uint256){
        require (isInScheme(addr) == true, "not in the scheme");
        return registeredSafes[addr].customerId;
    }

    function getMoney (address addr) public override view returns (uint256){
        require (isInScheme(addr) == true, "not in the scheme");
        return registeredSafes[addr].money;
    }

    function getSafeType (address addr) public override view returns (uint256){
        require (isInScheme(addr) == true, "not in the scheme");
        return registeredSafes[addr].safeType;
    }

    function addSafe (address addr, uint256 _safeType, uint256 _customerId, uint256 _money) public override onlyOwners() returns (bool){
        require (addr != address(0x0), "address null");
        require (isInScheme(addr) != true, "already registered");
        registeredSafes[addr].money = _money;
        registeredSafes[addr].customerId = _customerId;
        registeredSafes[addr].safeType = _safeType;
        registeredSafes[addr].linkedPlateform = msg.sender;
        return true;
    }


    function addMoney (address addrMoney, address platform) public override returns (bool){
        require (addrMoney != address(0x0), "address null");
        require (electronicMoney[addrMoney].state == 0, "money already created or ask");
        electronicMoney[addrMoney].state = 1;
        electronicMoney[addrMoney].linkedPlatform = platform;
        return true;
    }

    function acceptMoney (address addrMoney) public override  onlyOwners() returns (bool){
        require (electronicMoney[addrMoney].state == 1, "not pending money");
        require (_msgSender() == electronicMoney[addrMoney].linkedPlatform, "not the right admin");
        electronicMoney[addrMoney].state = 2;
        moneyList[addrMoney] = moneyList[SENTINEL_KEY];     //ajout au mapping de listage total (uniquement si l'EME n'a jamais été listé)
        moneyList[SENTINEL_KEY] = addrMoney;
        countMoney++;
        return true;
    }

    function isTypeMoney (address addrMoney) public override  view returns (uint8){
        return (electronicMoney[addrMoney].state);
    }

    function getAllMoney () public override view returns (address[] memory){
        address[] memory listAllMoney = new address[](countMoney);
        uint256 index;
        address keyM;
        for (keyM = moneyList[SENTINEL_KEY]; keyM != address(0) && index < countMoney; keyM = moneyList[keyM]){
            listAllMoney[index] = keyM;
            index++;
        }
        return listAllMoney;
    }

    function getMoneyLinkedPlatform (address addrMoney) public override view returns (address){
        return (electronicMoney[addrMoney].linkedPlatform);
    }

    function deleteMoney () public override returns (bool){
        require (electronicMoney[_msgSender()].state == 2, "not a money accepted");
        electronicMoney[_msgSender()].state = 3;
        return true;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////       Administration fonctions of Scheme    //////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////

    //Creation of a new vote for a new OwnershipPlateform (another QAXHIO plateform)
    function createNewOwnership(address _newOwner) public override onlyOwners() returns (bool){
        require (voteExists(1) == false, "already a pending owner vote"); //limitation to 1 vote for the election of new owner
        newOwner = _newOwner;
        createVote(1);
        emit NewOwnerPending(_newOwner);
        return true;
    }

    function votingOwner() public override onlyOwners() returns (bool){
        castVote(1, _msgSender());
        return true;
    }


    //New owner needs to accept the vote of Ownership. When it is done, the new owner will automatically be add to owners list.
    function acceptOwnership() public override returns (bool){
        require (countVotes(1) == countOwners, "Some Owners do not have voted yet");
        require (_msgSender() == newOwner, "you are not the new owner");
        ownership[newOwner] = true;
        owners[newOwner] = owners[SENTINEL_KEY];
        owners[SENTINEL_KEY] = newOwner;
        countOwners++;
        emit NewOwnerAccepted(_msgSender());
        delete newOwner;
        endVote(1);
        return true;
    }

    function transferNewOwnership(address _newOwner) public override onlyOwners() returns (bool){
        require (newOwnerTransferTo == address(0), "transfer pending");
        require (newOwnerTransferFrom == address(0), "transfer pending");
        newOwnerTransferTo = _newOwner;
        newOwnerTransferFrom = _msgSender();
        return true;
    }


    function acceptTransferOwnership() public override returns (bool){
        require (_msgSender() == newOwnerTransferTo, "not the new Owner transfer");
        //change in ownership whitelist
        ownership[newOwnerTransferTo] = true;
        ownership[newOwnerTransferFrom] = false;

        //search in ownership, the address which leads to the old address (to replace it with the new one)
        address addr = SENTINEL_KEY;
        while (owners[addr] != newOwnerTransferFrom){
            addr = owners[addr];
        }
        owners[addr] = newOwnerTransferTo;
        owners[newOwnerTransferTo] = owners[newOwnerTransferFrom];

        //delete data and emit event
        delete owners[newOwnerTransferFrom];
        emit NewOwnershipTransferred(newOwnerTransferFrom, newOwnerTransferTo);
        delete newOwnerTransferTo;
        delete newOwnerTransferFrom;
        return true;
    }

    function existingVote () public view onlyOwners() override returns (bool){
        bool exist = voteExists(1);
        return exist;
    }

    function alreadyVoted (address _voter) public override view onlyOwners() returns (bool){
        bool already = hasVoted(1, _voter);
        return already;
    }

    function numberVotes () public override view onlyOwners() returns (uint256){
        uint256 number = countVotes(1);
        return number;
    }
}