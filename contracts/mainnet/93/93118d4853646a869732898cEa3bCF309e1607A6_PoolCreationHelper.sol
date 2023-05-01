// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "Ownable.sol";
import "IERC20.sol";
import "SafeERC20.sol";
import "IVault.sol";
import "IWeightedPoolFactoryV4.sol";
import "IComposableStableFactoryV4.sol";
import "IWeightedPool.sol";
import "IComposableStablePool.sol";


interface IPool {
    function getPoolId() external view returns (bytes32);
}

/**
 * @title The MaxiPoolCreationHelperV1
 * @author tritium.eth
 * @notice This contract attempts to make creating and initializing a pool easier from etherscan.
 */
contract PoolCreationHelper is Ownable {
    IVault public immutable vault;
    IWeightedPoolFactoryV4 public  weightedFactory;
    IComposableStableFactoryV4 public  stableFactory;
    address public constant DAO = 0xBA1BA1ba1BA1bA1bA1Ba1BA1ba1BA1bA1ba1ba1B;
    uint256 public constant defaultTokenRateCacheDuration = 21600;

    event FactoryChange(address newWeightedPool, address newStablePoolFactory);

    constructor(IVault _vault, IWeightedPoolFactoryV4 _weightedFactory, IComposableStableFactoryV4 _stableFactory ) {
        weightedFactory = _weightedFactory;
        stableFactory = _stableFactory;
        vault = _vault;
        emit FactoryChange(address(weightedFactory), address(stableFactory));
    }

        
    struct StablePoolData {
        address addr;
        address rateProvider;
        bool exemptFees;
        uint256 amount;
    }
    
    struct WeightedPoolData {
        address addr;
        uint256 amount;
        uint256 weight;
        address rateProvider;
    }

    /**
      * @notice Easy and complete of a V4 stable swap pool - using the factory directly saves a little gas
     * @param name The Long Name of the pool token - Normally like Balancer B-33WETH-33WBTC-34USDC Token - MAX 67 characters if you want a gauge
     * @param symbol The symbol - Normally like B-33WETH-33WBTC-34USDC  - Max 40 characters if you want a gauge
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions.
     * @param amplificationParameter Also known as the A factor.  Defines how fast the pool slips when off balance.  Recommend <50 if you don't know what you are doing.
     * @param exemptFees_supports_empty_list_to_default Speak with the Maxis about how to use this if your pool includes other boosted BPTs.  Otherwise set to an empty list
     * @param rateProviders_supports_empty_list_to_default An ordered list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param weiAmountsPerToken An ordered list of amounts (wei denominated) of tokens for the initial deposit.  This will define opening prices. You  must have open approvals for each token to the helper.
     * @param swapFeeBPS The swap fee expressed in basis points from 1 to 1000 (0.01 - 10%)
     * @param somethingRandomForSalt A salt for the create2 (if you don't know just put something random like 0x123abc©©
     * @return The address of the created pool
   */
    function createAndJoinStableSwap (
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256 amplificationParameter,
        address[] memory rateProviders_supports_empty_list_to_default,
        bool[] memory exemptFees_supports_empty_list_to_default,
        uint256[] memory weiAmountsPerToken,
        uint256 swapFeeBPS,
        bytes32 somethingRandomForSalt
    ) public returns (address) {
        address poolAddress = createStablePool(name,
            symbol,
            tokens,
            amplificationParameter,
            rateProviders_supports_empty_list_to_default,
            exemptFees_supports_empty_list_to_default,
            swapFeeBPS,
            somethingRandomForSalt);
        IComposableStablePool pool = IComposableStablePool(poolAddress);
        bytes32 poolId = pool.getPoolId();
        initJoinStableSwap(poolId, address(pool), tokens, weiAmountsPerToken);
        return poolAddress;
    }
    /**
     * @notice Easy Creation of a V4 weighted pool - using the factory directly saves a little gas
     * @param name The Long Name of the pool token - Normally like Balancer B-33WETH-33WBTC-34USDC Token - MAX 67 characters if you want a gauge
     * @param symbol The symbol - Normally like B-33WETH-33WBTC-34USDC  - Max 40 characters if you want a gauge
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions
     * @param weightsFrom100 A list of token weights in percentage points ordered by the token addresses above (adds up to 100)
     * @param rateProviders_supports_empty_list_to_default An ordered list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param weiAmountsPerToken An ordered list of amounts (wei denominated) of tokens for the initial deposit.  This will define opening prices. You  must have open approvals for each token to the helper.
     * @param swapFeeBPS The swap fee expressed in basis points from 1 to 1000 (0.01 - 10%)
     * @param somethingRandomForSalt A salt for the create2 (if you don't know just put something random like 0x123abc
     * @return The address of the created pool
    */
    function createAndJoinWeightedPool(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        address[] memory rateProviders_supports_empty_list_to_default,
        uint256[] memory weiAmountsPerToken,
        uint256[] memory  weightsFrom100,
        uint256 swapFeeBPS,
        bytes32 somethingRandomForSalt
    ) public returns (address) {
        address poolAddress = createWeightedPool(name, symbol, tokens, rateProviders_supports_empty_list_to_default,  weightsFrom100, swapFeeBPS, somethingRandomForSalt);
        IWeightedPool pool = IWeightedPool(poolAddress);
        bytes32 poolId = pool.getPoolId();
        initJoinWeightedPool(poolId, poolAddress, tokens, weiAmountsPerToken);
        return poolAddress;
    }

    /**
      * @notice Init Joins an empty pool to set the starting price
     * @param poolId the pool id of the pool to init join
     * @param poolAddress The address of the pools BPT
     * @param tokenAddresses a list of all the tokens in the pool, sorted from lowest to highest (0 to F)
     * @param weiAmountsPerToken a list of amounts such that a matching index returns a token/amount pair
     */
    function initJoinWeightedPool(
        bytes32 poolId,
        address poolAddress,
        address[] memory tokenAddresses,
        uint256[] memory weiAmountsPerToken
    ) public {
        require(tokenAddresses.length == weiAmountsPerToken.length, "Amounts and tokens arrays are of different length");
        IAsset[] memory tokens = toIAssetArray(tokenAddresses);

        // The 0 as the first argument represents an init join
        bytes memory userData = abi.encode(0, weiAmountsPerToken);

        // Construct the JoinPoolRequest struct
        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: tokens,
            maxAmountsIn: weiAmountsPerToken,
            userData: userData,
            fromInternalBalance: false
        });

        // Call the joinPool function
        for (uint8 i=0; i < tokenAddresses.length; i++) {
            if(tokenAddresses[i] != poolAddress) {
                IERC20 t = IERC20(tokenAddresses[i]);
                SafeERC20.safeTransferFrom(t, msg.sender, address(this), weiAmountsPerToken[i]);
                if (t.allowance(address(this), address(vault)) < weiAmountsPerToken[i]) {
                    SafeERC20.safeApprove(t, address(vault), weiAmountsPerToken[i]);
                }
            }
        }
        vault.joinPool(poolId, address(this), msg.sender, request);
    }


    /**
      * @notice Easy Creation of a V4 weighted pool - using the factory directly saves a little gas
     * @param name The Long Name of the pool token - Normally like Balancer B-33WETH-33WBTC-34USDC Token
     * @param symbol The symbol - Normally like B-33WETH-33WBTC-34USDC
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions
     * @param weightsFrom100 A list of token weights in percentage points ordered by the token addresses above (adds up to 100)
     * @param rateProviders A list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param swapFeeBPS The swap fee expressed in basis ponts from 1 to 1000 (0.01 - 10%)
     * @param somethingRandomForSalt A salt for the create2 (if you don't know just put something random like 0x123abc
     * @return The address of the created pool
    */
    function createWeightedPool(
        string memory  name,
        string memory  symbol,
        address[] memory tokens,
        address[] memory rateProviders,
        uint256[] memory weightsFrom100,
        uint256 swapFeeBPS,
        bytes32 somethingRandomForSalt
    ) public returns (address) {
        // Check Stuff
        uint len = tokens.length;
        require(len <= 8, "Weighted pools can support max 8 tokens");
        require(len == weightsFrom100.length, "weightsFrom 100 not same len as tokens");
        require(len == rateProviders.length || rateProviders.length == 0, "rateProviders  not same len as tokens");

        // Transform Weights
        uint256 totalWeight;
        for (uint i=0; i < len; i++) {
            weightsFrom100[i] = weightsFrom100[i] * 10 **16; // not renaming var to save local stack space
            totalWeight += weightsFrom100[i];
        }
        require(totalWeight == 1e18, "Total Pool Weight does not add up to 100");

        // Replace empty array with zeroed out rate providers
        bool emptyRateProviders = rateProviders.length == 0;
        address[] memory RateProviders = new address[](len);
        if(!emptyRateProviders){
            RateProviders = rateProviders;
        }
        require(RateProviders.length == len);
        // Transform Fees
        require(swapFeeBPS >=1  && swapFeeBPS <= 1000, "Fees must be between 0.01%(1 BPS) and 10%(1000 BPS)");
        return  weightedFactory.create(name, symbol, tokens, weightsFrom100, RateProviders, swapFeeBPS * 10 ** 14, DAO, somethingRandomForSalt);
    }


    /**
      * @notice Easy Creation of a V4 stable swap pool - using the factory directly saves a little gas
     * @param name The Long Name of the pool token - Normally like Balancer B-33WETH-33WBTC-34USDC Token - MAX 67 characters if you want a gauge
     * @param symbol The symbol - Normally like B-33WETH-33WBTC-34USDC  - Max 40 characters if you want a gauge
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions.
     * @param amplificationParameter Also known as the A factor.  Defines how fast the pool slips when off balance.  Recommend <50 if you don't know what you are doing.
     * @param exemptFees_supports_empty_list_to_default Speak with the Maxis about how to use this if your pool includes other boosted BPTs.  Otherwise set to an empty list
     * @param rateProviders_supports_empty_list_to_default An ordered list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param swapFeeBPS The swap fee expressed in basis points from 1 to 1000 (0.01 - 10%)
     * @param somethingRandomForSalt A salt for the create2 (if you don't know just put something random like 0x123abc
     * @return The address of the created pool
   */
    function createStablePool(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256 amplificationParameter,
        address[] memory rateProviders_supports_empty_list_to_default,
        bool[] memory exemptFees_supports_empty_list_to_default,
        uint256 swapFeeBPS,
        bytes32 somethingRandomForSalt
    ) public returns (address) {
        // Check Stuff
        uint len = tokens.length;
        require(len <= 5, "Stable pools can only spport max 5 tokens");
        require(len == rateProviders_supports_empty_list_to_default.length || rateProviders_supports_empty_list_to_default.length == 0, "rateProviders  not same len as tokens or empty");
        require(len == exemptFees_supports_empty_list_to_default.length || exemptFees_supports_empty_list_to_default.length == 0, "ExemptFees not same len as tokens or empty");
        require(amplificationParameter > 1, "A Factor must be over 1");
        require(amplificationParameter < 2000, "This interface does not support creating pools with A-factor over 2000, you can use the factory directly");
        require(bytes(symbol).length <= 26, "Symbols with more than 26 characters break gauge creation");
        require(bytes(symbol).length >= 6, "You can do better than that on the symbol name.  BPT-80XXX-20YYY");
        require(bytes(name).length >= 10, "Use more than 10 characters and less than around 60 in your pool name");


        // pack tokenRateCacheDurations with default
        uint256[] memory tokenRateCacheDurations = new uint256[](tokens.length);
        for (uint i; i < tokenRateCacheDurations.length; ++i) tokenRateCacheDurations[i] = defaultTokenRateCacheDuration;

        // Handle Exempt Fees
        if(exemptFees_supports_empty_list_to_default.length == 0){
            exemptFees_supports_empty_list_to_default = new bool[](tokens.length);
        }

        // Hanlde Rate Providers
        if(rateProviders_supports_empty_list_to_default.length == 0){
            rateProviders_supports_empty_list_to_default = new address[](tokens.length);
        }
        require(rateProviders_supports_empty_list_to_default.length == len, "exemptFees list is not empty or the length of token list");

        // Transform Fees
        require(swapFeeBPS >=1  && swapFeeBPS <= 1000, "Fees must be between 0.01%(1 BPS) and 10%(1000 BPS)");
            return  stableFactory.create(name, symbol, tokens, amplificationParameter, rateProviders_supports_empty_list_to_default, tokenRateCacheDurations, exemptFees_supports_empty_list_to_default, swapFeeBPS * 10 ** 14, DAO, somethingRandomForSalt);
    }

        /**
      * @notice Init Joins an empty pool to set the starting price
     * @param poolId the pool id of the pool to init join
     * @param tokenAddresses a list of all the tokens in the pool, sorted from lowest to highest (0 to F)
     * @param weiAmountsPerToken An ordered list of amounts (wei denominated) of tokens for the initial deposit.  This will define opening prices. You  must have open approvals for each token to the helper.
     */
    function initJoinStableSwap(
        bytes32 poolId,
        address poolAddress,
        address[] memory tokenAddresses,
        uint256[] memory weiAmountsPerToken
    ) public {
        require(tokenAddresses.length == weiAmountsPerToken.length, "Arrays of different length");
        /// TODO consider a check around balanced deposits
        bool foundOwnToken;
        // Composable pools include their own token as a phantom token.  On initjoin these tokens must be created, 2*111 is a min amount advised by blabs
        //  The own pool token is minted on initjoin not transferred from the caller.
        for(uint8 i=0; i<tokenAddresses.length; i++){
            if (tokenAddresses[i] == poolAddress){
                weiAmountsPerToken[i] = 2**111;
                foundOwnToken = true;
            }
        }

        if(!foundOwnToken){
            tokenAddresses = appendAddress(tokenAddresses, poolAddress);
            weiAmountsPerToken = appendAmount(weiAmountsPerToken, 2**111);
            (tokenAddresses, weiAmountsPerToken) = sortAmountsByAddresses(tokenAddresses, weiAmountsPerToken);
        }
        IAsset[] memory tokens = toIAssetArray(tokenAddresses);

        // The 0 as the first argument represents an init join
        bytes memory userData = abi.encode(0, weiAmountsPerToken);

        // Construct the JoinPoolRequest struct
        IVault.JoinPoolRequest memory request = IVault.JoinPoolRequest({
            assets: tokens,
            maxAmountsIn: weiAmountsPerToken,
            userData: userData,
            fromInternalBalance: false
        });

        // Call the joinPool function
        for (uint8 i=0; i < tokenAddresses.length; i++) {
            if(tokenAddresses[i] != poolAddress) {
                IERC20 t = IERC20(tokenAddresses[i]);
                SafeERC20.safeTransferFrom(t, msg.sender, address(this), weiAmountsPerToken[i]);
                if (t.allowance(address(this), address(vault)) < weiAmountsPerToken[i]) {
                    SafeERC20.safeApprove(t, address(vault), weiAmountsPerToken[i]);
                }
            }
        }
        vault.joinPool(poolId, address(this), msg.sender, request);

    }

    /// Admin Functions
          /**
   * @notice Sweep the full contract's balance for a given ERC-20 token (save tokens that somehow ended up in here)
   * @param token The ERC-20 token which needs to be swept
   * @param payee The address to pay
   */
    function sweep(address token, address payee) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(payee, balance);
    }

    function changeFactories(IWeightedPoolFactoryV4 _weightedFactory, IComposableStableFactoryV4 _stableFactory) external onlyOwner {
        weightedFactory = _weightedFactory;
        stableFactory = _stableFactory;
        emit FactoryChange(address(weightedFactory), address(stableFactory));
    }

    /// Sort Helpers

    /**
     * @notice Converts an array of token addresses to an array of IAsset objects
     * @param tokenAddresses the array of token addresses to convert
     * @return the array of IAsset objects
     */
    function toIAssetArray(address[] memory tokenAddresses) private pure returns (IAsset[] memory) {
        IAsset[] memory assets = new IAsset[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            assets[i] = IAsset(tokenAddresses[i]);
        }
        return assets;
    }


    /**
      * @notice Sort function for stable create
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions.
     * @param rateProviders  An ordered list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param amounts The amounts per token for the init join to set initial price
     * @param weights The weights per token of the pool, adding up to 100
     * @return All the lists sorted together.
   */

