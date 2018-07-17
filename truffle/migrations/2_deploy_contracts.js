var DexLib = artifacts.require("./DexLib");
var ERC20Token = artifacts.require("./ERC20Token");
var BlockSpaceToken = artifacts.require("./BlockSpaceToken");
var ProtocolGasFutures = artifacts.require("./ProtocolGasFutures");
var ProtocolGasFuturesToken = artifacts.require("./ProtocolGasFuturesToken");
var Dex = artifacts.require("./Dex");

var Mock = artifacts.require("./Mock");

module.exports = function(deployer, network, accounts) {
  if(network === "development"){
    deployer.deploy([
      [ BlockSpaceToken ],
      [ ProtocolGasFuturesToken ],
      [ ERC20Token ],
      [ Mock ]
    ]).then( () => {
      return deployer.deploy(ProtocolGasFutures, ProtocolGasFuturesToken.address);
    }).then( () => {
      return deployer.deploy(DexLib);
    }).then( () => {
      deployer.link(DexLib, Dex);
      var admin = accounts[0];
      var period = 10;
      return deployer.deploy(Dex, admin, period, { gas: "8000000" });
    });
  }
};
