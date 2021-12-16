const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
        const NestOpenMining = await ethers.getContractFactory('NestOpenPlatform');
        const { 
            nest, usdt, hbtc,

            nestGovernance, nestLedger,
            nestMining, nestBatchMining,
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
            };
        };

        const showStatus = async function() {
            let status = await getStatus();
            console.log(status);
            return status;
        };

        const skipBlocks = async function(n) {
            for (var i = 0; i < n; ++i) {
                await usdt.transfer(owner.address, 0);
            }
        };

        await usdt.transfer(owner.address, 10000000000000n);
        await hbtc.transfer(owner.address, 10000000000000000000000000n);
        await usdt.connect(addr1).transfer(addr1.address, 10000000000000n);
        await hbtc.connect(addr1).transfer(addr1.address, 10000000000000000000000000n);
        await nest.transfer(addr1.address, 1000000000000000000000000000n);
        console.log(await getStatus());

        await nest.approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.approve(nestBatchMining.address, 10000000000000000000000000n);
        await nest.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);

        //await nestBatchMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
        await nestBatchMining.open({
            // 计价代币地址, 0表示eth
            token0: hbtc.address,
            // 计价代币单位
            unit: 1000000000000000000n,
    
            // 报价代币地址，0表示eth
            //token1: usdt.address,
            // 每个区块的标准出矿量
            rewardPerBlock: 1000000000000000000n,
    
            // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
            // 出矿代币地址
            reward: nest.address,
            // 矿币总量
            //uint96 vault;
    
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

            tokens: [usdt.address]
        });
        await nestBatchMining.increase(0, 5000000000000000000000000000n);
        console.log(await getStatus());

        if (false) {
            console.log('1. initialize');
            const nom = await NestOpenMining.deploy();
            console.log('accounts.length: ' + await nom.getAccountCount());
            await nom.initialize('0x0000000000000000000000000000000000000000');
            await nom.initialize('0x0000000000000000000000000000000000000000');
            await nom.initialize('0x0000000000000000000000000000000000000000');
            await nom.initialize(nestGovernance.address);
            console.log('accounts.length: ' + await nom.getAccountCount());
            await nom.update(nestGovernance.address);
            console.log('accounts.length: ' + await nom.getAccountCount());
        }

        if (false) {
            console.log('2. getConfig');
            let cfg = await nestBatchMining.getConfig();
            console.log(UI(cfg));

            await nestBatchMining.setConfig({
                postEthUnit: 10,
                postFeeUnit: 2000,
                minerNestReward: 3000,
                minerNTokenReward: 4500,
                doublePostThreshold: 500,
                ntokenMinedBlockLimit: 600,
                maxBiteNestedLevel: 7,
                priceEffectSpan: 80,
                pledgeNest: 900
            });

            cfg = await nestBatchMining.getConfig();
            console.log(UI(cfg));
        }

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        if (true) {
            console.log('3. post');
            let receipt = await nestBatchMining.post(0, 1, [60000000000n], {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }

        if (false) {
            console.log('4. price');

            const np = await ethers.getContractAt('INestPriceView', nestBatchMining.address);
            const test = async function() {
                console.log(UI(await np.latestPrice(0)));
                console.log(UI(await np.triggeredPrice(0)));
                console.log(UI(await np.latestPriceAndTriggeredPriceInfo(0)));
                console.log(UI(await np.lastPriceListAndTriggeredPriceInfo(0, 2)));
                console.log(UI(await np.lastPriceList(0, 2)));
                console.log(UI(await np.findPrice(0, 85)));
            }

            console.log('没有等待');
            await test();

            console.log('等待20区块');
            await skipBlocks(20);
            await test();

            console.log('触发');
            await nestBatchMining.stat(0);
            await test();

            console.log();
            console.log('报新价格');
            await nestBatchMining.post(0, 1, toBigInt(65000, 6), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });

            console.log('没有等待');
            await test();

            console.log('等待20区块');
            await skipBlocks(20);
            await test();

            console.log('触发');
            await nestBatchMining.stat(0);
            await test();
        }

        if (true) {
            console.log('4. price');
            
            await showStatus();
            console.log('fee: ' + toDecimal((await nestBatchMining.getChannelInfo(0)).rewards));

            const np = await ethers.getContractAt('INestBatchPrice2', nestBatchMining.address);
            const nv = await ethers.getContractAt('INestBatchPriceView', nestBatchMining.address);
            const test = async function() {
                const FEE = 0.010;

                let pi = await nv.lastPriceList(0, 0, 1);
                console.log({
                    blockNumber: pi[0].toString(), //pi.blockNumber.toString(),
                    price: pi[1].toString() //pi.price.toString()
                });

                await np.lastPriceList(0, [0], 1, owner.address, { value: toBigInt(FEE) });
                await np.triggeredPrice(0, [0], owner.address, { value: toBigInt(FEE) });
                //await np.latestPriceAndTriggeredPriceInfo(0, 0, owner.address, { value: toBigInt(FEE) });
                await np.lastPriceListAndTriggeredPriceInfo(0, [0], 2, owner.address, { value: toBigInt(FEE) });
                await np.lastPriceList(0, [0], 2, owner.address, { value: toBigInt(FEE) });
                await np.findPrice(0, [0], 85, owner.address, { value: toBigInt(FEE) });
            }

            console.log('没有等待');
            await test();

            console.log('等待20区块');
            await skipBlocks(20);
            await test();

            // console.log('触发');
            // await nestBatchMining.stat(0);
            // await test();

            console.log();
            console.log('报新价格');
            await nestBatchMining.post(0, 1, [toBigInt(65000, 6)], {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });

            console.log('没有等待');
            await test();

            console.log('等待20区块');
            await skipBlocks(20);
            await test();

            // console.log('触发');
            // await nestBatchMining.stat(0);
            // await test();

            await showStatus();
            console.log('fee: ' + toDecimal((await nestBatchMining.getChannelInfo(0)).rewards));
        }
    });
});
