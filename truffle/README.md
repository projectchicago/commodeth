# BlockSpaceToken

## Prerequisites

* [Truffle](https://github.com/trufflesuite/truffle)
	
		npm install truffle -g

* [Ganache CLI](https://github.com/trufflesuite/ganache-cli) (optional)

		npm install -g ganache-cli
	
## How to Run Tests

1. Start ganache-cli client or truffle's test client

		ganache-cli -p 9545
		OR 
		truffle develop

2. Deploy contracts with the following command:

		truffle migrate --network development

3. Run the following commands

		truffle test