pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
//import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "./ProtocolGasFuturesToken.sol";
import "./Dex.sol";

contract ProtocolGasFutures {
  
  using SafeMath for uint;

  ProtocolGasFuturesToken private token;

  mapping (uint => uint) public ids;

  Dex dex;

  event CreatedGasFuture(uint indexed id);
  event AuctionResult(uint id, uint price);

  constructor(ProtocolGasFuturesToken _token) public{
    token = _token;  
  }
  
  function issue(Dex _dex) public returns (uint){

    dex = _dex;

    uint height = block.number;
    uint gasLimit = 1000000;
    uint id = token.issue(height+100, height+1000, gasLimit);

    token.approve(_dex, id);

    _dex.depositNFToken(token.name(), id);

    _dex.askOrderERC721(token.name(), "ETH", id, 0, 1);
  
    ids[height+1000] = id;

    emit CreatedGasFuture(id);

    return id;
  }

  function runAuction(uint _id) public {

    uint price = dex.settleERC721(token.name(), _id);

    emit AuctionResult(_id, price);

  }

  function settle() public returns (bool) {
    uint id = ids[block.number];
    bool executed = token.settle(id);

    return executed;
  }
}