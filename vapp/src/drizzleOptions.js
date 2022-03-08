import Web3 from 'web3'; 
const web3 = new Web3('http://127.0.0.1:8545'); 
import DjinnBottleUSDC from "./contracts/DjinnBottleUSDC.json"; 
import DeltaNeutralFtmTomb from "./contracts/DeltaNeutralFtmTomb.json"; 
import USDCABI from "../../test/abi/USDCABI.json"; 
import tsharePoolABI from "../../test/abi/tsharePool.json"; 
import tombftmLPABI from "../../test/abi/tombftmLP.json"; 
import tombABI from "../../test/abi/TOMBABI.json"; 


const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'; 
const tshareRewardPool = '0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43'; 
const tombftmLP = '0x2A651563C9d3Af67aE0388a5c8F89b867038089e'; 
const tombAddress = '0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7'; 

const options = {
  web3: {
    block: false,
    fallback: {
      type: 'ws',
      url: 'ws://127.0.0.1:9545'
    }
  },
  contracts: [DjinnBottleUSDC, DeltaNeutralFtmTomb, 
	{
	contractName: 'Usdc',
	web3Contract: new web3.eth.Contract(
		USDCABI, 
		USDCAddress	
	)},
	{
	contractName: 'TShareRewardPool',
	web3Contract: new web3.eth.Contract(
		tsharePoolABI,
		tshareRewardPool
	)},
	{
	contractName: 'UniswapV2Pair',
	web3Contract: new web3.eth.Contract(
		tombftmLPABI,
		tombftmLP
	)},
	{
	contractName: 'Tomb',
	web3Contract: new web3.eth.Contract(
		tombABI, 
		tombAddress
	)}
  ],
	//events
  polls: {
    accounts: 15000
  }
}

export default options
