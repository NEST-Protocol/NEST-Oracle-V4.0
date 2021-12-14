const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth, hbtc,

            nestGovernance, nestLedger,
            nestOpenMining, nestBatchPlatform2
        } = await deploy();
        
        console.log('ok');
        
        //await nest.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        //await pusd.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        //await hbtc.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        
        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0n;
        const EFFECT_BLOCK = 50;

        //await hbtc.transfer(owner.address, 10000000000000000000000000n);

        // let receipt = await nestBatchPlatform2.post(0, 1, [60000000000n], {
        //     value: toBigInt(POSTFEE) + 10000000000n * GASLIMIT
        // });

        // await nestBatchPlatform2.open({
        //     // 计价代币地址, 0表示eth
        //     token0: pusd.address,
        //     // 计价代币单位
        //     unit: 2000000000000000000000n,
    
        //     // 报价代币地址，0表示eth
        //     //token1: usdt.address,
        //     // 每个区块的标准出矿量
        //     rewardPerBlock: 1000000000000000000n,
    
        //     // 矿币地址如果和token0或者token1是一种币，可能导致挖矿资产被当成矿币挖走
        //     // 出矿代币地址
        //     reward: nest.address,
        //     // 矿币总量
        //     //uint96 vault;
    
        //     // 管理地址
        //     //address governance;
        //     // 创世区块
        //     //uint32 genesisBlock;
        //     // Post fee(0.0001eth，DIMI_ETHER). 1000
        //     postFeeUnit: 1000,
        //     // Single query fee (0.0001 ether, DIMI_ETHER). 100
        //     singleFee: 10,
        //     // 衰减系数，万分制。8000
        //     reductionRate: 8000,

        //     tokens: [hbtc.address]
        // });

        // await nest.approve(nestBatchPlatform2.address, 1000000000000000000000000n);
        // await nestBatchPlatform2.increase(0, 1000000000000000000000000n);
    });
});
