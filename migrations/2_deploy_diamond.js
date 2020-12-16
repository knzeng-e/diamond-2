/* eslint-disable prefer-const */
/* global artifacts */

const Diamond = artifacts.require('Diamond')
const Etagfacet = artifacts.require('EtagFacet')
// const UsersafeFacet = artifacts.require('UsersafeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const KeyManagerFacet = artifacts.require('KeyManagerFacet')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet');
const MandateManagerFacet = artifacts.require('MandateManagerFacet');
const IdentityReaderFacet = artifacts.require('IdentityReaderFacet');
const IdentityManagerFacet = artifacts.require('IdentityManagerFacet')

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}

function getSelectors(contract) {
  const selectors = contract.abi.reduce((acc, val) => {
    if (val.type === 'function') {
      console.log("function: ", val.name, ' ==> ', val.signature)
      acc.push(val.signature)
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

module.exports = function (deployer, network, accounts) {
  deployer.deploy(Etagfacet);
  deployer.deploy(KeyManagerFacet);
  deployer.deploy(DiamondCutFacet);
  deployer.deploy(DiamondLoupeFacet);

  deployer.deploy(IdentityManagerFacet).then(() => {
    console.log("IdentityManager deployed at address ==> ", IdentityManagerFacet.address);
    console.log("[IdentityManager] Function selectors ==> ", getSelectors(IdentityManagerFacet));
  });

  // deployer.deploy(UsersafeFacet, accounts[0], "QI_HASH", "QE_HASH", 1, 21, "CustomerID").then(() => {
  //   console.log("Usesafe deployed at address ==> ", UsersafeFacet.address);
  //   console.log("[QaxhModule] Function selectors ==> ", getSelectors(UsersafeFacet))
  // });

  deployer.deploy(IdentityReaderFacet).then(() => {
    console.log("IdentityReaderFacet deployed at address ==> ", IdentityReaderFacet.address);
    console.log("[IdentityReaderFacet] Function selectors ==> ", getSelectors(IdentityReaderFacet))
  });

  deployer.deploy(MandateManagerFacet).then(() => {
    console.log("[MandateManager] Function selectors ==> ", getSelectors(MandateManagerFacet))
  });

  deployer.deploy(OwnershipFacet).then(() => {
    const diamondCut = [
      [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
      [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
      [Etagfacet.address, FacetCutAction.Add, getSelectors(Etagfacet)],
      [KeyManagerFacet.address, FacetCutAction.Add, getSelectors(KeyManagerFacet)],
      [MandateManagerFacet.address, FacetCutAction.Add, getSelectors(MandateManagerFacet)],
      [IdentityReaderFacet.address, FacetCutAction.Add, getSelectors(IdentityReaderFacet)],
      [IdentityManagerFacet.address, FacetCutAction.Add, getSelectors(IdentityManagerFacet)]
    ]
    return deployer.deploy(Diamond, diamondCut, [accounts[0]]);
  })
}
