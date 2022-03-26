const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, pbtc, peth,

            nestGovernance, nestLedger,
            nestBatchMining
        } = await deploy();
        
        console.log('ok');

        return;
        await nestBatchMining.open(
            pusd.address,
            toBigInt(2000),
            nest.address,
            [peth.address, nest.address, pbtc.address], {
                // Reward per block standard
                rewardPerBlock: 1000000000000000000n,

                // Post fee(0.0001eth, DIMI_ETHER). 1000
                postFeeUnit: 0,

                // Single query fee (0.0001 ether, DIMI_ETHER). 100
                singleFee: 20,

                // Reduction rate(10000 based). 8000
                reductionRate: 8000
            }
        );

        return;
        //await nest.transfer(owner.address, toBigInt(100000000));
        await nest.approve(nestBatchMining.address, toBigInt(100000000));
        await nestBatchMining.increase(0, toBigInt(100000000));
    });
});
