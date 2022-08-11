## Foundry + Solmate NFT Tutorial

Steps to setup the project

1. Install foundry as per the steps mentioned [here](https://github.com/foundry-rs/foundry#installation)

2. Setup a foundry project

```shell
forge init foundry-nft && cd foundry-nft
```

3. Install project dependencies

```shell
forge install transmissions11/solmate Openzeppelin/openzeppelin-contracts
```

4. Declare the remappings

```shell
forge remappings > remappings.txt
```

## Commands

To build/compile the contracts

```shell
forge build
```

To run the tests

```shell
forge test
```

To clean the compilation files

```shell
forge clean
```
