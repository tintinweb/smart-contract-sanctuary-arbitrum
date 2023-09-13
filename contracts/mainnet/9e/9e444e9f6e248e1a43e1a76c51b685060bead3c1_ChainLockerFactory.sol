/**
 *Submitted for verification at Arbiscan.io on 2023-09-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * this solidity file is provided as-is; no guarantee, representation or warranty is being made, express or implied,
 * as to the safety or correctness of the code or any smart contracts or other software deployed from these files.
 * '_seller', '_buyer', '_deposit', '_refundable', '_openOffer' and other terminology herein is used only for simplicity and convenience of reference, and
 * should not be interpreted to ascribe, intend, nor imply any legal status, agreement, nor relationship between or among any author, modifier, deployer, participant, or other relevant user hereto
 **/

// O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O \\

/////// o=o=o=o=o ChainLocker Factory o=o=o=o=o \\\\\\\

// O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O=o=O \\

/// @notice interface to Receipt.sol, which optionally returns USD-value receipts for a provided token amount
interface IReceipt {
    function printReceipt(
        address token,
        uint256 tokenAmount,
        uint256 decimals
    ) external returns (uint256, uint256);
}

/// @notice used for valueCondition checks - user must ensure the correct dAPI/data feed proxy address is provided to the constructor
/// @dev See docs.api3.org for comments about usage
interface IProxy {
    function read() external view returns (int224 value, uint32 timestamp);
}

/// @notice Solbase / Solady's SafeTransferLib 'SafeTransferETH()'.  Extracted from library and pasted for convenience, transparency, and size minimization.
/// @author Solbase / Solady (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol / https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// Licenses copied below
/// @dev implemented as abstract contract rather than library for size/gas reasons
abstract contract SafeTransferLib {
    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }
}

/// @notice Gas-optimized reentrancy protection for smart contracts.
/// @author Solbase (https://github.com/Sol-DAO/solbase/blob/main/src/utils/ReentrancyGuard.sol)
/// License copied below
/// @dev sole difference from Solmate's ReentrancyGuard is 'Reentrancy()' custom error
abstract contract ReentrancyGuard {
    uint256 private locked = 1;
    error Reentrancy();

    modifier nonReentrant() virtual {
        if (locked == 2) revert Reentrancy();
        locked = 2;
        _;
        locked = 1;
    }
}

/**
 * @title       o=o=o=o=o EthLocker o=o=o=o=o
 **/
/**
 * @author      o=o=o=o=o ChainLocker LLC o=o=o=o=o
 **/
/** @notice non-custodial smart escrow contract for ETH-denominated transaction on Arbitrum, supporting:
 * partial or full deposit amount
 * refundable or non-refundable deposit upon expiry
 * seller-identified buyer or open offer
 * escrow expiration denominated in seconds
 * optional value condition for execution (contingent execution based on oracle-fed external data value)
 * buyer and seller addresses replaceable by applicable party
 **/
/** @dev executes and releases 'totalAmount' to 'seller' iff:
 * (1) 'buyer' and 'seller' have both called 'readyToExecute()'
 * (2) address(this).balance - 'pendingWithdraw' >= 'totalAmount'
 * (3) 'expirationTime' > block.timestamp
 * (4) if there is a valueCondition, such condition is satisfied
 *
 * otherwise, amount held in address(this) will be treated according to the code in 'checkIfExpired()' when called following expiry
 *
 * variables are public for interface friendliness and enabling getters.
 * 'seller', 'buyer', 'deposit', 'refundable', 'open offer' and other terminology, naming, and descriptors herein are used only for simplicity and convenience of reference, and
 * should not be interpreted to ascribe nor imply any agreement or relationship between or among any author, modifier, deployer, user, contract, asset, or other relevant participant hereto
 **/
