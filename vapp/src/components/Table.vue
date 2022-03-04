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
					<div class="depositCoin">
						<span class="subtext"> Bottle Your USDC </span>
						<div class="coinImage">
							<v-img src="../assets/usdc.svg"
								width=50px
								height=50px
							> </v-img>
						</div>
					</div>
					<v-row>
						<v-col>
							<span class="subtext"> APY: </span>
						</v-col>
						<v-col>
							<span class="subtext"> Daily: </span> 	
						</v-col>
					</v-row>
					<v-row>
						<v-col> 
							<span class="subtext"> Pool: {{ underlyingRewardAmount / 1e18 }} </span>
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
							<span class="subtext"> TVL: ${{ Number((TVL / 1e6).toFixed(2)) }} </span> 
						</div>
					</v-col>
				</v-row>
				
					<v-row>
						<v-col>
							<span class="subtext"> Amount Available: {{ usdcBalance / 1e6 }} USDC </span> 
					</v-col>
					<v-col>
						<span class="subtext"> Your Shares: {{ shareBalance  / 1e6 }} dUSDC </span> 
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
import Web3 from 'web3' 
import {abi} from "../contracts/DjinnBottleUSDC.json"; 
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

		TVL() {
			return this.loadTVL(); 
		},

		underlyingRewardAmount() {
			return this.call('DeltaNeutralFtmTomb', 'totalSupply', []);
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
				methodArgs: this.user
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
			this.drizzleInstance.contracts['DjinnBottleUSDC'].methods['withdraw'].cacheSend(this.value * 1e6); 
		},

		loadTVL() {
			this.drizzlIenstance.contracts['DjinnBottleUSDC'].methods['balance'].cacheCall(); 
		},

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
