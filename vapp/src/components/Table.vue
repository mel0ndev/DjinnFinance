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
						<v-img src="../assets/usdc.svg"
							width=50px
							height=50px
						> </v-img>
					</div>
					<span class="subtext"> APY: </span>
					<span class="subtext"> Daily: </span> 	
					<div class="defaultInput">
						<v-text-field
							class="defaultInupt"
							label="Amount"
							placeholder="Enter Amount To Deposit"
							filled
							rounded
							dense
						>
						</v-text-field>	
					</div>
					
					<div>
						<span class="subtext"> TVL: </span> 
					</div>

					<div>
						<span class="subtext"> Amount Available: </span> 
						<span class="subtext"> Your Shares: </span> 
					</div>
					
					<div class="buttonWrapper">
						<v-btn
							rounded
							depressed
							class="defaultButton" 
						>
							Deposit
						</v-btn>
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
export default {
	name: 'Table', 

	data() {
		return {

		}
	}

}
</script>

<style>

.defaultButton {
    color: #000009 !important;
    background-image: linear-gradient(to right, #FAD2E1 0%, #C5DEDD  100%);
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
}

</style> 
