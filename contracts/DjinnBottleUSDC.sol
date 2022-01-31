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

	constructor( address _usdc) ERC20("Djinn Finance USDC Vault","dfUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
	}

	function initialize(ShortFarmFTM _shortStrategy) external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy = _shortStrategy; 
	}
	
	function deposit(uint amount) public {
		usdc.transferFrom(msg.sender, address(this), amount); 		
		//mint shares relative to ownership of vault 
		uint shares; 
		if (totalSupply() == 0) {
		   shares = amount; 
		} else {
		   shares = (amount *  totalSupply()) / totalSupply();  
		}
		_mint(msg.sender, shares); 
		//mint corresponding number of shares that keeps track of how much USDC they have in vault 
		usdc.transfer(address(shortStrategy), amount); 
		shortStrategy.open(msg.sender, amount);  
	}
	
	//we get msg.sender's % of pool and then use that to convert to tokens 
	function withdraw(uint amountShares) public returns(uint) {
		require(amountShares <= IERC20(address(this)).balanceOf(msg.sender), "no"); 
		_burn(msg.sender, amountShares); 	

		//then we pass this to the strategy contract to withdraw the correct % of LP tokens
		uint beforeBal = usdc.balanceOf(address(this)); 
		shortStrategy.close(msg.sender, amountShares); 
		uint afterBal = usdc.balanceOf(address(this));
		//send back user their usdc 
		uint amountToWithdraw = afterBal - beforeBal; 
		usdc.transfer(msg.sender, amountToWithdraw); 
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


