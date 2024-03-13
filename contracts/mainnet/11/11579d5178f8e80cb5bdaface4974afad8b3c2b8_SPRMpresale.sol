/**
 *Submitted for verification at Arbiscan.io on 2024-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract SPRMpresale {

    IERC20 immutable public  usdt ;
    IERC20 immutable public  usdc ;
    
    IERC20 immutable public token ;

    bool public paused; 

    address public owner;

    uint256 public perDollarPrice; 

    uint256 public UsdtoEth; 

    mapping (address => mapping (address => bool)) public referral;

    modifier onlyOwner {
        require(owner == msg.sender,"Caller must be Ownable!!");
        _;
    }

    constructor(uint256 _price,address _presaleToken , uint _perUsdtoEth , address _usdt , address _usdc){

        owner = msg.sender;
        perDollarPrice = _price;
        token = IERC20(_presaleToken);
        UsdtoEth = _perUsdtoEth;
        usdt = IERC20(_usdt);
        usdc = IERC20(_usdc);

    }
    
    //per dollar price in decimals
    function setTokenPrice(uint _price) public onlyOwner{
        perDollarPrice = _price;
    }

    //per dollar price in decimals of bnb
    function setEthPrice(uint _price) public onlyOwner{
        UsdtoEth = _price;
    }

    function setPause(bool _value) public onlyOwner{
        paused = _value;
    }


    //pid for selection of token USDT -> 1 or busd -> 2
    function buyfromToken(uint _pid,address ref,uint _amount) public {
        
        require(!paused, "Presale is Paused!!");

        uint check = 1;   

        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){}
        else{
            referral[msg.sender][ref] = true;
            check = 2;
        }

        if(_pid == 1){
            
                if(check == 2){
                    uint per5 = ( _amount * 5 ) / 100;
                    uint per95 = ( _amount * 95 ) / 100;
                    
                    usdt.transferFrom(msg.sender,ref,per5);
                    usdt.transferFrom(msg.sender,owner,per95);
                }
                else{
                    usdt.transferFrom(msg.sender,owner,_amount);
                }
            
            uint temp = _amount;
         
           uint multiplier = (temp*perDollarPrice)/10**18;

            token.transfer(msg.sender,multiplier);

        }
        else if(_pid == 2){
            
            if(check == 2){
                uint per5 = ( _amount * 5 ) / 100;
                uint per95 = ( _amount * 95 ) / 100;
                usdc.transferFrom(msg.sender,ref,per5);
                usdc.transferFrom(msg.sender,owner,per95);
           
            }
            else{
              usdc.transferFrom(msg.sender,owner,_amount);
            }

            uint temp = _amount;
            uint multiplier = (temp*perDollarPrice)/10**18; 
            token.transfer(msg.sender,multiplier);
        }
        else {
            revert("Wrong Selection!!");
        }


    }


    function buyFromNative(address ref) public payable {

        require(!paused,"Presale is Paused!!");

        uint check = 1;   

        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){}
        else{
            referral[msg.sender][ref] = true;
            check = 2;
        }

        uint value = msg.value;

        uint equaltousd = value* UsdtoEth;

        uint multiplier = (perDollarPrice * equaltousd)/(1000000000000000000*10**18);

        token.transfer(msg.sender,multiplier);

        if(check == 2){
            uint per5 = ( value * 5 ) / 100;
            uint per95 = ( value * 95 ) / 100;
            payable(ref).transfer(per5);
            payable(owner).transfer(per95);
        }
        else{
            payable(owner).transfer(value);
        }

    }

    function RescueFunds() public onlyOwner {
        payable(msg.sender).transfer( address(this).balance );
    }

    function RescueTokens(IERC20 _add,uint _amount,address _recipient) public onlyOwner{
        _add.transfer(_recipient,_amount);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

}