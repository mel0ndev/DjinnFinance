const DjinnBottleUSDC = artifacts.require("DjinnBottleUSDC"); 
const DeltaNeutral = artifacts.require("DeltaNeutralFtmTomb"); 

const USDC = "0x04068DA6C83AFCFA0e13ba15A6696662335D5B75"; 
const spookyRouter = "0xF491e7B69E4244ad4002BC14e878a34207E38c29"; 
const comptroller = "0x4250A6D3BD57455d7C6821eECb6206F507576cD2"; 
const priceOracle = "0x56E2898E0ceFF0D1222827759B56B28Ad812f92F"; 
const treasuryWallet = '0xFD3d00800BD75922643B87650EBdb6B338235B7e'; 

module.exports = async function(deployer) {

	await deployer.deploy(DjinnBottleUSDC, USDC, treasuryWallet); 
	const vaultInstance = await DjinnBottleUSDC.deployed(); 
	const vaultAddress = await vaultInstance.address; 
	await deployer.deploy(DeltaNeutral, vaultAddress, spookyRouter, comptroller, priceOracle, treasuryWallet); 

}
