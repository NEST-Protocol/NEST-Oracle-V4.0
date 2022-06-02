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

    console.log('** Deploy: bsc@20211120.js **');
    
    //     ** Deploy: bsc@20211120.js **
    // nest: 0x98f8669F6481EbB341B522fCD3663f79A3d1A6A7
    // pusd: 0x9b2689525e07406D8A6fB1C40a1b86D2cd34Cbb2
    // peth: 0x556d8bF8bF7EaAF2626da679Aa684Bac347d30bB
    // nestGovernance: 0x7b5ee1Dc65E2f3EDf41c798e7bd3C22283C3D4bb
    // nestLedger: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    // nestOpenMining: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    // proxyAdmin: 0x91acf819AC1c4f47C9298fC1D50F8561aC9Bb26E

    // 1. Deploy dependent contract
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
    const nestOpenMining = await NestOpenMining.attach('0x09CE0e021195BA2c1CDE62A8B187abf810951540');
    console.log('nestOpenMining: ' + nestOpenMining.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        pusd: pusd,
        peth: peth,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestOpenMining: nestOpenMining,
    };

    return contracts;
};