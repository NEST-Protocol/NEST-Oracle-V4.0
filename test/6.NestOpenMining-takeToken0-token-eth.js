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
            token0: '0x0000000000000000000000000000000000000000',
            // 计价代币单位
            unit: 1000000000000000000n,
    
            // 报价代币地址，0表示eth
            token1: usdt.address,
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
        await nestOpenMining.increase(0, toBigInt(5000000000));
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0;
        const EFFECT_BLOCK = 50;

        if (true) {
            console.log('1. post');
            let receipt = await nestOpenMining.post(0, 1, toBigInt(4300, 6), {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1)
            });
            await showReceipt(receipt);
            let status = await showStatus();

            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
            expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300, 6), 6));
            expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000)));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            console.log('sheets: ');
            let sheets = await nestOpenMining.list(0, 0, 1, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }

            console.log('2. takeToken0');
            await nestOpenMining.connect(addr1).takeToken0(0, 0, 1, toBigInt(4400, 6), {
                value: toBigInt(2 - 1)
            });
            status = await showStatus();

            console.log('sheets: ');
            sheets = await nestOpenMining.list(0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }

            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
            expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 - 4300, 6), 6));
            expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
            expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4300 + 4400 * 2, 6), 6));
            expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000)));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1 + 1)));
            
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));
            expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestOpenMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(0));
            
            if (false) {
                console.log('1. wait 20 and close');
                await skipBlocks(EFFECT_BLOCK);
                await nestOpenMining.close(0, [0]);
                await nestOpenMining.close(0, [1]);
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 - 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4300 + 4400 * 2, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT));
                
                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(toBigInt(4300 * 2, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(toBigInt(100000 + 10)));
                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(4400 * 2, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(toBigInt(200000)));

                console.log('sheets: ');
                sheets = await nestOpenMining.list(0, 0, 2, 0);
                for (var i = 0; i < sheets.length; ++i) {
                    console.log(sheets[i]);
                }

                console.log('price: ');
                let nestPrice = await ethers.getContractAt('INestPriceView', nestOpenMining.address);
                let list = await nestPrice.lastPriceList(0, 3);
                for (var i = 0; i < list.length; i += 2) {
                    console.log({
                        bn: list[i].toString(),
                        price: list[i+1].toString()
                    });
                }
            } else {
                console.log('2. 吃单链');
                await nestOpenMining.takeToken0(0, 1, 2, toBigInt(4150, 6), { value: toBigInt(2) });
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300 - 4150 * 4 - 4400 * 2, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000 - 100000 * 4)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 - 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4300 + 4400 * 2 + 4150 * 4 + 4400 * 2, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000 + 400000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1 + 1 + 2)));
                
                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(toBigInt(0)));

                console.log('1. wait 20 and close');
                await skipBlocks(EFFECT_BLOCK);
                await nestOpenMining.close(0, [0]);
                await nestOpenMining.close(0, [1]);
                await nestOpenMining.close(0, [2]);
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300 - 4150 * 4 - 4400 * 2, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000 - 100000 * 4)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 - 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4300 + 4400 * 2 + 4150 * 4 + 4400 * 2, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000 + 400000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT));
                
                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(toBigInt(4300 * 2 + 4150 * 4, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, owner.address))).eq(toDecimal(toBigInt(100000 + 400000 + 10)));

                expect(toDecimal(await nestOpenMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(4400 * 4, 6), 6));
                expect(toDecimal(await nestOpenMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(toBigInt(200000)));

                console.log('price: ');
                let nestPrice = await ethers.getContractAt('INestPriceView', nestOpenMining.address);
                let list = await nestPrice.lastPriceList(0, 3);
                for (var i = 0; i < list.length; i += 2) {
                    console.log({
                        bn: list[i].toString(),
                        price: list[i+1].toString()
                    });
                }
            }
        }
    });
});
