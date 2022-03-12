<template>
	<v-container>
		<v-row>
			<v-col 	
				justify="center"
				align="center"
			>
				<v-card
					class="defaultCard" 
					color="#DBE7E4"
					flat
				>
					<h3> Coming Soon </h3>
					<br>
					<p class="subtext"> Dai strategy by Coasey </p>

				</v-card> 
			</v-col>

			<v-col
				justify="center"
				align="center"
			>
				<v-card 
					class="defaultCard" 
					color="#DBE7E4"
					flat
				>
					<h3> FTM/TOMB Yield Bottle </h3>
					<v-row>
						<v-col>
					<div class="depositCoin">
						<span class="subtext"> Deposit USDC </span>
						<div class="coinImage">
							<v-img src="../assets/usdc.svg"
								width=50px
								height=50px
							> </v-img>
						</div>
					</div>
				</v-col>
				<v-col>
					<div class="depositCoin">
						<span class="subtext"> Receive USDC </span>
						<div class="coinImage">
							<v-img src="../assets/usdc.svg"
								width=50px
								height=50px
							> </v-img>
						</div>
					</div>	
				</v-col>
			</v-row>
					<v-row>
						<v-col>
							<span class="subtext"> APY: {{ getAPY.yearlyAPY }}% </span>
						</v-col>
						<v-col>
							<span class="subtext"> Daily: {{ getAPY.dailyAPR }}% </span> 	
						</v-col>
					</v-row>
					<v-row>
						<v-col> 
							<span class="subtext"> Pool: {{ (underlyingRewardAmount / 1e18).toFixed(2).toString() }} LP </span>
						</v-col>
					</v-row>

					<div class="defaultInput">
						<v-text-field
							v-model="value"
							class="defaultInupt"
							label="Amount"
							placeholder="Enter Amount To Deposit"
							filled
							rounded
							dense
						>
						</v-text-field>	
					</div>

				<v-row>
					<v-col>
						<div>
							<span class="subtext"> TVL: ${{ (TVL / 1e18).toFixed(2).toString() }} </span> 
						</div>
					</v-col>
				</v-row>
				
					<v-row>
						<v-col>
							<span class="subtext"> Amount Available: {{ (usdcBalance / 1e6).toFixed(2).toString() }} USDC </span> 
					</v-col>
					<v-col>
						<span class="subtext"> Your Shares: {{ (shareBalance  / 1e8).toFixed(2).toString() }} dUSDC </span> 
					</v-col>
				</v-row>
				
				<div class="buttonWrapper">
					<v-row v-if="hasAllowance">
						<v-col
							justify="center"
							align="center"
						>

							<v-btn @click.prevent="onDeposit"
								rounded
								depressed
								class="defaultButton" 
								color="#EDDCD2"
							>
								Deposit
							</v-btn>
						</v-col>

						<v-col 
							justify="center"
							align="center"
						>
							<v-btn @click.prevent="onWithdraw"
								rounded
								depressed
								class="defaultButton" 
								color="#EDDCD2"
							>
								Withdraw
							</v-btn>
						</v-col>
					</v-row>
						
					<v-row v-else>
						<v-col>
							<v-btn @click.prevent="onApproveVault"
								rounded
								depressed
								class="defaultButton"
								color="#EDDCD2"
							>
								Approve
							</v-btn>
						</v-col>
					</v-row>
				</div>

				</v-card>
			</v-col> 

			<v-col 
				justify="center"
				align="center"
			>
				<v-card 
					class="defaultCard"
					color="#DBE7E4"
					flat
				>
					<h3> Coming Soon </h3>
				</v-card> 
			</v-col>
		</v-row>	
	</v-container>
</template>

<script>
import { mapGetters } from 'vuex'; 
import axios from 'axios'; 
import Web3 from 'web3' 
const web3 = new Web3;

const maxApprove = new web3.utils.BN('2').pow(new web3.utils.BN('256')).sub(new web3.utils.BN('1')).toString(); 

