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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IChainlink } from "../../interfaces/oracle/IChainlink.sol";
import { BeefyOracleHelper, BeefyOracleErrors } from "./BeefyOracleHelper.sol";

/// @title Beefy Oracle using Chainlink
/// @author Beefy, @kexley
/// @notice On-chain oracle using Chainlink
library BeefyOracleChainlink {

    /// @notice Fetch price from the Chainlink feed and scale to 18 decimals
    /// @param _data Payload from the central oracle with the address of the Chainlink feed
    /// @return price Retrieved price from the Chainlink feed
    /// @return success Successful price fetch or not
    function getPrice(bytes calldata _data) external view returns (uint256 price, bool success) {
        address chainlink = abi.decode(_data, (address));
        try IChainlink(chainlink).decimals() returns (uint8 decimals) {
            try IChainlink(chainlink).latestAnswer() returns (int256 latestAnswer) {
                price = BeefyOracleHelper.scaleAmount(uint256(latestAnswer), decimals);
                success = true;
            } catch {}
        } catch {}
    }

    /// @notice Data validation for new oracle data being added to central oracle
    /// @param _data Encoded Chainlink feed address
    function validateData(bytes calldata _data) external view {
        address chainlink = abi.decode(_data, (address));
        try IChainlink(chainlink).decimals() returns (uint8) {
            try IChainlink(chainlink).latestAnswer() returns (int256) {
            } catch { revert BeefyOracleErrors.NoAnswer(); }
        } catch { revert BeefyOracleErrors.NoAnswer(); }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @title Beefy Oracle Errors
/// @author Beefy, @kexley
/// @notice Error list for Beefy Oracles
contract BeefyOracleErrors {

    /// @dev No response from the Chainlink feed
    error NoAnswer();

    /// @dev No price for base token
    /// @param token Base token
    error NoBasePrice(address token);

    /// @dev Token is not present in the pair
    /// @param token Input token
    /// @param pair Pair token
    error TokenNotInPair(address token, address pair);

    /// @dev Array length is not correct
    error ArrayLength();

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import { IBeefyOracle } from "../../interfaces/oracle/IBeefyOracle.sol";
import { BeefyOracleErrors } from "./BeefyOracleErrors.sol";

/// @title Beefy Oracle Helper
/// @author Beefy, @kexley
/// @notice Helper functions for Beefy oracles
library BeefyOracleHelper {

    /// @dev Calculate the price of the output token in 18 decimals given the base token price 
    /// and the amount out received from swapping 1 unit of the base token
    /// @param _oracle Central Beefy oracle which stores the base token price
    /// @param _token Address of token to calculate the price of
    /// @param _baseToken Address of the base token used in the price chain
    /// @param _amountOut Amount received from swapping 1 unit of base token into the target token
    /// @return price Price of the target token in 18 decimals
    function priceFromBaseToken(
        address _oracle,
        address _token,
        address _baseToken,
        uint256 _amountOut
    ) internal returns (uint256 price) {
        (uint256 basePrice,) = IBeefyOracle(_oracle).getFreshPrice(_baseToken);
        uint8 decimals = IERC20MetadataUpgradeable(_token).decimals();
        _amountOut = scaleAmount(_amountOut, decimals);
        price =  basePrice * 1 ether / _amountOut;
    }

    /// @dev Scale an input amount to 18 decimals
    /// @param _amount Amount to be scaled up or down
    /// @param _decimals Decimals that the amount is already in
    /// @return scaledAmount New scaled amount in 18 decimals
    function scaleAmount(
        uint256 _amount,
        uint8 _decimals
    ) internal pure returns (uint256 scaledAmount) {
        scaledAmount = _decimals == 18 ? _amount : _amount * 10 ** 18 / 10 ** _decimals;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBeefyOracle {
    function getPrice(address token) external view returns (uint256 price);
    function getPrice(address[] calldata tokens) external view returns (uint256[] memory prices);
    function getFreshPrice(address token) external returns (uint256 price, bool success);
    function getFreshPrice(address[] calldata tokens) external returns (uint256[] memory prices, bool[] memory successes);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IChainlink {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}