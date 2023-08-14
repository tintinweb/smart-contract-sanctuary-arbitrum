// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Collateral {
    address public owner;
    uint public ltv;
    uint public liquidation_income;
    uint public liquidation_penalty;
    uint public crosschain_fee;
    uint public curr_collateral_sn;

    struct Balance {
        uint active;
        uint frozen;
    }
    mapping (address => Balance) public balances;
    mapping (address => mapping(address => Balance)) public tokenBalances;
    
    struct CollateralToken {
        address token;
        string symbol;
        bool active;
    }
    CollateralToken[] public tokenList;

    struct Freeze {
        address token;
        uint frozen;
    }
    mapping (address => mapping(uint => Freeze)) public userFreezes;
    
    event FreezeCollateral(address user, uint sn, address token, uint frozen, uint chain, bytes32 dest, uint amount, uint order_sn, uint[] candidate_orders);
    event ReleaseCollateral(address user, uint sn, address token, uint amount);
    event LiquidateCollateral(address receiver, uint sn, address token, uint amount, address borrower); 
    
    event Deposit(address user, uint amount, uint balance);
    event DepositToken(address user, address token, uint amount, uint balance);
    event Withdraw(address user, uint amount, uint balance);
    event WithdrawToken(address user, address token, uint amount, uint balance);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
        ltv = 95;
        liquidation_income = 99;
        liquidation_penalty = 1;
        crosschain_fee = 0.0001 ether;
    }

    function deposit() external payable {
        require(msg.value > 0);
        balances[msg.sender].active += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender].active);
    }

    function depositToken(address token, uint amount) external {
        require(amount > 0);
        require(isCollateralToken(token), "InvalidCollateralToken");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        tokenBalances[token][msg.sender].active += amount;
        emit DepositToken(msg.sender, token, amount, tokenBalances[token][msg.sender].active);
    }

    function withdraw(uint amount) external {
        require(amount > 0);
        require(balances[msg.sender].active >= amount, "InsufficientBalance");
        balances[msg.sender].active -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success);
        emit Withdraw(msg.sender, amount, balances[msg.sender].active);
    }

    function withdrawToken(address token, uint amount) external {
        require(amount > 0);
        require(tokenBalances[token][msg.sender].active >= amount, "InsufficientBalance");
        tokenBalances[token][msg.sender].active -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit WithdrawToken(msg.sender, token, amount, tokenBalances[token][msg.sender].active);
    }

    function freeze(address token, uint chain, bytes32 dest, uint amount, uint order_sn, uint[] calldata c_orders) external payable {
        require(msg.value >= crosschain_fee, "InsufficientCrossChainFee");
        require(isCollateralToken(token));
        amount = amount / 1e14 * 1e14;
        uint frozen = amount * 100 / ltv;
        frozen = frozen / 1e14 * 1e14;

        if (token == address(1)) {
            require(balances[msg.sender].active >= frozen, "InsufficientCollateral");
            balances[msg.sender].active -= frozen;
            balances[msg.sender].frozen += frozen;
        } else {
            require(tokenBalances[token][msg.sender].active >= frozen, "InsufficientCollateral");
            tokenBalances[token][msg.sender].active -= frozen;
            tokenBalances[token][msg.sender].frozen += frozen;
        }
        curr_collateral_sn++;
        userFreezes[msg.sender][curr_collateral_sn] = Freeze({
            token: token,
            frozen: frozen
        }); 
        balances[owner].active += msg.value;

        uint[] memory candidate_orders = new uint[](c_orders.length);
        for (uint i = 0; i < c_orders.length; i++) {
            candidate_orders[i] = c_orders[i];
        }
        emit FreezeCollateral(msg.sender, curr_collateral_sn, token, frozen, chain, dest, amount, order_sn, candidate_orders);
    }

    function release(address user, uint sn, uint frozen) external onlyOwner {
        require(userFreezes[user][sn].frozen == frozen);
        address token = userFreezes[user][sn].token;
        delete userFreezes[user][sn];
        if (token == address(1)) {
            balances[user].frozen -= frozen;
            balances[user].active += frozen;
        } else {
            tokenBalances[token][user].frozen -= frozen;
            tokenBalances[token][user].active += frozen;
        }
        emit ReleaseCollateral(user, sn, token, frozen);
    }

    function liquidate(address user, uint sn, uint frozen, address receiver) external onlyOwner {
        require(userFreezes[user][sn].frozen == frozen);
        address token = userFreezes[user][sn].token;
        delete userFreezes[user][sn];
        uint amount = (frozen * liquidation_income) / 100;
        uint penalty = (frozen * liquidation_penalty) / 100;
        if (token == address(1)) {
            balances[user].frozen -= frozen;
            balances[receiver].active += amount;
            balances[owner].active += penalty;
        } else {
            tokenBalances[token][user].frozen -= frozen;
            tokenBalances[token][receiver].active += amount;
            tokenBalances[token][owner].active += penalty;
        }
        emit LiquidateCollateral(receiver, sn, token, amount, user);
    }

    function configure(
        uint ltv_,
        uint liquidation_income_,
        uint liquidation_penalty_,
        uint crosschain_fee_
    ) external onlyOwner {
        ltv = ltv_;
        liquidation_income = liquidation_income_;
        liquidation_penalty = liquidation_penalty_;
        crosschain_fee = crosschain_fee_;
    }

    function newCollateralToken(address token, string memory symbol) external onlyOwner {
        tokenList.push(CollateralToken({
            token: token,
            symbol: symbol,
            active: true
        }));
    }

    function activeCollateralToken(address token, bool active) external onlyOwner {
        for (uint i = 0; i < tokenList.length; i++) {
            if (token == tokenList[i].token) {
                tokenList[i].active = active;
                return;
            }
        }
    }

    function isCollateralToken(address token) internal view returns (bool) {
        if (token == address(1)) return true;
        for (uint i = 0; i < tokenList.length; i++) {
            if (token == tokenList[i].token) {
                return tokenList[i].active;
            }
        }
        return false;
    }

    function getCollateralTokens() external view returns (CollateralToken[] memory) {
        CollateralToken[] memory tokens = new CollateralToken[](tokenList.length);
        for (uint i = 0; i < tokenList.length; i++) {
            tokens[i] = CollateralToken({
                token: tokenList[i].token,
                symbol: tokenList[i].symbol,
                active: tokenList[i].active
            });
        }
        return tokens;
    }

    function getConfigure() external view returns(uint, uint, uint, uint) {
        return (ltv, liquidation_income, liquidation_penalty, crosschain_fee);
    }
}