export default {
	name: 'Table', 
	computed: {
		...mapGetters('drizzle', ['drizzleInstance']),
		...mapGetters('contracts',['getContractData', 'contractInstances']),
		...mapGetters('accounts', ['activeAccount']),
		
		vault() {
			return this.drizzleInstance.contracts['DjinnBottleUSDC'].address; 
		},

		user() {
			return this.activeAccount; 
		},

		allowanceVault() {
			return this.call('Usdc', 'allowance', [this.user, this.vault]); //returns BN object 
		},

		hasAllowance() {
			if (this.allowanceVault.words[0] > 0) {
				return true;
			}
			return false; 
		},

		lpPrice() {
		
		let lpSupply = this.call('UniswapV2Pair', 'totalSupply', []); 
		let ftmTombLp = this.drizzleInstance.contracts['UniswapV2Pair'].address; 
		let underlyingTokenAmountTomb = this.call('Tomb', 'balanceOf', [ftmTombLp]); 
		let underlyingTokenAmountFtm = this.call('WrappedFtm', 'balanceOf', [ftmTombLp]);

		let lpTombPrice =  underlyingTokenAmountTomb * this.tombPrice; 
		let lpFtmPrice = underlyingTokenAmountFtm * this.ftmPrice; 
		let lpTVL = lpTombPrice + lpFtmPrice; 
		let lpPrice = lpTVL / lpSupply; 
		return lpPrice; 

		},

		TVL() {
			return this.lpPrice * this.underlyingRewardAmount; 
		},

		underlyingRewardAmount() {
			return this.call('DeltaNeutralFtmTomb', 'totalSupply', []); 
		},

		getAPY() {
			let tSharePerSecond = this.call('TShareRewardPool', 'tSharePerSecond', []) / 1e18; 
			let tSharePerSecondAdjusted = (tSharePerSecond * 35500) / 59500; 
			let tSharePerHour = (tSharePerSecondAdjusted * 60) * 60; 
			let dailyAmount  = tSharePerHour * 24; 
			let tSharePerYear= dailyAmount * 365; 
			
			//get LP price 
			let tSharePoolAddress = this.drizzleInstance.contracts['TShareRewardPool'].address; 
			let totalInPool = this.call('UniswapV2Pair', 'balanceOf', [tSharePoolAddress]) / 1e18; 
			let totalLPUSD = totalInPool * this.lpPrice; 

			let dailyReward = dailyAmount * this.tsharePrice; //USD
			let dailyAPR = (dailyReward / totalLPUSD) * 100; //USD
			let yearAPR = ((tSharePerYear * this.tsharePrice) / totalLPUSD); 

			let apy = (Math.pow( 1 + (yearAPR / 17520), 17520) - 1) * 100;  


			return {	
				dailyAPR: dailyAPR.toFixed(2).toString(), 
				yearlyAPY:  apy.toFixed(2).toString()
			}
			

		},

		shareBalance() {
			return this.getContractData ({
				contract: "DjinnBottleUSDC",
				method: "balanceOf", 
				methodArgs: this.user
			});
		},

		usdcBalance() {
			return this.getContractData ({
				contract: "Usdc",
				method: "balanceOf",
			}); 
		},
	},
	methods: {
		onApproveVault() {
			this.drizzleInstance.contracts['Usdc'].methods['approve'].cacheSend(this.vault, maxApprove, {from: this.user});
		},

		onDeposit() {
			this.drizzleInstance.contracts['DjinnBottleUSDC'].methods['deposit'].cacheSend(this.value * 1e6); 
		}, 

		onWithdraw() {
			this.drizzleInstance.contracts['DjinnBottleUSDC'].methods['withdraw'].cacheSend(this.value * 1e8); 
		},

		loadTVL() {
			this.drizzlIenstance.contracts['DjinnBottleUSDC'].methods['balance'].cacheCall(); 
		},
		
		//thank you banteg 
		call(contract, method, args, out='number') {
			let key = this.drizzleInstance.contracts[contract].methods[method].cacheCall(...args)
			let value
			try {
			value = this.contractInstances[contract][method][key].value 
			} catch (error) {
				value = null
			}
			switch (out) {
				case 'number':
					if (value === null) value = 0
					return new web3.utils.BN(value); 
				case 'address':
					return value
				default:
					return value
			}
		}	
	},
	data() {
		return {
			value: '', 
			allowance: false, 
			ftmPrice: 0,
			tombPrice: 0,
			tsharePrice: 0,
		}
	}, 

	created() {
		this.$store.dispatch('drizzle/REGISTER_CONTRACT', {
			contractName: "DjinnBottleUSDC",
			method: "balanceOf",
			methodArgs: [this.activeAccount]
		}); 

		this.$store.dispatch('drizzle/REGISTER_CONTRACT', {
			contractName: "Usdc",
			method: "balanceOf",
			methodArgs: [this.activeAccount]
		}); 
			
		axios.get("https://api.coingecko.com/api/v3/simple/price?ids=fantom&vs_currencies=USD").then((res) => {
			this.ftmPrice = res.data.fantom.usd; 
		});

		axios.get("https://api.coingecko.com/api/v3/simple/price?ids=tomb-shares&vs_currencies=USD").then((resp) => {
			this.tsharePrice = resp.data['tomb-shares'].usd; 
		}); 	

		axios.get("https://api.coingecko.com/api/v3/simple/price?ids=tomb&vs_currencies=usd").then((response) => {
			this.tombPrice = response.data.tomb.usd; 
		}); 
	}

}
</script>

<style>

.defaultButton {
    color: #000009 !important;
    text-transform: none !important;
    text-decoration: none !important;
    letter-spacing: 0.01em !important;
	font-size: 0.75REM !important;
	font-family: 'Press Start 2p', sans-serif; 
 }

 .defaultCard {
	padding-top: 15px; 
	padding-bottom: 15px; 
	border-radius: 25px !important; 
 }

 .defaultInput {
	font-size: 0.75rem !important;
	padding: 10px; 
}

.subtext {
	padding: 10px;  
	font-size: 0.75rem !important;
}

.depositCoin {
	padding: 10px; 
}

.buttonWrapper {
	padding: 20px; 
}

.v-text-field {
	padding-bottom: 0px !important; 
	padding-top: 10px !important;  
}

.coinImage {
	padding-top: 10px; 
}

</style> 
