const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth,

            nestGovernance, nestLedger,
            nestOpenMining
        } = await deploy();
        
        console.log('ok');
        // const NestOpenMining = await ethers.getContractFactory('NestOpenPlatform');

        // const newNestOpenMining = await NestOpenMining.deploy();
        // console.log('newNestOpenMining: ' + newNestOpenMining.address);

        
        // await nestOpenMining.open({
        //     // 计价代币地址, 0表示eth
        //     token0: pusd.address,
        //     // 计价代币单位
        //     unit: toBigInt(2000),
            
        //     // 报价代币地址，0表示eth
        //     token1: nest.address,
        //     // 每个区块的标准出矿量
        //     rewardPerBlock: toBigInt(1),
            
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
        //     postFeeUnit: 0,
        //     // Single query fee (0.0001 ether, DIMI_ETHER). 100
        //     singleFee: 50,
        //     // 衰减系数，万分制。8000
        //     reductionRate: 8000
        // });

        //await nest.approve(nestOpenMining.address, toBigInt(20000000));
        //await nestOpenMining.increase(1, toBigInt(20000000));
        //console.log(await nest.balanceOf(owner.address) + 'nest');
    });
});
