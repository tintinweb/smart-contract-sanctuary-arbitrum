/**
 *Submitted for verification at Arbiscan.io on 2023-11-13
*/

pragma solidity ^0.8.13;
pragma abicoder v2;

interface ISeadPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
    function claimFees() external returns (uint, uint);
    function tokens() external returns (address, address);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function burn(address to) external returns (uint amount0, uint amount1);
    function mint(address to) external returns (uint liquidity);
    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);
    function getAmountOut(uint, address) external view returns (uint);
}


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

pragma solidity ^0.8.13;

library Sqrt {
    function sqrt(uint y) internal pure returns (uint z) {
        unchecked {
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
}


pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

interface IPoolFactory {
    event SetFeeManager(address feeManager);
    event SetPauser(address pauser);
    event SetPauseState(bool state);
    event SetVoter(address voter);
    event PoolCreated(address indexed token0, address indexed token1, bool indexed stable, address pool, uint256);
    event SetCustomFee(address indexed pool, uint256 fee);

    error FeeInvalid();
    error FeeTooHigh();
    error InvalidPool();
    error NotFeeManager();
    error NotPauser();
    error NotSinkConverter();
    error NotVoter();
    error PoolAlreadyExists();
    error SameAddress();
    error ZeroFee();
    error ZeroAddress();

    /// @notice returns the number of pools created from this factory
    function allPoolsLength() external view returns (uint256);

    /// @notice Is a valid pool created by this factory.
    /// @param .
    function isPool(address pool) external view returns (bool);

    /// @notice Support for Velodrome v1 which wraps around isPool(pool);
    /// @param .
    function isPair(address pool) external view returns (bool);

    /// @notice Return address of pool created by this factory
    /// @param tokenA .
    /// @param tokenB .
    /// @param stable True if stable, false if volatile
    function getPool(address tokenA, address tokenB, bool stable) external view returns (address);

    /// @notice Support for v3-style pools which wraps around getPool(tokenA,tokenB,stable)
    /// @dev fee is converted to stable boolean.
    /// @param tokenA .
    /// @param tokenB .
    /// @param fee  1 if stable, 0 if volatile, else returns address(0)
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);

    /// @notice Support for Velodrome v1 pools as a "pool" was previously referenced as "pair"
    /// @notice Wraps around getPool(tokenA,tokenB,stable)
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address);

    /// @dev Only called once to set to Voter.sol - Voter does not have a function
    ///      to call this contract method, so once set it's immutable.
    ///      This also follows convention of setVoterAndDistributor() in VotingEscrow.sol
    /// @param _voter .
    function setVoter(address _voter) external;

    function setSinkConverter(address _sinkConvert, address _velo, address _veloV2) external;

    function setPauser(address _pauser) external;

    function setPauseState(bool _state) external;

    function setFeeManager(address _feeManager) external;

    /// @notice Set default fee for stable and volatile pools.
    /// @dev Throws if higher than maximum fee.
    ///      Throws if fee is zero.
    /// @param _stable Stable or volatile pool.
    /// @param _fee .
    function setFee(bool _stable, uint256 _fee) external;

    /// @notice Set overriding fee for a pool from the default
    /// @dev A custom fee of zero means the default fee will be used.
    function setCustomFee(address _pool, uint256 _fee) external;

    /// @notice Returns fee for a pool, as custom fees are possible.
    function getFee(address _pool, bool _stable) external view returns (uint256);

    /// @notice Create a pool given two tokens and if they're stable/volatile
    /// @dev token order does not matter
    /// @param tokenA .
    /// @param tokenB .
    /// @param stable .
    function createPool(address tokenA, address tokenB, bool stable) external returns (address pool);

    /// @notice Support for v3-style pools which wraps around createPool(tokena,tokenB,stable)
    /// @dev fee is converted to stable boolean
    /// @dev token order does not matter
    /// @param tokenA .
    /// @param tokenB .
    /// @param fee 1 if stable, 0 if volatile, else revert
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);

    /// @notice Support for Velodrome v1 which wraps around createPool(tokenA,tokenB,stable)
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pool);

    function isPaused() external view returns (bool);

    function velo() external view returns (address);

    function veloV2() external view returns (address);

    function voter() external view returns (address);

    function sinkConverter() external view returns (address);

    function implementation() external view returns (address);
}


interface IBasePrices {
    /**
    * @notice Gets exchange rates between a series of source tokens and a destination token.
    * @param src_len The length of the source tokens.
    * @param connectors Array of ERC20 tokens where the first src_len elements are source tokens, 
    *        the elements from src_len to len(connectors)-2 are connector tokens, 
    *        and the last element is the destination token.
    * @return rates Array of exchange rates.
    */
    function getManyRatesWithConnectors(uint8 src_len, IERC20Metadata[] memory connectors) external view returns (uint256[] memory rates);
}

