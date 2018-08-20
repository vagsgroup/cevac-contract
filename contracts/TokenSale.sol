pragma solidity ^0.4.10;
import './CevacToken.sol';
import './Pausable.sol';
import './SafeMath.sol';
import './PricingStrategy.sol';
import './Ownable.sol';

contract TokenSale is Ownable,Pausable{

//----------------------------------------------------------------------------------------------------------
    ////CevacToken token
    CevacToken token;
    uint decimals = 8;
    bool public fundssent;
    uint256 public currentSupply;
    PricingStrategy pricingstrategy;

    ///ther mapping to hold the endTimestamps of the stages
    mapping(uint256 => uint256) public maxSaleableTokens;


    ///the mapping to hold the states and the cumulative tokens sold
    mapping(uint256 => uint256) public cumulativeTokens;

    ///the mapping to hold the max tokens saleable from stages
    mapping(uint256 => uint256) public stageEndTimestamps;

    //this will hold that what is the current supply of the tokens so that they do not go over the max supply
    ///the mapping to hold the max tokens saleable from stages
    mapping(uint256 => uint256) public currentSupplyStages;
    

//----------------------------------------------------------------------------------------------------------
    uint256 public tokenCreationMax= 1836 * (10**6) * 10**8;//TODO

    ///reserve
    uint256 public reserve = 1764000000 * 10**8;

    ///reserve address
    address public reserveAddress;


    ///the address of owner to recieve the token
    address public ownerAddr = 0xB0583785f27B7f87535B4c574D3B30928aD3A7eb ; //to be filled 

    ///the function to change the ownerAddr
    ///this is the address that will recieve the tokens
    function changeOwnerAddr(address addr) public onlyOwner{
        ownerAddr = addr;
    }

//----------------------------------------------------------------------------------------------------------
//the function to change the maxSaleable tokens
    function changeMaxSaleableTokens(uint256 state, uint256 value) public onlyOwner{
    maxSaleableTokens[state] = value;

    }
   
//----------------------------------------------------------------------------------------------------------
    //the function to change the maxSaleable tokens
    function changeEndTimestamps(uint256 state, uint256 newTimestamp) public onlyOwner{
        stageEndTimestamps[state] = newTimestamp;
    }

//----------------------------------------------------------------------------------------------------------

 ///this will be mapping against the hashes and whether they have been claimed or not
   mapping(uint256 => bool) public transactionsClaimed;
   uint256 public valueToBeSent;
   uint public investorCount;

//----------------------------------------------------------------------------------------------------------

    ///the event log to log out the address of the multisig wallet
    event logaddr(address addr);

//----------------------------------------------------------------------------------------------------------
    //the constructor function
    function TokenSale(address tokenAddress,address strategy){
        //require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input
        token = CevacToken(tokenAddress);
        valueToBeSent = token.valueToBeSent();
        pricingstrategy = PricingStrategy(strategy);
        ////MAX Tokens for private sale

        maxSaleableTokens[0] = 9 * (10**8) * (10**8);
        ///MAX tokens for presale 
        maxSaleableTokens[1] = 3 * (10**8) * (10**8);

        ///MAX tokens for the public sale
        maxSaleableTokens[2] = 15 * (10**7) * (10**8);
        maxSaleableTokens[3] = 15 * (10**7) * (10**8);
        maxSaleableTokens[4] = 15 * (10**7) * (10**8);
        maxSaleableTokens[5] = 186 * (10**6) * (10**8);


        cumulativeTokens[0] = maxSaleableTokens[0];
        cumulativeTokens[1] = maxSaleableTokens[0]+maxSaleableTokens[1];
        cumulativeTokens[2] = maxSaleableTokens[0]+maxSaleableTokens[1] + maxSaleableTokens[2];
        cumulativeTokens[3] = maxSaleableTokens[0]+maxSaleableTokens[1] + maxSaleableTokens[2]+maxSaleableTokens[3];
        cumulativeTokens[4] = maxSaleableTokens[0]+maxSaleableTokens[1] + maxSaleableTokens[2]+maxSaleableTokens[3]+maxSaleableTokens[4];
        cumulativeTokens[5] = maxSaleableTokens[0]+maxSaleableTokens[1] + maxSaleableTokens[2]+maxSaleableTokens[3]+maxSaleableTokens[4]+maxSaleableTokens[5];

        ///current sales
        currentSupplyStages[0] = 0; 
        currentSupplyStages[1] = 0;
        currentSupplyStages[2] = 0;
        currentSupplyStages[3] = 0;
        currentSupplyStages[4] = 0;
        currentSupplyStages[5] = 0;

    }
//----------------------------------------------------------------------------------------------------------
    /**
        Payable function to send the ether funds
    **/
    function() external payable stopInEmergency{
        // require(token.isValid());
        require(msg.value>0);
        uint currentState = getStateFunding();
        var (tokens,usd) = pricingstrategy.totalDiscount(currentState,msg.value,"ethereum");
        currentSupply = SafeMath.add(currentSupply,tokens);
        currentState = getStateFunding();
        require(SafeMath.add(currentSupply,tokens)<=tokenCreationMax);
        require(SafeMath.add(currentSupplyStages[currentState],tokens)<=cumulativeTokens[currentState]);
        currentSupplyStages[currentState] = SafeMath.add(currentSupplyStages[currentState],tokens);
        require(currentState!=6);
        require(currentState!=7);
        token.addToBalances(msg.sender,tokens);
        token.increaseEthRaised(msg.value);
        token.increaseUSDRaised(usd);
        if(!ownerAddr.send(this.balance))throw;
    }


//----------------------------------------------------------------------------------------------------------
    ///function to allot tokens to address
    function allottTokensBTC(address addr,uint256 value) public onlyOwner{
        require(token.isValid());
        uint currentState = getStateFunding();
        var (tokens,usd) = pricingstrategy.totalDiscount(currentState,value,"bitcoin");
        currentSupply = SafeMath.add(currentSupply,tokens);
        currentState = getStateFunding();
        require(SafeMath.add(currentSupplyStages[currentState],tokens)<=cumulativeTokens[currentState]);
        require(SafeMath.add(currentSupply,tokens)<=tokenCreationMax);
        require(currentState!=6);
        require(currentState!=7);
        currentSupplyStages[currentState] = SafeMath.add(currentSupplyStages[currentState],tokens);
        token.addToBalances(addr,tokens);
        token.increaseBTCRaised(value);
        token.increaseUSDRaised(usd);
    }

//----------------------------------------------------------------------------------------------------------

    ///function to alott tokens by the owner
    function alottTokensExchange(address contributor,uint256 tokens) public onlyOwner{
        currentSupply = SafeMath.add(currentSupply,tokens);
        uint currentState = getStateFunding();
        require(SafeMath.add(currentSupplyStages[currentState],tokens)<=cumulativeTokens[currentState]);
        require(SafeMath.add(currentSupply,tokens)<=tokenCreationMax);
        require(currentState!=6);
        require(currentState!=7);
        require(tokens>0);
        token.addToBalances(contributor,tokens);
        currentSupplyStages[currentState] = SafeMath.add(currentSupplyStages[currentState],tokens);

    }
//----------------------------------------------------------------------------------------------------------

    /////finalize the token sale
    function finalizeTokenSale() public onlyOwner{
        uint currentState = getStateFunding();
        if(currentState!=6) throw;
        token.finalizeICO();
    }
//----------------------------------------------------------------------------------------------------------

    ///kill the contract in case of change of functionality
    function killContract() public onlyOwner{
        selfdestruct(ownerAddr);
    }
//----------------------------------------------------------------------------------------------------------

    ///send tokens
    function sendTokens() public onlyOwner{
        if(fundssent) throw;
        token.addToBalances(reserveAddress,reserve);
        fundssent = true;
    }
//----------------------------------------------------------------------------------------------------------
    /**
    check if the owner state is set ot not
    **/
    bool public isOwnerStateSet = false;
    uint public ownerState;

    /**
    The function to set the owner defined state 
    **/
    function setOwnerState(uint state) public onlyOwner{
        ownerState = state;
        isOwnerStateSet = true;
    }

    /**
    The function for the owner to disable the owner state
    **/
    function disableOwnerState() public onlyOwner{
        isOwnerStateSet = false;
    }

    /**
    The function to get the state of the funding for the ico
    **/
    function getStateFunding() returns (uint){
       if(isOwnerStateSet) return ownerState;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[0]) return 0;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[1]) return 1;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[2]) return 2;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[3]) return 3;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[4]) return 4;
       if(now>token.fundingStartBlock() && currentSupply<=cumulativeTokens[5]) return 5;
       if(now>token.fundingEndBlock() && token.usdraised()<token.minCapUSD()) return 7;
       if(now>token.fundingEndBlock() && token.usdraised()>=token.minCapUSD()) return 6;
    }



    

}