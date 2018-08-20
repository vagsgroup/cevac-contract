var TCubeToken = artifacts.require('./CevacToken.sol');
var tokenSale = artifacts.require('./TokenSale.sol');
var PricingStrategy = artifacts.require('./PricingStrategy.sol');

module.exports = function(deployer) {
  
  ///deploy the contracts here
  var fundingStartDate = Date.now()/1000; 
  var fundingEndDate = (Date.now()/1000)+10000000;
  deployer.deploy(TCubeToken,fundingStartDate,fundingEndDate).then(function(contractToken){
        deployer.deploy(PricingStrategy).then(function(pricingContract){
          deployer.deploy(tokenSale,contractToken.address,pricingContract.address).then(function(tokenSale){
            console.log( "contracts deployed ", contractToken.address, tokenSale.address)
          })
        })
			})
};