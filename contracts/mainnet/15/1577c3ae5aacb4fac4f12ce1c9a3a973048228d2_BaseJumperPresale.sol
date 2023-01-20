// SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "contracts/token/BaseJumper.sol";

/// @title BaseJumper presale contract
contract BaseJumperPresale is Ownable, ReentrancyGuard {

    using SafeERC20 for BaseJumper;

    BaseJumper public immutable baseJumper;
    address payable public immutable treasury;
    uint public constant PERCENT_DENOMINATOR = 100;
    uint public constant PRESALE_PERCENT = 30;
    uint public constant MIN_PRESALE_AMOUNT = 0.1 ether;
    uint public constant MAX_PRESALE_AMOUNT = 0.5 ether;
    uint public constant PRESALE_CAP = 50 ether;
    uint public constant BATCH_SIZE = 100;
    uint public gonTotal;
    uint public totalETHDeposited;
    uint public totalWhitelisted;

    bool public hasPresaleStarted;
    bool public hasPresaleEnded;
    uint public totalPresalers;

    uint public lastBatch;

    struct Presale {
        uint id;
        uint eth;
    }

    mapping(address => bool) public isWhitelisted;
    mapping(address => Presale) public presale;
    mapping(uint => address) public presaleIndex;

    event Whitelisted(address[] addresses);
    event PresaleStarted();
    event PresaleEnded();
    event Buy(address user, uint purchased, uint totalPurchase);
    event BulkTransfer();

    modifier onlyWhitelisted() {
        require(isWhitelisted[_msgSender()], "BaseJumperPresale: Only whitelisted users can call this");
        _;
    }

    constructor(address payable _baseJumper, address payable _treasury) {
        require(_baseJumper != address(0), "BaseJumperPresale: _baseJumper cannot be the zero address");
        require(_treasury != address(0), "BaseJumperPresale: _treasury cannot be the zero address");
        baseJumper = BaseJumper(_baseJumper);
        treasury = _treasury;
    }

    /// @notice Import whitelist (Owner)
    /// @param _addresses Wallet addresses
    function whitelist(address[] calldata _addresses) external onlyOwner {
        require(!hasPresaleEnded, "BaseJumperPresale: Presale has already ended");
        for (uint i; i < _addresses.length; i++) {
            isWhitelisted[_addresses[i]] = true;
        }
        totalWhitelisted += _addresses.length;
        emit Whitelisted(_addresses);
    }

    /// @notice Start presale (owner)
    function startPresale() external nonReentrant onlyOwner {
        require(!hasPresaleStarted, "BaseJumperPresale: Presale already started");
        uint total = amountToTransfer();
        hasPresaleStarted = true;
        baseJumper.safeTransferFrom(_msgSender(), address(this), total);
        gonTotal = baseJumper.gonBalanceOf(address(this));
        emit PresaleStarted();
    }

    /// @notice End presale (owner)
    function endPresale() external onlyOwner {
        require(hasPresaleStarted, "BaseJumperPresale: Presale has not started");
        require(!hasPresaleEnded, "BaseJumperPresale: Presale already ended");
        _endPresale();
    }

    /// @notice Buy tokens in presale (whitelisted users only)
    function buy() external payable nonReentrant onlyWhitelisted {
        require(hasPresaleStarted, "BaseJumperPresale: Presale has not started yet");
        require(!hasPresaleEnded, "BaseJumperPresale: Presale has ended");
        uint currentPurchase = presale[_msgSender()].eth;
        if (currentPurchase == 0) {
            totalPresalers++;
            presaleIndex[totalPresalers] = _msgSender();
        }
        uint newPurchase = msg.value;
        uint totalPurchase = currentPurchase + newPurchase;
        require(newPurchase > 0, "BaseJumperPresale: Invalid msg.value");
        require(totalETHDeposited + newPurchase <= PRESALE_CAP, "BaseJumperPresale: Amount would exceed presale cap, enter a smaller amount");
        require(MIN_PRESALE_AMOUNT <= totalPurchase && totalPurchase <= MAX_PRESALE_AMOUNT, "BaseJumperPresale: Invalid ETH amount");
        require(totalPurchase % 0.1 ether == 0, "BaseJumperPresale: ETH amount must be an interval of 0.1 ETH");
        presale[_msgSender()].eth += newPurchase;
        totalETHDeposited += newPurchase;
        if (totalETHDeposited == PRESALE_CAP) {
            _endPresale();
        }
        treasury.transfer(newPurchase);
        emit Buy(_msgSender(), newPurchase, totalPurchase);
    }

    /// @notice Amount to transfer
    /// @return total - Total amount
    function amountToTransfer() public view returns (uint total) {
        total = baseJumper.totalSupply() * PRESALE_PERCENT / PERCENT_DENOMINATOR;
    }

    function _endPresale() internal {
        if (totalETHDeposited < PRESALE_CAP) {
            /// @dev gonTotal is a large number therefore have to divide in brackets
            uint totalPresaleGonValue = totalETHDeposited * (gonTotal / PRESALE_CAP);
            uint unsoldPresale = gonTotal - totalPresaleGonValue;
            baseJumper.gonTransfer(treasury, unsoldPresale);
            gonTotal -= unsoldPresale;
        }
        hasPresaleEnded = true;
        emit PresaleEnded();
    }

    /// @notice Total batches (used after presale has ended)
    /// @return total Total batches
    function totalBatches() public view returns (uint total) {
        require(hasPresaleEnded, "BaseJumperPresale: Presale has not ended");
        uint remainder = totalPresalers % BATCH_SIZE;
        total = totalPresalers / BATCH_SIZE;
        if(remainder > 0) {
            total += 1;
        }
        return total;
    }

    /// @notice Bulk transfer presalers their tokens (owner)
    /// @param _batch Batch number
    function bulkTransfer(uint _batch) external nonReentrant onlyOwner {
        require(hasPresaleEnded, "BaseJumperPresale: Presale has not ended");
        require(lastBatch + 1 == _batch && _batch <= totalBatches(), "BaseJumperPresale: Invalid batch number");
        uint startIndex = (lastBatch * BATCH_SIZE);
        uint endIndex = startIndex + BATCH_SIZE;
        if (endIndex > totalPresalers) {
            endIndex = totalPresalers;
        }
        for (uint i = startIndex; i < endIndex; i++) {
            address user = presaleIndex[i + 1];
            uint gonValue = _calculatePresaleGonValue(user);
            baseJumper.gonTransfer(user, gonValue);
        }
        lastBatch = _batch;
        emit BulkTransfer();
    }

    /// @param _user User address
    function _calculatePresaleGonValue(address _user) internal view returns (uint gonValue) {
        gonValue = presale[_user].eth * (gonTotal / totalETHDeposited);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity = 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

/// @title Base Jumper
contract BaseJumper is ERC20, Ownable {

    bool internal _inSwap = false;

    uint private constant MAX_UINT256 = ~uint(0);
    uint private constant INITIAL_FRAGMENTS_SUPPLY = 420_069_000 ether;
    uint private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint private constant MAX_SUPPLY = ~uint128(0);
    /// @dev REBASE_BUFFER is not set to 24 hours so that oracle can call it on the dot
    uint private constant REBASE_BUFFER = 23.5 hours;
    uint private constant MAX_TOTAL_TAX_RATE = 100;
    uint private constant TAX_RATE_DENOMINATOR = 1000;
    uint private constant MIN_SWAP_THRESHOLD_DENOMINATOR = 10000;
    uint private constant LP_TAX_LOCK_UP_PERIOD = 180 days;
    /// @dev 1/1,000 of the total supply
    uint private constant MIN_HOLDER_BALANCE_THRESHOLD = 1_000;
    /// @dev 1/100,000 of the total supply
    uint private constant MAX_HOLDER_BALANCE_THRESHOLD = 100_000;
    address private constant FACTORY = 0xc35DADB65012eC5796536bD9864eD8773aBc74C4;
    address private constant ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    /// @dev minSwapThreshold = 0.5%
    uint public minSwapThreshold = 50;
    /// @dev 1/10,000 of the total supply
    uint public holderBalanceThreshold = 10_000;
    /// @dev treasuryTaxRate = 3%
    uint public treasuryTaxRate = 30;
    /// @dev liquidityTaxRate = 3%
    uint public liquidityTaxRate = 30;
    uint private _totalSupply;
    uint private _gonsPerFragment;

    uint public totalHolders;
    uint public totalTransfers;
    uint public latestRebaseEpoch;
    uint public rebaseUpdatedAtTimestamp;
    uint public rebaseUpdatedAtBlock;
    uint public lpTaxLockedUntil;
    address public oracle;
    address public treasury;
    bool public isAutoSwapEnabled = true;

    IUniswapV2Router02 private _router;
    address private _pair;

    struct RebaseLog {
        uint holders;
        uint transfers;
        uint marketCap;
        uint blockNumber;
    }

    mapping(uint => RebaseLog) public rebaseLogs;
    mapping(address => bool) public isTaxExcluded;
    mapping(address => bool) public isWhitelistedForGonTransfer;
    mapping(address => uint) private _gonBalances;
    mapping(address => bool) private _holders;

    modifier lockSwap {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier onlyOracle {
        require(_msgSender() == oracle, "BaseJumper: caller not oracle");
        _;
    }

    event Rebased(uint _percent, bool _isPositive, uint _prevTotalSupply, uint _newTotalSupply);
    event OracleUpdated(address oracle);
    event TreasuryUpdated(address treasury);
    event TaxExclusion(address wallet, bool isExcluded);
    event MinSwapThresholdUpdated(uint minSwapThreshold);
    event HolderBalanceThresholdUpdated(uint holderBalanceThreshold);
    event TaxRateUpdated(uint treasuryTaxRate, uint liquidityTaxRate);
    event AutoSwapConfigured(bool isEnabled);
    event WhitelistGonTransfer(address wallet);

    constructor(address _oracle, address _treasury) ERC20("Base Jumper", "BJ") {
        setOracle(_oracle);
        setTreasury(_treasury);
        setTaxExclusion(owner(), true);
        setTaxExclusion(address(this), true);
        lpTaxLockedUntil = block.timestamp + LP_TAX_LOCK_UP_PERIOD;
        /// @dev transfer total supply to owner
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[owner()] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS / _totalSupply;
        _handleHolder(owner());
        totalTransfers++;
        /// @dev initialise router and create Uniswap pair
        _router = IUniswapV2Router02(ROUTER);
        IUniswapV2Factory factory = IUniswapV2Factory(FACTORY);
        _pair = factory.createPair(address(this), _router.WETH());
        emit Transfer(address(0), owner(), _totalSupply);
    }

    /// @notice Set Oracle address (owner)
    /// @param _oracle Oracle address
    function setOracle(address _oracle) public onlyOwner {
        require(_oracle != address(0), "BaseJumper: _oracle cannot be the zero address");
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    /// @notice Set Treasury address (owner)
    /// @param _treasury Treasury address
    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0), "BaseJumper: _treasury cannot be the zero address");
        if (treasury != address(0) && treasury != owner()) {
            setTaxExclusion(treasury, false);
        }
        treasury = _treasury;
        setTaxExclusion(treasury, true);
        emit TreasuryUpdated(treasury);
    }

    /// @notice Set tax exclusion (owner)
    /// @param _wallet Wallet address
    /// @param _exclude True - Exclude from tax, False - Include tax
    function setTaxExclusion(address _wallet, bool _exclude) public onlyOwner {
        require(_wallet != address(0), "BaseJumper: _wallet cannot be the zero address");
        require(_exclude || _wallet != address(this), "BaseJumper: _wallet cannot equal this address");
        isTaxExcluded[_wallet] = _exclude;
        emit TaxExclusion(_wallet, _exclude);
    }

    /// @notice Set minimum threshold before a swap occurs (owner)
    /// @notice _minSwapThreshold Min swap threshold as a percentage, e.g. 50 = 0.5%
    function setMinSwapThreshold(uint _minSwapThreshold) external onlyOwner {
        require(_minSwapThreshold > 0, "BaseJumper: _minSwapThreshold must be greater than 0");
        minSwapThreshold = _minSwapThreshold;
        emit MinSwapThresholdUpdated(minSwapThreshold);
    }

    /// @notice Set tax rate, max total tax 10% (100) (owner)
    /// @notice _treasuryTaxRate Treasury tax rate swap e.g. 30 = 3%
    /// @notice _liquidityTaxRate Liquidity tax rate swap e.g. 30 = 3%
    function setTaxRate(uint _treasuryTaxRate, uint _liquidityTaxRate) external onlyOwner {
        require(_treasuryTaxRate + _liquidityTaxRate <= MAX_TOTAL_TAX_RATE, "BaseJumper: total tax rate must be less than to equal to 10%");
        treasuryTaxRate = _treasuryTaxRate;
        liquidityTaxRate = _liquidityTaxRate;
        emit TaxRateUpdated(treasuryTaxRate, liquidityTaxRate);
    }

    /// @notice Enable/disable auto swap (owner)
    /// @param _isAutoSwapEnabled True - Auto swap will occur on sells and transfers once over the threshold, False - No auto-swap
    function setIsAutoSwapEnabled(bool _isAutoSwapEnabled) external onlyOwner {
        isAutoSwapEnabled = _isAutoSwapEnabled;
        emit AutoSwapConfigured(isAutoSwapEnabled);
    }

    /// @notice Rebase (oracle)
    /// @param _percent Percent e.g. 1 = 1%
    /// @param _isPositive True _percent is positive, False _percent is negative
    function rebase(uint _percent, bool _isPositive) external onlyOracle {
        require(_percent <= 5, "BaseJumper: Rebase percent must be less than or equal to 5%");
        require(block.timestamp >= rebaseUpdatedAtTimestamp + REBASE_BUFFER, "BaseJumper: Cannot rebase more than once per day");
        rebaseUpdatedAtTimestamp = block.timestamp;
        rebaseUpdatedAtBlock = block.number;
        uint prevTotalSupply = _totalSupply;
        if (_percent > 0) {
            uint delta = _totalSupply * _percent / 100;
            if (_isPositive) {
                _totalSupply += delta;
            } else {
                _totalSupply -= delta;
            }
            if (_totalSupply > MAX_SUPPLY) {
                _totalSupply = MAX_SUPPLY;
            }
            _gonsPerFragment = TOTAL_GONS / _totalSupply;
            IUniswapV2Pair(_pair).sync();
        }
        emit Rebased(_percent, _isPositive, prevTotalSupply, _totalSupply);
    }

    /// @notice Get Gon balance of _address
    /// @param _address Address
    /// @return uint Gon balance
    function gonBalanceOf(address _address) external view returns (uint) {
        return _gonBalances[_address];
    }

    /// @notice Calculate the Gon value for _amount
    /// @param _amount Amount
    /// @return uint Gon value
    function calculateGonValue(uint _amount) public view returns (uint) {
        return _amount * _gonsPerFragment;
    }

    /// @notice Calculate the amount for _gonValue
    /// @param _gonValue Gon value
    /// @return uint Amount
    function calculateAmount(uint _gonValue) public view returns (uint) {
        return _gonValue / _gonsPerFragment;
    }

    /// @notice Whitelist an address so it can call gonTransfer (owner)
    /// @param _address Address to whitelist
    function whitelistGonTransfer(address _address) external onlyOwner {
        require(_address != address(0), "BaseJumper: _address cannot be the zero address");
        isWhitelistedForGonTransfer[_address] = true;
        emit WhitelistGonTransfer(_address);
    }

    /// @notice Transfer in Gon rather than amount
    /// @param _to To address
    /// @param _gonValue Gon value
    function gonTransfer(address _to, uint _gonValue) external {
        address from = _msgSender();
        require(isWhitelistedForGonTransfer[from], "BaseJumper: Only whitelisted addresses can call this function");
        require(_gonValue > 0, "BaseJumper: Cannot transfer 0 gon");
        require(from != address(0), "ERC20: transfer to the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        _gonTransfer(from, _to, _gonValue);
        uint amount = calculateAmount(_gonValue);
        emit Transfer(from, _to, amount);
    }

    /// @notice Claim tax generated LP tokens, locked for 6 months (owner)
    function claimTaxGeneratedLP() external onlyOwner {
        require(block.timestamp >= lpTaxLockedUntil, "BaseJumper: Cannot withdraw yet");
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        uint lpBalance = pair.balanceOf(address(this));
        require(lpBalance > 0, "BaseJumper: Nothing to withdraw");
        pair.transfer(owner(), lpBalance);
    }

    /// @notice Get holder balance threshold as an amount
    /// @return uint Holder balance threshold
    function holderBalanceThresholdAmount() external view returns (uint) {
        return calculateAmount(TOTAL_GONS / holderBalanceThreshold);
    }

    /// @notice Set balance threshold used to determine if a wallet is a "holder" (owner)
    /// @param _threshold Holder balance threshold
    function setHolderBalanceThreshold(uint _threshold) external onlyOwner {
        require(
            MIN_HOLDER_BALANCE_THRESHOLD <= _threshold && _threshold <= MAX_HOLDER_BALANCE_THRESHOLD,
            "BaseJumper: _threshold must be within range"
        );
        holderBalanceThreshold = _threshold;
        emit HolderBalanceThresholdUpdated(holderBalanceThreshold);
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address _address) public override view returns (uint) {
        return _gonBalances[_address] / _gonsPerFragment;
    }

    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal override {
        require(_amount > 0, "BaseJumper: Cannot transfer 0 tokens");
        if (!_inSwap) {
            /// @dev do not include transfers from handling fees
            totalTransfers++;
        }
        if (isTaxExcluded[_from] || isTaxExcluded[_to]) {
            _rawTransfer(_from, _to, _amount);
            return;
        }
        /// @dev only handle tax when not buying, the tax is over the threshold, and auto swap is enabled
        if (_from != _pair && _isTaxOverMinThreshold() && isAutoSwapEnabled) {
            _autoSwapTax();
        }
        uint amountToSend = _amount;
        /// @dev apply tax when buying or selling
        if (_from == _pair || _to == _pair) {
            uint tax = _calculateTax(_amount);
            if (tax > 0) {
                amountToSend -= tax;
                _rawTransfer(_from, address(this), tax);
            }
        }
        _rawTransfer(_from, _to, amountToSend);
    }

    /// @dev Raw transfer, calls _gonTransfer
    /// @param _from From address
    /// @param _to To address
    /// @param _amount Amount
    function _rawTransfer(
        address _from,
        address _to,
        uint _amount
    ) internal {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");
        uint gonValue = calculateGonValue(_amount);
        _gonTransfer(_from, _to, gonValue);
        emit Transfer(_from, _to, _amount);
    }

    /// @dev Gon transfer
    /// @param _from From address
    /// @param _to To address
    /// @param _gonValue Gon value
    function _gonTransfer(address _from, address _to, uint _gonValue) internal {
        require(_gonBalances[_from] >= _gonValue, "ERC20: transfer amount exceeds balance");
        _gonBalances[_from] -= _gonValue;
        _gonBalances[_to] += _gonValue;
        _handleHolder(_from);
        _handleHolder(_to);
    }

    /// @dev Auto swap tax from Base Jumper to ETH, add liquidity, transfer treasury tax to treasury
    function _autoSwapTax() internal lockSwap {
        uint amount = balanceOf(address(this));
        uint taxRate = _getTotalTaxRate();
        if (taxRate > 0) {
            uint liquidityAmount = amount * liquidityTaxRate / taxRate;
            uint tokensForLP = liquidityAmount / 2;
            uint amountToSwap = amount - tokensForLP;
            _approve(address(this), ROUTER, amountToSwap);
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = _router.WETH();
            _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );
            uint ethBalance = address(this).balance;
            uint taxRateRelativeToSwap = taxRate - (liquidityTaxRate / 2);
            uint treasuryTaxETH = ethBalance * treasuryTaxRate / taxRateRelativeToSwap;
            uint liquidityTaxETH = ethBalance - treasuryTaxETH;
            if (treasuryTaxETH > 0) {
                payable(treasury).transfer(treasuryTaxETH);
            }
            if (tokensForLP > 0 && liquidityTaxETH > 0) {
                _addLiquidity(tokensForLP, liquidityTaxETH);
            }
        }
    }

    /// @param _bj Amount of BJ
    /// @param _eth Amount of ETH
    function _addLiquidity(uint _bj, uint _eth) internal {
        _approve(address(this), ROUTER, _bj);
        _router.addLiquidityETH{value : _eth}(
            address(this),
            _bj,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    /// @param _amount Amount to apply tax to
    /// @return uint Tax owed on _amount
    function _calculateTax(uint _amount) internal view returns (uint) {
        return _amount * _getTotalTaxRate() / TAX_RATE_DENOMINATOR;
    }

    /// @return uint Total tax rate
    function _getTotalTaxRate() internal view returns (uint) {
        return treasuryTaxRate + liquidityTaxRate;
    }

    /// @return bool True if over min threshold, otherwise false
    function _isTaxOverMinThreshold() internal view returns (bool){
        return balanceOf(address(this)) >= _totalSupply * minSwapThreshold / MIN_SWAP_THRESHOLD_DENOMINATOR;
    }

    /// @param _holder Address of a potential holder
    function _handleHolder(address _holder) internal {
        if (_gonBalances[_holder] >= TOTAL_GONS / holderBalanceThreshold) {
            if (!_holders[_holder]) {
                _holders[_holder] = true;
                totalHolders += 1;
            }
        } else {
            if (_holders[_holder]) {
                _holders[_holder] = false;
                totalHolders -= 1;
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}