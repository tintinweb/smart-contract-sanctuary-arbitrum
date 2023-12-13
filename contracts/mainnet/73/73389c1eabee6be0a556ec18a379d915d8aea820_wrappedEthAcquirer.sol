/**
 *Submitted for verification at Arbiscan.io on 2023-12-09
*/

// File: testArbi/IVaultUtils.sol



pragma solidity ^0.8.20;

interface IVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external view;
    function validateDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external view;
    function validateLiquidation(address _account, address _collateralToken, address _indexToken, bool _isLong, bool _raise) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256);
    function getPositionFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);
    function getFundingFee(address _account, address _collateralToken, address _indexToken, bool _isLong, uint256 _size, uint256 _entryFundingRate) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);
}
// File: testArbi/IVault.sol



pragma solidity ^0.8.20;


interface IVault {
    function isInitialized() external view returns (bool);
    function isSwapEnabled() external view returns (bool);
    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IVaultUtils _vaultUtils) external;
    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);
    function usdg() external view returns (address);
    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);
    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);
    function hasDynamicFees() external view returns (bool);
    function fundingInterval() external view returns (uint256);
    function totalTokenWeights() external view returns (uint256);
    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);
    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);
    function isLiquidator(address _account) external view returns (bool);
    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);
    function tokenBalances(address _token) external view returns (uint256);
    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;
    function setInManagerMode(bool _inManagerMode) external;
    function setManager(address _manager, bool _isManager) external;
    function setIsSwapEnabled(bool _isSwapEnabled) external;
    function setIsLeverageEnabled(bool _isLeverageEnabled) external;
    function setMaxGasPrice(uint256 _maxGasPrice) external;
    function setUsdgAmount(address _token, uint256 _amount) external;
    function setBufferAmount(address _token, uint256 _amount) external;
    function setMaxGlobalShortSize(address _token, uint256 _amount) external;
    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;
    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor) external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;
    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;
    function buyUSDG(address _token, address _receiver) external returns (uint256);
    function sellUSDG(address _token, address _receiver) external returns (uint256);
    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);
    function increasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function decreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);
    function fundingRateFactor() external view returns (uint256);
    function stableFundingRateFactor() external view returns (uint256);
    function cumulativeFundingRates(address _token) external view returns (uint256);
    function getNextFundingRate(address _token) external view returns (uint256);
    function getFeeBasisPoints(address _token, uint256 _usdgDelta, uint256 _feeBasisPoints, uint256 _taxBasisPoints, bool _increment) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);
    function taxBasisPoints() external view returns (uint256);
    function stableTaxBasisPoints() external view returns (uint256);
    function mintBurnFeeBasisPoints() external view returns (uint256);
    function swapFeeBasisPoints() external view returns (uint256);
    function stableSwapFeeBasisPoints() external view returns (uint256);
    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256) external view returns (address);
    function whitelistedTokens(address _token) external view returns (bool);
    function stableTokens(address _token) external view returns (bool);
    function shortableTokens(address _token) external view returns (bool);
    function feeReserves(address _token) external view returns (uint256);
    function globalShortSizes(address _token) external view returns (uint256);
    function globalShortAveragePrices(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
    function tokenDecimals(address _token) external view returns (uint256);
    function tokenWeights(address _token) external view returns (uint256);
    function guaranteedUsd(address _token) external view returns (uint256);
    function poolAmounts(address _token) external view returns (uint256);
    function bufferAmounts(address _token) external view returns (uint256);
    function reservedAmounts(address _token) external view returns (uint256);
    function usdgAmounts(address _token) external view returns (uint256);
    function maxUsdgAmounts(address _token) external view returns (uint256);
    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getMaxPrice(address _token) external view returns (uint256);
    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(address _indexToken, uint256 _size, uint256 _averagePrice, bool _isLong, uint256 _lastIncreasedTime) external view returns (bool, uint256);
    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);
}
// File: testArbi/Interfaces.sol

pragma solidity ^0.8.20;


interface IRouter {
    function addPlugin(address _plugin) external;
    function pluginTransfer(address _token, address _account, address _receiver, uint256 _amount) external;
    function pluginIncreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _sizeDelta, bool _isLong) external;
    function pluginDecreasePosition(address _account, address _collateralToken, address _indexToken, uint256 _collateralDelta, uint256 _sizeDelta, bool _isLong, address _receiver) external returns (uint256);
    function swap(address[] memory _path, uint256 _amountIn, uint256 _minOut, address _receiver) external;
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}
interface IReader{
    function getAmountOut(IVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn) external returns (uint256, uint256);
}

interface ISwapper{
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    function swap(SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline) external returns (uint256 amountCalculated);

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    function batchSwap(SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline) external returns (int256[] memory assetDeltas);
    
