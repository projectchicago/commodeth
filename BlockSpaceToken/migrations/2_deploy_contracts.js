var BlockSpaceToken = artifacts.require("./BlockSpaceToken.sol");

module.exports = function(deployer, network, accounts) {
	if(network === "development"){
  		deployer.deploy(BlockSpaceToken,{
  			from: accounts[0],
  			gas: 3610000
  		});
	}
};
