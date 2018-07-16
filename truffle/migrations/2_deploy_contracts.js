var DexLib = artifacts.require("./DexLib");

var FixedSupplyToken = artifacts.require("./FixedSupplyToken");
var BlockSpaceToken = artifacts.require("./BlockSpaceToken");
var Dex = artifacts.require("./Dex");

var Mock = artifacts.require("./Mock");

module.exports = function(deployer, network, accounts) {
	if(network === "development"){
		deployer.deploy([
			[ FixedSupplyToken ],
			[ Mock ]
		]).then( () => {
			return deployer.deploy(DexLib);
		}).then( () => {
			deployer.link(DexLib, Dex);
			var admin = accounts[0];
			var period = 10;
			return deployer.deploy(Dex, admin, period);
		});
	}
};
