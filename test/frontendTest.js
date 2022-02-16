const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545'); 

const USDC = require('./abi/USDCABI.json');
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75';

const shortFarmABI = require('../vapp/src/contracts/ShortFarmFTM.json').abi;
const shortFarmAddress = '0xed8aa9aCA4877e2982C5c2A9eCb1c7162189D1C4'; 

const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi;
const vaultAddress = '0xC2467C896eD696Bb5331ceEAde2A51b31e671c42'; 

let vault = new web3.eth.Contract(
	vaultABI,
	vaultAddress
);


let usdc = new web3.eth.Contract(
	USDC, 
	USDCAddress
);

let shortFarm = new web3.eth.Contract(
	shortFarmABI, 
	shortFarmAddress
);

let unlockedAccount = '0x30bdd77514BEab40c433c5e09AA9a8b87700D6c8'; 

async function setup() {
	let accounts = await web3.eth.getAccounts();
	let metamaskAccount = accounts[0]; 
	let account2 = accounts[1]; 

	await usdc.methods.transfer(metamaskAccount, '100000000').send({from: unlockedAccount}); 
	await usdc.methods.transfer(account2, '100000000').send({from: unlockedAccount}); 
	
	await vault.methods.initialize(shortFarmAddress).send({from: metamaskAccount}); 

}

setup(); 
