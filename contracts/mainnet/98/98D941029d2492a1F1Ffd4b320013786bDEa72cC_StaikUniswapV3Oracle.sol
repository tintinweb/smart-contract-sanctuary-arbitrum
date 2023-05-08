/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


// File contracts/UniswapV3Oracle.sol

// SPDX-License-Identifier: UNLICENSED

//     ███████╗████████╗ █████╗ ██╗██╗  ██╗    █████╗ ██╗
//     ██╔════╝╚══██╔══╝██╔══██╗██║██║ ██╔╝   ██╔══██╗██║
//     ███████╗   ██║   ███████║██║█████╔╝    ███████║██║
//     ╚════██║   ██║   ██╔══██║██║██╔═██╗    ██╔══██║██║
//     ███████║   ██║   ██║  ██║██║██║  ██╗██╗██║  ██║██║
//     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝

/// @title StaikUniswapV3Oracle
/// @notice An oracle contract that calculates price rates using Uniswap V3 pools with different fees.

pragma solidity ^0.8.0;
/// @notice Interface for the Oracle contract
interface IOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 rate, uint256 weight);
}

/// @notice Interface for Uniswap V3 Pool
interface IUniswapV3Pool {
    function slot0() external view returns (uint160 sqrtPriceX96, int24, uint16, uint16, uint16, uint8, bool);
    function token0() external view returns (IERC20 token);
    function liquidity() external view returns (uint128);
}

/// @notice Library for Sqrt function
library Sqrt {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/// @notice The main oracle contract implementing the IOracle interface
contract StaikUniswapV3Oracle is IOracle {
    using Sqrt for uint256;

    bytes32 public immutable poolInitCodeHash;

    /// @notice factory address - set during initialization
    address public factory;

    /**
    The purpose of the _NONE variable is to act as a sentinel value, indicating that there is no 
    connector token being used when calling the getRate() or getRateForFee() functions. 
    Instead of passing a real ERC20 token as the connector, the _NONE value is used to signal 
    that a direct swap between the source and destination tokens should be considered. 
    It helps to simplify the logic in the getRateForFee() function when determining how to 
    calculate the rate between the source and destination tokens.
    */
    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    /// @notice Constructor that sets the poolInitCodeHash and factory address
    /// @param _poolInitCodeHash The Uniswap V3 pool init code hash
    /// @param _factory The Uniswap V3 factory address
    constructor(bytes32 _poolInitCodeHash, address _factory) {
        poolInitCodeHash = _poolInitCodeHash;
        factory = _factory; // Set the factory state variable in the constructor
    }

    /// @notice Get the rate and weight between two tokens using the specified connector
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param connector Connector token
    /// @return rate - The rate between the two tokens
    /// @return weight - The weight of the rate
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external override view returns (uint256 rate, uint256 weight) {
        uint24[3] memory fees = [uint24(500), 3000, 10000];
        for (uint256 i = 0; i < 3; i++) {
            (uint256 rateForFee, uint256 weightForFee) = getRateForFee(srcToken, dstToken, connector, fees[i]);
            rate = rate + (rateForFee * weightForFee);
            weight = weight + weightForFee;
        }
        if (weight > 0) {
            rate = rate / weight;
            weight = weight.sqrt();
        }
    }

    /// @notice Get the rate and weight between two tokens using the specified connector and fee
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param connector Connector token
    /// @param fee Uniswap V3 pool fee
    /// @return rate - The rate between the two tokens
    /// @return weight - The weight of the rate
    function getRateForFee(IERC20 srcToken, IERC20 dstToken, IERC20 connector, uint24 fee) public view returns (
        uint256 rate, uint256 weight) {
        uint256 balance0;
        uint256 balance1;
        if (connector == _NONE) {
            (rate, balance0, balance1) = _getRate(srcToken, dstToken, fee);
        } else {
            uint256 balanceConnector0;
            uint256 balanceConnector1;
            uint256 rate0;
            uint256 rate1;
            (rate0, balance0, balanceConnector0) = _getRate(srcToken, connector, fee);
            if (balance0 == 0 || balanceConnector0 == 0) {
                return (0, 0);
            }
            (rate1, balanceConnector1, balance1) = _getRate(connector, dstToken, fee);
            if (balanceConnector1 == 0 || balance1 == 0) {
                return (0, 0);
            }

            if (balanceConnector0 > balanceConnector1) {
                balance0 = (balance0 * balanceConnector1) / balanceConnector0;
            } else {
                balance1 = (balance1 * balanceConnector0) / balanceConnector1;
            }

            rate = (rate0 * rate1) / 1e18;
        }

        weight = balance0 * balance1;
    }

    /// @notice Get the rate and balances between two tokens using the specified fee
    /// @param srcToken Source token
    /// @param dstToken Destination token
    /// @param fee Uniswap V3 pool fee
    /// @return rate - The rate between the two tokens
    /// @return srcBalance - The balance of the source token in the pool
    /// @return dstBalance - The balance of the destination token in the pool   
    function _getRate(IERC20 srcToken, IERC20 dstToken, uint24 fee) internal view returns (
        uint256 rate, uint256 srcBalance, uint256 dstBalance) {
        (IERC20 token0, IERC20 token1) = srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        address pool = _getPool(address(token0), address(token1), fee);

        uint256 codeSize;
        assembly {
            codeSize := extcodesize(pool)
        }

        if (codeSize > 0) {
            (uint256 sqrtPriceX96,,,,,,) = IUniswapV3Pool(pool).slot0();
            if (srcToken == token0) {
                rate = ((1e18 * sqrtPriceX96) >> 96) * sqrtPriceX96 >> 96;
            } else {
                rate = (1e18 << 192) / (sqrtPriceX96 * sqrtPriceX96);
            }
            srcBalance = srcToken.balanceOf(address(pool));
            dstBalance = dstToken.balanceOf(address(pool));
        } else {
            return (0, 0, 0);
        }
    }

    /// @notice Get the Uniswap V3 pool address for the specified tokens and fee
    /// @param token0 The first token of the pool
    /// @param token1 The second token of the pool
    /// @param fee The Uniswap V3 pool fee
    /// @return The address of the Uniswap V3 pool
    function _getPool(address token0, address token1, uint24 fee) private view returns (address) {
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(token0, token1, fee)),
                            poolInitCodeHash
                        )
                    )
                )
            )
        );
    }
}