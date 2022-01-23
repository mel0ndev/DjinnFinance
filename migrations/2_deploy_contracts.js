const DjinnBottleUSDC = artifacts.require("DjinnBottleUSDC"); 
const ShortFarmFTM = artifacts.require("ShortFarmFTM"); 

const USDC = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"; 
const spookyRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29"; 
const tShareRewardPool = "0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43"; 
const comptroller = "0x4250A6D3BD57455d7C6821eECb6206F507576cD2"; 
const priceOracle = "0x56E2898E0ceFF0D1222827759B56B28Ad812f92F"; 
const crWFTM = "0xd528697008aC67A21818751A5e3c58C8daE54696"; 

module.exports = async function(deployer) {
	await deployer.deploy(DjinnBottleUSDC, USDC); 
	const vaultInstance = await DjinnBottleUSDC.deployed(); 
	const vaultAddress = await vaultInstance.address; 

	await deployer.deploy(ShortFarmFTM, spookyRouter, vaultAddress, tShareRewardPool, comptroller, priceOracle, crWFTM); 
};
