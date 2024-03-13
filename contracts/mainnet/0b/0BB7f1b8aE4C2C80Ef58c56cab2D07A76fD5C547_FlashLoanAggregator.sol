// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.23;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFlashLoanAggregator.sol";
import "./interfaces/IWagmiLeverageFlashCallback.sol";
import "./interfaces/IUniswapV3FlashCallback.sol";
import "./interfaces/abstract/ILiquidityManager.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./vendor0.8/uniswap/FullMath.sol";
import { TransferHelper } from "./libraries/TransferHelper.sol";

// import "hardhat/console.sol";

contract FlashLoanAggregator is Ownable, IFlashLoanAggregator, IUniswapV3FlashCallback {
    using TransferHelper for address;

    enum Protocol {
        UNKNOWN,
        UNISWAP,
        AAVE
    }
    struct Debt {
        address creditor;
        uint256 body;
        uint256 interest;
    }

    struct UniswapV3Identifier {
        bool enabled;
        address factoryV3;
        bytes32 initCodeHash;
        string name;
    }

    struct CallbackDataExt {
        address recipient;
        uint256 currentIndex;
        uint256 amount;
        uint256 prevBalance;
        Debt[] debts;
        bytes originData;
    }

    UniswapV3Identifier[] public uniswapV3Dexes;
    mapping(bytes32 => bool) public uniswapDexIsExists;
    mapping(address => bool) public wagmiLeverageContracts;

    modifier onlyWagmiLeverage() {
        require(wagmiLeverageContracts[msg.sender], "IC");
        _;
    }

    modifier correctIndx(uint256 indx) {
        require(uniswapV3Dexes.length > indx, "II");
        _;
    }
    event UniswapV3DexAdded(address factoryV3, bytes32 initCodeHash, string name);
    event UniswapV3DexChanged(address factoryV3, bytes32 initCodeHash, string name);

    error CollectedAmountIsNotEnough(uint256 desiredAmount, uint256 collectedAmount);
    error FlashLoanZeroLiquidity(address pool);

    constructor(address factoryV3, bytes32 initCodeHash, string memory name) {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        _addUniswapV3Dex(factoryV3, initCodeHash, nameHash, name);
    }

    function setWagmiLeverageAddress(address _wagmiLeverageAddress) external onlyOwner {
        wagmiLeverageContracts[_wagmiLeverageAddress] = true;
    }

    function addUniswapV3Dex(
        address factoryV3,
        bytes32 initCodeHash,
        string calldata name
    ) external onlyOwner {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(!uniswapDexIsExists[nameHash], "DE");
        _addUniswapV3Dex(factoryV3, initCodeHash, nameHash, name);
    }

    function _addUniswapV3Dex(
        address factoryV3,
        bytes32 initCodeHash,
        bytes32 nameHash,
        string memory name
    ) private {
        uniswapV3Dexes.push(
            UniswapV3Identifier({
                enabled: true,
                factoryV3: factoryV3,
                initCodeHash: initCodeHash,
                name: name
            })
        );
        uniswapDexIsExists[nameHash] = true;
        emit UniswapV3DexAdded(factoryV3, initCodeHash, name);
    }

    function editUniswapV3Dex(
        bool enabled,
        address factoryV3,
        bytes32 initCodeHash,
        uint256 indx
    ) external correctIndx(indx) onlyOwner {
        UniswapV3Identifier storage dex = uniswapV3Dexes[indx];
        dex.enabled = enabled;
        dex.factoryV3 = factoryV3;
        dex.initCodeHash = initCodeHash;
        emit UniswapV3DexChanged(factoryV3, initCodeHash, dex.name);
    }

    function flashLoan(uint256 amount, bytes memory data) external onlyWagmiLeverage {
        ILiquidityManager.CallbackData memory decodedData = abi.decode(
            data,
            (ILiquidityManager.CallbackData)
        );
        ILiquidityManager.FlashLoanParams[] memory flashLoanParams = decodedData
            .routes
            .flashLoanParams;

        require(flashLoanParams.length > 0, "FLP");
        Protocol protocol = Protocol(flashLoanParams[0].protocol);

        if (protocol == Protocol.UNISWAP) {
            address pool = _getUniswapV3Pool(decodedData.saleToken, flashLoanParams[0].data);

            (uint256 flashAmount0, uint256 flashAmount1) = _maxUniPoolFlashAmt(
                decodedData.zeroForSaleToken,
                decodedData.saleToken,
                pool,
                amount
            );

            IUniswapV3Pool(pool).flash(
                address(this),
                flashAmount0,
                flashAmount1,
                abi.encode(
                    CallbackDataExt({
                        recipient: msg.sender,
                        amount: amount,
                        currentIndex: 0,
                        prevBalance: 0,
                        debts: new Debt[](flashLoanParams.length),
                        originData: data
                    })
                )
            );
        } else if (protocol == Protocol.AAVE) {
            revert("AAVE NOT SUPPORTED YET");
        } else {
            revert("UFP");
        }
    }

    // //aave flashLoanSimple
    // function executeOperation(
    //     address /*asset*/,
    //     uint256 /*amount*/,
    //     uint256 /*premium*/,
    //     address /*initiator*/,
    //     bytes calldata params
    // ) external returns (bool) {
    //     (
    //         uint256 poolIndex,
    //         address[] memory targets,
    //         bytes[] memory execData,
    //         uint256[] memory values
    //     ) = abi.decode(params, (uint256, address[], bytes[], uint256[]));
    //     require(msg.sender == pools[poolIndex], "callback not allowed");
    //     execute(targets, execData, values);

    //     return true;
    // }

    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        CallbackDataExt memory decodedDataExt = abi.decode(data, (CallbackDataExt));
        ILiquidityManager.CallbackData memory decodedData = abi.decode(
            decodedDataExt.originData,
            (ILiquidityManager.CallbackData)
        );
        ILiquidityManager.FlashLoanParams memory flashParams = decodedData.routes.flashLoanParams[
            decodedDataExt.currentIndex
        ];
        address pool = _getUniswapV3Pool(decodedData.saleToken, flashParams.data);
        require(msg.sender == pool, "IPC");
        uint256 flashBalance = decodedData.saleToken.getBalance();
        if (flashBalance >= decodedDataExt.amount) {
            uint256 interest = decodedData.zeroForSaleToken ? fee0 : fee1;
            uint256 debtsLength = decodedDataExt.debts.length;
            for (uint256 i = 0; i < debtsLength; ) {
                if (decodedDataExt.debts[i].creditor == address(0)) {
                    debtsLength = i;
                    break;
                }
                unchecked {
                    interest += decodedDataExt.debts[i].interest;
                    ++i;
                }
            }

            decodedData.saleToken.safeTransfer(decodedDataExt.recipient, decodedDataExt.amount);
            IWagmiLeverageFlashCallback(decodedDataExt.recipient).wagmiLeverageFlashCallback(
                decodedDataExt.amount,
                interest,
                decodedDataExt.originData
            );
            decodedData.saleToken.safeTransfer(
                msg.sender,
                flashBalance -
                    decodedDataExt.prevBalance +
                    (decodedData.zeroForSaleToken ? fee0 : fee1)
            );
            for (uint256 i = 0; i < debtsLength; ) {
                Debt memory debt = decodedDataExt.debts[i];
                decodedData.saleToken.safeTransfer(debt.creditor, debt.body + debt.interest);
                unchecked {
                    ++i;
                }
            }
        } else {
            if (decodedDataExt.currentIndex == decodedData.routes.flashLoanParams.length) {
                revert CollectedAmountIsNotEnough(decodedDataExt.amount, flashBalance);
            }
            decodedDataExt.debts[decodedDataExt.currentIndex] = Debt({
                creditor: msg.sender,
                body: flashBalance - decodedDataExt.prevBalance,
                interest: decodedData.zeroForSaleToken ? fee0 : fee1
            });
            uint256 nextIndx = decodedDataExt.currentIndex + 1;
            bytes memory nextData = abi.encode(
                CallbackDataExt({
                    recipient: decodedDataExt.recipient,
                    amount: decodedDataExt.amount,
                    currentIndex: nextIndx,
                    prevBalance: flashBalance,
                    debts: decodedDataExt.debts,
                    originData: decodedDataExt.originData
                })
            );

            flashParams = decodedData.routes.flashLoanParams[nextIndx];
            Protocol protocol = Protocol(flashParams.protocol);

            if (protocol == Protocol.UNISWAP) {
                pool = _getUniswapV3Pool(decodedData.saleToken, flashParams.data);

                (uint256 flashAmount0, uint256 flashAmount1) = _maxUniPoolFlashAmt(
                    decodedData.zeroForSaleToken,
                    decodedData.saleToken,
                    pool,
                    decodedDataExt.amount - flashBalance
                );

                IUniswapV3Pool(pool).flash(address(this), flashAmount0, flashAmount1, nextData);
            } else if (protocol == Protocol.AAVE) {
                revert("AAVE NOT SUPPORTED YET");
            } else {
                revert("UFP");
            }
        }
    }

    function _maxUniPoolFlashAmt(
        bool zeroForSaleToken,
        address token,
        address pool,
        uint256 amount
    ) private view returns (uint256 flashAmount0, uint256 flashAmount1) {
        uint256 flashAmt = token.getBalanceOf(pool);
        if (flashAmt == 0 || IUniswapV3Pool(pool).liquidity() == 0) {
            revert FlashLoanZeroLiquidity(pool);
        }
        flashAmt = flashAmt > amount ? amount : flashAmt;
        (flashAmount0, flashAmount1) = zeroForSaleToken
            ? (flashAmt, uint256(0))
            : (uint256(0), flashAmt);
    }

    function _getUniswapV3Pool(
        address saleToken,
        bytes memory leverageData
    ) private view returns (address pool) {
        (uint24 poolfeeTiers, address secondToken, uint256 dexIndx) = abi.decode(
            leverageData,
            (uint24, address, uint256)
        );
        UniswapV3Identifier memory dex = uniswapV3Dexes[dexIndx];
        require(dex.enabled, "DXE");

        pool = computePoolAddress(
            poolfeeTiers,
            saleToken,
            secondToken,
            dex.factoryV3,
            dex.initCodeHash
        );
    }

    /**
     * @dev Computes the address of a Uniswap V3 pool based on the provided parameters.
     * Not applicable for the zkSync.
     *
     * This function calculates the address of a Uniswap V3 pool contract using the token addresses and fee.
     * It follows the same logic as Uniswap's pool initialization process.
     *
     * @param fee The fee level of the pool.
     * @param tokenA The address of one of the tokens in the pair.
     * @param tokenB The address of the other token in the pair.
     * @param factoryV3 The address of the Uniswap V3 factory contract.
     * @param initCodeHash The hash of the pool initialization code.
     * @return pool The computed address of the Uniswap V3 pool.
     */
    function computePoolAddress(
        uint24 fee,
        address tokenA,
        address tokenB,
        address factoryV3,
        bytes32 initCodeHash
    ) public pure returns (address pool) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factoryV3,
                            keccak256(abi.encode(tokenA, tokenB, fee)),
                            initCodeHash
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../INonfungiblePositionManager.sol";
import "../ILightQuoterV3.sol";

