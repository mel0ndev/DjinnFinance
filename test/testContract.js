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
const vaultAddress = '0x66743601C8107c95dbC2AFA58DA2a08999325C72';
const shortFarmAddress = '0xAea855EBA9e12075dfD13F9d2D52df216e19CBE6'; 
const swapAddress = '0xC1a072D42851e1c3b8147D8fef62D661373c57ec'; 
//unlocked account 
const unlockedAccount = "0xCE38d0c1714085C2deD6986Be63bFa6b77b789c2";
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
	await usdc.methods.approve(vaultAddress, '100000000').send({from: sender}); 
	await vault.methods.deposit('100000000').send({from: sender, gas: 6721975});
	console.log("Position has been opened!"); 
	let total = await vault.methods.totalSupply().call(); 
	let ownership = await vault.methods.balanceOf(sender).call(); 
	console.log(`Your percentage of the pool is: ${ownership / total * 100}% `); 

	console.log("----------------------------------------------------"); 
	let shares  = await vault.methods.balanceOf(sender).call(); 
	console.log(shares); 
	let strategyBal = await shortFarm.methods.balanceOf(shortFarmAddress).call();
	console.log(strategyBal); 
	let amountPerShares = strategyBal / shares; 
	console.log(`amount per share: ${amountPerShares}`); 
	console.log(`lp tokens to withdraw: ${amountPerShares * shares}`); 

	let check = await shortFarm.methods.depositBalance(sender).call(); 
	console.log(check); 

	setTimeout(sleepy, 1000); 

}
//TODO calculate how to get deposit amount - how much is being borrowed against
async function sleepy() {
let accounts = await web3.eth.getAccounts(); 
let sender = accounts[0]; 
	await vault.methods.withdraw('100000000').send({from: sender, gas: maxGas});
	let underlingBalance = await shortFarm.methods.getUnderlying().call();
	console.log(underlingBalance); 

	let balls = await shortFarm.methods.getUnderlying().call(); 
	console.log(`underlying crUSDC remaining supplied: ${balls}`); 
	
	//TODO 
	//WFTM and crUSDC swap rates are not functioning rn 
	console.log('Position has been closed!'); 
}

main(); 
