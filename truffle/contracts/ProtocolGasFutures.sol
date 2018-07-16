pragma solidity ^0.4.23;

contract ProtocolGasFutures {
  
  using SafeMath for uint;

  address extraProtocol = 0x0; // Fill with the address of `ProtocolGasFuturesToken.sol`
  ProtocolGasFuturesToken token = ProtocolGasFuturesToken(extraProtocol);

  mapping (uint => uint) public ids;
  
  function issue() public returns (uint)  {
  	uint height = block.number;
  	uint gasLimit = 1000000;
  	uint id = token.issue(height+100, height+1000, gasLimit);

  	ids[height+1000] = id;

  	return id;
  }


  function settle() public returns (bool) {
  	uint id = ids[block.number];
  	bool executed = token.settle(id);

  	return executed;
  }
}