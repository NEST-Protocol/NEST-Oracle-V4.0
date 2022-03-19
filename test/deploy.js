const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, usdt, hbtc,

            nestGovernance, nestLedger,
            nestBatchMining
        } = await deploy();
        
        console.log('ok');

        // await nestBatchMining.open(
        //     usdt.address,
        //     toBigInt(2000),
        //     nest.address,
        //     [nest.address, hbtc.address], {
        //         rewardPerBlock: 1000000000000000000n,
        //         postFeeUnit: 0,
        //         singleFee: 2,
        //         reductionRate: 8000
        //     }
        // );

        // await nest.transfer(owner.address, toBigInt(100000000));
        // await nest.approve(nestBatchMining.address, toBigInt(100000000));
        // await nestBatchMining.increase(0, toBigInt(100000000));
    });
});
