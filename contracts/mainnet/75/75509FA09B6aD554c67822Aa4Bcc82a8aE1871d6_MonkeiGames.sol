// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Libraries.sol";

contract MonkeiGames is IERC20Metadata, Ownable
{
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public excludedFromFees;
    mapping(address => bool) public excludedFromLimit;
    mapping(address => bool) public isAMM;
    //Token Info
    string private constant _name = 'Monkei';
    string private constant _symbol = 'MONK';
    uint8 private constant _decimals = 18;
    uint public constant InitialSupply = 5000 * 10 ** _decimals;

    uint private constant DefaultLiquidityLockTime = 7 days;

    address private constant UniswapRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    //variables that track balanceLimit and sellLimit,
    //can be updated based on circulating supply and Sell- and BalanceLimitDividers
    uint private _circulatingSupply = InitialSupply;

    //Tracks the current Taxes, different Taxes can be applied for buy/sell/transfer
    uint public buyTax = 60;
    uint public sellTax = 60;
    uint public transferTax = 0;
    uint public burnTax = 0;
    uint public liquidityTax = 0;
    uint public marketingTax = 1000;
    uint constant TAX_DENOMINATOR = 1000;
    uint constant MAXTAXDENOMINATOR = 10;
    uint public LimitV = 65;
    uint public LimitSell = 1;


    address private _uniswapPairAddress;

    //TODO: marketingWallet
    address public marketingWallet;
    address public gameContract = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //Only marketingWallet can change marketingWallet
    function ChangeMarketingWallet(address newWallet) public {
        require(msg.sender == marketingWallet); // this is only owner checking access control. because that the begining it's set to owner wallet
        marketingWallet = newWallet;
    }

    function setGameContract(address newContract) public onlyOwner {
        gameContract = newContract;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Constructor///////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    constructor () {
        uint deployerBalance = _circulatingSupply;
        _balances[msg.sender] = deployerBalance;
        emit Transfer(address(0), msg.sender, deployerBalance);
        //contract creator is by default marketing wallet
        marketingWallet = msg.sender;
        //owner uniswap router and contract is excluded from Taxes
        excludedFromFees[msg.sender] = true;
        excludedFromFees[UniswapRouter] = true;
        excludedFromFees[address(this)] = true;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Transfer functionality////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //transfer function, every transfer runs through this function
    function _transfer(address sender, address recipient, uint amount) private {
        require(sender != address(0), "Transfer from zero");
        require(recipient != address(0), "Transfer to zero");

        //Pick transfer
        if (excludedFromFees[sender] || excludedFromFees[recipient])
            _feelessTransfer(sender, recipient, amount);
        else if (excludedFromLimit[recipient]) {
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp > 0, "trading not yet enabled");
            _LimitlessFonctionTransfer(sender, recipient, amount);
        }
        else {
            //once trading is enabled, it can't be turned off again
            require(LaunchTimestamp > 0, "trading not yet enabled");
            _taxedTransfer(sender, recipient, amount);
        }
    }

    //applies taxes, checks for limits, locks generates autoLP and stakingETH, and autostakes
    function _taxedTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        uint recipientBalance = _balances[recipient];
        require(senderBalance >= amount, "Transfer exceeds balance");
        require(senderBalance / LimitSell >= amount, "Transfer exceeds authorise sell");
        require((recipientBalance + amount ) <= InitialSupply/LimitV, "Wallet contain more than certain % Total Supply");

        bool isBuy = isAMM[sender];
        bool isSell = isAMM[recipient];

        uint tax;
        if (isSell) {
            uint SellTaxDuration = 120 seconds;
            if (block.timestamp < LaunchTimestamp + SellTaxDuration) {
                tax = _getStartTax(SellTaxDuration, 999);
            } else tax = sellTax;
        }
        else if (isBuy) {
            uint BuyTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + BuyTaxDuration) {
                tax = _getStartTax(BuyTaxDuration, 999);
            } else tax = buyTax;
        } else tax = transferTax;

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt = _calculateFee(amount, tax, burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint contractToken = _calculateFee(amount, tax, marketingTax + liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount = amount - (tokensToBeBurnt + contractToken);

        _balances[sender] -= amount;
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply -= tokensToBeBurnt;
        _balances[recipient] += taxedAmount;

        emit Transfer(sender, marketingWallet, contractToken);
        emit Transfer(sender, recipient, taxedAmount);
    }
    //Start tax drops depending on the time since launch, enables bot protection and Dump protection
    function _getStartTax(uint duration, uint maxTax) private view returns (uint){
        uint timeSinceLaunch = block.timestamp - LaunchTimestamp;
        return maxTax - ((maxTax - 50) * timeSinceLaunch / duration);
    }
    //Calculates the token that should be taxed
    function _calculateFee(uint amount, uint tax, uint taxPercent) private pure returns (uint) {
        return (amount * tax * taxPercent) / (TAX_DENOMINATOR * TAX_DENOMINATOR);
    }


    //Feeless transfer only transfers and autostakes
    function _feelessTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }
    ///////////////////////////////YeaaaahBrooooooo//////////addd
    function _LimitlessFonctionTransfer(address sender, address recipient, uint amount) private {
        uint senderBalance = _balances[sender];
        require(senderBalance >= amount, "Transfer exceeds balance");

        bool isBuy = isAMM[sender];
        bool isSell = isAMM[recipient];

        uint tax;
        if (isSell) {
            uint SellTaxDuration = 120 seconds;
            if (block.timestamp < LaunchTimestamp + SellTaxDuration) {
                tax = _getStartTax(SellTaxDuration, 999);
            } else tax = sellTax;
        }
        else if (isBuy) {
            uint BuyTaxDuration = 60 seconds;
            if (block.timestamp < LaunchTimestamp + BuyTaxDuration) {
                tax = _getStartTax(BuyTaxDuration, 999);
            } else tax = buyTax;
        } else tax = transferTax;

        //Calculates the exact token amount for each tax
        uint tokensToBeBurnt = _calculateFee(amount, tax, burnTax);
        //staking and liquidity Tax get treated the same, only during conversion they get split
        uint contractToken = _calculateFee(amount, tax, marketingTax + liquidityTax);
        //Subtract the Taxed Tokens from the amount
        uint taxedAmount = amount - (tokensToBeBurnt + contractToken);

        _balances[sender] -= amount;
        //Adds the taxed tokens to the contract wallet
        _balances[address(this)] += contractToken;
        //Burns tokens
        _circulatingSupply -= tokensToBeBurnt;
        _balances[recipient] += taxedAmount;

        emit Transfer(sender, marketingWallet, contractToken);
        emit Transfer(sender, recipient, taxedAmount);
    }


    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Swap Contract Tokens yeaaaaah Broo//////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    //Locks the swap if already swapping
    bool private _isSwappingContractModifier;
    modifier lockTheSwap {
        _isSwappingContractModifier = true;
        _;
        _isSwappingContractModifier = false;
    }

    //Sets the permille of uniswap pair to trigger liquifying taxed token
    uint public swapTreshold = 2;

    function setSwapTreshold(uint newSwapTresholdPermille) public onlyOwner {
        require(newSwapTresholdPermille <= 15);
        //MaxTreshold= 1.5%
        swapTreshold = newSwapTresholdPermille;
    }
    //Sets the max Liquidity where swaps for Liquidity still happen
    uint public overLiquifyTreshold = 150;

    function SetOverLiquifiedTreshold(uint newOverLiquifyTresholdPermille) public onlyOwner {
        require(newOverLiquifyTresholdPermille <= 1000);
        overLiquifyTreshold = newOverLiquifyTresholdPermille;
    }
    //Sets the taxes Burn+marketing+liquidity tax needs to equal the TAX_DENOMINATOR (1000)
    //buy, sell and transfer tax are limited by the MAXTAXDENOMINATOR
    event OnSetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint liquidity);

    function SetTaxes(uint buy, uint sell, uint transfer_, uint burn, uint marketing, uint liquidity) public onlyOwner {
        uint maxTax = (TAX_DENOMINATOR / MAXTAXDENOMINATOR) / 2;
        require(buy <= maxTax && sell <= maxTax && transfer_ <= maxTax, "Tax exceeds maxTax");
        require(burn + marketing + liquidity == TAX_DENOMINATOR, "Taxes don't add up to denominator");

        buyTax = buy;
        sellTax = sell;
        transferTax = transfer_;
        marketingTax = marketing;
        liquidityTax = liquidity;
        burnTax = burn;
        emit OnSetTaxes(buy, sell, transfer_, burn, marketing, liquidity);
    }

    event OnSetLimit(uint LimitV2);

    function SetLimit(uint LimitV2) public onlyOwner {
        require(LimitV2 <= 50, "Max wallet  can't be under 2% of the total supply");
        LimitV = LimitV2;

        emit OnSetLimit(LimitV2);
    }

    event OnSetSell(uint LimitSell2);

    function SetSell(uint LimitSell2) public onlyOwner {
        require(LimitSell2 <= 2, "Dump measure can't be under 50% of the wallet");
        LimitSell = LimitSell2;

        emit OnSetSell(LimitSell2);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Settings//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //For AMM addresses buy and sell taxes apply
    function SetAMM(address AMM, bool Add) public onlyOwner {
        require(AMM != _uniswapPairAddress, "can't change uniswap");
        isAMM[AMM] = Add;
    }

    bool public manualSwap;
    //switches autoLiquidity and marketing ETH generation during transfers
    function SwitchManualSwap(bool manual) public onlyOwner {
        manualSwap = manual;
    }

    event ExcludeAccount(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludeAccountFromFees(address account, bool exclude) public onlyOwner {
        require(account != address(this), "can't Include the contract");
        excludedFromFees[account] = exclude;
        emit ExcludeAccount(account, exclude);
    }

    /////////////moussss///////////
    event ExcludeAccountLimit(address account, bool exclude);
    //Exclude/Include account from fees (eg. CEX)
    function ExcludedFromLimit(address account, bool exclude) public onlyOwner {
        require(account != address(this), "can't Include the contract");
        excludedFromLimit[account] = exclude;
        emit ExcludeAccountLimit(account, exclude);
    }

    //Enables trading. Sets the launch timestamp to the given Value
    event OnEnableTrading();

    uint public LaunchTimestamp;

    function SetupEnableTrading() public onlyOwner {
        require(LaunchTimestamp == 0, "AlreadyLaunched");
        LaunchTimestamp = block.timestamp;
        emit OnEnableTrading();
    }

    function mint(address _to, uint256 _amount) external {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(msg.sender == gameContract, "Only Game contract can mint token");
        _circulatingSupply += _amount;
        _balances[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //external//////////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    receive() external payable {}

    function name() external pure override returns (string memory) {
        return _name;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint) {
        return _circulatingSupply;
    }

    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address _owner, address spender) external view override returns (uint) {
        return _allowances[_owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint amount) private {
        require(owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Transfer > allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // IERC20 - Helpers

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        uint currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "<0 allowance");

        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

}