function sortForWeighted(address[] memory tokens, address[] memory rateProviders, uint256[] memory amounts, uint256[] memory weights) public pure returns (address[] memory, address[] memory, uint256[] memory, uint256[] memory) {
    uint256 n = tokens.length;
    if (rateProviders.length == 0) {
        rateProviders = new address[](n);
    }
    WeightedPoolData[] memory data = new WeightedPoolData[](n);
    for (uint256 i = 0; i < n; i++) {
        data[i] = WeightedPoolData(tokens[i], amounts[i], weights[i], rateProviders[i]);
    }
    for (uint256 i = 0; i < n - 1; i++) {
        for (uint256 j = 0; j < n - i - 1; j++) {
            if (data[j].addr > data[j + 1].addr) {
                WeightedPoolData memory tempData = data[j];
                data[j] = data[j + 1];
                data[j + 1] = tempData;
            }
        }
    }
    for (uint8 i = 0; i < n; i++) {
        amounts[i] = data[i].amount;
        weights[i] = data[i].weight;
        rateProviders[i] = data[i].rateProvider;
        tokens[i] = data[i].addr;
    }
    return (tokens, rateProviders, amounts, weights);
}


    /**
      * @notice Sort function for stable create
     * @param tokens An list of token addresses in the pool in ascending order (from 0 to f) - check the read functions.
     * @param rateProviders An ordered list of rateProviders using zero addresses where there is none, or an empty array [] to autofill zeros for all rate providers.
     * @param exemptFees Speak with the Maxis about how to use this if your pool includes other boosted BPTs.  Otherwise set to an empty list
     * @param amounts The amounts per token for the init join to set initial price
     * @return All the lists sorted together.
   */
    function sortForStable(
        address[] memory tokens,
        address[] memory rateProviders,
        bool[] memory exemptFees,
        uint256[] memory amounts
    ) public pure returns (
        address[] memory,
        address[] memory,
        bool[] memory,
        uint256[] memory
    ) {
        uint256 n = tokens.length;
        if (rateProviders.length == 0) {
            rateProviders = new address[](n);
        }
        if (exemptFees.length == 0) {
            exemptFees = new bool[](n);
        }
        StablePoolData[] memory data = new StablePoolData[](n);
        for (uint256 i = 0; i < n; i++) {
            data[i] = StablePoolData({
                addr: tokens[i],
                rateProvider: rateProviders[i],
                exemptFees: exemptFees[i],
                amount: amounts[i]
            });
        }
        for (uint256 i = 0; i < n - 1; i++) {
            for (uint256 j = 0; j < n - i - 1; j++) {
                if (data[j].addr > data[j + 1].addr) {
                    StablePoolData memory tempData = data[j];
                    data[j] = data[j + 1];
                    data[j + 1] = tempData;
                }
            }
        }
        for (uint256 i = 0; i < n; i++) {
            tokens[i] = data[i].addr;
            rateProviders[i] = data[i].rateProvider;
            exemptFees[i] = data[i].exemptFees;
            amounts[i] = data[i].amount;
        }
        return (tokens, rateProviders, exemptFees, amounts);
    }

    function sortAmountsByAddresses(address[] memory addresses, uint256[] memory amounts) public pure returns (address[] memory, uint256[] memory) {
    uint256 n = addresses.length;
    for (uint256 i = 0; i < n - 1; i++) {
        for (uint256 j = 0; j < n - i - 1; j++) {
            if (addresses[j] > addresses[j + 1]) {
                address tempAddress = addresses[j];
                addresses[j] = addresses[j + 1];
                addresses[j + 1] = tempAddress;
                uint256 tempAmount = amounts[j];
                amounts[j] = amounts[j + 1];
                amounts[j + 1] = tempAmount;
            }
        }
    }
    return (addresses, amounts);
    }
