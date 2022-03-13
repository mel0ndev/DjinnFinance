import Web3 from 'web3'; 
const web3 = new Web3(Web3.givenProvider); 

import DjinnBottleUSDC from "./contracts/DjinnBottleUSDC.json"; 
import DeltaNeutralFtmTomb from "./contracts/DeltaNeutralFtmTomb.json"; 
import USDCABI from "../../test/abi/USDCABI.json"; 
import tsharePoolABI from "../../test/abi/tsharePool.json"; 
import tombftmLPABI from "../../test/abi/tombftmLP.json"; 
import tombABI from "../../test/abi/TOMBABI.json"; 
import wftmABI from "../../test/abi/wFTMABI.json"; 

//public addresses
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'; 
const tshareRewardPool = '0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43'; 
const tombftmLP = '0x2A651563C9d3Af67aE0388a5c8F89b867038089e'; 
const tombAddress = '0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7'; 
const wftmAddress = '0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83'; 

const options = {
  web3: {
    block: false,
  },
	syncAlways: true, 
  contracts: [
	  DjinnBottleUSDC,
	  DeltaNeutralFtmTomb, 
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
	)}, 
	{
	contractName: 'WrappedFtm',
	web3Contract: new web3.eth.Contract(
		wftmABI,
		wftmAddress
	)}
  ],
	//events
  polls: {
    accounts: 15000
  }
}

export default options
