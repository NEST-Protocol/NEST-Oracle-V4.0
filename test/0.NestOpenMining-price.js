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
            nestMining, nestOpenMining,
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

        await nest.approve(nestOpenMining.address, 10000000000000000000000000000n);
        await usdt.approve(nestOpenMining.address, 10000000000000000000000000n);
        await hbtc.approve(nestOpenMining.address, 10000000000000000000000000n);
        await nest.connect(addr1).approve(nestOpenMining.address, 10000000000000000000000000000n);
        await usdt.connect(addr1).approve(nestOpenMining.address, 10000000000000000000000000n);
        await hbtc.connect(addr1).approve(nestOpenMining.address, 10000000000000000000000000n);

        //await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
        await nestOpenMining.open(
            hbtc.address,
            1000000000000000000n,
            nest.address,
            usdt.address,

            {
            // Reward per block standard
            rewardPerBlock: 1000000000000000000n,
    
            // Post fee(0.0001eth, DIMI_ETHER). 1000
            postFeeUnit: 1000,
            // Single query fee (0.0001 ether, DIMI_ETHER). 100
            singleFee: 100,
            // Reduction rate(10000 based). 8000
            reductionRate: 8000
        });
        await nestOpenMining.increase(0, 5000000000000000000000000000n);
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
            let cfg = await nestOpenMining.getConfig();
            console.log(UI(cfg));

            await nestOpenMining.setConfig({
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

            cfg = await nestOpenMining.getConfig();
            console.log(UI(cfg));
        }

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        if (true) {
            console.log('3. post');
            let receipt = await nestOpenMining.post(0, 1, 60000000000n, {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });
            await showReceipt(receipt);
            let status = await showStatus();
        }


        if (false) {
            console.log('4. price');

            const np = await ethers.getContractAt('INestPriceView', nestOpenMining.address);
            const test = async function() {
                console.log(UI(await np.latestPrice(0)));
                console.log(UI(await np.triggeredPrice(0)));
                console.log(UI(await np.latestPriceAndTriggeredPriceInfo(0)));
                console.log(UI(await np.lastPriceListAndTriggeredPriceInfo(0, 2)));
                console.log(UI(await np.lastPriceList(0, 2)));
                console.log(UI(await np.findPrice(0, 85)));
            }

            console.log('No wait');
            await test();

            console.log('Wait for 20 blocks');
            await skipBlocks(20);
            await test();

            console.log('stat');
            await nestOpenMining.stat(0);
            await test();

            console.log();
            console.log('Post new price');
            await nestOpenMining.post(0, 1, toBigInt(65000, 6), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });

            console.log('No wait');
            await test();

            console.log('Wait for 20 blocks');
            await skipBlocks(20);
            await test();

            console.log('stat');
            await nestOpenMining.stat(0);
            await test();
        }

        if (true) {
            console.log('4. price');
            
            await showStatus();
            console.log('fee: ' + toDecimal((await nestOpenMining.getChannelInfo(0)).feeInfo));

            const np = await ethers.getContractAt('INestOpenPrice', nestOpenMining.address);
            const test = async function() {
                const FEE = 0.010;
                await np.latestPrice(0, owner.address, { value: toBigInt(FEE) });
                await np.triggeredPrice(0, owner.address, { value: toBigInt(FEE) });
                //await np.latestPriceAndTriggeredPriceInfo(0, owner.address, { value: toBigInt(FEE) });
                await np.lastPriceListAndTriggeredPriceInfo(0, 2, owner.address, { value: toBigInt(FEE) });
                await np.lastPriceList(0, 2, owner.address, { value: toBigInt(FEE) });
                await np.findPrice(0, 88, owner.address, { value: toBigInt(FEE) });
            }

            console.log('No wait');
            await test();

            console.log('Wait for 20 blocks');
            await skipBlocks(20);
            await test();

            console.log('stat');
            await nestOpenMining.stat(0);
            await test();

            console.log();
            console.log('Post new price');
            await nestOpenMining.post(0, 1, toBigInt(65000, 6), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT
            });

            console.log('No wait');
            await test();

            console.log('Wait for 20 blocks');
            await skipBlocks(20);
            await test();

            console.log('stat');
            await nestOpenMining.stat(0);
            await test();

            await showStatus();
            console.log('fee: ' + toDecimal((await nestOpenMining.getChannelInfo(0)).feeInfo));
        }
    });
});
