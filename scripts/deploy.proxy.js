// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    const IterableMapping = await ethers.getContractFactory('IterableMapping');
    const iterableMapping = await IterableMapping.deploy();
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const IBNEST = await ethers.getContractFactory('IBNEST', {
        libraries: {
            IterableMapping: iterableMapping.address
        }
    });
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestLedger = await ethers.getContractFactory('NestLedger');
    const NestBatchMining = await ethers.getContractFactory('NestBatchPlatform2');

    console.log('** Deploy: deploy.proxy.js **');
    
    // 1. Deploy dependent contract
    const nest = await IBNEST.deploy();
    //const nest = await IBNEST.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const usdc = await TestERC20.deploy('USDC', 'USDC', 18);
    //const usdc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdc: ' + usdc.address);

    const cofi = await TestERC20.deploy('COFI', 'COFI', 18);
    //const cofi = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('cofi: ' + cofi.address);

    const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    //const hbtc = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('hbtc: ' + hbtc.address);

    const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    //const nestGovernance = await NestGovernance.attach('0x0000000000000000000000000000000000000000');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    //const nestLedger = await NestLedger.attach('0x0000000000000000000000000000000000000000');
    console.log('nestLedger: ' + nestLedger.address);

    const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    //const nestBatchMining = await NestBatchMining.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBatchMining: ' + nestBatchMining.address);

    console.log('1. nestGovernance.setBuiltinAddress()');
    await nestGovernance.setBuiltinAddress(
        nest.address,
        '0x0000000000000000000000000000000000000000',
        nestLedger.address,
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nestPriceFacade.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000', //nestMining.address,
        '0x0000000000000000000000000000000000000000', //nnIncome.address,
        '0x0000000000000000000000000000000000000000'  //nTokenController.address
    );

    console.log('2. nestLedger.update()');
    await nestLedger.update(nestGovernance.address);

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

    // console.log('11. nestOpenMining.open()');
    // await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,
        usdc: usdc,
        cofi: cofi,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestBatchMining: nestBatchMining
    };

    return contracts;
};