pragma solidity ^0.8.10; 
pragma abicoder v2;  

import "../DjinnBottle.sol"; 
import "../interfaces/CTokenInterfaces.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 
import "../interfaces/IWFTM.sol";


contract ShortFarmFTM {


	ufixed8x2 private constant CREATOR_FEE = 1 / 100; 
	DjinnBottle public immutable VAULT; 
	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; 
	address public immutable crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 
	address public immutable crWFTM = 0xd528697008aC67A21818751A5e3c58C8daE54696; 
	address public immutable wFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 
	address public immutable TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7; 
	address spookyAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29; 
	address public controller; //the address that's going to be controlling when the vault updates percent borrowed  	
	
	IWFTM private wftm; 
	//get FTM and TOMB addresses

	IUniswapV2Router02 public immutable spookyRouter; 

	uint borrowAmount; 

	constructor(address creator,
				DjinnBottle _djBottle, 	
				IUniswapV2Router02 _spookyRouter, 
				IWFTM _wftm) {
					creator = msg.sender;
					spookyRouter = _spookyRouter; 
					VAULT = _djBottle; 
					wftm = _wftm; 
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
		borrowAmount = cToken(crWFTM).borrow(amount); //returns wFTM to msg.sender  
	}

	function open() external { //make sure to pass msg.value when opening 
		unwrapAndSwap(); //swap half of bal to TOMB and unwrap the rest to FTM 
		getLPTokens(); //get FTM-TOMB LP tokens 	
		//deposit LP tokens somewhere idk where yet 
	}
	
	//then we send the funds to spookyswap where we sell 50% to tomb and then unwrap the rest 
	function swap() internal { 
		//swap 50% to TOMB
		uint half = IERC20(wFTM).balanceOf(address(this)) * 50 / 100; 
		address[] memory path = new address[](2);
		path[0] = wFTM; 
		path[1] = TOMB; 
		//we swap half of the balance of WFTM for TOMB 
		spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			half,
		   	0,
		   	path,
		   	address(this),
		   	block.timestamp + 30
		);

	}

	function getLPTokens() internal {
		//we need to approve the router to spend our TOMB
		uint tombAmount = IERC20(TOMB).balanceOf(address(this)); 
		uint ftmAmount = IERC20(wFTM).balanceOf(address(this));  

		//now we add liquidity 
		//@params token, tokenAmount, minToken, minETH, to, deadline
		//I think we should just be able to reuse the amounts since the router doesn't guarantee a price anyways 
		spookyRouter.addLiquidity(TOMB, wFTM, tombAmount, ftmAmount, 1, 1, address(this), block.timestamp + 30); 
	}

	function getTShares() internal {
		//deposit into tshare vault using _pid but idk how to get that currently 	
	}	

} 
