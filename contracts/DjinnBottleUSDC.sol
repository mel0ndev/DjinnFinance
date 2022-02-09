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

	address private admin; 	
	address public controller; //the contract that will be in charge of depositing gas fees into strategies and autoharvesting  
	ShortFarmFTM public shortStrategy; 

	constructor( address _usdc, address _controller) ERC20("Djinn Finance USDC Vault","dfUSDC") {
		admin = msg.sender; 
		usdc = IERC20(_usdc); 
		controller = _controller; 
	}
	
	//set strategy address 
	function initialize(ShortFarmFTM _shortStrategy) external {
		require(msg.sender == admin, "!admin"); 
		shortStrategy = _shortStrategy; 
	}

	function balance() public returns(uint) {
		return usdc.balanceOf(address(this)) + shortStrategy.getUnderlying(); 
	}

	function testMint(uint shares) public {
		usdc.transferFrom(msg.sender, address(this), shares);
		_mint(msg.sender, shares); 
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

	function callHarvest() external {
		require(msg.sender == controller, "only the autoharvester contract can call this"); 
		shortStrategy.harvest(); 
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


