// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.10; 

import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 
import "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 

//The deposit contract for Djinn Finance
contract DjinnBottle is ERC20 {

	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75;  	 
	uint public globalRewards; 
	mapping(address => uint) private lastHarvest; 
	IERC20 public usdc; 

	address private admin; 

	constructor(address admin, address _usdc) ERC20("Djinn Finance USDC Vault","djUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
	}

	function deposit(uint amount) public {
		usdc.approve(address(this), amount);
		usdc.transferFrom(msg.sender, address(this), amount); 		
		//mint tokens 1:1 to usdc to keep it simple 
		_mint(msg.sender, amount); 
	}

	function withdraw(uint amount) public {
		require(amount <= IERC20(address(this)).balanceOf(msg.sender), "no"); 	
		//send back user their usdc 
		usdc.transfer(msg.sender, amount); 
	}

	function claim() external {
		harvest(msg.sender); 
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


