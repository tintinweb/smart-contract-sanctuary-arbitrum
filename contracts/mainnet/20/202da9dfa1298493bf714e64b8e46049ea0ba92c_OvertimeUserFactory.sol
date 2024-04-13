// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

import { Ownable } from "solady/auth/Ownable.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import "solady/utils/LibClone.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { IOvertimeUserFactory } from "../interfaces/IOvertimeUserFactory.sol";
import { IOvertimeUser } from "../interfaces/IOvertimeUser.sol";
import { ISportsAMM } from "../interfaces/ISportsAMM.sol";
import { IParlayMarketsAMM } from "../interfaces/IParlayMarketsAMM.sol";
import { ReentrancyGuard } from "solady/utils/ReentrancyGuard.sol";
import { ISportPositionalMarketManager } from "../interfaces/ISportPositionalMarketManager.sol";

contract OvertimeUserFactory is IOvertimeUserFactory, Ownable, ReentrancyGuard {
    address public mastercopy;

    address public feeManager;
    address public sportsAMM;
    address public parlayMarketsAMM;
    address public overtimeReferrer;
    address public susd;
    address public weth;

    mapping(address => uint8) private deployed;

    uint256 public version;
    mapping(address => uint256) public parametersVersion;

    // Constructor
    constructor(address _mastercopy, address _owner) {
        mastercopy = _mastercopy;
        _initializeOwner(_owner);
    }

    function setMastercopy(address _mastercopy) external onlyOwner {
        if (mastercopy != address(0)) revert MastercopyInitialized();
        mastercopy = _mastercopy;
    }

    function createUser(address referrer) external returns (address clone) {
        if (version == 0) revert ParametersNotSet();
        bytes32 p = _getParameters(msg.sender);
        if (deployed[msg.sender] != 0) revert AlreadyInitialized();

        clone = LibClone.cloneDeterministic(mastercopy, p);

        IFeeManager(feeManager).setReferrer(referrer, msg.sender);
        IOvertimeUser ot = IOvertimeUser(clone);
        ot.initialize(msg.sender);
        ot.setVariables(sportsAMM, parlayMarketsAMM, feeManager, susd, weth, overtimeReferrer);

        deployed[msg.sender] = 1;
        deployed[clone] = 2;
        parametersVersion[msg.sender] = version;
        parametersVersion[clone] = version;

        emit OvertimeUserCreated(clone, msg.sender);
    }

    function getUser(address _owner) public view returns (address wallet) {
        bytes32 p = _getParameters(_owner);
        wallet = LibClone.predictDeterministicAddress(mastercopy, p, address(this));
    }

    function isDeployed(address wallet) external view returns (bool) {
        return deployed[wallet] != 0;
    }

    function isWrapper(address wallet) external view returns (bool) {
        return deployed[wallet] == 2;
    }

    function resetVariables() external {
        _resetVariables();
    }

    function _resetVariables() internal {
        IOvertimeUser(getUser(msg.sender)).setVariables(
            sportsAMM, parlayMarketsAMM, feeManager, susd, weth, overtimeReferrer
        );
        parametersVersion[msg.sender] = version;
        parametersVersion[getUser(msg.sender)] = version;
    }

    function setFactoryVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external
        onlyOwner
    {
        sportsAMM = _sportsAMM;
        parlayMarketsAMM = _parlayMarketsAMM;
        feeManager = _feeManager;
        overtimeReferrer = _overtimeReferrer;
        susd = _susd;
        weth = _weth;
        version += 1;
    }

    function _getParameters(address owner) internal view returns (bytes32) {
        return keccak256(abi.encode(address(this), owner));
    }

    function buySingle(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        if (parametersVersion[msg.sender] != version) _resetVariables();

        uint256 quoteAmount =
            ISportsAMM(payable(sportsAMM)).buyFromAmmQuote(market, ISportsAMM.Position(position), payout);

        if ((quoteAmount * 1 ether) / desiredAmount > (1 ether + additionalSlippage)) revert Slippage();
        SafeTransferLib.safeTransferFrom(susd, msg.sender, address(user), quoteAmount);
        user.buySingle(market, position, payout, quoteAmount);
        if (referrer == msg.sender) referrer = address(0);
        IFeeManager(feeManager).setBetInfo(msg.sender, referrer, market, desiredAmount, position);
    }

    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        if (parametersVersion[msg.sender] != version) _resetVariables();

        (uint256 collateralQuote, uint256 sUSDtoPay) = ISportsAMM(payable(sportsAMM))
            .buyFromAmmQuoteWithDifferentCollateral(market, ISportsAMM.Position(position), payout, collateral);

        if ((collateralQuote * 1 ether) / (desiredAmount) > (1 ether + additionalSlippage)) revert Slippage();

        SafeTransferLib.safeTransferFrom(collateral, msg.sender, address(user), collateralQuote);

        user.buySingleWithDifferentCollateral(market, position, payout, collateralQuote, collateral);
        if (referrer == msg.sender) referrer = address(0);
        IFeeManager(feeManager).setBetInfo(msg.sender, referrer, market, sUSDtoPay, position);
    }

    function buyParlay(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        IParlayMarketsAMM parlayMarketsAMM_ = IParlayMarketsAMM(payable(parlayMarketsAMM));

        (uint256 susdAfterFees, uint256 totalAmount,,,,,) =
            parlayMarketsAMM_.buyQuoteFromParlay(sportMarkets, positions, desiredAmount);

        uint256 timestamp =
            block.timestamp + ISportPositionalMarketManager(parlayMarketsAMM_.sportManager()).expiryDuration();

        if (((1 ether * expectedPayout) / totalAmount) > (1 ether + additionalSlippage)) revert Slippage();

        SafeTransferLib.safeTransferFrom(susd, msg.sender, address(user), desiredAmount);

        user.buyParlay(sportMarkets, positions, totalAmount, desiredAmount);
        if (referrer == msg.sender) referrer = address(0);
        _setParlayInfo(timestamp, totalAmount, susdAfterFees, referrer);
    }

    function buyParlayWithDifferentCollateral(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));

        IParlayMarketsAMM parlayMarketsAMM_ = IParlayMarketsAMM(payable(parlayMarketsAMM));

        (uint256 collateralQuote, uint256 sUSDAfterFees, uint256 totalBuyAmount,,,,) = parlayMarketsAMM_
            .buyQuoteFromParlayWithDifferentCollateral(sportMarkets, positions, desiredAmount, collateral);

        uint256 timestamp =
            block.timestamp + ISportPositionalMarketManager(parlayMarketsAMM_.sportManager()).expiryDuration();

        if (((1 ether * expectedPayout) / totalBuyAmount) > (1 ether + additionalSlippage)) revert Slippage();

        SafeTransferLib.safeTransferFrom(collateral, msg.sender, address(user), collateralQuote);

        user.buyParlayWithDifferentCollateral(
            sportMarkets, positions, totalBuyAmount, desiredAmount, collateralQuote, collateral
        );

        if (referrer == msg.sender) referrer = address(0);
        _setParlayInfo(timestamp, totalBuyAmount, sUSDAfterFees, referrer);
    }

    function exerciseSingle(address market) external nonReentrant {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        (uint256 fee, address referrer) = user.exerciseSingle(market);
        IFeeManager(feeManager).collectFee(fee, msg.sender, referrer, susd);
    }

    function exerciseSingleWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        (uint256 fee, address referrer) = user.exerciseSingleWithDifferentCollateral(market, collateral, toEth);
        IFeeManager(feeManager).collectFee(fee, msg.sender, referrer, collateral);
    }

    function exerciseParlay(address market) external nonReentrant {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        (uint256 fee, address referrer) = user.exerciseParlay(market);
        IFeeManager(feeManager).collectFee(fee, msg.sender, referrer, susd);
    }

    function exerciseParlayWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        nonReentrant
    {
        IOvertimeUser user = IOvertimeUser(getUser(msg.sender));
        (uint256 fee, address referrer) = user.exerciseParlayWithDifferentCollateral(market, collateral, toEth);
        IFeeManager(feeManager).collectFee(fee, msg.sender, referrer, collateral);
    }

    function _setParlayInfo(uint256 expiry, uint256 amount, uint256 sUSDPaid, address referrer) internal {
        bytes32 refHash = IFeeManager(feeManager).getParlayHash(expiry, amount, sUSDPaid);
        IFeeManager(feeManager).setParlayInfo(msg.sender, referrer, refHash, sUSDPaid);
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

    /// @dev Cannot double-initialize.
    error AlreadyInitialized();

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

    /// @dev The owner slot is given by:
    /// `bytes32(~uint256(uint32(bytes4(keccak256("_OWNER_SLOT_NOT")))))`.
    /// It is intentionally chosen to be a high value
    /// to avoid collision with lower slots.
    /// The choice of manual storage layout is to enable compatibility
    /// with both regular and upgradeable contracts.
    bytes32 internal constant _OWNER_SLOT =
        0xffffffffffffffffffffffffffffffffffffffffffffffffffffffff74873927;

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

    /// @dev Override to return true to make `_initializeOwner` prevent double-initialization.
    function _guardInitializeOwner() internal pure virtual returns (bool guard) {}

    /// @dev Initializes the owner directly without authorization guard.
    /// This function must be called upon initialization,
    /// regardless of whether the contract is upgradeable or not.
    /// This is to enable generalization to both regular and upgradeable contracts,
    /// and to save gas in case the initial owner is not the caller.
    /// For performance reasons, this function will not check if there
    /// is an existing owner.
    function _initializeOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                if sload(ownerSlot) {
                    mstore(0x00, 0x0dc149f0) // `AlreadyInitialized()`.
                    revert(0x1c, 0x04)
                }
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Store the new value.
                sstore(_OWNER_SLOT, newOwner)
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, 0, newOwner)
            }
        }
    }

    /// @dev Sets the owner directly without authorization guard.
    function _setOwner(address newOwner) internal virtual {
        if (_guardInitializeOwner()) {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, or(newOwner, shl(255, iszero(newOwner))))
            }
        } else {
            /// @solidity memory-safe-assembly
            assembly {
                let ownerSlot := _OWNER_SLOT
                // Clean the upper 96 bits.
                newOwner := shr(96, shl(96, newOwner))
                // Emit the {OwnershipTransferred} event.
                log3(0, 0, _OWNERSHIP_TRANSFERRED_EVENT_SIGNATURE, sload(ownerSlot), newOwner)
                // Store the new value.
                sstore(ownerSlot, newOwner)
            }
        }
    }

    /// @dev Throws if the sender is not the owner.
    function _checkOwner() internal view virtual {
        /// @solidity memory-safe-assembly
        assembly {
            // If the caller is not the stored owner, revert.
            if iszero(eq(caller(), sload(_OWNER_SLOT))) {
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
            result := sload(_OWNER_SLOT)
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Minimal proxy library.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
/// @author Minimal proxy by 0age (https://github.com/0age)
/// @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
/// (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
/// @author Minimal ERC1967 proxy by jtriley-eth (https://github.com/jtriley-eth/minimum-viable-proxy)
///
/// @dev Minimal proxy:
/// Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
/// it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
/// which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
///
/// @dev Minimal proxy (PUSH0 variant):
/// This is a new minimal proxy that uses the PUSH0 opcode introduced during Shanghai.
/// It is optimized first for minimal runtime gas, then for minimal bytecode.
/// The PUSH0 clone functions are intentionally postfixed with a jarring "_PUSH0" as
/// many EVM chains may not support the PUSH0 opcode in the early months after Shanghai.
/// Please use with caution.
///
/// @dev Clones with immutable args (CWIA):
/// The implementation of CWIA here implements a `receive()` method that emits the
/// `ReceiveETH(uint256)` event. This skips the `DELEGATECALL` when there is no calldata,
/// enabling us to accept hard gas-capped `sends` & `transfers` for maximum backwards
/// composability. The minimal proxy implementation does not offer this feature.
///
/// @dev Minimal ERC1967 proxy:
/// An minimal ERC1967 proxy, intended to be upgraded with UUPS.
/// This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.
library LibClone {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the clone.
    error DeploymentFailed();

    /// @dev The salt must start with either the zero address or `by`.
    error SaltDoesNotStartWith();

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  MINIMAL PROXY OPERATIONS                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a clone of `implementation`.
    function clone(address implementation) internal returns (address instance) {
        instance = clone(0, implementation);
    }

    /// @dev Deploys a clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 3d         | RETURNDATASIZE    | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (44 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | 0                      |                       |
             * 3d      | RETURNDATASIZE | 0 0                    |                       |
             * 3d      | RETURNDATASIZE | 0 0 0                  |                       |
             * 3d      | RETURNDATASIZE | 0 0 0 0                |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            |                       |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          |                       |
             * 3d      | RETURNDATASIZE | 0 0 cds 0 0 0 0        |                       |
             * 37      | CALLDATACOPY   | 0 0 0 0                | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0 0 0            | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | 0 cds 0 0 0 0          | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0 0 0     | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0 0 0 | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success 0 0            | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success 0 0        | [0..cds): calldata    |
             * 3d      | RETURNDATASIZE | rds rds success 0 0    | [0..cds): calldata    |
             * 93      | SWAP4          | 0 rds success 0 rds    | [0..cds): calldata    |
             * 80      | DUP1           | 0 0 rds success 0 rds  | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success 0 rds          | [0..rds): returndata  |
             *                                                                           |
             * 60 0x2a | PUSH1 0x2a     | 0x2a success 0 rds     | [0..rds): returndata  |
             * 57      | JUMPI          | 0 rds                  | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create(value, 0x0c, 0x35)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    function cloneDeterministic(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            instance := create2(value, 0x0c, 0x35, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the clone of `implementation`.
    function initCode(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(add(result, 0x40), 0x5af43d3d93803e602a57fd5bf30000000000000000000000)
            mstore(add(result, 0x28), implementation)
            mstore(add(result, 0x14), 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            mstore(result, 0x35) // Store the length.
            mstore(0x40, add(result, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x21, 0x5af43d3d93803e602a57fd5bf3)
            mstore(0x14, implementation)
            mstore(0x00, 0x602c3d8160093d39f33d3d3d3d363d3d37363d73)
            hash := keccak256(0x0c, 0x35)
            mstore(0x21, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*          MINIMAL PROXY OPERATIONS (PUSH0 VARIANT)          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Deploys a PUSH0 clone of `implementation`.
    function clone_PUSH0(address implementation) internal returns (address instance) {
        instance = clone_PUSH0(0, implementation);
    }

    /// @dev Deploys a PUSH0 clone of `implementation`.
    /// Deposits `value` ETH during deployment.
    function clone_PUSH0(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * --------------------------------------------------------------------------+
             * CREATION (9 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                       |
             * --------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize     | r         |                              |
             * 5f         | PUSH0             | 0 r       |                              |
             * 81         | DUP2              | r 0 r     |                              |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                              |
             * 5f         | PUSH0             | 0 o r 0 r |                              |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code   |
             * f3         | RETURN            |           | [0..runSize): runtime code   |
             * --------------------------------------------------------------------------|
             * RUNTIME (45 bytes)                                                        |
             * --------------------------------------------------------------------------|
             * Opcode  | Mnemonic       | Stack                  | Memory                |
             * --------------------------------------------------------------------------|
             *                                                                           |
             * ::: keep some values in stack ::::::::::::::::::::::::::::::::::::::::::: |
             * 5f      | PUSH0          | 0                      |                       |
             * 5f      | PUSH0          | 0 0                    |                       |
             *                                                                           |
             * ::: copy calldata to memory ::::::::::::::::::::::::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                |                       |
             * 5f      | PUSH0          | 0 cds 0 0              |                       |
             * 5f      | PUSH0          | 0 0 cds 0 0            |                       |
             * 37      | CALLDATACOPY   | 0 0                    | [0..cds): calldata    |
             *                                                                           |
             * ::: delegate call to the implementation contract :::::::::::::::::::::::: |
             * 36      | CALLDATASIZE   | cds 0 0                | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 cds 0 0              | [0..cds): calldata    |
             * 73 addr | PUSH20 addr    | addr 0 cds 0 0         | [0..cds): calldata    |
             * 5a      | GAS            | gas addr 0 cds 0 0     | [0..cds): calldata    |
             * f4      | DELEGATECALL   | success                | [0..cds): calldata    |
             *                                                                           |
             * ::: copy return data to memory :::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds success            | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 rds success          | [0..cds): calldata    |
             * 5f      | PUSH0          | 0 0 rds success        | [0..cds): calldata    |
             * 3e      | RETURNDATACOPY | success                | [0..rds): returndata  |
             *                                                                           |
             * 60 0x29 | PUSH1 0x29     | 0x29 success           | [0..rds): returndata  |
             * 57      | JUMPI          |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: revert :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * fd      | REVERT         |                        | [0..rds): returndata  |
             *                                                                           |
             * ::: return :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b      | JUMPDEST       |                        | [0..rds): returndata  |
             * 3d      | RETURNDATASIZE | rds                    | [0..rds): returndata  |
             * 5f      | PUSH0          | 0 rds                  | [0..rds): returndata  |
             * f3      | RETURN         |                        | [0..rds): returndata  |
             * --------------------------------------------------------------------------+
             */
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create(value, 0x0e, 0x36)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    function cloneDeterministic_PUSH0(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic_PUSH0(0, implementation, salt);
    }

    /// @dev Deploys a deterministic PUSH0 clone of `implementation` with `salt`.
    /// Deposits `value` ETH during deployment.
    function cloneDeterministic_PUSH0(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            instance := create2(value, 0x0e, 0x36, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the initialization code of the PUSH0 clone of `implementation`.
    function initCode_PUSH0(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(add(result, 0x40), 0x5af43d5f5f3e6029573d5ffd5b3d5ff300000000000000000000) // 16
            mstore(add(result, 0x26), implementation) // 20
            mstore(add(result, 0x12), 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            mstore(result, 0x36) // Store the length.
            mstore(0x40, add(result, 0x60)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the PUSH0 clone of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash_PUSH0(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x24, 0x5af43d5f5f3e6029573d5ffd5b3d5ff3) // 16
            mstore(0x14, implementation) // 20
            mstore(0x00, 0x602d5f8160095f39f35f5f365f5f37365f73) // 9 + 9
            hash := keccak256(0x0e, 0x36)
            mstore(0x24, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Returns the address of the deterministic PUSH0 clone of `implementation`,
    /// with `salt` by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress_PUSH0(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash_PUSH0(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*           CLONES WITH IMMUTABLE ARGS OPERATIONS            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: This implementation of CWIA differs from the original implementation.
    // If the calldata is empty, it will emit a `ReceiveETH(uint256)` event and skip the `DELEGATECALL`.

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        instance = clone(0, implementation, data);
    }

    /// @dev Deploys a clone of `implementation` with immutable arguments encoded in `data`.
    /// Deposits `value` ETH during deployment.
    function clone(uint256 value, address implementation, bytes memory data)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 108`
            // The `runSize` is `creationSize - 10`.

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: if no calldata, emit event & return w/o `DELEGATECALL` ::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 60 0x2c  | PUSH1 0x2c     | 0x2c cds                 |                                             |
             * 57       | JUMPI          |                          |                                             |
             * 34       | CALLVALUE      | cv                       |                                             |
             * 3d       | RETURNDATASIZE | 0 cv                     |                                             |
             * 52       | MSTORE         |                          | [0..0x20): callvalue                        |
             * 7f sig   | PUSH32 0x9e..  | sig                      | [0..0x20): callvalue                        |
             * 59       | MSIZE          | 0x20 sig                 | [0..0x20): callvalue                        |
             * 3d       | RETURNDATASIZE | 0 0x20 sig               | [0..0x20): callvalue                        |
             * a1       | LOG1           |                          | [0..0x20): callvalue                        |
             * 00       | STOP           |                          | [0..0x20): callvalue                        |
             * 5b       | JUMPDEST       |                          |                                             |
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x62  | PUSH1 0x62     | 0x62 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x62 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x60  | PUSH1 0x60     | 0x60 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create(value, sub(data, 0x4c), add(extraLength, 0x6c))
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = cloneDeterministic(0, implementation, data, salt);
    }

    /// @dev Deploys a deterministic clone of `implementation`
    /// with immutable arguments encoded in `data` and `salt`.
    function cloneDeterministic(
        uint256 value,
        address implementation,
        bytes memory data,
        bytes32 salt
    ) internal returns (address instance) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                // Do a out-of-gas revert if `extraLength` is too big. 0xffff - 0x62 + 0x01 = 0xff9e.
                // The actual EVM limit may be smaller and may change over time.
                sub(data, add(0x59, lt(extraLength, 0xff9e))),
                or(shl(0x78, add(extraLength, 0x62)), 0xfd6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            instance := create2(value, sub(data, 0x4c), add(extraLength, 0x6c), salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    function initCode(address implementation, bytes memory data)
        internal
        pure
        returns (bytes memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            let dataLength := mload(data)

            // Do a out-of-gas revert if `dataLength` is too big. 0xffff - 0x02 - 0x62 = 0xff9b.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))

            let o := add(result, 0x8c)
            let end := add(o, dataLength)

            // Copy the `data` into `result`.
            for { let d := sub(add(data, 0x20), o) } 1 {} {
                mstore(o, mload(add(o, d)))
                o := add(o, 0x20)
                if iszero(lt(o, end)) { break }
            }

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(add(result, 0x6c), 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(add(result, 0x5f), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                add(result, 0x4b),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                add(result, 0x32),
                0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                add(result, 0x12),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(end, shl(0xf0, extraLength))
            mstore(add(end, 0x02), 0) // Zeroize the slot after the result.
            mstore(result, add(extraLength, 0x6c)) // Store the length.
            mstore(0x40, add(0x22, end)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the clone of `implementation`
    /// using immutable arguments encoded in `data`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHash(address implementation, bytes memory data)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore3 := mload(sub(data, 0x60))
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // Do a out-of-gas revert if `dataLength` is too big. 0xffff - 0x02 - 0x62 = 0xff9b.
            // The actual EVM limit may be smaller and may change over time.
            returndatacopy(returndatasize(), returndatasize(), gt(dataLength, 0xff9b))

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)

            mstore(data, 0x5af43d3d93803e606057fd5bf3) // Write the bytecode before the data.
            mstore(sub(data, 0x0d), implementation) // Write the address of the implementation.
            // Write the rest of the bytecode.
            mstore(
                sub(data, 0x21),
                or(shl(0x48, extraLength), 0x593da1005b363d3d373d3d3d3d610000806062363936013d73)
            )
            // `keccak256("ReceiveETH(uint256)")`
            mstore(
                sub(data, 0x3a), 0x9e4ac34f21c619cefc926c8bd93b54bf5a39c7ab2127a895af1cc0691d7e3dff
            )
            mstore(
                sub(data, 0x5a),
                or(shl(0x78, add(extraLength, 0x62)), 0x6100003d81600a3d39f336602c57343d527f)
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            hash := keccak256(sub(data, 0x4c), add(extraLength, 0x6c))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
            mstore(sub(data, 0x60), mBefore3)
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(
        address implementation,
        bytes memory data,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              MINIMAL ERC1967 PROXY OPERATIONS              */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: The ERC1967 proxy here is intended to be upgraded with UUPS.
    // This is NOT the same as ERC1967Factory's transparent proxy, which includes admin logic.

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    function deployERC1967(address implementation) internal returns (address instance) {
        instance = deployERC1967(0, implementation);
    }

    /// @dev Deploys a minimal ERC1967 proxy with `implementation`.
    /// Deposits `value` ETH during deployment.
    function deployERC1967(uint256 value, address implementation)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            /**
             * ---------------------------------------------------------------------------------+
             * CREATION (34 bytes)                                                              |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             * 60 runSize | PUSH1 runSize  | r                |                                 |
             * 3d         | RETURNDATASIZE | 0 r              |                                 |
             * 81         | DUP2           | r 0 r            |                                 |
             * 60 offset  | PUSH1 offset   | o r 0 r          |                                 |
             * 3d         | RETURNDATASIZE | 0 o r 0 r        |                                 |
             * 39         | CODECOPY       | 0 r              | [0..runSize): runtime code      |
             * 73 impl    | PUSH20 impl    | impl 0 r         | [0..runSize): runtime code      |
             * 60 slotPos | PUSH1 slotPos  | slotPos impl 0 r | [0..runSize): runtime code      |
             * 51         | MLOAD          | slot impl 0 r    | [0..runSize): runtime code      |
             * 55         | SSTORE         | 0 r              | [0..runSize): runtime code      |
             * f3         | RETURN         |                  | [0..runSize): runtime code      |
             * ---------------------------------------------------------------------------------|
             * RUNTIME (62 bytes)                                                               |
             * ---------------------------------------------------------------------------------|
             * Opcode     | Mnemonic       | Stack            | Memory                          |
             * ---------------------------------------------------------------------------------|
             *                                                                                  |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36         | CALLDATASIZE   | cds              |                                 |
             * 3d         | RETURNDATASIZE | 0 cds            |                                 |
             * 3d         | RETURNDATASIZE | 0 0 cds          |                                 |
             * 37         | CALLDATACOPY   |                  | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: delegatecall to implementation ::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | 0                |                                 |
             * 3d         | RETURNDATASIZE | 0 0              |                                 |
             * 36         | CALLDATASIZE   | cds 0 0          | [0..calldatasize): calldata     |
             * 3d         | RETURNDATASIZE | 0 cds 0 0        | [0..calldatasize): calldata     |
             * 7f slot    | PUSH32 slot    | s 0 cds 0 0      | [0..calldatasize): calldata     |
             * 54         | SLOAD          | i 0 cds 0 0      | [0..calldatasize): calldata     |
             * 5a         | GAS            | g i 0 cds 0 0    | [0..calldatasize): calldata     |
             * f4         | DELEGATECALL   | succ             | [0..calldatasize): calldata     |
             *                                                                                  |
             * ::: copy returndata to memory :::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds succ         | [0..calldatasize): calldata     |
             * 60 0x00    | PUSH1 0x00     | 0 rds succ       | [0..calldatasize): calldata     |
             * 80         | DUP1           | 0 0 rds succ     | [0..calldatasize): calldata     |
             * 3e         | RETURNDATACOPY | succ             | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: branch on delegatecall status :::::::::::::::::::::::::::::::::::::::::::::: |
             * 60 0x38    | PUSH1 0x38     | dest succ        | [0..returndatasize): returndata |
             * 57         | JUMPI          |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall failed, revert :::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * fd         | REVERT         |                  | [0..returndatasize): returndata |
             *                                                                                  |
             * ::: delegatecall succeeded, return ::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b         | JUMPDEST       |                  | [0..returndatasize): returndata |
             * 3d         | RETURNDATASIZE | rds              | [0..returndatasize): returndata |
             * 60 0x00    | PUSH1 0x00     | 0 rds            | [0..returndatasize): returndata |
             * f3         | RETURN         |                  | [0..returndatasize): returndata |
             * ---------------------------------------------------------------------------------+
             */
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create(value, 0x21, 0x5f)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    function deployDeterministicERC1967(address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        instance = deployDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Deploys a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    function deployDeterministicERC1967(uint256 value, address implementation, bytes32 salt)
        internal
        returns (address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            instance := create2(value, 0x21, 0x5f, salt)
            if iszero(instance) {
                mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        return createDeterministicERC1967(0, implementation, salt);
    }

    /// @dev Creates a deterministic minimal ERC1967 proxy with `implementation` and `salt`.
    /// Deposits `value` ETH during deployment.
    /// Note: This method is intended for use in ERC4337 factories,
    /// which are expected to NOT revert if the proxy is already deployed.
    function createDeterministicERC1967(uint256 value, address implementation, bytes32 salt)
        internal
        returns (bool alreadyDeployed, address instance)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            // Compute and store the bytecode hash.
            mstore(add(m, 0x35), keccak256(0x21, 0x5f))
            mstore(m, shl(88, address()))
            mstore8(m, 0xff) // Write the prefix.
            mstore(add(m, 0x15), salt)
            instance := keccak256(m, 0x55)
            for {} 1 {} {
                if iszero(extcodesize(instance)) {
                    instance := create2(value, 0x21, 0x5f, salt)
                    if iszero(instance) {
                        mstore(0x00, 0x30116425) // `DeploymentFailed()`.
                        revert(0x1c, 0x04)
                    }
                    break
                }
                alreadyDeployed := 1
                if iszero(value) { break }
                if iszero(call(gas(), instance, value, codesize(), 0x00, codesize(), 0x00)) {
                    mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                    revert(0x1c, 0x04)
                }
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the initialization code of the minimal ERC1967 proxy of `implementation`.
    function initCodeERC1967(address implementation) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            result := mload(0x40)
            mstore(
                add(result, 0x60),
                0x3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f300
            )
            mstore(
                add(result, 0x40),
                0x55f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc
            )
            mstore(add(result, 0x20), or(shl(24, implementation), 0x600951))
            mstore(add(result, 0x09), 0x603d3d8160223d3973)
            mstore(result, 0x5f) // Store the length.
            mstore(0x40, add(result, 0x80)) // Allocate memory.
        }
    }

    /// @dev Returns the initialization code hash of the minimal ERC1967 proxy of `implementation`.
    /// Used for mining vanity addresses with create2crunch.
    function initCodeHashERC1967(address implementation) internal pure returns (bytes32 hash) {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, 0xcc3735a920a3ca505d382bbc545af43d6000803e6038573d6000fd5b3d6000f3)
            mstore(0x40, 0x5155f3363d3d373d3d363d7f360894a13ba1a3210667c828492db98dca3e2076)
            mstore(0x20, 0x6009)
            mstore(0x1e, implementation)
            mstore(0x0a, 0x603d3d8160223d3973)
            hash := keccak256(0x21, 0x5f)
            mstore(0x40, m) // Restore the free memory pointer.
            mstore(0x60, 0) // Restore the zero slot.
        }
    }

    /// @dev Returns the address of the deterministic clone of
    /// `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddressERC1967(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        bytes32 hash = initCodeHashERC1967(implementation);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      OTHER OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns the address when a contract with initialization code hash,
    /// `hash`, is deployed with `salt`, by `deployer`.
    /// Note: The returned result has dirty upper 96 bits. Please clean if used in assembly.
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)
            mstore(0x35, 0) // Restore the overwritten part of the free memory pointer.
        }
    }

    /// @dev Requires that `salt` starts with either the zero address or `by`.
    function checkStartsWith(bytes32 salt, address by) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            // If the salt does not start with the zero address or `by`.
            if iszero(or(iszero(shr(96, salt)), eq(shr(96, shl(96, by)), shr(96, salt)))) {
                mstore(0x00, 0x0c4549ef) // `SaltDoesNotStartWith()`.
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

interface IFeeManager {
    event FeeCollected(
        address betReferrer, address userReferrer, uint256 amount, uint256 betReferrerAmount, uint256 referrerAmount
    );
    event BetReferrerSet(address indexed user, address indexed referrer, address market, uint8 position);
    event ParlayReferrerSet(address indexed user, address indexed referrer, bytes32 _hash);

    struct BetInfo {
        uint256 amount;
        address referrer;
    }

    function setReferrer(address referrer, address referred) external;

    function setBetInfo(
        address referred,
        address referrer,
        address market,
        uint256 susdAmount,
        uint8 position
    )
        external;

    function setParlayInfo(address referred, address referrer, bytes32 _hash, uint256 susdAmount) external;

    function getBetInfo(address user, address market, uint8 position) external view returns (BetInfo memory);

    function getParlayInfo(address user, bytes32 hash) external view returns (BetInfo memory);

    function getParlayHash(uint256 expiry, uint256 amount, uint256 sUSDPaid) external pure returns (bytes32 refHash);

    function fee(uint256 total) external returns (uint256);
    function collectFee(uint256 amount, address user, address betReferrer, address collateral) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IOvertimeUserFactory {
    error MastercopyInitialized();
    error ParametersNotSet();
    error Slippage();

    event OvertimeUserCreated(address indexed wallet, address indexed owner);

    function buySingle(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external;
    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external;

    function buyParlay(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address referrer
    )
        external;
    function buyParlayWithDifferentCollateral(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 additionalSlippage,
        address collateral,
        address referrer
    )
        external;

    function exerciseSingle(address market) external;
    function exerciseSingleWithDifferentCollateral(address market, address collateral, bool toEth) external;

    function exerciseParlay(address market) external;
    function exerciseParlayWithDifferentCollateral(address market, address collateral, bool toEth) external;

    function setMastercopy(address _mastercopy) external;
    function createUser(address referrer) external returns (address clone);
    function getUser(address _owner) external view returns (address wallet);

    function isDeployed(address wallet) external view returns (bool);
    function isWrapper(address wallet) external view returns (bool);

    function resetVariables() external;
    function setFactoryVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external;

    function version() external view returns (uint256);
    function parametersVersion(address) external view returns (uint256);

    function sportsAMM() external view returns (address);
    function parlayMarketsAMM() external view returns (address);
    function overtimeReferrer() external view returns (address);
    function feeManager() external view returns (address);

    function susd() external view returns (address);
    function weth() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IOvertimeUser {
    error Initialized();
    error Unauthorized();
    error ZeroAddress();
    error NullPayout();

    event SingleReferrerSet(address market, uint8 position, address referrer);
    event ParlayReferrerSet(address[] sportMarkets, uint[] positions, address referrer);
    event BuySingleBet(address market, uint8 position, uint256 payout, address collateral, uint256 collateralAmount);
    event BuyParlayBet(
        address[] sportMarkets, uint[] positions, uint256 expectedPayout, address collateral, uint256 collateralAmount
    );
    event ExerciseSingleBet(address market, address collateral, uint256 payout);
    event ExerciseParlayBet(address market, address collateral, uint256 payout);

    function buySingle(address market, uint8 position, uint256 payout, uint256 desiredAmount) external payable;

    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        address collateral
    )
        external
        payable;

    function buyParlay(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount
    )
        external
        payable;

    function buyParlayWithDifferentCollateral(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 collateralAmount,
        address collateral
    )
        external
        payable;

    function exerciseParlay(address market) external returns (uint256 fee, address referrer);

    function exerciseParlayWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        returns (uint256 fee, address referrer);

    function exerciseSingle(address market) external returns (uint256 fee, address referrer);

    function exerciseSingleWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        returns (uint256 fee, address referrer);

    function initialize(address _user) external;

    function setVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISportsAMM {
    enum Position {
        Home,
        Away,
        Draw
    }

    event AddressesUpdated(
        address _safeBox,
        address _sUSD,
        address _theRundownConsumer,
        address _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp,
        address _riskManager
    );
    event BoughtFromAmm(
        address buyer, address market, Position position, uint256 amount, uint256 sUSDPaid, address susd, address asset
    );
    event ExercisedWithOfframp(
        address user, address market, address collateral, bool toEth, uint256 payout, uint256 payoutInCollateral
    );
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event ParametersUpdated(
        uint256 _minimalTimeLeftToMaturity,
        uint256 _minSpread,
        uint256 _maxSpread,
        uint256 _minSupportedOdds,
        uint256 _maxSupportedOdds,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 threshold
    );
    event Paused(address account);
    event ReferrerPaid(address refferer, address trader, uint256 amount, uint256 volume);
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
    event SetSportsPositionalMarketManager(address _manager);
    event Unpaused(address account);

    receive() external payable;

    function TAG_NUMBER_PLAYERS() external view returns (uint256);
    function acceptOwnership() external;
    function availableToBuyFromAMM(address market, Position position) external view returns (uint256 _available);
    function availableToBuyFromAMMWithBaseOdds(
        address market,
        Position position,
        uint256 baseOdds,
        uint256 balance,
        bool useBalance
    )
        external
        view
        returns (uint256 availableAmount);
    function buyFromAMM(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage
    )
        external;
    function buyFromAMMWithDifferentCollateral(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral
    )
        external;
    function buyFromAMMWithDifferentCollateralAndReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral,
        address _referrer
    )
        external;
    function buyFromAMMWithEthAndReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral,
        address _referrer
    )
        external
        payable;
    function buyFromAMMWithReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address _referrer
    )
        external;
    function buyFromAmmQuote(
        address market,
        Position position,
        uint256 amount
    )
        external
        view
        returns (uint256 _quote);
    function buyFromAmmQuoteForParlayAMM(
        address market,
        Position position,
        uint256 amount
    )
        external
        view
        returns (uint256 _quote);
    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        Position position,
        uint256 amount,
        address collateral
    )
        external
        view
        returns (uint256 collateralQuote, uint256 sUSDToPay);
    function buyPriceImpact(address market, Position position, uint256 amount) external view returns (int256 impact);
    function exerciseWithOfframp(address market, address collateral, bool toEth) external;
    function floorBaseOdds(uint256 baseOdds, address market) external view returns (uint256);
    function getMarketDefaultOdds(address _market, bool isSell) external view returns (uint256[] memory odds);
    function initNonReentrant() external;
    function initialize(
        address _owner,
        address _sUSD,
        uint256 _min_spread,
        uint256 _max_spread,
        uint256 _minimalTimeLeftToMaturity
    )
        external;
    function isMarketInAMMTrading(address market) external view returns (bool isTrading);
    function liquidityPool() external view returns (address);
    function manager() external view returns (address);
    function maxSupportedOdds() external view returns (uint256);
    function max_spread() external view returns (uint256);
    function minSupportedOdds() external view returns (uint256);
    function min_spread() external view returns (uint256);
    function min_spreadPerAddress(address) external view returns (uint256);
    function minimalTimeLeftToMaturity() external view returns (uint256);
    function multiCollateralOnOffRamp() external view returns (address);
    function multicollateralEnabled() external view returns (bool);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function obtainOdds(address _market, Position _position) external view returns (uint256 oddsToReturn);
    function owner() external view returns (address);
    function parlayAMM() external view returns (address);
    function paused() external view returns (bool);
    function referrals() external view returns (address);
    function riskManager() external view returns (address);
    function sUSD() external view returns (address);
    function safeBox() external view returns (address);
    function safeBoxFeePerAddress(address) external view returns (uint256);
    function safeBoxImpact() external view returns (uint256);
    function setAddresses(
        address _safeBox,
        address _sUSD,
        address _theRundownConsumer,
        address _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp,
        address _riskManager
    )
        external;
    function setAmmUtils(address _ammUtils) external;
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external;
    function setOwner(address _owner) external;
    function setParameters(
        uint256 _minimalTimeLeftToMaturity,
        uint256 _minSpread,
        uint256 _maxSpread,
        uint256 _minSupportedOdds,
        uint256 _maxSupportedOdds,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _threshold
    )
        external;
    function setPaused(bool _setPausing) external;
    function setSafeBoxFeeAndMinSpreadPerAddress(address _address, uint256 newSBFee, uint256 newMSFee) external;
    function setSportsPositionalMarketManager(address _manager) external;
    function spentOnGame(address) external view returns (uint256);
    function sportAmmUtils() external view returns (address);
    function stakingThales() external view returns (address);
    function theRundownConsumer() external view returns (address);
    function thresholdForOddsUpdate() external view returns (uint256);
    function transferOwnershipAtInit(address proxyAddress) external;
    function updateParlayVolume(address _account, uint256 _amount) external;
    function wrapper() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IParlayMarketsAMM {
    event AddressesSet(address _thalesAMM, address _safeBox, address _referrals, address _parlayMarketData);
    event ExtraAmountTransferredDueToCancellation(address receiver, uint256 amount);
    event NewParametersSet(uint256 parlaySize);
    event NewParlayMarket(address market, address[] markets, uint256[] positions, uint256 amount, uint256 sUSDpaid);
    event NewParlayMastercopy(address parlayMarketMastercopy);
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event ParlayAmmFeePerAddressChanged(address _address, uint256 newFee);
    event ParlayLPSet(address parlayLP);
    event ParlayMarketCreated(
        address market,
        address account,
        uint256 amount,
        uint256 sUSDPaid,
        uint256 sUSDAfterFees,
        uint256 totalQuote,
        uint256 skewImpact,
        uint256[] marketQuotes
    );
    event ParlayResolved(address _parlayMarket, address _parlayOwner, bool _userWon);
    event PauseChanged(bool isPaused);
    event ReferrerPaid(address refferer, address trader, uint256 amount, uint256 volume);
    event SafeBoxFeePerAddressChanged(address _address, uint256 newFee);
    event SetAmounts(
        uint256 minUSDamount,
        uint256 max_amount,
        uint256 max_odds,
        uint256 _parlayAMMFee,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _maxAllowedRiskPerCombination
    );
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
    event SetSGPFeePerPosition(uint256 tag1, uint256 tag2_1, uint256 tag2_2, uint256 fee);
    event SetSUSD(address sUSDToken);
    event VerifierAndPolicySet(address _parlayVerifier, address _parlayPolicy);

    receive() external payable;

    function SGPFeePerCombination(uint256, uint256, uint256) external view returns (uint256);
    function acceptOwnership() external;
    function activeParlayMarkets(uint256 index, uint256 pageSize) external view returns (address[] memory);
    function buyFromParlay(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address _differentRecipient
    )
        external;
    function buyFromParlayWithDifferentCollateralAndReferrer(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address collateral,
        address _referrer
    )
        external;
    function buyFromParlayWithEth(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address collateral,
        address _referrer
    )
        external
        payable;
    function buyFromParlayWithReferrer(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address _differentRecipient,
        address _referrer
    )
        external;
    function buyQuoteFromParlay(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid
    )
        external
        view
        returns (
            uint256 sUSDAfterFees,
            uint256 totalBuyAmount,
            uint256 totalQuote,
            uint256 initialQuote,
            uint256 skewImpact,
            uint256[] memory finalQuotes,
            uint256[] memory amountsToBuy
        );
    function buyQuoteFromParlayWithDifferentCollateral(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        address _collateral
    )
        external
        view
        returns (
            uint256 collateralQuote,
            uint256 sUSDAfterFees,
            uint256 totalBuyAmount,
            uint256 totalQuote,
            uint256 skewImpact,
            uint256[] memory finalQuotes,
            uint256[] memory amountsToBuy
        );
    function canCreateParlayMarket(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDToPay
    )
        external
        view
        returns (bool canBeCreated);
    function curveSUSD() external view returns (address);
    function exerciseParlay(address _parlayMarket) external;
    function exerciseParlayWithOfframp(address _parlayMarket, address collateral, bool toEth) external;
    function expireMarkets(address[] memory _parlayMarkets) external;
    function getSgpFeePerCombination(
        uint256 tag1,
        uint256 tag2_1,
        uint256 tag2_2,
        uint256 position1,
        uint256 position2
    )
        external
        view
        returns (uint256 sgpFee);
    function initNonReentrant() external;
    function initialize(
        address _owner,
        address _sportsAmm,
        address _sportManager,
        uint256 _parlayAmmFee,
        uint256 _maxSupportedAmount,
        uint256 _maxSupportedOdds,
        address _sUSD,
        address _safeBox,
        uint256 _safeBoxImpact
    )
        external;
    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket);
    function isParlayOwnerTheWinner(address _parlayMarket) external view returns (bool isUserTheWinner);
    function lastPauseTime() external view returns (uint256);
    function maxAllowedRiskPerCombination() external view returns (uint256);
    function maxSupportedAmount() external view returns (uint256);
    function maxSupportedOdds() external view returns (uint256);
    function minUSDAmount() external view returns (uint256);
    function multiCollateralOnOffRamp() external view returns (address);
    function multicollateralEnabled() external view returns (bool);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function numActiveParlayMarkets() external view returns (uint256);
    function owner() external view returns (address);
    function parlayAmmFee() external view returns (uint256);
    function parlayAmmFeePerAddress(address) external view returns (uint256);
    function parlayLP() external view returns (address);
    function parlayMarketData() external view returns (address);
    function parlayMarketMastercopy() external view returns (address);
    function parlayPolicy() external view returns (address);
    function parlaySize() external view returns (uint256);
    function parlayVerifier() external view returns (address);
    function parlaysWithNewFormat(address) external view returns (bool);
    function paused() external view returns (bool);
    function referrals() external view returns (address);
    function resolveParlay() external;
    function resolvedParlay(address) external view returns (bool);
    function riskPerCombination(
        address,
        uint256,
        address,
        uint256,
        address,
        uint256,
        address,
        uint256
    )
        external
        view
        returns (uint256);
    function riskPerGameCombination(
        address,
        address,
        address,
        address,
        address,
        address,
        address,
        address
    )
        external
        view
        returns (uint256);
    function riskPerMarketAndPosition(address, uint256) external view returns (uint256);
    function riskPerPackedGamesCombination(bytes32) external view returns (uint256);
    function sUSD() external view returns (address);
    function safeBox() external view returns (address);
    function safeBoxFeePerAddress(address) external view returns (uint256);
    function safeBoxImpact() external view returns (uint256);
    function setAddresses(
        address _sportsAMM,
        address _safeBox,
        address _referrals,
        address _parlayMarketData
    )
        external;
    function setAmounts(
        uint256 _minUSDAmount,
        uint256 _maxSupportedAmount,
        uint256 _maxSupportedOdds,
        uint256 _parlayAMMFee,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _maxAllowedRiskPerCombination
    )
        external;
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external;
    function setOwner(address _owner) external;
    function setParameters(uint256 _parlaySize) external;
    function setParlayAmmFeePerAddress(address _address, uint256 newFee) external;
    function setParlayLP(address _parlayLP) external;
    function setParlayMarketMastercopies(address _parlayMarketMastercopy) external;
    function setPaused(bool _paused) external;
    function setPausedMarkets(address[] memory _parlayMarkets, bool _paused) external;
    function setSGPFeePerPosition(
        uint256[] memory tag1,
        uint256 tag2_1,
        uint256 tag2_2,
        uint256 position_1,
        uint256 position_2,
        uint256 fee
    )
        external;
    function setSafeBoxFeePerAddress(address _address, uint256 newFee) external;
    function setSgpFeePerCombination(uint256 tag1, uint256 tag2_1, uint256 tag2_2, uint256 fee) external;
    function setVerifierAndPolicyAddresses(address _parlayVerifier, address _parlayPolicy) external;
    function sportManager() external view returns (address);
    function sportsAmm() external view returns (address);
    function stakingThales() external view returns (address);
    function transferOwnershipAtInit(address proxyAddress) external;
    function triggerResolvedEvent(address _account, bool _userWon) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Reentrancy guard mixin.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unauthorized reentrant call.
    error Reentrancy();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STORAGE                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to: `uint72(bytes9(keccak256("_REENTRANCY_GUARD_SLOT")))`.
    /// 9 bytes is large enough to avoid collisions with lower slots,
    /// but not too large to result in excessive bytecode bloat.
    uint256 private constant _REENTRANCY_GUARD_SLOT = 0x929eee149b4bd21268;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      REENTRANCY GUARD                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Guards a function from reentrancy.
    modifier nonReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), 2) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
            sstore(_REENTRANCY_GUARD_SLOT, 2)
        }
        _;
        /// @solidity memory-safe-assembly
        assembly {
            sstore(_REENTRANCY_GUARD_SLOT, 1)
        }
    }

    /// @dev Guards a view function from read-only reentrancy.
    modifier nonReadReentrant() virtual {
        /// @solidity memory-safe-assembly
        assembly {
            if eq(sload(_REENTRANCY_GUARD_SLOT), 2) {
                mstore(0x00, 0xab143c06) // `Reentrancy()`.
                revert(0x1c, 0x04)
            }
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISportPositionalMarketManager {
    event AddedIntoWhitelist(address _whitelistAddress, bool _flag);
    event CreatorCapitalRequirementUpdated(uint256 value);
    event DatesUpdatedForMarket(address _market, uint256 _newStartTime, uint256 _expiry);
    event DoubleChanceMarketCreated(address _parentMarket, address _doubleChanceMarket, uint256 tag, string label);
    event DoubleChanceSupportChanged(bool _isDoubleChanceSupported);
    event ExpiryDurationUpdated(uint256 duration);
    event MarketCreated(
        address market,
        address indexed creator,
        bytes32 indexed gameId,
        uint256 maturityDate,
        uint256 expiryDate,
        address up,
        address down,
        address draw
    );
    event MarketCreationEnabledUpdated(bool enabled);
    event MarketExpired(address market);
    event MarketLabel(address market, string gameLabel);
    event MarketsMigrated(address receivingManager, address markets);
    event MarketsReceived(address migratingManager, address markets);
    event MaxTimeToMaturityUpdated(uint256 duration);
    event OddsForMarketRestored(address _market, uint256 _homeOdds, uint256 _awayOdds, uint256 _drawOdds);
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event PauseChanged(bool isPaused);
    event SetMigratingManager(address migratingManager);
    event SetObtainerAddress(address _obratiner);
    event SetPlayerPropsAddress(address _playerProps);
    event SetSportPositionalMarketFactory(address _sportPositionalMarketFactory);
    event SetTherundownConsumer(address theRundownConsumer);
    event SetsUSD(address _address);
    event SupportedSportForDoubleChanceAdded(uint256 _sportId, bool _isSupported);

    function acceptOwnership() external;
    function activeMarkets(uint256 index, uint256 pageSize) external view returns (address[] memory);
    function cancelMarketsForParents(address[] memory _parents) external;
    function cancelMarketsForPlayerProps(address[] memory _playerPropsMarkets) external;
    function cancelTimeout() external view returns (uint256);
    function createDoubleChanceMarketsForParent(address market) external;
    function createMarket(
        bytes32 gameId,
        string memory gameLabel,
        uint256 maturity,
        uint256 initialMint,
        uint256 positionCount,
        uint256[] memory tags,
        bool isChild,
        address parentMarket
    )
        external
        returns (address);
    function customMarketCreationEnabled() external view returns (bool);
    function decrementTotalDeposited(uint256 delta) external;
    function doesSportSupportDoubleChance(uint256) external view returns (bool);
    function doubleChanceMarketsByParent(address, uint256) external view returns (address);
    function expireMarkets(address[] memory markets) external;
    function expiryDuration() external view returns (uint256);
    function getActiveMarketAddress(uint256 _index) external view returns (address);
    function getDoubleChanceMarketsByParentMarket(address market) external view returns (address[] memory);
    function getOddsObtainer() external view returns (address obtainer);
    function incrementTotalDeposited(uint256 delta) external;
    function initialize(address _owner, address _sUSD) external;
    function isActiveMarket(address candidate) external view returns (bool);
    function isDoubleChance(address) external view returns (bool);
    function isDoubleChanceMarket(address candidate) external view returns (bool);
    function isDoubleChanceSupported() external view returns (bool);
    function isKnownMarket(address candidate) external view returns (bool);
    function isMarketPaused(address _market) external view returns (bool);
    function isWhitelistedAddress(address _address) external view returns (bool);
    function lastPauseTime() external view returns (uint256);
    function marketCreationEnabled() external view returns (bool);
    function maturedMarkets(uint256 index, uint256 pageSize) external view returns (address[] memory);
    function needsTransformingCollateral() external view returns (bool);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function numActiveMarkets() external view returns (uint256);
    function numMaturedMarkets() external view returns (uint256);
    function oddsObtainer() external view returns (address);
    function overrideResolveWithCancel(address market, uint256 _outcome) external;
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function playerProps() external view returns (address);
    function queryMintsAndMaturityStatusForParents(address[] memory _parents)
        external
        view
        returns (bool[] memory _hasAnyMintsArray, bool[] memory _isMaturedArray, bool[] memory _isResolvedArray);
    function queryMintsAndMaturityStatusForPlayerProps(address[] memory _playerPropsMarkets)
        external
        view
        returns (
            bool[] memory _hasAnyMintsArray,
            bool[] memory _isMaturedArray,
            bool[] memory _isResolvedArray,
            uint256[] memory _maturities
        );
    function resolveMarket(address market, uint256 _outcome) external;
    function resolveMarketWithResult(
        address _market,
        uint256 _outcome,
        uint8 _homeScore,
        uint8 _awayScore,
        address _consumer,
        bool _useBackupOdds
    )
        external;
    function restoreInvalidOddsForMarket(
        address _market,
        uint256 _homeOdds,
        uint256 _awayOdds,
        uint256 _drawOdds
    )
        external;
    function reverseTransformCollateral(uint256 value) external view returns (uint256);
    function sUSD() external view returns (address);
    function setCancelTimeout(uint256 _cancelTimeout) external;
    function setExpiryDuration(uint256 _expiryDuration) external;
    function setIsDoubleChanceSupported(bool _isDoubleChanceSupported) external;
    function setMarketCreationEnabled(bool enabled) external;
    function setMarketPaused(address _market, bool _paused) external;
    function setNeedsTransformingCollateral(bool _needsTransformingCollateral) external;
    function setOddsObtainer(address _oddsObtainer) external;
    function setOwner(address _owner) external;
    function setPaused(bool _paused) external;
    function setPlayerProps(address _playerProps) external;
    function setSportPositionalMarketFactory(address _sportPositionalMarketFactory) external;
    function setSupportedSportForDoubleChance(uint256[] memory _sportIds, bool _isSupported) external;
    function setTherundownConsumer(address _theRundownConsumer) external;
    function setWhitelistedAddresses(address[] memory _whitelistedAddresses, bool _flag, uint8 _group) external;
    function setsUSD(address _address) external;
    function sportPositionalMarketFactory() external view returns (address);
    function theRundownConsumer() external view returns (address);
    function totalDeposited() external view returns (uint256);
    function transferOwnershipAtInit(address proxyAddress) external;
    function transferSusdTo(address sender, address receiver, uint256 amount) external;
    function transformCollateral(uint256 value) external view returns (uint256);
    function updateDatesForMarket(address _market, uint256 _newStartTime) external;
    function whitelistedAddresses(address) external view returns (bool);
    function whitelistedCancelAddresses(address) external view returns (bool);
}