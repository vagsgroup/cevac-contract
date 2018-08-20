var web3 = require('web3');
var mocha = require('mocha');
var chai = require('chai');
var CevacToken = artifacts.require('./CevacToken');
var TokenSale = artifacts.require('./TokenSale');
var PricingStrategy = artifacts.require('./PricingStrategy');
require('babel-register');
require('babel-polyfill');
import expectThrow from './helpers/expectThrow';


////The tests for the tokensale of the allrites

contract("TokenSale", function(accounts){

	let fundingStartBlock = Date.now()/1000;
	let pricingcontract; 
	let fundingEndBlock = Date.now()/1000 + 10000000;

	let cevactoken;
	let tokensale;
	///before each do this
	beforeEach(async function(){
		cevactoken = await CevacToken.new(fundingStartBlock,fundingEndBlock);
		let cevactokenaddress  = cevactoken.address;
		pricingcontract = await PricingStrategy.new();
		tokensale = await TokenSale.new(cevactokenaddress,pricingcontract.address);
		await cevactoken.addToOwnership(tokensale.address);
	})

	it("The owner should be able to alott tokens", async function(){
		let owner = await tokensale.owner.call();
		let person = accounts[4];
		let balancePerson = await cevactoken.balances.call(person);
		let isowner = await cevactoken.ownership.call(tokensale.address);
		assert.equal(isowner,true);
		await tokensale.alottTokensExchange(person,100000000, {from:owner,to:cevactoken.address});
		balancePerson = await cevactoken.balances.call(person);
		assert.equal(balancePerson.toNumber(),100000000);
	});

	it("The users should be able to contribute in ethers and get the tokens", async function(){
		let owner = await tokensale.owner.call();
		let person = accounts[4];
		let ethPrice = await pricingcontract.ETHUSD.call();
		let balancePerson = await cevactoken.balances.call(person);
		await tokensale.sendTransaction({from:person,to:tokensale.address,value:1000000000000000000});
		let totalusd = Math.floor((1000000000000000000*ethPrice)/Math.pow(10,18));
		let totalTokens = totalusd*158730*10**3;
		console.log(totalTokens);
		balancePerson = await cevactoken.balances.call(person);
		assert.equal(balancePerson.toNumber(),totalTokens);
	});

	it("The users should be able to contribute in btc and get the tokens ", async function(){
		let owner = await tokensale.owner.call();
		let person = accounts[4];
		let btcPrice = await pricingcontract.BTCUSD.call();
		let balancePerson = await cevactoken.balances.call(person);
		await tokensale.allottTokensBTC(person, 100000000);
		balancePerson = await cevactoken.balances.call(person);
		let totalusd = Math.floor((100000000*btcPrice)/Math.pow(10,8));
		let totalTokens = totalusd*158730*10**3;
		console.log(totalTokens);
		assert.equal(balancePerson.toNumber(),totalTokens);
	});

	it("test the states and check the discount and price of tokens", async function(){
		///check the current state when it is initialized
		var currentState = await tokensale.getStateFunding.call();
		let owner = await tokensale.owner.call();

		assert.equal(currentState,0);
		let currentSupply = await tokensale.currentSupplyStages.call(0);
		assert.equal(currentSupply,0);
		///let the owner change the state
		await tokensale.setOwnerState(3);
		currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,3);
		///let the owner diable the state
		await tokensale.disableOwnerState();
		currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,0);
		///since the currentl supply is still 0 check that if we add some tokens it will still be 0
		await tokensale.alottTokensExchange(accounts[1],100000000, {from:owner,to:cevactoken.address});
		currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,0);

		///assert that they have been addded to desired current supply
		currentSupply = await tokensale.currentSupplyStages.call(0);
		assert.equal(currentSupply,100000000);
		console.log(currentState.toNumber(),"state");
		///assert that they have been addded to desired current supply
		let  maxSaleableTokens = await tokensale.maxSaleableTokens.call(0);
		currentSupply = await tokensale.currentSupplyStages.call(0);
		console.log(currentSupply.toNumber(),"supply",maxSaleableTokens.toNumber())

		maxSaleableTokens = await tokensale.maxSaleableTokens.call(0);
		await tokensale.alottTokensExchange(accounts[2],maxSaleableTokens,{from:owner,to:cevactoken.address})
		currentState = await tokensale.getStateFunding.call();
		console.log(currentState.toNumber(),"state");
		///assert that they have been addded to desired current supply
		currentSupply = await tokensale.currentSupplyStages.call(0);
		console.log(currentSupply.toNumber(),"supply",maxSaleableTokens.toNumber())
	});

	it("The owner should be able to send the reserve funds to the owner address",async function(){
		let owner = await tokensale.owner.call();
		await tokensale.sendTokens();
		await expectThrow(tokensale.sendTokens());
	});

	it("The owner should be able to change the values of owneronly modifier things",async function(){
		var currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,0);
		let currentSupply = await tokensale.currentSupplyStages.call(0);
		assert.equal(currentSupply,0);
		///let the owner change the state
		await tokensale.setOwnerState(3);
		currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,3);
		///let the owner diable the state
		await tokensale.disableOwnerState();
		currentState = await tokensale.getStateFunding.call();
		assert.equal(currentState,0);

		///change the state to state 5
		await tokensale.setOwnerState(5);
		currentState = await tokensale.getStateFunding.call();
		let isOwnerStateSet = await tokensale.isOwnerStateSet.call();
		assert.equal(currentState,5);
		let person = accounts[8];
		assert.equal(isOwnerStateSet,true);

		///try to send the ethers and check for price of staeg 5 specifically since it is a different way than others
		ethPrice = await pricingcontract.ETHUSD.call();
		balancePerson = await cevactoken.balances.call(person);
		await tokensale.sendTransaction({from:person,to:tokensale.address,value:1000000000000000000});

		// ///try to get the balance of accounts[8]
		let xbalance = await cevactoken.balances.call(accounts[8]);
		assert.equal(xbalance.toNumber(),Math.floor(ethPrice*(1000000000000000000/Math.pow(10,18)*1000/1117)));

		let maxSaleablestagezero = await tokensale.maxSaleableTokens.call(0);
		assert.equal(maxSaleablestagezero,9 * (10**8) * (10**8));

		///the owner can change the max tokens to be sold at each stages
		await tokensale.changeMaxSaleableTokens(0 , 3 * (10**8) * (10**8));
		maxSaleablestagezero = await tokensale.maxSaleableTokens.call(0);
		assert.equal(maxSaleablestagezero.toNumber(),3 * (10**8) * (10**8));
		let ethPrice = await pricingcontract.ETHUSD.call();

		
		///the owner is able to change the owner address
		let balancePerson = await cevactoken.balances.call(person);
		await tokensale.sendTransaction({from:person,to:tokensale.address,value:1000000000000000000});
		let totalusd = Math.floor((1000000000000000000*ethPrice)/Math.pow(10,18));
		let totalTokens = totalusd*5*10**8;
		console.log(totalTokens);
		balancePerson = await cevactoken.balances.call(person);

		///now check the address of owner who had to recieve the ethereum
		let owneraddr = 0xB0583785f27B7f87535B4c574D3B30928aD3A7eb;
		await tokensale.changeOwnerAddr(accounts[4]);

		let newowneraddr = await tokensale.ownerAddr.call();
		assert.equal(newowneraddr,accounts[4]);
		// let bal = await web3.eth.getBalance(owneraddr);
	});

	it("Owner Should be able to finalizeTokenSale",async function(){
		let owner = await tokensale.owner.call();

		///it is expected to throw because they have just not raised enough ethers
		await expectThrow( tokensale.finalizeTokenSale() );
		await cevactoken.finalizeICOOwner();
	});

})