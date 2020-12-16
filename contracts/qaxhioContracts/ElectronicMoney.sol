//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

// @title An ERC20 contract which implements the Electronic Euro
// @author Sébastien PIERRE

//import "./OwnerAdministration.sol/";
import "./Owned.sol";
import "./Context.sol/";
import "./ISchemeQAXH.sol";
import "./Libraries/SafeMath.sol/";

contract ElectronicMoney is Owned{

    using SafeMath for uint256;

    // variables et events nécessaires à un ERC 20 classique

    string private _symbol;
    string private _name;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping(address => uint) private _balances;

    //utilisation de allowance pour la limite de création de token par les EMEs
    mapping (address => mapping (address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // Ajout de nouvelles caractéristiques

    //this event recorded token creation and destruction, it's mean exchange between customers and EME
    event Exchange (address indexed from, address indexed to, uint256 value);

    mapping (address => EME) private whitelistEME;
    mapping (address => address) private EMElist;            //mapping de listage
    address internal constant SENTINEL_KEY = address (0x45); //key need for initialiser l'EME list
    uint256 internal CountActiveEME;
    uint256 internal CountTotalEME;

    struct EME {
        address addressEME;
        uint256 limitEuroToken;   //ne pas prendre en compte le nombre de décimales !!! TRES IMPORTANT
        uint256 euroTokenDeliver; // total numbers of token deliver by the EME
        uint256 ratio;           //ratio should be divided by decimals in the app (bc solidity doesn't have floats)
        uint8 whitelisted;       // variable de whitelist dans la structure EME: 0 false, 1 is EME, 2 EME delete
    }

    //mapping pour le customer id, lister tous les CI qui peuvent intéragir avec l'EEUR
    mapping (uint256 => bool) private acceptedCId;
    uint256 public countCId;

    //adresse du regulateur + bool de fin de vie du token => plus d'emission/transfert que des remboursements
    address public regulator;
    bool private endLife;

    ISchemeQAXH public Scheme;  //address dy contrat scheme


    //modifier to check if an address is an EME
    modifier onlyCurrentEME(){
        require (whitelistEME[_msgSender()].whitelisted == 1, "is not a current EME");
        _;
    }

    modifier onlyEME(){
        require (whitelistEME[_msgSender()].whitelisted > 0, "not an EME");
        _;
    }

    modifier onlyEMEAndQAXH(){
        require (whitelistEME[_msgSender()].whitelisted == 1 || _msgSender() == owner, "not EME or Owner");
        _;
    }

/////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////             CONSTRUCTORS                 ////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

constructor (string memory symbol, string memory name, uint256 CID, address _regulator, ISchemeQAXH _Scheme) public {
    _name = name;
    _symbol = symbol;
    _decimals = 10;
    acceptedCId[CID] = true;
    countCId = 1;
    regulator = _regulator;
    Scheme = _Scheme;
    Scheme.addMoney(address(this), _msgSender());

    owner = _msgSender();
    /*
    isAdmin[owner] = true;
    administrations[owner] = SENTINEL_KEYS;
    administrations[SENTINEL_KEYS] = owner;
    countAdmin++;*/
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////              FONCTIONS ERC20          ////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

    function name() public view returns (string memory){
        return _name;
    }

    function symbol() public view returns (string memory){
        return _symbol;
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        require (account != address (0x0), "addr null");
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    //utilisation de la fonction allowance comme base pour la limite des EuroTokens
    function allowance(address _owner, address spender) public view returns (uint256) {
        return _allowances[_owner][spender];
    }


    //modifier onlyOwner car seul Qaxh.io peut augmenter la limite de tokens des EMEs
    function approve(address spender, uint256 amount) public onlyOwner() returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //refléchir aux droits sur cette fonction de l'ERC (potentiellement la supprimer)
    function transferFrom(address sender, address recipient, uint256 amount) public onlyOwner() returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "amount > allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public onlyOwner() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public onlyOwner() returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "allowance < 0"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal {
        //check de tous les paramètres sur les adresses de la transaction
        require(endLife != true, "End of Token");
        require(sender != address(0), "addr null");
        require(recipient != address(0), "addr null");
        require (Scheme.isInScheme(sender) == true && Scheme.isInScheme(recipient) == true,"not in scheme");
        uint256 CIDSender = Scheme.getCustomerId(sender);
        uint256 CIDRecipient = Scheme.getCustomerId(recipient);
        require (checkCustomerId(CIDSender) == true && checkCustomerId(CIDRecipient) == true, "not good CID");
        require (Scheme.getMoney(sender) == 1 && Scheme.getMoney(recipient) == 1, "safes not money true");

        //realisation de la transaction
        _balances[sender] = _balances[sender].sub(amount, "amount > balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


// différence avec ERC20 traditionnel, ici c'est l'EME qui transfère les tokens et pas le contrat. Comme l'EME
// ne possèdent pas les tokens, il doit les créer (mais ces tokens ne passent pas par l'EMESafe)
    function _mint(address account, uint256 amount) internal {
        require(endLife != true, "End of Token");
        require(account != address(0), "addr null");
        require(Scheme.isInScheme(account) == true, "not in scheme");
        uint256 CIDaccount = Scheme.getCustomerId(account);
        require(checkCustomerId(CIDaccount) == true, "not good CID");

        //creation token
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        emit Exchange(_msgSender(), account, amount);
    }


    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "addr null");
        require(Scheme.isInScheme(account) == true, "not in scheme");
        uint256 CIDaccount = Scheme.getCustomerId(account);
        require(checkCustomerId(CIDaccount) == true, "not good CID");

        _balances[account] = _balances[account].sub(amount, "burn > amount");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
        emit Exchange(account, _msgSender(), amount);
    }


    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "owner addr null");
        require(spender != address(0), "sender addr null");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }


/////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////              FONCTIONS EUROTOKEN            ////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////

//L'EME doit absolument être inscrit dans le scheme avant d'être ajouté au mapping de l'EEUR (car l'EEUR vérifie que l'EME est bien inscrit dans le scheme)
    function addToWhitelist (address _addressEME) public onlyOwner() returns (bool){
        require(endLife != true, "End of Token");
        require (_addressEME != address(0x0), "address null");
        require(Scheme.isInScheme(_addressEME) == true, "not in scheme");
        require(whitelistEME[_addressEME].whitelisted != 1, "already added");

        if (whitelistEME[_addressEME].whitelisted == 0){
            EMElist[_addressEME] = EMElist[SENTINEL_KEY];     //ajout au mapping de listage total (uniquement si l'EME n'a jamais été listé)
            EMElist[SENTINEL_KEY] = _addressEME;
            CountTotalEME++;                                  //augmentation de la taille de listage total
        }
        whitelistEME[_addressEME].whitelisted = 1;            //ajout à la whitelist, on crée en même temps la structure EME
        whitelistEME[_addressEME].addressEME = _addressEME;
        whitelistEME[_addressEME].ratio = 1*(10**uint256(_decimals));   //solidity ne possèdent pas de floatant, on utilise
        // la variable décimals pour décrire après la virgule. Ici le ratio est de 1 (0/0 = 1)

        CountActiveEME++;          //augmentation count listage actif

        return true;
    }


    function removeFromWhitelist (address _addressEME) public onlyEMEAndQAXH() returns (bool){
        require (_addressEME != address(0x0), "addr null");
        require (whitelistEME[_addressEME].whitelisted == 1, "not in whitelist");

        whitelistEME[_addressEME].whitelisted = 2;            //on retire l'adresse de la whitelist (passer en false suffit)
        whitelistEME[_addressEME].ratio = 10**(uint256)(_decimals);

        CountActiveEME--;
        return true;
    }


    function getNumberActiveEME () public view returns (uint256){
        return CountActiveEME;
    }

    function getNumberEME () public view returns (uint256){
        return CountTotalEME;
    }


    function isEME (address addEME) public view returns (bool){
        return (whitelistEME[addEME].whitelisted == 1);
    }

    //liste tous les EMEs (current/old)
    function getListAllEME () public view returns (address[] memory){
        address[] memory listEME = new address[](CountTotalEME);
        uint256 index;
        address keyEME;
        for (keyEME = EMElist[SENTINEL_KEY]; keyEME != address(0) && index < CountTotalEME; keyEME = EMElist[keyEME]){
            listEME[index] = keyEME;
            index++;
        }
        return listEME;
    }

    //liste tous les EMEs actifs
    function getListActiveEME () public view returns (address[] memory){
        address[] memory listEME = new address[](CountActiveEME);
        uint256 index;
        address keyEME;
        for (keyEME = EMElist[SENTINEL_KEY]; keyEME != address(0) && index < CountActiveEME; keyEME = EMElist[keyEME]){
            if (whitelistEME[keyEME].whitelisted == 1){
                listEME[index] = keyEME;
                index++;
            }
        }
        return listEME;
    }

    //recupère les infos de tous les EMEs (old as current)
    function getEMEInformations(address _addressEME) public view returns (uint256[] memory){
        require (_addressEME != address(0x0), "addr null");
        require (whitelistEME[_addressEME].whitelisted > 0, "addr not in whitelist");
        uint256[] memory informations = new uint256[](3);
        informations[0] = whitelistEME[_addressEME].limitEuroToken;
        informations[1] = whitelistEME[_addressEME].euroTokenDeliver;
        informations[2] = whitelistEME[_addressEME].ratio;
        return informations;
    }


    //question sur les limites: achete t'on une limite fixe (ex: 1 montant 60) ou un montant cumulatif (ex: 3 de 20 tokens)
    //ici codé pour une limite fixe
    function newTokenLimit (uint256 amount, address addEME) public onlyOwner() returns (bool){
        require (addEME != address(0x0), "address null");
        require (whitelistEME[addEME].whitelisted == 1, "not in whitelist");
        require (amount > whitelistEME[addEME].euroTokenDeliver*10**uint256(_decimals), "limit inf dispense");
        whitelistEME[addEME].limitEuroToken = amount;
        whitelistEME[addEME].ratio = whitelistEME[addEME].euroTokenDeliver.div(whitelistEME[addEME].limitEuroToken);
        _approve(_msgSender(), addEME, amount);
        return true;
    }


    //uniquement les EMEs ACTIFS peuvent "créer des tokens"
    function EMETransferToCustomers (uint256 amount, address addressSafe) public onlyCurrentEME() returns (bool){
        require (whitelistEME[_msgSender()].euroTokenDeliver.add(amount) <= whitelistEME[_msgSender()].limitEuroToken*10**uint256(_decimals),
        "token dispense sup limit");
        require (Scheme.getMoney(addressSafe) == 1, "safe not money true");

        _mint (addressSafe, amount); //creation des tokens vers le compte Safe
        whitelistEME[_msgSender()].euroTokenDeliver = whitelistEME[_msgSender()].euroTokenDeliver.add(amount);
        whitelistEME[_msgSender()].ratio = whitelistEME[_msgSender()].euroTokenDeliver.div(whitelistEME[_msgSender()].limitEuroToken);
        return true;
    }


    //fonction retournant le meilleur EME pour le refund. Se base sur le ratio token emis / limite. On choisi le plus haut ratio
    function bestRefundEME(uint256 amount) public view returns (address){
        uint256 higherRatio;
        address bestEME;
        uint256 index;
        address keyEME;
        //Les vieux EMES peuvent toujours rembourser leurs clients, d'ou la recherche sur tous les EMEs
        for (keyEME = EMElist[SENTINEL_KEY]; keyEME != address(0) && index < CountTotalEME; keyEME = EMElist[keyEME]){
            if (whitelistEME[keyEME].euroTokenDeliver >= amount && whitelistEME[keyEME].ratio > higherRatio){
                higherRatio = whitelistEME[keyEME].ratio;
                bestEME = keyEME;
            }
            index++;
        }
        return bestEME;
    }


    function maxRefund () public view returns (uint256){
        uint256 max;
        address keyEME;
        uint256 index;
        for (keyEME = EMElist[SENTINEL_KEY]; keyEME != address(0) && index < CountTotalEME; keyEME = EMElist[keyEME]){
            if (whitelistEME[keyEME].euroTokenDeliver > max){
                max = whitelistEME[keyEME].euroTokenDeliver;
            }
            index++;
        }
        return max;
    }


    //récupération des tokens par l'EME (on effectue un prévèlèvement), mais on supprime les tokens (on ne les transfère pas sur le compte de l'EME)
    function refund (uint256 amount, address addressSafe) public onlyEME() returns (bool){
        require (amount > 0, "amount < 0");
        require (addressSafe != address (0x0), "address null");
        require (_balances[addressSafe] >= amount, "not enough token in usersafe");
        require (whitelistEME[_msgSender()].euroTokenDeliver >= amount, "not enough euro send by EME");
        _burn (addressSafe, amount);
        whitelistEME[_msgSender()].euroTokenDeliver = whitelistEME[_msgSender()].euroTokenDeliver.sub(amount);

        //on ne baisse le ratio que si l'EME est actif, les vieux EMES devant être vidés en priorité gardent un ratio de 1
        if (whitelistEME[_msgSender()].whitelisted == 1){
            whitelistEME[_msgSender()].ratio = whitelistEME[_msgSender()].euroTokenDeliver.div(whitelistEME[_msgSender()].limitEuroToken);
        }
        return true;
    }


    //connection au scheme
    function setScheme (ISchemeQAXH addr) public onlyOwner() returns (bool){
        Scheme = addr;
        return true;
    }


    //augmentation des customers ID
    function addCustomerId (uint256 id) public onlyOwner() returns (bool){
        acceptedCId[id] = true;
        return true;
    }

    function removeCustomerId (uint256 id) public onlyOwner() returns (bool){
        acceptedCId[id] = false;
        return true;
    }

    function checkCustomerId(uint256 id) public view returns (bool){
        return acceptedCId[id];
    }

    function setEndLife() public returns (bool){
        require (_msgSender() == owner || _msgSender() == regulator, "not owner or regulator");
        endLife = true;
        Scheme.deleteMoney();
        return true;
    }
}