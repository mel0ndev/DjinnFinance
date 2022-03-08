// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.10; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "./strategies/CreamFtmTombStrategy.sol"; 

//The deposit contract for Djinn Finance
contract DjinnBottleUSDC is ERC20 {

	IERC20 public usdc;
	uint private constant PROTOCOL_FEE = 100; 
	address public PROTOCOL_TREASURY; //the protocol collects 1% USDC deposits and 1% yield bearing assets
	bool public isPaused; 

	address private admin; //deployer address used to perform basic admin features
	DeltaNeutralFtmTomb public deltaNeutral; 

	constructor( address _usdc, address _treasury) ERC20("Djinn Finance USDC Vault","dfUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
		PROTOCOL_TREASURY = _treasury; 
	}

	function changeTreasuryAddress(address newAddress) external {
		require(msg.sender == admin, "!admin"); 
		PROTOCOL_TREASURY = newAddress; 	
		deltaNeutral.setTreasury(newAddress); 
	}

	function changeAdmin(address newAdmin) external {
		require(msg.sender == admin, "!admin"); 
		admin = newAdmin; 
	}
	
	//set strategy address 
	function initialize(DeltaNeutralFtmTomb _deltaNeutral) external {
		require(msg.sender == admin, "!admin"); 
		deltaNeutral = _deltaNeutral; 
	}

	function deposit(uint amount) public {
		require(isPaused == false, "deposits are not allowed at this time"); 
		usdc.transferFrom(msg.sender, address(this), amount); 		

		uint feeAmount = (amount * PROTOCOL_FEE) / 1e4;  //1% deposit fee 
		uint newAmount = amount - feeAmount;
		uint shareAmount = (newAmount * totalSupply()) / 1e8; 

		//send to strategy contract 
		usdc.transfer(address(deltaNeutral), newAmount); 
		deltaNeutral.open(msg.sender, newAmount);  

		//send fee to treasury address 
		usdc.transfer(PROTOCOL_TREASURY, feeAmount); 
	}
	
	//we get msg.sender's % of pool and then use that to convert to tokens 
	function withdraw(uint amountShares) public returns(uint) {
		require(amountShares <= IERC20(address(this)).balanceOf(msg.sender), "no"); 
				
		//then we pass this to the strategy contract to withdraw the correct % of LP tokens (I think??) 
		uint beforeBal = usdc.balanceOf(address(this)); 
		deltaNeutral.close(msg.sender, amountShares); 
		uint afterBal = usdc.balanceOf(address(this));

		_burn(msg.sender, amountShares); 	

		//send back user their usdc 
		uint amountToWithdraw = afterBal - beforeBal; 
		usdc.transfer(msg.sender, amountToWithdraw);
	}	

	function harvest() external {
		require(msg.sender == admin, "!admin"); 
		deltaNeutral.harvest(); 
	}

	function storeCrTokens(address user, uint amountUSDC, uint amountETH) external {
		require(msg.sender == address(deltaNeutral), "no"); 
		uint amountTotal = amountUSDC + amountETH; 
		_mint(user, amountTotal); 
	}	

	function pause() external {
		require(msg.sender == admin, "!admin");		

		if (isPaused == false) {
			isPaused = true; 
		} else {
			isPaused = false; 
		}
	}

}
