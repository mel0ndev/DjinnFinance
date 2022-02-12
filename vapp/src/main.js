import Vue from 'vue'
import App from './App.vue'
import Vuex from 'vuex'
import drizzleVuePlugin from '@drizzle/vue-plugin'
import drizzleOptions from './drizzleOptions'
import vuetify from './plugins/vuetify'
import router from './router'





Vue.use(Vuex)
const store = new Vuex.Store({ state: {} })

Vue.use(drizzleVuePlugin, { store, drizzleOptions })

Vue.config.productionTip = false

new Vue({
  store,
  vuetify,
  router,
  render: h => h(App)
}).$mount('#app')
