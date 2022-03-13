const path = require('path')
const HDWalletProvider = require('@truffle/hdwallet-provider'); 
const env = require('dotenv').config(); 

const getEnv = env => {
	const value = process.env[env];
		if (typeof value === 'undefined') {
			throw new Error(`${env} has not been set.`);
		}
	return value;
};

const mnemonic = getEnv('FTM_WALLET_MNEMONIC');
const liveNetwork = getEnv('FTM_LIVE_NETWORK');
const liveNetworkId = getEnv('FTM_LIVE_NETWORK_ID');

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
	networks: {
		development: {
			host: "127.0.0.1",
			port: 8545,
			network_id: "*",  //match any network id 
		}, 
		live: {
			provider: () => new HDWalletProvider({
				mnemonic: mnemonic,
				providerOrUrl: liveNetwork, 
				addressIndex: 1
			}), 
			network_id: liveNetworkId 
		}
	},
	compilers: {
		 solc: {
			version: "0.8.10"  // ex:  "0.4.20". (Default: Truffle's installed solc)
		 }
	},

  contracts_build_directory: path.join(__dirname, "vapp/src/contracts"),


};
