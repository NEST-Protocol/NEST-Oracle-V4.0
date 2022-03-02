const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth, hbtc,

            nestGovernance, nestLedger,
            nestOpenMining, nestBatchPlatform2New
        } = await deploy();
        
        console.log('ok');
        const NestBatchPlatform2New = await ethers.getContractFactory('NestBatchPlatform2New');
        const nestBatchPlatform2New2 = await NestBatchPlatform2New.deploy();
        console.log('nestBatchPlatform2New2: ' + nestBatchPlatform2New2.address);

        // await nestBatchPlatform2New.open(
        //     pusd.address,
        //     toBigInt(2000),
        //     nest.address,
        //     [peth.address, nest.address, hbtc.address], {
        //         rewardPerBlock: 1000000000000000000n, 
        //         // Post fee(0.0001eth, DIMI_ETHER). 1000
        //         postFeeUnit: 0,
        //         // Single query fee (0.0001 ether, DIMI_ETHER). 100
        //         singleFee: 2,
        //         // Reduction rate(10000 based). 8000
        //         reductionRate: 8000
        //     }
        // );
        //await hbtc.transfer(owner.address, toBigInt(10000000));

        return;
        // const newNestOpenMining = await NestOpenMining.deploy();
        // console.log('newNestOpenMining: ' + newNestOpenMining.address);
    });
});
