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

        const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');

        if (false) {
            // 2022-05-08 10:00 Deploy and update NNIncome
            const NNIncome = await ethers.getContractFactory('NNIncome');
            const newNNIncome = await NNIncome.deploy();
            console.log('newNNIncome: ' + newNNIncome.address);
        }

        if (false) {
            // 2022-05-08 10:00 Deploy and update NestBatchMining
            const newNestBatchPlatform2 = await NestBatchPlatform2.deploy();
            console.log('newNestBatchPlatform2: ' + newNestBatchPlatform2.address);
        }

        if (false) {
            // 2022-05-08 10:00 Add eth&nest to channel 0
            const nestBatchPlatform = await NestBatchPlatform2.attach('xxx');
            await nestBatchPlatform.addPair(0, '0x0000000000000000000000000000000000000000');
            await nestBatchPlatform.addPair(0, nest.address);
        }

        ////////////////////////////////////////////////////////////////////////////////////////////////////////////////
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

        // 2022-05-08 10:00 Adjust nest reward speed

        // ETH
        if (true) {
            const nestBatchPlatform = await NestBatchPlatform2.attach('0xE544cF993C7d477C7ef8E91D28aCA250D135aa03');
            const c = await nestBatchPlatform.getChannelInfo(0);
            const ci = toCi(c);

            console.log(ci);
            console.log(toChannelConfig(ci));
            ci.rewardPerBlock = '24000000000000000000';
            ci.singleFee = '0';
            console.log(toChannelConfig(ci));
        }

        // BSC
        if (false) {
            const nestBatchPlatform = await NestBatchPlatform2.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
            const c = await nestBatchPlatform.getChannelInfo(0);
            const ci = toCi(c);

            console.log(ci);
            console.log(toChannelConfig(ci));
            ci.rewardPerBlock = '1000000000000000000';
            ci.singleFee = '0';
            console.log(toChannelConfig(ci));
        }

        // Polygon
        if (false) {
            const nestBatchPlatform = await NestBatchPlatform2.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
            const c = await nestBatchPlatform.getChannelInfo(0);
            const ci = toCi(c);

            console.log(ci);
            console.log(toChannelConfig(ci));
            ci.rewardPerBlock = '300000000000000000';
            ci.singleFee = '0';
            console.log(toChannelConfig(ci));
        }

        // KCC
        if (false) {
            const nestBatchPlatform = await NestBatchPlatform2.attach('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
            const c = await nestBatchPlatform.getChannelInfo(0);
            const ci = toCi(c);

            console.log(ci);
            console.log(toChannelConfig(ci));
            ci.rewardPerBlock = '100000000000000000';
            ci.singleFee = '0';
            console.log(toChannelConfig(ci));
        }
    });
});
