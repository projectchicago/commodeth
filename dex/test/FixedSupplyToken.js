var FixedSupplyToken = artifacts.require("FixedSupplyToken.sol");

contract('FixedSupplyToken', function(accounts) {
  it("should be deployed", function() {
    return FixedSupplyToken.deployed().then(function(instance) {
        assert(true);
    });
  });
});