function appendAddress(address[] memory addressArray, address newAddress) private pure returns (address[] memory) {
    uint256 length = addressArray.length;
    address[] memory newArray = new address[](length + 1);
    for (uint256 i = 0; i < length; i++) {
        newArray[i] = addressArray[i];
    }
    newArray[length] = newAddress;
    return newArray;
}


function appendAmount(uint256[] memory amountArray, uint256 newAmount) private pure returns (uint256[] memory) {
    uint256 length = amountArray.length;
    uint256[] memory newArray = new uint256[](length + 1);
    for (uint256 i = 0; i < length; i++) {
        newArray[i] = amountArray[i];
    }
    newArray[length] = newAmount;
    return newArray;
}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Permit.sol";
import "Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
    }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
        success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
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
     * @dev Returns the domain separator used in the encoding of the signature for `permit`, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "IAuthentication.sol";
import "ISignaturesValidator.sol";
import "ITemporarilyPausable.sol";
import "IWETH.sol";

import "IAsset.sol";
import "IAuthorizer.sol";
import "IFlashLoanRecipient.sol";
import "IProtocolFeesCollector.sol";

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Full external interface for the Vault core contract - no external or public methods exist in the contract that
 * don't override one of these declarations.
 */
interface IVault is ISignaturesValidator, ITemporarilyPausable, IAuthentication {
    // Generalities about the Vault:
    //
    // - Whenever documentation refers to 'tokens', it strictly refers to ERC20-compliant token contracts. Tokens are
    // transferred out of the Vault by calling the `IERC20.transfer` function, and transferred in by calling
    // `IERC20.transferFrom`. In these cases, the sender must have previously allowed the Vault to use their tokens by
    // calling `IERC20.approve`. The only deviation from the ERC20 standard that is supported is functions not returning
    // a boolean value: in these scenarios, a non-reverting call is assumed to be successful.
    //
    // - All non-view functions in the Vault are non-reentrant: calling them while another one is mid-execution (e.g.
    // while execution control is transferred to a token contract during a swap) will result in a revert. View
    // functions can be called in a re-reentrant way, but doing so might cause them to return inconsistent results.
    // Contracts calling view functions in the Vault must make sure the Vault has not already been entered.
    //
    // - View functions revert if referring to either unregistered Pools, or unregistered tokens for registered Pools.

