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

	uint private constant PROTOCOL_FEE = 100; 

	uint public ass; 

	address private admin; //admin contract will be responsible for autoharvesting the vault 
	ShortFarmFTM public shortStrategy; 

	constructor( address _usdc) ERC20("Djinn Finance USDC Vault","dfUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
	}
	
	//set strategy address 
	function initialize(ShortFarmFTM _shortStrategy) external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy = _shortStrategy; 
	}

	function balance() public returns(uint) {
		return usdc.balanceOf(address(this)) + shortStrategy.getUnderlying(); 
	}
	
	function deposit(uint amount) public {
		usdc.transferFrom(msg.sender, address(this), amount); 		

		uint feeAmount = (amount * PROTOCOL_FEE) / 1e4;  //1% deposit fee 
		uint newAmount = amount - feeAmount; 

		//mint shares == deposit amount (maybe composability later?)  
		_mint(msg.sender, newAmount);

		//send to strategy contract 
		usdc.transfer(address(shortStrategy), newAmount); 
		shortStrategy.open(msg.sender, newAmount);  
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

	function harvest() external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy.harvest(); 
	}

}
