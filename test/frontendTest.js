const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545'); 

const USDC = require('./abi/USDCABI.json');
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75';

const shortFarmABI = require('../vapp/src/contracts/ShortFarmFTM.json').abi;
const shortFarmAddress = '0x0F744e1Eb7c33C615E3fA57f93b18fdB46dafe05'; 

const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi;
const vaultAddress = '0xF62b4F17b03b088B207a6fCf2b3BA40d7Dd230C0'; 

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

let unlockedAccount = '0x4a05F104417eA2063a8b02273d4ff523a7968be6'; 

async function setup() {
	let accounts = await web3.eth.getAccounts();
	let metamaskAccount = accounts[0]; 
	let account2 = accounts[1];

	await usdc.methods.transfer(metamaskAccount, '100000000').send({from: unlockedAccount}); 
	await usdc.methods.transfer(account2, '100000000').send({from: unlockedAccount}); 
	
	await vault.methods.initialize(shortFarmAddress).send({from: metamaskAccount}); 

}

setup(); 
