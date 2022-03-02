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
            owner.address, //nestMining.address,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000', //nestMining.address,
            '0x0000000000000000000000000000000000000000',
            '0x0000000000000000000000000000000000000000'
        );
        await nhbtc.update(nestGovernance.address);
        await nhbtc.increaseTotal(1);
        await nhbtc.approve(nestOpenMining.address, 1);
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

        await nestOpenMining.open(
            usdt.address,
            2000000000n,
            nhbtc.address,
            '0x0000000000000000000000000000000000000000',
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
        await nestOpenMining.increaseNToken(0, 5000000000000000000000000000n);
        console.log(await getStatus());

        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;

        let prev = BigInt(await nestOpenMining.balanceOf(nhbtc.address, owner.address));
        
        const TEST_PRIVATE = false;
        if (TEST_PRIVATE) {
            console.log('1. _reduction');
            const test = async function(bn, rt) {
                let n = await nestOpenMining._reduction(bn, rt);
                console.log('_reduction(' + bn + ', ' + rt + '): ' + n);
            }
            
            await test(0, 8000);
            await test(2399999, 8000);
            await test(2400000, 8000);
            await test(2400001, 8000);
            await test(4799999, 8000);
            await test(4800000, 8000);
            await test(23999999, 8000);
            await test(24000000, 8000);            
            await test(24000001, 8000);            
            await test(25000001, 8000);            
            await test(26000001, 8000);            
            await test(28000001, 8000);            
            await test(28000000001, 8000);            

        }

        if (TEST_PRIVATE) {
            console.log('1. _encodeFloat');
            const test = async function test(n) {
                let e = BigInt(await nestOpenMining._encodeFloat(n));
                let d = BigInt(await nestOpenMining._decodeFloat(e));

                console.log(UI({
                    n, e, d
                }));

                expect((n - d) * 10000000000000n / n).to.eq(0n);
            }
            
            for (var n = 999n; n < 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; n *= 7n) {
                await test(n);
            }
        }
    });
});
