// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, upgrades } = require('hardhat');

exports.deploy = async function() {
    
    //const IterableMapping = await ethers.getContractFactory('IterableMapping');
    //const iterableMapping = await IterableMapping.deploy();
    const eth = { address: '0x0000000000000000000000000000000000000000' };
    const TestERC20 = await ethers.getContractFactory('TestERC20');
    // const IBNEST = await ethers.getContractFactory('IBNEST', {
    //     libraries: {
    //         IterableMapping: iterableMapping.address
    //     }
    // });
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

    // const nestMining = await upgrades.deployProxy(NestMining, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestMining = await NestMining.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestMining: ' + nestMining.address);

    //const nestOpenMining = await upgrades.deployProxy(NestOpenMining, [nestGovernance.address], { initializer: 'initialize' });
    const nestOpenMining = await NestOpenMining.attach('0x723B860fDA5Fd8f5Fc4D3d525587836D203b510c');
    console.log('nestOpenMining: ' + nestOpenMining.address);

    // const nestPriceFacade = await upgrades.deployProxy(NestPriceFacade, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestPriceFacade = await NestPriceFacade.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestPriceFacade: ' + nestPriceFacade.address);

    //const nestVote = await upgrades.deployProxy(NestVote, [nestGovernance.address], { initializer: 'initialize' });
    const nestVote = await NestVote.attach('0x329cF16006A250fA2016912CB0a9B160Cc264D16');
    console.log('nestVote: ' + nestVote.address);

    // const nTokenController = await upgrades.deployProxy(NTokenController, [nestGovernance.address], { initializer: 'initialize' });
    // //const nTokenController = await NTokenController.attach('0x0000000000000000000000000000000000000000');
    // console.log('nTokenController: ' + nTokenController.address);

    // const nnIncome = await upgrades.deployProxy(NNIncome, [nestGovernance.address], { initializer: 'initialize' });
    // //const nnIncome = await NNIncome.attach('0x0000000000000000000000000000000000000000');
    // console.log('nnIncome: ' + nnIncome.address);

    // const nestRedeeming = await upgrades.deployProxy(NestRedeeming, [nestGovernance.address], { initializer: 'initialize' });
    // //const nestRedeeming = await NestRedeeming.attach('0x0000000000000000000000000000000000000000');
    // console.log('nestRedeeming: ' + nestRedeeming.address);

    // console.log('1. nestGovernance.setBuiltinAddress()');
    // await nestGovernance.setBuiltinAddress(
    //     nest.address,
    //     '0x0000000000000000000000000000000000000000',
    //     nestLedger.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nestPriceFacade.address,
    //     nestVote.address,
    //     '0x0000000000000000000000000000000000000000', //nestMining.address,
    //     '0x0000000000000000000000000000000000000000', //nnIncome.address,
    //     '0x0000000000000000000000000000000000000000'  //nTokenController.address
    // );

    // console.log('2. nestLedger.update()');
    // await nestLedger.update(nestGovernance.address);
    // //console.log('3. nestMining.update()');
    // //await nestMining.update(nestGovernance.address);
    // console.log('4. nestOpenMining.update()');
    // await nestOpenMining.update(nestGovernance.address);
    // //console.log('5. nestPriceFacade.update()');
    // //await nestPriceFacade.update(nestGovernance.address);
    // console.log('6. nestVote.update()');
    // await nestVote.update(nestGovernance.address);
    // //console.log('7. nTokenController.update()');
    // //await nTokenController.update(nestGovernance.address);
    // //console.log('8. nnIncome.update()');
    // // await nnIncome.update(nestGovernance.address);
    // // console.log('9. nestRedeeming.update()');
    // // await nestRedeeming.update(nestGovernance.address);

    // console.log('10. nestOpenMining.setConfig()');
    // await nestOpenMining.setConfig({
    //     // Eth number of each post. 30
    //     // We can stop post and taking orders by set postEthUnit to 0 (closing and withdraw are not affected)
    //     postEthUnit: 30,

    //     // Post fee(0.0001eth, DIMI_ETHER). 1000
    //     postFeeUnit: 100,

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

    console.log('---------- OK ----------');
    
    const contracts = {
        eth: eth,
        nest: nest,
        usdt: usdt,
        hbtc: hbtc,

        nestGovernance: nestGovernance,
        nestLedger: nestLedger,
        //nestMining: nestMining,
        nestOpenMining: nestOpenMining,
        //nestPriceFacade: nestPriceFacade,
        nestVote: nestVote,
        // nTokenController: nTokenController,
        // nestRedeeming: nestRedeeming
    };

    return contracts;
};