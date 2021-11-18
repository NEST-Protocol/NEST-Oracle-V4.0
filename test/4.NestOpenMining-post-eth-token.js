const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

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
            reductionRate: 8000
        });
        await nestOpenMining.increase(0, 5000000000000000000000000000n);
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0n;
        const EFFECT_BLOCK = 50;

        if (false) {
            console.log('1. post');
            let receipt = await nestOpenMining.post(0, 2, toBigInt(0.465), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 2n * toBigInt(0.465)
            });
            await showReceipt(receipt);
            let status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 4000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(4000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 2n * toBigInt(0.465)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            console.log('sheets: ');
            let sheets = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }
            
            console.log('1. close');
            await nestOpenMining.close(0, [0]);
            status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 4000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(4000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 2n * toBigInt(0.465)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            console.log('1. wait 20 and close');
            await skipBlocks(EFFECT_BLOCK);
            await nestOpenMining.close(0, [0]);
            status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 4000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(4000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(4000000000n, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(100000000000000000000000n + 10000000000000000000n));

            console.log('sheets: ');
            sheets = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(sheets[i]);
            }

            console.log('price: ');
            let nestPrice = await ethers.getContractAt('INestPriceView', nestOpenMining.address);
            let price = await nestPrice.triggeredPriceInfo(0);
            console.log(UI(price));
        }

        if (true) {
            console.log('1. post');
            let receipt = await nestOpenMining.post(0, 1, toBigInt(0.465), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 1n * toBigInt(0.465)
            });
            await showReceipt(receipt);
            let status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 2000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(2000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 1n * toBigInt(0.465)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            console.log('sheets: ');
            let sheets = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }
            
            console.log('1. close');
            await nestOpenMining.close(0, [0]);
            status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 2000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(2000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + 1n * toBigInt(0.465)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            console.log('1. wait 20 and close');
            await skipBlocks(EFFECT_BLOCK);
            await nestOpenMining.close(0, [0]);
            status = await showStatus();
            expect(status.owner.usdt).to.eq(toDecimal(10000000000000n - 2000000000n, 6));
            expect(status.owner.nest).to.eq(toDecimal(4000000000000000000000000000n - OPEN_FEE - 100000000000000000000000n));
            expect(status.mining.usdt).to.eq(toDecimal(2000000000n, 6));
            expect(status.mining.nest).to.eq(toDecimal(5000000000000000000000000000n + OPEN_FEE + 100000000000000000000000n));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(2000000000n, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(100000000000000000000000n + 10000000000000000000n));

            console.log('sheets: ');
            sheets = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(sheets[i]);
            }

            console.log('price: ');
            let nestPrice = await ethers.getContractAt('INestPriceView', nestOpenMining.address);
            let price = await nestPrice.triggeredPriceInfo(0);
            console.log(UI(price));
        }
        
        console.log('getAccountCount: ' + await nestOpenMining.getAccountCount());
    });
});
