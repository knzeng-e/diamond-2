//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;
import "./SchemeQAXH.sol";
import "../facets/UsersafeFacet.sol";


contract MandateSafe {

    /*-------------------- Mandate variables --------------------*/
    address public parentSafeAddress;
    string public sci; // FR15ZZZ169587
    string public creditorName; // Banque Populaire Occitanie
    string public creditorThirdParty;
    string public serviceLabel;
    //directDebitType =1 pour un One-off, =2 pour un recurrent
    uint8 public directDebitType;
    //mandateType =1 pour SEPA direct debit on euro
    uint8 public mandateType;
    uint public maxValue;
    //minPeriod exprimée en mois
    uint public minPeriod;
    uint public urmHeader; //*Si changement de type, changer sur QAXH_eth aussi
    //customerID propre à l'application mandate (=5)
    uint8 public customerID;
    //logoCode pour savoir quel logo afficher (=1 pour caisse d'epargne par exemple)
    string public creditorLogoCode;
    // liens vers les api
    string public api_confirmation;
    string public api_revocation;
    string public api_tou;
    string public api_gdpr;
    // versions des cgu
    string public touVersion;
    string public touIssuanceDate;
    string public touHash;

    //safeType = 6 pour un mandateSafe
    uint8 public constant safeType = 6;
    string public constant safeVersion = "6.i";

    // Scheme
    SchemeQAXH schemeSafe;

    struct Mandate {
        uint urm; //complete
        address debtorSafe;
        string hashMandate;
        uint8 status; //état du mandate (0=inexistant, 1= pending, 2=active, 3=revoked)
        uint creationDate;
        uint revocationDate;
    }

    //mandates : mapping(urm => mandate)
    mapping(uint => Mandate) public mandates;
    // urmBody pour savoir où on en est dans les urm de mandats
    uint public urmBodyNonce;
    // debtorToUrmBody pour connaitre l'urmBody associée à un debtor
    mapping(address => uint) public debtorToUrmBody;
    // urmFooterNonce l'urmFooter du dernier mandat signé (ou non)
    mapping(address => uint8) public urmFooterNonce;


    event CreatedUrm(address debtorSafe, uint urm);
    event CreatedMandate(address debtorSafe, uint urm, string hashMandate);
    event RevokedMandate(address debtorSafe, uint urm);

    modifier validUrm(address _debtorSafe, uint _urm) {
        require(debtorToUrmBody[_debtorSafe] != 0, "No mandate for this user");
        require(_urm / 10**14 == urmHeader, "Invalid urmHeader");
        require((_urm / (10**4)) % 10**10 == debtorToUrmBody[_debtorSafe], "Invalid urmBody");
        require(_urm % 10**4 <= urmFooterNonce[_debtorSafe], "Invalid urmFooter");
        _;
    }

    modifier onlyCreditor() {
        require(msg.sender == parentSafeAddress, "Only the parentSafeAdress can call this function");
        _;
    }

    /*-----------------------    Constructeur    -----------------------*/
    constructor(string memory _sci, string memory _creditorName, string memory _creditorLogoCode,
        address _parentSafeAddress, address _schemeSafe, string memory _creditorThirdParty,
        string memory _serviceLabel, uint8 _directDebitType, uint8 _mandateType, uint _maxValue, 
        uint _minPeriod, uint _urmHeader, uint8 _customerID, string memory _api_links
        )
    {
        parentSafeAddress = _parentSafeAddress;
        sci = _sci;
        creditorName = _creditorName;
        creditorThirdParty = _creditorThirdParty;
        serviceLabel = _serviceLabel;
        directDebitType = _directDebitType;
        mandateType = _mandateType;
        maxValue = _maxValue;
        minPeriod = _minPeriod;
        urmHeader = _urmHeader;
        customerID = _customerID;
        creditorLogoCode = _creditorLogoCode;
        schemeSafe = SchemeQAXH(_schemeSafe);

        uint8 i = 0;
        bytes memory api_links = bytes(_api_links);
        byte c = api_links[i++];
        while (keccak256(abi.encodePacked(c)) != keccak256(abi.encodePacked(';'))) {
            api_confirmation = string(abi.encodePacked(api_confirmation, c));
            c = api_links[i++];
        }
        c = api_links[i++];
        while (keccak256(abi.encodePacked(c)) != keccak256(abi.encodePacked(';'))) {
            api_revocation = string(abi.encodePacked(api_revocation, c));
            c = api_links[i++];
        }
        c = api_links[i++];
        while (keccak256(abi.encodePacked(c)) != keccak256(abi.encodePacked(';'))) {
            api_tou = string(abi.encodePacked(api_tou, c));
            c = api_links[i++];
        }
        c = api_links[i++];
        while (keccak256(abi.encodePacked(c)) != keccak256(abi.encodePacked(';'))) {
            api_gdpr = string(abi.encodePacked(api_gdpr, c));
            c = api_links[i++];
        }
    }

    ////////////////////////////         Getters & Setters       ////////////////////////////

    function getLastUrm(address debtorSafe) public view returns(uint) {
        uint urm = urmHeader * 10**10 + debtorToUrmBody[debtorSafe];
        urm = urm * 10**4 + urmFooterNonce[debtorSafe];
        return urm;
    }

    function updateTouVariables(string memory _touVersion, string memory _touIssuanceDate, string memory _touHash) 
            public onlyCreditor() {
        touVersion = _touVersion;
        touIssuanceDate = _touIssuanceDate;
        touHash = _touHash;
    }

    function updateApiVariables(string memory _api_confirmation, string memory _api_revocation,
            string memory _api_tou, string memory _api_gdpr) 
            public onlyCreditor() {
        api_confirmation = _api_confirmation;
        api_revocation = _api_revocation;
        api_tou = _api_tou;
        api_gdpr = _api_gdpr;
    }

    function updateLogoCode(string memory logoCode) public onlyCreditor() {
        creditorLogoCode = logoCode;
    }

    ////////////////////////////    Changement de statut d'un mandat   ////////////////////////////

    /**
     * Réserve une urm au debtor, en créant un mandate avec un status 0 (= pending)
     * Si le debtor a deja une urm on la lui renvoie, et on vérifie qu'il n'a pas de mandat déjà actif
     */
    function debtorSignURM() public {
        require(schemeSafe.isInScheme(msg.sender), "Votre adresse n'est pas reconnue par Qaxh");
        require(UsersafeFacet(msg.sender).getSafeType() == 1, "Seul un userSafe peut signer un mandat");
        require(schemeSafe.getCustomerId(msg.sender) == customerID, "UserSafe d'un autre customerId");

        uint urm;
        if (debtorToUrmBody[msg.sender] == 0) {
            // the debtor doesn't already have a mandate, we create an urmBody
            urmBodyNonce++; //TO-DO: use safeMath .add() to prevent from overflows
            debtorToUrmBody[msg.sender] = urmBodyNonce;
            urm = urmHeader*(10**10) + urmBodyNonce;
        }
        else {
            // we get the existing urmBody
            urm = urmHeader*(10**10) + debtorToUrmBody[msg.sender];
        }
        // we increment the urmFooter
        urmFooterNonce[msg.sender]++;
        urm = urm*(10**4) + urmFooterNonce[msg.sender];

        mandates[urm] = Mandate(urm, msg.sender, "", 1, 0, 0);
        emit CreatedUrm(msg.sender, urm);
    }

    /**
     * Crée (= confirme) un mandat, dont le status passe à 1
     * On vérifie la correspondance utilisateur et urm, et que le mandat ne soit pas actif
     */
    function debtorSignCreate(uint _urm, string memory _hash) public validUrm(msg.sender, _urm) {
        require(mandates[_urm].status == 1, "Mandat deja actif ou revoque");

        mandates[_urm].hashMandate = _hash;
        mandates[_urm].status = 2;
        mandates[_urm].creationDate = block.timestamp;

        emit CreatedMandate(msg.sender, _urm, _hash);
    }

    /**
     * Révoquer un mandat actif
     */
    function debtorSignRevok(uint _urm) public validUrm(msg.sender, _urm) {
        require(mandates[_urm].status == 2, "Pas de mandat actif");

        mandates[_urm].status = 3;
        mandates[_urm].revocationDate = block.timestamp;

        emit RevokedMandate(msg.sender, _urm);
    }

}