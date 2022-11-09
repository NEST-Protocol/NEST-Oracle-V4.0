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
    const SuperMan = await ethers.getContractFactory('SuperMan');
    const NNIncome = await ethers.getContractFactory('NNIncome');

    console.log('** Deploy: goerli@20221108.js **');
    
    //     ** Deploy: goerli@20221108.js **
    // nest: 0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F
    // peth: 0x17322b20752cC7d6094209f6Fa73275375Cf7B27
    // pusd: 0x5cbb73B367FD69807381d06BC2041BEc86d8487d
    // pbtc: 0x48e5c876074549cD4Bb7be0800154450b59b1eB6
    // nestGovernance: 0x821edD79cc386E56FeC9DA5793b87a3A52373cdE
    // nestBatchMining: 0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA
    // superMap: 0x4474ddECBa0940B1B4a699c87d9B76Cf1F200548
    // nnIncome: 0xbe388405c5f091f46DA440652f776c9832e0d1c3
    // proxyAdmin: 0xEB8b3c263A32C3f098Fb0Da0F7855E2E98D75971

    // 1. Deploy dependent contract
    //const nest = await TestERC20.deploy('NEST', 'NEST', 18);
    const nest = await TestERC20.attach('0xE2975bf674617bbCE57D2c72dCfC926716D8AC1F');
    console.log('nest: ' + nest.address);

    //const peth = await TestERC20.deploy('PETH', 'PETH', 18);
    const peth = await TestERC20.attach('0x17322b20752cC7d6094209f6Fa73275375Cf7B27');
    console.log('peth: ' + peth.address);

    //const pusd = await TestERC20.deploy('PUSD', 'PUSD', 18);
    const pusd = await TestERC20.attach('0x5cbb73B367FD69807381d06BC2041BEc86d8487d');
    console.log('pusd: ' + pusd.address);

    //const pbtc = await TestERC20.deploy('PBTC', 'PBTC', 18);
    const pbtc = await TestERC20.attach('0x48e5c876074549cD4Bb7be0800154450b59b1eB6');
    console.log('pbtc: ' + pbtc.address);

    //const nestGovernance = await upgrades.deployProxy(NestGovernance, ['0x0000000000000000000000000000000000000000'], { initializer: 'initialize' });
    const nestGovernance = await NestGovernance.attach('0x821edD79cc386E56FeC9DA5793b87a3A52373cdE');
    console.log('nestGovernance: ' + nestGovernance.address);

    //const nestBatchMining = await upgrades.deployProxy(NestBatchMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchMining = await NestBatchMining.attach('0x3948F9ec377110327dE3Fb8176C8Ed46296d76bA');
    console.log('nestBatchMining: ' + nestBatchMining.address);

    // const superMan = await SuperMan.deploy(nestGovernance.address);
    const superMan = await SuperMan.attach('0x4474ddECBa0940B1B4a699c87d9B76Cf1F200548');
    console.log('superMan: ' + superMan.address);

    //const nnIncome = await upgrades.deployProxy(NNIncome, [nestGovernance.address], { initializer: 'initialize' });
    const nnIncome = await NNIncome.attach('0xbe388405c5f091f46DA440652f776c9832e0d1c3');
    console.log('nnIncome: ' + nnIncome.address);

    //await nestGovernance.registerAddress('nodeAssignment', '0xbe388405c5f091f46DA440652f776c9832e0d1c3');
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
    //     priceEffectSpan: 20,

    //     // The amount of nest to pledge for each post (Unit: 1000). 100
    //     pledgeNest: 100
    // });

    // console.log('11. nestBatchMining.open()');
    // await nestBatchMining.open(
    //     pusd.address, 
    //     2000000000000000000000n, 
    //     nest.address, 
    //     [peth.address, pbtc.address, nest.address],
    //     {
    //         rewardPerBlock: 1000000000000000000n,
    //         postFeeUnit: 0,
    //         singleFee: 0,
    //         reductionRate: 8000
    //     });

    // await nest.transfer('0x0e20201B2e9bC6eba51bcC6E710C510dC2cFCfA4', 101000000000000000000000000n);
    // await nest.approve(nestBatchMining.address, 100000000000000000000000000n);
    // await nestBatchMining.increase(0, 100000000000000000000000000n);

    console.log('---------- OK ----------');
    
    const contracts = {
        nest: nest,
        peth: peth,
        pusd: pusd,
        pbtc: pbtc,

        nestGovernance: nestGovernance,
        nestBatchMining: nestBatchMining
    };

    return contracts;
};