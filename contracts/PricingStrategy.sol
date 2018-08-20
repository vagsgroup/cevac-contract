pragma solidity ^0.4.8;
import './SafeMath.sol';
import "./Ownable.sol";

contract PricingStrategy is Ownable{
    uint public ETHUSD=580;
    uint public BTCUSD=9000;
    uint256 public exchangeRate;
    bool public called;

    function PricingStrategy(){
        ///initialize with these values
        statePrices[0] = 158730*10**3;
        statePrices[1] = 7215*10**5;
        statePrices[2] = 3607*10**5;
        statePrices[3] = 2*10**8;
        statePrices[4] = 1252*10**5;
        statePrices[5] = 1117;
        ////intiialization ends
    }
    
    function getLatest(uint btcusd,uint ethusd) onlyOwner{
        ETHUSD = ethusd;
        BTCUSD = btcusd;
    }


    ///this will save the statePrices
    mapping( uint256 => uint256 ) public statePrices;

    ////this function will make sure that the owner is able to change the values
    function changeStatePrices(uint state, uint256 price) public onlyOwner{
        statePrices[state] = price;
    }

    ///log the value to get the value in usd
    event logval(uint256 s);

    function totalDiscount(uint state,uint256 contribution,string types) returns (uint256,uint256){
        uint256 valueInUSD;
        logval(state);
      if(keccak256(types)==keccak256("ethereum")){
            if(ETHUSD==0) throw;
            valueInUSD = (ETHUSD*contribution)/1000000000000000000;
            logval(valueInUSD);
       }else if(keccak256(types)==keccak256("bitcoin")){
            if(BTCUSD==0) throw;
            valueInUSD = (BTCUSD*contribution)/100000000;
            logval(valueInUSD);
        }
        uint temp = SafeMath.mul(valueInUSD,statePrices[state]);
        if(state!=5){
            return (SafeMath.mul(valueInUSD,statePrices[state]),valueInUSD);
        }else{
            return ((SafeMath.div(valueInUSD*10000000,statePrices[state]))/10000,valueInUSD);
        }
    }
    
    function() payable{
        throw;
        ///do not allow any ether  contributions
    }
}
