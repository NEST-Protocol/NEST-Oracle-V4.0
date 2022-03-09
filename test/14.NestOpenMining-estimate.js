// const { expect } = require('chai');
// const { deploy } = require('../scripts/deploy.js');
// const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

// describe('NestOpenMining', function() {
//     it('First', async function() {
//         var [owner, addr1, addr2] = await ethers.getSigners();
//         const NToken = await ethers.getContractFactory('NToken');

//         const { 
//             nest, usdt, hbtc,

//             nestGovernance, nestLedger,
//             nestMining, nestBatchMining,
//             nestPriceFacade, nestVote,
//             nTokenController, nestRedeeming
//         } = await deploy();
//         const nhbtc = await NToken.deploy('NToken001', 'N001');
//         await nhbtc.initialize(nestGovernance.address);
//         await nhbtc.update(nestGovernance.address);

//         const getAccountInfo = async function(account) {
//             let acc = account;
//             account = account.address;
//             return {
//                 eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
//                 usdt: toDecimal(await usdt.balanceOf(account), 6),
//                 hbtc: toDecimal(await hbtc.balanceOf(account), 18),
//                 nhbtc: toDecimal(await nhbtc.balanceOf(account), 18),
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
//             console.log(status);
//             return status;
//         }

//         const skipBlocks = async function(n) {
//             for (var i = 0; i < n; ++i) {
//                 await usdt.transfer(owner.address, 0);
//             }
//         }

//         await usdt.transfer(owner.address, 10000000000000n);
//         await hbtc.transfer(owner.address, 10000000000000000000000000n);
//         await usdt.connect(addr1).transfer(addr1.address, 10000000000000n);
//         await hbtc.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
//         await nest.transfer(addr1.address, 1000000000000000000000000000n);
//         console.log(await getStatus());

//         await nest.approve(nestBatchMining.address, 10000000000000000000000000000n);
//         await usdt.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await hbtc.approve(nestBatchMining.address, 10000000000000000000000000n);
//         await nest.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000000n);
//         await usdt.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
//         await hbtc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);

//         await nestGovernance.setBuiltinAddress(
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000', //nestMining.address,
//             owner.address, //nestMining.address,
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000', //nestMining.address,
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000'
//         );
//         await nhbtc.update(nestGovernance.address);
//         await nhbtc.increaseTotal(1);
//         await nhbtc.approve(nestBatchMining.address, 1);
//         await nestGovernance.setBuiltinAddress(
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000', //nestMining.address,
//             nestBatchMining.address, //nestMining.address,
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000', //nestMining.address,
//             '0x0000000000000000000000000000000000000000',
//             '0x0000000000000000000000000000000000000000'
//         );
//         await nhbtc.update(nestGovernance.address);

//         await nestBatchMining.open(
//             usdt.address,
//             2000000000n,
//             nhbtc.address,
//             ['0x0000000000000000000000000000000000000000'],
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
//         await nestBatchMining.increaseNToken(0, 5000000000000000000000000000n);
//         console.log(await getStatus());

//         const GASLIMIT = 400000n;
//         const POSTFEE = 0.1;
//         const OPEN_FEE = 0;
//         const EFFECT_BLOCK = 50;

//         let prev = BigInt(await nestBatchMining.balanceOf(nhbtc.address, owner.address));
//         for (var i = 0; i < 10; ++i) {
//             if (true) {
//                 console.log('1. post0');
//                 let es = await nestBatchMining.estimate(0);
//                 let receipt = await nestBatchMining.post(0, 1, toBigInt(0.46), {
//                     value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0.46)
//                 });
//                 await showReceipt(receipt);
//                 let status = await showStatus();

//                 await skipBlocks(EFFECT_BLOCK);
//                 console.log('(i << 1): ' + (i << 1))
//                 await nestBatchMining.close(0, [0 + (i << 1)]);
//                 let now = BigInt(await nestBatchMining.balanceOf(nhbtc.address, owner.address));
//                 let mi = now - prev;
//                 prev = now;
//                 console.log(UI({
//                     es: toDecimal(es), 
//                     mi: toDecimal(mi)
//                 }));
//                 expect(toDecimal(es)).to.eq(toDecimal(mi));
//             }

//             if (true) {
//                 console.log('2. post1');
//                 let es = await nestBatchMining.estimate(0);
//                 let receipt = await nestBatchMining.post(0, 1, toBigInt(0.46), {
//                     value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0.46)
//                 });
//                 await showReceipt(receipt);
//                 let status = await showStatus();

//                 await skipBlocks(EFFECT_BLOCK + 1);
//                 await nestBatchMining.close(0, [1 + (i << 1)]);
//                 let now = BigInt(await nestBatchMining.balanceOf(nhbtc.address, owner.address));
//                 let mi = now - prev;
//                 prev = now;
//                 console.log(UI({
//                     es: toDecimal(es), 
//                     mi: toDecimal(mi)
//                 }));
//                 expect(toDecimal(es)).to.eq(toDecimal(mi));
//             }
//         }

//         let count = (await nestBatchMining.list(0, 0, 1, 0))[0].index + 1;
//         let list = await nestBatchMining.list(0, 0, count, 0);
//         for (var i = 0; i < list.length; ++i) {
//             console.log(UI(await nestBatchMining.getMinedBlocks(0, i)));
//         }
//     });
// });
