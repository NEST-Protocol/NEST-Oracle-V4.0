const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth, usdt,

            nestGovernance, nestLedger,
            nestOpenMining, nestBatchMining
        } = await deploy();
        
        console.log('ok');
        
        // await nestBatchMining.open(
        //     pusd.address, 
        //     2000000000000000000000n, 
        //     nest.address, 
        //     [peth.address, nest.address], {
        //         // 每个区块的标准出矿量
        //         rewardPerBlock: 1000000000000000000n,

        //         // 矿币总量
        //         //uint96 vault;

        //         // 管理地址
        //         //address governance;
        //         // 创世区块
        //         //uint32 genesisBlock;
        //         // Post fee(0.0001eth，DIMI_ETHER). 1000
        //         postFeeUnit: 0,
        //         // Single query fee (0.0001 ether, DIMI_ETHER). 100
        //         singleFee: 20,
        //         // 衰减系数，万分制。8000
        //         reductionRate: 8000
        //     }
        // );

        // await nest.transfer(owner.address, 100000000000000000000000000n);
        await nest.approve(nestBatchMining.address, 1000000000000000000000000000000n)
        await nestBatchMining.increase(0, 100000000000000000000000000n);
    });
});
