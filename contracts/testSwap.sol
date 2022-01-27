pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Swap{ 


	address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
	address public constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
	address public constant spookyAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;		
	
	function deposit(uint amount) external {
		IERC20(WFTM).transferFrom(msg.sender, address(this), amount); 
	}

	function swap() external {
		uint balance = IERC20(WFTM).balanceOf(address(this)); 
		IERC20(WFTM).approve(spookyAddress, balance); 

		address[] memory path = new address[](2); 
		path[0] = WFTM; 
		path[1] = TOMB;
		IUniswapV2Router02(spookyAddress).swapExactTokensForTokens(
			balance, 
			0, 
			path, 
			address(this),
			block.timestamp
		); 

	}

}