    // Authorizer
    //
    // Some system actions are permissioned, like setting and collecting protocol fees. This permissioning system exists
    // outside of the Vault in the Authorizer contract: the Vault simply calls the Authorizer to check if the caller
    // can perform a given action.

    /**
     * @dev Returns the Vault's Authorizer.
     */
    function getAuthorizer() external view returns (IAuthorizer);

    /**
     * @dev Sets a new Authorizer for the Vault. The caller must be allowed by the current Authorizer to do this.
     *
     * Emits an `AuthorizerChanged` event.
     */
    function setAuthorizer(IAuthorizer newAuthorizer) external;

    /**
     * @dev Emitted when a new authorizer is set by `setAuthorizer`.
     */
    event AuthorizerChanged(IAuthorizer indexed newAuthorizer);

    // Relayers
    //
    // Additionally, it is possible for an account to perform certain actions on behalf of another one, using their
    // Vault ERC20 allowance and Internal Balance. These accounts are said to be 'relayers' for these Vault functions,
    // and are expected to be smart contracts with sound authentication mechanisms. For an account to be able to wield
    // this power, two things must occur:
    //  - The Authorizer must grant the account the permission to be a relayer for the relevant Vault function. This
    //    means that Balancer governance must approve each individual contract to act as a relayer for the intended
    //    functions.
    //  - Each user must approve the relayer to act on their behalf.
    // This double protection means users cannot be tricked into approving malicious relayers (because they will not
    // have been allowed by the Authorizer via governance), nor can malicious relayers approved by a compromised
    // Authorizer or governance drain user funds, since they would also need to be approved by each individual user.

