const Diamond = artifacts.require('Diamond');
const UsersafeFacet = artifacts.require('UsersafeFacet');
const DiamondCutFacet = artifacts.require('DiamondCutFacet')


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

const zeroAddress = '0x0000000000000000000000000000000000000000';


module.exports = async (deployer, network, accounts) => {
    const diamond = await Diamond.deployed();
    
    const usersafeAddress = await deployer.deploy(UsersafeFacet, accounts[0], "QI_HASH", "QE_HASH", 1, 21, "CustomerID");

    const _diamondCut = [
        [UsersafeFacet.address, FacetCutAction.Add, getSelectors(UsersafeFacet)],
    ]

    const diamondCut = await DiamondCutFacet.deployed(); 
    const diamondInstance = new web3.eth.Contract(diamondCut.abi, diamond.address)


    await diamondInstance.methods.diamondCut(_diamondCut, zeroAddress, '0x').send({
        from: accounts[0],
        gas: 1000000
    })
}