    function queryBatchSwap(SwapKind kind,
          BatchSwapStep[] memory swaps,
          IAsset[] memory assets,
          FundManagement memory funds) external
          returns (int256[] memory assetDeltas);
    
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;


// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: testArbi/wrappedEthAcquirer.sol

pragma solidity ^0.8.20;




contract wrappedEthAcquirer is Ownable {
    struct params {
        address stable;
        uint256 thresh;
        uint256 amtStableSell;
    }
    mapping(address=>mapping(address=>uint256)) public userBalances;
    mapping(address=>params) public userParams;
    address[] users;
    address public immutable WETH; //0x82aF49447D8a07e3bd95BD0d56f35241523fBab1
    address public immutable VAULT; //0x489ee077994B6658eAfA855C308275EAd8097C4A
    address public immutable READER; //0x22199a49A999c351eF7927602CFB187ec3cae489
    address public immutable ROUTER; //0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064
    address public immutable BALVAULT; //0xBA12222222228d8Ba445958a75a0704d566BF2C8
    address public AGENT; //0xad1e507f8a0cb1b91421f3bb86bbe29f001cbcc6
    address public immutable WSTETH; //0x5979D7b546E38E414F7E9822514be443A4800529
    bytes32 public immutable balPoolId; //0x9791d590788598535278552eecd4b211bfc790cb000000000000000000000498
    address public secondStage;
    mapping(address=>bool) public secondStageCallingPermissions;

    event registered(address indexed stable, uint256 indexed thresh, uint256 indexed amtStableSell, address owner);
    event updatedParams(address indexed stable, uint256 indexed thresh, uint256 indexed amtStableSell, address owner);

    constructor(address _secondStage, address _WETH, address _WSTETH, bytes32 _balPoolId, address vault, address reader, address router, address agent, address balvault){
        secondStage = _secondStage;
        WETH = _WETH;
        WSTETH = _WSTETH;
        balPoolId = _balPoolId;
        ROUTER = router;
        READER = reader;
        VAULT = vault;
        AGENT = agent;
        BALVAULT = balvault;
    }

    function replenish(address token, uint256 amt) public {
        IERC20(token).transferFrom(msg.sender, address(this), amt);
        userBalances[msg.sender][token] += amt;
    }
    
    function withdraw(address token, uint256 amt) public {
        require(amt <= userBalances[msg.sender][token], "Insufficient balance");
        IERC20(token).transfer(msg.sender, amt);
        userBalances[msg.sender][token] -= amt;
    }

    function drawAdditional(address from) internal {
        params memory param = userParams[from];
        address token = param.stable;
        uint256 toDraw = userBalances[from][token]<param.amtStableSell ? param.amtStableSell - userBalances[from][token] : 0;
        if (toDraw>0){
            IERC20(token).transferFrom(from, address(this), toDraw);
            userBalances[from][token] += toDraw;
        }  
    }

    function register(address _stable, uint256 _thresh, uint256 _amtStableSell) public {
        if(userParams[msg.sender].stable == address(0)){
            users.push(msg.sender);
        }
        userParams[msg.sender] = params(
            _stable,
            _thresh,
            _amtStableSell
        );
        drawAdditional(msg.sender);
        
        emit registered(_stable, _thresh, _amtStableSell, msg.sender);
    }

    function modify(address _stable, uint256 _thresh, uint256 _amtStableSell) public{
        params memory param = userParams[msg.sender];
        address stable = _stable != address(0) ? _stable : param.stable;
        uint256 thresh = _thresh > 0 ? _thresh : param.thresh;
        uint256 amtStableSell = _amtStableSell > 0 ? _amtStableSell : param.amtStableSell;
        userParams[msg.sender] = params(
            stable,
            thresh,
            amtStableSell
        );
        emit updatedParams(stable, thresh, amtStableSell, msg.sender);
    }

    function tradeWethForWstethIfNeeded(address _for) internal {
        params memory param = userParams[_for];
        if (userBalances[_for][WETH] >= param.thresh){
            //swap weth for wsteth on Bal
            ISwapper.SingleSwap memory swapdata = ISwapper.SingleSwap(
                balPoolId,
                ISwapper.SwapKind(0),
                IAsset(WETH),
                IAsset(WSTETH),
                userBalances[_for][WETH],
                bytes("0")
            );
            ISwapper.FundManagement memory fm = ISwapper.FundManagement(
                address(this),
                false,
                payable(address(this)),
                false
            );
            IERC20(WETH).approve(BALVAULT, type(uint256).max);
            uint256 prevWsteth = IERC20(WSTETH).balanceOf(address(this));
            ISwapper(BALVAULT).swap(
                swapdata,
                fm,
                userBalances[_for][WETH]/4,
                block.timestamp + 1800
            );
            uint256 postWsteth = IERC20(WSTETH).balanceOf(address(this));
            userBalances[_for][WSTETH] += (postWsteth-prevWsteth);
            userBalances[_for][WETH] = 0;
        }
    }

    function swapStableForWeth(address _for) public {
        require((msg.sender == _for)||(msg.sender == this.owner())||(msg.sender == AGENT), "NOT PERMITTTED");
        //the owner permission is temporary for debugging
        //quote the price from gmx reader
        params memory param = userParams[_for];
        (uint256 afterFees,) = IReader(READER).getAmountOut(
            IVault(VAULT),
            param.stable,
            WETH,
            param.amtStableSell
        );
        //adjust for slippage
        uint256 admissible = (afterFees*80)/100;
        drawAdditional(_for);
        //swap
        address [] memory path = new address[](2);
        path[0] = param.stable;
        path[1] = WETH;
        uint256 prevWeth = IERC20(WETH).balanceOf(address(this));
        IERC20(param.stable).approve(ROUTER, type(uint256).max);
        IRouter(ROUTER).swap(
            path, param.amtStableSell, admissible, address(this)
        );
        uint256 currentWeth = IERC20(WETH).balanceOf(address(this));
        userBalances[_for][WETH] += (currentWeth-prevWeth);
        userBalances[_for][param.stable] -= param.amtStableSell;
        tradeWethForWstethIfNeeded(_for);
    }

    function target() public {
        require(msg.sender == AGENT, "ONLY AGENT");
            for (uint256 i = 0; i<users.length; i++){
                swapStableForWeth(users[i]);
            }
        
    }

}