interface ILiquidityManager {
    /**
     * @notice Represents information about a loan.
     * @dev This struct is used to store liquidity and tokenId for a loan.
     * @param liquidity The amount of liquidity for the loan represented by a uint128 value.
     * @param tokenId The token ID associated with the loan represented by a uint256 value.
     */
    struct LoanInfo {
        uint128 liquidity;
        uint256 tokenId;
    }

    struct Amounts {
        uint256 amount0;
        uint256 amount1;
    }

    struct SqrtPriceLimitation {
        uint24 feeTier;
        uint160 sqrtPriceLimitX96;
    }

    /// @dev Struct containing parameters necessary for conducting a flash loan.
    /// @param protocol The identifier of the flash loan protocol (if 0, the flash loan is not used).
    /// @param data Arbitrary data that can be used by the flash loan protocol.
    struct FlashLoanParams {
        uint8 protocol;
        bytes data;
    }

    /// @dev Struct containing parameters for defining restoration routes,
    /// including the use of external swaps, fee tiers for internal swaps, and potential flash loan arrangements.
    /// @param strict  If the flag strict is false, part of the profit or liquidation bonus can be used to close the position.
    /// @param tokenId The ID of the NFT-POS token that needs to be restored, if applicable.
    /// @param flashLoanParams An array of FlashLoanParams structs, detailing each flash loan involved in the route.
    struct FlashLoanRoutes {
        bool strict;
        FlashLoanParams[] flashLoanParams;
    }
    /**
     * @notice Contains parameters for restoring liquidity.
     * @dev This struct is used to store various parameters required for restoring liquidity.
     * @param zeroForSaleToken A boolean value indicating whether the token for sale is the 0th token or not.
     * @param totalfeesOwed The total fees owed represented by a uint256 value.
     * @param totalBorrowedAmount The total borrowed amount represented by a uint256 value.
     * @param routes An array of FlashLoanRoutes structs representing the restoration routes.
     * @param loans An array of LoanInfo structs representing the loans.
     */
    struct RestoreLiquidityParams {
        bool zeroForSaleToken;
        uint256 totalfeesOwed;
        uint256 totalBorrowedAmount;
        FlashLoanRoutes routes;
        LoanInfo[] loans;
    }

