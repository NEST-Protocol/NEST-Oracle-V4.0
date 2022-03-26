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
    
    // 1. Deploy dependent contract
    // TODO: 确定地址
    //const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('peth: ' + peth.address);

    // TODO: 确定地址
    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pusd: ' + pusd.address);

    // TODO: 确定地址
    //const pbtc = await TestERC20.deploy('PBTC', 'PBTC', 18);
    const pbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pbtc: ' + pbtc.address);

    // TODO: 确定地址
    // TODO: 修改代码中的NEST地址常量
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const nestGovernance = await NestGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    //const nestBatchMining = await NestBatchMining.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBatchMining: ' + nestBatchMining.address);

    console.log('1. nestGovernance.setBuiltinAddress()');
    await nestGovernance.setBuiltinAddress(
        nest.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nestPriceFacade.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nnIncome.address,
        '0x0000000000000000000000000000000000000000'  //nTokenController.address
    );

    console.log('5. nestBatchMining.update()');
    await nestBatchMining.update(nestGovernance.address);

    console.log('11. nestBatchMining.setConfig()');
    await nestBatchMining.setConfig({
        // -- Public configuration
        // The number of times the sheet assets have doubled. 4
        maxBiteNestedLevel: 4,
        
        // Price effective block interval. 20
        priceEffectSpan: 20,

        // The amount of nest to pledge for each post (Unit: 1000). 100
        pledgeNest: 100
    });

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