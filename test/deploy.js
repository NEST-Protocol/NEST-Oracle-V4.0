const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('NestOpenMining', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { 
            eth, nest, pusd, peth, hbtc,

            nestGovernance, nestLedger,
            nestOpenMining, nestBatchPlatform2
        } = await deploy();
        
        console.log('ok');
        //await nest.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        //await pusd.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        //await hbtc.approve(nestBatchPlatform2.address, 100000000000000000000000000n);
        
        const GASLIMIT = 400000n;
        const POSTFEE = 0.1;
        const OPEN_FEE = 0n;
        const EFFECT_BLOCK = 50;

        const NestBatchPlatform2 = await ethers.getContractFactory('NestBatchPlatform2');
        const newNestBatchPlatform2 = await NestBatchPlatform2.deploy();
        console.log('newNestBatchPlatform2: ' + newNestBatchPlatform2.address);
        
    });
});
