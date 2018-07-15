var BlockSpaceToken = artifacts.require("./BlockSpaceToken");
var Mock = artifacts.require("./Mock");

module.exports = function(deployer, network, accounts) {
	if(network === "development"){
		deployer.deploy(Mock);
  		deployer.deploy(BlockSpaceToken,{
  			from: accounts[0],
  			gas: 3610000
  		});
	}
};
