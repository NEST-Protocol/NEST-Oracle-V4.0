// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    /*
    ***** .deploy.rinkeby@20210716.js *****
    nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    nTokenController: 0xb75Fd1a678dAFE00cEafc8d9e9B1ecf75cd6afC5
    nestVote: 0xF9539C7151fC9E26362170FADe13a4e4c250D720
    nestMining: 0x50E911480a01B9cF4826a87BD7591db25Ac0727F
    ntokenMining: 0xb984cCe9fdA423c5A18DFDE4a7bCdfC150DC1012
    nestPriceFacade: 0x40C3EB032f27fDa7AdcF1B753c75B84e27f26838
    nestRedeeming: 0xeD859B5f5A2e19bC36C14096DC05Fe9192CeFa31
    nnIncome: 0x82307CbA43f05D632aB835AFfD30ED0073dC4bd9
    nhbtc: 0xe6bf6Bd50b07D577a22FEA5b1A205Cf21642b198
    nn: 0x52Ab1592d71E20167EB657646e86ae5FC04e9E01

    account0: 0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4
    newNestMiningImpl: 0xea3bDB3630208E1dE4Ab6d738F97294F790fB4eD
    newNestMiningImpl: 0xD8BF1b64C908Cc358b37263B241bFaeD2eDd8038
    */

    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    const NestGovernance = await ethers.getContractFactory('NestGovernance');
    const NestLedger = await ethers.getContractFactory('NestLedger');
    const NestOpenMining = await ethers.getContractFactory('NestOpenPlatform');

    console.log('** Deploy: rinkeby@20211102.js **');
    
    // ** Deploy: rinkeby@20211102.js **
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    // nestOpenMining: 0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF

    // 1. Deploy dependent contract
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

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        nestOpenMining: nestOpenMining,
    };

    return contracts;
};