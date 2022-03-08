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
					<h3> Maximum Yield. Minimal Exposure.</h3> 
				</v-card> 
			</div>
			</v-col>
		</v-row>

		<v-row>
			<Table /> 
		</v-row>
	</v-container>
</template> 


<script>
import Table from "./Table.vue"; 

export default {
	name: 'Main', 
	components: {
		Table,
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
