// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {
    AddressNotContract,
    InvalidInitiator,
    PoolMismatch,
    OnlyLendingPool,
    OnlyLiquidityPool,
    RequesterNotMSA,
    TokensAndAmountsLengthMismatch,
    WrongFlashloanRequester
} from "src/Errors.sol";
import {MassSmartAccount} from "src/MassSmartAccount.sol";
import {SmartAccountOwnerResolver} from "src/SmartAccountOwnerResolver.sol";
import {IAaveLending} from "src/interfaces/external/IAaveLending.sol";
import {IPoolAddressesProviderV3} from "src/interfaces/external/IPoolAddressesProviderV3.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

/// @title FlashloanerMSA
/// @notice FlashloanerMSA for Aave V3 and UniswapV3
/// @dev This contract is used by MassSmartAccounts to execute flashloans.
///      It allows to be flexible in the params validation and the execution
///      of flashloans. No funds are kept in this contract. All the funds are
///      transferred to the requester and then pulled back with fees to repay the
///      flashloan.
contract FlashloanerMSA is ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev This code hash was not updated in the UniswapV3 library branch 0.8 leading to
    ///     a different address than the one computed by the UniswapV3 factory.
    ///     This helper is needed to compute the correct address.
    bytes32 internal constant POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /* -------------------------------------------------------------------------- */
    /*                                 IMMUTABLES                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice The address of the SmartAccountOwnerResolver
    SmartAccountOwnerResolver public immutable smartAccountOwnerResolver;

    /// @notice The address of the Aave PoolAddressesProvider​
    IPoolAddressesProviderV3 public immutable aavePoolAddressesProvider;

    /// @notice The address of the UniswapV3 factory
    address public immutable uniswapFactoryV3;

    /* -------------------------------------------------------------------------- */
    /*                                   STRUCTS                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Struct to store the data needed to execute an Aave flashloan
    ///         callback.
    /// @dev This struct is necessary to avoid stack too deep errors
    ///      when calling executeOperation.
    /// @param lendingPool The address of the Aave lending pool
    /// @param requester The address of the MassSmartAccount that requested the flashloan
    /// @param data The byte-encoded params passed when initiating the flashloan
    struct AaveExecutionData {
        address lendingPool;
        address requester;
        bytes data;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        SmartAccountOwnerResolver smartAccountOwnerResolver_,
        address aavePoolAddressesProvider_,
        address uniswapFactoryV3_
    ) ReentrancyGuard() {
        if (address(smartAccountOwnerResolver_).code.length == 0) {
            revert AddressNotContract(address(smartAccountOwnerResolver_));
        }
        if (address(aavePoolAddressesProvider_).code.length == 0) {
            revert AddressNotContract(address(aavePoolAddressesProvider_));
        }
        if (address(uniswapFactoryV3_).code.length == 0) {
            revert AddressNotContract(address(uniswapFactoryV3_));
        }
        smartAccountOwnerResolver = smartAccountOwnerResolver_;
        uniswapFactoryV3 = uniswapFactoryV3_;
        aavePoolAddressesProvider = IPoolAddressesProviderV3(aavePoolAddressesProvider_);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 FLASHLOANS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Flashloan function for Aave V3
    /// @dev data is encoded as follows:
    ///      data = abi.encode(requester, requesterData)
    /// @param tokens The addresses of the flash-borrowed assets
    /// @param amounts The amounts of the flash-borrowed assets
    /// @param data The byte-encoded params passed when initiating the flashloan
    function flashloanAaveV3(
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata data
    ) external nonReentrant {
        uint256 totalTokens = tokens.length;
        if (totalTokens != amounts.length) revert TokensAndAmountsLengthMismatch();
        // Ensure msg.sender is a MassSmartAccount
        if (smartAccountOwnerResolver.ownerOf(msg.sender) == address(0)) revert RequesterNotMSA();
        // Ensure the msg.sender will be the one to receive the funds from the flashloan
        (address requester,) = abi.decode(data, (address, bytes));
        if (requester != msg.sender) revert WrongFlashloanRequester(requester);

        // no debt
        uint256[] memory modes = new uint256[](totalTokens);
        for (uint256 i; i < totalTokens; i++) {
            modes[i] = 0;
        }

        IAaveLending(aavePoolAddressesProvider.getPool()).flashLoan(
            address(this),
            tokens,
            amounts,
            modes,
            msg.sender, // onBehalfOf
            data,
            0
        );
    }

    /// @notice Flashloan function for Uniswap V3
    /// @dev data is encoded as follows:
    ///      data = abi.encode([tokens, amounts, PoolKey, requester, requesterData])
    /// @param amounts The amounts of the flash-borrowed assets
    /// @param liquidityPool The address of the liquidity pool
    /// @param data The byte-encoded params passed when initiating the flashloan
    function flashloanUniswapV3(
        uint256[] calldata amounts,
        address liquidityPool,
        bytes calldata data
    ) external nonReentrant {
        if (amounts.length != 2) revert TokensAndAmountsLengthMismatch();
        // Ensure msg.sender is a MassSmartAccount
        if (smartAccountOwnerResolver.ownerOf(msg.sender) == address(0)) revert RequesterNotMSA();
        (,, PoolKey memory key, address requester,) =
            abi.decode(data, (address[], uint256[], PoolKey, address, bytes));
        // Ensure the msg.sender will be the one to receive the funds from the flashloan
        if (requester != msg.sender) revert WrongFlashloanRequester(requester);
        if (liquidityPool != _computeAddressUniswapPool(uniswapFactoryV3, key)) {
            revert PoolMismatch();
        }

        IUniswapV3Pool(liquidityPool).flash(address(this), amounts[0], amounts[1], data);
    }

    /* -------------------------------------------------------------------------- */
    /*                                  CALLBACKS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Flashloan callback for Aave V3
    /// @dev data is encoded as follows:
    ///      data = abi.encode(requester, requesterData)
    /// @param assets The addresses of the flash-borrowed assets
    /// @param amounts The amounts of the flash-borrowed assets
    /// @param premiums The fee of each flash-borrowed asset
    /// @param initiator The address of the flashloan initiator
    /// @param params The byte-encoded params passed when initiating the flashloan
    /// @return True if the execution of the operation succeeds
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        if (initiator != address(this)) revert InvalidInitiator(initiator);
        AaveExecutionData memory executionData;
        executionData.lendingPool = aavePoolAddressesProvider.getPool();
        if (msg.sender != executionData.lendingPool) revert OnlyLendingPool();

        (executionData.requester, executionData.data) = abi.decode(params, (address, bytes));
        if (smartAccountOwnerResolver.ownerOf(executionData.requester) == address(0)) {
            revert RequesterNotMSA();
        }

        // Transfer assets to requester
        for (uint256 i; i < assets.length; i++) {
            IERC20(assets[i]).safeTransfer(executionData.requester, amounts[i]);
        }

        // Call the MassSmartAccount to execute the requester data
        MassSmartAccount(payable(executionData.requester)).executeHyVMCallFromReentrant(
            executionData.data, abi.encode(assets, amounts, premiums)
        );

        _pullFromAndApprove(
            executionData.requester, executionData.lendingPool, assets, amounts, premiums
        );

        return true;
    }

    /// @notice Flashloan callback for Uniswap V3
    /// @dev data is encoded as follows:
    ///      data = abi.encode([tokens, amounts, PoolKey, requester, requesterData])
    /// @param fee0 The fee of the first token
    /// @param fee1 The fee of the second token
    /// @param data The byte-encoded params passed when initiating the flashloan
    function uniswapV3FlashCallback(uint256 fee0, uint256 fee1, bytes calldata data) external {
        (
            address[] memory tokens,
            uint256[] memory amounts,
            PoolKey memory key,
            address requester,
            bytes memory requesterData
        ) = abi.decode(data, (address[], uint256[], PoolKey, address, bytes));

        // Ensure requester is a MassSmartAccount
        if (smartAccountOwnerResolver.ownerOf(requester) == address(0)) revert RequesterNotMSA();
        // Ensure msg.sender is a valid uniswapV3 pool
        if (msg.sender != _computeAddressUniswapPool(uniswapFactoryV3, key)) {
            revert OnlyLiquidityPool();
        }

        // Transfer tokens to requester
        for (uint256 i; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(requester, amounts[i]);
        }

        uint256[] memory fees = new uint256[](2);
        fees[0] = fee0;
        fees[1] = fee1;

        // Call the MassSmartAccount to execute the requester data
        MassSmartAccount(payable(requester)).executeHyVMCallFromReentrant(
            requesterData, abi.encode(tokens, amounts, fees)
        );

        _pullFromAndSendTo(requester, msg.sender, tokens, amounts, fees);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Pull funds from an address and approve spender
    /// @param from The address to pull funds from
    /// @param spender The address to approve the funds to
    /// @param tokens The addresses of the flash-borrowed tokens
    /// @param amounts The amounts of the flash-borrowed tokens
    /// @param fees The fee of each flash-borrowed tokens
    function _pullFromAndApprove(
        address from,
        address spender,
        address[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees
    ) internal {
        uint256 totalTokens = tokens.length;
        for (uint256 i; i < totalTokens; i++) {
            uint256 totalToPull = amounts[i] + fees[i];
            IERC20(tokens[i]).safeTransferFrom(from, address(this), totalToPull);
            IERC20(tokens[i]).forceApprove(spender, totalToPull);
        }
    }

    /// @dev Pull funds from an address and send funds to an address
    /// @param from The address to pull funds from
    /// @param to The address to send the funds to
    /// @param tokens The addresses of the flash-borrowed tokens
    /// @param amounts The amounts of the flash-borrowed tokens
    /// @param fees The fee of each flash-borrowed tokens
    function _pullFromAndSendTo(
        address from,
        address to,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory fees
    ) internal {
        uint256 totalTokens = tokens.length;
        for (uint256 i; i < totalTokens; i++) {
            uint256 totalToPull = amounts[i] + fees[i];
            if (totalToPull > 0) {
                IERC20(tokens[i]).safeTransferFrom(from, address(this), totalToPull);
                IERC20(tokens[i]).safeTransfer(to, totalToPull);
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                             HELPERS UNISWAP V3                             */
    /* -------------------------------------------------------------------------- */

    /// @dev The identifying key of the uniswapV3 pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @dev Compute the address of the UniswapV3 pool
    /// @param factory The address of the UniswapV3 factory
    /// @param key The pool key
    /// @return pool The address of the UniswapV3 pool
    function _computeAddressUniswapPool(address factory, PoolKey memory key)
        internal
        pure
        returns (address pool)
    {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

error AddressNotContract(address notContract);

error AlreadyInitialized();

error CannotInitializeImpl();

error CannotRecreateSmartAccount(address massSmartAccount);

error EmptyByteCode();

error Expired();

error FailedDeployment();

error InvalidMerkleProof();

error InvalidMerkleRoot(bytes32 root);

error InvalidInitiator(address notInitiator);

error PoolMismatch();

error OwnerAlreadySet();

error OnlySelfCall();

error OnlySmartAccountFactory(address);

error InvalidReentrantData();

error InvalidValue();

error InvalidNonce();

error OnlyLendingPool();

error OnlyLiquidityPool();

error Reentrancy();

error SenderNotInitializer(address sender);

error RequesterNotMSA();

error SenderNotSmartAccountOwner(address sender);

error SenderNotSmartAccountOwnerOrMSAItself(address sender);

error SenderNotWeth(address sender);

error TransactionAlreadyProcessed(bytes32 txDataHash);

error TokensAndAmountsLengthMismatch();

error WrongFlashloanRequester(address requester);

error WrongSigner(address signer);

error WrongImplementation(address implementation);

error ZeroAddress();

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ERC721Holder} from "openzeppelin/token/ERC721/utils/ERC721Holder.sol";
import {ERC1155Holder} from "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {ERC2771Context} from "openzeppelin/metatx/ERC2771Context.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {IWETH} from "src/interfaces/external/IWETH.sol";
import {IMassSmartAccount} from "src/interfaces/IMassSmartAccount.sol";
import {SmartAccountOwnerResolver} from "src/SmartAccountOwnerResolver.sol";
import {WithdrawerWeth} from "src/WithdrawerWeth.sol";
import {
    AddressNotContract,
    AlreadyInitialized,
    CannotInitializeImpl,
    Expired,
    InvalidMerkleProof,
    InvalidNonce,
    InvalidReentrantData,
    InvalidValue,
    InvalidMerkleRoot,
    OnlySelfCall,
    SenderNotInitializer,
    SenderNotSmartAccountOwner,
    TransactionAlreadyProcessed,
    WrongSigner
} from "src/Errors.sol";

