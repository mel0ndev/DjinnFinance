// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.10; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "./strategies/ShortFarmFTM.sol"; 

//The deposit contract for Djinn Finance
contract DjinnBottleUSDC is ERC20 {

//	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  	 
	IERC20 public usdc;
	
//	mapping(address => uint) public crShares; 

	uint private constant PROTOCOL_FEE = 100; 
	address public PROTOCOL_TREASURY; //the protocol collects 1% USDC deposits and 1% yield bearing assets

	address private admin; //deployer address used to perform basic admin features
	ShortFarmFTM public shortStrategy; 

	constructor( address _usdc, address _treasury) ERC20("Djinn Finance USDC Vault","dfUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
		PROTOCOL_TREASURY = _treasury; 
	}

	function changeTreasuryAddress(address newAddress) external {
		require(msg.sender == admin, "!admin"); 
		PROTOCOL_TREASURY = newAddress; 	
		shortStrategy.setTreasury(newAddress); 
	}

	function changeAdmin(address newAdmin) external {
		require(msg.sender == admin, "!admin"); 
		admin = newAdmin; 
	}
	
	//set strategy address 
	function initialize(ShortFarmFTM _shortStrategy) external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy = _shortStrategy; 
	}

	function balance() public returns(uint) {
		return usdc.balanceOf(address(this)) + shortStrategy.getUnderlying(); 
	}

	function getTotal() public returns(uint) {
		return totalSupply(); 
	}
	
	function deposit(uint amount) public {
		usdc.transferFrom(msg.sender, address(this), amount); 		

		uint feeAmount = (amount * PROTOCOL_FEE) / 1e4;  //1% deposit fee 
		uint newAmount = amount - feeAmount;

		//send to strategy contract 
		usdc.transfer(address(shortStrategy), newAmount); 
		shortStrategy.open(msg.sender, newAmount);  

		//send fee to treasury address 
		usdc.transfer(PROTOCOL_TREASURY, feeAmount); 
	}
	
	//we get msg.sender's % of pool and then use that to convert to tokens 
	function withdraw(uint amountShares) public returns(uint) {
		require(amountShares <= IERC20(address(this)).balanceOf(msg.sender), "no"); 
		//so we do not divide by zero 
		if (amountShares < totalSupply()) {
			_burn(msg.sender, amountShares); 
		}
		//then we pass this to the strategy contract to withdraw the correct % of LP tokens
		uint beforeBal = usdc.balanceOf(address(this)); 
		shortStrategy.close(msg.sender, amountShares); 
		uint afterBal = usdc.balanceOf(address(this));
		//send back user their usdc 
		uint amountToWithdraw = afterBal - beforeBal; 
		usdc.transfer(msg.sender, amountToWithdraw); 

		//if they are the last to withdraw
		if (amountShares >= totalSupply()) {
			_burn(msg.sender, amountShares); 
		}
	}	

	function harvest() external {
		shortStrategy.harvest(); 
	}

	function storeCrTokens(address user, uint amount) external {
		require(msg.sender == address(shortStrategy), "no"); 
		_mint(user, amount); 
	}	


}
