<template>
	<v-card
		flat
		class="main"
		height="100%"
		width="100%"
	>
		<v-row>
			<v-col
				justify="center"
				align="center"
			>
				<h1> ATTENTION! </h1>
			
				<h3> Djinn is a HIGHLY experimental vault system! </h3>
				<v-row>
					<v-col justify="center" align="center">
				<span class="par">	
					<p> Each vault is built with caution and care, but there are only so many tests that one person can do. 
						Please use the protocol responsibly, and do not deposit assets that you cannot afford to lose. There 
						is no guarantee that your funds will be safe. Each vault interacts with numerous other protocols, increasing
						smart contract risk further. Proceed at your own risk. </p>	
				</span>
					</v-col>
				</v-row>
			</v-col>
		</v-row>
	</v-card>	
</template>
<script>

export default {
	name: 'Alert', 
}

</script>

<style scoped>

.par {
	padding: 50px;
	margin-left: 25px; 
	margin-right: 25px; 
}

.main {
	padding: 50px; 
}

</style>
