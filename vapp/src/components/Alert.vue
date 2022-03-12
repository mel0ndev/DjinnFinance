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
			
				<h3> Djinn is a HIGHLY experimental vault system. </h3>
				<v-row>
					<v-col justify="center" align="center">
						<span class="par">	
							<p> These contracts have not been audited. Please consider this early iteration to be an MVP and thus highly								likely to be vulernable to loss of funds. It is not the intention of this protocol to lose funds,
							   	but	please, do not deposit assets that you cannot afford to lose. <strong> You will not be refunded.
								</strong>
						   	</p>
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
