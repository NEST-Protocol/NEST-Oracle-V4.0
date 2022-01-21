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
    const NestBatchMining = await ethers.getContractFactory('NestBatchPlatform2');
    const NestVote = await ethers.getContractFactory('NestVote');

    console.log('** 开始部署合约 polygon_main@20220121.js **');
    
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // pusd: 0xf26D86043a3133Cc042221Ea178cAED7Fe0eE362
    // peth: 0x1E0967e10B5Ef10342d4D71da69c30332666C899
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestLedger: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    // nestBatchMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540

    // proxyAdmin: 0x91acf819AC1c4f47C9298fC1D50F8561aC9Bb26E

    // 1. 部署依赖合约
    const nest = await TestERC20.attach('0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7');
    console.log('nest: ' + nest.address);

    const pusd = await TestERC20.attach('0xf26D86043a3133Cc042221Ea178cAED7Fe0eE362');
    console.log('pusd: ' + pusd.address);

    const peth = await TestERC20.attach('0x1E0967e10B5Ef10342d4D71da69c30332666C899');
    console.log('peth: ' + peth.address);

    // TODO: 根据DCU的部署情况，观察脚本返回的合约地址是否正确
    // 部署nestGovernance时，需要即时备份openzeeplin的数据文件，以便在得不到正确地址时，可以手动修改

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    const nestLedger = await NestLedger.attach('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
    console.log('nestLedger: ' + nestLedger.address);

    //const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchMining = await NestBatchMining.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestBatchMining: ' + nestBatchMining.address);

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
    //     , { nonce: 7 }
    // );

    // console.log('2. nestLedger.update()');
    // await nestLedger.update(nestGovernance.address);

    // console.log('5. nestBatchMining.update()');
    // await nestBatchMining.update(nestGovernance.address);

    // console.log('11. nestBatchMining.setConfig()');
    // await nestBatchMining.setConfig({
    //     // -- Public configuration
    //     // The number of times the sheet assets have doubled. 4
    //     maxBiteNestedLevel: 4,
        
    //     // Price effective block interval. 20
    //     priceEffectSpan: 50,

    //     // The amount of nest to pledge for each post (Unit: 1000). 100
    //     pledgeNest: 100
    // }, { nonce: 8 });

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        peth: peth,
        pusd: pusd,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestBatchMining: nestBatchMining,
    };

    return contracts;
};