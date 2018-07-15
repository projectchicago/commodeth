var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

module.exports = function(deployer, network, accounts) {
    if(network === "development"){
        deployer.deploy(FixedSupplyToken);
    }
};
