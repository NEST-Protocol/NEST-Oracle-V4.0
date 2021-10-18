const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
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
        }
        const getStatus = async function() {
            return {
                height: await ethers.provider.getBlockNumber(),
                owner: await getAccountInfo(owner),
                addr1: await getAccountInfo(addr1),
            };
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
        await nestOpenMining.increase(0, 5000000000000000000000000000n);
        console.log(await getStatus());

        if (true) {
            console.log('1. 报价');

            let receipt = await nestOpenMining.post(0, 1, 62000000000n, {
                value: toBigInt(0.2)
            });
            
            await showReceipt(receipt);
            console.log(await getStatus());

            let list = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < list.length; ++i) {
                let sheet = list[i];
                console.log({
                    index: sheet.index.toString(),
                    miner: sheet.miner,
                    height: sheet.height,
                    remainNum: sheet.remainNum,
                    ethNumBal: sheet.ethNumBal,
                    tokenNumBal: sheet.tokenNumBal,
                    nsetNum1k: sheet.nestNum1k,
                    level: sheet.level,
                    shares: sheet.shares,
                    price: sheet.price.toString()
                });
            }
        }

        if (true) {
            console.log('2. 关闭');
            for (var i = 0; i < 25; ++i) {
                await usdt.transfer(owner.address, 0);
            }
            let receipt = await nestOpenMining.close(0, 0);
            await showReceipt(receipt);
            console.log(await getStatus());
        }

        if (false) {
            console.log('3. withdraw');
            await nestOpenMining.withdraw(usdt.address, await nestOpenMining.balanceOf(usdt.address, owner.address));
            await nestOpenMining.withdraw(hbtc.address, await nestOpenMining.balanceOf(hbtc.address, owner.address));
            await nestOpenMining.withdraw(nest.address, await nestOpenMining.balanceOf(nest.address, owner.address));

            console.log(await getStatus());
        }

        if (true) {
            console.log('3. 报价');

            let receipt = await nestOpenMining.post(0, 1, 62000000000n, {
                value: toBigInt(0.2)
            });
            
            await showReceipt(receipt);
            console.log(await getStatus());

            let list = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < list.length; ++i) {
                let sheet = list[i];
                console.log({
                    index: sheet.index.toString(),
                    miner: sheet.miner,
                    height: sheet.height,
                    remainNum: sheet.remainNum,
                    ethNumBal: sheet.ethNumBal,
                    tokenNumBal: sheet.tokenNumBal,
                    nsetNum1k: sheet.nestNum1k,
                    level: sheet.level,
                    shares: sheet.shares,
                    price: sheet.price.toString()
                });
            }
        }

        if (true) {
            console.log('4. 吃单');
            let receipt = await nestOpenMining.connect(addr1).takeToken1(0, 1, 1, 63000000000n);
            await showReceipt(receipt);
            console.log(await getStatus());
        }
    });
});
