// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestLedger = await ethers.getContractFactory('NestLedger');
    const NestBatchPlatform2New = await ethers.getContractFactory('NestBatchPlatform2New');
    const NestVote = await ethers.getContractFactory('NestVote');

    console.log('** Deploy: bsc@20220305.js **');
    
    //     ** Deploy: bsc@20220305.js **
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // pusd: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // peth: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // pbtc: 0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestLedger: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // proxyAdmin: 0x91acf819AC1c4f47C9298fC1D50F8561aC9Bb26E

    // 1. Deploy dependent contract
    const pbtc = await TestERC20.attach('0x46893c30fBDF3A5818507309c0BDca62eB3e1E6b');
    console.log('pbtc: ' + pbtc.address);

    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7');
    console.log('nest: ' + nest.address);

    //const pusd = await TestERC20.deploy('USDT', 'USDT', 18);
    const pusd = await TestERC20.attach('0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2');
    console.log('pusd: ' + pusd.address);

    //const peth = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const peth = await TestERC20.attach('0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB');
    console.log('peth: ' + peth.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    const nestLedger = await NestLedger.attach('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
    console.log('nestLedger: ' + nestLedger.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchPlatform2New = await NestBatchPlatform2New.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestBatchPlatform2New: ' + nestBatchPlatform2New.address);

    // console.log('1. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestLedger.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestPriceFacade.address,
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nnIncome.address,
    //     '0x0000000000000000000000000000000000000000'  //nTokenController.address
    // );

    // console.log('2. nestLedger.update()');
    // await nestLedger.update(nestGovernance.address);
    // //console.log('3. nestMining.update()');
    // //await nestMining.update(nestGovernance.address);
    // console.log('4. nestOpenMining.update()');
    // await nestOpenMining.update(nestGovernance.address);
    //console.log('5. nestPriceFacade.update()');
    //await nestPriceFacade.update(nestGovernance.address);
    // console.log('6. nestVote.update()');
    // await nestVote.update(nestGovernance.address);
    //console.log('7. nTokenController.update()');
    //await nTokenController.update(nestGovernance.address);
    //console.log('8. nnIncome.update()');
    // await nnIncome.update(nestGovernance.address);
    // console.log('9. nestRedeeming.update()');
    // await nestRedeeming.update(nestGovernance.address);

    // console.log('10. nestOpenMining.setConfig()');
    // await nestOpenMining.setConfig({
    //     // // Eth number of each post. 30
    //     // // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
    //     // postEthUnit: 30,

    //     // // Post fee(0.0001eth, DIMI_ETHER). 1000
    //     // postFeeUnit: 1000,

    //     // // Proportion of miners digging(10000 based). 8000
    //     // minerNestReward: 8000,
        
    //     // // The proportion of token dug by miners is only valid for the token created in version 3.0
    //     // // (10000 based). 9500
    //     // minerNTokenReward: 9500,

    //     // // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
    //     // doublePostThreshold: 500,
        
    //     // // The limit of ntoken mined blocks. 100
    //     // ntokenMinedBlockLimit: 100,

    //     // -- Public configuration
    //     // The number of times the sheet assets have doubled. 4
    //     maxBiteNestedLevel: 4,
        
    //     // Price effective block interval. 20
    //     priceEffectSpan: 50,

    //     // The amount of nest to pledge for each post (Unit: 1000). 100
    //     pledgeNest: 100
    // });

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        pusd: pusd,
        peth: peth,
        pbtc: pbtc,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        //nestMining: nestMining,
        nestBatchPlatform2New: nestBatchPlatform2New,
        //nestPriceFacade: nestPriceFacade,
        //nestVote: nestVote,
        // nTokenController: nTokenController,
        // nestRedeeming: nestRedeeming
    };

    return contracts;
};