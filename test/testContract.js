//load web}); 
const Web3 = require('web3'); 
const web3 = new Web3('http://127.0.0.1:8545'); 

//load external abi
const wFTMABI = require('./abi/wFTMABI.json'); 
const USDC = require('./abi/USDCABI.json'); 
const crUSDCABI = require('./abi/crUSDCABI.json'); 
const TombABI = require('./abi/TOMBABI.json'); 
const lpABI = require('./abi/lpABI.json'); 

//load this contract  abi
const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi; 
const shortFarmABI = require('../vapp/src/contracts/ShortFarmFTM.json').abi; 
const swapABI = require('../vapp/src/contracts/Swap.json').abi;


//load external addresses 
const wFTMAddress = '0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83';
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75'; 
const crUSDCAddress = '0x328A7b4d538A2b3942653a9983fdA3C12c571141'; 
const TombAddress = '0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7';  
const lpAddress = '0x2A651563C9d3Af67aE0388a5c8F89b867038089e'

//contract addresses 
const vaultAddress = '0x3E71ddadF3A81ECEf1b32ea28c5d8FE4D75B26D1'; 
const shortFarmAddress = '0x3348ae5e61B2723f48d825C0954dc14a3F214993';
const swapAddress = '0xC1a072D42851e1c3b8147D8fef62D661373c57ec'; 
//unlocked account 
const unlockedAccount = "0x4a05F104417eA2063a8b02273d4ff523a7968be6";
const wftmWhale = "0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB"; 

//initialize web3 contracts 
let shortFarm = new web3.eth.Contract(
	shortFarmABI, 
	shortFarmAddress
);

let vault = new web3.eth.Contract(
	vaultABI, 
	vaultAddress
); 

let swap = new web3.eth.Contract(
	swapABI, 
	swapAddress
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

let tomb = new web3.eth.Contract(
	TombABI, 
	TombAddress
); 

let lpToken = new web3.eth.Contract(
	lpABI,
	lpAddress	
); 


const maxGas =  6721975; 

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
	//check total supply before mint 
	await usdc.methods.approve(vaultAddress, '100000000').send({from: sender}); 
	await vault.methods.deposit('100000000').send({from: sender, gas: 6721975});
	console.log("Position has been opened!"); 
	
	console.log("----------------------------------------------------");
	
	let tokenBorrow = await shortFarm.methods.tokenBorrowBalance(sender).call(); 
	console.log(tokenBorrow); 
	
	await multiDeposit(); 
	setTimeout(sleepy, 1000); 

}

async function multiDeposit() {
let accounts = await web3.eth.getAccounts(); 
	for (i = 1; i < 5; i++) {
		let account = accounts[i]; 

	await usdc.methods.transfer(account, '100000000').send({from: unlockedAccount});
	await usdc.methods.approve(vaultAddress, '100000000').send({from: account}); 
	await vault.methods.deposit('100000000').send({from: account, gas: maxGas});	

	let borrowAmount = await shortFarm.methods.getBorrowAmount().call()
	console.log(`liquidity in USD: ${borrowAmount[0] / 1e18}`);
	
	let totalUserBorrow = await shortFarm.methods.tokenBorrowBalance(account).call();
	console.log(`total user borrow: ${totalUserBorrow / 1e18}`); 

	let totalBorrow = await shortFarm.methods.borrowBalance().call();
	console.log(`total borrow amount is now: ${totalBorrow / 1e18}`);
	
	}

	
	let underlying = await shortFarm.methods.getUnderlying().call();
	console.log(underlying / 1e6);  
	
	console.log("Accounts done depositing"); 
	
}

async function sleepy() {
let accounts = await web3.eth.getAccounts(); 
let sender = accounts[0]; 
	let withdrawAmount = await vault.methods.balanceOf(sender).call(); 
	await vault.methods.withdraw(withdrawAmount).send({from: sender, gas: maxGas});

	console.log('Position has been closed!'); 
	console.log('--------------------------------------------'); 
	
	let profits = await usdc.methods.balanceOf(sender).call(); 
	console.log(profits / 1e6); 

	let tsharesEarned = await shortFarm.methods.tshareBalance().call(); 
	console.log(tsharesEarned); 

	let lpTokenBalance = await shortFarm.methods.balanceOf(shortFarmAddress).call(); 
	console.log(lpTokenBalance); 

	await vault.methods.harvest().send({from: sender, gas: maxGas}); 
	let ass = await shortFarm.methods.ass().call(); 
	console.log(ass); 

}

main(); 
