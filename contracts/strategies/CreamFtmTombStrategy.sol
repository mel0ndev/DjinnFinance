pragma solidity ^0.8.10; 
pragma abicoder v2;  

import "../DjinnBottleUSDC.sol"; 
import "../interfaces/CTokenInterfaces.sol"; 
import "../interfaces/ComptrollerInterface.sol";  
import "../interfaces/IStdReference.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 
import "../interfaces/IMasterChef.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 


contract DeltaNeutralFtmTomb is ERC20 {
	
	//Contract Spec/if ifics 
	address public creator; 
	uint private constant CREATOR_FEE = 100; //1% 
	address public treasuryWallet;  
	DjinnBottleUSDC public VAULT; 

	//Balances For Withdraw
	mapping(address => uint) public tokenBorrowBalance; //18 decimals  
	
	//Cream Finance Contracts (also just the Iron Bank Contracts)
	address public constant crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 
	address public constant crETH = 0xcc3E89fBc10e155F1164f8c9Cf0703aCDe53f6Fd; 

	//Public Tokens
	address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; 
	address public constant WETH = 0x74b23882a30290451A17c44f4F05243b6b58C76d; 
	address public constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83; 
	address public constant TOMB = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7; 
	address public constant TSHARE = 0x4cdF39285D7Ca8eB3f090fDA0C069ba5F4145B37; 
	
	//SpookySwap Router, LP, TSHAREPool 
	address public constant spookyAddress = 0xF491e7B69E4244ad4002BC14e878a34207E38c29;		
	address public constant spookyFtmTombLP = 0x2A651563C9d3Af67aE0388a5c8F89b867038089e; 
	address public constant tShareRewardPool = 0xcc0a87F7e7c693042a9Cc703661F5060c80ACb43; 


	//Contract Interfaces  
	IUniswapV2Router02 public immutable spookyRouter; 
	ComptrollerInterface public immutable comptroller; 
	IStdReference public immutable priceOracle;
	


	constructor(DjinnBottleUSDC _djBottle, 	
				IUniswapV2Router02 _spookyRouter, 
				ComptrollerInterface _comptroller, 
				IStdReference _priceOracle) ERC20("Djinn FTM Short Farm", "dFTMShort") {
					creator = msg.sender;
					VAULT = _djBottle; 
					spookyRouter = _spookyRouter; 
					comptroller = _comptroller;  
					priceOracle = _priceOracle; 	
				}

	//TODO: swap 50% USDC for 50% FTM to protect against price appreciation 	
	//designed for single user ie. user opens via vault contract 	
	function open(address user, uint amount) external {
		require(msg.sender == address(VAULT), "!vault"); 
		split(user, amount); 
	}

	//automate the harvest 
	function harvest() external {
		require(msg.sender == address(VAULT), "!vault"); 
		IMasterChef(tShareRewardPool).deposit(0, 0); //0 is poolId and we call a deposit of 0 to allocate the shares to this contract
		//sellAndSwap(); //sell tshare for 50% TOMB 50% WFTM 
	//	getLPTokens(); 
		//depositLPGetTShare(); 
	}
	
	//automate the closing of the position
	//designed for single use ie. user closes via vault contract 	
	//so we need to vault contract to determine how many tokens belong to the user from this contract 
	function close(address user, uint amountShares) external {
		require(msg.sender == address(VAULT), "!vault"); 
		//swap all LP tokens back to underlying 
		withdrawLP(user, amountShares);
	}

	////////////////// BEGIN DEPOSIT LOGIC //////////////////  

	function split(address user, uint amount) internal {
		uint swapAmount = (amount * 70) / 100; 
		swap(USDC, WETH, swapAmount); 
		uint usdcAmount = getTokenBalance(USDC);
		uint wethAmount = getTokenBalance(WETH); 

		//next step
		borrow(user, usdcAmount, wethAmount);
	}
	
	//we are borrowing the same amount of deposited ETH to achieve a vault that does not get liquidated	
	function borrow(address user, uint amountUSDC, uint amountWETH) internal {
		//first check for any leftovers in the contract
		uint cTokenUSDCBefore = CERC20(crUSDC).balanceOf(address(this)); 
		uint cTokenETHBefore = CERC20(crETH).balanceOf(address(this)); 

		//supply USDC && WETH
		IERC20(USDC).approve(crUSDC, amountUSDC); 
		CERC20(crUSDC).mint(amountUSDC);

		IERC20(WETH).approve(crETH, amountWETH); 
		CERC20(crETH).mint(amountWETH); 
		
		uint cTokenUSDCAfter = CERC20(crUSDC).balanceOf(address(this)); 
		uint cTokenETHAfter = CERC20(crETH).balanceOf(address(this));  

		uint cTokenUSDCAmount = cTokenUSDCAfter - cTokenUSDCBefore; 
		uint cTokenETHAmount = cTokenETHAfter - cTokenETHBefore; 
		
		//store cTokens user amounts separate due to different interest rates 
		VAULT.storeCrTokens(user, cTokenUSDCAmount, cTokenETHAmount); 
	
		//we enter the markets to use usdc && wftm as collateral 	
		address[] memory cTokenSupplied = new address[](2); 
		cTokenSupplied[0] = crUSDC; //cToken address
		cTokenSupplied[1] = crETH; 
		comptroller.enterMarkets(cTokenSupplied); 
		
		uint borrowBalanceBefore = borrowBalance(); 	
		//get max borrow && borrow  
		( ,uint borrowAmount, ) = getBorrowAmount();
		CERC20(crETH).borrow(borrowAmount);  
		
		uint borrowBalanceAfter = borrowBalance(); 
		tokenBorrowBalance[user] += (borrowBalanceAfter - borrowBalanceBefore);   

		//next step 
		swapForTokens(); 
	}

	function swapForTokens() internal {
		uint half = (getTokenBalance(WETH) * 50) / 100; 
		IERC20(WETH).approve(spookyAddress, getTokenBalance(WETH)); 
		
		//execute the swap here 
		swap(WETH, WFTM, half);  

		uint rest = getTokenBalance(WETH); 
		swap(WETH, TOMB, rest);
		
		//next step 
		getLPTokens(); 
	}

	function getLPTokens() internal {
		//we need to approve the router to spend our TOMB
		uint wftmAmount = getTokenBalance(WFTM); 
		uint tombAmount = getTokenBalance(TOMB); 

		//now we add liquidity 
		//@params token, tokenAmount, minToken, minETH, to, deadline
		IERC20(TOMB).approve(spookyAddress, tombAmount); 
		IERC20(WFTM).approve(spookyAddress, wftmAmount); 
		uint lpTokenBalanceBefore = getTokenBalance(spookyFtmTombLP); 
		spookyRouter.addLiquidity(TOMB, WFTM, tombAmount, wftmAmount, 1, 1, address(this), block.timestamp + 30); 
		uint lpTokenBalanceAfter = getTokenBalance(spookyFtmTombLP); 
		uint lpTokenToMint = lpTokenBalanceAfter - lpTokenBalanceBefore; 
		_mint(address(this), lpTokenToMint); 

		depositLPGetTShare(lpTokenToMint); 
	}
	
	function depositLPGetTShare(uint lpTokenAmount) internal {
		//deposit into tshare vault using _pid but idk how to get that currently 	
		//after this deposit the contract should be earning tshares as a reward 
		IERC20(spookyFtmTombLP).approve(tShareRewardPool, lpTokenAmount); 
		IMasterChef(tShareRewardPool).deposit(0, lpTokenAmount); //FTM-TOMB pool ID is 0 on Tomb.finance  
	}

	////////////////// DEPOSIT LOGIC ENDS  ////////////////// 

	////////////////// BEGIN WITHDRAW LOGIC  ////////////////// 
	
	//the shares are based on the dUSDC in the users wallet 
	function withdrawLP(address user, uint amountShares) internal {
		uint strategyBalance = getTokenBalance(address(this)); //18 decimals 
		uint totalShares = IERC20(address(VAULT)).totalSupply(); //8 decimals 

		uint withdrawAmount = (strategyBalance / totalShares) * amountShares;

		//handle rounding error case on full vault withdrawl 
		if (withdrawAmount > strategyBalance) {
			withdrawAmount = strategyBalance; 
		}

		//we first withdraw the LP tokens from TOMB  
		///we have to check the balances before and after the withdrawl in case there are leftovers 
		uint amountBefore = getTokenBalance(spookyFtmTombLP); 
		IMasterChef(tShareRewardPool).withdraw(0, withdrawAmount);  
		uint amountAfter = getTokenBalance(spookyFtmTombLP); 
		uint lpTokenAmount = amountAfter - amountBefore; 

		removeLiq(user, lpTokenAmount, amountShares); 
	}

	function removeLiq(address user, uint lpTokenAmount, uint amountShares) internal {		 
		//we remove liquidity belonging to the user(amount) back for tomb + wftm 
		uint wftmBefore = getTokenBalance(WFTM); 
		uint tombBefore = getTokenBalance(TOMB); 

		IERC20(spookyFtmTombLP).approve(spookyAddress, lpTokenAmount); 
		spookyRouter.removeLiquidity(
			WFTM,
			TOMB, 
			lpTokenAmount,
		   	1,
		   	1,
		   	address(this),
		   	block.timestamp + 30
		); 

		_burn(address(this), lpTokenAmount); 

		uint wftmAfter = getTokenBalance(WFTM); 
		uint tombAfter = getTokenBalance(TOMB); 

		uint wftmToSwap = wftmAfter - wftmBefore; 
		uint tombToSwap = tombAfter - tombBefore; 
		IERC20(WFTM).approve(spookyAddress, wftmToSwap); 
		IERC20(TOMB).approve(spookyAddress, tombToSwap); 

		uint ethBefore = getTokenBalance(WETH); 
		//execute the swaps 
		swap(WFTM, WETH, wftmToSwap); 
		swap(TOMB, WETH, tombToSwap); 
		uint ethAfter = getTokenBalance(WETH); 
		uint ethAfterSwap = ethAfter - ethBefore; 

		//next step	
		repay(user, amountShares, ethAfterSwap); 
	}
	
	function repay(address user, uint amountShares, uint ethAfterSwap) internal {
		uint profits; 
		uint amountToRepay;
		if (ethAfterSwap > tokenBorrowBalance[user]) {
			profits = ethAfterSwap - tokenBorrowBalance[user]; 
			amountToRepay = tokenBorrowBalance[user]; 
			tokenBorrowBalance[user] = 0; 
		} else {
			profits = 0; 
			amountToRepay = ethAfterSwap; 
			tokenBorrowBalance[user] -= ethAfterSwap; 
		}	
		
		//crToken shares 
		(uint ethShares, uint usdcShares) = splitShares(amountShares);	
		uint ethRedeem = ethShares - (chargeFees(ethShares)); 
		uint usdcRedeem = usdcShares - (chargeFees(usdcShares));
		payCreator(chargeFees(ethShares), chargeFees(usdcShares)); 

		//account for rounding errors if last person in vault wants to withdraw 
		if (amountToRepay > borrowBalance()) {
			amountToRepay = borrowBalance(); 
		}

		//now we can repay our users borrow
		IERC20(WETH).approve(crETH, amountToRepay);
		CERC20(crETH).repayBorrow(amountToRepay); 

		uint ethBefore = getTokenBalance(WETH); 	
		uint usdcBefore = getTokenBalance(USDC); 	
		//redeem initial deposit amount + interest 
		CERC20(crETH).redeem(ethRedeem);
		CERC20(crUSDC).redeem(usdcRedeem); 

		//one final check for dust 
		if (profits > getTokenBalance(WETH)) {
			profits = getTokenBalance(WETH); 
		}

		uint ethAfter = getTokenBalance(WETH); 
		uint usdcAfter = getTokenBalance(USDC); 
		uint ethAmount = (ethAfter - ethBefore) + profits; 
		uint usdcAmount = usdcAfter - usdcBefore;  

		//final step 
		swapProfits(ethAmount, usdcAmount); 
	}

	//swap eth for usdc and send back to vault
	function swapProfits(uint ethAmount, uint usdcAmount) internal {	
		uint usdcBefore = getTokenBalance(USDC); 
		swap(WETH, USDC, ethAmount); 
		uint usdcAfter = getTokenBalance(USDC); 
		uint totalToSend = (usdcAfter - usdcBefore) + usdcAmount; 

		IERC20(USDC).transfer(address(VAULT), totalToSend); 
	}

	////////////////// END WITHDRAW LOGIC ////////////////// 

	////////////////// BEGIN HARVEST LOGIC ////////////////// 
	
	//sells tshares for tomb and wftm tokens 
	function compoundLPTokens() internal {
		uint tsharesInitial = getTokenBalance(TSHARE); 
		uint harvestFee = chargeFees(tsharesInitial); 
		IERC20(TSHARE).transfer(treasuryWallet, harvestFee); //goes to vault and will be swapped for gas  

		uint tshares = getTokenBalance(TSHARE);  //update amount 
		uint half = (tshares * 50) / 100; 
		IERC20(TSHARE).approve(spookyAddress, tshares); 
		//true for 3 route swap 
		swap(TSHARE, TOMB, half); 
	
		//swap rest to WFTM 
		//call again to avoid rounding errors 
		uint rest = getTokenBalance(TSHARE); 
		swap(TSHARE, WFTM, rest); 	
	}

	////////////////// END HARVEST LOGIC ////////////////// 

	////////////////// BEGIN HELPER LOGIC ////////////////// 

	 function swap(address tokenIn, address tokenOut, uint amount) internal {	
		IERC20(tokenIn).approve(spookyAddress, amount); 
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


	  	IUniswapV2Router02(spookyAddress).swapExactTokensForTokens(
   			amount, 
	  		0, //min amount out 
	  		path, 
	  		address(this),
	  		block.timestamp + 30
	 	); 
	}

	//returuns USD value of deposited assets, how much can be borrowed, and the price of the borrowed asset 
	function getBorrowAmount() public view returns(uint liquidity, uint borrowAmount, uint price) {
		(, liquidity,) = comptroller.getAccountLiquidity(address(this)); 
		IStdReference.ReferenceData memory data = priceOracle.getReferenceData("ETH", "USDC"); 
		price = data.rate; 

		uint maxTokenBorrow = (liquidity * 1e18) / price; //ETH has 18 decimals   	
		borrowAmount = (maxTokenBorrow * 94) / 100; //this is token amount  

		return (liquidity, borrowAmount, price); 
	}

	function getShares(uint amountShares) external view returns(uint, uint) {
		(uint one, uint two) = splitShares(amountShares); 
		return (one, two); 
	}
	
	//returns the share per underlying crToken price  
	function splitShares (uint amountShares) internal view returns(uint, uint) {
		uint cTokenEth = CERC20(crETH).balanceOf(address(this)); 
		uint cTokenUsdc = CERC20(crUSDC).balanceOf(address(this)); 
		uint pool = VAULT.totalSupply(); 

		uint ethShares = (cTokenEth * amountShares) / pool; 
		uint usdcShares = (cTokenUsdc * amountShares) / pool; 

		return (ethShares, usdcShares); 
	}

	function payCreator(uint amountEth, uint amountUSDC) internal {
		CERC20(crETH).transfer(creator, amountEth); 
		CERC20(crUSDC).transfer(creator, amountUSDC); 
	}
	
	function chargeFees(uint amount) internal view returns(uint feeAmount) {
		return feeAmount = (amount * CREATOR_FEE) / 1e4; //0.1 or 1% 
	}

	function getTokenBalance(address token) internal view returns(uint amount) {
		return amount = IERC20(token).balanceOf(address(this)); 
	}

	function setTreasury(address wallet) external {
		require(msg.sender == address(VAULT), "!vault"); 
		treasuryWallet = wallet; 		
	}

	function getUnderlying() public returns(uint) {
		return CERC20(crUSDC).balanceOfUnderlying(address(this)); //this returns the underlying USDC amount in 6 decimals 
	}

	function borrowBalance() public returns(uint) {
		return CERC20(crETH).borrowBalanceCurrent(address(this)); 
	}

	receive() external payable{} 	
} 
