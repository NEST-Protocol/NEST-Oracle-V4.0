// const { expect } = require('chai');
// const { deploy } = require('../scripts/deploy.js');
// const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

// describe('NestOpenMining', function() {
//     it('First', async function() {
//         var [owner, addr1, addr2] = await ethers.getSigners();
        
//         const { 
//             nest, usdt, hbtc, usdc, cofi,

//             nestGovernance, nestLedger,
//             nestMining, nestOpenMining, nestBatchMining,
//             nestPriceFacade, nestVote,
//             nTokenController, nestRedeeming
//         } = await deploy();

//         const getAccountInfo = async function(account) {
//             let acc = account;
//             account = account.address;
//             return {
//                 eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
//                 usdt: toDecimal(await usdt.balanceOf(account), 6),
//                 hbtc: toDecimal(await hbtc.balanceOf(account), 18),
//                 nest: toDecimal(await nest.balanceOf(account), 18),
//             };
//         };
//         const getStatus = async function() {
//             return {
//                 height: await ethers.provider.getBlockNumber(),
//                 owner: await getAccountInfo(owner),
//                 addr1: await getAccountInfo(addr1),
//                 mining: await getAccountInfo(nestBatchMining)
//             };
//         };

//         const showStatus = async function() {
//             let status = await getStatus();
//             //console.log(status);
//             return status;
//         }

//         const skipBlocks = async function(n) {
//             for (var i = 0; i < n; ++i) {
//                 await usdt.transfer(owner.address, 0);
//             }
//         }

//         await usdt.transfer(owner.address, 10000000000000n);
//         await usdc.transfer(owner.address, 10000000000000n);
//         await cofi.transfer(owner.address, 10000000000000n);
//         await hbtc.transfer(owner.address, 10000000000000000000000000n);
//         await usdt.connect(addr1).transfer(addr1.address, 10000000000000n);
//         await usdc.connect(addr1).transfer(addr1.address, 10000000000000n);
//         await cofi.connect(addr1).transfer(addr1.address, 10000000000000n);
//         await hbtc.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
//         await nest.transfer(addr1.address, 1000000000000000000000000000n);
//         console.log(await getStatus());

//         await nest.approve(nestBatchMining.address, 10000000000000000000000000000n);
//         await usdt.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await usdc.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await cofi.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await hbtc.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await nest.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000000n);
//         await usdt.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
//         await usdc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
//         await cofi.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
//         await hbtc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);

//         //await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
//         await nestBatchMining.open(
//             hbtc.address,
//             1000000000000000000n,
//             nest.address,
//             [usdt.address, usdc.address, cofi.address],
//             {
//             // Reward per block standard
//             rewardPerBlock: 1000000000000000000n,
//             // Post fee(0.0001eth, DIMI_ETHER). 1000
//             postFeeUnit: 1000,
//             // Single query fee (0.0001 ether, DIMI_ETHER). 100
//             singleFee: 100,
//             // Reduction rate(10000 based). 8000
//             reductionRate: 8000,
//         });
//         await nestBatchMining.increase(0, 5000000000000000000000000000n);
//         //console.log(await getStatus());

//         const GASLIMIT = 400000n;
//         const POSTFEE = 0.1;
//         const OPEN_FEE = 0n;
//         const EFFECT_BLOCK = 50;

//         if (true) {
//             console.log('1. post');
//             let receipt = await nestBatchMining.post(0, 1, [71000000000n, 72000000000n, 73000000000n], {
//                 value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
//             });
//             await showReceipt(receipt);

//             console.log('1. wait 20 and close');
//             await skipBlocks(EFFECT_BLOCK);
//             await nestBatchMining.close(0, [[0], [0], [0]]);
//             //await nestBatchMining.close(0, 1, [0]);
//             //await nestBatchMining.close(0, 2, [0]);
//         }

//         const nbm = await ethers.getContractAt('INestBatchPrice2', nestBatchMining.address);
//         if (true) {
//             console.log('2. post');
//             let receipt = await nestBatchMining.post(0, 1, [61000000000n, 62000000000n, 63000000000n], {
//                 value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
//             });
//             await showReceipt(receipt);
//         }

//         if (true) {
//             await skipBlocks(EFFECT_BLOCK);
//             await nestBatchMining.close(0, [[1], [1], [1]]);
//         }

//         if (true) {
//             console.log('3. triggeredPrice');
//             let p = await nbm.triggeredPrice(0, [1, 2, 0], owner.address);
//             for (var i = 0; i < p.length; ++i) {
//                 console.log(p[i].toString());
//             }
//         }

//         if (true) {
//             console.log('4. triggeredPriceInfo');
//             let p = await nbm.triggeredPriceInfo(0, [1, 2, 0], owner.address);
//             for (var i = 0; i < p.length; ++i) {
//                 console.log(p[i].toString());
//             }
//         }

//         if (true) {
//             console.log('5. findPrice');
//             let p = await nbm.findPrice(0, [1, 2, 0], 99, owner.address);
//             for (var i = 0; i < p.length; ++i) {
//                 console.log(p[i].toString());
//             }
//         }

//         if (true) {
//             console.log('6. latestPrice');
//             let p = await nbm.latestPrice(0, [1, 2, 0], owner.address);
//             for (var i = 0; i < p.length; ++i) {
//                 console.log(p[i].toString());
//             }
//         }

//         if (true) {
//             console.log('7. lastPriceList');
//             let p = await nbm.lastPriceList(0, [1, 2, 0], 2, owner.address);
//             for (var i = 0; i < p.length; ++i) {
//                 console.log(p[i].toString());
//             }
//         }

//         if (true) {
//             console.log('8. lastPriceListAndTriggeredPriceInfo');
//             let p = await nbm.lastPriceListAndTriggeredPriceInfo(0, [1, 2, 0], 2, owner.address);
//             for (var i = 0; i < p.length; ) {
//                 console.log('height1: ' + p[i++].toString());
//                 console.log('price1: ' + p[i++].toString());
//                 console.log('height0: ' + p[i++].toString());
//                 console.log('price0: ' + p[i++].toString());
//                 console.log('triggeredPriceBlockNumber: ' + p[i++].toString());
//                 console.log('triggeredPriceValue: ' + p[i++].toString());
//                 console.log('triggeredAvgPrice: ' + p[i++].toString());
//                 console.log('triggeredSigmaSQ: ' + p[i++].toString());
//                 console.log();
//             }
//         }
//     });
// });
