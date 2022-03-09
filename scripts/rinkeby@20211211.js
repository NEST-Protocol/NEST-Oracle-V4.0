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

    console.log('** Deploy: rinkeby@20211211.js **');
    
    // ** Deploy: rinkeby@20211102.js **
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // pusd: 0x5407cab67ad304FB8A4aC46D83b3Dd63A9dbA575
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    // nestOpenMining: 0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF

    //     ** Deploy: rinkeby@20211211.js **
    // pusd: 0x5407cab67ad304FB8A4aC46D83b3Dd63A9dbA575
    // nest: 0xE313F3f49B647fBEDDC5F2389Edb5c93CBf4EE25
    // usdt: 0x20125a7256EFafd0d4Eec24048E08C5045BC5900
    // hbtc: 0xaE73d363Cb4aC97734E07e48B01D0a1FF5D1190B
    // nestGovernance: 0xa52936bD3848567Fbe4bA24De3370ABF419fC1f7
    // nestLedger: 0x005103e352f86e4C32a3CE4B684fe211eB123210
    // nestOpenMining: 0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF
    // nestBatchPlatform2: 0x12af92C6e7a1F855008c6B9dDEd7DcA19B49B51B
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

    // const nestMining = await upgrades.deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestMining = await NestMining.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestMining: ' + nestMining.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestOpenMining = await NestOpenMining.attach('0x638461F3Ae49CcC257ef49Fe76CCE5816A9234eF');
    console.log('nestOpenMining: ' + nestOpenMining.address);

    // const nestPriceFacade = await upgrades.deployProxy(NestPriceFacade, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestPriceFacade: ' + nestPriceFacade.address);

    // const nestVote = await upgrades.deployProxy(NestVote, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestVote = await NestVote.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestVote: ' + nestVote.address);

    // const nTokenController = await upgrades.deployProxy(NTokenController, [nestGovernance.address], { initializer: 'initialize' });
    // //const nTokenController = await NTokenController.attach('0x0000000000000000000000000000000000000000');
    // console.log('nTokenController: ' + nTokenController.address);

    // const nnIncome = await upgrades.deployProxy(NNIncome, [nestGovernance.address], { initializer: 'initialize' });
    // //const nnIncome = await NNIncome.attach('0x0000000000000000000000000000000000000000');
    // console.log('nnIncome: ' + nnIncome.address);

    // const nestRedeeming = await upgrades.deployProxy(NestRedeeming, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestRedeeming = await NestRedeeming.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestRedeeming: ' + nestRedeeming.address);

    //const nestBatchPlatform2 = await upgrades.deployProxy(NestBatchPlatform2, [nestGovernance.address], { initializer: 'initialize' });
    const nestBatchPlatform2 = await NestBatchPlatform2.attach('0x12af92C6e7a1F855008c6B9dDEd7DcA19B49B51B');
    console.log('nestBatchPlatform2: ' + nestBatchPlatform2.address);

    // console.log('1. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestLedger.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     nestPriceFacade.address,
    //     nestVote.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     nnIncome.address,
    //     nTokenController.address
    // );

    // console.log('2. nestLedger.update()');
    // await nestLedger.update(nestGovernance.address);
    // //console.log('3. nestMining.update()');
    // //await nestMining.update(nestGovernance.address);
    // console.log('4. nestOpenMining.update()');
    // await nestOpenMining.update(nestGovernance.address);
    // console.log('5. nestPriceFacade.update()');
    // await nestPriceFacade.update(nestGovernance.address);
    // console.log('6. nestVote.update()');
    // await nestVote.update(nestGovernance.address);
    // console.log('7. nTokenController.update()');
    // await nTokenController.update(nestGovernance.address);
    // console.log('8. nnIncome.update()');
    // await nnIncome.update(nestGovernance.address);
    // console.log('9. nestRedeeming.update()');
    // await nestRedeeming.update(nestGovernance.address);
    
    // console.log('10. nestOpenMining.setConfig()');
    // await nestOpenMining.setConfig({
    //     // Eth number of each post. 30
    //     // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
    //     postEthUnit: 30,

    //     // Post fee(0.0001eth, DIMI_ETHER). 1000
    //     postFeeUnit: 1000,

    //     // Proportion of miners digging(10000 based). 8000
    //     minerNestReward: 8000,
        
    //     // The proportion of token dug by miners is only valid for the token created in version 3.0
    //     // (10000 based). 9500
    //     minerNTokenReward: 9500,

    //     // When the circulation of ntoken exceeds this threshold, post() is prohibited(Unit: 10000 ether). 500
    //     doublePostThreshold: 500,
        
    //     // The limit of ntoken mined blocks. 100
    //     ntokenMinedBlockLimit: 100,

    //     // -- Public configuration
    //     // The number of times the sheet assets have doubled. 4
    //     maxBiteNestedLevel: 4,
        
    //     // Price effective block interval. 20
    //     priceEffectSpan: 20,

    //     // The amount of nest to pledge for each post (Unit: 1000). 100
    //     pledgeNest: 100
    // });

    // console.log('11. nestOpenMining.open()');
    // await nestOpenMining.open(hbtc.address, 1000000000000000000n, usdt.address, nest.address);
    
    // console.log('11. nestBatchPlatform2.setConfig()');
    // await nestBatchPlatform2.setConfig({
    //     // -- Public configuration
    //     // The number of times the sheet assets have doubled. 4
    //     maxBiteNestedLevel: 4,
        
    //     // Price effective block interval. 20
    //     priceEffectSpan: 20,

    //     // The amount of nest to pledge for each post (Unit: 1000). 100
    //     pledgeNest: 100
    // });
    
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