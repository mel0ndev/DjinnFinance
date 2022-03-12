const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545'); 

const USDC = require('./abi/USDCABI.json');
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75';

const shortFarmABI = require('../vapp/src/contracts/DeltaNeutralFtmTomb.json').abi;
const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi;

const vaultAddress = '0xeB791db178589F028552eD2344f23eCE88B8B755'; 
const shortFarmAddress = '0xa0F179944851B1db652B6797A18c8548E0d9f192'; 


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

let unlockedAccount = '0x1a8A0255e8B0ED7C596D236bf28D57Ff3978899b'; 

async function setup() {
	let accounts = await web3.eth.getAccounts();
	let metamaskAccount = accounts[0]; 
	let account2 = accounts[1];

	console.log(await usdc.methods.balanceOf(unlockedAccount).call()); 
	

	await usdc.methods.transfer(metamaskAccount, '100000000').send({from: unlockedAccount}); 
	await usdc.methods.transfer(account2, '100000000').send({from: unlockedAccount}); 
	
	await vault.methods.initialize(shortFarmAddress).send({from: metamaskAccount}); 

}

setup(); 
