pragma solidity ^0.8.10;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 



contract DjinnHelpers {
	

	address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 


    function swap(address tokenIn, address tokenOut, uint amount) external {
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
