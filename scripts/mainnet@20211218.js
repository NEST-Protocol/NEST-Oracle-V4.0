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
    const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');

    console.log('** 开始部署合约 mainnet@20211218.js **');
    /*
    2021-04-27
    proxy
    nest: 0x04abEdA201850aC0124161F037Efd70c74ddC74C
    usdt: 0xdAC17F958D2ee523a2206206994597C13D831ec7
    nestGovernance: 0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5
    nestLedger: 0x34B931C7e5Dc45dDc9098A1f588A0EA0dA45025D
    nTokenController: 0xc4f1690eCe0145ed544f0aee0E2Fa886DFD66B62
    nestVote: 0xDa52f53a5bE4cb876DE79DcfF16F34B95e2D38e9
    nestMining: 0x03dF236EaCfCEf4457Ff7d6B88E8f00823014bcd
    ntokenMining: 0xC2058Dd4D55Ae1F3e1b0744Bdb69386c9fD902CA
    nestPriceFacade: 0xB5D2890c061c321A5B6A4a4254bb1522425BAF0A
    nestRedeeming: 0xF48D58649dDb13E6e29e03059Ea518741169ceC8
    nnIncome: 0x95557DE67444B556FE6ff8D7939316DA0Aa340B2
    nn: 0xC028E81e11F374f7c1A3bE6b8D2a815fa3E96E6e

    implementation
    nestGovernance: 0x6D76935090FB8b8B73B39F03243fAd047B0794C0
    nestLedger: 0x09CE0e021195BA2c1CDE62A8B187abf810951540
    nTokenController: 0x6C4BD6148F72b525f72b8033D6dD5C5aC4C9DCB7
    nestVote: 0xBBf3E1B2901AcCc3fDe5A4971903a0aBC6CA04CA
    nestMining: 0xE34A736290548227415329962705a6ee17c5f1a5
    ntokenMining: 0xE34A736290548227415329962705a6ee17c5f1a5
    nestPriceFacade: 0xD0B5532Cd0Ae1a14dAdf94f8562679A48aDa3643
    nestRedeeming: 0x5441B24FA3a2347Ac6EE70431dD3BfD0c224B4B7
    nnIncome: 0x718626a4b78e0ECfA60dE1D4C386302e68fac8cD

    ProxyAdmin: 0x7DBe94A4D6530F411A1E7337c7eb84185c4396e6
    */

    // PUSD: 0xCCEcC702Ec67309Bc3DDAF6a42E9e5a6b8Da58f0

    // 1. 部署依赖合约
    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0x04abEdA201850aC0124161F037Efd70c74ddC74C');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xdAC17F958D2ee523a2206206994597C13D831ec7');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x0316EB71485b0Ab14103307bf65a021042c6d380');
    console.log('hbtc: ' + hbtc.address);

    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x0316EB71485b0Ab14103307bf65a021042c6d380');
    console.log('pusd: ' + pusd.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0xA2eFe217eD1E56C743aeEe1257914104Cf523cf5');
    console.log('nestGovernance: ' + nestGovernance.address);

    const nestBatchPlatform2 = await upgrades.deployProxy(NestBatchPlatform2, [nestGovernance.address], { initializer: 'initialize' });
    //const nestBatchPlatform2 = await NestBatchPlatform2.attach('0x0000000000000000000000000000000000000000');
    console.log('nestBatchPlatform2: ' + nestBatchPlatform2.address);

    console.log('6. nestBatchPlatform2.update()');
    await nestBatchPlatform2.update(nestGovernance.address);

    console.log('11. nestBatchPlatform2.setConfig()');
    await nestBatchPlatform2.setConfig({
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
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,
        pusd: pusd,

        nestGovernance: nestGovernance,
        nestBatchPlatform2: nestBatchPlatform2
    };

    return contracts;
};