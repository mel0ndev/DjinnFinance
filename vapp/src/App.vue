<template>
	<v-app id="main">
		<v-app-bar
			app
			flat
			color="#BCD4E6"
		>
			<v-row
				align="center"
			>
				<v-col>
					<div class="imgWrapper">
					<v-img 
						width=50px
						height=50px
						src="./assets/djinn.png"> </v-img> 
				</div>
				<div class="textWrapper">
					<span class="alphatext"> pre-alpha v0.25 </span>
				</div>
				</v-col>
				<v-col 
					justify="center"
					align="center"	
				>
					<div class="nav">
						<span v-for="routerLink in routerLinks" 
							:key="routerLink.name"
							class="linkName"
						>
							<router-link class="linkName" :to="routerLink.link">
								{{routerLink.text}}
							</router-link>
						</span>
					</div>
				</v-col>
				<v-col>
					<h2 v-if="isDrizzleInitialized" class="account"> Connected, {{ activeAccount.substring(0,4) + `...` + activeAccount.substring(activeAccount.length - 4, activeAccount.length) }} </h2>
					<h2 v-else class="account"> Please Connect to Fantom </h2> 
				</v-col>
			</v-row>
		</v-app-bar>
	
		<v-main v-if="isDrizzleInitialized">
			<v-dialog v-model="showDialog" class="dialogBox"> 
				<Alert />
			</v-dialog> 
			

			<router-view/>

		</v-main>

		<div v-else> 	
			<AltLoad />	
		</div>

	</v-app>
</template>
<script>
import Alert from "./components/Alert.vue"; 
import AltLoad from "./components/AltLoad.vue"; 
import { mapGetters } from 'vuex'; 

export default {
	components: {
		Alert, 
		AltLoad,
	},

	computed: {
		...mapGetters('accounts', ['activeAccount']), 
		...mapGetters('drizzle', ['isDrizzleInitialized', 'drizzleInstance']),	

	}, 

	data() {
		return {
			routerLinks: [
				{name: 'Home', link: '/', text: 'Home'}
			],
			showDialog: false,
		}
	}, 

	created() {
		this.showDialog = true; 
	}	
}

</script>

<style> 
#main {
	background-color: #99c1de;
	font-family: 'Press Start 2p', sans-serif;
}

.account {
	position: absolute; 
	right: 1%; 
	font-size: 0.75rem; 
}

.nav {
	color: #D6E2E9; 
	text-decoration: none; 
}

.linkName {
	color: #FFF1E6 !important; 
	text-decoration: none !important; 
}

.imgWrapper {
	padding-top: 3px; 
	display: inline-block; 
}

.textWrapper {
	display: inline-block;   
}

.alphatext {
	font-size: 0.6REM;  
	opacity: 0.75; 
	padding-left: 10px; 
}


</style>
