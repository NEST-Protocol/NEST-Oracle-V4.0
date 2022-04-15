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
    const NestBatchMining = await ethers.getContractFactory('NestBatchPlatform2');

    console.log('** Deploy: kcc_main@20220329.js **');

    // PETH:0x6cce8b9da777Ab10B11f4EA8510447431ED6ad1E
    // PUSD:0x0C4CD7cA70172Af5f4BfCb7b0ACBf6EdFEaFab31
    // PBTC:0x32D4a9a94537a88118e878c56b93009Af234A6ce
    // NEST:0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7

    //     ** Deploy: kcc_main@20220329.js **
    // peth: 0x6cce8b9da777Ab10B11f4EA8510447431ED6ad1E
    // pusd: 0x0C4CD7cA70172Af5f4BfCb7b0ACBf6EdFEaFab31
    // pbtc: 0x32D4a9a94537a88118e878c56b93009Af234A6ce
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestBatchMining: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    // proxyAdmin: 0x91acf819AC1c4f47C9298fC1D50F8561aC9Bb26E

    // 1. Deploy dependent contract
    //const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x6cce8b9da777Ab10B11f4EA8510447431ED6ad1E');
    console.log('peth: ' + peth.address);

    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x0C4CD7cA70172Af5f4BfCb7b0ACBf6EdFEaFab31');
    console.log('pusd: ' + pusd.address);

    //const pbtc = await TestERC20.deploy('PBTC', 'PBTC', 18);
    const pbtc = await TestERC20.attach('0x32D4a9a94537a88118e878c56b93009Af234A6ce');
    console.log('pbtc: ' + pbtc.address);

    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7');
    console.log('nest: ' + nest.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchMining = await NestBatchMining.attach('0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6');
    console.log('nestBatchMining: ' + nestBatchMining.address);

    // console.log('1. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestPriceFacade.address,
    //     '0x0000000000000000000000000000000000000000',
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nnIncome.address,
    //     '0x0000000000000000000000000000000000000000'  //nTokenController.address
    // );

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
    // });

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        peth: peth,
        nest: nest,
        pusd: pusd,
        pbtc: pbtc,

        nestGovernance: nestGovernance,
        nestBatchMining: nestBatchMining
    };

    return contracts;
};