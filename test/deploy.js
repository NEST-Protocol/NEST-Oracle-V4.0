const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        // const { 
        //     eth, nest, pusd, peth, hbtc,

        //     nestGovernance, nestLedger,
        //     nestOpenMining, nestBatchPlatform2
        // } = await deploy();
        
        console.log('ok');

        const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');
        const toPi = function(p) {
            return {
                target: p.target.toString(),
                sheetCount: p.sheetCount.toString()
            };
        }
        const toCi = function(c) {
            let pairs = [];
            for (var i = 0; i < c.pairs.length; ++i) {
                pairs.push(toPi(c.pairs[i]));
            }
            return {
                channelId: c.channelId.toString(),
                token0: c.token0.toString(),
                unit: c.unit.toString(),
                reward: c.reward.toString(),
                rewardPerBlock: c.rewardPerBlock.toString(),
                vault: c.vault.toString(),
                rewards: c.rewards.toString(),
                postFeeUnit: c.postFeeUnit.toString(),
                count: c.count.toString(),
                opener: c.opener.toString(),
                genesisBlock: c.genesisBlock.toString(),
                singleFee: c.singleFee.toString(),
                reductionRate: c.reductionRate.toString(),
                pairs: pairs
            };
        }
        const toChannelConfig = function(ci) {
            return {
                rewardPerBlock: ci.rewardPerBlock,
                postFeeUnit: ci.postFeeUnit,
                singleFee: ci.singleFee,
                reductionRate: ci.reductionRate
            };
        }

        // if (false) {
        //     // 2022-05-08 10:00 Deploy and update NNIncome
        //     // 1. Deploy contract
        //     const NNIncome = await ethers.getContractFactory('NNIncome');
        //     const newNNIncome = await NNIncome.deploy();
        //     console.log('newNNIncome: ' + newNNIncome.address);

        //     // 2. Verify contract code
        //     // 3. Update implementation
        //     // Proxy: 0x95557DE67444B556FE6ff8D7939316DA0Aa340B2
        //     // ProxyAdmin: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6

        //     // 4. Check view methods, eg. earned
        //     return;
        // }

        // if (false) {
        //     // 2022-05-08 10:30 Deploy and update NestBatchMining
        //     // 1. Deploy contract
        //     const newNestBatchPlatform2 = await NestBatchPlatform2.deploy();
        //     console.log('newNestBatchPlatform2: ' + newNestBatchPlatform2.address);

        //     // 2. Verify contract code
        //     // 3. Update implementation
        //     // Proxy: 0xE544cF993C7d477C7ef8E91D28aCA250D135aa03
        //     // ProxyAdmin: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6

        //     // 4. Check view methods. eg. earned
        //     return;
        // }

        // if (true) {
        //     // 2022-05-08 10:00 Add eth&nest to channel 0

        //     const nestBatchPlatform = await NestBatchPlatform2.attach('0xE544cF993C7d477C7ef8E91D28aCA250D135aa03');
        //     // // 1. Add eth pair
        //     // await nestBatchPlatform.addPair(0, '0x0000000000000000000000000000000000000000');
        //     // // 2. Add nest pair
        //     // await nestBatchPlatform.addPair(0, nest.address);
        //     // 3. Check channel info
        //     console.log(toCi(await nestBatchPlatform.getChannelInfo(0)));

        //     return;
        // }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
        // 2022-05-08 10:00 Adjust nest reward speed

        // // ETH
        // if (false) {
        //     const nestBatchPlatform = await NestBatchPlatform2.attach('0xE544cF993C7d477C7ef8E91D28aCA250D135aa03');
        //     const c = await nestBatchPlatform.getChannelInfo(0);
        //     const ci = toCi(c);

        //     console.log(ci);
        //     console.log(toChannelConfig(ci));
        //     ci.rewardPerBlock = '24000000000000000000';
        //     ci.singleFee = '0';
        //     // console.log(toChannelConfig(ci));

        //     // Update
        //     //await nestBatchPlatform.modify(0, ci);

        //     // Check
        //     return;
        // }

        // // BSC
        // if (true) {
        //     const nestBatchPlatform = await NestBatchPlatform2.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
        //     const c = await nestBatchPlatform.getChannelInfo(0);
        //     const ci = toCi(c);

        //     console.log(ci);
        //     console.log(toChannelConfig(ci));
        //     ci.rewardPerBlock = '1000000000000000000';
        //     ci.singleFee = '0';
        //     console.log(toChannelConfig(ci));

        //     // Update
        //     //await nestBatchPlatform.modify(0, ci);

        //     // Check

        //     return;
        // }

        // // Polygon
        // if (true) {
        //     const nestBatchPlatform = await NestBatchPlatform2.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
        //     const c = await nestBatchPlatform.getChannelInfo(0);
        //     const ci = toCi(c);

        //     console.log(ci);
        //     console.log(toChannelConfig(ci));
        //     ci.rewardPerBlock = '300000000000000000';
        //     ci.singleFee = '0';
        //     console.log(toChannelConfig(ci));

        //     // Update
        //     //await nestBatchPlatform.modify(0, ci);

        //     // Check
        // }

        // KCC
        if (true) {
            const nestBatchPlatform = await NestBatchPlatform2.attach('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
            const c = await nestBatchPlatform.getChannelInfo(0);
            const ci = toCi(c);

            console.log(ci);
            console.log(toChannelConfig(ci));
            ci.rewardPerBlock = '100000000000000000';
            ci.singleFee = '0';
            console.log(toChannelConfig(ci));

            // Update
            //await nestBatchPlatform.modify(0, ci);

            // Check
        }

        // const nm = await ethers.getContractAt('INestMining', '0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd');
        // const cfg = await nm.getConfig();
        // console.log(cfg);
        // const ccc = {
        //     postEthUnit: cfg.postEthUnit.toString(),
        //     postFeeUnit: cfg.postFeeUnit.toString(),
        //     minerNestReward: cfg.minerNestReward.toString(),
        //     minerNTokenReward: cfg.minerNTokenReward.toString(),
        //     doublePostThreshold: cfg.doublePostThreshold.toString(),
        //     ntokenMinedBlockLimit: cfg.ntokenMinedBlockLimit.toString(),
        //     maxBiteNestedLevel: cfg.maxBiteNestedLevel.toString(),
        //     priceEffectSpan: cfg.priceEffectSpan.toString(),
        //     pledgeNest: cfg.pledgeNest.toString()
        // };
        // console.log(ccc);
        // console.log('after modify');
        // ccc.postEthUnit = '0';
        // console.log(ccc);
        // //await nm.setConfig(ccc);
        // return;
    });
});
