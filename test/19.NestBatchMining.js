const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const { 
            nest, usdt, hbtc, usdc, cofi,

            nestGovernance, nestLedger,
            nestMining, nestOpenMining, nestBatchMining,
            nestPriceFacade, nestVote,
            nTokenController, nestRedeeming
        } = await deploy();

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                hbtc: toDecimal(await hbtc.balanceOf(account), 18),
                nest: toDecimal(await nest.balanceOf(account), 18),
            };
        };
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                mining: await getAccountInfo(nestBatchMining)
            };
        };

        const showStatus = async function() {
            let status = await getStatus();
            //console.log(status);
            return status;
        }

        const skipBlocks = async function(n) {
            for (var i = 0; i < n; ++i) {
                await usdt.transfer(owner.address, 0);
            }
        }

        await usdt.transfer(owner.address, 10000000000000n);
        await usdc.transfer(owner.address, 10000000000000n);
        await cofi.transfer(owner.address, 10000000000000n);
        await hbtc.transfer(owner.address, 10000000000000000000000000n);
        await usdt.connect(addr1).transfer(addr1.address, 10000000000000n);
        await usdc.connect(addr1).transfer(addr1.address, 10000000000000n);
        await cofi.connect(addr1).transfer(addr1.address, 10000000000000n);
        await hbtc.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
        await nest.transfer(addr1.address, 1000000000000000000000000000n);
        console.log(await getStatus());

        await nest.approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.approve(nestBatchMining.address, 10000000000000000000000000n);
        await usdc.approve(nestBatchMining.address, 10000000000000000000000000n);
        await cofi.approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.approve(nestBatchMining.address, 10000000000000000000000000n);
        await nest.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
        await usdc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
        await cofi.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);

        //await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
        await nestBatchMining.open(
            hbtc.address,
            1000000000000000000n,
            nest.address,
            [usdt.address],
            {
                // // 计价代币地址, 0表示eth
                // token0: hbtc.address,
                // // 计价代币单位
                // unit: 1000000000000000000n,
        
                // 报价代币地址，0表示eth
                //token1: usdt.address,
                // 每个区块的标准出矿量
                rewardPerBlock: 1000000000000000000n,
        
                // // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
                // // 出矿代币地址
                // reward: nest.address,
                // // 矿币总量
                // //uint96 vault;
        
                // 管理地址
                //address governance;
                // 创世区块
                //uint32 genesisBlock;
                // Post fee(0.0001eth，DIMI_ETHER). 1000
                postFeeUnit: 1000,
                // Single query fee (0.0001 ether, DIMI_ETHER). 100
                singleFee: 100,
                // 衰减系数，万分制。8000
                reductionRate: 8000,
                
                // tokens: [usdt.address]
        });
        await nestBatchMining.increase(0, 5000000000000000000000000000n);
        //console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0n;
        const EFFECT_BLOCK = 50;

        if (true) {
            console.log('1. post');
            let receipt = await nestBatchMining.post(0, 1, [60000000000n], {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });
            await showReceipt(receipt);

            console.log('1. wait 20 and close');
            await skipBlocks(EFFECT_BLOCK);
            await nestBatchMining.close(0, [[0]]);
        }

        if (true) {
            console.log('1. post');
            let receipt = await nestBatchMining.post(0, 1, [60000000000n], {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });
            await showReceipt(receipt);
        }
    });
});
