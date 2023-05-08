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


// File contracts/StaikSushiswapV2Oracle.sol

// SPDX-License-Identifier: UNLICENSED

//     ███████╗████████╗ █████╗ ██╗██╗  ██╗    █████╗ ██╗
//     ██╔════╝╚══██╔══╝██╔══██╗██║██║ ██╔╝   ██╔══██╗██║
//     ███████╗   ██║   ███████║██║█████╔╝    ███████║██║
//     ╚════██║   ██║   ██╔══██║██║██╔═██╗    ██╔══██║██║
//     ███████║   ██║   ██║  ██║██║██║  ██╗██╗██║  ██║██║
//     ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝

pragma solidity ^0.8.0;
interface IOracle {
    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view returns (uint256 rate, uint256 weight);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

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

abstract contract OracleBase is IOracle {
    using Sqrt for uint256;

    /**
    The purpose of the _NONE variable is to act as a sentinel value, indicating that there is no 
    connector token being used when calling the getRate() or getRateForFee() functions. 
    Instead of passing a real ERC20 token as the connector, the _NONE value is used to signal 
    that a direct swap between the source and destination tokens should be considered. 
    It helps to simplify the logic in the getRateForFee() function when determining how to 
    calculate the rate between the source and destination tokens.
    */
    IERC20 private constant _NONE = IERC20(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    function getRate(IERC20 srcToken, IERC20 dstToken, IERC20 connector) external view override returns (uint256 rate, uint256 weight) {
        uint256 balance0;
        uint256 balance1;
        if (connector == _NONE) {
            (balance0, balance1) = _getBalances(srcToken, dstToken);
        } else {
            uint256 balanceConnector0;
            uint256 balanceConnector1;
            (balance0, balanceConnector0) = _getBalances(srcToken, connector);
            (balanceConnector1, balance1) = _getBalances(connector, dstToken);
            if (balanceConnector0 > balanceConnector1) {
                balance0 = (balance0 * balanceConnector1) / balanceConnector0;
            } else {
                balance1 = (balance1 * balanceConnector0) / balanceConnector1;
            }
        }

        rate = (balance1 * 1e18) / balance0;
        weight = (balance0 * balance1).sqrt();
    }

    function _getBalances(IERC20 srcToken, IERC20 dstToken) internal view virtual returns (uint256 srcBalance, uint256 dstBalance);
    }


/// @title StaikSushiSwapV2Oracle - A SushiSwap V2-based oracle for determining token rates and weights.
/// @notice This contract implements the IOracle interface and extends the OracleBase abstract contract.
contract StaikSushiSwapV2Oracle is OracleBase {

    /// @notice The factory address used for calculating the pair address.
    /// @dev This is the factory address.
    address public immutable factory;
    /// @notice The initcode hash used for calculating the pair address.
    /// @dev This is the init code hash, obtained from the factory contract
    bytes32 public immutable initcodeHash;



    /// @notice Constructs a new StaikSushiSwapV2Oracle with the provided factory and initcodeHash.
    /// @param _factory - The factory address.
    /// @param _initcodeHash - The init code hash.
    constructor(address _factory, bytes32 _initcodeHash) {
        factory = _factory;
        initcodeHash = _initcodeHash;
    }

    /// @notice Calculates the pair address for the provided tokens.
    /// @param tokenA The first token in the pair.
    /// @param tokenB The second token in the pair.
    /// @return pair - The address of the pair contract for the given tokens.
    function _pairFor(IERC20 tokenA, IERC20 tokenB) private view returns (address pair) {
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        bytes32 hash = keccak256(abi.encodePacked(
            bytes1(0xff),
            factory,
            salt,
            initcodeHash
        ));
        pair = address(bytes20(hash << 96));
    }

    /// @notice Retrieves the token balances for the provided token pair.
    /// @param srcToken The source token.
    /// @param dstToken The destination token.
    /// @return srcBalance - The balance of the source token in the pair contract.
    /// @return dstBalance - The balance of the destination token in the pair contract.
    function _getBalances(IERC20 srcToken, IERC20 dstToken) internal view override returns (uint256 srcBalance, uint256 dstBalance) {
        (IERC20 token0, IERC20 token1) = srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(_pairFor(token0, token1)).getReserves();
        (srcBalance, dstBalance) = srcToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

}