/// @title BasePrices
/// @author @AkemiHomura-maow, @ethzoomer
/// @notice An oracle contract to fetch and calculate rates for a given set of connectors
/// @dev The routing is done by greedily choose the pool with the most amount of input tokens.
/// The DFS search is performed iteratively, and stops until we have reached the target token,
/// or when the max budget for search has been consumed.
contract BasePrices is IBasePrices {
    using Sqrt for uint256;

    /// @notice The address of the poolFactory contract
    address public immutable factoryV2;

    /// @notice Maximum number of hops allowed for rate calculations
    uint8 maxHop = 10;

    /// @param _factoryV2 Address of the factory contract for Sead pairs
    constructor(address _factoryV2) {
        factoryV2 = _factoryV2;
    }

    /// @notice Struct to hold balance information for a pair
    struct BalanceInfo {
        uint256 bal0;
        uint256 bal1;
        bool isStable;
    }

    /// @notice Struct to hold path information including intermediate token index and rate
    struct Path {
        uint8 to_i;
        uint256 rate;
    }

    /// @notice Struct to hold return value for balance fetching function
    struct ReturnVal {
        bool mod;
        bool isStable;
        uint256 bal0;
        uint256 bal1;
    }

    /// @notice Struct to hold array variables used in rate calculation, to avoid stack too deep error
    struct Arrays {
        uint256[] rates;
        Path[] paths;
        int256[] decimals;
        uint8[] visited;
    }

    /// @notice Struct to hold iteration variables used in rate calculation, to avoid stack too deep error
    struct IterVars {
        uint256 cur_rate;
        uint256 rate;
        uint8 from_i;
        uint8 to_i;
        bool seen;
    }

    /// @notice Internal function to get balance of two tokens
    /// @param from First token of the pair
    /// @param to Second token of the pair
    /// @param in_bal0 Initial balance of the first token
    /// @return out ReturnVal structure with balance information
    function _get_bal(IERC20Metadata from, IERC20Metadata to, uint256 in_bal0)
        internal
        view
        returns (ReturnVal memory out)
    {
        (uint256 b0, uint256 b1) = _getBalances(from, to, false);
        (uint256 b2, uint256 b3) = _getBalances(from, to, true);
        if (b0 > in_bal0 || b2 > in_bal0) {
            out.mod = true;
            if (b0 > b2) (out.bal0, out.bal1, out.isStable) = (b0, b1, false);
            else (out.bal0, out.bal1, out.isStable) = (b2, b3, true);
        }
    }

    /**
     * @inheritdoc IBasePrices
     */
    function getManyRatesWithConnectors(uint8 src_len, IERC20Metadata[] memory connectors)
        external
        view
        returns (uint256[] memory rates)
    {
        uint8 j_max = min(maxHop, uint8(connectors.length - src_len));
        Arrays memory arr;
        arr.rates = new uint256[]( src_len );
        arr.paths = new Path[]( (connectors.length - src_len ));
        arr.decimals = new int[](connectors.length);

        // Caching decimals of all connector tokens
        {
            for (uint8 i = 0; i < connectors.length; i++) {
                arr.decimals[i] = int256(uint256(connectors[i].decimals()));
            }
        }

        // Iterating through srcTokens
        for (uint8 src = 0; src < src_len; src++) {
            IterVars memory vars;
            vars.cur_rate = 1;
            vars.from_i = src;
            arr.visited = new uint8[](connectors.length - src_len);
            // Counting hops
            for (uint8 j = 0; j < j_max; j++) {
                BalanceInfo memory balInfo = BalanceInfo(0, 0, false);
                vars.to_i = 0;
                // Going through all connectors
                for (uint8 i = src_len; i < connectors.length; i++) {
                    // Check if the current connector has been used to prevent cycles
                    vars.seen = false;
                    {
                        for (uint8 c = 0; c < j; c++) {
                            if (arr.visited[c] == i) {
                                vars.seen = true;
                                break;
                            }
                        }
                    }
                    if (vars.seen) continue;
                    ReturnVal memory out = _get_bal(connectors[vars.from_i], connectors[i], balInfo.bal0);
                    if (out.mod) {
                        balInfo.isStable = out.isStable;
                        balInfo.bal0 = out.bal0;
                        balInfo.bal1 = out.bal1;
                        vars.to_i = i;
                    }
                }

                if (vars.to_i == 0) {
                    arr.rates[src] = 0;
                    break;
                }

                if (balInfo.isStable) {
                    vars.rate = _stableRate(
                        connectors[vars.from_i],
                        connectors[vars.to_i],
                        arr.decimals[vars.from_i] - arr.decimals[vars.to_i]
                    );
                } else {
                    vars.rate =
                        _volatileRate(balInfo.bal0, balInfo.bal1, arr.decimals[vars.from_i] - arr.decimals[vars.to_i]);
                }

                vars.cur_rate *= vars.rate;
                if (j > 0) vars.cur_rate /= 1e18;

                // If from_i points to a connector, cache swap rate for connectors[from_i] : connectors[to_i]
                if (vars.from_i >= src_len) {
                    arr.paths[vars.from_i - src_len] = Path(vars.to_i, vars.rate);
                }
                // If from_i points to a srcToken, check if to_i is a connector which has already been expanded.
                // If so, directly follow the cached path to dstToken to get the final rate.
                else {
                    if (arr.paths[vars.to_i - src_len].rate > 0) {
                        while (true) {
                            vars.cur_rate = vars.cur_rate * arr.paths[vars.to_i - src_len].rate / 1e18;
                            vars.to_i = arr.paths[vars.to_i - src_len].to_i;
                            if (vars.to_i == connectors.length - 1) {
                                arr.rates[src] = vars.cur_rate;
                                break;
                            }
                        }
                    }
                }
                arr.visited[j] = vars.to_i;

                // Next token is dstToken, stop
                if (vars.to_i == connectors.length - 1) {
                    arr.rates[src] = vars.cur_rate;
                    break;
                }
                vars.from_i = vars.to_i;
            }
        }
        return arr.rates;
    }

    /// @notice Internal function to calculate the volatile rate for a pair
    /// @dev For volatile pools, the price (negative derivative) is trivial and can be calculated by b1/b0
    /// @param b0 Balance of the first token
    /// @param b1 Balance of the second token
    /// @param dec_diff Decimal difference between the two tokens
    /// @return rate Calculated exchange rate, scaled by 1e18
    function _volatileRate(uint256 b0, uint256 b1, int256 dec_diff) internal pure returns (uint256 rate) {
        // b0 has less 0s
        if (dec_diff < 0) {
            rate = (1e18 * b1) / (b0 * 10 ** (uint256(-dec_diff)));
        }
        // b0 has more 0s
        else {
            rate = (1e18 * 10 ** (uint256(dec_diff)) * b1) / b0;
        }
    }

    /// @notice Internal function to calculate the stable rate for a pair
    /// @dev For stable pools, the price (negative derivative) is non-trivial to solve. The rate is thus obtained
    /// by simulating a trade of an amount equal to 1 unit of the first token (t0)
    /// in the pair and seeing how much of the second token (t1) that would buy, taking into consideration
    /// the difference in decimal places between the two tokens.
    /// @param t0 First token of the pair
    /// @param t1 Second token of the pair
    /// @param dec_diff Decimal difference between the two tokens
    /// @return rate Calculated exchange rate, scaled by 1e18
    function _stableRate(IERC20Metadata t0, IERC20Metadata t1, int256 dec_diff) internal view returns (uint256 rate) {
        uint256 t0_dec = t0.decimals();
        address currentPair = _orderedPairFor(t0, t1, true);
        uint256 newOut = 0;

        // newOut in t1
        try ISeadPair(currentPair).getAmountOut((10**t0_dec), address(t0)) returns (uint256 result) {
            newOut = result;
        } catch {
            return 0;
        }

        // t0 has less 0s
        if (dec_diff < 0) {
            rate = (1e18 * newOut) / (10 ** t0_dec * 10 ** (uint256(-dec_diff)));
        }
        // t0 has more 0s
        else {
            rate = (1e18 * (newOut * 10 ** (uint256(dec_diff)))) / (10 ** t0_dec);
        }
    }

    /// @notice Internal function to calculate the CREATE2 address for a pair without making any external calls
    /// @param tokenA First token of the pair
    /// @param tokenB Second token of the pair
    /// @param stable Whether the pair is stable or not
    /// @return pair Address of the pair
    function _pairFor(IERC20Metadata tokenA, IERC20Metadata tokenB, bool stable) private view returns (address pair) {
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB, stable));
        pair = Clones.predictDeterministicAddress(IPoolFactory(factoryV2).implementation(), salt, factoryV2);
    }

    /// @notice Internal function to get the reserves of a pair, preserving the order of srcToken and dstToken
    /// @param srcToken Source token of the pair
    /// @param dstToken Destination token of the pair
    /// @param stable Whether the pair is stable or not
    /// @return srcBalance Reserve of the source token
    /// @return dstBalance Reserve of the destination token
    function _getBalances(IERC20Metadata srcToken, IERC20Metadata dstToken, bool stable)
        internal
        view
        returns (uint256 srcBalance, uint256 dstBalance)
    {
        (IERC20Metadata token0, IERC20Metadata token1) =
            srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        address pairAddress = _pairFor(token0, token1, stable);

        // if the pair doesn't exist, return 0
        if (!Address.isContract(pairAddress)) {
            srcBalance = 0;
            dstBalance = 0;
        } else {
            (uint256 reserve0, uint256 reserve1,) = ISeadPair(pairAddress).getReserves();
            (srcBalance, dstBalance) = srcToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }
    }

    /// @notice Internal function to fetch the pair from tokens using correct order
    /// @param tokenA First input token
    /// @param tokenB Second input token
    /// @param stable Whether the pair is stable or not
    /// @return pairAddress Address of the ordered pair
    function _orderedPairFor(IERC20Metadata tokenA, IERC20Metadata tokenB, bool stable)
        internal
        view
        returns (address pairAddress)
    {
        (IERC20Metadata token0, IERC20Metadata token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pairAddress = _pairFor(token0, token1, stable);
    }

    /// @notice Internal function to get the minimum of two uint8 values
    /// @param a First value
    /// @param b Second value
    /// @return Minimum of the two values
    function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a < b ? a : b;
    }
}