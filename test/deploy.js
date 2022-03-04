const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth, hbtc, pbtc,

            nestGovernance, nestLedger,
            nestOpenMining, nestBatchPlatform2New
        } = await deploy();
        
        console.log('ok');

        // 将NEST4.1@bsc升级为NEST4.3@bsc，在确定准备工作完成后

        // 相关信息
        // proxyAdmin: 0x91acf819AC1c4f47C9298fC1D50F8561aC9Bb26E
        // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
        // oldNestOpenMiningImpl: 0xf74A8434eaF7Ec9Ba0A43487aCaDf97e6f85D6C7
        // PUSD: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
        // PETH: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
        // NEST: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
        // PBTC: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b

        // 步骤
        // 1.	部署新的批量报价合约，并记录合约地址，并在bscscan上验证合约代码
        // 2.	从PETH|PUSD和NEST|PUSD报价通道取出剩余的矿币，并记录数量
        // 3.	将PETH|PUSD和NEST|PUSD报价通道的BNB转入到DAO地址，并记录数量(跟james确定如何处理，DAO是哪个DAO？)
        // 4.	通过proxyAdmin将报价合约的实现更新为步骤1中部署的合约地址（注意记录更新前状态以便核对）
        // 5.	通过合约只读方法验证更新后，数据是否正确对齐
        // 6.	在新的报价合约开通PETH&NEST&PBTC|PUSD报价通道，并确保channelId为0，PETH、NEST、PBTC的报价对编号分别为0、1、2
        // 7.	将步骤2中取出的矿币，全部注入到新开通的报价通道，并记录总数
        // 8.	通知王露露检查合约参数
        // 9.	通知王露露报价，并观察，验证吃单逻辑
        // 10.	分别查询PETH、NEST、PBTC的新报价和历史报价，验证查询数据是否正确
        const NestBatchPlatform2New = await ethers.getContractFactory('NestBatchPlatform2New');
        const newNestBatchPlatform2New = await NestBatchPlatform2New.deploy();
        console.log('newNestBatchPlatform2New: ' + newNestBatchPlatform2New.address);
        return;

        // 开通后，确定channelId为0，peth、nest、pbtc的pairIndex分别为0、1、2
        await nestBatchPlatform2New.open(
            pusd.address,
            toBigInt(2000),
            nest.address,
            [peth.address, nest.address, pbtc.address], {
                // Reward per block standard
                rewardPerBlock: 5000000000000000000n,

                // Post fee(0.0001eth, DIMI_ETHER). 1000
                postFeeUnit: 0,

                // Single query fee (0.0001 ether, DIMI_ETHER). 100
                singleFee: 2,

                // Reduction rate(10000 based). 8000
                reductionRate: 8000
            }
        );

        return;

        // TODO: 确保channelId为0，并确定注入nest数量
        await nestBatchPlatform2New.increase(0, 0n);
        return;
    });
});
