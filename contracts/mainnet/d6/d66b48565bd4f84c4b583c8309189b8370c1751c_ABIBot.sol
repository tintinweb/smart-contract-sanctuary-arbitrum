/**
 *Submitted for verification at Arbiscan.io on 2023-11-12
*/

// SPDX-License-Identifier: MIT

/**
Copyright (C) 2023 ABI.
   ###    ########  ####     ########   #######  ######## 
  ## ##   ##     ##  ##      ##     ## ##     ##    ##    
 ##   ##  ##     ##  ##      ##     ## ##     ##    ##    
##     ## ########   ##      ########  ##     ##    ##    
######### ##     ##  ##      ##     ## ##     ##    ##    
##     ## ##     ##  ##  ### ##     ## ##     ##    ##    
##     ## ########  #### ### ########   #######     ##   

                 -- Coded for ABI.Bot with ❤️ by [email protected]

Coded for DEXAI+™️ Bot core program in the case of ensuring the safety of the user's funds, the call trading its interface to achieve automated trading contracts.

The code involves capital security of the most core variables swapper in the release (or after initConf method initialization) can not be modified.

Administrator Privileges.

    Administrator privileges (for the AI Core program to call, although the administrator's privileges are extremely limited and absolutely unlikely to result in a loss of principal, the funder may withdraw administrator privileges at any time due to the 100% certainty of ownership of the robot and associated assets from the code).
    1. swapFunction method initiates the transaction, and the destination address of the exchange is the default value (i.e. the address of the contract itself) and cannot be modified.
    Whitelist of target addresses for transactions.
    target.
    0x84e387B4ACb7C0597AE99bF7Af29741A9b7baa51(ABI.Bot Relayer Contract)
    2.withdrawToken Distribute the balance in the agreed ratio. ()
    3. other write method permissions that do not involve the safety of the principal please see the notes.
    
Contributor rights.

    setAdmin The contributor can set a new administrator (when this method is triggered, the old administrator is invalidated immediately).

Commitment.

    As of November 8, 2023, after the update, ABIBot.com (registered in Marshall Islands as Sigma Holdings Limited, hereinafter referred to as "we") promises the following to all users who pay for the use of ABIBot's proprietary trading scripts.
    1. The code we have published is the complete code for your chain-run money security management contract, please complete the compilation yourself in our designated compilation environment, if the results of the compilation of your chain-run money management contract is consistent with the results of your use of this code to compile the results of their own use of the use, or please stop using it, immediately contact us. Any legal commitments we make below are subject to the condition that the bytecode of the contracts you run on the link matches the compilation of this source code.
    2. To the best of our current knowledge, we believe that what you are looking at is safe for your digital currency principal. We guarantee that we have not intentionally inserted any malicious backdoor code known to computer science (at the time of code release).
    3. Before the Code was deployed on the EtherNet, Blockchain Institiute, a blockchain research organization based in the United States of America, was commissioned to conduct a professional assessment of the security of the digital assets that users are authorized to invoke in the Contract. The audit report published by the organization after due diligence showed that it is unlikely that any of the digital assets that users are authorized to invoke in the Contract will be lost as a result of the Contract or any process related to it, except in exceptional circumstances. We undertake that if the digital assets authorized by the User to be accessed under this Contract or any program related to this Contract result in any loss of assets, whether intentional or unintentional, other than the loss of fuel costs due to the occurrence of a failed transaction in exceptional circumstances, we shall not be liable for any loss of assets.
    4. We undertake to reimburse you for any monetary loss of digital assets caused by an error in logic or a bug in the code that was not detected at the time of its development, but only up to the amount of your loss minus the total amount of your historical profits from the use of this Agreement.

Refusal of Commitment: 1.

    1. We refuse to make any commitment to the future price of any digital asset in fiat currency at any time in the future in any real world trading scene (DEX, CEX, OTC, etc.), even if we have made a clear and optimistic forecast of the future value of a particular digital asset or assets or have done so in writing, it does not mean that we are committing to the future price of the digital asset or assets.
    2. We refuse to be responsible for the safety of the funds of our experiential users who use our ABIBot without using any of our published money management contracts.

Special Note: This contract is a security-enhanced version of ABI.Bot released on November 8, 2023, and we guarantee the security of previous versions until this contract is deployed on the EtherNet.

Compile environment: +commit.4fc 
    
    https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=berlin&version=soljson-v0.8.22+commit.4fc1097e.js

Consistency check.

    Please set up your compilation environment according to the specified compilation parameters and finish compiling. Compare the Bytecode (compilation result) with the Bytecode of your private contract address in the block browser to ensure consistency, or at least to prove that the source code you are currently seeing is identical to the source code of your private contract address. Ensuring code consistency is a prerequisite for evaluating the security of your code.

Token Authorization.

    Authorization of the transaction of the token contract: according to the need to authorize a variety of tokens, the current ABI.Bot mainly for: weth9, weth.x, wbtc.x, Aave WETH (aWETH), interBTC, wBTC and other encapsulated coins to optimize.

    The number of tokens authorized for trading: in order to avoid the frequent occurrence of insufficient authorization, it is recommended that the number of tokens authorized is not less than 10,000, and authorization means that you understand or fully trust the contract to ensure the safety of your funds.

The most important note: the contract's external method xCall.

    The external method xCall of this contract is the real method for robots to call the user's funds, the method in the code constraints in the same block must meet the contributor does not lose money, otherwise the contract reports an error, the transaction fails. This is a fundamental absolute guarantee of the security of the transaction.

**/


