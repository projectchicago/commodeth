pragma solidity ^0.4.23;

contract Mock{

	uint public counter;

	// 0xd09...de08a
	function increment() external payable{
		counter = counter + 1;
	}
}