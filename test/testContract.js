//load web3 
const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545'); 

//load external abi
const wFTMABI = require('./abi/wFTMABI.json'); 
const USDC = require('./abi/USDCABI.json'); 
const crUSDCABI = require('./abi/crUSDCABI.json'); 
//load this contract  abi
const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi; 
const shortFarmABI = require('../vapp/src/contracts/ShortFarmFTM.json').abi; 

//load external addresses 
const wFTMAddress = '0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83';
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'; 
const crUSDCAddress = '0x328A7b4d538A2b3942653a9983fdA3C12c571141'; 

//contract addresses 
const vaultAddress = '0xd7FaE0Fe66797aFe531a8bdd33b38f27772B75b9'; 
const shortFarmAddress = '0x7b6c090CF40365b842E0AeAcDc8AfAEDE179bfb2';
//unlocked account 
const unlockedAccount = "0xe81F8F98ae7d42e2dc28DEa4302aaf62c6A5de02";

let shortFarm = new web3.eth.Contract(
	shortFarmABI, 
	shortFarmAddress
);

let vault = new web3.eth.Contract(
	vaultABI, 
	vaultAddress
); 

let wftm = new web3.eth.Contract(
	wFTMABI, 
	wFTMAddress
);

let usdc = new web3.eth.Contract(
	USDC, 
	USDCAddress
);

let crUSDC = new web3.eth.Contract(
	crUSDCABI,
	crUSDCAddress
); 



async function main() {
let accounts = await web3.eth.getAccounts(); 
let sender = accounts[0]; 
	let unlockedBalance = await usdc.methods.balanceOf(unlockedAccount).call(); 
	console.log(unlockedBalance); 
	await usdc.methods.transfer(sender, '100000000').send({from: unlockedAccount}); 

	//our truffle account now has 100 usdc -- easier to see balances 
	let usdcBalance = await usdc.methods.balanceOf(sender).call(); 
	console.log(usdcBalance / 1e6);

	//first we have to initialize the strategy via the vault contract 
	await vault.methods.initialize(shortFarmAddress).send({from: sender, gas: 900000}); 	
	await usdc.methods.approve(vaultAddress, '100000000').send({from: sender}); 
	await vault.methods.deposit('100000000').send({from: sender, gas: 6721975});

	let bal = await wftm.methods.balanceOf(shortFarmAddress).call(); 
	console.log(`contract wftm balance is: ${bal / 1e18}`); 
	//approval in contract is not working but here it is 
		
}

main(); 
