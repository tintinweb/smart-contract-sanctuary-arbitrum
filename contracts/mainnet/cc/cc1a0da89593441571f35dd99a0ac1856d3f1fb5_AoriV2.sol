pragma solidity 0.8.17;
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { SafeERC20 } from "./libs/SafeERC20.sol";
import { BitMaps } from "./libs/BitMaps.sol";
import { IAoriV2 } from "./interfaces/IAoriV2.sol";
import { IAoriHook } from "./interfaces/IAoriHook.sol";
import { IERC1271 } from "./interfaces/IERC1271.sol";
import { IERC165 } from "./interfaces/IERC165.sol";
import { IFlashLoanReceiver } from "./interfaces/IFlashLoanReceiver.sol";
import { SignatureChecker } from "./libs/SignatureChecker.sol";

/// @title AoriV2
/// @notice An implementation of the settlement contract used for the Aori V2 protocol
/// @dev The current implementation regards a serverSigner that signs off on matching details
///      of which the private key behind this wallet should be protected. If the private key is
///      compromised, no funds can technically be stolen but orders will be matched in a way
///      that is not intended i.e FIFO.
contract AoriV2 is IAoriV2 {
    /*//////////////////////////////////////////////////////////////
                               LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using BitMaps for BitMaps.BitMap;
    using SafeERC20 for IERC20;
    using SignatureChecker for address;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    // @notice Orders are stored using buckets of bitmaps to allow
    //         for potential gas optimisations by a bucket's bitmap
    //         having been written to previously. Programmatic
    //         users can also attempt to mine for specific order
    //         hashes to hit a used bucket.
    BitMaps.BitMap private orderStatus;

    // @notice 2D mapping of balances. The primary index is by
    //         owner and the secondary index is by token.
    mapping(address => mapping(address => uint256)) private balances;

    // @notice Counters for each address. A user can cancel orders
    //         by incrementing their counter, similar to how
    //         Seaport does it.
    mapping(address => uint256) private addressCounter;

    // @notice Server signer wallet used to verify matching for
    //         this contract. Again, the key should be protected.
    //         In the case that a key is compromised, no funds
    //         can be stolen but orders may be matched in an
    //         unfair way. A new contract would need to be
    //         deployed with a new deployer.
    address private immutable serverSigner;
    // Taker fee in bips i.e 100 = 1%
    uint8 private takerFeeBips;
    // Fees are paid to this address
    address private takerFeeAddress;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    
    constructor(address _serverSigner) {
        serverSigner = _serverSigner;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETTLE
    //////////////////////////////////////////////////////////////*/

    /// @notice Main bulk of the logic for validating and settling orders
    /// @param matching   The matching details of the orders to settle
    /// @param serverSignature  The signature of the server signer
    /// @dev Server signer signature must be signed with the private key of the server signer
    function settleOrders(MatchingDetails calldata matching, bytes calldata serverSignature, bytes calldata hookData, bytes calldata options) external payable {

        /*//////////////////////////////////////////////////////////////
                           SPECIFIC ORDER VALIDATION
        //////////////////////////////////////////////////////////////*/

        // Check start and end times of orders
        require(matching.makerOrder.startTime <= block.timestamp, "Maker order start time is in the future");
        require(matching.takerOrder.startTime <= block.timestamp, "Taker order start time is in the future");
        require(matching.makerOrder.endTime >= block.timestamp, "Maker order end time has already passed");
        require(matching.takerOrder.endTime >= block.timestamp, "Taker order end time has already passed");

        // Check counters (note: we allow orders with a counter greater than or equal to the current counter to be executed immediately)
        require(matching.makerOrder.counter >= addressCounter[matching.makerOrder.offerer], "Counter of maker order is too low");
        require(matching.takerOrder.counter >= addressCounter[matching.takerOrder.offerer], "Counter of taker order is too low");

        // And the chainId is the set chainId for the order such that
        // we can protect against cross-chain signature replay attacks.
        require(matching.makerOrder.inputChainId == matching.takerOrder.outputChainId, "Maker order's input chainid does not match taker order's output chainid");
        require(matching.takerOrder.inputChainId == matching.makerOrder.outputChainId, "Taker order's input chainid does not match maker order's output chainid");

        // Check zone
        require(matching.makerOrder.inputZone == matching.takerOrder.outputZone, "Maker order's input zone does not match taker order's output zone");
        require(matching.takerOrder.inputZone == matching.makerOrder.outputZone, "Taker order's input zone does not match maker order's output zone");

        // Single-chained orders via this contract
        require(matching.makerOrder.inputChainId == block.chainid, "Maker order's input chainid does not match current chainid");
        require(matching.takerOrder.inputChainId == block.chainid, "Taker order's input chainid does not match current chainid");
        require(matching.makerOrder.inputZone == address(this), "Maker order's input zone does not match this contract");
        require(matching.takerOrder.inputZone == address(this), "Taker order's input zone does not match this contract");

        // Compute order hashes of both orders
        bytes32 makerHash = getOrderHash(matching.makerOrder);
        bytes32 takerHash = getOrderHash(matching.takerOrder);

        // Check maker signature
        (uint8 makerV, bytes32 makerR, bytes32 makerS) = signatureIntoComponents(matching.makerSignature);
        require(matching.makerOrder.offerer.isValidSignatureNow(
            keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                makerHash
            )),
            abi.encodePacked(makerR, makerS, makerV)),
            "Maker signature does not correspond to order details"
        );

        (uint8 takerV, bytes32 takerR, bytes32 takerS) = signatureIntoComponents(matching.takerSignature);
        require(matching.takerOrder.offerer.isValidSignatureNow(
            keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                takerHash
            )),
            abi.encodePacked(takerR, takerS, takerV)),
            "Taker signature does not correspond to order details"
        );

        // Check that tokens are for each other
        require(matching.makerOrder.inputToken == matching.takerOrder.outputToken,
            "Maker order input token is not equal to taker order output token");
        require(matching.makerOrder.outputToken == matching.takerOrder.inputToken,
            "Maker order output token is not equal to taker order input token");

        // Check input/output amounts
        require(matching.takerOrder.outputAmount <= matching.makerOrder.inputAmount,
            "Taker order output amount is more than maker order input amount");
        require(matching.makerOrder.outputAmount <= adjustedWithFee(matching.takerOrder.inputAmount),
            "Maker order output amount is more than taker order input amount");

        // Check order statuses and make sure that they haven't been settled
        require(!BitMaps.get(orderStatus, uint256(makerHash)), "Maker order has been settled");
        require(!BitMaps.get(orderStatus, uint256(takerHash)), "Taker order has been settled");

        /*//////////////////////////////////////////////////////////////
                              MATCHING VALIDATION
        //////////////////////////////////////////////////////////////*/

        // Ensure that block deadline to execute has not passed
        require(
            matching.blockDeadline >= block.number,
            "Order execution deadline has passed"
        );

        (uint8 serverV, bytes32 serverR, bytes32 serverS) = signatureIntoComponents(serverSignature);

        // Ensure that the server has signed off on these matching details
        require(
            serverSigner ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            getMatchingHash(matching)
                        )
                    ),
                    serverV, serverR, serverS
                ),
            "Server signature does not correspond to order details"
        );

        /*//////////////////////////////////////////////////////////////
                                     SETTLE
        //////////////////////////////////////////////////////////////*/

        // These two lines alone cost 40k gas due to storage in the worst case :sad:
        // This itself is a form of non-reentrancy due to the order status checks above.
        BitMaps.set(orderStatus, uint256(makerHash));
        BitMaps.set(orderStatus, uint256(takerHash));

        // (Taker ==> Maker) processing
        if (balances[matching.takerOrder.offerer][matching.takerOrder.inputToken] >= matching.takerOrder.inputAmount) {
            balances[matching.takerOrder.offerer][matching.takerOrder.inputToken] -= matching.takerOrder.inputAmount;
        } else {
            // Transfer from their own wallet - move taker order assets into here
            IERC20(matching.takerOrder.inputToken).safeTransferFrom(matching.takerOrder.offerer, address(this), matching.takerOrder.inputAmount);
        }

        // If maker would like their output tokens withdrawn to them, they can do so.
        // Enabling the maker to receive the tokens first before we process their side
        // for them to have native flash-loan-like capabilities.
        if (!matching.makerOrder.toWithdraw) {
            // Add balance
            balances[matching.makerOrder.offerer][matching.makerOrder.outputToken] += matching.makerOrder.outputAmount;
        } else {
            IERC20(matching.makerOrder.outputToken).safeTransfer(
                matching.makerOrder.offerer,
                matching.makerOrder.outputAmount
            );
        }

        // Fee calculation
        if (takerFeeBips != 0) {
            // Apply fees
            balances[takerFeeAddress][matching.takerOrder.inputToken] += adjustedTakerFee(matching.takerOrder.inputAmount) * (100 - matching.seatPercentOfFees) / 100;

            if (matching.seatPercentOfFees != 0) {
                balances[matching.seatHolder][matching.takerOrder.inputToken] += adjustedTakerFee(matching.takerOrder.inputAmount) * matching.seatPercentOfFees / 100;
            }
        }
        
        // (Maker ==> Taker) processing
        // Before-Aori-Trade Hook
        if (matching.makerOrder.offerer.code.length > 0 && IERC165(matching.makerOrder.offerer).supportsInterface(IAoriHook.beforeAoriTrade.selector)) {
            (bool success) = IAoriHook(matching.makerOrder.offerer).beforeAoriTrade(matching, hookData);
            require(success, "BeforeAoriTrade hook failed");
        }

        if (balances[matching.makerOrder.offerer][matching.makerOrder.inputToken] >= matching.makerOrder.inputAmount) {
            balances[matching.makerOrder.offerer][matching.makerOrder.inputToken] -= matching.makerOrder.inputAmount;
        } else {
            IERC20(matching.makerOrder.inputToken).safeTransferFrom(matching.makerOrder.offerer, address(this), matching.makerOrder.inputAmount);
        }

        if (!matching.takerOrder.toWithdraw) {
            balances[matching.takerOrder.offerer][matching.takerOrder.outputToken] += matching.takerOrder.outputAmount;
        } else {
            IERC20(matching.takerOrder.outputToken).safeTransfer(
                matching.takerOrder.offerer,
                matching.takerOrder.outputAmount
            );
        }

        // After-Aori-Trade Hook
        if (matching.makerOrder.offerer.code.length > 0 && IERC165(matching.makerOrder.offerer).supportsInterface(IAoriHook.afterAoriTrade.selector)) {
            (bool success) = IAoriHook(matching.makerOrder.offerer).afterAoriTrade(matching, hookData);
            require(success, "AfterAoriTrade hook failed");
        }

        // Settler processing

        // Whoever settles the order gets to keep any excess
        if (matching.takerOrder.outputAmount > matching.makerOrder.inputAmount) {
            balances[tx.origin][matching.takerOrder.outputToken] += matching.takerOrder.outputAmount - matching.makerOrder.inputAmount;
        }

        if (matching.makerOrder.outputAmount > adjustedWithoutFee(matching.takerOrder.inputAmount)) {
            balances[tx.origin][matching.makerOrder.outputToken] += matching.makerOrder.outputAmount - adjustedWithoutFee(matching.takerOrder.inputAmount);
        }

        // Emit event
        emit OrdersSettled(
            makerHash, // makerHash
            takerHash, // takerHash
            matching.makerOrder.offerer, // maker
            matching.takerOrder.offerer, // taker
            matching.makerOrder.inputChainId, // inputChainId
            matching.makerOrder.outputChainId, // outputChainId
            matching.makerOrder.inputZone, // inputZone
            matching.makerOrder.outputZone, // outputZone
            matching.makerOrder.inputToken, // inputToken
            matching.makerOrder.outputToken, // outputToken
            matching.makerOrder.inputAmount, // inputAmount
            matching.makerOrder.outputAmount, // outputAmount
            getMatchingHash(matching)
        );
    }

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposits tokens to the contract
    /// @param _account The account to deposit to
    /// @param _token The token to deposit
    /// @param _amount The amount to deposit
    function deposit(address _account, address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        balances[_account][_token] += _amount;
    }

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws tokens from the contract
    /// @param _token The token to withdraw
    /// @param _amount The amount to withdraw
    function withdraw(address _token, uint256 _amount) external {
        balances[msg.sender][_token] -= (_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                               FLASH LOAN
    //////////////////////////////////////////////////////////////*/

    /// @notice Flash loan tokens
    /// @param recipient The recipient
    /// @param token The token
    /// @param amount The amount
    /// @param userData User data to pass to the recipient
    /// @param receiveToken Whether to receive the token directly or fine to keep in the contract for gas efficiency
    function flashLoan(address recipient, address token, uint256 amount, bytes memory userData, bool receiveToken) external {

        // Flash loan
        if (receiveToken) {
            IERC20(token).safeTransfer(recipient, amount);
        } else {
            balances[recipient][token] += amount;
        }
        
        // call the recipient's receiveFlashLoan
        IFlashLoanReceiver(recipient).receiveFlashLoan(token, amount, userData, receiveToken);

        if (receiveToken) {
            IERC20(token).safeTransferFrom(recipient, address(this), amount);
        } else {
            balances[recipient][token] -= amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 NONCE
    //////////////////////////////////////////////////////////////*/

    /// @notice Increment the counter of the sender. Note that this is
    ///         counter is not exactly a sequence number. It is a
    ///         counter that is incremented to denote
    function incrementCounter() external {
        addressCounter[msg.sender] += 1;
    }

    function getCounter() external view returns (uint256) {
        return addressCounter[msg.sender];
    }

    /*//////////////////////////////////////////////////////////////
                               TAKER FEE
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the taker fee address and bips
    /// @dev Can only be called by the server signer
    function setTakerFee(uint8 _takerFeeBips, address _takerFeeAddress) external {
        require(msg.sender == serverSigner, "Taker fee address must be server signer");
        require(_takerFeeBips <= 100, "Taker fee bips must be less than 1%");

        if (takerFeeBips != _takerFeeBips) {
            takerFeeBips = _takerFeeBips;
        }

        if (takerFeeAddress != _takerFeeAddress) {
            takerFeeAddress = _takerFeeAddress;
        }
    }

    function adjustedWithFee(uint256 _amount) internal view returns (uint256 amountWithFee) {
        amountWithFee = _amount * (10000 + takerFeeBips) / 10000;
    }

    function adjustedWithoutFee(uint256 _amountWithFee) internal view returns (uint256 amountWithoutFee) {
        amountWithoutFee = _amountWithFee * 10000 / (10000 + takerFeeBips);
    }

    function adjustedTakerFee(uint256 _amount) internal view returns (uint256 totalTakerFee) {
        totalTakerFee = _amount * takerFeeBips;
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function hasOrderSettled(bytes32 orderHash) public view returns (bool settled) {
        settled = BitMaps.get(orderStatus, uint256(orderHash));
    }

    function balanceOf(address _account, address _token) public view returns (uint256 balance) {
        balance = balances[_account][_token];
    }

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function signatureIntoComponents(
        bytes memory signature
    ) public pure returns (
        uint8 v,
        bytes32 r,
        bytes32 s
    ) {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }
    }

    function getOrderHash(Order memory order) public view returns (bytes32 orderHash) {
        orderHash = keccak256(
            abi.encodePacked(
                order.offerer,
                order.inputToken,
                order.inputAmount,
                order.inputChainId,
                order.inputZone,
                order.outputToken,
                order.outputAmount,
                order.outputChainId,
                order.outputZone,
                order.startTime,
                order.endTime,
                order.salt,
                order.counter,
                order.toWithdraw
            )
        );
    }

    function getMatchingHash(MatchingDetails calldata matching) public view returns (bytes32 matchingHash) {
        matchingHash = keccak256(
            abi.encodePacked(
                matching.makerSignature,
                matching.takerSignature,
                matching.blockDeadline,
                matching.seatNumber,
                matching.seatHolder,
                matching.seatPercentOfFees
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import { IERC20 } from "forge-std/interfaces/IERC20.sol";
import { Address } from "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
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
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

pragma solidity 0.8.17;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, provided the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 *
 * BitMaps pack 256 booleans across each bit of a single 256-bit slot of `uint256` type.
 * Hence booleans corresponding to 256 _sequential_ indices would only consume a single slot,
 * unlike the regular `bool` which would consume an entire slot for a single value.
 *
 * This results in gas savings in two ways:
 *
 * - Setting a zero value to non-zero only once every 256 times
 * - Accessing the same warm slot for every 256 _sequential_ indices
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

pragma solidity 0.8.17;

interface IAoriV2 {

    /*//////////////////////////////////////////////////////////////
                                STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Order {
        address offerer;
        address inputToken;
        uint256 inputAmount;
        uint256 inputChainId;
        address inputZone;
        address outputToken;
        uint256 outputAmount;
        uint256 outputChainId;
        address outputZone;
        uint256 startTime;
        uint256 endTime;
        uint256 salt;
        uint256 counter;
        bool toWithdraw;
    }

    struct MatchingDetails {
        Order makerOrder;
        Order takerOrder;

        bytes makerSignature;
        bytes takerSignature;
        uint256 blockDeadline;

        // Seat details
        uint256 seatNumber;
        address seatHolder;
        uint256 seatPercentOfFees;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OrdersSettled(
        bytes32 indexed makerHash,
        bytes32 indexed takerHash,
        address maker,
        address taker,
        uint256 inputChainId,
        uint256 outputChainId,
        address inputZone,
        address outputZone,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        bytes32 matchingHash
    );

    /*//////////////////////////////////////////////////////////////
                                 SETTLE
    //////////////////////////////////////////////////////////////*/

    function settleOrders(MatchingDetails calldata matching, bytes calldata serverSignature, bytes calldata hookData, bytes calldata options) external payable;

    /*//////////////////////////////////////////////////////////////
                                DEPOSIT
    //////////////////////////////////////////////////////////////*/

    function deposit(address _account, address _token, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                                WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function withdraw(address _token, uint256 _amount) external;

    /*//////////////////////////////////////////////////////////////
                               FLASHLOAN
    //////////////////////////////////////////////////////////////*/

    function flashLoan(address recipient, address token, uint256 amount, bytes memory userData, bool receiveToken) external;

    /*//////////////////////////////////////////////////////////////
                                 COUNTER
    //////////////////////////////////////////////////////////////*/

    function incrementCounter() external;
    function getCounter() external view returns (uint256);

    /*//////////////////////////////////////////////////////////////
                               TAKER FEE
    //////////////////////////////////////////////////////////////*/

    function setTakerFee(uint8 _takerFeeBips, address _takerFeeAddress) external;

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function hasOrderSettled(bytes32 orderHash) external view returns (bool settled);
    function balanceOf(address _account, address _token) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                            HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function signatureIntoComponents(
        bytes memory signature
    ) external pure returns (
        uint8 v,
        bytes32 r,
        bytes32 s
    );
    function getOrderHash(Order memory order) external view returns (bytes32 orderHash);
    function getMatchingHash(MatchingDetails calldata matching) external view returns (bytes32 matchingHash);
}

pragma solidity 0.8.17;

import "./IAoriV2.sol";

interface IAoriHook {
    function beforeAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
    function afterAoriTrade(IAoriV2.MatchingDetails calldata matching, bytes calldata hookData) external returns (bool);
}

pragma solidity 0.8.17;

interface IERC1271 {
  // bytes4(keccak256("isValidSignature(bytes32,bytes)")
  // bytes4 constant internal MAGICVALUE = 0x1626ba7e;

  /**
   * @dev Should return whether the signature provided is valid for the provided hash
   * @param _hash      Hash of the data to be signed
   * @param _signature Signature byte array associated with _hash
   *
   * MUST return the bytes4 magic value 0x1626ba7e when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */ 
  function isValidSignature(
    bytes32 _hash, 
    bytes memory _signature)
    external
    view 
    returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity 0.8.17;

interface IFlashLoanReceiver {
    function receiveFlashLoan(
        address token,
        uint256 amount,
        bytes calldata data,
        bool receiveToken
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity 0.8.17;

import {ECDSA} from "./ECDSA.sol";
import {IERC1271} from "../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC-1271 signatures from smart contract wallets like
 * Argent and Safe Wallet (previously Gnosis Safe).
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC-1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(address signer, bytes32 hash, bytes memory signature) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error, ) = ECDSA.tryRecover(hash, signature);
        return
            (error == ECDSA.RecoverError.NoError && recovered == signer) ||
            isValidERC1271SignatureNow(signer, hash, signature);
    }

    /**
     * @dev Checks if a signature is valid for a given signer and data hash. The signature is validated
     * against the signer smart contract using ERC-1271.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidERC1271SignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeCall(IERC1271.isValidSignature, (hash, signature))
        );
        return (success &&
            result.length >= 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/cryptography/ECDSA.sol)

pragma solidity 0.8.17;

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
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[ERC-2098 short signatures]
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError, bytes32) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError, bytes32) {
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
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}