const path = require('path')
module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, "vapp/src/contracts"),
 compilers: {
     solc: {
       version: "0.8.10"  // ex:  "0.4.20". (Default: Truffle's installed solc)
     }
  }


};
