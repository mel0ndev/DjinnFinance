const Web3 = require('web3');  
const web3 = new Web3('http://127.0.0.1:8545'); 
 
const USDC = require('./abi/USDCABI.json');
const USDCAddress = '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75';

const shortFarmABI = require('../vapp/src/contracts/DeltaNeutralFtmTomb.json').abi;
const shortFarmAddress = '0xE5554c7C0F84eB62aAc8518f9d19B6F3294B9129'; 

const vaultABI = require('../vapp/src/contracts/DjinnBottleUSDC.json').abi;
const vaultAddress = '0xB4b743196f72dB42d00990E909B461a514E8057E'; 

let vault = new web3.eth.Contract(
    vaultABI,
    vaultAddress
);


usdc = new web3.eth.Contract(
    USDC, 
    USDCAddress
);

let shortFarm = new web3.eth.Contract(
    shortFarmABI, 
    shortFarmAddress
);

let unlockedAccount = '0x30bdd77514BEab40c433c5e09AA9a8b87700D6c8'; 

async function harvest() {
    let accounts = await web3.eth.getAccounts();
    let metamaskAccount = accounts[0];

    await vault.methods.harvest().send({from: metamaskAccount, gas: 678312});
}

harvest(); 

