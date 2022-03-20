pragma solidity ^0.8.10; 

import "../interfaces/DjinnHelpers.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 

contract DeltaNeutralTombMai {

	//Public Tokens and LPs 
	address public constant tombRouter = 0x6D0176C5ea1e44b08D3dd001b0784cE42F47a3A7; //univ2 fork  
	address public constant spookyRouter = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;	
	address public constant tarotRouter = 0x283e62CFe14b352dB8e30A9575481DCbf589Ad98; 
	address public constant tombMaiLP = 0x45f4682B560d4e3B8FF1F1b3A38FDBe775C7177b; 
	
	//Contract Specifics 
	address private admin; 
	DjinnBottleMAI public constant VAULT; 

	constructor(address admin, DjinnBottleMAI _vault) {
		msg.sender = admin; 
		VAULT = _vault; 
	}

	////////////////// External Interactions //////////////////

	function open() {
		require(msg.sender == address(VAULT), "!vault"); 
		split(); 
	}

	function harvest() {
	
	}

	function close() {
	
	}

	////////////////// Begin Deposit Logic //////////////////
	
	//split half of deposit to other token 
	function split(uint amount) internal {
		//swap 50/50 MAI/TOMB 
		uint swapAmount = (amount * 50) / 100; 

		DjinnHelpers.swap(MAI, TOMB, swapAmount); 

	}

	function getLP() internal {
		//get TombSwapV2 LP on Tomb Swap LP 
	}

	function mint() internal {
		//approve LP and mint collateral using Tarot Router 

	}

	function borrow() internal {
		//use minted Tarot Collateral Tokens to borrow Tomb 
	}

	function short() internal {
		//sell borrowed tomb for 50/50 USDC/MAI && get Spooky LP
	}

	function reinvest() internal {
		//deposit LP back onto Tarot with 10x leverage 
	}

	////////////////// End Deposit Logic //////////////////

	////////////////// Begin Withdraw Logic //////////////////

	function deleverage() internal {
		//deleverage LP and claim LP tokens 
	}

	function remove() internal {
		//remove liquidity from Spooky USDC/MAI
	}

	function repay() internal {
		//rebuy tomb && repay borrow
	}

	function finish() internal {
		//reclaim LP && remove liq && swap back to 100% MAI 
	}	

	////////////////// End Withdraw Logic //////////////////

	////////////////// Begin Helper Logic //////////////////

    function swap(address tokenIn, address tokenOut, uint amount) internal {
       IERC20(tokenIn).approve(spookyRouter, amount);
       address[] memory path;

       if (tokenIn == WFTM || tokenOut == WFTM) {
           path = new address[](2);
           path[0] = tokenIn;
           path[1] = tokenOut;
       } else {
           path = new address[](3);
           path[0] = tokenIn;
           path[1] = WFTM;
           path[2] = tokenOut;
       }


       IUniswapV2Router02(spookyRouter).swapExactTokensForTokens(
           amount,
           0, //min amount out 
           path,
           address(this),
           block.timestamp + 30
       );
   }

	
}
