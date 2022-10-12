const { expect } = require('chai');
const { deploy } = require('../scripts/deploy.js');
const { toBigInt, toDecimal, showReceipt, snd, tableSnd, d1, Vc, Vp, UI } = require('./utils.js');

describe('deploy', function() {
    it('First', async function() {
        var [owner, addr1, addr2] = await ethers.getSigners();

        const { nest, usdt, hbtc, cofi, usdc, nestBatchMining } = await deploy();
        console.log('ok');
    });
});
