pragma solidity ^0.8.10; 
pragma abicoder v2;  

import "../DjinnBottle.sol"; 
import "../interfaces/CTokenInterfaces.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 


contract ShortFarmFTM {


	ufixed8x2 private constant CREATOR_FEE = 1 / 100; 
	DjinnBottle public immutable VAULT; 
	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; 
	address public immutable crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 
	address public immutable crWFTM = 0xd528697008aC67A21818751A5e3c58C8daE54696; 
	address public immutable TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7; 
	address public controller; //the address that's going to be controlling when the vault updates percent borrowed  	

	//get FTM and TOMB addresses

	IUniswapV2Router02 public immutable spookyRouter; 

	uint borrowAmount; 

	constructor(address creator,
				DjinnBottle _djBottle, 	
				IUniswapV2Router02 _spookyRouter) {
					creator = msg.sender;
					spookyRouter = _spookyRouter; 
					VAULT = _djBottle; 
		}
	
	//first we deposit the USDC into the corresponding market on CREAM 
	function deposit(uint amount) external {
		IERC20(USDC).transferFrom(address(VAULT), address(this), amount); 
		IERC20(USDC).approve(crUSDC, amount); 

		//this is the supply function on cream/compound 
		cToken(crUSDC).mint(amount);  
	}

	//next we borrow WTFM from cream <= 70% so we don't get liquidated 
	function borrow(uint amount) external {
		require(amount >= cToken(crUSDC).balanceOf(address(this)) * 70 / 100, "balance too low"); 
		borrowAmount = cToken(crWFTM).borrow(amount); 
	}
	
	//then we send the funds to spookyswap where we sell 50% to tomb and then unwrap the rest 
	function unwrapAndSwap(uint amountOutMin) external { 
		//swap 50% to TOMB
		uint half = cToken(crWFTM).balanceOf(address(this)) * 50 / 100; 
		address[] memory path = new address[](2);
		path[0] = crWFTM; //not sure if this has to be WFTM or the cToken equivalent? 
		path[1] = TOMB; 
		//we swap half of the balance of WFTM for TOMB 
		uint[] memory amountOut = spookyRouter.swapExactTokensForTokens(half, amountOutMin, path, address(this), block.timestamp);

		//quick check for slippage 
		uint[] memory amountsOutSlippage = spookyRouter.getAmountsOut(half, path);	
		require(amountsOutSlippage[0] <= amountOut[0]); 	

		//now we unwrap the rest to FTM but idk how to that on spooky rn 
	}

}
