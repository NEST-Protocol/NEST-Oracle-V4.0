const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();
        const NToken = await ethers.getContractFactory('NToken');

        const { 
            eth, nest, usdt, hbtc,

            nestGovernance, nestLedger,
            nestMining, nestOpenMining,
            nestPriceFacade, nestVote,
            nTokenController, nestRedeeming
        } = await deploy();
        
        console.log('ok');

        // await nest.approve(nestOpenMining.address, toBigInt(10000000000));
        // await usdt.approve(nestOpenMining.address, toBigInt(10000000000));
        // await hbtc.approve(nestOpenMining.address, toBigInt(10000000000));

        // await usdt.transfer(owner.address, toBigInt(10000000000));
        // await hbtc.transfer(owner.address, toBigInt(10000000000));

        // await nestOpenMining.open({
        //     // 计价代币地址, 0表示eth
        //     token0: eth.address,
        //     // 计价代币单位
        //     unit: 1000000000000000000n,
            
        //     // 报价代币地址，0表示eth
        //     token1: usdt.address,
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
        //     singleFee: 100,
        //     // 衰减系数，万分制。8000
        //     reductionRate: 8000
        // });
        //await nestOpenMining.increase(0, 50000000000000000000000000n);

        //await nest.transfer('0xd9f3aA57576a6da995fb4B7e7272b4F16f04e681', 5000000000000000000000000000n);

        //let receipt = await nestOpenMining.post(0, 1, toBigInt(4100), { value: toBigInt(1.108) });
        //await showReceipt(receipt);
        //let receipt = await nestOpenMining.close(0, [0]);
        //await showReceipt(receipt);
    });
});
