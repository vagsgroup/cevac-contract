pragma solidity ^0.4.18;

import './SafeMath.sol';
import './Ownable.sol';
import './Pausable.sol';


contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


/*  ERC 20 token */
contract CevacToken is Token,Ownable {
    string public constant name = "Cevac Token";
    string public constant symbol = "CEVAC";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    uint public valueToBeSent = 1;

    bool public finalizedICO = false;

    uint256 public ethraised;
    uint256 public btcraised;
    uint256 public usdraised;


    uint256 public numberOfBackers;

    bool public istransferAllowed;

    uint256 public constant CevacFund = 36 * (10**8) * 10**decimals; 
    uint256 public fundingStartBlock; // crowdsale start unix //now
    uint256 public fundingEndBlock; // crowdsale end unix //1530403200 //07/01/2018 @ 12:00am (UTC)
    uint256 public tokenCreationMax= 1836 * (10**6) * 10**decimals;//TODO
    mapping (address => bool) public ownership;
    uint256 public minCapUSD = 210000000;
    uint256 public maxCapUSD = 540000000;


    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function burnTokens(uint256 _value) public{
        require(balances[msg.sender]>=_value);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender],_value);
        totalSupply =SafeMath.sub(totalSupply,_value);
    }


    //this is the default constructor
    function CevacToken(uint256 _fundingStartBlock, uint256 _fundingEndBlock){
        balances[owner] = CevacFund;
        totalSupply = CevacFund;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
       

    }

    ///change the funding end block
    function changeEndBlock(uint256 _newFundingEndBlock) public onlyOwner{
        fundingEndBlock = _newFundingEndBlock;
    }

    ///change the funding start block
    function changeStartBlock(uint256 _newFundingStartBlock) public onlyOwner{
        fundingStartBlock = _newFundingStartBlock;
    }

    ///the Min Cap USD 
    ///function too chage the miin cap usd
    function changeMinCapUSD(uint256 _newMinCap) public onlyOwner{
        minCapUSD = _newMinCap;
    }


    ///fucntion to change the max cap usd
    function changeMaxCapUSD(uint256 _newMaxCap) public onlyOwner{
        maxCapUSD = _newMaxCap;
    }


    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
      if(!istransferAllowed) throw;
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }


    function addToBalances(address _person,uint256 value) {
        if(!ownership[msg.sender]) throw;
        balances[owner] = SafeMath.sub(balances[owner],value);
        balances[_person] = SafeMath.add(balances[_person],value);
        Transfer(address(this), _person, value);
    }

    /**
    This is to add the token sale platform ownership to send tokens
    **/
    function addToOwnership(address owners) onlyOwner{
        ownership[owners] = true;
    }

    /**
    To be done after killing the old conttract else conflicts can take place
    This is to remove the token sale platform ownership to send tokens
    **/
    function removeFromOwnership(address owners) onlyOwner{
        ownership[owners] = false;
    }

    function balanceOf(address _owner) view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    function increaseEthRaised(uint256 value){
        require(ownership[msg.sender]);
        ethraised+=value;
    }

    function increaseBTCRaised(uint256 value){
        require(ownership[msg.sender]);
        btcraised+=value;
    }

    function increaseUSDRaised(uint256 value){
        require(ownership[msg.sender]);
        usdraised+=value;
    }

    function finalizeICO() public{
    require(ownership[msg.sender]);
    require(usdraised>=minCapUSD);
    finalizedICO = true;
    istransferAllowed = true;
    }

    function enableTransfers() public onlyOwner{
        istransferAllowed = true;
    }

    function disableTransfers() public onlyOwner{
        istransferAllowed = false;
    }

    //functiion to force finalize the ICO by the owner no checks called here
    function finalizeICOOwner() onlyOwner{
        finalizedICO = true;
        istransferAllowed = true;
    }

    function isValid() returns(bool){
        if(now>=fundingStartBlock && now<fundingEndBlock ){
            return true;
        }else{
            return false;
        }
        if(usdraised>maxCapUSD) throw;
    }

    ///do not allow payments on this address

    function() payable{
        throw;
    }
}

