pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./ProtocolGasFuturesToken.sol";
import "./Dex.sol";

contract ProtocolGasFutures {
  
  using SafeMath for uint;

  ProtocolGasFuturesToken private token;

  mapping (uint => uint[]) public ids;
  uint public numFuturesIssued = 0;

  Dex dex;

  event CreatedGasFuture(uint indexed id);
  event AuctionResult(uint id, uint price);

  constructor(ProtocolGasFuturesToken _token) public {
    token = _token;  
  }

  function () {
      issue(dex);
      //settle();
  }

  function issueToken(uint256 expiry, uint256 gasLimit) internal {
    uint256 id = token.issue(expiry-100, expiry, gasLimit);

    // transfer token to the dex
    token.approve(dex, id);
    dex.depositNFToken(token.name(), id);
    dex.askOrderERC721(token.name(), "ETH", id, 0, 1);
 
    // update internal bookkeeping
    numFuturesIssued++;
    ids[expiry].push(id);
    emit CreatedGasFuture(id);
  }
  
  function issue(Dex _dex) public {
    dex = _dex;

    uint height = block.number;
    uint gasLimit = 350000;

    issueToken(height+5760, gasLimit);
    issueToken(height+40320, gasLimit);
    issueToken(height+175200, gasLimit);
    issueToken(height+2102400, gasLimit);
  }

  function runAuction(uint _id) public {

    uint price = dex.settleERC721(token.name(), _id);

    emit AuctionResult(_id, price);

  }

  function settle() public returns (bool) {
    uint[] ids_to_settle = ids[block.number];
    for (uint i = 0; i < ids_to_settle.length; i++) {
        bool executed = token.settle(ids_to_settle[i]);
        if (!executed)
            return false;
    }

    return true;
  }
}
