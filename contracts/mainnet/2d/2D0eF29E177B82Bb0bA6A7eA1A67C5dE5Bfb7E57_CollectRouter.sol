// SPDX-License-Identifier: No License
/**
 * @title Collect Router
 * @author 0xTaiga
 * @dev Allows for mass collection of the pools once they are expired
 */

import "../interfaces/ILendingPool.sol";

 contract CollectRouter {
    function collect(address[] calldata _pools) external {
        for (uint256 i = 0; i < _pools.length; i++) {
            ILendingPool(_pools[i]).collect();
        }
    }
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import {IERC20MetadataUpgradeable as IERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "./IStructs.sol";

interface ILendingPool is IStructs {
    struct UserReport {
        uint256 borrowAmount; // total borrowed in lend token
        uint256 colAmount; // total collateral borrowed
        uint256 totalFees; // total fees owed at the moment
    }

    event Borrow(
        address borrower,
        uint256 colDepositAmount,
        uint256 borrowAmount,
        uint48 currentFeeRate
    );
    event RollOver(address pool, uint256 colRolled);
    event Collect(uint256 treasuryLend, uint256 treasuryCol, uint256 lenderLend, uint256 lenderCol);
    event BalanceChange(address token, bool incoming, uint256 amount);
    event Repay(address borrower, uint256 colReturned, uint256 repayAmount);
    event UpdateExpiry(uint48 newExpiry);
    event AddBorrower(address newBorrower);
    event Pause(uint256 disabled);

    function initialize(Data calldata data) external;

    function undercollateralized() external view returns (uint256);

    function mintRatio() external view returns (uint256);

    function lendToken() external view returns (IERC20);

    function colToken() external view returns (IERC20);

    function expiry() external view returns (uint48);

    function borrowOnBehalfOf(
        address _borrower,
        uint256 _colDepositAmount,
        uint256 _rate,
        uint256 _estimate
    ) external;

    function owner() external view returns (address);

    function isPrivate() external view returns (uint256);

    function borrowers(address borrower) external view returns (uint256);

    function disabledBorrow() external view returns (uint256);

    function collect() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: No-License
pragma solidity ^0.8.11;

interface IStructs {
    struct Data {
        address deployer;
        uint256 mintRatio;
        address colToken;
        address lendToken;
        uint48 expiry;
        address[] borrowers;
        uint48 protocolFee;
        uint48 protocolColFee;
        address feesManager;
        address oracle;
        address factory;
        uint256 undercollateralized;
    }

    struct UserPoolData {
        uint256 _mintRatio;
        address _colToken;
        address _lendToken;
        uint48 _feeRate;
        uint256 _type;
        uint48 _expiry;
        address[] _borrowers;
        uint256 _undercollateralized;
        uint256 _licenseId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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