/// @author MassMoney
/// @notice Mass smart account.
/// @dev The smart account is upgradeable, this is the implementation.
///      See the proxy contract (`./src/Proxy.huff`).
/// @custom:version V1
contract MassSmartAccount is IMassSmartAccount, ERC2771Context, ERC1155Holder, ERC721Holder {
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Implementation version.
    string public constant VERSION = "V1";

    /// @notice EIP712 domain separator typehash.
    bytes32 public constant DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /// @notice Transaction typehash for EIP712 signature.
    bytes32 public constant TX_TYPEHASH =
        keccak256("Tx(address to,bytes payload,uint256 value,uint256 expiration,uint256 nonce)");

    /// @notice Merkle tree root typehash for EIP712 signature.
    bytes32 public constant MERKLE_TREE_ROOT_TYPEHASH = keccak256("MerkleTreeRoot(bytes32 root)");

    /* -------------------------------------------------------------------------- */
    /*                                  IMMUTABLE                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice HyVM contract address.
    /// @dev HyVM is an Ethereum Virtual Machine (EVM) Hypervisor, allowing the
    ///      execution of arbitrary EVM Bytecode. See https://github.com/MassMoney/HyVM.
    address public immutable hyvm;

    /// @notice smartAccountOwnerResolver proxy contract address to retrieve the owner.
    SmartAccountOwnerResolver public immutable smartAccountOwnerResolver;

    /// @notice smartAccountFactory initialize weth address.
    address public immutable smartAccountFactory;

    /// @notice The implementation address.
    address private immutable _self;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Flag to check if the proxy is initialized.
    bool public initialized;

    /// @notice Wrapped native token contract.
    IWETH public weth;

    /// @notice Withdrawer contract.
    WithdrawerWeth public withdrawer;

    /// @notice Nonce for transaction through EIP712 signature.
    uint256 public nonce;

    // @notice Flag to check if the ERC2771 feature is activated.
    bool public isERC2771Activated;

    /// @notice Mapping of transaction bundled to avoid replay
    ///         Either it was revoked or executed.
    mapping(bytes32 => mapping(bytes32 => bool)) public bundledTransactionProcessed;

    /// @notice Mapping of revoked merkle tree roots.
    mapping(bytes32 => bool) public revokedMerkleRoot;

    /// @notice Flag to authorize reentrancy data to be executed.
    /// @dev    Equals to keccak256(dataToBeExecuted). Can only be set by
    //          the function performReetrantCall. Must be set to 0 after the
    ///         reentrancy data is executed.
    bytes32 private _authorizedReentrancyHash;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when the nonce is set.
    /// @param nonce The nonce.
    event NonceSet(uint256 nonce);

    /// @dev Emitted when the ERC2771 is activated.
    event ERC2771Activated();

    /// @dev Emitted when the ERC2771 is deactivated.
    event ERC2771Deactivated();

    /// @dev Emitted when a transaction is processed.
    /// @param root The merkle root.
    /// @param txHash The transaction hash.
    event TransactionProcessed(bytes32 root, bytes32 txHash);

    /// @dev Emitted when a merkle root is revoked.
    /// @param root The merkle root.
    event MerkleRootRevoked(bytes32 root);

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(
        address _forwarder,
        address _hyvm,
        address _smartAccountOwnerResolver,
        address _smartAccountFactory
    ) ERC2771Context(_forwarder) {
        if (_hyvm.code.length == 0) revert AddressNotContract(_hyvm);
        if (_smartAccountOwnerResolver.code.length == 0) {
            revert AddressNotContract(_smartAccountOwnerResolver);
        }
        if (_smartAccountFactory.code.length == 0) revert AddressNotContract(_smartAccountFactory);
        hyvm = _hyvm;
        _self = address(this);
        smartAccountOwnerResolver = SmartAccountOwnerResolver(_smartAccountOwnerResolver);
        smartAccountFactory = _smartAccountFactory;
    }

    /* -------------------------------------------------------------------------- */
    /*                                  MODIFIERS                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Check that the message sender is the owner of the MassSmartAccount.
    modifier onlySmartAccountOwner() {
        address sender = _sender();
        // The sender must be the smart account owner
        if (smartAccountOwner() != sender) revert SenderNotSmartAccountOwner(sender);
        _;
    }

    /// @dev Check that the message sender is the owner of the MassSmartAccount
    ///     or the MassSmartAccount itself.
    ///     This modifier is only used for the activation of the ERC2771 feature.
    ///     Allows to activate the feature through the HyVM.
    modifier onlySmartAccountOwnerOrSelf() {
        address sender = _sender();
        // The sender must be the smart account owner or the MSA itself
        if (!(smartAccountOwner() == sender || address(this) == msg.sender)) {
            revert SenderNotSmartAccountOwner(sender);
        }
        _;
    }

    /// @dev Sender of the call depending on the ERC2771 feature.
    /// @return The sender of the call.
    function _sender() internal returns (address) {
        return isERC2771Activated ? ERC2771Context._msgSender() : msg.sender;
    }

    /* -------------------------------------------------------------------------- */
    /*                          INITIALIZE WITHDRAWERWETH                         */
    /* -------------------------------------------------------------------------- */

    /// @notice Initialize the WithdrawerWeth and Weth contracts.
    /// @dev This function can only be called once. It is called by the
    ///      SmartAccountFactory when creating the smart account. It is not possible to
    ///      change contracts addresses once it is set.
    ///      This function is necessary to avoid having to pass addresses in the
    ///      constructor, which would make the deployment dependant on the
    ///      wrapped native token address. It would lead to different deployed
    ///      addresses on different chains.
    ///      WithdrawerWeth is necessary to avoid hitting gas limit from
    ///      transfer when withdrawing ETH from WETH9.
    /// @param weth_ The wrapped native token address.
    /// @param withdrawer_ The withdrawer contract address.
    function initializeWithdrawerWeth(address weth_, address withdrawer_) external {
        if (initialized) revert AlreadyInitialized();
        if (address(this) == _self) revert CannotInitializeImpl();
        if (msg.sender != smartAccountFactory) revert SenderNotInitializer(msg.sender);
        if (weth_.code.length == 0) revert AddressNotContract(weth_);
        if (withdrawer_.code.length == 0) revert AddressNotContract(withdrawer_);
        initialized = true;
        weth = IWETH(weth_);
        withdrawer = WithdrawerWeth(payable(withdrawer_));
    }

    /* -------------------------------------------------------------------------- */
    /*                                   RECEIVE                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Wraps received ETH to WETH, unless it comes from the withdrawer.
    ///      In case the owner wants to withdraw ETH from the smart account, he
    ///      will need to call the withdrawer and send the funds in the same
    ///      transaction. Any ETH in this contract can be wrapped by anyone by
    ///      calling the contract without value and data.
    receive() external payable {
        if (msg.sender != address(withdrawer)) {
            _wrapNativeToken();
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                               EXECUTION LOGIC                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a Call to a contract.
    /// @param call A Call to execute.
    /// @return data The returned data from the underlying call.
    function executeCall(Call calldata call)
        external
        payable
        override
        onlySmartAccountOwner
        returns (bytes memory data)
    {
        return Address.functionCallWithValue(call.target, call.payload, call.value);
    }

    /// @notice Execute a delegatecall to the HyVM.
    /// @dev This function is a shortcut to save gas, since the HyVM address
    ///      is immutable.
    ///      Any ETH sent to this function will be wrapped to WETH to avoid having
    ///      ETH in the smart account in case it is not used in the delegatecall.
    /// @param bytecode The data to delegatecall the HyVM.
    /// @return data The returned data from the underlying HyVM call.
    function executeHyVMCall(bytes calldata bytecode)
        external
        payable
        override
        onlySmartAccountOwner
        returns (bytes memory data)
    {
        _wrapNativeToken();
        data = Address.functionDelegateCall(hyvm, bytecode);
    }

    /* -------------------------------------------------------------------------- */
    /*                                ERC2771 LOGIC                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Activate the ERC2771 feature.
    /// @dev Only the smart account owner or the smart account itself can activate
    ///      the feature. The function is public to allow the SDK to activate the
    ///      feature through the HyVM in delegatecall.
    function activateERC2771() public override onlySmartAccountOwnerOrSelf {
        isERC2771Activated = true;
        emit ERC2771Activated();
    }

    /// @notice Deactivate the ERC2771 feature.
    function deactivateERC2771() external override onlySmartAccountOwner {
        isERC2771Activated = false;
        emit ERC2771Deactivated();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   ERC1271                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Should return whether the signature provided is valid for the
    ///         provided hashed data.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with data.
    /// @return Function selector of the function or bytes4(0).
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        override
        returns (bytes4)
    {
        return ECDSA.recover(hash, signature) == smartAccountOwner()
            ? this.isValidSignature.selector
            : bytes4(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                              EIP712 EXECUTION                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute a transaction through an EIP712 signature.
    /// @dev If the target is the HyVM, any ETH sent to this function will be
    ///      wrapped to WETH to avoid having ETH in the smart account in case it
    ///      is not used in the delegatecall.
    /// @param to The target address.
    /// @param payload The payload to send.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param n The nonce.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeSignature712(
        address to,
        bytes memory payload,
        uint256 value,
        uint256 expiration,
        uint256 n,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable override returns (bytes memory returnData) {
        _checkTxSignature712(to, payload, value, expiration, n, v, r, s);

        // Check expiration
        if (expiration < block.timestamp) revert Expired();

        // Check msg.value
        if (value != msg.value) revert InvalidValue();

        // Check nonce
        if (n != nonce) revert InvalidNonce();

        _setNonce(n + 1);

        returnData = _execute(to, payload, value);
    }

    /// @dev Check the signature of a transaction following the Tx structure.
    /// @param to The target address.
    /// @param payload The payload to send.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param n The nonce.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    function _checkTxSignature712(
        address to,
        bytes memory payload,
        uint256 value,
        uint256 expiration,
        uint256 n,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view {
        bytes32 hashStruct =
            keccak256(abi.encode(TX_TYPEHASH, to, keccak256(payload), value, expiration, n));
        _checkSignature712(hashStruct, v, r, s);
    }

    /// @notice Increment the nonce.
    /// @dev Only the owner can execute this function. It allows to cancel a
    ///      signature.
    function incrementNonce() external onlySmartAccountOwner {
        _setNonce(nonce + 1);
    }

    /// @dev Set the nonce.
    /// @param _nonce The nonce to set.
    function _setNonce(uint256 _nonce) internal {
        emit NonceSet(_nonce);
        nonce = _nonce;
    }

    /* -------------------------------------------------------------------------- */
    /*                            BUNDLED TRANSACTIONS                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Execute one of the transactions through the HyVM in a merkle tree which root was signed
    ///         by EIP712 signature.
    /// @dev Any ETH sent to this function will be wrapped to WETH to avoid having ETH in the
    ///      smart account in case it is not used in the delegatecall as the target is the HyVM.
    ///      Dynamic payload is appended to the signed payload when needed (e.g. pyth data).
    ///      Use cases of this function: TP and SL orders in the same bundle or creating multiple
    ///      limit orders in the same bundle.
    ///      It allows to require only one signature for multiple transactions from a user.
    ///      Merkle trees should be created with the Merkle tree OZ library.
    ///      https://github.com/OpenZeppelin/merkle-tree
    ///
    ///      !!! No jump should be done from the reentrantData to the dynamic data.
    ///          Only calldataload should be used to read the dynamic data else it
    ///          could lead to malicious data being executed.
    ///          By using the SDK, this issue will be avoided as it will ensure
    ///          only read of dynamic data will be done. !!!
    ///
    ///      !!! A particular attention is needed to be sure about what is signed as order
    ///          of transactions execution could have an impact. It is also the responsibility of the
    ///          user / SDK to check there are no 2 transactions with the same data in one merkle tree
    ///          else the second one will be rejected !!!
    ///
    /// @param root Merkle root of the tree that contains all signed transactions.
    /// @param proof Merkle proof of the transaction to execute.
    /// @param txPayload The transaction payload included in the merkle tree.
    /// @param dynamicPayload Dynamic payload to append to the txPayload.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeTransactionFromBundleSignature(
        bytes32 root,
        bytes32[] calldata proof,
        bytes memory txPayload,
        bytes memory dynamicPayload,
        uint256 value,
        uint256 expiration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData) {
        bytes32 txHash = _checkBundleSignatureAndTransactionInclusion(
            root, proof, txPayload, value, expiration, v, r, s
        );

        // Check expiration
        if (expiration < block.timestamp) revert Expired();

        // Check msg.value
        if (value != msg.value) revert InvalidValue();

        // Concat dynamic payload if necessary
        bytes memory payload = txPayload;
        if (dynamicPayload.length > 0) {
            payload = bytes.concat(txPayload, hex"00", dynamicPayload);
        }

        // Execute call
        returnData = _execute(hyvm, payload, value);

        emit TransactionProcessed(root, txHash);
    }

    /// @notice Revoke a transaction bundled in a merkle tree EIP712 execution bundle.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root of the tree.
    /// @param bundledTransaction The transaction to revoke.
    function revokeBundledTransactionExecution(bytes32 root, bytes32 bundledTransaction)
        external
        onlySmartAccountOwner
    {
        bundledTransactionProcessed[root][bundledTransaction] = true;
        emit TransactionProcessed(root, bundledTransaction);
    }

    /// @notice Revoke a merkle tree root. All transactions bundled in this merkle tree
    ///         will be revoked.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root to revoke.
    function revokeMerkleRootBundledTransactions(bytes32 root) external onlySmartAccountOwner {
        revokedMerkleRoot[root] = true;
        emit MerkleRootRevoked(root);
    }

    /// @notice Check the signature of the merkle tree root and the transaction inclusion in the merkle tree.
    /// @dev This function is used by executeTransactionFromBundleSignature.
    /// @param root Merkle root of the tree that contains all signed transactions.
    /// @param proof Merkle proof of the transaction to execute.
    /// @param payload The transaction payload included in the merkle tree.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    function _checkBundleSignatureAndTransactionInclusion(
        bytes32 root,
        bytes32[] calldata proof,
        bytes memory payload,
        uint256 value,
        uint256 expiration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal returns (bytes32) {
        if (revokedMerkleRoot[root]) revert InvalidMerkleRoot(root);
        // Merkle tree OZ library requires double hashing of leafs
        // Check if the transaction is already in status processed
        // !!! it is the responsibility of the user / SDK to check there are no
        // 2 transactions with the same data in the same merkle tree else the second
        // one will be rejected !!!
        bytes32 txHash = keccak256(bytes.concat(keccak256(abi.encode(payload, value, expiration))));
        if (bundledTransactionProcessed[root][txHash]) {
            revert TransactionAlreadyProcessed(txHash);
        }

        // Check signature of the merkle tree root
        bytes32 hashStruct = keccak256(abi.encode(MERKLE_TREE_ROOT_TYPEHASH, root));
        _checkSignature712(hashStruct, v, r, s);

        // Check merkle proof
        if (!MerkleProof.verifyCalldata(proof, root, txHash)) revert InvalidMerkleProof();

        bundledTransactionProcessed[root][txHash] = true;

        return txHash;
    }

    /* -------------------------------------------------------------------------- */
    /*                             AUTHORIZED REENTRANCY                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Perform external call to a contract with authorization
    ///         to reenter with validated data.
    /// @dev Only callable by the MSA itself.
    /// @param to The target address.
    /// @param value The value to send.
    /// @param toData The data to send.
    /// @param authorizedReentrancyHash_ Hash of the authorized data to reenter.
    /// @return returnedData The returned data from the underlying call.
    function performReentrantCall(
        address to,
        uint256 value,
        bytes calldata toData,
        bytes32 authorizedReentrancyHash_
    ) public payable returns (bytes memory) {
        if (msg.sender != address(this)) revert OnlySelfCall();
        if (authorizedReentrancyHash_ == bytes32(0)) revert InvalidReentrantData();
        _authorizedReentrancyHash = authorizedReentrancyHash_;
        bytes memory returnedData = Address.functionCallWithValue(to, toData, value);
        if (_authorizedReentrancyHash != bytes32(0)) revert InvalidReentrantData();
        return returnedData;
    }

    /// @notice Execute a delegatecall to the HyVM from a reentrant call.
    /// @dev The reentrant data was previously authorized in the `performReetrantCall`
    ///      by the smart account owner. New data will be appended after the authorized data.
    ///      This new data will only be executed according to the authorized data instructions.
    ///      A stop instruction will separate the authorized data from the new data to avoid
    ///      executing the new data by mistake by the HyVM.
    ///
    ///      !!! No jump should be done from the reentrantData to the dynamic data.
    ///          Only calldataload should be used to read the dynamic data else it
    ///          could lead to malicious data being executed.
    ///          By using the SDK, this issue will be avoided as the SDK will add checks. !!!
    ///
    /// @param reentrantData The reentrant data authorized by the user.
    /// @param nonValidatedData The non validated data.
    /// @return The returned data from the underlying HyVM call.
    function executeHyVMCallFromReentrant(
        bytes calldata reentrantData,
        bytes calldata nonValidatedData
    ) external payable returns (bytes memory) {
        // Ensure the reentrantData is authorized to be executed
        if (_authorizedReentrancyHash != keccak256(reentrantData)) revert InvalidReentrantData();
        _authorizedReentrancyHash = bytes32(0);

        // Concatenate the reentrant data with the non validated data
        // Add a stop instruction between the reentrant data and the non validated data
        // to ensure the non validated data is executed by the HyVM only explicitly
        bytes memory hyvmData = bytes.concat(reentrantData, hex"00", nonValidatedData);
        _wrapNativeToken();
        return Address.functionDelegateCall(hyvm, hyvmData);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    UTILS                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Return the owner of the current Mass Smart Account.
    /// @return Address of the owner.
    function smartAccountOwner() public view returns (address) {
        return smartAccountOwnerResolver.ownerOf(address(this));
    }

    /* -------------------------------------------------------------------------- */
    /*                                COMMON LOGIC                                */
    /* -------------------------------------------------------------------------- */

    /// @dev Smart Accounts are designed not to hold any ETH. All payable functions
    ///      will automatically wrap any received ETH to WETH.
    function _wrapNativeToken() private {
        if (address(this).balance != 0) {
            weth.deposit{value: address(this).balance}();
        }
    }

    /// @notice Execute a call
    /// @param to The target address.
    /// @param data The data to execute.
    /// @param value The value to send.
    /// @return returnData The returned data from the underlying call.
    function _execute(address to, bytes memory data, uint256 value)
        internal
        returns (bytes memory returnData)
    {
        if (to == hyvm) {
            _wrapNativeToken();
            returnData = Address.functionDelegateCall(to, data);
        } else {
            returnData = Address.functionCallWithValue(to, data, value);
        }
    }

    /// @dev Check an EIP712 signature.
    ///      ECDSA from OZ prevents malleability.
    /// @param hashStruct The hash of the struct signed.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    function _checkSignature712(bytes32 hashStruct, uint8 v, bytes32 r, bytes32 s) internal view {
        bytes32 h = ECDSA.toTypedDataHash(buildDomainSeparator(), hashStruct);
        // Will throw if the signature is invalid
        address signer = ECDSA.recover(h, v, r, s);

        // Signature must be from the owner
        if (signer != smartAccountOwner()) revert WrongSigner(signer);
    }

    /// @notice Build the domain separator for an EIP712 signature.
    /// @return The domain separator.
    function buildDomainSeparator() public view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes("MassSmartAccount")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ISmartAccountOwnerResolver} from "src/interfaces/ISmartAccountOwnerResolver.sol";
