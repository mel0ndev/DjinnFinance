pragma solidity ^0.8.10; 
pragma abicoder v2;  

import "../DjinnBottleUSDC.sol"; 
import "../interfaces/CTokenInterfaces.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 
import "../interfaces/IMasterChef.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 


contract ShortFarmFTM {


	ufixed8x2 private constant CREATOR_FEE = 1 / 100; 
	DjinnBottleUSDC public immutable VAULT; 

	//Cream Finance Contracts 
	address public immutable crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 
	address public immutable crWFTM = 0xd528697008aC67A21818751A5e3c58C8daE54696; 

	//Public Tokens
	address public immutable USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; 
	address public immutable WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 
	address public immutable TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7; 
	address public immutable TSHARE = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37; 
	
	//SpookySwap Router and LP 
	address public immutable spookyFtmTombLP = 0x2A651563C9d3Af67aE0388a5c8F89b867038089e; 
	address public immutable spookyAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;		

	//Router Interface && Tomb Share Rewards Pool Interface 
	IUniswapV2Router02 public immutable spookyRouter; 
	IMasterChef public immutable tsharePool; 

	uint borrowAmount; 

	constructor(address creator,
				DjinnBottleUSDC _djBottle, 	
				IUniswapV2Router02 _spookyRouter, 
				IMasterChef _tsharePool) {
					creator = msg.sender;
					spookyRouter = _spookyRouter; 
					VAULT = _djBottle; 
					tsharePool = _tsharePool; 
		}
	
	//automate opening a position
	//designed for single user ie. user opens via vault contract 	
	function open(uint amount) external { //make sure to pass msg.value when opening 
		deposit(amount); 
		borrow(); 
		swap(); //swap half of bal to TOMB and unwrap the rest to FTM 
		getLPTokens(); //get FTM-TOMB LP tokens 	
		depositLPGetTShare(); //deposit LP tokens on TOMB to earn TSHARE
	}

	//automate the harvest 
	function harvest() external {
		require(msg.sender == address(VAULT), "no"); 
		IMasterChef(tsharePool).deposit(0, 0); //0 is poolId and we call a deposit of 0 to allocate the shares to this contract
		//chargeFees(); 
		sellAndSwap(); //sell tshare for 50% TOMB 50% WFTM 
		getLPTokens(); 
		depositLPGetTShare(); 
	}
	
	//automate the closing of the position
	//designed for single use ie. user closes via vault contract 	
	//so we need to vault contract to determine how many tokens belong to the user from this contract 
	function close(uint amount) external {
		require(msg.sender == address(VAULT), "!vault"); 
		//swap all LP tokens back to underlying 
		swapAndWithdraw(amount);  
		//redeemUnderlying(); //to get USDC back 
		//send back to vault to allow for withdraw 
	}
	
	//first we deposit the USDC into the corresponding market on CREAM 
	function deposit(uint amount) internal {
		IERC20(USDC).transferFrom(address(VAULT), address(this), amount); 
		IERC20(USDC).approve(crUSDC, amount); 

		//this is the supply function on cream/compound 
		cToken(crUSDC).mint(amount);  
	}

	//next we borrow WTFM from cream <= 70% so we don't get liquidated
	//cream allows for 75% collateral on deposits of USDC, but this 75% is on the 75% 
	//so we are effectively borrowing ~55% of our deposit amount, which leaves room to the upside  	
	function borrow() internal {
		uint amount = IERC20(crUSDC).balanceOf(address(this)) * 75 / 100; 
		cToken(crWFTM).borrow(amount); //returns WFTM to msg.sender  
	}

	//where amount is the percentage of LP tokens relative to the callers % ownership of the vault 
	function swapAndWithdraw(uint amount) internal {
		uint percentOfLP = amount / 100; //div by 100 to get percentage	
		uint amountToWithdraw = IERC20(spookyFtmTombLP).balanceOf(address(this)) * percentOfLP;  
		//we first withdraw the LP tokens from TOMB  
		IMasterChef(tsharePool).withdraw(0, amountToWithdraw); //where amount is the amount of LP tokens 
		
		//we remove liquidity belonging to the user(amount) back for tomb + wftm 
		(uint amountTomb, uint amountWftm) = spookyRouter.removeLiquidity(
			TOMB, 
			WFTM,
		   	amountToWithdraw,
		   	0,
		   	0,
		   	address(this),
		   	block.timestamp + 30
		); 
		
		//now we swap tomb back for wftm 
		address[] memory path = new address[](2); 
		path[0] = TOMB; 
		path[1] = WFTM; 
		uint[] memory amounts = spookyRouter.swapExactTokensForTokens(
			amountTomb,
			0,
			path,
			address(this),
			block.timestamp + 30
		);

		uint amountToRepay = amounts[0] + amountWftm; 
		//now we can repay our users borrow 
		cToken(crWFTM).repayBorrow(amountToRepay); 
	}
	
	//then we send the funds to spookyswap where we sell 50% to tomb and then unwrap the rest 
	function swap() internal { 
		//swap 50% to TOMB
		uint half = IERC20(WFTM).balanceOf(address(this)) * 50 / 100; 
		address[] memory path = new address[](2);
		path[0] = WFTM; 
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

	function sellAndSwap() internal {
		uint half = IERC20(TSHARE).balanceOf(address(this)) * 50 / 100; 
		address[] memory pathToTomb = new address[](3); 
		pathToTomb[0] = TSHARE;  
		pathToTomb[1] = WFTM; 
		pathToTomb[2] = TOMB; 
		spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			half,
			0,
			pathToTomb,
			address(this),
			block.timestamp + 30
		); 

		//swap rest to WFTM 
		uint rest = IERC20(TSHARE).balanceOf(address(this)); 
		address[] memory pathToWftm = new address[](2); 
		pathToWftm[0] = TSHARE; 
		pathToWftm[1] = WFTM; 
		spookyRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
			rest,
			0,
			pathToWftm,
			address(this),
			block.timestamp + 30
		); 
	}

	function getLPTokens() internal {
		//we need to approve the router to spend our TOMB
		uint tombAmount = IERC20(TOMB).balanceOf(address(this)); 
		uint ftmAmount = IERC20(WFTM).balanceOf(address(this));  

		//now we add liquidity 
		//@params token, tokenAmount, minToken, minETH, to, deadline
		spookyRouter.addLiquidity(TOMB, WFTM, tombAmount, ftmAmount, 1, 1, address(this), block.timestamp + 30); 
	}

	function depositLPGetTShare() internal {
		//deposit into tshare vault using _pid but idk how to get that currently 	
		uint lpTokenBalance = IERC20(spookyFtmTombLP).balanceOf(address(this)); 
		//tomb has 2 pools that give tshare rewards for staked LPs, the TSHARE-FTM and TOMB-FTM, 
		//they are both distributed from the same contract tho, and they don't say which is which anywhere?? cringe. 
		//after this deposit the contract should be earning tshares as a reward 
		IMasterChef(tsharePool).deposit(0, lpTokenBalance); //I think the FTM-TOMB pool ID is 0 tho 
	}	

} 
