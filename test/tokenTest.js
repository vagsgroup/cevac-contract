require('babel-register');
require('babel-polyfill');var web3 = require('web3');
var mocha = require('mocha');
var chai = require('chai');
var CevacToken = artifacts.require('./CevacToken');
import expectThrow from './helpers/expectThrow';

console.log(web3.eth)
///these will be test cases for the tcube token

contract('CevacToken', function(accounts){
	var cevactokeninit = {};
	let fundingStartBlock = Date.now()/1000;
	let fundingEndBlock = Date.now()/1000 + 10000000;
	cevactokeninit.fundingStartBlock = fundingStartBlock;
	cevactokeninit.fundingEndBlock = fundingEndBlock;

	console.log("These are init parameters for the tcube crowdsale", cevactokeninit);

	let cevactoken;

	beforeEach(async function() {
		cevactoken = await CevacToken.new(fundingStartBlock,fundingEndBlock);
	})

	it("Should have initialized the right values", async function(){
		let name = await cevactoken.name.call();
		let decimals = await cevactoken.decimals.call();
		let symbol = await cevactoken.symbol.call();
		let totalSupply = await cevactoken.totalSupply.call();
		let fund = await cevactoken.CevacFund.call();

		assert.equal(name,"Cevac Token","Name is not correct");
		assert.equal(decimals.toNumber(),8,"Decimals are not Correct");
		assert.equal(symbol,"CEVAC","Symbol is not correct");
		assert.equal(totalSupply.toNumber(),fund.toNumber(),"Not correct");
	});

	it("Should set the owner of the contract correctly" , async function() {
		let owner = await cevactoken.owner.call();
		assert.equal(owner,accounts[0],"Owner is not correctly initialized");
	});

	it("Should allow the owner to change the values that are only owner modified", async function() {
		let owner = await cevactoken.owner.call();
		let initialFundingStartBlock = await cevactoken.fundingStartBlock.call();
		let initialEndBlock = await cevactoken.fundingEndBlock.call();
		let initialMinCapUSD = await cevactoken.minCapUSD.call();
		let initialMaxCapUSD = await cevactoken.maxCapUSD.call();

		let afterFundingStartBlock = 100000000000;
		let afterFundingEndBlock = 2000000000000;
		let afterMinCapUSD = 10000000;
		let afterMaxCapUSD = 999999999;

		await cevactoken.changeEndBlock(afterFundingEndBlock,{from:owner});
		await cevactoken.changeStartBlock(afterFundingStartBlock,{from:owner});
		await cevactoken.changeMinCapUSD(afterMinCapUSD,{from:owner});
		await cevactoken.changeMaxCapUSD(afterMaxCapUSD,{from:owner});

		let aftercallFundingStartBlock = await cevactoken.fundingStartBlock.call();
		let aftercallEndBlock = await cevactoken.fundingEndBlock.call();
		let aftercallMinCapUSD = await cevactoken.minCapUSD.call();
		let aftercallMaxCapUSD = await cevactoken.maxCapUSD.call();

		assert.equal(afterFundingStartBlock,aftercallFundingStartBlock);
		assert.equal(afterFundingEndBlock,aftercallEndBlock);
		assert.equal(aftercallMinCapUSD,afterMinCapUSD);
		assert.equal(aftercallMaxCapUSD,afterMaxCapUSD);
	});

	it("Should not allow the address other than owner to make those changes", async function() {
		let owner = await cevactoken.owner.call();

		let afterFundingStartBlock = 100000000000;
		let afterFundingEndBlock = 2000000000000;
		let afterMinCapUSD = 10000000;
		let afterMaxCapUSD = 999999999;

		await expectThrow(cevactoken.changeEndBlock(afterFundingEndBlock,{from:accounts[2]}));

		await expectThrow(cevactoken.changeStartBlock(afterFundingStartBlock,{from:accounts[2]}));

		await expectThrow(cevactoken.changeMinCapUSD(afterMinCapUSD,{from:accounts[2]}));

		await expectThrow(cevactoken.changeMaxCapUSD(afterMaxCapUSD,{from:accounts[2]}));
	});

	it("Should not allow any ether contributions in this contract", async function() {
		let owner = await cevactoken.owner.call();

		await expectThrow(cevactoken.sendTransaction({from:owner,to:cevactoken.address,value:10000000000000}));
	});

	it("Should give the correct value for isValid", async function() {
		let owner = await cevactoken.owner.call();
		let initialFundingStartBlock = await cevactoken.fundingStartBlock.call();
		let initialEndBlock = await cevactoken.fundingEndBlock.call();
		let isvalid = false;
		if(Date.now()/1000 > initialFundingStartBlock.toNumber() && Date.now()/1000 <= initialEndBlock){
			isvalid = true;

			///now check whether the output from contract is also is valid
			let valid = await cevactoken.isValid();
		}
	});	

	it("The owner should be able to finalize the token sale", async function() {
		let owner = await cevactoken.owner.call();

		let isFinalized = await cevactoken.finalizedICO.call();
		assert.equal(isFinalized,false);

		///try to finalize the token sale by other address othe rthan owner
		await expectThrow(cevactoken.finalizeICOOwner({from:accounts[2]}));
		isFinalized = await cevactoken.finalizedICO.call();
		assert.equal(isFinalized,false);

		///now owner can finalize the token sale
		await cevactoken.finalizeICOOwner({from:owner})
		isFinalized = await cevactoken.finalizedICO.call();
		let isTransfersAllowed = await cevactoken.istransferAllowed.call();
		assert.equal(isFinalized,true);
		assert.equal(isTransfersAllowed,true);
	});

	it("The Owner should be able to enable and disable transfers" , async function() {
		let owner = await cevactoken.owner.call();

		let istransferAllowed = await cevactoken.istransferAllowed.call();
		assert.equal(istransferAllowed,false);

		////try to enable transfer
		await cevactoken.enableTransfers({from:owner});
		 istransferAllowed = await cevactoken.istransferAllowed.call();
		assert.equal(istransferAllowed,true);

		///try to disable transfer
		await cevactoken.disableTransfers({from:owner});
		 istransferAllowed = await cevactoken.istransferAllowed.call();
		assert.equal(istransferAllowed,false);
	});
})