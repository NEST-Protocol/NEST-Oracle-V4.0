const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const NToken = await ethers.getContractFactory('NToken');

        const { 
            nest, usdt, hbtc,

            nestGovernance, nestLedger,
            nestMining, nestOpenMining,
            nestPriceFacade, nestVote,
            nTokenController, nestRedeeming
        } = await deploy();
        const nhbtc = await NToken.deploy('NToken001', 'N001');
        await nhbtc.initialize(nestGovernance.address);
        await nhbtc.update(nestGovernance.address);

        const getAccountInfo = async function(account) {
            let acc = account;
            account = account.address;
            return {
                eth: toDecimal(acc.ethBalance ? await acc.ethBalance() : await ethers.provider.getBalance(account)),
                usdt: toDecimal(await usdt.balanceOf(account), 6),
                hbtc: toDecimal(await hbtc.balanceOf(account), 18),
                nhbtc: toDecimal(await nhbtc.balanceOf(account), 18),
                nest: toDecimal(await nest.balanceOf(account), 18),
            };
        };
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
                mining: await getAccountInfo(nestOpenMining)
            };
        };

        const showStatus = async function() {
            let status = await getStatus();
            console.log(status);
            return status;
        }

        const skipBlocks = async function(n) {
            for (var i = 0; i < n; ++i) {
                await usdt.transfer(owner.address, 0);
            }
        }

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

        await nestGovernance.setBuiltinAddress(
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000', //nestMining.address,
            nestOpenMining.address, //nestMining.address,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000', //nestMining.address,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000'
        );
        await nhbtc.update(nestGovernance.address);
        //await nhbtc.increaseTotal(toBigInt(100000));
        //await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
        await nestOpenMining.open({
            // 计价代币地址, 0表示eth
            token0: usdt.address,
            // 计价代币单位
            unit: 2000000000n,
    
            // 报价代币地址，0表示eth
            token1: '0x0000000000000000000000000000000000000000',
            // 每个区块的标准出矿量
            rewardPerBlock: 1000000000000000000n,
    
            // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
            // 出矿代币地址
            reward: nhbtc.address,
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
            reductionRate: 8000
        });
        //await nestOpenMining.increase(0, 5000000000000000000000000000n);
        await nest.transfer(nestOpenMining.address, 5000000000000000000000000000n);
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;

        let prev = BigInt(await nestOpenMining.balanceOf(nhbtc.address, owner.address));
        for (var i = 0; i < 10; ++i) {
            if (true) {
                console.log('1. post0');
                let es = await nestOpenMining.estimate(0);
                let receipt = await nestOpenMining.post(0, 1, toBigInt(0.46), {
                    value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0.46)
                });
                await showReceipt(receipt);
                let status = await showStatus();

                await skipBlocks(20);
                console.log('(i << 1): ' + (i << 1))
                await nestOpenMining.close(0, 0 + (i << 1));
                let now = BigInt(await nestOpenMining.balanceOf(nhbtc.address, owner.address));
                let mi = now - prev;
                prev = now;
                console.log(UI({
                    es: toDecimal(es), 
                    mi: toDecimal(mi)
                }));
                expect(toDecimal(es)).to.eq(toDecimal(mi));
            }

            if (true) {
                console.log('2. post1');
                let es = await nestOpenMining.estimate(0);
                let receipt = await nestOpenMining.post(0, 1, toBigInt(0.46), {
                    value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0.46)
                });
                await showReceipt(receipt);
                let status = await showStatus();

                await skipBlocks(21);
                await nestOpenMining.close(0, 1 + (i << 1));
                let now = BigInt(await nestOpenMining.balanceOf(nhbtc.address, owner.address));
                let mi = now - prev;
                prev = now;
                console.log(UI({
                    es: toDecimal(es), 
                    mi: toDecimal(mi)
                }));
                expect(toDecimal(es)).to.eq(toDecimal(mi));
            }
        }

        let count = (await nestOpenMining.list(0, 0, 1, 0))[0].index + 1;
        let list = await nestOpenMining.list(0, 0, count, 0);
        for (var i = 0; i < list.length; ++i) {
            console.log(UI(await nestOpenMining.getMinedBlocks(0, i)));
        }
    });
});
