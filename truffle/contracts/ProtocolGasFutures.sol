pragma solidity ^0.4.23;

contract ProtocolGasFutures {
  
  using SafeMath for uint;

  address extraProtocol = 0x0; // Fill with the address of `ProtocolGasFuturesToken.sol`
  mapping (uint => uint) public ids;
  
  function mint() public returns (uint)  {
  	uint height = block.number;
  	uint gasLimit = 1000000;
  	ProtocolGasFuturesToken token = ProtocolGasFuturesToken(extraProtocol);
  	uint id = token.mint(height+100, height+1000, gasLimit);

  	ids[height+1000] = id;

  	return id;
  }


  function settle() public returns (bool) {
  	uint id = ids[block.number];

  	ProtocolGasFuturesToken token = ProtocolGasFuturesToken(extraProtocol);
  	bool executed = token.settle(id);

  	return executed;
  }
}