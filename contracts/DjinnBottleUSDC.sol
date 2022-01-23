// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.10; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import "./strategies/ShortFarmFTM.sol"; 

//The deposit contract for Djinn Finance
contract DjinnBottleUSDC is ERC20 {

	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  	 
	uint public globalRewards; 
	mapping(address => uint) private lastHarvest; 
	IERC20 public usdc;

	address private admin; 	
	ShortFarmFTM public shortStrategy; 

	constructor( address _usdc) ERC20("Djinn Finance USDC Vault","djUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
	}

	function initialize(ShortFarmFTM _shortStrategy) external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy = _shortStrategy; 
	}

	function deposit(uint amount) public {
		usdc.transferFrom(msg.sender, address(this), amount); 		
		//mint tokens 1:1 to usdc to keep it simple 
		_mint(msg.sender, amount); 
		
		//now send funds to strategy	
		usdc.transfer(address(shortStrategy), amount); 
		shortStrategy.open(amount); 
	}
	
	//we get msg.sender's % of pool and then subtract amount to get percent to withdraw
	function withdraw(uint amount) public {
		require(amount <= IERC20(address(this)).balanceOf(msg.sender), "no"); 	
		//calculate how much the user is owed in LP tokens 
		uint newAmount = IERC20(address(this)).balanceOf(msg.sender) - amount; 
		uint percentToWithdraw = newAmount / totalSupply() * 100; 
		//then we pass this to the strategy contract to withdraw the correct % of LP tokens
		shortStrategy.close(percentToWithdraw); 

		//send back user their usdc 
		usdc.transfer(msg.sender, amount); 
	}

	function claim() external {
		checkHarvest(msg.sender); 
	}
	
	//get percentage of profits by balance of this erc20 token in wallet 
	function harvest(address user) internal view returns(uint) {
		uint percentageReward = globalRewards - lastHarvest[user]; 
		
		return IERC20(address(this)).balanceOf(msg.sender) * (percentageReward / usdc.balanceOf(address(this))); 
	}

	function checkHarvest(address user) internal {
		uint owed = harvest(user); 
		if (owed > 0) { 
			_mint(user, owed); 
			lastHarvest[user] = globalRewards; 
		}
	}
	
	//deposits from strategies using this function  
	function depositProfits(uint amount) external {
		require(msg.sender == admin, "no"); 
		usdc.transferFrom(msg.sender, address(this), amount); 
	
		globalRewards += amount; 
	}
}


