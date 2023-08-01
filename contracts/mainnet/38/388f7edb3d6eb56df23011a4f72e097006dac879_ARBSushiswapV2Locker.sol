/**
 *Submitted for verification at Arbiscan on 2023-07-31
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.19;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IMigrator {
    function migrate(
        address lockowner,
        address lpaddress,
        uint256 unlockdate,
        uint256 lockamount,
        uint256 lockid
    ) external;
}

interface ISushiFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

interface ISushiswapV2Router02 {
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract ARBSushiswapV2Locker {
    constructor(ISushiFactory factory, ISushiswapV2Router02 sushiswaprouter) {
        owner = msg.sender;
        sushiswapFactory = factory;
        sushiswapRouter = sushiswaprouter;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    struct newLock {
        address lockowner;
        address lpaddress;
        uint256 unlockdate;
        uint256 lockamount;
        uint256 lockid;
    }

    struct fastLock {
        address tokenaddress1;
        address tokenaddress2;
        uint256 amount1Desired;
        uint256 amount2Desired;
        uint256 amount1Min;
        uint256 amount2Min;
    }

    struct fastLockETH {
        address tokenaddress;
        address owner;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountETHMin;
    }

    address owner;
    address payable devaddr;
    ISushiswapV2Router02 public sushiswapRouter;
    address _sushiswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    ISushiFactory public sushiswapFactory;
    uint256 public ETH = 100;
    address public delugeToken; 
    uint256 public percentFeeInTokens = 75;
    bool public paused;
    newLock[] public locks;
    address public newContract;
    mapping(address => uint256[]) public ownerLocks;
    mapping(address => uint256[]) public tokenLocks;
    mapping(address => uint256) public approvedTimeFastLock;
    mapping(address => bool) public approvedFastBurn;
    mapping(address => bool) public isExcludedFromFee;
    event lpLocked(
        address indexed tokenaddress,
        uint256 amount,
        uint256 unlocktime,
        address indexed owner,
        uint256 indexed locknumber
    );
    event lpWithdrawn(
        address indexed tokenaddress,
        uint256 amount,
        address indexed owner,
        uint256 indexed locknumber
    );
    event newLPadded(uint256 indexed newLPamount, uint256 indexed locknumber);
    event lockExtended(uint256 indexed newTime, uint256 indexed locknumber);
    event ownerUpdated(address indexed newOwner, uint256 indexed locknumber);
    event lpFastBurnt(address indexed lptoken, uint256 indexed liquidity);
    event newTimeApproved(
        address indexed _address,
        uint256 indexed approvedTime
    );
    event fastBurnApproved(address indexed _address);

    receive() external payable {}
    fallback() external payable {}

    function change(uint256 newETH) external onlyOwner {
        require(500000000000000000 >= newETH);
        ETH = newETH;
    }

    function withdrawStuckETH() external onlyOwner {
        devaddr.call{value: address(this).balance};
    }

    function changeTokenAddress(address newaddress) external onlyOwner {
        delugeToken = newaddress;
    }

    function changeNewContract(address newcontract) external onlyOwner {
        newContract = newcontract;
    }

    function changeaddress(address payable newaddress) external onlyOwner {
        devaddr = newaddress;
    }

    function changePercentFeeInTokens(uint256 newpercent) external onlyOwner {
        require(newpercent > 49);
        percentFeeInTokens = newpercent;
    }

    function manageIsExcludedFromFee(address addr, bool value) external onlyOwner {
        isExcludedFromFee[addr] = value;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function lockTokens(
        address token,
        uint256 amount,
        uint256 locktime,
        bool isFeeInTokens,
        address _owner
    ) external payable {
        if(!isExcludedFromFee[msg.sender]){
            if (isFeeInTokens) {
                uint256 feeInTokens = getFeeInTokens();
                uint256 senderBalance = IERC20(delugeToken).balanceOf(msg.sender);
                if(feeInTokens > senderBalance && feeInTokens / 100 * 95 <= senderBalance){
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), senderBalance);
                    IERC20(delugeToken).transfer(devaddr, senderBalance);
                }
                else{
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), feeInTokens);
                    IERC20(delugeToken).transfer(devaddr, feeInTokens);
                }
            }
            else {
                require(msg.value == ETH);
                (bool sent, ) = devaddr.call{value: ETH}("");
                require(sent);
            }
        }
        require(amount > 0);
        require(locktime > 3599);
        require(!paused);
        require(IERC20(token).allowance(msg.sender, address(this)) >= amount);

        uint256 oldBalance = IERC20(token).balanceOf(address(this));
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 newBalance = IERC20(token).balanceOf(address(this));
        require(oldBalance == newBalance - amount);

        uint256 newLockNumber = locks.length;
        ownerLocks[_owner].push(newLockNumber);
        tokenLocks[token].push(newLockNumber);
        uint256 unlocktime = block.timestamp + locktime;

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = token;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = amount;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(token, amount, unlocktime, _owner, newLockNumber);
    }

    function withdrawLP(uint256 lockNumber) external {
        require(msg.sender == locks[lockNumber].lockowner);
        require(block.timestamp >= locks[lockNumber].unlockdate);
        require(locks[lockNumber].lockamount > 0);
        IERC20(locks[lockNumber].lpaddress).transfer(
            msg.sender,
            locks[lockNumber].lockamount
        );
        locks[lockNumber].lockamount = 0;
        emit lpWithdrawn(
            locks[lockNumber].lpaddress,
            locks[lockNumber].lockamount,
            locks[lockNumber].lockowner,
            locks[lockNumber].lockid
        );
    }

    function addNewLP(uint256 lockNumber, uint256 amount) external {
        require(amount > 0);
        require(locks[lockNumber].unlockdate > block.timestamp);
        require(msg.sender == locks[lockNumber].lockowner);
        require(
            IERC20(locks[lockNumber].lpaddress).allowance(
                msg.sender,
                address(this)
            ) >= amount
        );
        IERC20(locks[lockNumber].lpaddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        locks[lockNumber].lockamount = locks[lockNumber].lockamount + amount;
        emit newLPadded(amount, lockNumber);
    }

    function extendLock(uint256 locknumber, uint256 newunlocktime) external {
        require(locks[locknumber].unlockdate > block.timestamp);
        require(msg.sender == locks[locknumber].lockowner);
        require(newunlocktime > locks[locknumber].unlockdate);
        locks[locknumber].unlockdate = newunlocktime;
        emit lockExtended(newunlocktime, locknumber);
    }

    function updateOwner(uint256 locknumber, address newowner) external {
        require(locks[locknumber].unlockdate > block.timestamp);
        require(msg.sender == locks[locknumber].lockowner);
        require(newowner != locks[locknumber].lockowner);
        locks[locknumber].lockowner = newowner;
        emit ownerUpdated(newowner, locknumber);
    }

    function approveCustomTime(uint256 approveTime) external {
        approvedTimeFastLock[msg.sender] = approveTime;
        emit newTimeApproved(msg.sender, approveTime);
    }

    function approve365DaysLock() external {
        approvedTimeFastLock[msg.sender] = 31536000;
        emit newTimeApproved(msg.sender, 31536000);
    }

    function approve180DaysLock() external {
        approvedTimeFastLock[msg.sender] = 15552000;
        emit newTimeApproved(msg.sender, 15552000);
    }

    function approve90DaysLock() external {
        approvedTimeFastLock[msg.sender] = 7776000;
        emit newTimeApproved(msg.sender, 7776000);
    }

    function approve30DaysLock() external {
        approvedTimeFastLock[msg.sender] = 2592000;
        emit newTimeApproved(msg.sender, 2592000);
    }

    function approve15DaysLock() external {
        approvedTimeFastLock[msg.sender] = 1296000;
        emit newTimeApproved(msg.sender, 1296000);
    }

    function approve7DaysLock() external {
        approvedTimeFastLock[msg.sender] = 604800;
        emit newTimeApproved(msg.sender, 604800);
    }

    function approve1DayLock() external {
        approvedTimeFastLock[msg.sender] = 86400;
        emit newTimeApproved(msg.sender, 86400);
    }

    function approveFastBurnLP() external {
        approvedFastBurn[msg.sender] = true;
        emit fastBurnApproved(msg.sender);
    }

    function fastLockLPWithTokens(
        address tokenaddress1,
        address tokenaddress2,
        uint256 amount1Desired,
        uint256 amount2Desired,
        uint256 amount1Min,
        uint256 amount2Min,
        bool isFeeInTokens,
        address _owner
    ) external payable {
        if(!isExcludedFromFee[msg.sender]){
            if (isFeeInTokens) {
                uint256 feeInTokens = getFeeInTokens();
                uint256 senderBalance = IERC20(delugeToken).balanceOf(msg.sender);
                if(feeInTokens > senderBalance && feeInTokens / 100 * 95 <= senderBalance){
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), senderBalance);
                    IERC20(delugeToken).transfer(devaddr, senderBalance);
                }
                else{
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), feeInTokens);
                    IERC20(delugeToken).transfer(devaddr, feeInTokens);
                }
            }
            else {
                require(msg.value == ETH);
                (bool sent, ) = devaddr.call{value: ETH}("");
                require(sent);
            }
        }
        require(!paused);
        require(amount1Desired > 0 && amount2Desired > 0);
        require(approvedTimeFastLock[msg.sender] > 3599);
        require(
            IERC20(tokenaddress1).allowance(msg.sender, address(this)) >=
                amount1Desired
        );
        require(
            IERC20(tokenaddress2).allowance(msg.sender, address(this)) >=
                amount2Desired
        );

        fastLock memory fastlock;
        fastlock.tokenaddress1 = tokenaddress1;
        fastlock.tokenaddress2 = tokenaddress2;
        fastlock.amount1Desired = amount1Desired;
        fastlock.amount2Desired = amount2Desired;
        fastlock.amount1Min = amount1Min;
        fastlock.amount2Min = amount2Min;

        uint256 oldBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 oldBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        IERC20(tokenaddress1).transferFrom(
            msg.sender,
            address(this),
            amount1Desired
        );
        IERC20(tokenaddress2).transferFrom(
            msg.sender,
            address(this),
            amount2Desired
        );
        uint256 newBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 newBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        require(
            oldBalance1 == newBalance1 - amount1Desired &&
                oldBalance2 == newBalance2 - amount2Desired
        );

        IERC20(fastlock.tokenaddress1).approve(_sushiswapRouter, amount1Desired);
        IERC20(fastlock.tokenaddress2).approve(_sushiswapRouter, amount2Desired);
        (, , uint256 liquidity) = sushiswapRouter.addLiquidity(
            fastlock.tokenaddress1,
            fastlock.tokenaddress2,
            fastlock.amount1Desired,
            fastlock.amount2Desired,
            fastlock.amount1Min,
            fastlock.amount2Min,
            address(this),
            block.timestamp
        );

        if (IERC20(tokenaddress1).balanceOf(address(this)) > oldBalance1) {
            IERC20(tokenaddress1).transfer(
                msg.sender,
                IERC20(fastlock.tokenaddress1).balanceOf(address(this)) -
                    oldBalance1
            );
        }

        if (IERC20(tokenaddress2).balanceOf(address(this)) > oldBalance2) {
            IERC20(tokenaddress2).transfer(
                msg.sender,
                IERC20(fastlock.tokenaddress2).balanceOf(address(this)) -
                    oldBalance2
            );
        }

        address lptoken = sushiswapFactory.getPair(
            fastlock.tokenaddress1,
            fastlock.tokenaddress2
        );

        uint256 locktime = approvedTimeFastLock[msg.sender];
        approvedTimeFastLock[msg.sender] = 0;
        uint256 unlocktime = block.timestamp + locktime;

        uint256 newLockNumber = locks.length;
        ownerLocks[_owner].push(newLockNumber);
        tokenLocks[lptoken].push(newLockNumber);

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = lptoken;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = liquidity;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(lptoken, liquidity, unlocktime, _owner, newLockNumber);
    }

    function fastLockLPWithETH(
        address tokenaddress,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        bool isFeeInTokens,
        address _owner
    ) external payable {
        uint256 ETHForLP;
        if(!isExcludedFromFee[msg.sender]){
            if (isFeeInTokens) {
                uint256 feeInTokens = getFeeInTokens();
                uint256 senderBalance = IERC20(delugeToken).balanceOf(msg.sender);
                if(feeInTokens > senderBalance && feeInTokens / 100 * 95 <= senderBalance){
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), senderBalance);
                    IERC20(delugeToken).transfer(devaddr, senderBalance);
                }
                else{
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), feeInTokens);
                    IERC20(delugeToken).transfer(devaddr, feeInTokens);
                }
                ETHForLP = msg.value;
            }
            else {
                require(msg.value > ETH);
                (bool sent, ) = devaddr.call{value: ETH}("");
                require(sent);
                ETHForLP = msg.value - ETH;
            }
        }
        require(approvedTimeFastLock[msg.sender] > 3599);
        require(!paused);
        require(amountTokenDesired > 0);
        require(
            IERC20(tokenaddress).allowance(msg.sender, address(this)) >=
                amountTokenDesired
        );

        fastLockETH memory fastlockETH;
        fastlockETH.tokenaddress = tokenaddress;
        fastlockETH.owner = _owner;
        fastlockETH.amountTokenDesired = amountTokenDesired;
        fastlockETH.amountTokenMin = amountTokenMin;
        fastlockETH.amountETHMin = amountETHMin;

        uint256 oldBalance = IERC20(tokenaddress).balanceOf(address(this));
        IERC20(tokenaddress).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        uint256 newBalance = IERC20(tokenaddress).balanceOf(address(this));
        require(oldBalance == newBalance - amountTokenDesired);

        uint256 oldBalanceETH = address(this).balance - ETHForLP;
        IERC20(tokenaddress).approve(_sushiswapRouter, amountTokenDesired);
        (, , uint256 liquidity) = sushiswapRouter.addLiquidityETH{
            value: ETHForLP
        }(
            fastlockETH.tokenaddress,
            fastlockETH.amountTokenDesired,
            fastlockETH.amountTokenMin,
            fastlockETH.amountETHMin,
            address(this),
            block.timestamp
        );
        uint256 newBalanceETH = address(this).balance;

        if (newBalanceETH > oldBalanceETH) {
            (bool sent, ) = payable(msg.sender).call{value: newBalanceETH - oldBalanceETH}("");
            require(sent);
        }

        if (IERC20(tokenaddress).balanceOf(address(this)) > oldBalance) {
            IERC20(tokenaddress).transfer(
                msg.sender,
                IERC20(fastlockETH.tokenaddress).balanceOf(address(this)) -
                    oldBalance
            );
        }

        address lptoken = sushiswapFactory.getPair(
            fastlockETH.tokenaddress,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
        );

        uint256 locktime = approvedTimeFastLock[msg.sender];
        approvedTimeFastLock[msg.sender] = 0;
        uint256 unlocktime = block.timestamp + locktime;

        uint256 newLockNumber = locks.length;
        ownerLocks[fastlockETH.owner].push(newLockNumber);
        tokenLocks[lptoken].push(newLockNumber);

        newLock memory newlock;
        newlock.lockowner = _owner;
        newlock.lpaddress = lptoken;
        newlock.unlockdate = unlocktime;
        newlock.lockamount = liquidity;
        newlock.lockid = newLockNumber;

        locks.push(newlock);

        emit lpLocked(lptoken, liquidity, unlocktime, _owner, newLockNumber);
    }

    function fastBurnLPWithETH(
        address tokenaddress,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        bool isFeeInTokens
    ) external payable {
        uint256 ETHForLP;
        if(!isExcludedFromFee[msg.sender]){
            if (isFeeInTokens) {
                uint256 feeInTokens = getFeeInTokens();
                uint256 senderBalance = IERC20(delugeToken).balanceOf(msg.sender);
                if(feeInTokens > senderBalance && feeInTokens / 100 * 95 <= senderBalance){
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), senderBalance);
                    IERC20(delugeToken).transfer(devaddr, senderBalance);
                }
                else{
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), feeInTokens);
                    IERC20(delugeToken).transfer(devaddr, feeInTokens);
                }
                ETHForLP = msg.value;
            }
            else {
                require(msg.value > ETH);
                (bool sent, ) = devaddr.call{value: ETH}("");
                require(sent);
                ETHForLP = msg.value - ETH;
            }
        }
        require(!paused);
        require(amountTokenDesired > 0);
        require(approvedFastBurn[msg.sender] == true);
        require(
            IERC20(tokenaddress).allowance(msg.sender, address(this)) >=
                amountTokenDesired
        );

        uint256 oldBalance = IERC20(tokenaddress).balanceOf(address(this));
        IERC20(tokenaddress).transferFrom(
            msg.sender,
            address(this),
            amountTokenDesired
        );
        uint256 newBalance = IERC20(tokenaddress).balanceOf(address(this));
        require(oldBalance == newBalance - amountTokenDesired);

        uint256 oldBalanceETH = address(this).balance - ETHForLP;
        IERC20(tokenaddress).approve(_sushiswapRouter, amountTokenDesired);
        (, , uint256 liquidity) = sushiswapRouter.addLiquidityETH{
            value: ETHForLP
        }(
            tokenaddress,
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            address(0),
            block.timestamp
        );
        uint256 newBalanceETH = address(this).balance;

        if (newBalanceETH > oldBalanceETH) {
            (bool sent, ) = payable(msg.sender).call{value: newBalanceETH - oldBalanceETH}("");
            require(sent);
        }

        if (IERC20(tokenaddress).balanceOf(address(this)) > oldBalance) {
            IERC20(tokenaddress).transfer(
                msg.sender,
                IERC20(tokenaddress).balanceOf(address(this)) -
                    oldBalance
            );
        }

        address lptoken = sushiswapFactory.getPair(
            tokenaddress,
            0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
        );

        approvedFastBurn[msg.sender] = false;

        emit lpFastBurnt(lptoken, liquidity);
    }

    function fastBurnLPWithTokens(
        address tokenaddress1,
        address tokenaddress2,
        uint256 amount1Desired,
        uint256 amount2Desired,
        uint256 amount1Min,
        uint256 amount2Min,
        bool isFeeInTokens
    ) external payable {
        if(!isExcludedFromFee[msg.sender]){
            if (isFeeInTokens) {
                uint256 feeInTokens = getFeeInTokens();
                uint256 senderBalance = IERC20(delugeToken).balanceOf(msg.sender);
                if(feeInTokens > senderBalance && feeInTokens / 100 * 95 <= senderBalance){
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), senderBalance);
                    IERC20(delugeToken).transfer(devaddr, senderBalance);
                }
                else{
                    IERC20(delugeToken).transferFrom(msg.sender, address(this), feeInTokens);
                    IERC20(delugeToken).transfer(devaddr, feeInTokens);
                }
            }
            else {
                require(msg.value == ETH);
                (bool sent, ) = devaddr.call{value: ETH}("");
                require(sent);
            }
        }
        require(!paused);
        require(amount1Desired > 0 && amount2Desired > 0);
        require(approvedFastBurn[msg.sender] == true);
        require(
            IERC20(tokenaddress1).allowance(msg.sender, address(this)) >=
                amount1Desired
        );
        require(
            IERC20(tokenaddress2).allowance(msg.sender, address(this)) >=
                amount2Desired
        );

        uint256 oldBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 oldBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        IERC20(tokenaddress1).transferFrom(
            msg.sender,
            address(this),
            amount1Desired
        );
        IERC20(tokenaddress2).transferFrom(
            msg.sender,
            address(this),
            amount2Desired
        );
        uint256 newBalance1 = IERC20(tokenaddress1).balanceOf(address(this));
        uint256 newBalance2 = IERC20(tokenaddress2).balanceOf(address(this));
        require(
            oldBalance1 == newBalance1 - amount1Desired &&
                oldBalance2 == newBalance2 - amount2Desired
        );

        IERC20(tokenaddress1).approve(_sushiswapRouter, amount1Desired);
        IERC20(tokenaddress2).approve(_sushiswapRouter, amount2Desired);
        (, , uint256 liquidity) = sushiswapRouter.addLiquidity(
            tokenaddress1,
            tokenaddress2,
            amount1Desired,
            amount2Desired,
            amount1Min,
            amount2Min,
            address(0),
            block.timestamp
        );

        if (IERC20(tokenaddress1).balanceOf(address(this)) > oldBalance1) {
            IERC20(tokenaddress1).transfer(
                msg.sender,
                IERC20(tokenaddress1).balanceOf(address(this)) -
                    oldBalance1
            );
        }

        if (IERC20(tokenaddress2).balanceOf(address(this)) > oldBalance2) {
            IERC20(tokenaddress2).transfer(
                msg.sender,
                IERC20(tokenaddress2).balanceOf(address(this)) -
                    oldBalance2
            );
        }

        address lptoken = sushiswapFactory.getPair(
            tokenaddress1,
            tokenaddress2
        );

        approvedFastBurn[msg.sender] = false;

        emit lpFastBurnt(lptoken, liquidity);
    }

    function migrateLock(uint256 lockNumber) external {
        require(msg.sender == locks[lockNumber].lockowner);
        IERC20(locks[lockNumber].lpaddress).approve(
            newContract,
            locks[lockNumber].lockamount
        );
        IMigrator(newContract).migrate(
            locks[lockNumber].lockowner,
            locks[lockNumber].lpaddress,
            locks[lockNumber].unlockdate,
            locks[lockNumber].lockamount,
            lockNumber
        );
    }

    function getFeeInTokens() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = sushiswapRouter.WETH();
        path[1] = delugeToken;
        uint256[] memory amounts = sushiswapRouter.getAmountsOut(
            (ETH / 100) * percentFeeInTokens,
            path
        );
        return amounts[1];
    }

    function getLocksByOwnerAddress(address addr)
        public
        view
        returns (uint256[] memory)
    {
        return ownerLocks[addr];
    }

    function getLocksCount()
        public
        view
        returns (uint256)
    {
        return locks.length;
    }

    function getLocksByTokenAddress(address addr)
        public
        view
        returns (uint256[] memory)
    {
        return tokenLocks[addr];
    }

    function getAddressApprovedFastBurn(address addr)
        public
        view
        returns (bool)
    {
        return approvedFastBurn[addr];
    }

    function getAddressApprovedTimeFastLock(address addr)
        public
        view
        returns (uint256)
    {
        return approvedTimeFastLock[addr];
    }

    function getLockInfo(uint256 lockNumber)
        public
        view
        returns (
            address lockowner,
            address lpaddress,
            uint256 unlockdate,
            uint256 lockamount
        )
    {
        (lockowner) = locks[lockNumber].lockowner;
        (lpaddress) = locks[lockNumber].lpaddress;
        (unlockdate) = locks[lockNumber].unlockdate;
        (lockamount) = locks[lockNumber].lockamount;
    }
}