contract EthLocker is ReentrancyGuard, SafeTransferLib {
    /** @notice enum values represent the following:
     *** 0 ('None'): no value contingency to ChainLocker execution; '_maximumValue', '_minimumValue' and '_dataFeedProxyAddress' params are ignored.
     *** 1 ('LessThanOrEqual'): the value returned from '_dataFeedProxyAddress' must be <= '_maximumValue' when calling 'execute()'; '_minimumValue' param is ignored
     *** 2 ('GreaterThanOrEqual'): the value returned from '_dataFeedProxyAddress' must be >= '_minimumValue' when calling 'execute()'; '_maximumValue' param is ignored
     *** 3 ('Both'): the value returned from '_dataFeedProxyAddress' must be both <= '_maximumValue' and >= '_minimumValue' when calling 'execute()'
     */
    enum ValueCondition {
        None,
        LessThanOrEqual,
        GreaterThanOrEqual,
        Both
    }

    // Receipt.sol contract address, Arbitrum One mainnet
    IReceipt internal constant RECEIPT =
        IReceipt(0xf838D6829fcCBedCB0B4D8aD58cb99814F935BA8);

    // 60 seconds * 60 minutes * 24 hours
    uint256 internal constant ONE_DAY = 86400;
    // 18 decimals for wei
    uint256 internal constant DECIMALS = 18;

    IProxy public immutable dataFeedProxy;
    ValueCondition public immutable valueCondition;
    bool public immutable openOffer;
    bool public immutable refundable;
    int224 public immutable maximumValue;
    int224 public immutable minimumValue;
    uint256 public immutable deposit;
    uint256 public immutable expirationTime;
    uint256 public immutable totalAmount;

    bool public deposited;
    bool public isExpired;
    bool public buyerApproved;
    bool public sellerApproved;
    address payable public buyer;
    address payable public seller;
    /// @notice aggregate pending withdrawable amount, so address(this) balance checks subtract withdrawable, but not yet withdrawn, amounts
    uint256 public pendingWithdraw;

    mapping(address => uint256) public amountDeposited;
    mapping(address => uint256) public amountWithdrawable;

    ///
    /// EVENTS
    ///

    event EthLocker_AmountReceived(uint256 weiAmount);
    event EthLocker_BuyerReady();
    event EthLocker_BuyerUpdated(address newBuyer);
    event EthLocker_DepositedAmountTransferred(
        address receiver,
        uint256 amount
    );
    event EthLocker_DepositInEscrow(address depositor);
    event EthLocker_Deployed(
        bool refundable,
        bool openOffer,
        uint256 deposit,
        uint256 totalAmount,
        uint256 expirationTime,
        address seller,
        address buyer
    );
    event EthLocker_DeployedCondition(
        address dataFeedProxy,
        ValueCondition valueCondition,
        int224 minimumValue,
        int224 maximumValue
    );
    event EthLocker_Expired();
    // emit indexed effective time of execution for ease of log collection, plus valueCondition value & value-reading oracle proxy contract (if applicable)
    event EthLocker_Executed(
        uint256 indexed effectiveTime,
        int224 valueCondition,
        address dataFeedProxy
    );
    event EthLocker_TotalAmountInEscrow();
    event EthLocker_SellerReady();
    event EthLocker_SellerUpdated(address newSeller);

    ///
    /// ERRORS
    ///

    error EthLocker_BalanceExceedsTotalAmount();
    error EthLocker_DepositGreaterThanTotalAmount();
    error EthLocker_IsExpired();
    error EthLocker_MustDepositTotalAmount();
    error EthLocker_NotReadyToExecute();
    error EthLocker_NotBuyer();
    error EthLocker_NotSeller();
    error EthLocker_OnlyOpenOffer();
    error EthLocker_ValueConditionConflict();
    error EthLocker_ValueOlderThanOneDay();
    error EthLocker_ZeroAmount();

    ///
    /// FUNCTIONS
    ///

    /// @notice constructs the EthLocker smart escrow contract. Arranger MUST verify that the _dataFeedProxyAddress is accurate if '_valueCondition' != 0, as neither address(this) nor the ChainLockerFactory.sol contract perform such check.
    /// @param _refundable: whether the '_deposit' is refundable to the 'buyer' in the event escrow expires without executing
    /// @param _openOffer: whether this escrow is open to any prospective 'buyer' (revocable at seller's option). A 'buyer' assents by sending 'deposit' to address(this) after deployment
    /** @param _valueCondition: uint8 corresponding to the ValueCondition enum (passed as 0, 1, 2, or 3), which is the value contingency (via oracle) which must be satisfied for the ChainLocker to release. Options are 0, 1, 2, or 3, which
     *** respectively correspond to: none, <=, >=, or two conditions (both <= and >=, for the '_maximumValue' and '_minimumValue' params, respectively).
     *** For an **EXACT** value condition (i.e. that the returned value must equal an exact number), pass '3' (Both) and pass such exact required value as both '_minimumValue' and '_maximumValue'
     *** Passed as uint8 rather than enum for easier composability */
    /// @param _maximumValue: the maximum permitted int224 value returned from the applicable dAPI / API3 data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 2.
    /// @param _minimumValue: the minimum permitted int224 value returned from the applicable dAPI / API3 data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 1.
    /// @param _deposit: deposit amount in wei, which must be <= '_totalAmount' (< for partial deposit, == for full deposit). If 'openOffer', msg.sender must deposit entire 'totalAmount', but if '_refundable', this amount will be refundable to the accepting address of the open offer (buyer) at expiry if not yet executed
    /// @param _totalAmount: total amount in wei which will be deposited in this contract, ultimately intended for '_seller'
    /// @param _expirationTime: _expirationTime in seconds (Unix time), which will be compared against block.timestamp. input type(uint256).max for no expiry (not recommended, as funds will only be released upon execution or if seller rejects depositor -- refunds only process at expiry)
    /// @param _seller: the seller's address, recipient of the '_totalAmount' if the contract executes
    /// @param _buyer: the buyer's address, who will cause the '_totalAmount' to be transferred to this address. Ignored if 'openOffer'
    /// @param _dataFeedProxyAddress: contract address for the proxy that will be used to access the applicable dAPI / data feed for the '_valueCondition' query. Ignored if '_valueCondition' == 0. Person calling this method should ensure the applicable sponsor wallet is sufficiently funded for their intended purposes, if applicable.
    constructor(
        bool _refundable,
        bool _openOffer,
        uint8 _valueCondition,
        int224 _maximumValue,
        int224 _minimumValue,
        uint256 _deposit,
        uint256 _totalAmount,
        uint256 _expirationTime,
        address payable _seller,
        address payable _buyer,
        address _dataFeedProxyAddress
    ) payable {
        if (_deposit > _totalAmount)
            revert EthLocker_DepositGreaterThanTotalAmount();
        if (_totalAmount == 0) revert EthLocker_ZeroAmount();
        if (_expirationTime <= block.timestamp) revert EthLocker_IsExpired();
        // '_valueCondition' cannot be > 3, nor can '_maximumValue' be < '_minimumValue' if _valueCondition == 3 (ValueCondition.Both)
        if (
            _valueCondition > 3 ||
            (_valueCondition == 3 && _maximumValue < _minimumValue)
        ) revert EthLocker_ValueConditionConflict();

        buyer = _buyer;
        refundable = _refundable;
        openOffer = _openOffer;
        valueCondition = ValueCondition(_valueCondition);
        maximumValue = _maximumValue;
        minimumValue = _minimumValue;
        deposit = _deposit;
        totalAmount = _totalAmount;
        seller = _seller;
        expirationTime = _expirationTime;
        dataFeedProxy = IProxy(_dataFeedProxyAddress);

        emit EthLocker_Deployed(
            _refundable,
            _openOffer,
            _deposit,
            _totalAmount,
            _expirationTime,
            _seller,
            _buyer
        );
        // if execution is contingent upon a value or values, emit relevant information
        if (_valueCondition != 0)
            emit EthLocker_DeployedCondition(
                _dataFeedProxyAddress,
                valueCondition,
                _minimumValue,
                _maximumValue
            );
    }

    /// @notice deposit value simply by sending 'msg.value' to 'address(this)'; if openOffer, msg.sender must deposit 'totalAmount'
    /** @dev max msg.value limit of 'totalAmount', and if 'totalAmount' is already held or escrow has expired, revert. Updates boolean and emits event when 'deposit' reached
     ** also updates 'buyer' to msg.sender if true 'openOffer' and false 'deposited' (msg.sender must send 'totalAmount' to accept an openOffer), and
     ** records amount deposited by msg.sender in case of refundability or where 'seller' rejects a 'buyer' and buyer's deposited amount is to be returned  */
    receive() external payable {
        uint256 _lockedBalance = address(this).balance - pendingWithdraw;
        if (_lockedBalance > totalAmount)
            revert EthLocker_BalanceExceedsTotalAmount();
        if (expirationTime <= block.timestamp) revert EthLocker_IsExpired();
        if (openOffer && _lockedBalance < totalAmount)
            revert EthLocker_MustDepositTotalAmount();
        if (_lockedBalance >= deposit && !deposited) {
            // if this EthLocker is an open offer and was not yet accepted (thus '!deposited'), make depositing address the 'buyer' and update 'deposited' to true
            if (openOffer) {
                buyer = payable(msg.sender);
                emit EthLocker_BuyerUpdated(msg.sender);
            }
            deposited = true;
            emit EthLocker_DepositInEscrow(msg.sender);
        }
        if (_lockedBalance == totalAmount) emit EthLocker_TotalAmountInEscrow();
        amountDeposited[msg.sender] += msg.value;
        emit EthLocker_AmountReceived(msg.value);
    }

    /// @notice for the current seller to designate a new recipient address
    /// @param _seller: new recipient address of seller
    function updateSeller(address payable _seller) external {
        if (msg.sender != seller) revert EthLocker_NotSeller();

        if (!checkIfExpired()) {
            seller = _seller;
            emit EthLocker_SellerUpdated(_seller);
        }
    }

    /// @notice for the current 'buyer' to designate a new buyer address
    /// @param _buyer: new address of buyer
    function updateBuyer(address payable _buyer) external {
        if (msg.sender != buyer) revert EthLocker_NotBuyer();

        // transfer 'amountDeposited[buyer]' to the new '_buyer', delete the existing buyer's 'amountDeposited', and update the 'buyer' state variable
        if (!checkIfExpired()) {
            amountDeposited[_buyer] += amountDeposited[buyer];
            delete amountDeposited[buyer];

            buyer = _buyer;
            emit EthLocker_BuyerUpdated(_buyer);
        }
    }

    /// @notice seller and buyer each call this when ready to execute the ChainLocker; other address callers will have no effect
    /// @dev no need for an address(this).balance check because (1) a reasonable seller will only pass 'true'
    /// if 'totalAmount' is in place, and (2) 'execute()' requires the locked balance >= 'totalAmount'
    /// separate conditionals in case 'buyer' == 'seller'
    function readyToExecute() external {
        if (msg.sender == seller) {
            sellerApproved = true;
            emit EthLocker_SellerReady();
        }
        if (msg.sender == buyer) {
            buyerApproved = true;
            emit EthLocker_BuyerReady();
        }
    }

    /** @notice callable by any external address: checks if both buyer and seller are ready to execute and expiration has not been met;
     *** if so, this contract executes and transfers 'totalAmount' to 'seller'; if not, totalAmount deposit returned to buyer (if refundable) **/
    /** @dev requires entire 'totalAmount' be held by address(this). If properly executes, pays seller and emits event with effective time of execution.
     *** Does not require amountDeposited[buyer] == address(this).balance to allow buyer to deposit from multiple addresses if desired */
    function execute() external {
        uint256 _lockedBalance = address(this).balance - pendingWithdraw;
        if (!sellerApproved || !buyerApproved || _lockedBalance < totalAmount)
            revert EthLocker_NotReadyToExecute();
        int224 _value;

        // delete approvals
        delete sellerApproved;
        delete buyerApproved;

        // only perform these checks if ChainLocker execution is contingent upon specified external value condition(s)
        if (valueCondition != ValueCondition.None) {
            (int224 _returnedValue, uint32 _timestamp) = dataFeedProxy.read();
            // require a value update within the last day
            if (block.timestamp - _timestamp > ONE_DAY)
                revert EthLocker_ValueOlderThanOneDay();

            if (
                (valueCondition == ValueCondition.LessThanOrEqual &&
                    _returnedValue > maximumValue) ||
                (valueCondition == ValueCondition.GreaterThanOrEqual &&
                    _returnedValue < minimumValue) ||
                (valueCondition == ValueCondition.Both &&
                    (_returnedValue > maximumValue ||
                        _returnedValue < minimumValue))
            ) revert EthLocker_ValueConditionConflict();
            // if no reversion, store the '_returnedValue' and proceed with execution
            else _value = _returnedValue;
        }

        if (!checkIfExpired()) {
            delete deposited;
            delete amountDeposited[buyer];
            // safeTransfer 'totalAmount' to 'seller' since 'receive()' prevents depositing more than the totalAmount, and safeguarded by any excess balance being withdrawable by buyer after expiry in 'checkIfExpired()'
            safeTransferETH(seller, totalAmount);

            // effective time of execution is block.timestamp upon payment to seller
            emit EthLocker_Executed(
                block.timestamp,
                _value,
                address(dataFeedProxy)
            );
            emit EthLocker_DepositedAmountTransferred(seller, totalAmount);
        }
    }

    /// @notice convenience function to get a USD value receipt if a dAPI / data feed proxy exists for ETH, for example for 'seller' to submit 'totalAmount' immediately after execution/release of this EthLocker
    /// @dev external call will revert if price quote is too stale or if token is not supported; event containing '_paymentId' and '_usdValue' emitted by Receipt.sol. address(0) hard-coded for tokenContract, as native gas token price is sought
    /// @param _weiAmount: amount of wei for which caller is seeking the total USD value receipt (for example, 'totalAmount' or 'deposit')
    function getReceipt(
        uint256 _weiAmount
    ) external returns (uint256 _paymentId, uint256 _usdValue) {
        return RECEIPT.printReceipt(address(0), _weiAmount, DECIMALS);
    }

    /// @notice for a 'seller' to reject any depositing address (including 'buyer') and enable their withdrawal of their deposited amount in 'withdraw()'
    /// @param _depositor: address being rejected by 'seller' which will subsequently be able to withdraw their 'amountDeposited' in 'withdraw()'
    /// @dev if !openOffer and 'seller' passes 'buyer' to this function, 'buyer' will need to call 'updateBuyer' to choose another address and re-deposit tokens.
    function rejectDepositor(address payable _depositor) external nonReentrant {
        if (msg.sender != seller) revert EthLocker_NotSeller();

        uint256 _amtDeposited = amountDeposited[_depositor];
        if (_amtDeposited == 0) revert EthLocker_ZeroAmount();

        delete amountDeposited[_depositor];
        // regardless of whether '_depositor' is 'buyer', permit them to withdraw their 'amountWithdrawable' balance
        amountWithdrawable[_depositor] += _amtDeposited;
        // update the aggregate withdrawable balance counter
        pendingWithdraw += _amtDeposited;

        // reset 'deposited' and 'buyerApproved' variables if 'seller' passed 'buyer' as '_depositor'
        if (_depositor == buyer) {
            delete deposited;
            delete buyerApproved;
            // if 'openOffer', delete the 'buyer' variable so the next valid depositor will become 'buyer'
            // we do not delete 'buyer' if !openOffer, to allow the 'buyer' to choose another address via 'updateBuyer', rather than irreversibly deleting the variable
            if (openOffer) {
                delete buyer;
                emit EthLocker_BuyerUpdated(address(0));
            }
        }
    }

    /// @notice allows an address to withdraw 'amountWithdrawable' of wei, such as a refundable amount post-expiry or if seller has called 'rejectDepositor' for such an address, etc.
    /// @dev used by a depositing address which 'seller' passed to 'rejectDepositor()', or if 'isExpired', used by 'buyer' and/or 'seller' (as applicable)
    function withdraw() external {
        uint256 _amt = amountWithdrawable[msg.sender];
        if (_amt == 0) revert EthLocker_ZeroAmount();

        delete amountWithdrawable[msg.sender];
        // update the aggregate withdrawable balance counter
        pendingWithdraw -= _amt;

        safeTransferETH(payable(msg.sender), _amt);
        emit EthLocker_DepositedAmountTransferred(msg.sender, _amt);
    }

    /// @notice check if expired, and if so, handle refundability by updating the 'amountWithdrawable' mapping as applicable
    /** @dev if expired, update isExpired boolean. If non-refundable, update seller's 'amountWithdrawable' to be the non-refundable deposit amount before updating buyer's mapping for the remainder.
     *** If refundable, update buyer's 'amountWithdrawable' to the entire balance. */
    /// @return isExpired
    function checkIfExpired() public nonReentrant returns (bool) {
        if (expirationTime <= block.timestamp) {
            isExpired = true;
            uint256 _balance = address(this).balance - pendingWithdraw;
            bool _isDeposited = deposited;

            emit EthLocker_Expired();

            delete deposited;
            delete amountDeposited[buyer];
            // update the aggregate withdrawable balance counter. Cannot overflow even if address(this).balance == type(uint256).max because 'pendingWithdraw' is subtracted in the calculation of '_balance' above
            unchecked {
                pendingWithdraw += _balance;
            }

            if (_balance > 0) {
                // if non-refundable deposit and 'deposit' hasn't been reset to 'false' by a successful 'execute()', enable 'seller' to withdraw the 'deposit' amount before enabling the remainder amount (if any) to be withdrawn by buyer
                if (!refundable && _isDeposited) {
                    amountWithdrawable[seller] = deposit;
                    amountWithdrawable[buyer] = _balance - deposit;
                } else amountWithdrawable[buyer] = _balance;
            }
        }
        return isExpired;
    }
}
/// @notice interface for ERC-20 standard token contract, including EIP2612 permit function
interface IERC20Permit {
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
/// @notice Solbase / Solady's SafeTransferLib 'SafeTransfer()' and 'SafeTransferFrom()'.  Extracted from library and pasted for convenience, transparency, and size minimization.
/// @author Solbase / Solady (https://github.com/Sol-DAO/solbase/blob/main/src/utils/SafeTransferLib.sol / https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// Licenses copied below
/// @dev implemented as abstract contract rather than library for size/gas reasons
abstract contract TokenSafeTransferLib {
    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0xa9059cbb)
            mstore(0x20, to) // Append the "to" argument.
            mstore(0x40, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x44 because that's the total length of our calldata (0x04 + 0x20 * 2)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // We'll write our calldata to this slot below, but restore it later.
            let memPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Append the "from" argument.
            mstore(0x40, to) // Append the "to" argument.
            mstore(0x60, amount) // Append the "amount" argument.

            if iszero(
                and(
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    // We use 0x64 because that's the total length of our calldata (0x04 + 0x20 * 3)
                    // Counterintuitively, this call() must be positioned after the or() in the
                    // surrounding and() because and() evaluates its arguments from right to left.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, memPointer) // Restore the memPointer.
        }
    }
}

/**
 * @title       o=o=o=o=o TokenLocker o=o=o=o=o
 **/
/**
 * @author      o=o=o=o=o ChainLocker LLC o=o=o=o=o
 **/
/** @notice non-custodial smart escrow contract using ERC20 tokens on Arbitrum One, supporting:
 * partial or full deposit amount
 * refundable or non-refundable deposit upon expiry
 * deposit via transfer or EIP2612 permit signature
 * seller-identified buyer or open offer
 * escrow expiration denominated in seconds
 * optional value condition for execution (contingent execution based on oracle-fed external data value)
 * buyer and seller addresses replaceable by applicable party
 **/
/** @dev optimize with >= 200 runs. contract executes and releases 'totalAmount' to 'seller' iff:
 * (1) 'buyer' and 'seller' have both called 'readyToExecute()'
 * (2) erc20.balanceOf(address(this)) - 'pendingWithdraw' >= 'totalAmount'
 * (3) 'expirationTime' > block.timestamp
 * (4) if there is a valueCondition, such condition is satisfied
 *
 * otherwise, amount held in address(this) will be treated according to the code in 'checkIfExpired()' when called following expiry
 *
 * variables are public for interface friendliness and enabling getters.
 * 'seller', 'buyer', 'deposit', 'refundable', 'openOffer' and other terminology, naming, and descriptors herein are used only for simplicity and convenience of reference, and
 * should not be interpreted to ascribe nor imply any agreement or relationship between or among any author, modifier, deployer, user, contract, asset, or other relevant participant hereto
 **/
contract TokenLocker is ReentrancyGuard, TokenSafeTransferLib {
    /** @notice enum values represent the following:
     *** 0 ('None'): no value contingency to ChainLocker execution; '_maximumValue', '_minimumValue' and '_dataFeedProxyAddress' params are ignored.
     *** 1 ('LessThanOrEqual'): the value returned from '_dataFeedProxyAddress' must be <= '_maximumValue' when calling 'execute()'; '_minimumValue' param is ignored
     *** 2 ('GreaterThanOrEqual'): the value returned from '_dataFeedProxyAddress' must be >= '_minimumValue' when calling 'execute()'; '_maximumValue' param is ignored
     *** 3 ('Both'): the value returned from '_dataFeedProxyAddress' must be both <= '_maximumValue' and >= '_minimumValue' when calling 'execute()'
     */
    enum ValueCondition {
        None,
        LessThanOrEqual,
        GreaterThanOrEqual,
        Both
    }

    // Receipt.sol contract address, Arbitrum One
    IReceipt internal constant RECEIPT =
        IReceipt(0xf838D6829fcCBedCB0B4D8aD58cb99814F935BA8);

    // 60 seconds * 60 minutes * 24 hours
    uint256 internal constant ONE_DAY = 86400;

    // internal visibility for gas savings, as 'tokenContract' is public and bears the same contract address
    IERC20Permit internal immutable erc20;

    IProxy internal immutable dataFeedProxy;
    ValueCondition public immutable valueCondition;
    address public immutable tokenContract;
    bool public immutable openOffer;
    bool public immutable refundable;
    int224 public immutable maximumValue;
    int224 public immutable minimumValue;
    uint256 public immutable deposit;
    uint256 public immutable totalAmount;
    uint256 public immutable expirationTime;

    address public buyer;
    address public seller;
    bool public deposited;
    bool public isExpired;
    bool public buyerApproved;
    bool public sellerApproved;
    /// @notice aggregate pending withdrawable amount, so address(this) balance checks subtract withdrawable, but not yet withdrawn, amounts
    uint256 public pendingWithdraw;

    mapping(address => uint256) public amountDeposited;
    mapping(address => uint256) public amountWithdrawable;

    ///
    /// EVENTS
    ///

    event TokenLocker_AmountReceived(uint256 tokenAmount);
    event TokenLocker_BuyerReady();
    event TokenLocker_BuyerUpdated(address newBuyer);
    event TokenLocker_DepositedAmountTransferred(
        address receiver,
        uint256 amount
    );
    event TokenLocker_DepositInEscrow(address depositor);
    event TokenLocker_Deployed(
        bool refundable,
        bool openOffer,
        uint256 deposit,
        uint256 totalAmount,
        uint256 expirationTime,
        address seller,
        address buyer,
        address tokenContract
    );
    event TokenLocker_DeployedCondition(
        address dataFeedProxy,
        ValueCondition valueCondition,
        int224 minimumValue,
        int224 maximumValue
    );
    // emit effective time of execution for ease of log collection, plus valueCondition value & value-reading oracle proxy contract (if applicable)
    event TokenLocker_Executed(
        uint256 indexed effectiveTime,
        int224 valueCondition,
        address dataFeedProxy
    );
    event TokenLocker_Expired();
    event TokenLocker_TotalAmountInEscrow();
    event TokenLocker_SellerReady();
    event TokenLocker_SellerUpdated(address newSeller);

    ///
    /// ERRORS
    ///

    error TokenLocker_AmountNotApprovedForTransferFrom();
    error TokenLocker_BalanceExceedsTotalAmount();
    error TokenLocker_DepositGreaterThanTotalAmount();
    error TokenLocker_IsExpired();
    error TokenLocker_MustDepositTotalAmount();
    error TokenLocker_NotBuyer();
    error TokenLocker_NotSeller();
    error TokenLocker_NonERC20Contract();
    error TokenLocker_NotReadyToExecute();
    error TokenLocker_OnlyOpenOffer();
    error TokenLocker_ValueConditionConflict();
    error TokenLocker_ValueOlderThanOneDay();
    error TokenLocker_ZeroAmount();

    ///
    /// FUNCTIONS
    ///

    /// @notice constructs the TokenLocker smart escrow contract. Arranger MUST verify that _tokenContract is both ERC20- and EIP2612- standard compliant and that the _dataFeedProxyAddress is accurate (if '_valueCondition' != 0), as neither address(this) nor the ChainLockerFactory.sol contract fully perform such checks.
    /// @param _refundable: whether the '_deposit' is refundable to the 'buyer' in the event escrow expires without executing
    /// @param _openOffer: whether this escrow is open to any prospective 'buyer' (revocable at seller's option). A 'buyer' assents by sending 'deposit' to address(this) after deployment
    /** @param _valueCondition: uint8 corresponding to the ValueCondition enum (passed as 0, 1, 2, or 3), which is the value contingency (via oracle) which must be satisfied for the ChainLocker to release. Options are 0, 1, 2, or 3, which
     *** respectively correspond to: none, <=, >=, or two conditions (both <= and >=, for the '_maximumValue' and '_minimumValue' params, respectively).
     *** For an **EXACT** value condition (i.e. that the returned value must equal an exact number), pass '3' (Both) and pass such exact required value as both '_minimumValue' and '_maximumValue'
     *** Passed as uint8 rather than enum for easier composability */
    /// @param _maximumValue: the maximum permitted int224 value returned from the applicable dAPI / API3 data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 2.
    /// @param _minimumValue: the minimum permitted int224 value returned from the applicable dAPI / API3 data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 1.
    /// @param _deposit: deposit amount, which must be <= '_totalAmount' (< for partial deposit, == for full deposit). If 'openOffer', msg.sender must deposit entire 'totalAmount', but if '_refundable', this amount will be refundable to the accepting address of the open offer (buyer) at expiry if not yet executed
    /// @param _totalAmount: total amount which will be deposited in this contract, ultimately intended for '_seller'
    /// @param _expirationTime: _expirationTime in seconds (Unix time), which will be compared against block.timestamp. input type(uint256).max for no expiry (not recommended, as funds will only be released upon execution or if seller rejects depositor -- refunds only process at expiry)
    /// @param _seller: the seller's address, recipient of the '_totalAmount' if the contract executes
    /// @param _buyer: the buyer's address, who will cause the '_totalAmount' to be paid to this address. Ignored if 'openOffer'
    /// @param _tokenContract: contract address for the ERC20 token used in this TokenLocker
    /// @param _dataFeedProxyAddress: contract address for the proxy that will be used to access the applicable dAPI / data feed for the '_valueCondition' query. Ignored if '_valueCondition' == 0. Person calling this method should ensure the applicable sponsor wallet is sufficiently funded for their intended purposes, if applicable.
    constructor(
        bool _refundable,
        bool _openOffer,
        uint8 _valueCondition,
        int224 _maximumValue,
        int224 _minimumValue,
        uint256 _deposit,
        uint256 _totalAmount,
        uint256 _expirationTime,
        address _seller,
        address _buyer,
        address _tokenContract,
        address _dataFeedProxyAddress
    ) payable {
        if (_deposit > _totalAmount)
            revert TokenLocker_DepositGreaterThanTotalAmount();
        if (_totalAmount == 0) revert TokenLocker_ZeroAmount();
        if (_expirationTime <= block.timestamp) revert TokenLocker_IsExpired();
        // '_valueCondition' cannot be > 3, nor can '_maximumValue' be < '_minimumValue' if _valueCondition == 3 (ValueCondition.Both)
        if (
            _valueCondition > 3 ||
            (_valueCondition == 3 && _maximumValue < _minimumValue)
        ) revert TokenLocker_ValueConditionConflict();

        // quick staticcall condition check that '_tokenContract' is at least partially ERC-20 compliant by checking if both totalSupply and balanceOf functions exist
        (bool successTotalSupply, ) = _tokenContract.staticcall(
            abi.encodeWithSignature("totalSupply()")
        );

        (bool successBalanceOf, ) = _tokenContract.staticcall(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        if (!successTotalSupply || !successBalanceOf)
            revert TokenLocker_NonERC20Contract();

        refundable = _refundable;
        openOffer = _openOffer;
        valueCondition = ValueCondition(_valueCondition);
        maximumValue = _maximumValue;
        minimumValue = _minimumValue;
        deposit = _deposit;
        totalAmount = _totalAmount;
        seller = _seller;
        buyer = _buyer;
        tokenContract = _tokenContract;
        expirationTime = _expirationTime;
        erc20 = IERC20Permit(_tokenContract);
        dataFeedProxy = IProxy(_dataFeedProxyAddress);

        emit TokenLocker_Deployed(
            _refundable,
            _openOffer,
            _deposit,
            _totalAmount,
            _expirationTime,
            _seller,
            _buyer,
            _tokenContract
        );
        // if execution is contingent upon a value or values, emit relevant information
        if (_valueCondition != 0)
            emit TokenLocker_DeployedCondition(
                _dataFeedProxyAddress,
                valueCondition,
                _minimumValue,
                _maximumValue
            );
    }

    /// @notice deposit value to 'address(this)' by permitting address(this) to safeTransferFrom '_amount' of tokens from '_depositor'
    /** @dev max '_amount limit of 'totalAmount', and if 'totalAmount' is already held or escrow has expired, revert. Updates boolean and emits event when 'deposit' reached
     ** also updates 'buyer' to msg.sender if true 'openOffer' and false 'deposited', and
     ** records amount deposited by msg.sender in case of refundability or where 'seller' rejects a 'buyer' and buyer's deposited amount is to be returned  */
    /// @param _depositor: depositor of the '_amount' of tokens, often msg.sender/originating EOA, but must == 'buyer' if this is not an open offer (!openOffer)
    /// @param _amount: amount of tokens deposited. If 'openOffer', '_amount' must == 'totalAmount'
    /// @param _deadline: deadline for usage of the permit approval signature
    /// @param v: ECDSA sig parameter
    /// @param r: ECDSA sig parameter
    /// @param s: ECDSA sig parameter
    function depositTokensWithPermit(
        address _depositor,
        uint256 _amount,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        uint256 _balance = erc20.balanceOf(address(this)) +
            _amount -
            pendingWithdraw;
        if (_balance > totalAmount)
            revert TokenLocker_BalanceExceedsTotalAmount();
        if (!openOffer && _depositor != buyer) revert TokenLocker_NotBuyer();
        if (_deadline < block.timestamp || expirationTime <= block.timestamp)
            revert TokenLocker_IsExpired();
        if (openOffer && _balance < totalAmount)
            revert TokenLocker_MustDepositTotalAmount();

        if (_balance >= deposit && !deposited) {
            // if this TokenLocker is an open offer and was not yet accepted (thus '!deposited'), make depositing address the 'buyer' and update 'deposited' to true
            if (openOffer) {
                buyer = _depositor;
                emit TokenLocker_BuyerUpdated(_depositor);
            }
            deposited = true;
            emit TokenLocker_DepositInEscrow(_depositor);
        }
        if (_balance == totalAmount) emit TokenLocker_TotalAmountInEscrow();

        emit TokenLocker_AmountReceived(_amount);
        amountDeposited[_depositor] += _amount;
        erc20.permit(_depositor, address(this), _amount, _deadline, v, r, s);
        safeTransferFrom(tokenContract, _depositor, address(this), _amount);
    }

    /// @notice deposit value to 'address(this)' via safeTransferFrom '_amount' of tokens from msg.sender; provided msg.sender has approved address(this) to transferFrom such 'amount'
    /** @dev msg.sender must have erc20.approve(address(this), _amount) prior to calling this function
     ** max '_amount limit of 'totalAmount', and if 'totalAmount' is already held or this TokenLocker has expired, revert. Updates boolean and emits event when 'deposit' reached
     ** also updates 'buyer' to msg.sender if true 'openOffer' and false 'deposited', and
     ** records amount deposited by msg.sender in case of refundability or where 'seller' rejects a 'buyer' and buyer's deposited amount is to be returned  */
    /// @param _amount: amount of tokens deposited. If 'openOffer', '_amount' must == 'totalAmount'
    function depositTokens(uint256 _amount) external nonReentrant {
        uint256 _balance = erc20.balanceOf(address(this)) +
            _amount -
            pendingWithdraw;
        if (_balance > totalAmount)
            revert TokenLocker_BalanceExceedsTotalAmount();
        if (!openOffer && msg.sender != buyer) revert TokenLocker_NotBuyer();
        if (erc20.allowance(msg.sender, address(this)) < _amount)
            revert TokenLocker_AmountNotApprovedForTransferFrom();
        if (expirationTime <= block.timestamp) revert TokenLocker_IsExpired();
        if (openOffer && _balance < totalAmount)
            revert TokenLocker_MustDepositTotalAmount();

        if (_balance >= deposit && !deposited) {
            // if this TokenLocker is an open offer and was not yet accepted (thus '!deposited'), make depositing address the 'buyer' and update 'deposited' to true
            if (openOffer) {
                buyer = msg.sender;
                emit TokenLocker_BuyerUpdated(msg.sender);
            }
            deposited = true;
            emit TokenLocker_DepositInEscrow(msg.sender);
        }
        if (_balance == totalAmount) emit TokenLocker_TotalAmountInEscrow();

        emit TokenLocker_AmountReceived(_amount);
        amountDeposited[msg.sender] += _amount;
        safeTransferFrom(tokenContract, msg.sender, address(this), _amount);
    }

    /// @notice for the current seller to designate a new recipient address
    /// @param _seller: new recipient address of seller
    function updateSeller(address _seller) external {
        if (msg.sender != seller) revert TokenLocker_NotSeller();

        if (!checkIfExpired()) {
            seller = _seller;
            emit TokenLocker_SellerUpdated(_seller);
        }
    }

    /// @notice for the current 'buyer' to designate a new buyer address
    /// @param _buyer: new address of buyer
    function updateBuyer(address _buyer) external {
        if (msg.sender != buyer) revert TokenLocker_NotBuyer();

        // transfer 'amountDeposited[buyer]' to the new '_buyer', delete the existing buyer's 'amountDeposited', and update the 'buyer' state variable
        if (!checkIfExpired()) {
            amountDeposited[_buyer] += amountDeposited[buyer];
            delete amountDeposited[buyer];

            buyer = _buyer;
            emit TokenLocker_BuyerUpdated(_buyer);
        }
    }

    /// @notice seller and buyer each call this when ready to execute; other address callers will have no effect
    /** @dev no need for an erc20.balanceOf(address(this)) check because (1) a reasonable seller will only pass 'true'
     *** if 'totalAmount' is in place, and (2) 'execute()' requires erc20.balanceOf(address(this)) - 'pendingWithdraw' >= 'totalAmount';
     *** separate conditionals in case 'buyer' == 'seller' */
    function readyToExecute() external {
        if (msg.sender == seller) {
            sellerApproved = true;
            emit TokenLocker_SellerReady();
        }
        if (msg.sender == buyer) {
            buyerApproved = true;
            emit TokenLocker_BuyerReady();
        }
    }

    /** @notice checks if both buyer and seller are ready to execute, and that any applicable 'ValueCondition' is met, and expiration has not been met;
     *** if so, this contract executes and pays seller; if not, totalAmount deposit returned to buyer (if refundable); callable by any external address **/
    /** @dev requires entire 'totalAmount' be held by address(this). If properly executes, pays seller and emits event with effective time of execution.
     *** Does not require amountDeposited[buyer] == erc20.balanceOf(address(this)) - pendingWithdraw to allow buyer to deposit from multiple addresses if desired; */
    function execute() external {
        if (
            !sellerApproved ||
            !buyerApproved ||
            erc20.balanceOf(address(this)) - pendingWithdraw < totalAmount
        ) revert TokenLocker_NotReadyToExecute();

        // delete approvals
        delete sellerApproved;
        delete buyerApproved;

        int224 _value;
        // only perform these checks if ChainLocker execution is contingent upon specified external value condition(s)
        if (valueCondition != ValueCondition.None) {
            (int224 _returnedValue, uint32 _timestamp) = dataFeedProxy.read();
            // require a value update within the last day
            if (block.timestamp - _timestamp > ONE_DAY)
                revert TokenLocker_ValueOlderThanOneDay();

            if (
                (valueCondition == ValueCondition.LessThanOrEqual &&
                    _returnedValue > maximumValue) ||
                (valueCondition == ValueCondition.GreaterThanOrEqual &&
                    _returnedValue < minimumValue) ||
                (valueCondition == ValueCondition.Both &&
                    (_returnedValue > maximumValue ||
                        _returnedValue < minimumValue))
            ) revert TokenLocker_ValueConditionConflict();
            // if no reversion, store the '_returnedValue' and proceed with execution
            else _value = _returnedValue;
        }

        if (!checkIfExpired()) {
            delete deposited;
            delete amountDeposited[buyer];

            // safeTransfer 'totalAmount' to 'seller'; note the deposit functions perform checks against depositing more than the 'totalAmount',
            // and further safeguarded by any excess balance being withdrawable by buyer after expiry in 'checkIfExpired()'
            safeTransfer(tokenContract, seller, totalAmount);

            // effective time of execution is block.timestamp upon payment to seller
            emit TokenLocker_Executed(
                block.timestamp,
                _value,
                address(dataFeedProxy)
            );
            emit TokenLocker_DepositedAmountTransferred(seller, totalAmount);
        }
    }

    /// @notice convenience function to get a USD value receipt if a dAPI / data feed proxy exists for 'tokenContract', for example for 'seller' to submit 'totalAmount' immediately after execution/release of TokenLocker
    /// @dev external call will revert if price quote is too stale or if token is not supported; event containing '_paymentId' and '_usdValue' emitted by Receipt.sol
    /// @param _tokenAmount: amount of tokens (corresponding to this TokenLocker's 'tokenContract') for which caller is seeking the total USD value receipt
    function getReceipt(
        uint256 _tokenAmount
    ) external returns (uint256 _paymentId, uint256 _usdValue) {
        return
            RECEIPT.printReceipt(tokenContract, _tokenAmount, erc20.decimals());
    }

    /// @notice for a 'seller' to reject any depositing address (including 'buyer') and cause the return of their deposited amount
    /// @param _depositor: address being rejected by 'seller' which will subsequently be able to withdraw their 'amountDeposited'
    /// @dev if !openOffer and 'seller' passes 'buyer' to this function, 'buyer' will need to call 'updateBuyer' to choose another address and re-deposit tokens.
    function rejectDepositor(address _depositor) external nonReentrant {
        if (msg.sender != seller) revert TokenLocker_NotSeller();

        uint256 _amtDeposited = amountDeposited[_depositor];
        if (_amtDeposited == 0) revert TokenLocker_ZeroAmount();

        delete amountDeposited[_depositor];
        // regardless of whether '_depositor' is 'buyer', permit them to withdraw their 'amountWithdrawable' balance
        amountWithdrawable[_depositor] += _amtDeposited;
        // update the aggregate withdrawable balance counter
        pendingWithdraw += _amtDeposited;

        // reset 'deposited' and 'buyerApproved' variables if 'seller' passed 'buyer' as '_depositor'
        if (_depositor == buyer) {
            delete deposited;
            delete buyerApproved;
            // if 'openOffer', delete the 'buyer' variable so the next valid depositor will become 'buyer'
            // we do not delete 'buyer' if !openOffer, to allow the 'buyer' to choose another address via 'updateBuyer', rather than irreversibly deleting the variable
            if (openOffer) {
                delete buyer;
                emit TokenLocker_BuyerUpdated(address(0));
            }
        }
    }

    /// @notice allows an address to withdraw 'amountWithdrawable' of tokens, such as a refundable amount post-expiry or if seller has called 'rejectDepositor' for such an address, etc.
    /// @dev used by a depositing address which 'seller' passed to 'rejectDepositor()', or if 'isExpired', used by 'buyer' and/or 'seller' (as applicable)
    function withdraw() external {
        uint256 _amt = amountWithdrawable[msg.sender];
        if (_amt == 0) revert TokenLocker_ZeroAmount();

        delete amountWithdrawable[msg.sender];
        // update the aggregate withdrawable balance counter
        pendingWithdraw -= _amt;

        safeTransfer(tokenContract, msg.sender, _amt);
        emit TokenLocker_DepositedAmountTransferred(msg.sender, _amt);
    }

    /// @notice check if expired, and if so, handle refundability by updating the 'amountWithdrawable' mapping as applicable
    /** @dev if expired, update isExpired boolean. If non-refundable, update seller's 'amountWithdrawable' to be the non-refundable deposit amount before updating buyer's mapping for the remainder.
     *** If refundable, update buyer's 'amountWithdrawable' to the entire balance. */
    /// @return isExpired
    function checkIfExpired() public nonReentrant returns (bool) {
        if (expirationTime <= block.timestamp) {
            isExpired = true;
            uint256 _balance = erc20.balanceOf(address(this)) - pendingWithdraw;
            bool _isDeposited = deposited;

            emit TokenLocker_Expired();

            delete deposited;
            delete amountDeposited[buyer];
            // update the aggregate withdrawable balance counter. Cannot overflow even if erc20.balanceOf(address(this)) == type(uint256).max because 'pendingWithdraw' is subtracted in the calculation of '_balance' above
            unchecked {
                pendingWithdraw += _balance;
            }

            if (_balance > 0) {
                // if non-refundable deposit and 'deposit' hasn't been reset to 'false' by
                // a successful 'execute()', enable 'seller' to withdraw the 'deposit' amount before enabling the remainder amount (if any) to be withdrawn by buyer
                if (!refundable && _isDeposited) {
                    amountWithdrawable[seller] = deposit;
                    amountWithdrawable[buyer] = _balance - deposit;
                } else amountWithdrawable[buyer] = _balance;
            }
        }
        return isExpired;
    }
}

interface IERC20 {
    function decimals() external view returns (uint256);
}

/// @notice Chainalysis's sanctions oracle, to prevent sanctioned addresses from calling 'deployChainLocker' and thus deploying a ChainLocker/paying deployment fee to 'receiver'
/// @author Chainalysis (see: https://go.chainalysis.com/chainalysis-oracle-docs.html)
/// @dev note this programmatic check is in addition to several token-specific sanctions checks
interface ISanctionsOracle {
    function isSanctioned(address addr) external view returns (bool);
}

/**
 * @title       o=o=o=o=o ChainLockerFactory o=o=o=o=o
 **/
/**
 * @author      o=o=o=o=o ChainLocker LLC o=o=o=o=o
 **/
/**
 * @notice ChainLocker factory contract, which enables a caller of 'deployChainLocker' to deploy a ChainLocker with their chosen parameters
 **/
contract ChainLockerFactory {
    /** @notice 'ValueCondition' enum values represent the following:
     *** 0 ('None'): no value contingency to ChainLocker execution; '_maximumValue', '_minimumValue' and '_dataFeedProxyAddress' params are ignored.
     *** 1 ('LessThanOrEqual'): the value returned from '_dataFeedProxyAddress' in the deployed ChainLocker must be <= '_maximumValue'; '_minimumValue' param is ignored
     *** 2 ('GreaterThanOrEqual'): the value returned from '_dataFeedProxyAddress' in the deployed ChainLocker must be >= '_minimumValue'; '_maximumValue' param is ignored
     *** 3 ('Both'): the value returned from '_dataFeedProxyAddress' in the deployed ChainLocker must be both <= '_maximumValue' and >= '_minimumValue'
     */
    enum ValueCondition {
        None,
        LessThanOrEqual,
        GreaterThanOrEqual,
        Both
    }

    /// @notice Chainalysis Inc.'s Arbitrum One mainnet sanctions oracle, see https://go.chainalysis.com/chainalysis-oracle-docs.html for contract addresses
    ISanctionsOracle internal constant sanctionCheck =
        ISanctionsOracle(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);

    /// @notice address which may update the fee parameters and receives any fees if 'feeSwitch' == true
    address payable public receiver;
    address payable private _pendingReceiver;

    /// @notice whether a fee is payable for using 'deployChainLocker()'
    bool public feeSwitch;

    /// @notice number by which the user's submitted '_totalAmount' is divided in order to calculate the fee, if 'feeSwitch' == true
    uint256 public feeDenominator;

    /// @notice minimum fee amount for a user calling 'deployChainLocker()' if 'feeSwitch' == true
    uint256 public minimumFee;

    ///
    /// EVENTS
    ///

    event ChainLockerFactory_Deployment(
        address indexed deployer,
        address indexed chainLockerAddress,
        address tokenContract
    );

    event ChainLockerFactory_FeePaid(uint256 feeAmount);

    event ChainLockerFactory_FeeUpdate(
        bool feeSwitch,
        uint256 newFeeDenominator,
        uint256 newMinimumFee
    );

    event ChainLockerFactory_ReceiverUpdate(address newReceiver);

    ///
    /// ERRORS
    ///

    error ChainLockerFactory_DeployerSanctioned();
    error ChainLockerFactory_FeeMissing();
    error ChainLockerFactory_OnlyReceiver();
    error ChainLockerFactory_ZeroInput();

    ///
    /// FUNCTIONS
    ///

    /** @dev enable optimization with >= 200 runs; 'msg.sender' is the initial 'receiver';
     ** constructor is payable for gas optimization purposes but msg.value should == 0. */
    constructor() payable {
        receiver = payable(msg.sender);
        // avoid a zero denominator, though there is also such a check in 'updateFee()'
        feeDenominator = 1;
    }

    /** @notice for a user to deploy their own ChainLocker, with a msg.value fee in wei if 'feeSwitch' == true. Note that electing a custom '_valueCondition' introduces
     ** execution reliance upon external oracle-fed data from the user's submitted '_dataFeedProxyAddress', but otherwise the deployed ChainLocker will be entirely immutable save for 'seller' and 'buyer' having the ability to update their own addresses. */
    /** @dev the various applicable input validations/condition checks for deployment of a ChainLocker are in the prospective contracts rather than this factory,
     ** except this function ensures the msg.sender is not sanctioned, as it may be paying a deployment fee to the 'receiver'. Fee (if 'feeSwitch' == true) is calculated on the basis of (decimal-accounted) raw amount with a hard-coded minimum, rather than introducing price oracle dependency here;
     ** '_deposit', '_seller' and '_buyer' nomenclature used for clarity (rather than payee and payor or other alternatives),
     ** though intended purpose of the ChainLocker is the user's choice; see comments above and in documentation.
     ** The constructor of each deployed ChainLocker contains more detailed event emissions */
    /// @param _refundable: whether the '_deposit' for the ChainLocker should be refundable to the applicable 'buyer' (true) or non-refundable (false) in the event the ChainLocker expires (reaches '_expirationTime') without executing.
    /// @param _openOffer: whether the ChainLocker is open to any prospective 'buyer' (with any specific 'buyer' rejectable at seller's option).
    /** @param _valueCondition: ValueCondition enum, which is the value contingency (via oracle) which must be satisfied for the ChainLocker to release.
     *** Options are none ('0'), <= ('1'), >= ('2'), or either precisely == or within two values ('3', both <= and >=, for the '_maximumValue' and '_minimumValue' params, respectively). */
    /// @param _maximumValue: the maximum returned int224 value from the applicable data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 2.
    /// @param _minimumValue: the minimum returned int224 value from the applicable data feed upon which the ChainLocker's execution is conditioned. Ignored if '_valueCondition' == 0 or _valueCondition == 1.
    /// @param _deposit: deposit amount in wei or tokens (if EthLocker or TokenLocker is deployed, respectively), which must be <= '_totalAmount' (< for partial deposit, == for full deposit).
    /// @param _totalAmount: total amount of wei or tokens (if EthLocker or TokenLocker is deployed, respectively) which will be transferred to and locked in the deployed ChainLocker.
    /// @param _expirationTime: time of the ChainLocker's expiry, provided in seconds (Unix time), which will be compared against block.timestamp.
    /// @param _seller: the contractor/payee/seller's address, as intended ultimate recipient of the locked '_totalAmount' should the ChainLocker successfully execute without expiry. Also receives '_deposit' at '_expirationTime' regardless of execution if '_refundable' == false.
    /// @param _buyer: the client/payor/buyer's address, who will cause the '_totalAmount' to be transferred to the deployed ChainLocker's address. Ignored if 'openOffer' == true.
    /// @param _tokenContract: contract address for the ERC20-compliant token used when deploying a TokenLocker; if deploying an EthLocker, pass address(0).
    /// @param _dataFeedProxyAddress: contract address for the proxy that will read the data feed for the '_valueCondition' query. Ignored if '_valueCondition' == 0. User calling this method should ensure the managed feed subscription, or applicable sponsor wallet, is sufficiently funded for their intended purposes.
    function deployChainLocker(
        bool _refundable,
        bool _openOffer,
        ValueCondition _valueCondition,
        int224 _maximumValue,
        int224 _minimumValue,
        uint256 _deposit,
        uint256 _totalAmount,
        uint256 _expirationTime,
        address payable _seller,
        address payable _buyer,
        address _tokenContract,
        address _dataFeedProxyAddress
    ) external payable returns (address) {
        if (sanctionCheck.isSanctioned(msg.sender))
            revert ChainLockerFactory_DeployerSanctioned();
        uint8 _condition = uint8(_valueCondition);

        // if 'feeSwitch' == true, calculate fee based on '_totalAmount', adjusting if ERC20 token's decimals is != 18 (if applicable)
        // if no necessary adjustment or if decimals returns 0, '_adjustedAmount' will remain == '_totalAmount'
        if (feeSwitch) {
            uint256 _fee;
            uint256 _adjustedAmount = _totalAmount;
            if (_tokenContract != address(0)) {
                uint256 _decimals = IERC20(_tokenContract).decimals();
                // if more than 18 decimals, divide the total amount by the excess decimal places; subtraction will not underflow due to condition check
                if (_decimals > 18) {
                    unchecked {
                        _adjustedAmount = (_totalAmount /
                            10 ** (_decimals - 18));
                    }
                }
                // if less than 18 decimals, multiple the total amount by the difference in decimal places
                else if (_decimals < 18) {
                    _adjustedAmount = _totalAmount * (10 ** (18 - _decimals));
                }
            }
            // 'feeDenominator' cannot == 0, and '_adjustedAmount' cannot be > max uint256 || < 0, no overflow or underflow risk
            unchecked {
                _fee = _adjustedAmount / feeDenominator;
            }
            if (_fee < minimumFee) _fee = minimumFee;

            // revert if the 'msg.value' is insufficient to cover the fee, or if the transfer of the fee to 'receiver' fails
            (bool success, ) = receiver.call{value: msg.value}("");
            if (msg.value < _fee || !success)
                revert ChainLockerFactory_FeeMissing();
            emit ChainLockerFactory_FeePaid(msg.value);
        }

        if (_tokenContract == address(0)) {
            EthLocker _newEthLocker = new EthLocker(
                _refundable,
                _openOffer,
                _condition,
                _maximumValue,
                _minimumValue,
                _deposit,
                _totalAmount,
                _expirationTime,
                _seller,
                _buyer,
                _dataFeedProxyAddress
            );
            emit ChainLockerFactory_Deployment(
                msg.sender,
                address(_newEthLocker),
                address(0)
            );
            return address(_newEthLocker);
        } else {
            TokenLocker _newTokenLocker = new TokenLocker(
                _refundable,
                _openOffer,
                _condition,
                _maximumValue,
                _minimumValue,
                _deposit,
                _totalAmount,
                _expirationTime,
                _seller,
                _buyer,
                _tokenContract,
                _dataFeedProxyAddress
            );
            emit ChainLockerFactory_Deployment(
                msg.sender,
                address(_newTokenLocker),
                _tokenContract
            );
            return address(_newTokenLocker);
        }
    }

    /// @notice allows the receiver to toggle the fee switch, and update the 'feeDenominator' and 'minimumFee'
    /// @param _feeSwitch: boolean fee toggle for 'deployChainLocker()' (true == fees on, false == no fees)
    /// @param _newFeeDenominator: nonzero number by which a user's submitted '_totalAmount' will be divided in order to calculate the fee, updating the 'feeDenominator' variable; 10e14 corresponds to a 0.1% fee, 10e15 for 1%, etc. (fee calculations in 'deployChainlocker()' are 18 decimals)
    /// @param _newMinimumFee: minimum fee for a user's call to 'deployChainLocker()', which must be > 0
    function updateFee(
        bool _feeSwitch,
        uint256 _newFeeDenominator,
        uint256 _newMinimumFee
    ) external {
        if (msg.sender != receiver) revert ChainLockerFactory_OnlyReceiver();
        if (_newFeeDenominator == 0) revert ChainLockerFactory_ZeroInput();
        feeSwitch = _feeSwitch;
        feeDenominator = _newFeeDenominator;
        minimumFee = _newMinimumFee;

        emit ChainLockerFactory_FeeUpdate(
            _feeSwitch,
            _newFeeDenominator,
            _newMinimumFee
        );
    }

    /// @notice allows the 'receiver' to replace their address. First step in two-step address change.
    /// @dev use care in updating 'receiver' to a contract with complex receive() function due to the 'call' usage in this contract
    /// @param _newReceiver: new payable address for pending 'receiver', who must accept the role by calling 'acceptReceiverRole'
    function updateReceiver(address payable _newReceiver) external {
        if (msg.sender != receiver) revert ChainLockerFactory_OnlyReceiver();
        _pendingReceiver = _newReceiver;
    }

    /// @notice for the pending new receiver to accept the role transfer.
    /// @dev access restricted to the address stored as '_pendingReceiver' to accept the two-step change. Transfers 'receiver' role to the caller and deletes '_pendingReceiver' to reset.
    function acceptReceiverRole() external {
        address payable _sender = payable(msg.sender);
        if (_sender != _pendingReceiver) {
            revert ChainLockerFactory_OnlyReceiver();
        }
        delete _pendingReceiver;
        receiver = _sender;
        emit ChainLockerFactory_ReceiverUpdate(_sender);
    }
}