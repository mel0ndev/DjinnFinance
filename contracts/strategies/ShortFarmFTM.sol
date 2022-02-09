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
	DjinnBottleUSDC public VAULT; 

	mapping(address => uint) public depositBalance;
	uint public ass; 
	uint public balls; 
	//Cream Finance Contracts 
	address public constant crUSDC = 0x328A7b4d538A2b3942653a9983fdA3C12c571141; 

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
	CERC20 public immutable crWFTM; 	
	


	constructor(DjinnBottleUSDC _djBottle, 	
				IUniswapV2Router02 _spookyRouter, 
				ComptrollerInterface _comptroller, 
				IStdReference _priceOracle,
				CERC20 _cERC20) ERC20("Djinn Finance FTM Short Farm", "dfFTMShort") {
					address creator = msg.sender;
					VAULT = _djBottle; 
					spookyRouter = _spookyRouter; 
					comptroller = _comptroller;  
					priceOracle = _priceOracle; 
					crWFTM = _cERC20; 
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
		require(msg.sender == address(VAULT), "vault"); 
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
	}
	
	//next we borrow WTFM from cream <= 75% so we don't get liquidated
	//cream allows for 75% collateral on deposits of USDC, but this 75% is on the 75% 
	//so we are effectively borrowing ~55% of our deposit amount, which leaves room to the upside  		
	function borrow(address user, uint amount) internal {
		//store user balance for withdraw later 
		depositBalance[user] = amount; 

		//first we supply USDC
		IERC20(USDC).approve(crUSDC, amount);  
		CERC20(crUSDC).mint(amount); 
		
		//we enter the marker to use usdc as collateral 	
		address[] memory cTokenSupplied = new address[](1); 
		cTokenSupplied[0] = crUSDC; //cToken address
		comptroller.enterMarkets(cTokenSupplied); 
		
		//get max borrow && borrow  
		( ,uint borrowAmount, ) = getBorrowAmount();
		crWFTM.borrow(borrowAmount);  
		
	}

	function getBorrowAmount() public view returns(uint liquidity, uint borrowAmount, uint price) {
		(, liquidity,) = comptroller.getAccountLiquidity(address(this)); 
		IStdReference.ReferenceData memory data = priceOracle.getReferenceData("FTM", "USDC"); 
		price = data.rate; 
		uint maxTokenBorrow = (liquidity * 10**18) / price; //wFTM has 18 decimals   	
		borrowAmount = (maxTokenBorrow * 75) / 100; //this is token amount  
		return (liquidity, borrowAmount, price); 
	}

	function vaultBalance() public returns(uint) {
		uint vault = IERC20(USDC).balanceOf(address(VAULT)); 
		uint underlying = getUnderlying(); 
		uint total = vault + underlying; 
		return total; 
	}

	//where amount is the percentage of LP tokens relative to the users USDC amount in vault 
	function swapAndWithdraw(address user, uint amountShares) internal {
		uint strategyBalance = IERC20(address(this)).balanceOf(address(this)); 
		uint pool = vaultBalance();  
		uint percentLP = (strategyBalance * pool) / amountShares; //percentLP is WAD scaled now  	
		
		//handle rounding error case on big withdraw 
		if (percentLP > strategyBalance) {
			percentLP = strategyBalance; 
		}

		//we first withdraw the LP tokens from TOMB  
		//we have to check the balances before and after the withdrawl in case there are leftovers 
		uint amountBefore = IERC20(spookyFtmTombLP).balanceOf(address(this)); 
		IMasterChef(tShareRewardPool).withdraw(0, percentLP);  
		uint amountAfter = IERC20(spookyFtmTombLP).balanceOf(address(this)); 
		uint lpTokenAmount = amountAfter - amountBefore; 


		depositBalance[user] = amountShares; 	
		removeLiq(user, lpTokenAmount); 
	}

	function getAss() external view returns(uint) {
		return ass; 
	}

	function removeLiq(address user, uint lpTokenAmount) internal {		 
		//we remove liquidity belonging to the user(amount) back for tomb + wftm 
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
		//next step	
		swapBack(user, amountWftm, amountTomb); 
	}

	function getUnderlying() public returns(uint) {
		return CERC20(crUSDC).balanceOfUnderlying(address(this)); //this returns the underlying USDC amount in 6 decimals 
	}
	
	function borrowBalance() public returns(uint) {
		return crWFTM.borrowBalanceCurrent(address(this)); 
	}

	function swapBack(address user, uint amountWftm, uint amountTomb) internal {
		//now we swap tomb back for wftm
		//only need to approve TOMB because wftm is not being swapped 
		IERC20(TOMB).approve(spookyAddress, amountTomb); 
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

		IStdReference.ReferenceData memory data = priceOracle.getReferenceData("FTM", "USDC"); 		
		uint amountToRepay = amountWftm + amounts[0]; //amount from removing liq + amount from swap in token 
		uint holding = IERC20(WFTM).balanceOf(address(this)); 

		if (amountToRepay >= holding) {
			amountToRepay = holding; 
		}	

		uint dollarAmount = (amountToRepay / 1e18) * (data.rate / 1e18) * 1e6; //token price in USDC for amount of wftm   
		uint diff  = depositBalance[user] - dollarAmount; //share amount - LP token amount = diff  
		
		//deposit balance is share amount  
		uint initial = diff + dollarAmount;  
		uint fee = (initial * CREATOR_FEE) / 10000;
		uint redeemAmount = initial - fee; 


		//now we can repay our users borrow
	   	//need to convert wftm token amount to dollar amount 
		IERC20(WFTM).approve(address(crWFTM), amountToRepay); //this is wftm token amount  
		crWFTM.repayBorrow(amountToRepay); 

		//creamUSDC balance redeem
		uint beforeBalance = IERC20(USDC).balanceOf(address(this)); 
		if (redeemAmount >= getUnderlying()) {
			redeemAmount = getUnderlying();
		}
	
		//have to cheat a bit due to all the dust if one person is in farm, they won't be able to withdraw unless we
		//charge the fee here to allow them to get out with a small fee  	
		CERC20(crUSDC).redeemUnderlying(redeemAmount); 
		
		//get usdc balance after redeem 
		uint afterBalance = IERC20(USDC).balanceOf(address(this));
		uint sendAmount	= afterBalance - beforeBalance; //check for difference to send correct amount 
		
		IERC20(USDC).transfer(address(VAULT), sendAmount);  
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
		(uint tombBefore, uint wftmBefore) = getIERC20Balance(); 

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
		
		(uint tombAfter, uint wftmAfter) = getIERC20Balance(); 	
		uint tombToSend = tombAfter - tombBefore; 
		uint wftmToSend = wftmAfter - wftmBefore; 
		
		//charge the fees here
		uint feeAmountTomb = chargeFeesOnHarvest(tombToSend); 	
		uint feeAmountWftm = chargeFeesOnHarvest(wftmToSend);
		IERC20(TOMB).transfer(address(VAULT), feeAmountTomb); 
		IERC20(WFTM).transfer(address(VAULT), feeAmountWftm); 	
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
		return feeAmount = amount * (CREATOR_FEE / 10000) * 100; //0.1 or 1% 
	}

	function getIERC20Balance() internal view returns(uint amountTomb, uint amountWftm) {
		amountTomb = IERC20(TOMB).balanceOf(address(this)); 
		amountWftm = IERC20(WFTM).balanceOf(address(this)); 
		return (amountTomb, amountWftm); 
	}

	receive() external payable{} 
	
} 
