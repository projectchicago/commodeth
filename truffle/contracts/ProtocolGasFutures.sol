pragma solidity ^0.4.23;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

import "./ProtocolGasFuturesToken.sol";

contract ProtocolGasFutures {
  
  using SafeMath for uint;

  ProtocolGasFuturesToken private token;

  mapping (uint => uint) public ids;

  event CreatedGasFuture(uint indexed id);

  modifier onlyProtocol{
    // FIXME
    //require(msg.sender == address(this));
    _;
  }

  constructor(ProtocolGasFuturesToken _token) public{
    token = _token;  
  }

  function () public payable{
  }
  
  function issue() onlyProtocol public returns (uint)  {
    uint height = block.number;
    uint gasLimit = 1000000;
    uint id = token.issue(height+100, height+1000, gasLimit);

    ids[height+1000] = id;

    emit CreatedGasFuture(id);

    return id;
  }


  function settle() onlyProtocol public returns (bool) {
    uint id = ids[block.number];
    bool executed = token.settle(id);

    return executed;
  }
}