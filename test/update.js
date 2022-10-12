const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('update', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { nest, usdt, hbtc, cofi, usdc, nestBatchPlatform2 } = await deploy();
        console.log('ok');

        {
            const config = await nestBatchPlatform2.getConfig();
            console.log(UI(config));

            const ci = await nestBatchPlatform2.getChannelInfo(0);
            console.log(UI(ci));

            // await nestBatchPlatform2.modifyToken(0, 0, '0x102E6BBb1eBfe2305Ee6B9E9fd5547d0d39CE3B4');
            // await nestBatchPlatform2.modify(0, {
            //     rewardPerBlock: 20000000000000000000n,
            //     postFeeUnit: 0,
            //     singleFee: 0,
            //     reductionRate: 8000
            // });

            // // Price channel configuration
            // struct ChannelConfig {

            //     // Reward per block standard
            //     uint96 rewardPerBlock;

            //     // Post fee(0.0001eth, DIMI_ETHER). 1000
            //     uint16 postFeeUnit;

            //     // Single query fee (0.0001 ether, DIMI_ETHER). 100
            //     uint16 singleFee;

            //     // Reduction rate(10000 based). 8000
            //     uint16 reductionRate;
            // }
        }
        
        {
            const config = await nestBatchPlatform2.getConfig();
            console.log(UI(config));

            const ci = await nestBatchPlatform2.getChannelInfo(0);
            console.log(UI(ci));
        }
    });
});