    struct CallbackData {
        bool zeroForSaleToken;
        uint24 fee;
        address saleToken;
        address holdToken;
        uint256 holdTokenDebt;
        uint256 vaultBodyDebt;
        uint256 vaultFeeDebt;
        Amounts amounts;
        LoanInfo loan;
        FlashLoanRoutes routes;
    }
    /**
     * @title NFT Position Cache Data Structure
     * @notice This struct holds the cache data necessary for restoring liquidity to an NFT position.
     * @dev Stores essential parameters for an NFT representing a position in a Uniswap-like pool.
     * @param tickLower The lower bound of the liquidity position's price range, represented as an int24.
     * @param tickUpper The upper bound of the liquidity position's price range, represented as an int24.
     * @param fee The fee tier of the Uniswap pool in which this liquidity will be restored, represented as a uint24.
     * @param liquidity The amount of NFT Position liquidity.
     * @param saleToken The ERC-20 sale token.
     * @param holdToken The ERC-20 hold token.
     * @param operator The address of the operator who is permitted to restore liquidity and manage this position.
     * @param holdTokenDebt The outstanding debt of the hold token that needs to be repaid when liquidity is restored, represented as a uint256.
     */
    struct NftPositionCache {
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
        uint128 liquidity;
        address saleToken;
        address holdToken;
        address operator;
        uint256 holdTokenDebt;
    }

