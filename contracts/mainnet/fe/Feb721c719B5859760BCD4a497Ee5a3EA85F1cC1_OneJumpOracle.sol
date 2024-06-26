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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

/// @dev Base unit for computations, usually used in scaling (multiplications, divisions)
uint256 constant EXP_SCALE = 1e18;

/// @dev A unit (literal one) in EXP_SCALE, usually used in additions/subtractions
uint256 constant MANTISSA_ONE = EXP_SCALE;

/// @dev The approximate number of seconds per year
uint256 constant SECONDS_PER_YEAR = 31_536_000;

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

/// @notice Thrown if the supplied address is a zero address where it is not allowed
error ZeroAddressNotAllowed();

/// @notice Thrown if the supplied value is 0 where it is not allowed
error ZeroValueNotAllowed();

/// @notice Checks if the provided address is nonzero, reverts otherwise
/// @param address_ Address to check
/// @custom:error ZeroAddressNotAllowed is thrown if the provided address is a zero address
function ensureNonzeroAddress(address address_) pure {
    if (address_ == address(0)) {
        revert ZeroAddressNotAllowed();
    }
}

/// @notice Checks if the provided value is nonzero, reverts otherwise
/// @param value_ Value to check
/// @custom:error ZeroValueNotAllowed is thrown if the provided value is 0
function ensureNonzeroValue(uint256 value_) pure {
    if (value_ == 0) {
        revert ZeroValueNotAllowed();
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.25;

interface OracleInterface {
    function getPrice(address asset) external view returns (uint256);
}

interface ResilientOracleInterface is OracleInterface {
    function updatePrice(address vToken) external;

    function updateAssetPrice(address asset) external;

    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface TwapInterface is OracleInterface {
    function updateTwap(address asset) external returns (uint256);
}

interface BoundValidatorInterface {
    function validatePriceWithAnchorPrice(
        address asset,
        uint256 reporterPrice,
        uint256 anchorPrice
    ) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import { CorrelatedTokenOracle } from "./common/CorrelatedTokenOracle.sol";
import { ensureNonzeroAddress } from "@venusprotocol/solidity-utilities/contracts/validators.sol";
import { OracleInterface } from "../interfaces/OracleInterface.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title OneJumpOracle
 * @author Venus
 * @notice This oracle fetches the price of an asset in through an intermediate asset
 */
contract OneJumpOracle is CorrelatedTokenOracle {
    /// @notice Address of the intermediate oracle
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    OracleInterface public immutable INTERMEDIATE_ORACLE;

    /// @notice Constructor for the implementation contract.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address correlatedToken,
        address underlyingToken,
        address resilientOracle,
        address intermediateOracle
    ) CorrelatedTokenOracle(correlatedToken, underlyingToken, resilientOracle) {
        ensureNonzeroAddress(intermediateOracle);
        INTERMEDIATE_ORACLE = OracleInterface(intermediateOracle);
    }

    /**
     * @notice Fetches the amount of the underlying token for 1 correlated token, using the intermediate oracle
     * @return amount The amount of the underlying token for 1 correlated token scaled by the underlying token decimals
     */
    function _getUnderlyingAmount() internal view override returns (uint256) {
        // uint256 underlyingDecimals = IERC20Metadata(UNDERLYING_TOKEN).decimals();
        // uint256 correlatedDecimals = IERC20Metadata(CORRELATED_TOKEN).decimals();

        uint256 underlyingAmount = INTERMEDIATE_ORACLE.getPrice(CORRELATED_TOKEN);

        return underlyingAmount;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.25;

import { OracleInterface } from "../../interfaces/OracleInterface.sol";
import { ensureNonzeroAddress } from "@venusprotocol/solidity-utilities/contracts/validators.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { EXP_SCALE } from "@venusprotocol/solidity-utilities/contracts/constants.sol";
/**
 * @title CorrelatedTokenOracle
 * @notice This oracle fetches the price of a token that is correlated to another token.
 */
abstract contract CorrelatedTokenOracle is OracleInterface {
    /// @notice Address of the correlated token
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable CORRELATED_TOKEN;

    /// @notice Address of the underlying token
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address public immutable UNDERLYING_TOKEN;

    /// @notice Address of Resilient Oracle
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    OracleInterface public immutable RESILIENT_ORACLE;

    /// @notice Thrown if the token address is invalid
    error InvalidTokenAddress();

    /// @notice Constructor for the implementation contract.
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address correlatedToken, address underlyingToken, address resilientOracle) {
        ensureNonzeroAddress(correlatedToken);
        ensureNonzeroAddress(underlyingToken);
        ensureNonzeroAddress(resilientOracle);
        CORRELATED_TOKEN = correlatedToken;
        UNDERLYING_TOKEN = underlyingToken;
        RESILIENT_ORACLE = OracleInterface(resilientOracle);
    }

    /**
     * @notice Fetches the price of the correlated token
     * @param asset Address of the correlated token
     * @return price The price of the correlated token in scaled decimal places
     */
    function getPrice(address asset) external view override returns (uint256) {
        if (asset != CORRELATED_TOKEN) revert InvalidTokenAddress();

        // get underlying token amount for 1 correlated token scaled by underlying token decimals
        uint256 underlyingAmount = _getUnderlyingAmount();

        // oracle returns (36 - asset decimal) scaled price
        uint256 underlyingUSDPrice = RESILIENT_ORACLE.getPrice(UNDERLYING_TOKEN);

        IERC20Metadata token = IERC20Metadata(CORRELATED_TOKEN);
        uint256 decimals = token.decimals();

        // underlyingAmount (for 1 correlated token) * underlyingUSDPrice / decimals(correlated token)
        return (underlyingAmount * underlyingUSDPrice) / EXP_SCALE;
    }

    /**
     * @notice Gets the underlying amount for correlated token
     * @return underlyingAmount Amount of underlying token
     */
    function _getUnderlyingAmount() internal view virtual returns (uint256);
}