    /**
     * @dev Returns true if `user` has approved `relayer` to act as a relayer for them.
     */
    function hasApprovedRelayer(address user, address relayer) external view returns (bool);

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(
        address sender,
        address relayer,
        bool approved
    ) external;

    /**
     * @dev Emitted every time a relayer is approved or disapproved by `setRelayerApproval`.
     */
    event RelayerApprovalChanged(address indexed relayer, address indexed sender, bool approved);

    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] memory tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] memory ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] memory tokens,
        address[] memory assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] memory tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);

    // Flash Loans

    /**
     * @dev Performs a 'flash loan', sending tokens to `recipient`, executing the `receiveFlashLoan` hook on it,
     * and then reverting unless the tokens plus a proportional protocol fee have been returned.
     *
     * The `tokens` and `amounts` arrays must have the same length, and each entry in these indicates the loan amount
     * for each token contract. `tokens` must be sorted in ascending order.
     *
     * The 'userData' field is ignored by the Vault, and forwarded as-is to `recipient` as part of the
     * `receiveFlashLoan` call.
     *
     * Emits `FlashLoan` events.
     */
    function flashLoan(
        IFlashLoanRecipient recipient,
        IERC20[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;

    /**
     * @dev Emitted for each individual flash loan performed by `flashLoan`.
     */
    event FlashLoan(IFlashLoanRecipient indexed recipient, IERC20 indexed token, uint256 amount, uint256 feeAmount);

    // Asset Management
    //
    // Each token registered for a Pool can be assigned an Asset Manager, which is able to freely withdraw the Pool's
    // tokens from the Vault, deposit them, or assign arbitrary values to its `managed` balance (see
    // `getPoolTokenInfo`). This makes them extremely powerful and dangerous. Even if an Asset Manager only directly
    // controls one of the tokens in a Pool, a malicious manager could set that token's balance to manipulate the
    // prices of the other tokens, and then drain the Pool with swaps. The risk of using Asset Managers is therefore
    // not constrained to the tokens they are managing, but extends to the entire Pool's holdings.
    //
    // However, a properly designed Asset Manager smart contract can be safely used for the Pool's benefit,
    // for example by lending unused tokens out for interest, or using them to participate in voting protocols.
    //
    // This concept is unrelated to the IAsset interface.

    /**
     * @dev Performs a set of Pool balance operations, which may be either withdrawals, deposits or updates.
     *
     * Pool Balance management features batching, which means a single contract call can be used to perform multiple
     * operations of different kinds, with different Pools and tokens, at once.
     *
     * For each operation, the caller must be registered as the Asset Manager for `token` in `poolId`.
     */
    function managePoolBalance(PoolBalanceOp[] memory ops) external;

    struct PoolBalanceOp {
        PoolBalanceOpKind kind;
        bytes32 poolId;
        IERC20 token;
        uint256 amount;
    }

    /**
     * Withdrawals decrease the Pool's cash, but increase its managed balance, leaving the total balance unchanged.
     *
     * Deposits increase the Pool's cash, but decrease its managed balance, leaving the total balance unchanged.
     *
     * Updates don't affect the Pool's cash balance, but because the managed balance changes, it does alter the total.
     * The external amount can be either increased or decreased by this call (i.e., reporting a gain or a loss).
     */
    enum PoolBalanceOpKind { WITHDRAW, DEPOSIT, UPDATE }

    /**
     * @dev Emitted when a Pool's token Asset Manager alters its balance via `managePoolBalance`.
     */
    event PoolBalanceManaged(
        bytes32 indexed poolId,
        address indexed assetManager,
        IERC20 indexed token,
        int256 cashDelta,
        int256 managedDelta
    );

    // Protocol Fees
    //
    // Some operations cause the Vault to collect tokens in the form of protocol fees, which can then be withdrawn by
    // permissioned accounts.
    //
    // There are two kinds of protocol fees:
    //
    //  - flash loan fees: charged on all flash loans, as a percentage of the amounts lent.
    //
    //  - swap fees: a percentage of the fees charged by Pools when performing swaps. For a number of reasons, including
    // swap gas costs and interface simplicity, protocol swap fees are not charged on each individual swap. Rather,
    // Pools are expected to keep track of how much they have charged in swap fees, and pay any outstanding debts to the
    // Vault when they are joined or exited. This prevents users from joining a Pool with unpaid debt, as well as
    // exiting a Pool in debt without first paying their share.

    /**
     * @dev Returns the current protocol fee module.
     */
    function getProtocolFeesCollector() external view returns (IProtocolFeesCollector);

    /**
     * @dev Safety mechanism to pause most Vault operations in the event of an emergency - typically detection of an
     * error in some part of the system.
     *
     * The Vault can only be paused during an initial time period, after which pausing is forever disabled.
     *
     * While the contract is paused, the following features are disabled:
     * - depositing and transferring internal balance
     * - transferring external balance (using the Vault's allowance)
     * - swaps
     * - joining Pools
     * - Asset Manager interactions
     *
     * Internal Balance can still be withdrawn, and Pools exited.
     */
    function setPaused(bool paused) external;

    /**
     * @dev Returns the Vault's WETH instance.
     */
    function WETH() external view returns (IWETH);
    // solhint-disable-previous-line func-name-mixedcase
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthentication {
    /**
     * @dev Returns the action identifier associated with the external function described by `selector`.
     */
    function getActionId(bytes4 selector) external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the SignatureValidator helper, used to support meta-transactions.
 */
interface ISignaturesValidator {
    /**
     * @dev Returns the EIP712 domain separator.
     */
    function getDomainSeparator() external view returns (bytes32);

    /**
     * @dev Returns the next nonce used by an address to sign messages.
     */
    function getNextNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Interface for the TemporarilyPausable helper.
 */
interface ITemporarilyPausable {
    /**
     * @dev Emitted every time the pause state changes by `_setPaused`.
     */
    event PausedStateChanged(bool paused);

    /**
     * @dev Returns the current paused state.
     */
    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

import "IERC20.sol";

/**
 * @dev Interface for WETH9.
 * See https://github.com/gnosis/canonical-weth/blob/0dd1ea3e295eef916d0c6223ec63141137d22d67/contracts/WETH9.sol
 */
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

interface IAuthorizer {
    /**
     * @dev Returns true if `account` can perform the action described by `actionId` in the contract `where`.
     */
    function canPerform(
        bytes32 actionId,
        address account,
        address where
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;

// Inspired by Aave Protocol's IFlashLoanReceiver.

import "IERC20.sol";

interface IFlashLoanRecipient {
    /**
     * @dev When `flashLoan` is called on the Vault, it invokes the `receiveFlashLoan` hook on the recipient.
     *
     * At the time of the call, the Vault will have transferred `amounts` for `tokens` to the recipient. Before this
     * call returns, the recipient must have transferred `amounts` plus `feeAmounts` for each token back to the
     * Vault, or else the entire flash loan will revert.
     *
     * `userData` is the same value passed in the `IVault.flashLoan` call.
     */
    function receiveFlashLoan(
        IERC20[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory userData
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "IERC20.sol";

import "IVault.sol";
import "IAuthorizer.sol";

interface IProtocolFeesCollector {
    event SwapFeePercentageChanged(uint256 newSwapFeePercentage);
    event FlashLoanFeePercentageChanged(uint256 newFlashLoanFeePercentage);

    function withdrawCollectedFees(
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        address recipient
    ) external;

    function setSwapFeePercentage(uint256 newSwapFeePercentage) external;

    function setFlashLoanFeePercentage(uint256 newFlashLoanFeePercentage) external;

    function getSwapFeePercentage() external view returns (uint256);

    function getFlashLoanFeePercentage() external view returns (uint256);

    function getCollectedFeeAmounts(IERC20[] memory tokens) external view returns (uint256[] memory feeAmounts);

    function getAuthorizer() external view returns (IAuthorizer);

    function vault() external view returns (IVault);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IWeightedPoolFactoryV4 {
    event FactoryDisabled();
    event PoolCreated(address indexed pool);

    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256[] memory normalizedWeights,
        address[] memory rateProviders,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns (address);

    function disable() external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getAuthorizer() external view returns (address);

    function getCreationCode() external view returns (bytes memory);

    function getCreationCodeContracts()
        external
        view
        returns (address contractA, address contractB);

    function getPauseConfiguration()
        external
        view
        returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration);

    function getPoolVersion() external view returns (string memory);

    function getProtocolFeePercentagesProvider()
        external
        view
        returns (address);

    function getVault() external view returns (address);

    function isDisabled() external view returns (bool);

    function isPoolFromFactory(address pool) external view returns (bool);

    function version() external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract IVault","name":"vault","type":"address"},{"internalType":"contract IProtocolFeePercentagesProvider","name":"protocolFeeProvider","type":"address"},{"internalType":"string","name":"factoryVersion","type":"string"},{"internalType":"string","name":"poolVersion","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[],"name":"FactoryDisabled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pool","type":"address"}],"name":"PoolCreated","type":"event"},{"inputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"internalType":"uint256[]","name":"normalizedWeights","type":"uint256[]"},{"internalType":"contract IRateProvider[]","name":"rateProviders","type":"address[]"},{"internalType":"uint256","name":"swapFeePercentage","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"}],"name":"create","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"disable","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"selector","type":"bytes4"}],"name":"getActionId","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAuthorizer","outputs":[{"internalType":"contract IAuthorizer","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCreationCode","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCreationCodeContracts","outputs":[{"internalType":"address","name":"contractA","type":"address"},{"internalType":"address","name":"contractB","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPauseConfiguration","outputs":[{"internalType":"uint256","name":"pauseWindowDuration","type":"uint256"},{"internalType":"uint256","name":"bufferPeriodDuration","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPoolVersion","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getProtocolFeePercentagesProvider","outputs":[{"internalType":"contract IProtocolFeePercentagesProvider","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVault","outputs":[{"internalType":"contract IVault","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isDisabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"pool","type":"address"}],"name":"isPoolFromFactory","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

interface IComposableStableFactoryV4 {
    event FactoryDisabled();
    event PoolCreated(address indexed pool);

    function create(
        string memory name,
        string memory symbol,
        address[] memory tokens,
        uint256 amplificationParameter,
        address[] memory rateProviders,
        uint256[] memory tokenRateCacheDurations,
        bool[] memory exemptFromYieldProtocolFeeFlags,
        uint256 swapFeePercentage,
        address owner,
        bytes32 salt
    ) external returns (address);

    function disable() external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getAuthorizer() external view returns (address);

    function getCreationCode() external view returns (bytes memory);

    function getCreationCodeContracts()
        external
        view
        returns (address contractA, address contractB);

    function getPauseConfiguration()
        external
        view
        returns (uint256 pauseWindowDuration, uint256 bufferPeriodDuration);

    function getPoolVersion() external view returns (string memory);

    function getProtocolFeePercentagesProvider()
        external
        view
        returns (address);

    function getVault() external view returns (address);

    function isDisabled() external view returns (bool);

    function isPoolFromFactory(address pool) external view returns (bool);

    function version() external view returns (string memory);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"contract IVault","name":"vault","type":"address"},{"internalType":"contract IProtocolFeePercentagesProvider","name":"protocolFeeProvider","type":"address"},{"internalType":"string","name":"factoryVersion","type":"string"},{"internalType":"string","name":"poolVersion","type":"string"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[],"name":"FactoryDisabled","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"pool","type":"address"}],"name":"PoolCreated","type":"event"},{"inputs":[{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"symbol","type":"string"},{"internalType":"contract IERC20[]","name":"tokens","type":"address[]"},{"internalType":"uint256","name":"amplificationParameter","type":"uint256"},{"internalType":"contract IRateProvider[]","name":"rateProviders","type":"address[]"},{"internalType":"uint256[]","name":"tokenRateCacheDurations","type":"uint256[]"},{"internalType":"bool[]","name":"exemptFromYieldProtocolFeeFlags","type":"bool[]"},{"internalType":"uint256","name":"swapFeePercentage","type":"uint256"},{"internalType":"address","name":"owner","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"}],"name":"create","outputs":[{"internalType":"contract ComposableStablePool","name":"","type":"address"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"disable","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"selector","type":"bytes4"}],"name":"getActionId","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getAuthorizer","outputs":[{"internalType":"contract IAuthorizer","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCreationCode","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getCreationCodeContracts","outputs":[{"internalType":"address","name":"contractA","type":"address"},{"internalType":"address","name":"contractB","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPauseConfiguration","outputs":[{"internalType":"uint256","name":"pauseWindowDuration","type":"uint256"},{"internalType":"uint256","name":"bufferPeriodDuration","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getPoolVersion","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getProtocolFeePercentagesProvider","outputs":[{"internalType":"contract IProtocolFeePercentagesProvider","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getVault","outputs":[{"internalType":"contract IVault","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isDisabled","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"pool","type":"address"}],"name":"isPoolFromFactory","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"version","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import "IPoolSwapStructs.sol";

interface IWeightedPool {
    struct NewPoolParams {
        string name;
        string symbol;
        address[] tokens;
        uint256[] normalizedWeights;
        address[] rateProviders;
        address[] assetManagers;
        uint256 swapFeePercentage;
    }

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event PausedStateChanged(bool paused);
    event ProtocolFeePercentageCacheUpdated(
        uint256 indexed feeType,
        uint256 protocolFeePercentage
    );
    event RecoveryModeStateChanged(bool enabled);
    event SwapFeePercentageChanged(uint256 swapFeePercentage);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DELEGATE_PROTOCOL_SWAP_FEES_SENTINEL()
        external
        view
        returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    function disableRecoveryMode() external;

    function enableRecoveryMode() external;

    function getATHRateProduct() external view returns (uint256);

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getActualSupply() external view returns (uint256);

    function getAuthorizer() external view returns (address);

    function getDomainSeparator() external view returns (bytes32);

    function getInvariant() external view returns (uint256);

    function getLastPostJoinExitInvariant() external view returns (uint256);

    function getNextNonce(address account) external view returns (uint256);

    function getNormalizedWeights() external view returns (uint256[] memory);

    function getOwner() external view returns (address);

    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );

    function getPoolId() external view returns (bytes32);

    function getProtocolFeePercentageCache(
        uint256 feeType
    ) external view returns (uint256);

    function getProtocolFeesCollector() external view returns (address);

    function getProtocolSwapFeeDelegation() external view returns (bool);

    function getRateProviders() external view returns (address[] memory);

    function getScalingFactors() external view returns (uint256[] memory);

    function getSwapFeePercentage() external view returns (uint256);

    function getVault() external view returns (address);

    function inRecoveryMode() external view returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory, uint256[] memory);

    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory, uint256[] memory);

    function onSwap(
        IPoolSwapStructs.SwapRequest memory request,
        uint256 balanceTokenIn,
        uint256 balanceTokenOut
    ) external returns (uint256);

    function pause() external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function setAssetManagerPoolConfig(
        address token,
        bytes memory poolConfig
    ) external;

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function unpause() external;

    function updateProtocolFeePercentageCache() external;

    function version() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "IERC20.sol";

import "IVault.sol";

interface IPoolSwapStructs {
    // This is not really an interface - it just defines common structs used by other interfaces: IGeneralPool and
    // IMinimalSwapInfoPool.
    //
    // This data structure represents a request for a token swap, where `kind` indicates the swap type ('given in' or
    // 'given out') which indicates whether or not the amount sent by the pool is known.
    //
    // The pool receives `tokenIn` and sends `tokenOut`. `amount` is the number of `tokenIn` tokens the pool will take
    // in, or the number of `tokenOut` tokens the Pool will send out, depending on the given swap `kind`.
    //
    // All other fields are not strictly necessary for most swaps, but are provided to support advanced scenarios in
    // some Pools.
    //
    // `poolId` is the ID of the Pool involved in the swap - this is useful for Pool contracts that implement more than
    // one Pool.
    //
    // The meaning of `lastChangeBlock` depends on the Pool specialization:
    //  - Two Token or Minimal Swap Info: the last block in which either `tokenIn` or `tokenOut` changed its total
    //    balance.
    //  - General: the last block in which *any* of the Pool's registered tokens changed its total balance.
    //
    // `from` is the origin address for the funds the Pool receives, and `to` is the destination address
    // where the Pool sends the outgoing tokens.
    //
    // `userData` is extra data provided by the caller - typically a signature from a trusted party.
    struct SwapRequest {
        IVault.SwapKind kind;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amount;
        // Misc data
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IComposableStablePool {
    event AmpUpdateStarted(
        uint256 startValue,
        uint256 endValue,
        uint256 startTime,
        uint256 endTime
    );
    event AmpUpdateStopped(uint256 currentValue);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event PausedStateChanged(bool paused);
    event ProtocolFeePercentageCacheUpdated(
        uint256 indexed feeType,
        uint256 protocolFeePercentage
    );
    event RecoveryModeStateChanged(bool enabled);
    event SwapFeePercentageChanged(uint256 swapFeePercentage);
    event TokenRateCacheUpdated(uint256 indexed tokenIndex, uint256 rate);
    event TokenRateProviderSet(
        uint256 indexed tokenIndex,
        address indexed provider,
        uint256 cacheDuration
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function DELEGATE_PROTOCOL_SWAP_FEES_SENTINEL()
        external
        view
        returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(
        address spender,
        uint256 amount
    ) external returns (bool);

    function disableRecoveryMode() external;

    function enableRecoveryMode() external;

    function getActionId(bytes4 selector) external view returns (bytes32);

    function getActualSupply() external view returns (uint256);

    function getAmplificationParameter()
        external
        view
        returns (uint256 value, bool isUpdating, uint256 precision);

    function getAuthorizer() external view returns (address);

    function getBptIndex() external view returns (uint256);

    function getDomainSeparator() external view returns (bytes32);

    function getLastJoinExitData()
        external
        view
        returns (
            uint256 lastJoinExitAmplification,
            uint256 lastPostJoinExitInvariant
        );

    function getMinimumBpt() external pure returns (uint256);

    function getNextNonce(address account) external view returns (uint256);

    function getOwner() external view returns (address);

    function getPausedState()
        external
        view
        returns (
            bool paused,
            uint256 pauseWindowEndTime,
            uint256 bufferPeriodEndTime
        );

    function getPoolId() external view returns (bytes32);

    function getProtocolFeePercentageCache(
        uint256 feeType
    ) external view returns (uint256);

    function getProtocolFeesCollector() external view returns (address);

    function getProtocolSwapFeeDelegation() external view returns (bool);

    function getRate() external view returns (uint256);

    function getRateProviders() external view returns (address[] memory);

    function getScalingFactors() external view returns (uint256[] memory);

    function getSwapFeePercentage() external view returns (uint256);

    function getTokenRate(address token) external view returns (uint256);

    function getTokenRateCache(
        address token
    )
        external
        view
        returns (
            uint256 rate,
            uint256 oldRate,
            uint256 duration,
            uint256 expires
        );

    function getVault() external view returns (address);

    function inRecoveryMode() external view returns (bool);

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) external returns (bool);

    function isTokenExemptFromYieldProtocolFee(
        address token
    ) external view returns (bool);

    function name() external view returns (string memory);

    function nonces(address owner) external view returns (uint256);

    function onExitPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory, uint256[] memory);

    function onJoinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256[] memory, uint256[] memory);

    function onSwap(
        IPoolSwapStructsLocal.SwapRequest memory swapRequest,
        uint256[] memory balances,
        uint256 indexIn,
        uint256 indexOut
    ) external returns (uint256);

    function pause() external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function queryExit(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptIn, uint256[] memory amountsOut);

    function queryJoin(
        bytes32 poolId,
        address sender,
        address recipient,
        uint256[] memory balances,
        uint256 lastChangeBlock,
        uint256 protocolSwapFeePercentage,
        bytes memory userData
    ) external returns (uint256 bptOut, uint256[] memory amountsIn);

    function setAssetManagerPoolConfig(
        address token,
        bytes memory poolConfig
    ) external;

    function setSwapFeePercentage(uint256 swapFeePercentage) external;

    function setTokenRateCacheDuration(
        address token,
        uint256 duration
    ) external;

    function startAmplificationParameterUpdate(
        uint256 rawEndValue,
        uint256 endTime
    ) external;

    function stopAmplificationParameterUpdate() external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function unpause() external;

    function updateProtocolFeePercentageCache() external;

    function updateTokenRateCache(address token) external;

    function version() external view returns (string memory);
}

interface ComposableStablePool {
    struct NewPoolParams {
        address vault;
        address protocolFeeProvider;
        string name;
        string symbol;
        address[] tokens;
        address[] rateProviders;
        uint256[] tokenRateCacheDurations;
        bool[] exemptFromYieldProtocolFeeFlags;
        uint256 amplificationParameter;
        uint256 swapFeePercentage;
        uint256 pauseWindowDuration;
        uint256 bufferPeriodDuration;
        address owner;
        string version;
    }
}

interface IPoolSwapStructsLocal {
    struct SwapRequest {
        uint8 kind;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        bytes32 poolId;
        uint256 lastChangeBlock;
        address from;
        address to;
        bytes userData;
    }
}