    function VAULT_ADDRESS() external view returns (address);

    function underlyingPositionManager() external view returns (INonfungiblePositionManager);

    function lightQuoterV3Address() external view returns (address);

    function flashLoanAggregatorAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanAggregator {
    function flashLoan(uint256 amount, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Light Quoter Interface
interface ILightQuoterV3 {
    /// @title Struct for "Zap In" Calculation Parameters
    /// @notice This struct encapsulates the various parameters required for calculating the exact amount of tokens to zap in.
    struct CalculateExactZapInParams {
        /// @notice The address of the swap pool where liquidity will be added.
        address swapPool;
        /// @notice A boolean determining which token will be used to add liquidity (true for token0 or false for token1).
        bool zeroForIn;
        /// @notice The lower bound of the tick range for the position within the pool.
        int24 tickLower;
        /// @notice The upper bound of the tick range for the position within the pool.
        int24 tickUpper;
        /// @notice The exact amount of liquidity to add to the pool.
        uint128 liquidityExactAmount;
        /// @notice The balance of the token that will be used to add liquidity.
        uint256 tokenInBalance;
        /// @notice The balance of the other token in the pool, not typically used for adding liquidity directly but necessary for calculations.
        uint256 tokenOutBalance;
    }

    /// @notice Calculates parameters related to "zapping in" to a position with an exact amount of liquidity.
    /// @dev Interacts with an on-chain liquidity pool to precisely estimate the amounts in/out to add liquidity.
    ///      This calculation is performed using iterative methods to ensure the exactness of the resulting values.
    ///      It uses the `getSqrtRatioAtTick` method within the loop to determine price bounds.
    ///      This process is designed to avoid failure due to constraints such as limited input or other conditions.
    ///      The number of iterations to reach an accurate result is bounded by a maximum value.
    /// @param params A `CalculateExactZapInParams` struct containing all necessary parameters to perform the calculations.
    ///               This may include details about the liquidity pool, desired position, slippage tolerance, etc.
    /// @return swapAmountIn The exact total amount of input tokens required to complete the zap in operation.
    /// @return amount0 The exact amount of the token0 will be used for "zapping in" to a position.
    /// @return amount1 The exact amount of the token1 will be used for "zapping in" to a position.
    function calculateExactZapIn(
        CalculateExactZapInParams memory params
    ) external view returns (uint256 swapAmountIn, uint256 amount0, uint256 amount1);

    /**
     * @notice Quotes the output amount for a given input amount in a single token swap operation on Uniswap V3.
     * @dev This function simulates the swap and returns the estimated output amount. It does not execute the trade itself.
     * @param zeroForIn A boolean indicating the direction of the swap:
     * true for swapping the 0th token (token0) to the 1st token (token1), false for token1 to token0.
     * @param swapPool The address of the Uniswap V3 pool contract through which the swap will be simulated.
     * @param amountIn The amount of input tokens that one would like to swap.
     * @return sqrtPriceX96After The square root of the price after the swap, scaled by 2^96. This is the price between the two tokens in the pool post-simulation.
     * @return amountOut The amount of output tokens that can be expected to receive in the swap based on the current state of the pool.
     */
    function quoteExactInputSingle(
        bool zeroForIn,
        address swapPool,
        uint256 amountIn
    ) external view returns (uint160 sqrtPriceX96After, uint256 amountOut);

    /**
     * @notice Quotes the amount of input tokens required to arrive at a specified output token amount for a single pool swap.
     * @dev This function performs a read-only operation to compute the necessary input amount and does not execute an actual swap.
     *      It is useful for obtaining quotes prior to performing transactions.
     * @param zeroForIn A boolean that indicates the direction of the trade, true if swapping zero for in-token, false otherwise.
     * @param swapPool The address of the swap pool contract where the trade will take place.
     * @param amountOut The desired amount of output tokens.
     * @return sqrtPriceX96After The square root price (encoded as a 96-bit fixed point number) after the swap would occur.
     * @return amountIn The amount of input tokens required for the swap to achieve the desired `amountOut`.
     */
    function quoteExactOutputSingle(
        bool zeroForIn,
        address swapPool,
        uint256 amountOut
    ) external view returns (uint160 sqrtPriceX96After, uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

interface INonfungiblePositionManager {
    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /**
     * @notice from IERC721
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWagmiLeverageFlashCallback {
    function wagmiLeverageFlashCallback(
        uint256 bodyAmt,
        uint256 feeAmt,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
// https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity 0.8.23;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "W-STF");
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "W-ST");
    }

    function getBalance(address token) internal view returns (uint256 balance) {
        bytes memory callData = abi.encodeWithSelector(IERC20.balanceOf.selector, address(this));
        (bool success, bytes memory data) = token.staticcall(callData);
        require(success && data.length >= 32);
        balance = abi.decode(data, (uint256));
    }

    function getBalanceOf(address token, address target) internal view returns (uint256 balance) {
        bytes memory callData = abi.encodeWithSelector(IERC20.balanceOf.selector, target);
        (bool success, bytes memory data) = token.staticcall(callData);
        require(success && data.length >= 32);
        balance = abi.decode(data, (uint256));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0 = a * b; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the preconditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}