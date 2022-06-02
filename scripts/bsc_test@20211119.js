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

    console.log('** Deploy: bsc_test@20211119.js **');
    
    // ** Deploy: bsc_test@20211119.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // pusd: 0x3DA5c9aafc6e6D6839E62e2fB65825869019F291
    // peth: 0xc39dC1385a44fBB895991580EA55FC10e7451cB3
    // nestGovernance: 0x5691dc0770D55B9469a3242DA282754687687935
    // nestLedger: 0x78D5E2fC85969e51580fd2C0Fd6D056a444167cE
    // nestOpenMining: 0xF2f9E62f52389EF223f5Fa8b9926e95386935277

    // 1. Deploy dependent contract
    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);
    
    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x3DA5c9aafc6e6D6839E62e2fB65825869019F291');
    console.log('pusd: ' + pusd.address);

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