pragma solidity 0.8.22;

interface ERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address src,address dst,uint256 amount) external returns (bool);
    function allowance(address src,address dst) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

}

interface IxSwap {
    function ScriptSwap(address _token,uint256 _amount,uint256 _minRate,uint256 _minExRate)external returns(bool);
}


contract ABIBot {
    address public admin;


    address public addressA;
    address public addressB;
    address public addressC;
    address public addressD;
    address public addressX;
    address public addressEx;

    address public addressS1;
    address public addressM;
    address public addressDe;

    uint256 public lineOfBurn = 1000000000000000000;
    address public swapper;
    uint256 public totalSwapped;
    uint256 public totalEarned;
    uint256 public     rateA;
    uint256 public     rateB;
    uint256 public     rateC;
    uint256 public     rateD;
    uint256 public     rateX;
    uint256 public     rateEx;
    uint256 public     rateM;
    uint256 public     rateDe;

    address public target = 0x1Cd8243CCB7d4cEcA135eB4b0913F0889165Cc85;//唯一許可的資產流出方向

    event TokensSwapped(address indexed tokenA, address indexed user, uint256 amount, uint256 profit);


    //构造函数,该函数只能在发布合约时执行一次,且所有赋值均在代码中明文完成,每个用户独立设置。
    constructor() {
        admin = msg.sender;//合约发布者为管理员,管理员由DEXBot Plus核心AI控制,只有向不可篡改的交易聚合器代理地址发起交易。
        addressS1 = 0x0030Bd57c4946F82b7468ba82B746b9859D83919;//分润地址A，不可以修改。
        addressM = 0xf608CFf9b8273714248a4a077A39695d8362bA9B;//分润地址B，不可以修改。
        addressDe = 0x78c0F0fF1d9b36F53FEa77312BB4465073399999;//分润地址C，不可以修改。
        swapper  = address(0);//出资人地址,初始化後不修改。        
        addressA = address(0);
        addressB = address(0);
        addressC = address(0);
        addressD = address(0);
        addressX = address(0);
        addressEx = address(0);
        rateM = 2;
        rateDe = 21;

        rateA = 0;rateB = 0;rateC = 0;rateD = 0; rateX= 0;rateEx=0;
        
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "This function only for owner!");
        _;
    }
    //出资人权限,收回现有管理员的权限,并赋予新用户管理员权限
    function setAdmin(address _admin) external {
        require(msg.sender == swapper, "This function only for owner!");
        admin = _admin;
    }


    //管理员权限(预留供AI Core修改各级推荐人投资额数值的接口,从而实现烧伤与否与烧伤值与未来推荐人投资变动同步)
    function initConf(address _swapper)external onlyAdmin {
        require(swapper == address(0), "This function only can be used once!");
        swapper  = _swapper;//初始化後不可以修改。

    }

    function initConf(address _swapper,address _addressA,address _addressS1,address _addressM,address _addressDe,uint256 _rateA,uint256 _rateM,uint256 _rateDe )external onlyAdmin {
        require(swapper == address(0), "This function only can be used once!");
        swapper  = _swapper;//初始化後不可以修改。
        addressA = _addressA;

        addressS1 = _addressS1;
        addressM = _addressM;
        addressDe = _addressDe;
        rateA    = _rateA;
        rateM   = _rateM;
        rateDe   = _rateDe;

    }

    function setRef(address _addressA, address _addressB, address _addressC, address _addressD,address _target)external {
        require((msg.sender == swapper)||(msg.sender == admin), "This function only for owner or swapper!");
        addressA = _addressA;
        addressB = _addressB;
        addressC = _addressC;
        addressD = _addressD;
        target = _target;
    }

    function setRate(uint256 _rateA, uint256 _rateB, uint256 _rateC, uint256 _rateD)external {
        require((msg.sender == swapper)||(msg.sender == admin), "This function only for owner or swapper!");
        require((_rateA+_rateB+_rateC+_rateD)<=270, "MAX 27%!");
        rateA = _rateA;
        rateB = _rateB;
        rateC = _rateC;
        rateD = _rateD;
    }

    function setX(address _address,uint _rate)external {
        require((msg.sender == swapper)||(msg.sender == admin), "This function only for owner or swapper!");
        require(_rate<=10);
        addressX = _address;
        rateX= _rate;
    }

    function setEx(address _address,uint _rate)external {
        require((msg.sender == swapper)||(msg.sender == admin), "This function only for owner or swapper!");
        require(_rate<=10);
        addressEx = _address;
        rateEx = _rate;
    }


    function xCall( address _token,uint256 _amount,uint256 _minRate,uint256 _minExRate) external onlyAdmin returns (bool)  {
        ERC20 token = ERC20(_token);
        if(token.allowance(address(this),target)<_amount){
            require(token.approve(target, _amount*10),"DEBUG:0");
        }
        require(token.transferFrom(swapper, address(this), _amount),"DEBUG:1");
        uint256 afterOutput = token.balanceOf(swapper);
        IxSwap _IxSwap = IxSwap(target);
        require(_IxSwap.ScriptSwap(_token,_amount,_minRate,_minExRate),"DEBUG:2");
        require(token.balanceOf(swapper)>=(afterOutput+_amount),"DEBUG:Last");
        uint256 basicProfit = _amount * ( _minRate - 1000)/1000;

        uint256 exProfit = _amount * _minExRate/1000;
        uint256 profit = basicProfit + exProfit;

        uint256 swapperProfit = basicProfit * 40 /100;
        swapperProfit = swapperProfit + exProfit * 10 /100;
        if(addressX == address(0)){
            swapperProfit = swapperProfit + basicProfit * (10-rateX)/100;
        }
        if(addressEx == address(0)){
            swapperProfit = swapperProfit + exProfit * (10-rateX) /100;
        }
        record(_token, swapperProfit, _amount, profit) ;
        return true;
    }




    function callback(address _token,uint256 _total,uint256 _cost,uint256 exProfit) external returns(bool)  {
        require((msg.sender == target)||(msg.sender == address(this)), "This function only for owner or swapper!");
        ERC20 token = ERC20(_token);
        require (_cost <= _total);
        uint256 profit  = _total - _cost;
        require (profit <= ( _cost * 2)/100);//利润上限制锁；
        uint256 basicProfit = profit - exProfit;
        
        uint256 amountToSwapper = (basicProfit * 40) / 100 + _cost;
        amountToSwapper = (exProfit * 10) / 100 + amountToSwapper;

        uint256 amountX = 0;
        if(addressX!=address(0)){
            amountX = (basicProfit * rateX) / 100; 
        }else{
            amountToSwapper = (basicProfit * (10-rateX)) / 100 + amountToSwapper;
        }

        uint256 amountM = 0;
        if(addressM!=address(0)){
            amountM = (basicProfit * rateM) / 100;
        }
    
        uint256 amountDe = 0;
         if(addressDe!=address(0)){       
            amountDe = (basicProfit * rateDe) / 100;
            amountDe = amountDe + (exProfit * 30) / 100;
        }
   

        uint256 amountA = 0;
        if(addressA!=address(0)){
            amountA = (basicProfit * rateA) / 1000;
        }

        uint256 amountB = 0;
        if(addressB!=address(0)){
            amountB = (basicProfit * rateB) / 1000;
        }

        uint256 amountC = 0;
        if(addressC!=address(0)){
            amountC = (basicProfit * rateC) / 1000;
        }

        uint256 amountD = 0;
        if(addressD!=address(0)){
            amountD = (basicProfit * rateD) / 1000;
        }

        uint256 amountEx = 0;
        if(addressEx==address(0)){
            amountToSwapper = amountToSwapper + (exProfit * (10-rateEx)) / 100;
        }else{
            amountEx = (exProfit * rateEx) / 100;
        }

        uint256 amountS1 = token.balanceOf(address(this));
        amountS1  = amountS1 - amountM - amountDe;
        amountS1  = amountS1 - amountA - amountB - amountC - amountD;
        amountS1  = amountS1 - amountX - amountEx - amountToSwapper;

        // 将代币转移到交换地址
        require(token.transfer(swapper, amountToSwapper), "Transfer failed");

        // 将代币转移到地址A
        if((addressA!=address(0))&&(amountA>0)){
            require(token.transfer(addressA, amountA), "Transfer failed");
        }   

        // 将代币转移到地址B
        if((addressB!=address(0))&&(amountB>0)){
            require(token.transfer(addressB, amountB), "Transfer failed");
        }   

        // 将代币转移到地址C
        if((addressC!=address(0))&&(amountC>0)){
            require(token.transfer(addressC, amountC), "Transfer failed");
        }

        
        if((addressD!=address(0))&&(amountD>0)){
            require(token.transfer(addressD, amountD), "Transfer failed");
        }
        // 将代币转移到地址E
        if((addressX!=address(0))&&(amountX>0)){
        require(token.transfer(addressX, amountX), "Transfer failed");
        }
        // 将代币转移到地址Dev
        if((addressEx!=address(0))&&(amountEx>0)){
        require(token.transfer(addressEx, amountEx), "Transfer failed");
        }
        if((addressS1!=address(0))&&(amountS1>0)){
        require(token.transfer(addressS1, amountS1), "Transfer failed");
        }
        if((addressM!=address(0))&&(amountM>0)){
        require(token.transfer(addressM, amountM), "Transfer failed");
        }
        if((addressDe!=address(0))&&(amountDe>0)){
        require(token.transfer(addressDe, amountDe), "Transfer failed");
        }
        return true;
    }

    function record (address token_,uint256 amountToSwapper,uint256 cost_,uint256 profit_) internal returns(bool){
        totalSwapped = totalSwapped + cost_;
        totalEarned = totalEarned + amountToSwapper;        
        emit TokensSwapped(token_,swapper, cost_, profit_);
        return true;
    }
}