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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../utils/Ownable.sol";
import "../../utils/Accessibility.sol";
import "../../storages/MAStorage.sol";
import "../../storages/MuonStorage.sol";
import "../../storages/GlobalAppStorage.sol";
import "../../storages/SymbolStorage.sol";
import "./IControlEvents.sol";
import "../../libraries/LibDiamond.sol";

contract ControlFacet is Accessibility, Ownable, IControlEvents {
    
    function transferOwnership(address owner) external onlyOwner{
        require(owner != address(0),"ControlFacet: Zero address");
        LibDiamond.setContractOwner(owner); 
    }

    function setAdmin(address user) external onlyOwner {
        require(user != address(0),"ControlFacet: Zero address");
        GlobalAppStorage.layout().hasRole[user][LibAccessibility.DEFAULT_ADMIN_ROLE] = true;
        emit RoleGranted(LibAccessibility.DEFAULT_ADMIN_ROLE, user);
    }

    function grantRole(
        address user,
        bytes32 role
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        GlobalAppStorage.layout().hasRole[user][role] = true;
        emit RoleGranted(role, user);
    }

    function revokeRole(
        address user,
        bytes32 role
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().hasRole[user][role] = false;
        emit RoleRevoked(role, user);
    }

    function registerPartyB(
        address partyB
    ) external onlyRole(LibAccessibility.PARTY_B_MANAGER_ROLE) {
        require(partyB != address(0), "ControlFacet: Zero address");
        require(
            !MAStorage.layout().partyBStatus[partyB],
            "ControlFacet: Address is already registered"
        );
        MAStorage.layout().partyBStatus[partyB] = true;
        MAStorage.layout().partyBList.push(partyB);
        emit RegisterPartyB(partyB);
    }

    function deregisterPartyB(
        address partyB,
        uint256 index
    ) external onlyRole(LibAccessibility.PARTY_B_MANAGER_ROLE) {
        require(partyB != address(0), "ControlFacet: Zero address");
        require(MAStorage.layout().partyBStatus[partyB], "ControlFacet: Address is not registered");
        require(MAStorage.layout().partyBList[index] == partyB, "ControlFacet: Invalid index");
        uint256 lastIndex = MAStorage.layout().partyBList.length - 1;
        require(index <= lastIndex, "ControlFacet: Invalid index");
        MAStorage.layout().partyBStatus[partyB] = false;
        MAStorage.layout().partyBList[index] = MAStorage.layout().partyBList[lastIndex];
        MAStorage.layout().partyBList.pop();
        emit DeregisterPartyB(partyB, index);
    }

    function setMuonConfig(
        uint256 upnlValidTime,
        uint256 priceValidTime,
        uint256 priceQuantityValidTime
    ) external onlyRole(LibAccessibility.MUON_SETTER_ROLE) {
        emit SetMuonConfig(upnlValidTime, priceValidTime, priceQuantityValidTime);
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        muonLayout.upnlValidTime = upnlValidTime;
        muonLayout.priceValidTime = priceValidTime;
        muonLayout.priceQuantityValidTime = priceQuantityValidTime;
    }

    function setMuonIds(
        uint256 muonAppId,
        address validGateway,
        PublicKey memory publicKey
    ) external onlyRole(LibAccessibility.MUON_SETTER_ROLE) {
        MuonStorage.Layout storage muonLayout = MuonStorage.layout();
        muonLayout.muonAppId = muonAppId;
        muonLayout.validGateway = validGateway;
        muonLayout.muonPublicKey = publicKey;
        emit SetMuonIds(muonAppId, validGateway, publicKey.x, publicKey.parity);
    }

    function setCollateral(
        address collateral
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(collateral != address(0),"ControlFacet: Zero address");
        require(
            IERC20Metadata(collateral).decimals() <= 18,
            "ControlFacet: Token with more than 18 decimals not allowed"
        );
        if (GlobalAppStorage.layout().collateral != address(0)) {
            require(
                IERC20Metadata(GlobalAppStorage.layout().collateral).balanceOf(address(this)) == 0,
                "ControlFacet: There is still collateral in the contract"
            );
        }
        GlobalAppStorage.layout().collateral = collateral;
        emit SetCollateral(collateral);
    }

    // Symbol State

    function addSymbol(
        string memory name,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF,
        uint256 tradingFee,
        uint256 maxLeverage,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    ) public onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        require(
            fundingRateWindowTime < fundingRateEpochDuration / 2,
            "ControlFacet: High window time"
        );
        require(tradingFee <= 1e18, "ControlFacet: High trading fee");
        uint256 lastId = ++SymbolStorage.layout().lastId;
        Symbol memory symbol = Symbol(
            lastId,
            name,
            true,
            minAcceptableQuoteValue,
            minAcceptablePortionLF,
            tradingFee,
            maxLeverage,
            fundingRateEpochDuration,
            fundingRateWindowTime
        );
        SymbolStorage.layout().symbols[lastId] = symbol;
        emit AddSymbol(
            lastId,
            name,
            minAcceptableQuoteValue,
            minAcceptablePortionLF,
            tradingFee, 
            maxLeverage,
            fundingRateEpochDuration,
            fundingRateWindowTime
        );
    }

    function addSymbols(
        Symbol[] memory symbols
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        for (uint8 i; i < symbols.length; i++) {
            addSymbol(
                symbols[i].name,
                symbols[i].minAcceptableQuoteValue,
                symbols[i].minAcceptablePortionLF,
                symbols[i].tradingFee,
                symbols[i].maxLeverage,
                symbols[i].fundingRateEpochDuration,
                symbols[i].fundingRateWindowTime
            );
        }
    }

    function setSymbolFundingState(
        uint256 symbolId,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        require(
            fundingRateWindowTime < fundingRateEpochDuration / 2,
            "ControlFacet: High window time"
        );
        symbolLayout.symbols[symbolId].fundingRateEpochDuration = fundingRateEpochDuration;
        symbolLayout.symbols[symbolId].fundingRateWindowTime = fundingRateWindowTime;
        emit SetSymbolFundingState(symbolId, fundingRateEpochDuration, fundingRateWindowTime);
    }

    function setSymbolValidationState(
        uint256 symbolId,
        bool isValid
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolValidationState(symbolId, symbolLayout.symbols[symbolId].isValid, isValid);
        symbolLayout.symbols[symbolId].isValid = isValid;
    }

    function setSymbolMaxLeverage(
        uint256 symbolId,
        uint256 maxLeverage
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolMaxLeverage(symbolId, symbolLayout.symbols[symbolId].maxLeverage, maxLeverage);
        symbolLayout.symbols[symbolId].maxLeverage = maxLeverage;
    }

    function setSymbolAcceptableValues(
        uint256 symbolId,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolAcceptableValues(
            symbolId,
            symbolLayout.symbols[symbolId].minAcceptableQuoteValue,
            symbolLayout.symbols[symbolId].minAcceptablePortionLF,
            minAcceptableQuoteValue,
            minAcceptablePortionLF
        );
        symbolLayout.symbols[symbolId].minAcceptableQuoteValue = minAcceptableQuoteValue;
        symbolLayout.symbols[symbolId].minAcceptablePortionLF = minAcceptablePortionLF;
    }

    function setSymbolTradingFee(
        uint256 symbolId,
        uint256 tradingFee
    ) external onlyRole(LibAccessibility.SYMBOL_MANAGER_ROLE) {
        SymbolStorage.Layout storage symbolLayout = SymbolStorage.layout();
        require(symbolId >= 1 && symbolId <= symbolLayout.lastId, "ControlFacet: Invalid id");
        emit SetSymbolTradingFee(symbolId, symbolLayout.symbols[symbolId].tradingFee, tradingFee);
        symbolLayout.symbols[symbolId].tradingFee = tradingFee;
    }

    /////////////////////////////////////

    // CoolDowns

    function setDeallocateCooldown(
        uint256 deallocateCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetDeallocateCooldown(MAStorage.layout().deallocateCooldown, deallocateCooldown);
        MAStorage.layout().deallocateCooldown = deallocateCooldown;
    }

    function setForceCancelCooldown(
        uint256 forceCancelCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCancelCooldown(MAStorage.layout().forceCancelCooldown, forceCancelCooldown);
        MAStorage.layout().forceCancelCooldown = forceCancelCooldown;
    }

    function setForceCloseCooldown(
        uint256 forceCloseCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCloseCooldown(MAStorage.layout().forceCloseCooldown, forceCloseCooldown);
        MAStorage.layout().forceCloseCooldown = forceCloseCooldown;
    }

    function setForceCancelCloseCooldown(
        uint256 forceCancelCloseCooldown
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCancelCloseCooldown(
            MAStorage.layout().forceCancelCloseCooldown,
            forceCancelCloseCooldown
        );
        MAStorage.layout().forceCancelCloseCooldown = forceCancelCloseCooldown;
    }

    function setLiquidatorShare(
        uint256 liquidatorShare
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetLiquidatorShare(MAStorage.layout().liquidatorShare, liquidatorShare);
        MAStorage.layout().liquidatorShare = liquidatorShare;
    }

    function setForceCloseGapRatio(
        uint256 forceCloseGapRatio
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetForceCloseGapRatio(MAStorage.layout().forceCloseGapRatio, forceCloseGapRatio);
        MAStorage.layout().forceCloseGapRatio = forceCloseGapRatio;
    }

    function setPendingQuotesValidLength(
        uint256 pendingQuotesValidLength
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetPendingQuotesValidLength(
            MAStorage.layout().pendingQuotesValidLength,
            pendingQuotesValidLength
        );
        MAStorage.layout().pendingQuotesValidLength = pendingQuotesValidLength;
    }

    // Pause State

    function setFeeCollector(
        address feeCollector
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(feeCollector != address(0),"ControlFacet: Zero address");
        emit SetFeeCollector(GlobalAppStorage.layout().feeCollector, feeCollector);
        GlobalAppStorage.layout().feeCollector = feeCollector;
    }

    function pauseGlobal() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().globalPaused = true;
        emit PauseGlobal();
    }

    function pauseLiquidation() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().liquidationPaused = true;
        emit PauseLiquidation();
    }

    function pauseAccounting() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().accountingPaused = true;
        emit PauseAccounting();
    }

    function pausePartyAActions() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().partyAActionsPaused = true;
        emit PausePartyAActions();
    }

    function pausePartyBActions() external onlyRole(LibAccessibility.PAUSER_ROLE) {
        GlobalAppStorage.layout().partyBActionsPaused = true;
        emit PausePartyBActions();
    }

    function activeEmergencyMode() external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().emergencyMode = true;
        emit ActiveEmergencyMode();
    }

    function unpauseGlobal() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().globalPaused = false;
        emit UnpauseGlobal();
    }

    function unpauseLiquidation() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().liquidationPaused = false;
        emit UnpauseLiquidation();
    }

    function unpauseAccounting() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().accountingPaused = false;
        emit UnpauseAccounting();
    }

    function unpausePartyAActions() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().partyAActionsPaused = false;
        emit UnpausePartyAActions();
    }

    function unpausePartyBActions() external onlyRole(LibAccessibility.UNPAUSER_ROLE) {
        GlobalAppStorage.layout().partyBActionsPaused = false;
        emit UnpausePartyBActions();
    }

    function setLiquidationTimeout(
        uint256 liquidationTimeout
    ) external onlyRole(LibAccessibility.SETTER_ROLE) {
        emit SetLiquidationTimeout(MAStorage.layout().liquidationTimeout, liquidationTimeout);
        MAStorage.layout().liquidationTimeout = liquidationTimeout;
    }

    function suspendedAddress(
        address user
    ) external onlyRole(LibAccessibility.SUSPENDER_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        emit SetSuspendedAddress(user, true);
        AccountStorage.layout().suspendedAddresses[user] = true;
    }

    function unsuspendedAddress(
        address user
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        require(user != address(0),"ControlFacet: Zero address");
        emit SetSuspendedAddress(user, false);
        AccountStorage.layout().suspendedAddresses[user] = false;
    }

    function deactiveEmergencyMode() external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        GlobalAppStorage.layout().emergencyMode = false;
        emit DeactiveEmergencyMode();
    }

    function setBalanceLimitPerUser(
        uint256 balanceLimitPerUser
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        emit SetBalanceLimitPerUser(balanceLimitPerUser);
        GlobalAppStorage.layout().balanceLimitPerUser = balanceLimitPerUser;
    }

    function setPartyBEmergencyStatus(
        address[] memory partyBs,
        bool status
    ) external onlyRole(LibAccessibility.DEFAULT_ADMIN_ROLE) {
        for (uint8 i; i < partyBs.length; i++) {
            require(partyBs[i] != address(0),"ControlFacet: Zero address");
            GlobalAppStorage.layout().partyBEmergencyStatus[partyBs[i]] = status;
            emit SetPartyBEmergencyStatus(partyBs[i], status);
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IControlEvents {
    event RoleGranted(bytes32 role, address user);
    event RoleRevoked(bytes32 role, address user);
    event SetMuonConfig(
        uint256 upnlValidTime,
        uint256 priceValidTime,
        uint256 priceQuantityValidTime
    );
    event SetMuonIds(uint256 muonAppId, address gateway, uint256 x, uint8 parity);
    event SetCollateral(address collateral);
    event AddSymbol(
        uint256 id,
        string name,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF,
        uint256 tradingFee,
        uint256 maxLeverage,
        uint256 fundingRateEpochDuration,
        uint256 fundingRateWindowTime
    );
    event SetFeeCollector(address oldFeeCollector, address newFeeCollector);
    event SetSymbolValidationState(uint256 id, bool oldState, bool isValid);
    event SetSymbolFundingState(uint256 id, uint256 fundingRateEpochDuration, uint256 fundingRateWindowTime);
    event SetSymbolAcceptableValues(
        uint256 symbolId,
        uint256 oldMinAcceptableQuoteValue,
        uint256 oldMinAcceptablePortionLF,
        uint256 minAcceptableQuoteValue,
        uint256 minAcceptablePortionLF
    );
    event SetSymbolTradingFee(uint256 symbolId, uint256 oldTradingFee, uint256 tradingFee);
    event SetSymbolMaxSlippage(uint256 symbolId, uint256 oldMaxSlippage, uint256 maxSlippage);
    event SetSymbolMaxLeverage(uint256 symbolId, uint256 oldMaxLeverage, uint256 maxLeverage);
    event SetDeallocateCooldown(uint256 oldDeallocateCooldown, uint256 newDeallocateCooldown);
    event SetForceCancelCooldown(uint256 oldForceCancelCooldown, uint256 newForceCancelCooldown);
    event SetForceCloseCooldown(uint256 oldForceCloseCooldown, uint256 newForceCloseCooldown);
    event SetForceCancelCloseCooldown(
        uint256 oldForceCancelCloseCooldown,
        uint256 newForceCancelCloseCooldown
    );
    event SetLiquidatorShare(uint256 oldLiquidatorShare, uint256 newLiquidatorShare);
    event SetForceCloseGapRatio(uint256 oldForceCloseGapRatio, uint256 newForceCloseGapRatio);
    event SetPendingQuotesValidLength(
        uint256 oldPendingQuotesValidLength,
        uint256 newPendingQuotesValidLength
    );
    event PauseGlobal();
    event PauseLiquidation();
    event PauseAccounting();
    event PausePartyAActions();
    event PausePartyBActions();
    event ActiveEmergencyMode();
    event UnpauseGlobal();
    event UnpauseLiquidation();
    event UnpauseAccounting();
    event UnpausePartyAActions();
    event UnpausePartyBActions();
    event DeactiveEmergencyMode();
    event SetLiquidationTimeout(uint256 oldLiquidationTimeout, uint256 newLiquidationTimeout);
    event SetSuspendedAddress(address user, bool isSuspended);
    event SetPartyBEmergencyStatus(address partyB, bool status);
    event SetBalanceLimitPerUser(uint256 balanceLimitPerUser);
    event RegisterPartyB(address partyB);
    event DeregisterPartyB(address partyB, uint256 index);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    // Add=0, Replace=1, Remove=2
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/GlobalAppStorage.sol";

library LibAccessibility {
    bytes32 public constant DEFAULT_ADMIN_ROLE = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant MUON_SETTER_ROLE = keccak256("MUON_SETTER_ROLE");
    bytes32 public constant SYMBOL_MANAGER_ROLE = keccak256("SYMBOL_MANAGER_ROLE");
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");
    bytes32 public constant PARTY_B_MANAGER_ROLE = keccak256("PARTY_B_MANAGER_ROLE");
    bytes32 public constant LIQUIDATOR_ROLE = keccak256("LIQUIDATOR_ROLE");
    bytes32 public constant SUSPENDER_ROLE = keccak256("SUSPENDER_ROLE");
    bytes32 public constant DISPUTE_ROLE = keccak256("DISPUTE_ROLE");

    function hasRole(address user, bytes32 role) internal view returns (bool) {
        GlobalAppStorage.Layout storage layout = GlobalAppStorage.layout();
        return layout.hasRole[user][role];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

library LibDiamond {
    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsOwnerOrContract() internal view {
        require(
            msg.sender == diamondStorage().contractOwner || msg.sender == address(this),
            "LibDiamond: Must be contract or owner"
        );
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(
                _facetAddress,
                selectorCount
            );
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Replace facet can't be address(0)");
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddress != address(this),
                "LibDiamondCut: Can't replace immutable function"
            );
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            require(
                oldFacetAddress != address(0),
                "LibDiamondCut: Can't replace function that doesn't exist"
            );
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds
                .facetAddressAndSelectorPosition[selector];
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(0),
                "LibDiamondCut: Can't remove function that doesn't exist"
            );
            // can't remove immutable functions -- functions defined directly in the diamond
            require(
                oldFacetAddressAndSelectorPosition.facetAddress != address(this),
                "LibDiamondCut: Can't remove immutable function."
            );
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds
                    .facetAddressAndSelectorPosition[lastSelector]
                    .selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../storages/QuoteStorage.sol";

struct LockedValues {
    uint256 cva;
    uint256 lf;
    uint256 partyAmm;
    uint256 partyBmm;
}

library LockedValuesOps {
    using SafeMath for uint256;

    function add(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.add(a.cva);
        self.partyAmm = self.partyAmm.add(a.partyAmm);
        self.partyBmm = self.partyBmm.add(a.partyBmm);
        self.lf = self.lf.add(a.lf);
        return self;
    }

    function addQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return add(self, quote.lockedValues);
    }

    function sub(LockedValues storage self, LockedValues memory a)
        internal
        returns (LockedValues storage)
    {
        self.cva = self.cva.sub(a.cva);
        self.partyAmm = self.partyAmm.sub(a.partyAmm);
        self.partyBmm = self.partyBmm.sub(a.partyBmm);
        self.lf = self.lf.sub(a.lf);
        return self;
    }

    function subQuote(LockedValues storage self, Quote storage quote)
        internal
        returns (LockedValues storage)
    {
        return sub(self, quote.lockedValues);
    }

    function makeZero(LockedValues storage self) internal returns (LockedValues storage) {
        self.cva = 0;
        self.partyAmm = 0;
        self.partyBmm = 0;
        self.lf = 0;
        return self;
    }

    function totalForPartyA(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyAmm + self.lf;
    }

    function totalForPartyB(LockedValues memory self) internal pure returns (uint256) {
        return self.cva + self.partyBmm + self.lf;
    }

    function mul(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.mul(a);
        self.partyAmm = self.partyAmm.mul(a);
        self.partyBmm = self.partyBmm.mul(a);
        self.lf = self.lf.mul(a);
        return self;
    }

    function mulMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.mul(a),
            self.lf.mul(a),
            self.partyAmm.mul(a),
            self.partyBmm.mul(a)
        );
        return lockedValues;
    }

    function div(LockedValues storage self, uint256 a) internal returns (LockedValues storage) {
        self.cva = self.cva.div(a);
        self.partyAmm = self.partyAmm.div(a);
        self.partyBmm = self.partyBmm.div(a);
        self.lf = self.lf.div(a);
        return self;
    }

    function divMem(LockedValues memory self, uint256 a)
        internal
        pure
        returns (LockedValues memory)
    {
        LockedValues memory lockedValues = LockedValues(
            self.cva.div(a),
            self.lf.div(a),
            self.partyAmm.div(a),
            self.partyBmm.div(a)
        );
        return lockedValues;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum LiquidationType {
    NONE,
    NORMAL,
    LATE,
    OVERDUE
}

struct SettlementState {
    int256 actualAmount; 
    int256 expectedAmount; 
    uint256 cva;
    bool pending;
}

struct LiquidationDetail {
    bytes liquidationId;
    LiquidationType liquidationType;
    int256 upnl;
    int256 totalUnrealizedLoss;
    uint256 deficit;
    uint256 liquidationFee;
    uint256 timestamp;
    uint256 involvedPartyBCounts;
    int256 partyAAccumulatedUpnl;
    bool disputed;
}

struct Price {
    uint256 price;
    uint256 timestamp;
}

library AccountStorage {
    bytes32 internal constant ACCOUNT_STORAGE_SLOT = keccak256("diamond.standard.storage.account");

    struct Layout {
        // Users deposited amounts
        mapping(address => uint256) balances;
        mapping(address => uint256) allocatedBalances;
        // position value will become pending locked before openPosition and will be locked after that
        mapping(address => LockedValues) pendingLockedBalances;
        mapping(address => LockedValues) lockedBalances;
        mapping(address => mapping(address => uint256)) partyBAllocatedBalances;
        mapping(address => mapping(address => LockedValues)) partyBPendingLockedBalances;
        mapping(address => mapping(address => LockedValues)) partyBLockedBalances;
        mapping(address => uint256) withdrawCooldown;
        mapping(address => uint256) partyANonces;
        mapping(address => mapping(address => uint256)) partyBNonces;
        mapping(address => bool) suspendedAddresses;
        mapping(address => LiquidationDetail) liquidationDetails;
        mapping(address => mapping(uint256 => Price)) symbolsPrices;
        mapping(address => address[]) liquidators;
        mapping(address => uint256) partyAReimbursement;
        // partyA => partyB => SettlementState
        mapping(address => mapping(address => SettlementState)) settlementStates;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = ACCOUNT_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library GlobalAppStorage {
    bytes32 internal constant GLOBAL_APP_STORAGE_SLOT =
        keccak256("diamond.standard.storage.global");

    struct Layout {
        address collateral;
        address feeCollector;
        bool globalPaused;
        bool liquidationPaused;
        bool accountingPaused;
        bool partyBActionsPaused;
        bool partyAActionsPaused;
        bool emergencyMode;
        uint256 balanceLimitPerUser;
        mapping(address => bool) partyBEmergencyStatus;
        mapping(address => mapping(bytes32 => bool)) hasRole;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = GLOBAL_APP_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

library MAStorage {
    bytes32 internal constant MA_STORAGE_SLOT =
        keccak256("diamond.standard.storage.masteragreement");

    struct Layout {
        uint256 deallocateCooldown;
        uint256 forceCancelCooldown;
        uint256 forceCancelCloseCooldown;
        uint256 forceCloseCooldown;
        uint256 liquidationTimeout;
        uint256 liquidatorShare; // in 18 decimals
        uint256 pendingQuotesValidLength;
        uint256 forceCloseGapRatio;
        mapping(address => bool) partyBStatus;
        mapping(address => bool) liquidationStatus;
        mapping(address => mapping(address => bool)) partyBLiquidationStatus;
        mapping(address => mapping(address => uint256)) partyBLiquidationTimestamp;
        mapping(address => mapping(address => uint256)) partyBPositionLiquidatorsShare;
        address[] partyBList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MA_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}

struct PublicKey {
    uint256 x;
    uint8 parity;
}

struct SingleUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct SingleUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnl;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct PairUpnlAndPriceSig {
    bytes reqId;
    uint256 timestamp;
    int256 upnlPartyA;
    int256 upnlPartyB;
    uint256 price;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct LiquidationSig {
    bytes reqId;
    uint256 timestamp;
    bytes liquidationId;
    int256 upnl;
    int256 totalUnrealizedLoss; 
    uint256[] symbolIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

struct QuotePriceSig {
    bytes reqId;
    uint256 timestamp;
    uint256[] quoteIds;
    uint256[] prices;
    bytes gatewaySignature;
    SchnorrSign sigs;
}

library MuonStorage {
    bytes32 internal constant MUON_STORAGE_SLOT = keccak256("diamond.standard.storage.muon");

    struct Layout {
        uint256 upnlValidTime;
        uint256 priceValidTime;
        uint256 priceQuantityValidTime;
        uint256 muonAppId;
        PublicKey muonPublicKey;
        address validGateway;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = MUON_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibLockedValues.sol";

enum PositionType {
    LONG,
    SHORT
}

enum OrderType {
    LIMIT,
    MARKET
}

enum QuoteStatus {
    PENDING, //0
    LOCKED, //1
    CANCEL_PENDING, //2
    CANCELED, //3
    OPENED, //4
    CLOSE_PENDING, //5
    CANCEL_CLOSE_PENDING, //6
    CLOSED, //7
    LIQUIDATED, //8
    EXPIRED //9
}

struct Quote {
    uint256 id;
    address[] partyBsWhiteList;
    uint256 symbolId;
    PositionType positionType;
    OrderType orderType;
    // Price of quote which PartyB opened in 18 decimals
    uint256 openedPrice;
    uint256 initialOpenedPrice;
    // Price of quote which PartyA requested in 18 decimals
    uint256 requestedOpenPrice;
    uint256 marketPrice;
    // Quantity of quote which PartyA requested in 18 decimals
    uint256 quantity;
    // Quantity of quote which PartyB has closed until now in 18 decimals
    uint256 closedAmount;
    LockedValues initialLockedValues;
    LockedValues lockedValues;
    uint256 maxFundingRate;
    address partyA;
    address partyB;
    QuoteStatus quoteStatus;
    uint256 avgClosedPrice;
    uint256 requestedClosePrice;
    uint256 quantityToClose;
    // handle partially open position
    uint256 parentId;
    uint256 createTimestamp;
    uint256 statusModifyTimestamp;
    uint256 lastFundingPaymentTimestamp;
    uint256 deadline;
    uint256 tradingFee;
}

library QuoteStorage {
    bytes32 internal constant QUOTE_STORAGE_SLOT = keccak256("diamond.standard.storage.quote");

    struct Layout {
        mapping(address => uint256[]) quoteIdsOf;
        mapping(uint256 => Quote) quotes;
        mapping(address => uint256) partyAPositionsCount;
        mapping(address => mapping(address => uint256)) partyBPositionsCount;
        mapping(address => uint256[]) partyAPendingQuotes;
        mapping(address => mapping(address => uint256[])) partyBPendingQuotes;
        mapping(address => uint256[]) partyAOpenPositions;
        mapping(uint256 => uint256) partyAPositionsIndex;
        mapping(address => mapping(address => uint256[])) partyBOpenPositions;
        mapping(uint256 => uint256) partyBPositionsIndex;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = QUOTE_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

struct Symbol {
    uint256 symbolId;
    string name;
    bool isValid;
    uint256 minAcceptableQuoteValue;
    uint256 minAcceptablePortionLF;
    uint256 tradingFee;
    uint256 maxLeverage;
    uint256 fundingRateEpochDuration;
    uint256 fundingRateWindowTime;
}

library SymbolStorage {
    bytes32 internal constant SYMBOL_STORAGE_SLOT = keccak256("diamond.standard.storage.symbol");

    struct Layout {
        mapping(uint256 => Symbol) symbols;
        uint256 lastId;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SYMBOL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../storages/MAStorage.sol";
import "../storages/AccountStorage.sol";
import "../storages/QuoteStorage.sol";
import "../libraries/LibAccessibility.sol";

abstract contract Accessibility {
    modifier onlyPartyB() {
        require(MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Should be partyB");
        _;
    }

    modifier notPartyB() {
        require(!MAStorage.layout().partyBStatus[msg.sender], "Accessibility: Shouldn't be partyB");
        _;
    }

    modifier onlyRole(bytes32 role) {
        require(LibAccessibility.hasRole(msg.sender, role), "Accessibility: Must has role");
        _;
    }

    modifier notLiquidatedPartyA(address partyA) {
        require(
            !MAStorage.layout().liquidationStatus[partyA],
            "Accessibility: PartyA isn't solvent"
        );
        _;
    }

    modifier notLiquidatedPartyB(address partyB, address partyA) {
        require(
            !MAStorage.layout().partyBLiquidationStatus[partyB][partyA],
            "Accessibility: PartyB isn't solvent"
        );
        _;
    }

    modifier notLiquidated(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(
            !MAStorage.layout().liquidationStatus[quote.partyA],
            "Accessibility: PartyA isn't solvent"
        );
        require(
            !MAStorage.layout().partyBLiquidationStatus[quote.partyB][quote.partyA],
            "Accessibility: PartyB isn't solvent"
        );
        require(
            quote.quoteStatus != QuoteStatus.LIQUIDATED && quote.quoteStatus != QuoteStatus.CLOSED,
            "Accessibility: Invalid state"
        );
        _;
    }

    modifier onlyPartyAOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyA == msg.sender, "Accessibility: Should be partyA of quote");
        _;
    }

    modifier onlyPartyBOfQuote(uint256 quoteId) {
        Quote storage quote = QuoteStorage.layout().quotes[quoteId];
        require(quote.partyB == msg.sender, "Accessibility: Should be partyB of quote");
        _;
    }

    modifier notSuspended(address user) {
        require(
            !AccountStorage.layout().suspendedAddresses[user],
            "Accessibility: Sender is Suspended"
        );
        _;
    }
}

// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "../libraries/LibDiamond.sol";

abstract contract Ownable {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyOwnerOrContract() {
        LibDiamond.enforceIsOwnerOrContract();
        _;
    }
}