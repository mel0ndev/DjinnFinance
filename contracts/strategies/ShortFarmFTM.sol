pragma solidity ^0.8.10; 

import "CREAM CR TOKENS"; 

contract ShortFarmFTM {


	ufixed8x2 public constant CREATOR_FEE = 1 / 100; 
	public immutable VAULT; 
	IERC20 public immutable usdc; 
	IERC20 public immutable crToken;
	IERC20 public immutable crWFTM; 

	//get FTM and TOMB addresses

	IUniswapV02Router public immutable spookyRouter; 

	uint borrowAmount; 

	constructor(address creator,
			   	address _vault, 
				IERC20 _usdc,
			   	IERC20 _crToken, 
				IERC20 _wftm, 
				IUniswapV02Router _spookyRouter) {
					creator = msg.sender
					usdc = _usdc; 
					crToken = _crToken; 
					crWFTM = _wftm; 
					spookyRouter = _spookyRouter; 
		}
	
	//first we deposit the USDC into the corresponding market on CREAM 
	function deposit(uint amount) external {
		usdc.transferFrom(address(VAULT), address(this), amount); 
		usdc.approve(address(crToken), amount); 

		crToken.mint(amount);  
	}

	//next we borrow WTFM from cream <= 70% so we don't get liquidated 
	function borrow(uint amount) external {
		require(amount >= crToken.balanceOf(address(this)) * 70 / 100, "balance too low"); 
		borrowAmount = crWTFM.borrow(amount); 
	}
	
	//then we send the funds to spookyswap where we sell 50% to tomb and then unwrap the rest 
	function unwrapAndSwap(uint amountOut) external { 
		//swap 50% to TOMB
		uint half = crWFTM.balanceOf(address(this) * 50 / 100; 
		address[] memory path = new address[](2);
		path[0] = crWFTM; 
		path[1] = TOMB; 
		uint amountOut = spookyRouter.swapExactTokensForTokens(amountOutMin, path, address(this), block.timestamp);
		//quick check for slippage 
		uint256[] memory amountOutMins = spookyRouter.getAmountsOut(half, path);	
		require(amountOutMins[path.length - 1] <= amountOut); 	

		//now we unwrap the rest to FTM but idk how to that on spooky rn 
	}

}
