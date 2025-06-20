# Questionnaire 10

In our lessons on developing smart contracts, we worked with the Remix IDE (<https://remix.ethereum.org/>) to develop smart contracts in Solidity (<https://docs.soliditylang.org/en/v0.8.30/>) and deploy them on the Ethereum test network called Sepolia (<https://sepolia.etherscan.io/>). In our classes, we worked with a smart contract full of design flaws. Your task here is to fix some of those development flaws. Consider the Solidy code attached to this assignment and make the following changes:

1. Use the owner parameter that identifies the owner of the smart contract to allow only the owner of the contract to execute the *commitment* function;

2. Develop a new function that allows the commitment value to be revealed. Remember that the initial idea is for the owner of the contract to be able to store a drawn value in the contract, by hashing this value concatenated with a salt value, i.e. h(value|salt). For example, if the value drawn was 8 and the salt was 123, we would have: h(8|123). So that, later on, we could reveal both the salt and the value drawn and anyone with access to the contract would be able to verify that the value drawn had already been recorded on the blockchain before the bets were placed. Note that the function that reveals the commitment must also be restricted to the owner of the contract. Calculating hashes in Solidity can be complex and costly, so consider that hash verification can be done externally. Therefore, it is sufficient for the new function to allow the value once drawn to be revealed.

To publish and execute the smart contract in question you will need Ether on the Sepolia test network, you can get these cryptocurrencies for free via Google's Ethereum Sepolia Faucet: <https://cloud.google.com/application/web3/faucet/ethereum/sepolia>. To interact with the Sepolia network via Remix, use Metamask: <https://metamask.io/>.

Smart Contract reference:

```solidity
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

contract CPQD {

    bytes32 hash;
    uint256 salt;
    mapping(uint256 => address[]) public bets;

    function commitment(bytes32 h, uint256 s) public {
        hash = h;
        salt = s;
    }

    function bet(uint256 b) public {
        bets[b].push(msg.sender);
    }

    function get_results(uint256 secret) public view returns (address[] memory) {
        return bets[secret];
    }

}
```

Solution: [CPQD.sol](src/CPQD.sol)

## Development

### Build

```shell
$ forge build
```

#### Build with Model Checker

```shell
$ FOUNDRY_PROFILE=checker forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

## Scripts

### Setup

See [Configuring `foundry.toml`](https://getfoundry.sh/guides/scripting-with-solidity/#configuring-foundrytoml).

#### Sepolia API

Get an API Key from [MetaMask Developer](https://developer.metamask.io/key/all-endpoints) and enable the Ethereum Sepolia endpoint. Copy the key and save to `METAMASK_API_KEY` in a `.env` file:

```sh
METAMASK_API_KEY=0123456789abcdef0123456789abcdef
```

#### Etherscan API

Additionally, get an API Key from [Etherscan](https://etherscan.io/myapikey) and save to `ETHERSCAN_API_KEY` in `.env`:

```sh
ETHERSCAN_API_KEY=ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567
```

### Deploy

```shell
$ forge script --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast script/CPQD.s.sol:CPQDDeploy

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
1: address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### Commit

```shell
$ CONTRACT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 VALUE=7 \
  forge script --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast script/CPQD.s.sol:CPQDCommit

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
1: uint8 7
2: uint256 20185558336621230769913983648758001828384355342540795198665400638095085795870 [2.018e76]
3: bytes32 0x1f1cd6908da08f7cbc9a78a56431aa833d12fb2b4a203ec3d3aeb1102e99219a
```

### Place Bet

```shell
$ CONTRACT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 VALUE=7 \
  forge script --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast script/CPQD.s.sol:CPQDBet

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
1: uint8 7
2: address 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
```

### Reveal

```shell
$ CONTRACT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 VALUE=7 SALT=20185558336621230769913983648758001828384355342540795198665400638095085795870 \
  forge script --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast script/CPQD.s.sol:CPQDReveal

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
1: uint8 7
2: uint256 20185558336621230769913983648758001828384355342540795198665400638095085795870 [2.018e76]
```

### Results

```shell
$ CONTRACT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
  forge script --rpc-url sepolia --private-key $PRIVATE_KEY script/CPQD.s.sol:CPQDResults

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
1: address[] [0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266]
```

### Restart

```shell
$ CONTRACT=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318 \
  forge script --rpc-url sepolia --private-key $PRIVATE_KEY --broadcast script/CPQD.s.sol:CPQDRestart

== Return ==
0: contract CPQD 0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
```
