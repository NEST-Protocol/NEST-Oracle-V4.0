# NEST-Oracle-V4.0
The NEST Oracle Smart Contract 4.0 is a solidity smart contract implementation of NEST Protocol which provide a unique on-chain Price Oracle through a decentralized mechanism.

![](https://img.shields.io/github/issues/NEST-Protocol/NEST-Oracle-V4.0)
![](https://img.shields.io/github/stars/NEST-Protocol/NEST-Oracle-V4.0)
![](https://img.shields.io/github/license/NEST-Protocol/NEST-Oracle-V4.0)

## Whitepaper

**[https://nestprotocol.org/doc/ennestwhitepaper.pdf](https://nestprotocol.org/doc/ennestwhitepaper.pdf)**

## Documents

**[About NEST](https://nestprotocol.org/docs/Concept/What-is-NEST)**

**[How does NEST Oracle Work?](https://nestprotocol.org/docs/NEST-Oracle/How-does-NEST-Oracle-Work)**

**[Audit Report](https://github.com/NEST-Protocol/NEST-Docs/blob/main/REP-NEST-Protocol4__final-20220715T020738Z.pdf)**

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

### 2021-12-18@mainnet
| Name | Interfaces | mainnet |
| ---- | ---- | ---- |
| nest | IERC20 | 0x04abEdA201850aC0124161F037Efd70c74ddC74C |
| usdt | IERC20 | 0xdAC17F958D2ee523a2206206994597C13D831ec7 |
| hbtc | IERC20 | 0x0316EB71485b0Ab14103307bf65a021042c6d380 |
| pusd | IERC20 | 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0 |
| nestGovernance | INestGovernance | 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5 |
| nestBatchPlatform2 | INestBatchMining, INestBatchPriceView, INestBatchPrice2 | 0xE544cF993C7d477C7ef8E91D28aCA250D135aa03 |

### 2021-11-20@bsc_main
| Name | Interfaces | bsc_main |
| ---- | ---- | ---- |
| nest | IERC20 | 0xcd6926193308d3b371fdd6a6219067e550000000 |
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

## 2022-03-29@kcc_main
| Name | Interfaces | kcc_main |
| ---- | ---- | ---- |
| peth | IERC20 | 0x6cce8b9da777Ab10B11f4EA8510447431ED6ad1E |
| pusd | IERC20 | 0x0C4CD7cA70172Af5f4BfCb7b0ACBf6EdFEaFab31 |
| pbtc | IERC20 | 0x32D4a9a94537a88118e878c56b93009Af234A6ce |
| nest | IERC20 | 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7 |
| nestGovernance | INestGovernance | 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb |
| nestBatchMining | INestBatchMining, INestBatchPriceView, INestBatchPrice2 | 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6 |
