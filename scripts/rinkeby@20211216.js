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
    const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');

    console.log('** Deploy: rinkeby@20211216.js **');
    
    // ** Deploy: rinkeby@20211216.js **
    // pusd: 0x5407cab67ad304FB8A4aC46D83b3Dd63A9dbA575
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    // nestOpenMining: 0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF
    // nestBatchPlatform2: 0xc08E6A853241B9a08225EECf93F3b279FA7A1bE7
    // proxyAdmin: 0xfe40659D3DEbEBC3B5454Ad974401233b3D0E9bC

    // 1. Deploy dependent contract
    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x5407cab67ad304FB8A4aC46D83b3Dd63A9dbA575');
    console.log('pusd: ' + pusd.address);

    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0x20125a7256EFafd0d4Eec24048E08C5045BC5900');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B');
    console.log('hbtc: ' + hbtc.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    const nestLedger = await NestLedger.attach('0x005103e352f86e4C32a3CE4B684fe211eB123210');
    console.log('nestLedger: ' + nestLedger.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestOpenMining = await NestOpenMining.attach('0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF');
    console.log('nestOpenMining: ' + nestOpenMining.address);

    //const nestBatchPlatform2 = await upgrades.deployProxy(NestBatchPlatform2, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchPlatform2 = await NestBatchPlatform2.attach('0xc08E6A853241B9a08225EECf93F3b279FA7A1bE7');
    console.log('nestBatchPlatform2: ' + nestBatchPlatform2.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,
        pusd: pusd,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        //nestMining: nestMining,
        nestOpenMining: nestOpenMining,
        //nestPriceFacade: nestPriceFacade,
        //nestVote: nestVote,
        //nTokenController: nTokenController,
        //nestRedeeming: nestRedeeming

        nestBatchPlatform2: nestBatchPlatform2
    };

    return contracts;
};