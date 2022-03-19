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

    console.log('** Deploy: kcc_test@20220319.js **');

    // ** Deploy: kcc_test@20220319.js **
    // nest: 0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F
    // usdt: 0x17322b20752cC7d6094209f6Fa73275375Cf7B27
    // hbtc: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // nestGovernance: 0xEB8b3c263A32C3f098Fb0Da0F7855E2E98D75971
    // nestBatchMining: 0xF331D5C0E36Cc8a575D185b1D513715be55087E4
    // proxyAdmin: 0x93B7508CD7b9aE755dA7F42A334F7AAcc1fc3987

    // 1. Deploy dependent contract
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0x17322b20752cC7d6094209f6Fa73275375Cf7B27');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x5cbb73B367FD69807381d06BC2041BEc86d8487d');
    console.log('hbtc: ' + hbtc.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xEB8b3c263A32C3f098Fb0Da0F7855E2E98D75971');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchMining = await NestBatchMining.attach('0xF331D5C0E36Cc8a575D185b1D513715be55087E4');
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

    // console.log('11. nestOpenMining.open()');
    // await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestBatchMining: nestBatchMining,
    };

    return contracts;
};