//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.21 <0.8.0;

/// @title Contract which implements the creation and use of an EMESafe
/// @author Sébastien PIERRE

import "./Context.sol";
import "./ElectronicMoney.sol";

contract EMESafe is Context{

    using SafeMath for uint256;

	ElectronicMoney internal EEUR;

	uint8 public safeType;
	uint256 public CID;
	string public brandName;
	address public QAXHIO;
	address public regulator;
	address public EOA;
	uint256 public limitTokenEmission;

	//attribut fourni directement par EOA (pas a la construction)
	string public API_EEURObyTransfer;  //virement
	string public API_refund;
	string public IBAN;
	string public API_Credittransfer;
	string public API_EEURObyCard;      //payement par carte
	string public API_tarification;
	string public hash_terms_of_use;
	string public date_issuance_TOU;
	string public version_TOU;

	modifier onlyEOA (){
		require (_msgSender() == EOA, "not the EOA");
		_;
	}

	modifier onlyRegulator(){
		require (_msgSender() == regulator, "not the regulator");
		_;
	}

	modifier onlyQAXHIO(){
		require (_msgSender() == QAXHIO, "not QAXHIO");
		_;
	}

	////////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////                 Constructors                   ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////

	constructor (address _regulator, address _EOA, uint256 limit, string memory _name) {
		safeType = 7;
		QAXHIO = _msgSender();
		regulator = _regulator;
		EOA = _EOA;
		limitTokenEmission = limit;
		brandName = _name;
		CID = 0;
	}

	//////////////////////////////////////////////////////////////////////////////////////////////////////
	////////////////////                 Fonctions EME                 ///////////////////////////////////
	///////////////////////////////////////////////////////////////////////////////////////////////////////


	//on indique l'adresse du contrat ElectronicEuro pour pouvoir appeler ses fonctions après
	function setEuroAddress (ElectronicMoney addr) public onlyQAXHIO() returns (bool){
		EEUR = addr;
		return true;
	}

	function changeRegulator (address addr) public onlyQAXHIO() returns (bool){
		require (addr != address(0x0), "the new address is null");
		regulator = addr;
		return true;
	}

	function setAPI_transfer (string memory URL) public onlyEOA() returns (bool){
		API_EEURObyTransfer = URL;
		return true;
	}

	function setAPI_Card (string memory URL) public onlyEOA() returns (bool){
		API_EEURObyCard = URL;
		return true;
	}

	function setAPI_refund (string memory URL) public onlyEOA() returns (bool){
		API_refund = URL;
		return true;
	}

	function setAPI_tarification (string memory URL) public onlyEOA() returns (bool){
		API_tarification = URL;
		return true;
	}

	function set_IBAN (string memory _IBAN) public onlyEOA() returns (bool){
		IBAN = _IBAN;
		return true;
	}

	function setDate_of_Issuance (string memory DOI) public onlyEOA() returns (bool){
		date_issuance_TOU = DOI;
		return true;
	}

	function setHash_terms_of_use (string memory _TOU) public onlyEOA() returns (bool){
		hash_terms_of_use = _TOU;
		return true;
	}

	function set_version (string memory _version) public onlyEOA() returns (bool){
		version_TOU = _version;
		return true;
	}

	function set_name (string memory name) public onlyEOA() returns (bool){
		brandName = name;
		return true;
	}


	//fonctions activant les fonctions de l'Electronic Euro

	function tokenTransferToCustomer (uint256 amount, address safe) public onlyEOA() returns(bool){
		//require déjà present dans l'ERC
		EEUR.EMETransferToCustomers(amount, safe);  //appel ElectronicEuro
		return true;
	}

	function tokenRefund (uint256 amount, address safe) public onlyEOA() returns(bool){
		//require déjà présent dans l'ERC
		EEUR.refund(amount, safe);
		return true;
	}

	//le régulateur retire le statut EME en appelant une fonction de l'EME.
	function removeByRegulator () public onlyRegulator() returns (bool){
		EEUR.removeFromWhitelist(address(this));
		return true;
	}

	function changeLimits (uint256 amount) public onlyQAXHIO() returns (bool){
		limitTokenEmission = amount;
		return true;
	}



	//rechargement des micros éthers sur tous les devices d'un UserSafe   ///TODO////

}