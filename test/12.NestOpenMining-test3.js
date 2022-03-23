const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        
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
                mining: await getAccountInfo(nestBatchMining)
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

        await nest.approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.approve(nestBatchMining.address, 10000000000000000000000000n);
        await nest.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000000n);
        await usdt.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);
        await hbtc.connect(addr1).approve(nestBatchMining.address, 10000000000000000000000000n);

        //await nestBatchMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
        await nestBatchMining.open(
            '0x0000000000000000000000000000000000000000',
            1000000000000000000n,
            nest.address,
            [usdt.address],
            {
                // Reward per block standard
                rewardPerBlock: 1000000000000000000n,
        
                // Post fee(0.0001eth, DIMI_ETHER). 1000
                postFeeUnit: 1000,
                // Single query fee (0.0001 ether, DIMI_ETHER). 100
                singleFee: 100,
                // Reduction rate(10000 based). 8000
                reductionRate: 8000,
        });
        await nestBatchMining.increase(0, 5000000000000000000000000000n);
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0;
        const EFFECT_BLOCK = 50;

        if (true) {
            console.log('1. post');
            let receipt = await nestBatchMining.post(0, 1, [toBigInt(4300, 6)], {
                value: toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1)
            });
            await showReceipt(receipt);
            let status = await showStatus();

            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
            expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300, 6), 6));
            expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000)));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1)));
            
            expect(toDecimal(await nestBatchMining.balanceOf(hbtc.address, owner.address))).eq(toDecimal(0));
            expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));
            
            console.log('sheets: ');
            let sheets = await nestBatchMining.list(0, 0, 0, 1, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }

            console.log('2. takeToken1');
            if (false) {
                await nestBatchMining.connect(addr1).takeToken1(0, 0, 1, toBigInt(1501, 6), {
                    value: toBigInt(2 + 1)
                });
                status = await showStatus();
    
                console.log('sheets: ');
                sheets = await nestBatchMining.list(0, 0, 2, 0);
                for (var i = 0; i < sheets.length; ++i) {
                    console.log(UI(sheets[i]));
                }
                
                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1 + 2 + 1)));
                
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));
    
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(4300 - 1501 * 2, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(0));
                return;
            }
            await nestBatchMining.connect(addr1).take(0, 0 + 0x10000, 0, 1, toBigInt(4400, 6), {
                value: toBigInt(2 + 1)
            });
            status = await showStatus();

            console.log('sheets: ');
            sheets = await nestBatchMining.list(0, 0, 0, 2, 0);
            for (var i = 0; i < sheets.length; ++i) {
                console.log(UI(sheets[i]));
            }
            
            expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
            expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
            expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 + 4300, 6), 6));
            expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
            expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4400 * 2 - 4300, 6), 6));
            expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000)));
            expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1 + 2 + 1)));
            
            expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
            expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));

            expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
            expect(toDecimal(await nestBatchMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(0));
            
            if (false) {
                console.log('1. wait 20 and close');
                await skipBlocks(50);
                await nestBatchMining.close(0, [0]);
                await nestBatchMining.close(0, [1]);
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 + 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4400 * 2 - 4300, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0)));
                
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(toBigInt(100000 + 10)));

                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(4400 * 2, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(toBigInt(200000)));

                console.log('sheets: ');
                sheets = await nestBatchMining.list(0, 0, 2, 0);
                for (var i = 0; i < sheets.length; ++i) {
                    console.log(UI(sheets[i]));
                }

                console.log('price: ');
                let nestPrice = await ethers.getContractAt('INestPriceView', nestBatchMining.address);
                let list = await nestPrice.lastPriceList(0, 3);
                for (var i = 0; i < list.length; i += 2) {
                    console.log({
                        bn: list[i].toString(),
                        price: list[i+1].toString()
                    });
                }
            } else {
                console.log('2. Bit chain');
                await nestBatchMining.take(0, 0 + 0x10000, 1, 2, toBigInt(4200, 6), {
                    value: toBigInt(2 * 2 + 2)
                });
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300 - 4200 * 4 + 4400 * 2, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000 - 400000)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 + 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4400 * 2 - 4300 + 4200 * 4 - 4400 * 2, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000 + 400000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(1 + 2 + 1 + 2 * 2 + 2)));
                
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(0, 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(0));
    
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(0));

                console.log('1. wait 20 and close');
                await skipBlocks(50);
                await nestBatchMining.close(0, [[0]]);
                await nestBatchMining.close(0, [[1]]);
                await nestBatchMining.close(0, [[2]]);
                status = await showStatus();

                expect(status.owner.usdt).to.eq(toDecimal(toBigInt(10000000 - 4300 - 4200 * 4 + 4400 * 2, 6), 6));
                expect(status.owner.nest).to.eq(toDecimal(toBigInt(4000000000 - OPEN_FEE - 100000 - 400000)));
                expect(status.addr1.usdt).to.eq(toDecimal(toBigInt(10000000 - 4400 * 2 + 4300, 6), 6));
                expect(status.addr1.nest).to.eq(toDecimal(toBigInt(1000000000 - 200000)));
                expect(status.mining.usdt).to.eq(toDecimal(toBigInt(4300 + 4400 * 2 - 4300 + 4200 * 4 - 4400 * 2, 6), 6));
                expect(status.mining.nest).to.eq(toDecimal(toBigInt(5000000000 + OPEN_FEE + 100000 + 200000 + 400000)));
                expect(status.mining.eth).to.eq(toDecimal(toBigInt(POSTFEE) + 1000000000n * GASLIMIT + toBigInt(0)));
                
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, owner.address), 6)).eq(toDecimal(toBigInt(0 + 4200 * 4, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, owner.address))).eq(toDecimal(toBigInt(100000 + 400000 + 10)));
    
                expect(toDecimal(await nestBatchMining.balanceOf(usdt.address, addr1.address), 6)).eq(toDecimal(toBigInt(0, 6), 6));
                expect(toDecimal(await nestBatchMining.balanceOf(nest.address, addr1.address))).eq(toDecimal(toBigInt(200000)));

                console.log('price: ');
                let nestPrice = await ethers.getContractAt('INestBatchPriceView', nestBatchMining.address);
                let list = await nestPrice.lastPriceList(0, 0, 3);
                for (var i = 0; i < list.length; i += 2) {
                    console.log({
                        bn: list[i].toString(),
                        price: list[i+1].toString()
                    });
                }
            }

            
            if (true) {
                console.log('4. stat');
                const prices = [
                    toBigInt(4444, 6), 
                    toBigInt(1834, 6), 
                    toBigInt(400, 6), 
                    toBigInt(3240, 6), 
                    toBigInt(2108, 6), 
                    toBigInt(3333, 6),
                    toBigInt(1987, 6)
                ];

                for (var i = 0; i < prices.length; ++i) {
                    await skipBlocks(i);
                    const price = prices[i];
                    let receipt = await nestBatchMining.post(0, 1, [price], { value: toBigInt(POSTFEE + 1) });
                    await showReceipt(receipt);
                }

                await skipBlocks(20);
                //await nestBatchMining.stat(0);

                let nq = await ethers.getContractAt('INestBatchPriceView', nestBatchMining.address);
                //let pi = await nq.triggeredPriceInfo(0, 0);
                //console.log(UI(pi));
                
                let list = await nestBatchMining.list(0, 0, 0, (await nestBatchMining.list(0, 0, 0, 1, 0))[0].index + 1, 1);
                for (var i = 0; i < list.length; ++i) {
                    console.log(UI(list[i]));
                }

                let sigmaSQ = 0;
                let avgPrice = 0;
                let prevPrice = 0;
                let prevBN = 0;
                for (var i = 0; i < list.length; ++i) {
                    let p = list[i];
                    let bn = parseInt(p.height);
                    let price = toDecimal(p.price, 6);
                    let remain = parseInt(p.remainNum);

                    if (remain == 0) {
                        continue;
                    }

                    if (prevPrice == 0) {
                        avgPrice = price;
                        sigmaSQ = 0;
                    } else {
                        avgPrice = avgPrice * 0.9 + price * 0.1;
                        let r = (price - prevPrice) / prevPrice;
                        sigmaSQ = sigmaSQ * 0.9 + r * r / (bn - prevBN) / 14 * 0.1;
                    }

                    prevPrice = price;
                    prevBN = bn;
                }

                console.log({
                    avgPrice: avgPrice,
                    sigmaSQ: sigmaSQ
                });
                // console.log({
                //     avgPrice: toDecimal(pi.avgPrice, 6),
                //     sigmaSQ: toDecimal(pi.sigmaSQ)
                // })
            }
        }
    });
});
