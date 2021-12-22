# NEST-Oracle-V4.0
The NEST Oracle Smart Contract 4.0 is a solidity smart contract implementation of NEST Protocol which provide a unique on-chain Price Oracle through a decentralized mechanism.

![](https://img.shields.io/github/issues/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/github/stars/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/github/license/NEST-Protocol/NEST-Oracle-V3.6)
![](https://img.shields.io/twitter/url?url=https%3A%2F%2Fgithub.com%2FNEST-Protocol%2FNEST-Oracle-V3.6%2F)

## Whitepaper

**[https://nestprotocol.org/doc/ennestwhitepaper.pdf](https://nestprotocol.org/doc/ennestwhitepaper.pdf)**

## Documents

**[NEST V3.6 Contract Specification](docs/readme.md)**

**[NEST V3.6 Contract Structure Diagram](docs/nest36-contracts.svg)**

**[NEST V3.6 Application Scenarios](docs/readme.md#5-application-scenarios)**

**[Audit Report](docs/PeckShield-Audit-Report-NestV3.6.pdf)**

**[Learn More...](https://nestprotocol.org/)**

## Usage

### Run test

```shell
npm install

npx truffle test
```

### Compile

Run `npx truffle compile`, get build results in `build/contracts` folder, including `ABI` json files.

### Deploy

Deploy with `truffle` and you will get a contract deployment summary on contract addresses.

```shell
npx truffle migrate --network ropsten
```

## Contract Addresses

### 2021-11-20@bsc_main
| Name | Interfaces | bsc_main |
| ---- | ---- | ---- |
| nest | IERC20 | 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7 |
| pusd | IERC20 | 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2 |
| peth | IERC20 | 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB |
| nestGovernance | INestGovernance | 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb |
| nestLedger | INestLedger | 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6 |
| nestOpenMining | INestOpenMining, INestOpenPrice, INestPriceView | 0x09CE0e021195BA2c1CDE62A8B187abf810951540 |

### 2021-11-02@rinkeby
| Name | Interfaces | rinkeby |
| ---- | ---- | ---- |
| nest | IERC20 | 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25 |
| usdt | IERC20 | 0x20125a7256EFafd0d4Eec24048E08C5045BC5900 |
| hbtc | IERC20 | 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B |
| nestGovernance | INestGovernance | 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7 |
| nestLedger | INestLedger | 0x005103e352f86e4C32a3CE4B684fe211eB123210 |
| nestOpenMining | INestOpenMining, INestOpenPrice, INestPriceView | 0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF |
