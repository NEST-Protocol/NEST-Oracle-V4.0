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
    const NestOpenMining = await ethers.getContractFactory('NestOpenPlatform');
    const NestVote = await ethers.getContractFactory('NestVote');

    console.log('** 开始部署合约 bsc_test@20211119.js **');
    
    // ** 开始部署合约 bsc_test@20211119.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277

    // 1. 部署依赖合约
    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);
    
    // TODO: 确定跨链PUSD地址
    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x3DA5c9aafc6e6D6839E62e2fB65825869019F291');
    console.log('pusd: ' + pusd.address);

    // TODO: 确定跨链PETH地址
    //const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0xc39dC1385a44fBB895991580EA55FC10e7451cB3');
    console.log('peth: ' + peth.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x5691dc0770D55B9469a3242DA282754687687935');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    const nestLedger = await NestLedger.attach('0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE');
    console.log('nestLedger: ' + nestLedger.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestOpenMining = await NestOpenMining.attach('0xF2f9E62f52389EF223f5Fa8b9926e95386935277');
    console.log('nestOpenMining: ' + nestOpenMining.address);

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
    // //console.log('5. nestPriceFacade.update()');
    // //await nestPriceFacade.update(nestGovernance.address);
    // // console.log('6. nestVote.update()');
    // // await nestVote.update(nestGovernance.address);
    // //console.log('7. nTokenController.update()');
    // //await nTokenController.update(nestGovernance.address);
    // //console.log('8. nnIncome.update()');
    // // await nnIncome.update(nestGovernance.address);
    // // console.log('9. nestRedeeming.update()');
    // // await nestRedeeming.update(nestGovernance.address);

    // console.log('10. nestOpenMining.setConfig()');
    // await nestOpenMining.setConfig({
    //     // // Eth number of each post. 30
    //     // // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
    //     // postEthUnit: 30,

    //     // // Post fee(0.0001eth，DIMI_ETHER). 1000
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

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        //nestMining: nestMining,
        nestOpenMining: nestOpenMining,
        //nestPriceFacade: nestPriceFacade,
        //nestVote: nestVote,
        // nTokenController: nTokenController,
        // nestRedeeming: nestRedeeming
    };

    return contracts;
};