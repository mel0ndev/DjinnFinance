<template>
<div v-if="isDrizzleInitialized" id="app">
	<b-navbar> 

	</b-navbar> 
	<div class="section">
		<h1> Djinn Finance </h1> 
	</div>
	
	<div> 
		<h3> Magic Bottles That Release Juicy Yields </h3> 
	</div>	

 </div>

<div v-else>Loading...</div>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'app',

  computed: mapGetters('drizzle', ['isDrizzleInitialized'])
}
</script>

<style>
#app {
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #fff;;
  background-color: #191919; 
}


</style>
