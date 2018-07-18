var DexLib = artifacts.require("./DexLib");
var ERC20Token = artifacts.require("./ERC20Token");
var BlockSpaceToken = artifacts.require("./BlockSpaceToken");
var ProtocolGasFutures = artifacts.require("./ProtocolGasFutures");
var ProtocolGasFuturesToken = artifacts.require("./ProtocolGasFuturesToken");
var Dex = artifacts.require("./Dex");

var Mock = artifacts.require("./Mock");

var period = 40;

module.exports = function(deployer, network, accounts) {
  if(network === "development"){
    deployer.deploy([
      [ BlockSpaceToken ],
      [ ProtocolGasFuturesToken ],
      [ ERC20Token ],
      [ Mock ]
    ]).then( () => {
      return deployer.deploy([
        [ ProtocolGasFutures, ProtocolGasFuturesToken.address ],
        [ DexLib ]
      ]);
    }).then( () => {
      deployer.link(DexLib, Dex);
      return deployer.deploy(Dex, "0xe035e5542e113f144286847c7b97a1da110df49f", period, { from: accounts[0], gas: "8000000" });
    });
  }else if(network === "geth"){
    deployer.deploy([
      [ ProtocolGasFuturesToken ],
      [ DexLib ]
    ]).then( () => {
      deployer.link(DexLib, Dex);
      return deployer.deploy(Dex, accounts[0], period, { from: accounts[0], gas: "8000000" });
    });
  }
};
