// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IFeeConverter} from "./interfaces/IFeeConverter.sol";

error StreamerMustBuyFirstPass();
error CannotSellLastPass();
error InsufficientPayment();
error InsufficientPasses();
error FundsTransferFailed();
error NotLiveYet();
error NotUnlockedYet();
error UnlocksTooSoon();

contract SankoTVPasses is Ownable {
    struct PackedArgs {
        uint96 amount;
        address addy;
    }

    struct Fees {
        uint256 streamerFee;
        uint256 ethFee;
        uint256 dmtFee;
        uint256 referralFee;
    }

    struct PassesBalance {
        uint96 unlocked;
        uint96 locked;
        uint64 unlocksAt;
    }

    address public protocolFeeDestination;
    IFeeConverter public feeConverter;
    uint256 public ethFeePercent;
    uint256 public dmtFeePercent;
    uint256 public streamerFeePercent;
    uint256 public referralFeePercent;

    bool public live;

    event Trade(
        address indexed trader,
        address indexed streamer,
        address indexed referrer,
        bool isBuy,
        uint256 passAmount,
        uint256 ethAmount,
        uint256 protocolEthAmount,
        uint256 streamerEthAmount,
        uint256 referralEthAmount,
        uint256 supply
    );

    event Locked(
        address indexed trader,
        address indexed streamer,
        uint256 passAmount,
        uint256 unlocksAt
    );

    event Unlocked(
        address indexed trader, address indexed streamer, uint256 passAmount
    );

    mapping(address streamer => mapping(address fan => PassesBalance balance))
        public passesBalance;

    mapping(address streamer => uint256 supply) public passesSupply;

    modifier whenLive() {
        if (!live) {
            revert NotLiveYet();
        }
        _;
    }

    constructor() {
        _initializeOwner(msg.sender);
    }

    function setLive() external onlyOwner {
        live = true;
    }

    function setFeeDestination(address _feeDestination) external onlyOwner {
        protocolFeeDestination = _feeDestination;
    }

    function setEthFeePercent(uint256 _feePercent) external onlyOwner {
        ethFeePercent = _feePercent;
    }

    function setDmtFeePercent(uint256 _feePercent) external onlyOwner {
        dmtFeePercent = _feePercent;
    }

    function setFeeConverter(IFeeConverter _feeConverter) external onlyOwner {
        feeConverter = _feeConverter;
    }

    function setStreamerFeePercent(uint256 _feePercent) external onlyOwner {
        streamerFeePercent = _feePercent;
    }

    function setReferralFeePercent(uint256 _feePercent) external onlyOwner {
        referralFeePercent = _feePercent;
    }

    function buyPasses(address streamer, bytes32 packedArgs)
        external
        payable
        whenLive
    {
        PackedArgs memory args = unpackArgs(packedArgs);
        uint96 amount = args.amount;
        address referrer = args.addy;

        uint256 supply = passesSupply[streamer];
        if (supply == 0 && msg.sender != streamer) {
            revert StreamerMustBuyFirstPass();
        }

        uint256 price = getPrice(supply, amount);
        Fees memory fees = getFees(price, referrer);

        uint256 totalCost = price + fees.ethFee + fees.dmtFee + fees.streamerFee
            + fees.referralFee;

        if (msg.value < totalCost) {
            revert InsufficientPayment();
        }

        passesBalance[streamer][msg.sender].unlocked += amount;
        passesSupply[streamer] = supply + amount;
        emit Trade(
            msg.sender,
            streamer,
            referrer,
            true,
            amount,
            price,
            fees.ethFee + fees.dmtFee,
            fees.streamerFee,
            fees.referralFee,
            supply + amount
        );

        (bool streamerSend,) = streamer.call{value: fees.streamerFee}("");
        (bool protocolSend,) =
            protocolFeeDestination.call{value: fees.ethFee}("");

        bool feeSend = true;
        if (fees.dmtFee > 0) {
            feeSend = feeConverter.convertFees{value: fees.dmtFee}();
        }

        bool referrerSend = true;
        if (referrer != address(0)) {
            (referrerSend,) = referrer.call{value: fees.referralFee}("");
        }

        if (!(streamerSend && protocolSend && feeSend && referrerSend)) {
            revert FundsTransferFailed();
        }
    }

    function sellPasses(address streamer, bytes32 packedArgs)
        external
        payable
        whenLive
    {
        PackedArgs memory args = unpackArgs(packedArgs);
        uint96 amount = args.amount;
        address referrer = args.addy;

        uint256 supply = passesSupply[streamer];
        PassesBalance storage sellerBalance =
            passesBalance[streamer][msg.sender];

        if (sellerBalance.unlocked < amount) {
            revert InsufficientPasses();
        }
        if (supply <= amount) {
            revert CannotSellLastPass();
        }

        uint256 price = getPrice(supply - amount, amount);
        Fees memory fees = getFees(price, referrer);

        sellerBalance.unlocked -= amount;
        passesSupply[streamer] = supply - amount;
        emit Trade(
            msg.sender,
            streamer,
            referrer,
            false,
            amount,
            price,
            fees.ethFee + fees.dmtFee,
            fees.streamerFee,
            fees.referralFee,
            supply - amount
        );

        (bool sellerSend,) = msg.sender.call{
            value: price
                - (fees.ethFee + fees.dmtFee + fees.streamerFee + fees.referralFee)
        }("");

        (bool streamerSend,) = streamer.call{value: fees.streamerFee}("");
        (bool protocolSend,) =
            protocolFeeDestination.call{value: fees.ethFee}("");

        bool feeSend = true;
        if (fees.dmtFee > 0) {
            feeSend = feeConverter.convertFees{value: fees.dmtFee}();
        }

        bool referrerSend = true;
        if (referrer != address(0)) {
            (referrerSend,) = referrer.call{value: fees.referralFee}("");
        }

        if (
            !(
                sellerSend && streamerSend && protocolSend && feeSend
                    && referrerSend
            )
        ) {
            revert FundsTransferFailed();
        }
    }

    function lockPasses(bytes32 packedArgs, uint256 lockTimeSeconds)
        external
        whenLive
    {
        PackedArgs memory args = unpackArgs(packedArgs);
        uint96 amount = args.amount;
        address streamer = args.addy;

        PassesBalance memory balance = passesBalance[streamer][msg.sender];
        if (balance.unlocked < amount) {
            revert InsufficientPasses();
        }

        uint64 newUnlocksAt = uint64(block.timestamp + lockTimeSeconds);
        uint64 oldUnlocksAt = balance.unlocksAt;
        if (newUnlocksAt < oldUnlocksAt) {
            revert UnlocksTooSoon();
        }

        passesBalance[streamer][msg.sender] = PassesBalance({
            locked: balance.locked += amount,
            unlocked: balance.unlocked -= amount,
            unlocksAt: newUnlocksAt
        });

        emit Locked(msg.sender, streamer, amount, newUnlocksAt);
    }

    function unlockPasses(address streamer) external whenLive {
        PassesBalance memory balance = passesBalance[streamer][msg.sender];
        if (balance.unlocksAt > block.timestamp) {
            revert NotUnlockedYet();
        }

        if (balance.locked == 0) {
            revert InsufficientPasses();
        }

        passesBalance[streamer][msg.sender] = PassesBalance({
            locked: 0,
            unlocked: balance.unlocked + balance.locked,
            unlocksAt: 0
        });

        emit Unlocked(msg.sender, streamer, balance.locked);
    }

    function getPrice(uint256 supply, uint256 amount)
        public
        pure
        returns (uint256)
    {
        uint256 x1 = priceCurve(supply);
        uint256 x2 = priceCurve(supply + amount);

        return (x2 - x1) * 1 ether / 16_000;
    }

    function priceCurve(uint256 x) public pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        return (x - 1) * x * (2 * (x - 1) + 1) / 6;
    }

    function getFees(uint256 price, address referrer)
        public
        view
        returns (Fees memory)
    {
        uint256 ethFee;
        uint256 dmtFee;
        uint256 referralFee;
        if (referrer != address(0)) {
            referralFee = price * referralFeePercent / 1 ether;
            ethFee = price * ethFeePercent / 1 ether;
            dmtFee = price * dmtFeePercent / 1 ether;
        } else {
            referralFee = 0;
            uint256 referralFeePercentShare =
                dmtFeePercent > 0 ? referralFeePercent / 2 : referralFeePercent;
            ethFee = price * (ethFeePercent + referralFeePercentShare) / 1 ether;
            dmtFee = dmtFeePercent > 0
                ? price * (dmtFeePercent + referralFeePercentShare) / 1 ether
                : 0;
        }
        uint256 streamerFee = price * streamerFeePercent / 1 ether;
        return Fees({
            streamerFee: streamerFee,
            ethFee: ethFee,
            dmtFee: dmtFee,
            referralFee: referralFee
        });
    }

    function getBuyPrice(address streamer, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(passesSupply[streamer], amount);
    }

    function getSellPrice(address streamer, uint256 amount)
        public
        view
        returns (uint256)
    {
        return getPrice(passesSupply[streamer] - amount, amount);
    }

    function getBuyPriceAfterFee(address streamer, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 price = getBuyPrice(streamer, amount);
        Fees memory fees = getFees(price, address(0));
        return price + fees.ethFee + fees.dmtFee + fees.streamerFee
            + fees.referralFee;
    }

    function getSellPriceAfterFee(address streamer, uint256 amount)
        external
        view
        returns (uint256)
    {
        uint256 price = getSellPrice(streamer, amount);
        Fees memory fees = getFees(price, address(0));
        return price - fees.ethFee + fees.dmtFee + fees.streamerFee
            + fees.referralFee;
    }

    function unpackArgs(bytes32 args)
        private
        pure
        returns (PackedArgs memory)
    {
        // Extract the amount (first 12 bytes)
        uint96 amount = uint96(uint256(args) >> (160));

        // Extract the referrer or streamer address (last 20 bytes)
        address addy = address(uint160(uint256(args)));

        return PackedArgs({amount: amount, addy: addy});
    }

    function packArgs(PackedArgs calldata args) public pure returns (bytes32) {
        return bytes32(
            (uint256(uint96(args.amount)) << 160) | uint256(uint160(args.addy))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Simple single owner authorization mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/auth/Ownable.sol)
///
/// @dev Note:
/// This implementation does NOT auto-initialize the owner to `msg.sender`.
/// You MUST call the `_initializeOwner` in the constructor / initializer.
///
/// While the ownable portion follows
/// [EIP-173](https://eips.ethereum.org/EIPS/eip-173) for compatibility,
/// the nomenclature for the 2-step ownership handover may be unique to this codebase.
abstract contract Ownable {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The caller is not authorized to call the function.
    error Unauthorized();

    /// @dev The `newOwner` cannot be the zero address.
    error NewOwnerIsZeroAddress();

    /// @dev The `pendingOwner` does not have a valid handover request.
    error NoHandoverRequest();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           EVENTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ownership is transferred from `oldOwner` to `newOwner`.
    /// This event is intentionally kept the same as OpenZeppelin's Ownable to be
    /// compatible with indexers and [EIP-173](https://eips.ethereum.org/EIPS/eip-173),
    /// despite it not being as lightweight as a single argument event.
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    /// @dev An ownership handover to `pendingOwner` has been requested.
    event OwnershipHandoverRequested(address indexed pendingOwner);

    /// @dev The ownership handover to `pendingOwner` has been canceled.
    event OwnershipHandoverCanceled(address indexed pendingOwner);

    /// @dev `keccak256(bytes("OwnershipTransferred(address,address)"))`.
    uint256 private constant _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE =
        0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0;

    /// @dev `keccak256(bytes("OwnershipHandoverRequested(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE =
        0xdbf36a107da19e49527a7176a1babf963b4b0ff8cde35ee35d6cd8f1f9ac7e1d;

    /// @dev `keccak256(bytes("OwnershipHandoverCanceled(address)"))`.
    uint256 private constant _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE =
        0xfa7b8eab7da67f412cc9575ed43464468f9bfbae89d1675917346ca6d8fe3c92;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The owner slot is given by: `not(_OWNER_SLOT_NOT)`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    uint256 private constant _OWNER_SLOT_NOT = 0x8b78c6d8;

    /// The ownership handover slot of `newOwner` is given by:
    /// ```
    ///     mstore(0x00, or(shl(96, user), _HANDOVER_SLOT_SEED))
    ///     let handoverSlot := keccak256(0x00, 0x20)
    /// ```
    /// It stores the expiry timestamp of the two-step ownership handover.
    uint256 private constant _HANDOVER_SLOT_SEED = 0x389a75e1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     INTERNAL FUNCTIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Store the new value.
            sstore(not(_OWNER_SLOT_NOT), newOwner)
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        /// @solidity memory-safe-assembly
        assembly {
            let ownerSlot := not(_OWNER_SLOT_NOT)
            // Clean the upper 96 bits.
            newOwner := shr(96, shl(96, newOwner))
            // Emit the {OwnershipTransferred} event.
            log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
            // Store the new value.
            sstore(ownerSlot, newOwner)
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(not(_OWNER_SLOT_NOT)))) {
                mstore(0x00, 0x82b42900) // `Unauthorized()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns how long a two-step ownership handover is valid for in seconds.
    /// Override to return a different value if needed.
    /// Made internal to conserve bytecode. Wrap it in a public function if needed.
    function _ownershipHandoverValidFor() internal view virtual returns (uint64) {
        return 48 * 3600;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  PUBLIC UPDATE FUNCTIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Allows the owner to transfer the ownership to `newOwner`.
    function transferOwnership(address newOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(shl(96, newOwner)) {
                mstore(0x00, 0x7448fbae) // `NewOwnerIsZeroAddress()`.
                revert(0x1c, 0x04)
            }
        }
        _setOwner(newOwner);
    }

    /// @dev Allows the owner to renounce their ownership.
    function renounceOwnership() public payable virtual onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Request a two-step ownership handover to the caller.
    /// The request will automatically expire in 48 hours (172800 seconds) by default.
    function requestOwnershipHandover() public payable virtual {
        unchecked {
            uint256 expires = block.timestamp + _ownershipHandoverValidFor();
            /// @solidity memory-safe-assembly
            assembly {
                // Compute and set the handover slot to `expires`.
                mstore(0x0c, _HANDOVER_SLOT_SEED)
                mstore(0x00, caller())
                sstore(keccak256(0x0c, 0x20), expires)
                // Emit the {OwnershipHandoverRequested} event.
                log2(0, 0, _OWNERSHIP_HANDOVER_REQUESTED_EVENT_SIGNATURE, caller())
            }
        }
    }

    /// @dev Cancels the two-step ownership handover to the caller, if any.
    function cancelOwnershipHandover() public payable virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, caller())
            sstore(keccak256(0x0c, 0x20), 0)
            // Emit the {OwnershipHandoverCanceled} event.
            log2(0, 0, _OWNERSHIP_HANDOVER_CANCELED_EVENT_SIGNATURE, caller())
        }
    }

    /// @dev Allows the owner to complete the two-step ownership handover to `pendingOwner`.
    /// Reverts if there is no existing ownership handover requested by `pendingOwner`.
    function completeOwnershipHandover(address pendingOwner) public payable virtual onlyOwner {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and set the handover slot to 0.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            let handoverSlot := keccak256(0x0c, 0x20)
            // If the handover does not exist, or has expired.
            if gt(timestamp(), sload(handoverSlot)) {
                mstore(0x00, 0x6f5e8818) // `NoHandoverRequest()`.
                revert(0x1c, 0x04)
            }
            // Set the handover slot to 0.
            sstore(handoverSlot, 0)
        }
        _setOwner(pendingOwner);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   PUBLIC READ FUNCTIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the owner of the contract.
    function owner() public view virtual returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := sload(not(_OWNER_SLOT_NOT))
        }
    }

    /// @dev Returns the expiry timestamp for the two-step ownership handover to `pendingOwner`.
    function ownershipHandoverExpiresAt(address pendingOwner)
        public
        view
        virtual
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the handover slot.
            mstore(0x0c, _HANDOVER_SLOT_SEED)
            mstore(0x00, pendingOwner)
            // Load the handover slot.
            result := sload(keccak256(0x0c, 0x20))
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MODIFIERS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Marks a function as only callable by the owner.
    modifier onlyOwner() virtual {
        _checkOwner();
        _;
    }
}

// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.21;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {ICamelotRouter} from "@camelot/interfaces/ICamelotRouter.sol";

interface IFeeConverter {
    function setFeeToken(address _feeToken) external;
    function setRouter(address _router) external;
    function setUsdc(address _usdc) external;

    // Withdraw collected oracle fees to a recipient
    function withdrawFees() external;
    function convertFees() external payable returns (bool);
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

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface ICamelotRouter is IUniswapV2Router01 {
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
    address referrer,
    uint deadline
  ) external;

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external payable;

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;


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

  function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

}