<template>
	<v-app v-if="isDrizzleInitialized" id="main">
		<v-app-bar
			app
			flat
			color="#BCD4E6"
		>
			<v-row
				align="center"
			>
				<v-col>
					<h1> Djinn </h1>
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
					<h2 class="account"> Connected, {{ activeAccount.substring(0,4) + `...` + activeAccount.substring(activeAccount.length - 4, activeAccount.length) }} </h2>
				</v-col>
		</v-row>
		</v-app-bar>
		
		<v-main>
			<router-view/>
		</v-main>
	</v-app>

<div v-else> Please Enable A Web3 Connection </div> 

</template>
<script>
import { mapGetters } from 'vuex'; 

export default {
	computed: {
		...mapGetters('accounts', ['activeAccount']), 
		...mapGetters('drizzle', ['isDrizzleInitialized', 'drizzleInstance']),
	}, 
	data() {
		return {
			routerLinks: [
				{name: 'Home', link: '/', text: 'Home'},
				{name: 'Docs', link: '/docs', text: 'Docs'}
			],
		}
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


</style>
