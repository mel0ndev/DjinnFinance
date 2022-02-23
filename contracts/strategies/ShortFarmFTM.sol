pragma solidity ^0.8.10; 
pragma abicoder v2;  

import "../DjinnBottleUSDC.sol"; 
import "../interfaces/CTokenInterfaces.sol"; 
import "../interfaces/ComptrollerInterface.sol";  
import "../interfaces/IStdReference.sol"; 
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol"; 
import "../interfaces/IMasterChef.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol"; 


contract ShortFarmFTM is ERC20 {
	
	//Contract Specifics 
	address public creator; 
	uint private constant CREATOR_FEE = 100; //1% 
	address public treasuryWallet;  
	DjinnBottleUSDC public VAULT; 
	
	//Balances For Withdraw 
	mapping(address => uint) public depositBalance;
	mapping(address => uint) public tokenBorrowBalance; 

	//Cream Finance Contracts (on Fantom these are also just the Iron Bank Contracts)
	address public constant crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 
	address public constant crWFTM = 0xd528697008aC67A21818751A5e3c58C8daE54696;  

	//Public Tokens
	address public constant USDC = 0x04068DA6C83AFCFA0e13ba15A6696662335D5B75; 
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
					address creator = msg.sender;
					VAULT = _djBottle; 
					spookyRouter = _spookyRouter; 
					comptroller = _comptroller;  
					priceOracle = _priceOracle; 	
				}
	
	//automate opening a position
	//designed for single user ie. user opens via vault contract 	
	function open(address user, uint amount) external {
		require(msg.sender == address(VAULT), "!vault"); 
		borrow(user, amount); //same amount in USDC to keep track of how many tokens we have supplied 
		swap(); //swap half of bal to TOMB and unwrap the rest to FTM 
		getLPTokens(); //get FTM-TOMB LP tokens 	
		depositLPGetTShare(); //deposit LP tokens on TOMB to earn TSHARE
	}

	//automate the harvest 
	function harvest() external {
		require(msg.sender == address(VAULT), "!vault"); 
		IMasterChef(tShareRewardPool).deposit(0, 0); //0 is poolId and we call a deposit of 0 to allocate the shares to this contract
		sellAndSwap(); //sell tshare for 50% TOMB 50% WFTM 
		getLPTokens(); 
		depositLPGetTShare(); 
	}
	
	//automate the closing of the position
	//designed for single use ie. user closes via vault contract 	
	//so we need to vault contract to determine how many tokens belong to the user from this contract 
	function close(address user, uint amountShares) external {
		require(msg.sender == address(VAULT), "!vault"); 
		//swap all LP tokens back to underlying 
		swapAndWithdraw(user, amountShares);
		rebalance(); 
	}

	//this function can be called by anyone if they notice that the vault needs to be rebalanced to avoid being liquidated 
	function rebalance() public {
		(uint tenPercent, uint underlyingAmountInToken, uint borrowBalance) = rebalanceParams(); 
		//get how much we have deposited by getting the underyling
		//check that current borrow balance does not exceed 85% of underlying (usd) amount
		if (borrowBalance > (underlyingAmountInToken * 85) / 100) {
			IERC20(WFTM).approve(crWFTM, tenPercent);  
			CERC20(crWFTM).repayBorrow(tenPercent); 
		} else if (borrowBalance < (underlyingAmountInToken * 70) / 100) { 
			CERC20(crWFTM).borrow(tenPercent); 
		}
		//do nothing if not above or below the range 
	}

	function rebalanceParams() internal returns(uint tenPercent, uint maxBorrow, uint borrowBalance) {	
		IStdReference.ReferenceData memory data = priceOracle.getReferenceData("FTM", "USDC"); //returns struct 
		uint price = data.rate; 
		uint underlyingAmountInToken = ((getUnderlying() * 1e18) / price) * 1e12; //returns 1e18 

		tenPercent = (underlyingAmountInToken * 10) / 100;
		maxBorrow = (underlyingAmountInToken * 75) / 100; 
		borrowBalance = CERC20(crWFTM).borrowBalanceCurrent(address(this)); 
		
		return (tenPercent, maxBorrow, borrowBalance); 
	}
	
	//next we borrow WTFM from cream <= 75% so we don't get liquidated
	//cream allows for 75% collateral on deposits of USDC, but this 75% is on the 75% 
	//so we are effectively borrowing ~55% of our deposit amount, which leaves room for price appreciation  		
	function borrow(address user, uint amount) internal {
		//first check for any leftovers in the contract
		uint cTokensBefore = CERC20(crUSDC).balanceOf(address(this)); 

		//supply USDC
		IERC20(USDC).approve(crUSDC, amount);  
		CERC20(crUSDC).mint(amount); 

		//recheck cToken amount and store mint amount as deposit balance for withdraw later 
		uint cTokensAfter = CERC20(crUSDC).balanceOf(address(this)); 
		uint cTokenAmount = cTokensAfter - cTokensBefore; 
		depositBalance[user] += cTokenAmount; 
		VAULT.storeCrTokens(user, cTokenAmount); 
	
		//we enter the marker to use usdc as collateral 	
		address[] memory cTokenSupplied = new address[](1); 
		cTokenSupplied[0] = crUSDC; //cToken address
		comptroller.enterMarkets(cTokenSupplied); 
		
		uint borrowBalanceBefore = borrowBalance(); 	
		//get max borrow && borrow  
		( ,uint borrowAmount, ) = getBorrowAmount();
		CERC20(crWFTM).borrow(borrowAmount);  
		
		//rebalance if needed 
		rebalance(); 

		uint borrowBalanceAfter = borrowBalance(); 
		tokenBorrowBalance[user] += (borrowBalanceAfter - borrowBalanceBefore);   
	}

	function getBorrowAmount() public view returns(uint liquidity, uint borrowAmount, uint price) {
		(, liquidity,) = comptroller.getAccountLiquidity(address(this)); 
		IStdReference.ReferenceData memory data = priceOracle.getReferenceData("FTM", "USDC"); 
		price = data.rate; 

		uint maxTokenBorrow = (liquidity * 10**18) / price; //wFTM has 18 decimals   	
		borrowAmount = (maxTokenBorrow * 75) / 100; //this is token amount  

		return (liquidity, borrowAmount, price); 
	}

	//where amount is the percentage of LP tokens relative to the users USDC amount in vault 
	function swapAndWithdraw(address user, uint amountShares) internal {

		uint strategyBalance = IERC20(address(this)).balanceOf(address(this)); //18 decimals 
		uint totalShares = IERC20(address(VAULT)).totalSupply(); //8 decimals 

		uint amountPerShare = (strategyBalance / totalShares);
		uint percentLP = amountPerShare * amountShares; //returns WAD scaled LP balance

		//handle rounding error case on big withdraw 
		if (percentLP > strategyBalance) {
			percentLP = strategyBalance; 
		}

		//we first withdraw the LP tokens from TOMB  
		///we have to check the balances before and after the withdrawl in case there are leftovers 
		uint amountBefore = IERC20(spookyFtmTombLP).balanceOf(address(this)); 

		IMasterChef(tShareRewardPool).withdraw(0, percentLP);  

		uint amountAfter = IERC20(spookyFtmTombLP).balanceOf(address(this)); 
		uint lpTokenAmount = amountAfter - amountBefore; 

		removeLiq(user, lpTokenAmount, amountShares); 
	}

	function removeLiq(address user, uint lpTokenAmount, uint amountShares) internal {		 
		//we remove liquidity belonging to the user(amount) back for tomb + wftm 
		(uint tombBefore, uint wftmBefore) = getIERC20Balance(); 

		IERC20(spookyFtmTombLP).approve(spookyAddress, lpTokenAmount); 
		(uint amountWftm, uint amountTomb) = IUniswapV2Router02(spookyAddress).removeLiquidity(
			WFTM,
			TOMB, 
			lpTokenAmount,
		   	1,
		   	1,
		   	address(this),
		   	block.timestamp + 30
		); 

		_burn(address(this), lpTokenAmount); 

		(uint tombAfter, uint wftmAfter) = getIERC20Balance(); 
		uint tombToSwap = tombAfter - tombBefore; 
		
		//now we swap tomb back for wftm
		//only need to approve TOMB because wftm is not being swapped 
		IERC20(TOMB).approve(spookyAddress, tombToSwap); 
		address[] memory path = new address[](2); 
		path[0] = TOMB; 
		path[1] = WFTM; 
		uint[] memory amounts = spookyRouter.swapExactTokensForTokens(
			tombToSwap,
			0,
			path,
			address(this),
			block.timestamp + 30
		);
		uint wftmAfterSwap = IERC20(WFTM).balanceOf(address(this));

		//next step	
		swapBack(user, amountShares, wftmAfterSwap); 
	}
	
	function swapBack(address user, uint amountShares, uint wftmAfterSwap) internal {	
		depositBalance[user] -= amountShares; 	

		uint profits; 
		uint amountToRepay;
		if (wftmAfterSwap > tokenBorrowBalance[user]) {
			profits = wftmAfterSwap - tokenBorrowBalance[user]; 
			amountToRepay = tokenBorrowBalance[user]; 
			tokenBorrowBalance[user] = 0; 
		} else {
			profits = 0; 
			amountToRepay = wftmAfterSwap; 
			tokenBorrowBalance[user] -= wftmAfterSwap; 
		}	

		uint fee = (amountShares * CREATOR_FEE) / 1e4; //1%
		uint redeemAmount = amountShares - fee; 

		//case where last user has to withdraw and there are not enough funds to cover  
		if (redeemAmount > CERC20(crUSDC).balanceOf(address(this))) {
			redeemAmount = CERC20(crUSDC).balanceOf(address(this));  
		}
		
		//account for rounding errors if last person in vault wants to withdraw 
		if (amountToRepay > borrowBalance()) {
			amountToRepay = borrowBalance(); 
		}

		//now we can repay our users borrow
		IERC20(WFTM).approve(crWFTM, amountToRepay); //this is wftm token amount  
		CERC20(crWFTM).repayBorrow(amountToRepay); 	

		//redeem initial deposit amount + interest 
		uint usdcBefore = IERC20(USDC).balanceOf(address(this)); 
		CERC20(crUSDC).redeem(redeemAmount); 
		uint usdcAfter = IERC20(USDC).balanceOf(address(this)); 

		uint usdcAmount = usdcAfter - usdcBefore; 

		//one final check for dust 
		if (profits > IERC20(WFTM).balanceOf(address(this))) {
			profits = IERC20(WFTM).balanceOf(address(this)); 
		}

		//final step 
		swapProfits(usdcAmount, profits); 
	}

	//swap wftm for usdc and send back to vault
	function swapProfits(uint redeemedAmount, uint profits) internal {	
		uint totalToSend; 

		if (profits > 0) {
			uint usdcBefore = IERC20(USDC).balanceOf(address(this)); 
			IERC20(WFTM).approve(spookyAddress, profits); 
			address[] memory path = new address[](2); 

			path[0] = WFTM; 
			path[1] = USDC; 
			uint[] memory amounts = spookyRouter.swapExactTokensForTokens(
				profits, 
				0,
				path,
				address(this),
				block.timestamp + 30 
			); 

			uint usdcAfter = IERC20(USDC).balanceOf(address(this)); 
			uint total = usdcAfter - usdcBefore; 
			totalToSend = total + redeemedAmount; 
		} else {

			totalToSend = redeemedAmount; 

		}

		if (totalToSend > IERC20(USDC).balanceOf(address(this))) {
			totalToSend = IERC20(USDC).balanceOf(address(this));  
		}

		IERC20(USDC).transfer(address(VAULT), totalToSend); 
	}

	//then we send the funds to spookyswap where we sell 50% to tomb and then unwrap the rest 
	function swap() internal { 
		//swap 50% to TOMB & approve 
		uint half = IERC20(WFTM).balanceOf(address(this)) * 50 / 100; 
		IERC20(WFTM).approve(spookyAddress, half);
	
 
         address[] memory path = new address[](2);
         path[0] = WFTM;
         path[1] = TOMB;
         IUniswapV2Router02(spookyAddress).swapExactTokensForTokens(
             half,
             0,
             path,
             address(this),
             block.timestamp
		 ); 
	 }

	function sellAndSwap() internal {
		uint tsharesInitial = tshareBalance(); 
		uint harvestFee = chargeFeesOnHarvest(tsharesInitial); 
		IERC20(TSHARE).transfer(treasuryWallet, harvestFee); //goes to vault and will be swapped for gas  

		uint tshares = tshareBalance(); //update amount 
		uint half = (tshares * 50) / 100; 
		IERC20(TSHARE).approve(spookyAddress, tshares); 

		address[] memory pathToTomb = new address[](3); 
		pathToTomb[0] = TSHARE;  
		pathToTomb[1] = WFTM; 
		pathToTomb[2] = TOMB; 
		spookyRouter.swapExactTokensForTokens(
			half,
			0,
			pathToTomb,
			address(this),
			block.timestamp + 30
		); 
	
		//swap rest to WFTM 
		//call again to avoid rounding errors 
		uint rest = tshareBalance();  
	 	address[] memory pathToWftm = new address[](2); 
	 	pathToWftm[0] = TSHARE; 
	 	pathToWftm[1] = WFTM; 
	 	spookyRouter.swapExactTokensForTokens(
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
		IERC20(TOMB).approve(spookyAddress, tombAmount); 
		IERC20(WFTM).approve(spookyAddress, ftmAmount); 
		IUniswapV2Router02(spookyAddress).addLiquidity(TOMB, WFTM, tombAmount, ftmAmount, 1, 1, address(this), block.timestamp + 30); 
	}

	function depositLPGetTShare() internal {
		//deposit into tshare vault using _pid but idk how to get that currently 	
		uint lpTokenBalance = IERC20(spookyFtmTombLP).balanceOf(address(this)); 

		_mint(address(this), lpTokenBalance); 

		//after this deposit the contract should be earning tshares as a reward 
		IERC20(spookyFtmTombLP).approve(tShareRewardPool, lpTokenBalance); 
		IMasterChef(tShareRewardPool).deposit(0, lpTokenBalance); //FTM-TOMB pool ID is 0 on Tomb.finance  
	}

	function chargeFeesOnHarvest(uint amount) internal view returns(uint feeAmount) {
		return feeAmount = (amount * CREATOR_FEE) / 1e4; //0.1 or 1% 
	}

	function getIERC20Balance() internal view returns(uint amountTomb, uint amountWftm) {
		amountTomb = IERC20(TOMB).balanceOf(address(this)); 
		amountWftm = IERC20(WFTM).balanceOf(address(this)); 
		return (amountTomb, amountWftm); 
	}

	function setTreasury(address wallet) external {
		require(msg.sender == address(VAULT), "!vault"); 
		treasuryWallet = wallet; 		
	}

	function getUnderlying() public returns(uint) {
		return CERC20(crUSDC).balanceOfUnderlying(address(this)); //this returns the underlying USDC amount in 6 decimals 
	}

	function borrowBalance() public returns(uint) {
		return CERC20(crWFTM).borrowBalanceCurrent(address(this)); 
	}

	function tshareBalance() public view returns(uint) {
		return IERC20(TSHARE).balanceOf(address(this)); 
	}

	receive() external payable{} 	
} 
