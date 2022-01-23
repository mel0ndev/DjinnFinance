const path = require('path')
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
	networks: {
		development: {
			host: "127.0.0.1",
			port: 8545,
			network_id: "*" //match any network id 
		}
	},
	compilers: {
		 solc: {
			version: "0.8.10"  // ex:  "0.4.20". (Default: Truffle's installed solc)
		 }
	},

  contracts_build_directory: path.join(__dirname, "vapp/src/contracts"),


};
