import Web3 from 'web3'; 
const web3 = new Web3('http://127.0.0.1:8545'); 
import DjinnBottleUSDC from "./contracts/DjinnBottleUSDC.json"; 
import ShortFarmFTM from "./contracts/ShortFarmFTM.json"; 
import USDCABI from "../../test/abi/USDCABI.json"; 


const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'; 

const options = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: 'ws://127.0.0.1:9545'
    }
  },
  contracts: [DjinnBottleUSDC, ShortFarmFTM, {
	contractName: 'Usdc',
	web3Contract: new web3.eth.Contract(
		USDCABI, 
		USDCAddress	
	)}],
  events: {
    SimpleStorage: ['StorageSet']
  },
  polls: {
    accounts: 15000
  }
}

export default options
