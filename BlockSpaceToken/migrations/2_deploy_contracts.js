var BlockSpaceToken = artifacts.require("./BlockSpaceToken.sol");

module.exports = function(deployer) {
  deployer.deploy(BlockSpaceToken);
};
