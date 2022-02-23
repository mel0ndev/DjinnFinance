<template>
	<v-container
		class="topPadding"
	>
		<v-row>
			<v-col
				justify="center"
				align="center"
			>
			<div class="welcomeWrapper">
				<v-card 	
					color="#F0EFEB" 
					flat
					class="welcomeWrapper"
				>
					<h1>
						Welcome to Djinn 
					</h1>
					<h3> Magic Price-Agnostic Yield Generation Bottles </h3> 
				</v-card> 
			</div>
			</v-col>
		</v-row>

		<v-row>
			<Table /> 
			<v-dialog class="dialog" v-model="dialogLoad" width="75%"> 
				<Alert /> 
			</v-dialog> 
		</v-row>
	</v-container>
</template> 


<script>
import Table from "./Table.vue"; 
import Alert from "./Alert.vue"; 

export default {
	name: 'Main', 
	components: {
		Table,
		Alert
	}, 

	data() {
		return {
			dialogLoad: false, 
		}
	}, 
	created() {
		this.dialogLoad = true; 
	}


}
</script> 

<style>

.topPadding {
	padding-top: 25px; 
}

.welcomeWrapper {
	padding-top: 25px; 
	padding-bottom: 25px; 
}

</style>