import {SmartAccountFactory} from "src/SmartAccountFactory.sol";
import {
    AddressNotContract,
    OwnerAlreadySet,
    OnlySmartAccountFactory,
    ZeroAddress
} from "src/Errors.sol";

/// @author MassMoney
/// @notice Stores owner of Mass Smart Accounts
/// @dev Update of owner can only be done by the SmartAccountFactory.
contract SmartAccountOwnerResolver is ISmartAccountOwnerResolver {
    /// @notice SmartAccountFactory proxy contract address
    address public immutable smartAccountFactory;

    /// @notice Smart Account address to owner.
    mapping(address => address) public override ownerOf;

    /// @notice Emitted when the owner of a Mass Smart Account is updated.
    event OwnerUpdated(address indexed massSmartAccount, address indexed owner);

    constructor(address _smartAccountFactory) {
        if (_smartAccountFactory.code.length == 0) revert AddressNotContract(_smartAccountFactory);
        smartAccountFactory = _smartAccountFactory;
    }

    /// @notice Modifier to check if the caller is the SmartAccountFactory
    modifier onlySmartAccountFactory() {
        if (msg.sender != smartAccountFactory) revert OnlySmartAccountFactory(msg.sender);
        _;
    }

    /// @notice Set owner for a mass smart account
    /// @dev    Only the SmartAccountFactory can call this function
    /// @param massSmartAccount massSmartAccount address for which owner is set.
    /// @param owner Owner address of the massSmartAccount
    function setOwner(address massSmartAccount, address owner) external onlySmartAccountFactory {
        if (owner == address(0)) revert ZeroAddress();
        if (massSmartAccount.code.length == 0) revert AddressNotContract(massSmartAccount);

        // The owner can be set only once. It ensures censorship resistance as the SmartAccountFactory is upgradable.
        address currentOwner = ownerOf[massSmartAccount];
        if (currentOwner != address(0)) {
            revert OwnerAlreadySet();
        }

        ownerOf[massSmartAccount] = owner;
        emit OwnerUpdated(massSmartAccount, owner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

interface IAaveLending {
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

interface IPoolAddressesProviderV3 {
    function getPool() external returns (address);
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 *
 * WARNING: The usage of `delegatecall` in this contract is dangerous and may result in context corruption.
 * Any forwarded request to this contract triggering a `delegatecall` to itself will result in an invalid {_msgSender}
 * recovery.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return address(bytes20(msg.data[calldataLength - contextSuffixLength:]));
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        uint256 calldataLength = msg.data.length;
        uint256 contextSuffixLength = _contextSuffixLength();
        if (isTrustedForwarder(msg.sender) && calldataLength >= contextSuffixLength) {
            return msg.data[:calldataLength - contextSuffixLength];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev ERC-2771 specifies the context as being a single address (20 bytes).
     */
    function _contextSuffixLength() internal view virtual override returns (uint256) {
        return 20;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.2) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 proofLen = proof.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proofLen - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            require(proofPos == proofLen, "MerkleProof: invalid multiproof");
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IERC1271} from "openzeppelin/interfaces/IERC1271.sol";

/// @author MassMoney
/// @notice Interface for the MassSmartAccount contract.
/// @custom:version V1
interface IMassSmartAccount is IERC1271 {
    /// @dev Information to call a contract function.
    /// @param payload Payload to forward to contract, function with params
    ///                encoded.
    /// @param target Contract address to call.
    /// @param value The value to pass to the call.
    struct Call {
        bytes payload;
        address target;
        uint256 value;
    }

    /// @notice Execute a Call to a contract.
    /// @param call A Call to execute.
    /// @return data The returned data from the underlying call.
    function executeCall(Call calldata call) external payable returns (bytes memory data);

    /// @notice Execute a delegatecall to the HyVM.
    /// @dev This function is a shortcut to save gas, since the HyVM address
    ///      is immutable.
    ///      Any ETH sent to this function will be wrapped to WETH to avoid having
    ///      ETH in the smart account in case it is not used in the delegatecall.
    /// @param bytecode The data to delegatecall the HyVM.
    /// @return data The returned data from the underlying HyVM call.
    function executeHyVMCall(bytes calldata bytecode)
        external
        payable
        returns (bytes memory data);

    /// @notice Activate the ERC2771 feature.
    function activateERC2771() external;

    /// @notice Deactivate the ERC2771 feature.
    function deactivateERC2771() external;

    /// @notice Check if the ERC2771 feature is activated.
    /// @return activated True if activated, false if not.
    function isERC2771Activated() external view returns (bool activated);

    /// @notice Should return whether the signature provided is valid for the
    ///         provided hashed data.
    /// @param hash Hash of the data to be signed.
    /// @param signature Signature byte array associated with data.
    /// @return Function selector of the function or bytes4(0).
    function isValidSignature(bytes32 hash, bytes memory signature)
        external
        view
        returns (bytes4);

    /// @notice Execute a transaction through an EIP712 signature.
    /// @dev If the target is the HyVM, any ETH sent to this function will be
    ///      wrapped to WETH to avoid having ETH in the smart account in case it
    ///      is not used in the delegatecall.
    /// @param to The target address.
    /// @param payload The payload to send.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param n The nonce.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeSignature712(
        address to,
        bytes memory payload,
        uint256 value,
        uint256 expiration,
        uint256 n,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData);

    /// @notice Execute one of the transactions through the HyVM in a merkle tree which root was signed
    ///         by EIP712 signature.
    /// @dev Any ETH sent to this function will be wrapped to WETH to avoid having ETH in the
    ///      smart account in case it is not used in the delegatecall as the target is the HyVM.
    ///      Dynamic payload is appended to the signed payload when needed (e.g. pyth data).
    ///      Use cases of this function: TP and SL orders in the same bundle or creating multiple
    ///      limit orders in the same bundle.
    ///      It allows to require only one signature for multiple transactions from a user.
    ///      Merkle trees should be created with the Merkle tree OZ library.
    ///      https://github.com/OpenZeppelin/merkle-tree
    ///
    ///      !!! No jump should be done from the reentrantData to the dynamic data.
    ///          Only calldataload should be used to read the dynamic data else it
    ///          could lead to malicious data being executed.
    ///          By using the SDK, this issue will be avoided as it will ensure
    ///          only read of dynamic data will be done. !!!
    ///
    ///      !!! A particular attention is needed to be sure about what is signed as order
    ///          of transactions execution could have an impact. It is also the responsibility of the
    ///          user / SDK to check there are no 2 transactions with the same data in one merkle tree
    ///          else the second one will be rejected !!!
    ///
    /// @param root Merkle root of the tree that contains all signed transactions.
    /// @param proof Merkle proof of the transaction to execute.
    /// @param txPayload The transaction payload included in the merkle tree.
    /// @param dynamicPayload Dynamic payload to append to the txPayload.
    /// @param value The value to send.
    /// @param expiration The expiration timestamp.
    /// @param v The v value of the signature.
    /// @param r The r value of the signature.
    /// @param s The s value of the signature.
    /// @return returnData The returned data from the underlying call.
    function executeTransactionFromBundleSignature(
        bytes32 root,
        bytes32[] calldata proof,
        bytes memory txPayload,
        bytes memory dynamicPayload,
        uint256 value,
        uint256 expiration,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable returns (bytes memory returnData);

    /// @notice Revoke a transaction bundled in a merkle tree EIP712 execution bundle.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root of the tree.
    /// @param bundledTransaction The transaction to revoke.
    function revokeBundledTransactionExecution(bytes32 root, bytes32 bundledTransaction) external;

    /// @notice Revoke a merkle tree root. All transactions bundled in this merkle tree
    ///         will be revoked.
    /// @dev Only the owner can execute this function.
    /// @param root Merkle root to revoke.
    function revokeMerkleRootBundledTransactions(bytes32 root) external;

    /// @notice Build the domain separator for the EIP712 signature.
    /// @return The domain separator.
    function buildDomainSeparator() external view returns (bytes32);

    /// @notice Increment the nonce.
    /// @dev Only the owner can execute this function. It allows to cancel a
    ///      signature.
    function incrementNonce() external;

    /// @notice Return the owner of the current Mass Smart Account.
    /// @return Address of the owner.
    function smartAccountOwner() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {Address} from "openzeppelin/utils/Address.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IWETH} from "src/interfaces/external/IWETH.sol";
import {AddressNotContract, SenderNotWeth} from "src/Errors.sol";

/// @title Native token withdrawer
/// @dev Withdraw native token from the wrapper contract on behalf
///      of the sender. The Proxy.huff contract is not able to receive
///      native tokens from contracts via `transfer`. This intermediary contract
///      is needed to receive the native tokens and then send them to the
///      Proxy.huff contract.
contract WithdrawerWeth {
    using SafeERC20 for IWETH;

    IWETH public immutable weth;

    constructor(address _weth) {
        if (_weth.code.length == 0) {
            revert AddressNotContract(_weth);
        }
        weth = IWETH(_weth);
    }

    receive() external payable {
        if (msg.sender != address(weth)) {
            revert SenderNotWeth(msg.sender);
        }
    }

    /// @notice Withdraw native token from wrapper contract
    /// @param amount The amount to withdraw
    function withdraw(uint256 amount) external {
        weth.safeTransferFrom(msg.sender, address(this), amount);
        weth.withdraw(amount);
        Address.sendValue(payable(msg.sender), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @author MassMoney
/// @notice Interface for the SmartAccountOwnerResolver contract.
interface ISmartAccountOwnerResolver {
    /// @notice Returns the owner of a massSmartAccount.
    /// @param massSmartAccount massSmartAccount for which owner is returned.
    /// @return owner Owner of the massSmartAccount.
    function ownerOf(address massSmartAccount) external view returns (address owner);

    /// @notice Set owner for a mass smart account
    /// @dev    Only the SmartAccountFactory can call this function
    /// @param massSmartAccount massSmartAccount address for which owner is set.
    /// @param owner Owner address of the massSmartAccount
    function setOwner(address massSmartAccount, address owner) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {ReentrancyGuardUpgradeable} from "src/abstracts/ReentrancyGuardUpgradeable.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";
import {Address} from "openzeppelin/utils/Address.sol";
import {Create2} from "openzeppelin/utils/Create2.sol";
import {IMassSmartAccount} from "src/interfaces/IMassSmartAccount.sol";
import {ISmartAccountFactory} from "src/interfaces/ISmartAccountFactory.sol";
import {ISmartAccountOwnerResolver} from "src/interfaces/ISmartAccountOwnerResolver.sol";
import {MassSmartAccount} from "src/MassSmartAccount.sol";
import {
    AddressNotContract,
    AlreadyInitialized,
    CannotInitializeImpl,
    CannotRecreateSmartAccount,
    EmptyByteCode,
    FailedDeployment,
    SenderNotInitializer,
    ZeroAddress
} from "src/Errors.sol";

/// @author MassMoney
/// @notice Factory deploying MassSmartAccount contracts.
/// @dev The SmartAccountFactory is upgradeable, this is the implementation.
///      It uses the UUPS pattern. The upgradability is managed by the
///      TimelockController.
/// @custom:version V1
contract SmartAccountFactory is
    UUPSUpgradeable,
    Ownable2Step,
    ISmartAccountFactory,
    ReentrancyGuardUpgradeable
{
    /* -------------------------------------------------------------------------- */
    /*                                  CONSTANTS                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Implementation version.
    string public constant VERSION = "V1";

    /* -------------------------------------------------------------------------- */
    /*                                  IMMUTABLE                                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Address that will initialize the proxy.
    address public immutable initializer;

    /// @dev Address of the current contract necessary for the proxy
    ///      initialization.
    SmartAccountFactory private immutable _self;

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice True if proxy was initialized with storage of the current
    ///         contract.
    bool public initialized;

    /// @notice Proxy bytecode.
    /// @dev Used to deploy new instances of the MassSmartAccount contract.
    bytes public proxyByteCode;

    /// @notice Implementation resolver address.
    address public implementationResolver;

    /// @notice Smart account owner Resolver address.
    ISmartAccountOwnerResolver public smartAccountOwnerResolver;

    /// @notice WETH address.
    address public weth;

    /// @notice WithdrawerWeth address.
    address public withdrawerWeth;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /// @dev Emitted when a MassSmartAccount is created.
    /// @param massSmartAccount Address of the MassSmartAccount created.
    /// @param smartAccountOwner Owner and creator of the MassSmartAccount.
    event MassSmartAccountCreated(
        address indexed massSmartAccount, address indexed smartAccountOwner
    );

    /* -------------------------------------------------------------------------- */
    /*                                 CONSTRUCTOR                                */
    /* -------------------------------------------------------------------------- */

    constructor(bytes memory _proxyByteCode, address _initializer) {
        if (keccak256(_proxyByteCode) == keccak256(bytes(""))) revert EmptyByteCode();
        if (_initializer == address(0)) revert ZeroAddress();
        _self = this;
        proxyByteCode = _proxyByteCode;
        initializer = _initializer;
        _transferOwnership(address(0));
    }

    /* -------------------------------------------------------------------------- */
    /*                               EXECUTION LOGIC                              */
    /* -------------------------------------------------------------------------- */

    /// @notice Creates MassSmartAccount with create2 for a given smartAccountOwner.
    /// @dev The smart account owner is set by calling the smartAccountOwnerResolver.
    /// @param salt Salt provided to create2.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount The new MassSmartAccount address.
    function create(bytes32 salt, address smartAccountOwner)
        external
        override
        nonReentrant
        returns (address massSmartAccount)
    {
        // Base the salt computation on the smartAccountOwner
        salt = _computeCreate2Salt(salt, smartAccountOwner);

        bytes memory bytecodeWithArgs = _bytecodeWithArgs();

        assembly {
            // 'bytecodeWithArgs' is a pointer, pointing out the length of
            // 'bytecodeWithArgs' byte array.
            // Length is 32 byte word. After length, actual bytecode is stored
            // in memory. Therefore, the offset is : bytecode + 32.
            massSmartAccount :=
                create2(0, add(bytecodeWithArgs, 0x20), mload(bytecodeWithArgs), salt)
        }

        // Check that the deployment was successful
        if (massSmartAccount == address(0)) revert FailedDeployment();

        // Users should not be able to recreate their MassSmartAccount after
        // a selfdestruct.
        if (smartAccountOwnerResolver.ownerOf(massSmartAccount) != address(0)) {
            revert CannotRecreateSmartAccount(massSmartAccount);
        }

        // Initialize weth and withdrawerWeth in the smart account
        MassSmartAccount(payable(massSmartAccount)).initializeWithdrawerWeth(weth, withdrawerWeth);

        // Force wrap of pre-deployed ETH balance
        massSmartAccount.call{value: 0}("");

        // Set the given address as owner of the created smart account.
        smartAccountOwnerResolver.setOwner(massSmartAccount, smartAccountOwner);

        emit MassSmartAccountCreated(massSmartAccount, smartAccountOwner);
    }

    /// @notice Compute predicted Mass Smart Account address from salt and smartAccountOwner.
    /// @param salt salt provided by user to smartAccountFactory functions.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount Predicted address of the Mass Smart Account.
    function computePredictedAddressSmartAccount(bytes32 salt, address smartAccountOwner)
        external
        view
        returns (address)
    {
        return Create2.computeAddress(
            _computeCreate2Salt(salt, smartAccountOwner), keccak256(_bytecodeWithArgs())
        );
    }

    /// @dev Compute a salt based on an address and a given salt.
    ///      It hashes the given salt with smartAccountOwner so the
    ///      create2 address computation depends on this address.
    /// @param salt The given salt.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return computedSalt The bytes32 hash of the salt and the smartAccountOwner.
    function _computeCreate2Salt(bytes32 salt, address smartAccountOwner)
        internal
        pure
        returns (bytes32 computedSalt)
    {
        computedSalt = keccak256(abi.encode(salt, smartAccountOwner));
    }

    /// @dev Return the bytecode with args necessary for create2.
    ///      It is not stored in storage as it is more expensive than using
    ///      memory.
    function _bytecodeWithArgs() private view returns (bytes memory) {
        return abi.encodePacked(proxyByteCode, implementationResolver);
    }

    /* -------------------------------------------------------------------------- */
    /*                              INITIALIZER LOGIC                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Function called by Proxy to initialize its storage.
    /// @dev It is needed to break to break the loop of dependencies between
    ///      contracts.
    /// @param _owner Owner address to set
    /// @param _implementationResolver Address of the implementation resolver
    /// @param _smartAccountOwnerResolver Address of the SmartAccountOwnerResolver
    /// @param _weth Address of the WETH contract
    /// @param _withdrawerWeth Address of the WithdrawerWeth contract
    function initialize(
        address _owner,
        address _implementationResolver,
        address _smartAccountOwnerResolver,
        address _weth,
        address _withdrawerWeth
    ) external {
        if (initialized) revert AlreadyInitialized();
        if (address(this) == address(_self)) revert CannotInitializeImpl();
        if (msg.sender != initializer) revert SenderNotInitializer(msg.sender);
        if (_owner == address(0)) revert ZeroAddress();
        if (_implementationResolver.code.length == 0) {
            revert AddressNotContract(_implementationResolver);
        }
        if (_smartAccountOwnerResolver.code.length == 0) {
            revert AddressNotContract(_smartAccountOwnerResolver);
        }
        if (_weth.code.length == 0) revert AddressNotContract(_weth);
        if (_withdrawerWeth.code.length == 0) revert AddressNotContract(_withdrawerWeth);

        initialized = true;
        _reentrancyGuard_init();
        proxyByteCode = _self.proxyByteCode();
        _transferOwnership(_owner);
        implementationResolver = _implementationResolver;
        smartAccountOwnerResolver = ISmartAccountOwnerResolver(_smartAccountOwnerResolver);
        weth = _weth;
        withdrawerWeth = _withdrawerWeth;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 UUPS LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev  Called by upgradeTo and upgradeToAndCall
    /// @param newImplementation New implementation to authorize for upgrade
    function _authorizeUpgrade(address newImplementation) internal virtual override onlyOwner {
        if (newImplementation.code.length == 0) {
            revert AddressNotContract(newImplementation);
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {AlreadyInitialized, Reentrancy} from "src/Errors.sol";

/// @author MassMoney
/// @author Forked from OpenZeppelin https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/security/ReentrancyGuardUpgradeable.sol
///         and Solmate https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol.
/// @notice Gas optimized reentrancy protection for upgradeable smart contracts.
/// @dev The _locked variable will be 0 in the proxy context, therefore, there
///      is a function that initializes the locked variable to 1 in the context
///      of the proxy. Otherwise, all calls with the nonReentrant modifier will
///      fail.
abstract contract ReentrancyGuardUpgradeable {
    /// @dev Indicates if the ReentrancyGuard has been initialized.
    bool private _guardInitialized;

    /// @dev Used to lock a function from reentrant calls.
    uint256 private _locked;

    /// @dev Prevents a contract from calling itself, directly or indirectly.
    modifier nonReentrant() {
        if (_locked != 1) revert Reentrancy();

        _locked = 2;

        _;

        _locked = 1;
    }

    /// @dev Init _locked for the proxy and prevent new initialization.
    function _reentrancyGuard_init() internal {
        if (_guardInitialized) revert AlreadyInitialized();

        _locked = 1;
        _guardInitialized = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeTo(address newImplementation) public virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @author MassMoney
/// @notice Interface for the SmartAccountFactory contract.
/// @custom:version V1
interface ISmartAccountFactory {
    /// @notice Creates MassSmartAccount with create2 for a given smartAccountOwner.
    /// @dev The smart account owner is set by calling the smartAccountOwnerResolver.
    /// @param salt Salt provided to create2.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount The new MassSmartAccount address.
    function create(bytes32 salt, address smartAccountOwner)
        external
        returns (address massSmartAccount);

    /// @notice Compute predicted Mass Smart Account address from salt and smartAccountOwner.
    /// @param salt salt provided by user to smartAccountFactory functions.
    /// @param smartAccountOwner The address receiving the ownership.
    /// @return massSmartAccount Predicted address of the Mass Smart Account.
    function computePredictedAddressSmartAccount(bytes32 salt, address smartAccountOwner)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/IERC1967.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 */
abstract contract ERC1967Upgrade is IERC1967 {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(address newBeacon, bytes memory data, bool forceCall) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC1967.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC-1967: Proxy Storage Slots. This interface contains the events defined in the ERC.
 *
 * _Available since v4.8.3._
 */
interface IERC1967 {
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Emitted when the beacon is changed.
     */
    event BeaconUpgraded(address indexed beacon);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}