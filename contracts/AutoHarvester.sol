pragma solidity ^0.8.10;

import "./DjinnBottleUSDC.sol"; 


contract AutoHarvester {

	address private admin; 
	DjinnBottleUSDC public VAULT; 

	constructor() {
		admin = msg.sender;
	}
	
	function addVault(address _vault) external {
		require(msg.sender == admin, "not admin"); 	
		VAULT = DjinnBottleUSDC( _vault); 
	}

	function autoHarvest() external {
		require(msg.sender == admin, "not admin"); 
		VAULT.callHarvest(); 	
	}

	function giveGasFees(uint amount) external {
		require(msg.sender == admin, "not admin");	
		(bool sent, bytes memory data) = address(VAULT).call{value: amount}(""); 
		require(sent, "Failed to transfer FTM: Check balance"); 
	}	


	receive() external payable{} 


}
