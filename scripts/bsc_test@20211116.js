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

    console.log('** Deploy: bsc_test@20211116.js **');
    
    //     ** Deploy: bsc_test@20211116.js **
    // nest: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // usdt: 0xF331D5C0E36Cc8a575D185b1D513715be55087E4
    // hbtc: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // nestGovernance: 0x73851c710953900dc8dE699A94762d21b1c941b2
    // nestLedger: 0xB9bb3EBa71Aeac185C34d7401fE3E84BF163d7ce
    // nestOpenMining: 0x723B860fDA5Fd8f5Fc4D3d525587836D203b510c
    // nestVote: 0x329cF16006A250fA2016912CB0a9B160Cc264D16

    // 1. Deploy dependent contract
    //const nest = await IBNEST.deploy();
    const nest = await TestERC20.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nest: ' + nest.address);

    //const usdt = await TestERC20.deploy('USDT', 'USDT', 18);
    const usdt = await TestERC20.attach('0xF331D5C0E36Cc8a575D185b1D513715be55087E4');
    console.log('usdt: ' + usdt.address);

    //const hbtc = await TestERC20.deploy('HBTC', 'HBTC', 18);
    const hbtc = await TestERC20.attach('0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA');
    console.log('hbtc: ' + hbtc.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x73851c710953900dc8dE699A94762d21b1c941b2');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestLedger = await upgrades.deployProxy(NestLedger, [nestGovernance.address], { initializer: 'initialize' });
    const nestLedger = await NestLedger.attach('0xB9bb3EBa71Aeac185C34d7401fE3E84BF163d7ce');
    console.log('nestLedger: ' + nestLedger.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestOpenMining = await NestOpenMining.attach('0x723B860fDA5Fd8f5Fc4D3d525587836D203b510c');
    console.log('nestOpenMining: ' + nestOpenMining.address);

    //const nestVote = await upgrades.deployProxy(NestVote, [nestGovernance.address], { initializer: 'initialize' });
    const nestVote = await NestVote.attach('0x329cF16006A250fA2016912CB0a9B160Cc264D16');
    console.log('nestVote: ' + nestVote.address);

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestOpenMining: nestOpenMining,
        nestVote: nestVote,
    };

    return contracts;
};