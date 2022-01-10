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

    console.log('** 开始部署合约 mumbai@20220110.js **');
    
    // 1. 部署依赖合约
    const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    nest.deployTransaction.wait(1);
    //const nest = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('nest: ' + nest.address);

    const usdt = await TestERC20.deploy('USDT', 'USDT', 6);
    usdt.deployTransaction.wait(1);
    //const usdt = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('usdt: ' + usdt.address);

    const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    pusd.deployTransaction.wait(1);
    //const pusd = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('pusd: ' + pusd.address);

    const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    peth.deployTransaction.wait(1);
    //const peth = await TestERC20.attach('0x0000000000000000000000000000000000000000');
    console.log('peth: ' + peth.address);

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
        priceEffectSpan: 50,

        // The amount of nest to pledge for each post (Unit: 1000). 100
        pledgeNest: 100
    });

    // console.log('11. nestOpenMining.open()');
    // await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        usdt: usdt,
        pusd: pusd,
        peth: peth,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestBatchMining: nestBatchMining,
        nestVote: nestVote,
    };

    return contracts;
};