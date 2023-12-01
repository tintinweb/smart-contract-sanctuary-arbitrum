// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IPrfctPair {
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


pragma solidity ^0.8.13;

interface IERC20 {
    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.13;
pragma abicoder v1;

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


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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


// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

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



pragma solidity ^0.8.0;

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

    /// @notice Support for Solidly v1 which wraps around isPool(pool);
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

    /// @notice Support for Solidly v1 pools as a "pool" was previously referenced as "pair"
    /// @notice Wraps around getPool(tokenA,tokenB,stable)
    function getPair(address tokenA, address tokenB, bool stable) external view returns (address);

    /// @dev Only called once to set to Voter.sol - Voter does not have a function
    ///      to call this contract method, so once set it's immutable.
    ///      This also follows convention of setVoterAndDistributor() in VotingEscrow.sol
    /// @param _voter .
    function setVoter(address _voter) external;

    function setSinkConverter(address _sinkConvert, address _prfct, address _prfctV2) external;

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

    /// @notice Support for Solidly v1 which wraps around createPool(tokenA,tokenB,stable)
    function createPair(address tokenA, address tokenB, bool stable) external returns (address pool);

    function isPaused() external view returns (bool);

    function prfct() external view returns (address);

    function prfctV2() external view returns (address);

    function voter() external view returns (address);

    function sinkConverter() external view returns (address);

    function implementation() external view returns (address);
}


pragma solidity ^0.8.13;


contract PrfctOracle {
    using Sqrt for uint256;

    address public immutable factoryV2;
    uint8 maxHop = 10;

    constructor(address _factoryV2) {
        factoryV2 = _factoryV2;
    }

    struct BalanceInfo {
        uint256 bal0;
        uint256 bal1;
        bool isStable;
    }

    struct Path {
        uint8 to_i;
        uint256 rate;
    }

    struct ReturnVal {
        bool mod;
        bool isStable;
        uint256 bal0;
        uint256 bal1;
    }

    struct Arrays {
        uint256[] rates;
        Path[] paths;
        int[] decimals;
        uint8[] visited;
    }

    struct IterVars {
        uint256 cur_rate;
        uint256 rate;
        uint8 from_i;
        uint8 to_i;
        bool seen;
    }

    function _get_bal(IERC20 from, IERC20 to, uint256 in_bal0) internal view returns (ReturnVal memory out) {
        (uint256 b0, uint256 b1) = _getBalances(from, to, false);
        (uint256 b2, uint256 b3) = _getBalances(from, to, true);
        if (b0 > in_bal0 || b2 > in_bal0) {
            out.mod = true;
            if (b0 > b2) {(out.bal0, out.bal1, out.isStable) = (b0,b1,false);}
            else {(out.bal0, out.bal1, out.isStable) = (b2,b3,true);}         
        }
    }

    function getManyRatesWithConnectors(uint8 src_len, IERC20[] memory connectors) external view returns (uint256[] memory rates) {
        uint8 j_max = min(maxHop, uint8(connectors.length - src_len ));
        Arrays memory arr;
        arr.rates = new uint256[]( src_len );
        arr.paths = new Path[]( (connectors.length - src_len ));
        arr.decimals = new int[](connectors.length);

        // Caching decimals of all connector tokens
        {
            for (uint8 i = 0; i < connectors.length; i++){
                arr.decimals[i] = int(uint(connectors[i].decimals()));
            }
        }

        // Iterating through srcTokens
        for (uint8 src = 0; src < src_len; src++){
            IterVars memory vars;
            vars.cur_rate = 1;
            vars.from_i = src;
            arr.visited = new uint8[](connectors.length - src_len);
            // Counting hops
            for (uint8 j = 0; j < j_max; j++){
                BalanceInfo memory balInfo = BalanceInfo(0, 0, false);
                vars.to_i = 0;
                // Going through all connectors
                for (uint8 i = src_len; i < connectors.length; i++) {
                    // Check if the current connector has been used to prevent cycles
                    vars.seen = false;
                    {
                        for (uint8 c = 0; c < j; c++){
                            if (arr.visited[c] == i){vars.seen = true; break;}
                        }
                    }
                    if (vars.seen) {continue;}
                    ReturnVal memory out =  _get_bal(connectors[vars.from_i], connectors[i], balInfo.bal0);
                    if (out.mod){
                        balInfo.isStable = out.isStable;
                        balInfo.bal0 = out.bal0;
                        balInfo.bal1 = out.bal1;
                        vars.to_i = i;
                    }
                }

                if (vars.to_i == 0){
                    arr.rates[src] = 0;
                    break;
                }

                if (balInfo.isStable) {vars.rate = _stableRate(connectors[vars.from_i], connectors[vars.to_i], 
                                                                arr.decimals[vars.from_i] - arr.decimals[vars.to_i]);}
                else                  {vars.rate = _volatileRate(balInfo.bal0, balInfo.bal1, arr.decimals[vars.from_i] - arr.decimals[vars.to_i]);} 

                vars.cur_rate *= vars.rate;
                if (j > 0){vars.cur_rate /= 1e18;}

                // If from_i points to a connector, cache swap rate for connectors[from_i] : connectors[to_i]
                if (vars.from_i >= src_len){ arr.paths[vars.from_i - src_len] = Path(vars.to_i, vars.rate);}
                // If from_i points to a srcToken, check if to_i is a connector which has already been expanded.
                // If so, directly follow the cached path to dstToken to get the final rate.
                else {
                    if (arr.paths[vars.to_i - src_len].rate > 0){
                        while (true){
                            vars.cur_rate = vars.cur_rate * arr.paths[vars.to_i - src_len].rate / 1e18;
                            vars.to_i = arr.paths[vars.to_i - src_len].to_i;
                            if (vars.to_i == connectors.length - 1) {arr.rates[src] = vars.cur_rate; break;}
                        }
                    }
                }
                arr.visited[j] = vars.to_i;

                // Next token is dstToken, stop
                if (vars.to_i == connectors.length - 1) {arr.rates[src] = vars.cur_rate; break;}
                vars.from_i = vars.to_i;

            }
        }
        return arr.rates;
    }

    function _volatileRate(uint256 b0, uint256 b1, int dec_diff) internal pure returns (uint256 rate){
        // b0 has less 0s
        if (dec_diff < 0){
            rate = (1e18 * b1) / (b0 * 10**(uint(-dec_diff)));
        }
        // b0 has more 0s
        else{
            rate = (1e18 * 10**(uint(dec_diff)) * b1) / b0;
        }
    }

    function _stableRate(IERC20 t0, IERC20 t1, int dec_diff) internal view returns (uint256 rate){
        uint256 t0_dec = t0.decimals();
        address currentPair = _orderedPairFor(t0, t1, true);
        // newOut in t1
        uint256 newOut = IPrfctPair(currentPair).getAmountOut((10**t0_dec), address(t0));

        // t0 has less 0s
        if (dec_diff < 0){
            rate = (1e18 * newOut) / (10**t0_dec * 10**(uint(-dec_diff)));
        }
        // t0 has more 0s
        else{
            rate = (1e18 * (newOut * 10**(uint(dec_diff)))) / (10**t0_dec);
        }
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function _pairFor(IERC20 tokenA, IERC20 tokenB, bool stable) private view returns (address pair) {
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB, stable));
        pair = Clones.predictDeterministicAddress(IPoolFactory(factoryV2).implementation(), salt, factoryV2);
    }

    // returns the reserves of a pool if it exists, preserving the order of srcToken and dstToken
    function _getBalances(IERC20 srcToken, IERC20 dstToken, bool stable) internal view returns (uint256 srcBalance, uint256 dstBalance) {
        (IERC20 token0, IERC20 token1) = srcToken < dstToken ? (srcToken, dstToken) : (dstToken, srcToken);
        address pairAddress = _pairFor(token0, token1, stable);

        // if the pair doesn't exist, return 0
        if(!Address.isContract(pairAddress)) {
            srcBalance = 0;
            dstBalance = 0;
        }
        else {
            (uint256 reserve0, uint256 reserve1,) = IPrfctPair(pairAddress).getReserves();
            (srcBalance, dstBalance) = srcToken == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        }
    }

    // fetch pair from tokens using correct order
    function _orderedPairFor(IERC20 tokenA, IERC20 tokenB, bool stable) internal view returns (address pairAddress) {
        (IERC20 token0, IERC20 token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pairAddress = _pairFor(token0, token1, stable);
    }

    function min(uint8 a, uint8 b) internal pure returns (uint8) {
        return a < b ? a : b;
    }
}

pragma solidity ^0.8.13;


interface IPair {
    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);
}

interface IRouter {
    function poolFor(address tokenA, address tokenB, bool stable, address _factory) external view returns (address pool);
}

contract ProtocolLibrary {
    IRouter internal immutable router;
    event Log(uint r0, uint r1, bool st, uint sample);

    constructor(address _router) {
        router = IRouter(_router);
    }

    struct Diffs {
        uint256[] aDiffs;
        uint256[] bDiffs;
    }

    struct PairData {
        uint256 dec0;
        uint256 dec1;
        uint256 r0;
        uint256 r1;
        bool st;
        address t0;
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return x0*(y*y/1e18*y/1e18)/1e18+(x0*x0/1e18*x0/1e18)*y/1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return 3*x0*(y*y/1e18)/1e18+(x0*x0/1e18*x0/1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = (xy - k)*1e18/_d(x0, y);
                y = y + dy;
            } else {
                uint dy = (k - xy)*1e18/_d(x0, y);
                y = y - dy;
            }
            if (y > y_prev) {
                if (y - y_prev <= 1) {
                    return y;
                }
            } else {
                if (y_prev - y <= 1) {
                    return y;
                }
            }
        }
        return y;
    }

    function getTradeDiffs(uint[] memory amountIn, address[] memory tokenIn, address[] memory tokenOut, bool[] memory stable, address[] memory factories) external view returns (uint[] memory a, uint[] memory b) {
        Diffs memory diffs;
        diffs.aDiffs = new uint256[]( amountIn.length );
        diffs.bDiffs = new uint256[]( amountIn.length );
        for (uint16 i = 0; i < amountIn.length; i++) {
            PairData memory pairData;
            (pairData.dec0, pairData.dec1, pairData.r0, pairData.r1, pairData.st, pairData.t0,) = IPair(router.poolFor(tokenIn[i], tokenOut[i], stable[i], factories[i])).metadata();
            if(stable[i]){
                uint sample = tokenIn[i] == pairData.t0 ? pairData.r0*pairData.dec1/pairData.r1 : pairData.r1*pairData.dec0/pairData.r0;
                diffs.aDiffs[i] = _getAmountOut(sample, tokenIn[i], pairData.r0, pairData.r1, pairData.t0, pairData.dec0, pairData.dec1, pairData.st) * 1e18 / sample;
            }
            else{
                diffs.aDiffs[i] = tokenIn[i] == pairData.t0 ? (pairData.r1 * 1e18 / pairData.dec1) * pairData.dec0 / pairData.r0 : (pairData.r0 * 1e18 / pairData.dec0) * pairData.dec1 / pairData.r1;
            }
            diffs.bDiffs[i] = _getAmountOut(amountIn[i], tokenIn[i], pairData.r0, pairData.r1, pairData.t0, pairData.dec0, pairData.dec1, pairData.st) * 1e18 / amountIn[i];
        }
        return (diffs.aDiffs, diffs.bDiffs);
    }

    function getTradeDiff(uint amountIn, address tokenIn, address tokenOut, bool stable, address factory) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(router.poolFor(tokenIn, tokenOut, stable, factory)).metadata();
        if(stable){
            uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
            a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        }
        else{
            a = tokenIn == t0 ? (r1 * 1e18 / dec1) * dec0 / r0 : (r0 * 1e18 / dec0) * dec1 / r1;
        }
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function getTradeDiff(uint amountIn, address tokenIn, address pair) external view returns (uint a, uint b) {
        (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0,) = IPair(pair).metadata();
        uint sample = tokenIn == t0 ? r0*dec1/r1 : r1*dec0/r0;
        a = _getAmountOut(sample, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / sample;
        b = _getAmountOut(amountIn, tokenIn, r0, r1, t0, dec0, dec1, st) * 1e18 / amountIn;
    }

    function _getAmountOut(uint amountIn, address tokenIn, uint _reserve0, uint _reserve1, address token0, uint decimals0, uint decimals1, bool stable) internal pure returns (uint) {
        if (stable) {
            uint xy =  _k(_reserve0, _reserve1, stable, decimals0, decimals1);
            _reserve0 = _reserve0 * 1e18 / decimals0;
            _reserve1 = _reserve1 * 1e18 / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? amountIn * 1e18 / decimals0 : amountIn * 1e18 / decimals1;
            uint y = reserveB - _get_y(amountIn+reserveA, xy, reserveB);
            return y * (tokenIn == token0 ? decimals1 : decimals0) / 1e18;
        } else {
            (uint reserveA, uint reserveB, uint decimalsA, uint decimalsB) = tokenIn == token0 ? (_reserve0, _reserve1, decimals0, decimals1) : (_reserve1, _reserve0, decimals1, decimals0);
            if (decimalsA > decimalsB) {
                return (amountIn * reserveB / (reserveA + amountIn)) * (decimalsA / decimalsB);
            }
            else {
                return (amountIn * reserveB / (reserveA + amountIn)) / (decimalsB / decimalsA);
            }
        }
    }

    function _k(uint x, uint y, bool stable, uint decimals0, uint decimals1) internal pure returns (uint) {
        if (stable) {
            uint _x = x * 1e18 / decimals0;
            uint _y = y * 1e18 / decimals1;
            uint _a = (_x * _y) / 1e18;
            uint _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return _a * _b / 1e18;  // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }
    
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPrfct} from "./interfaces/IPrfct.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAirdropDistributor} from "./interfaces/IAirdropDistributor.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AirdropDistributor is IAirdropDistributor, Ownable {
    using SafeERC20 for IPrfct;
    /// @inheritdoc IAirdropDistributor
    IPrfct public immutable prfct;
    /// @inheritdoc IAirdropDistributor
    IVotingEscrow public immutable ve;

    constructor(address _ve) {
        ve = IVotingEscrow(_ve);
        prfct = IPrfct(IVotingEscrow(_ve).token());
    }

    /// @inheritdoc IAirdropDistributor
    function distributeTokens(address[] memory _wallets, uint256[] memory _amounts) external override onlyOwner {
        uint256 _len = _wallets.length;
        if (_len != _amounts.length) revert InvalidParams();
        uint256 _sum;
        for (uint256 i = 0; i < _len; i++) {
            _sum += _amounts[i];
        }

        if (_sum > prfct.balanceOf(address(this))) revert InsufficientBalance();
        prfct.safeApprove(address(ve), _sum);
        address _wallet;
        uint256 _amount;
        uint256 _tokenId;
        for (uint256 i = 0; i < _len; i++) {
            _wallet = _wallets[i];
            _amount = _amounts[i];
            _tokenId = ve.createLock(_amount, 1 weeks);
            ve.lockPermanent(_tokenId);
            ve.safeTransferFrom(address(this), _wallet, _tokenId);
            emit Airdrop(_wallet, _amount, _tokenId);
        }
        prfct.safeApprove(address(ve), 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IVotes} from "./governance/IVotes.sol";

import {IGovernor} from "./governance/IGovernor.sol";
import {GovernorSimple} from "./governance/GovernorSimple.sol";
import {GovernorCountingMajority} from "./governance/GovernorCountingMajority.sol";
import {GovernorSimpleVotes} from "./governance/GovernorSimpleVotes.sol";

/**
 * @title EpochGovernor
 * @notice Epoch based governance system that allows for a three option majority (against, for, abstain).
 * @notice Refer to SPECIFICATION.md.
 * @dev Note that hash proposals are unique per epoch, but calls to a function with different values
 *      may be allowed any number of times. It is best to use EpochGovernor with a function that accepts
 *      no values.
 */
contract EpochGovernor is GovernorSimple, GovernorCountingMajority, GovernorSimpleVotes {
    constructor(
        address _forwarder,
        IVotes _ve,
        address _minter
    ) GovernorSimple(_forwarder, "Epoch Governor", _minter) GovernorSimpleVotes(_ve) {}

    function votingDelay() public pure override(IGovernor) returns (uint256) {
        return (15 minutes);
    }

    function votingPeriod() public pure override(IGovernor) returns (uint256) {
        return (1 weeks);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IFactoryRegistry} from "../interfaces/factories/IFactoryRegistry.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Protocol Factory Registry
/// @author Carter Carlson (@pegahcarter)
/// @notice Protocol Factory Registry to swap and create gauges
contract FactoryRegistry is IFactoryRegistry, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev factory to create free and locked rewards for a managed veNFT
    address private _managedRewardsFactory;

    /// @dev The protocol will always have a usable poolFactory, votingRewardsFactory, and gaugeFactory.  The votingRewardsFactory
    // and gaugeFactory are defined to the poolFactory which can never be removed
    address public immutable fallbackPoolFactory;

    /// @dev Array of poolFactories used to create a gauge and votingRewards
    EnumerableSet.AddressSet private _poolFactories;

    struct FactoriesToPoolFactory {
        address votingRewardsFactory;
        address gaugeFactory;
    }
    /// @dev the factories linked to the poolFactory
    mapping(address => FactoriesToPoolFactory) private _factoriesToPoolsFactory;

    constructor(
        address _fallbackPoolFactory,
        address _fallbackVotingRewardsFactory,
        address _fallbackGaugeFactory,
        address _newManagedRewardsFactory
    ) {
        fallbackPoolFactory = _fallbackPoolFactory;

        approve(_fallbackPoolFactory, _fallbackVotingRewardsFactory, _fallbackGaugeFactory);
        setManagedRewardsFactory(_newManagedRewardsFactory);
    }

    /// @inheritdoc IFactoryRegistry
    function approve(address poolFactory, address votingRewardsFactory, address gaugeFactory) public onlyOwner {
        if (poolFactory == address(0) || votingRewardsFactory == address(0) || gaugeFactory == address(0))
            revert ZeroAddress();
        if (_poolFactories.contains(poolFactory)) revert PathAlreadyApproved();

        FactoriesToPoolFactory memory usedFactories = _factoriesToPoolsFactory[poolFactory];

        // If the poolFactory *has not* been approved before, can approve any gauge/votingRewards factory
        // Only one check is sufficient
        if (usedFactories.votingRewardsFactory == address(0)) {
            _factoriesToPoolsFactory[poolFactory] = FactoriesToPoolFactory(votingRewardsFactory, gaugeFactory);
        } else {
            // If the poolFactory *has* been approved before, can only approve the same used gauge/votingRewards factory to
            //     to maintain state within Voter
            if (
                votingRewardsFactory != usedFactories.votingRewardsFactory || gaugeFactory != usedFactories.gaugeFactory
            ) revert InvalidFactoriesToPoolFactory();
        }

        _poolFactories.add(poolFactory);
        emit Approve(poolFactory, votingRewardsFactory, gaugeFactory);
    }

    /// @inheritdoc IFactoryRegistry
    function unapprove(address poolFactory) external onlyOwner {
        if (poolFactory == fallbackPoolFactory) revert FallbackFactory();
        if (!_poolFactories.contains(poolFactory)) revert PathNotApproved();
        _poolFactories.remove(poolFactory);
        (address votingRewardsFactory, address gaugeFactory) = factoriesToPoolFactory(poolFactory);
        emit Unapprove(poolFactory, votingRewardsFactory, gaugeFactory);
    }

    /// @inheritdoc IFactoryRegistry
    function setManagedRewardsFactory(address _newManagedRewardsFactory) public onlyOwner {
        if (_newManagedRewardsFactory == _managedRewardsFactory) revert SameAddress();
        if (_newManagedRewardsFactory == address(0)) revert ZeroAddress();
        _managedRewardsFactory = _newManagedRewardsFactory;
        emit SetManagedRewardsFactory(_newManagedRewardsFactory);
    }

    /// @inheritdoc IFactoryRegistry
    function managedRewardsFactory() external view returns (address) {
        return _managedRewardsFactory;
    }

    /// @inheritdoc IFactoryRegistry
    function factoriesToPoolFactory(
        address poolFactory
    ) public view returns (address votingRewardsFactory, address gaugeFactory) {
        FactoriesToPoolFactory memory f = _factoriesToPoolsFactory[poolFactory];
        votingRewardsFactory = f.votingRewardsFactory;
        gaugeFactory = f.gaugeFactory;
    }

    /// @inheritdoc IFactoryRegistry
    function poolFactories() external view returns (address[] memory) {
        return _poolFactories.values();
    }

    /// @inheritdoc IFactoryRegistry
    function isPoolFactoryApproved(address poolFactory) external view returns (bool) {
        return _poolFactories.contains(poolFactory);
    }

    /// @inheritdoc IFactoryRegistry
    function poolFactoriesLength() external view returns (uint256) {
        return _poolFactories.length();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IGaugeFactory} from "../interfaces/factories/IGaugeFactory.sol";
import {Gauge} from "../gauges/Gauge.sol";

contract GaugeFactory is IGaugeFactory {
    function createGauge(
        address _forwarder,
        address _pool,
        address _feesVotingReward,
        address _rewardToken,
        bool isPool
    ) external returns (address gauge) {
        gauge = address(new Gauge(_forwarder, _pool, _feesVotingReward, _rewardToken, msg.sender, isPool));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IManagedRewardsFactory} from "../interfaces/factories/IManagedRewardsFactory.sol";
import {FreeManagedReward} from "../rewards/FreeManagedReward.sol";
import {LockedManagedReward} from "../rewards/LockedManagedReward.sol";

contract ManagedRewardsFactory is IManagedRewardsFactory {
    /// @inheritdoc IManagedRewardsFactory
    function createRewards(
        address _forwarder,
        address _voter
    ) external returns (address lockedManagedReward, address freeManagedReward) {
        lockedManagedReward = address(new LockedManagedReward(_forwarder, _voter));
        freeManagedReward = address(new FreeManagedReward(_forwarder, _voter));
        emit ManagedRewardCreated(_voter, lockedManagedReward, freeManagedReward);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPoolFactory} from "../interfaces/factories/IPoolFactory.sol";
import {IPool} from "../interfaces/IPool.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

contract PoolFactory is IPoolFactory {
    address public immutable implementation;

    bool public isPaused;
    address public pauser;

    uint256 public stableFee;
    uint256 public volatileFee;
    uint256 public constant MAX_FEE = 300; // 3%
    // Override to indicate there is custom 0% fee - as a 0 value in the customFee mapping indicates
    // that no custom fee rate has been set
    uint256 public constant ZERO_FEE_INDICATOR = 420;
    address public feeManager;

    /// @dev used to change the name/symbol of the pool by calling emergencyCouncil
    address public voter;

    mapping(address => mapping(address => mapping(bool => address))) private _getPool;
    address[] public allPools;
    mapping(address => bool) private _isPool; // simplified check if its a pool, given that `stable` flag might not be available in peripherals
    mapping(address => uint256) public customFee; // override for custom fees

    address internal _temp0;
    address internal _temp1;
    bool internal _temp;

    constructor(address _implementation) {
        implementation = _implementation;
        voter = msg.sender;
        pauser = msg.sender;
        feeManager = msg.sender;
        isPaused = false;
        stableFee = 5; // 0.05%
        volatileFee = 30; // 0.3%
    }

    /// @inheritdoc IPoolFactory
    function allPoolsLength() external view returns (uint256) {
        return allPools.length;
    }

    /// @inheritdoc IPoolFactory
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address) {
        return fee > 1 ? address(0) : fee == 1 ? _getPool[tokenA][tokenB][true] : _getPool[tokenA][tokenB][false];
    }

    /// @inheritdoc IPoolFactory
    function getPool(address tokenA, address tokenB, bool stable) external view returns (address) {
        return _getPool[tokenA][tokenB][stable];
    }

    /// @inheritdoc IPoolFactory
    function isPool(address pool) external view returns (bool) {
        return _isPool[pool];
    }

    /// @inheritdoc IPoolFactory
    function setVoter(address _voter) external {
        if (msg.sender != voter) revert NotVoter();
        voter = _voter;
        emit SetVoter(_voter);
    }

    function setPauser(address _pauser) external {
        if (msg.sender != pauser) revert NotPauser();
        if (_pauser == address(0)) revert ZeroAddress();
        pauser = _pauser;
        emit SetPauser(_pauser);
    }

    function setPauseState(bool _state) external {
        if (msg.sender != pauser) revert NotPauser();
        isPaused = _state;
        emit SetPauseState(_state);
    }

    function setFeeManager(address _feeManager) external {
        if (msg.sender != feeManager) revert NotFeeManager();
        if (_feeManager == address(0)) revert ZeroAddress();
        feeManager = _feeManager;
        emit SetFeeManager(_feeManager);
    }

    /// @inheritdoc IPoolFactory
    function setFee(bool _stable, uint256 _fee) external {
        if (msg.sender != feeManager) revert NotFeeManager();
        if (_fee > MAX_FEE) revert FeeTooHigh();
        if (_fee == 0) revert ZeroFee();
        if (_stable) {
            stableFee = _fee;
        } else {
            volatileFee = _fee;
        }
    }

    /// @inheritdoc IPoolFactory
    function setCustomFee(address pool, uint256 fee) external {
        if (msg.sender != feeManager) revert NotFeeManager();
        if (fee > MAX_FEE && fee != ZERO_FEE_INDICATOR) revert FeeTooHigh();
        if (!_isPool[pool]) revert InvalidPool();

        customFee[pool] = fee;
        emit SetCustomFee(pool, fee);
    }

    /// @inheritdoc IPoolFactory
    function getFee(address pool, bool _stable) public view returns (uint256) {
        uint256 fee = customFee[pool];
        return fee == ZERO_FEE_INDICATOR ? 0 : fee != 0 ? fee : _stable ? stableFee : volatileFee;
    }

    /// @inheritdoc IPoolFactory
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool) {
        if (fee > 1) revert FeeInvalid();
        bool stable = fee == 1;
        return createPool(tokenA, tokenB, stable);
    }

    /// @inheritdoc IPoolFactory
    function createPool(address tokenA, address tokenB, bool stable) public returns (address pool) {
        if (tokenA == tokenB) revert SameAddress();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();
        if (_getPool[token0][token1][stable] != address(0)) revert PoolAlreadyExists();
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable)); // salt includes stable as well, 3 parameters
        pool = Clones.cloneDeterministic(implementation, salt);
        IPool(pool).initialize(token0, token1, stable);
        _getPool[token0][token1][stable] = pool;
        _getPool[token1][token0][stable] = pool; // populate mapping in the reverse direction
        allPools.push(pool);
        _isPool[pool] = true;
        emit PoolCreated(token0, token1, stable, pool, allPools.length);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IVotingRewardsFactory} from "../interfaces/factories/IVotingRewardsFactory.sol";
import {FeesVotingReward} from "../rewards/FeesVotingReward.sol";
import {BribeVotingReward} from "../rewards/BribeVotingReward.sol";

contract VotingRewardsFactory is IVotingRewardsFactory {
    /// @inheritdoc IVotingRewardsFactory
    function createRewards(
        address _forwarder,
        address[] memory _rewards
    ) external returns (address feesVotingReward, address bribeVotingReward) {
        feesVotingReward = address(new FeesVotingReward(_forwarder, msg.sender, _rewards));
        bribeVotingReward = address(new BribeVotingReward(_forwarder, msg.sender, _rewards));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IReward} from "../interfaces/IReward.sol";
import {IGauge} from "../interfaces/IGauge.sol";
import {IPool} from "../interfaces/IPool.sol";
import {IVoter} from "../interfaces/IVoter.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ProtocolTimeLibrary} from "../libraries/ProtocolTimeLibrary.sol";

/// @title Protocol Gauge
/// @author veldorome.finance, @figs999, @pegahcarter
/// @notice Gauge contract for distribution of emissions by address
contract Gauge is IGauge, ERC2771Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @inheritdoc IGauge
    address public immutable stakingToken;
    /// @inheritdoc IGauge
    address public immutable rewardToken;
    /// @inheritdoc IGauge
    address public immutable feesVotingReward;
    /// @inheritdoc IGauge
    address public immutable voter;
    /// @inheritdoc IGauge
    address public immutable ve;

    /// @inheritdoc IGauge
    bool public immutable isPool;

    uint256 internal constant DURATION = 7 days; // rewards are released over 7 days
    uint256 internal constant PRECISION = 10 ** 18;
    uint256 public CLAIMLOCKRATE = 30;

    /// @inheritdoc IGauge
    uint256 public periodFinish;
    /// @inheritdoc IGauge
    uint256 public rewardRate;
    /// @inheritdoc IGauge
    uint256 public lastUpdateTime;
    /// @inheritdoc IGauge
    uint256 public rewardPerTokenStored;
    /// @inheritdoc IGauge
    uint256 public totalSupply;
    /// @inheritdoc IGauge
    mapping(address => uint256) public balanceOf;
    /// @inheritdoc IGauge
    mapping(address => uint256) public userRewardPerTokenPaid;
    /// @inheritdoc IGauge
    mapping(address => uint256) public rewards;
    /// @inheritdoc IGauge
    mapping(uint256 => uint256) public rewardRateByEpoch;

    /// @inheritdoc IGauge
    uint256 public fees0;
    /// @inheritdoc IGauge
    uint256 public fees1;

    constructor(
        address _forwarder,
        address _stakingToken,
        address _feesVotingReward,
        address _rewardToken,
        address _voter,
        bool _isPool
    ) ERC2771Context(_forwarder) {
        stakingToken = _stakingToken;
        feesVotingReward = _feesVotingReward;
        rewardToken = _rewardToken;
        voter = _voter;
        isPool = _isPool;
        ve = IVoter(voter).ve();
    }

    function _claimFees() internal returns (uint256 claimed0, uint256 claimed1) {
        if (!isPool) {
            return (0, 0);
        }
        (claimed0, claimed1) = IPool(stakingToken).claimFees();
        if (claimed0 > 0 || claimed1 > 0) {
            uint256 _fees0 = fees0 + claimed0;
            uint256 _fees1 = fees1 + claimed1;
            (address _token0, address _token1) = IPool(stakingToken).tokens();
            if (_fees0 > DURATION) {
                fees0 = 0;
                IERC20(_token0).safeApprove(feesVotingReward, _fees0);
                IReward(feesVotingReward).notifyRewardAmount(_token0, _fees0);
            } else {
                fees0 = _fees0;
            }
            if (_fees1 > DURATION) {
                fees1 = 0;
                IERC20(_token1).safeApprove(feesVotingReward, _fees1);
                IReward(feesVotingReward).notifyRewardAmount(_token1, _fees1);
            } else {
                fees1 = _fees1;
            }

            emit ClaimFees(_msgSender(), claimed0, claimed1);
        }
    }

    /// @inheritdoc IGauge
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * PRECISION) /
            totalSupply;
    }

    /// @inheritdoc IGauge
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /// @inheritdoc IGauge
    function getReward(address _account) external nonReentrant {
        address sender = _msgSender();
        if (sender != _account && sender != voter) revert NotAuthorized();

        _updateRewards(_account);

        uint256 reward = rewards[_account];

        if (reward > 0) {
            uint256 _lockamount = reward * CLAIMLOCKRATE / 100;
            rewards[_account] = 0;
            IERC20(rewardToken).safeTransfer(_account, reward - _lockamount);
            IERC20(rewardToken).safeApprove(address(ve), _lockamount);
            uint256 _tokenId = IVotingEscrow(ve).createLock(_lockamount, 1 weeks);
            IVotingEscrow(ve).safeTransferFrom(address(this), _account, _tokenId);
            emit ClaimRewards(_account, reward);
        }
    }

    /// @inheritdoc IGauge
    function earned(address _account) public view returns (uint256) {
        return
            (balanceOf[_account] * (rewardPerToken() - userRewardPerTokenPaid[_account])) /
            PRECISION +
            rewards[_account];
    }

    /// @inheritdoc IGauge
    function deposit(uint256 _amount) external {
        _depositFor(_amount, _msgSender());
    }

    /// @inheritdoc IGauge
    function deposit(uint256 _amount, address _recipient) external {
        _depositFor(_amount, _recipient);
    }

    function _depositFor(uint256 _amount, address _recipient) internal nonReentrant {
        if (_amount == 0) revert ZeroAmount();
        if (!IVoter(voter).isAlive(address(this))) revert NotAlive();

        address sender = _msgSender();
        _updateRewards(_recipient);

        IERC20(stakingToken).safeTransferFrom(sender, address(this), _amount);
        totalSupply += _amount;
        balanceOf[_recipient] += _amount;

        emit Deposit(sender, _recipient, _amount);
    }

    /// @inheritdoc IGauge
    function withdraw(uint256 _amount) external nonReentrant {
        address sender = _msgSender();

        _updateRewards(sender);

        totalSupply -= _amount;
        balanceOf[sender] -= _amount;
        IERC20(stakingToken).safeTransfer(sender, _amount);

        emit Withdraw(sender, _amount);
    }

    function _updateRewards(address _account) internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[_account] = earned(_account);
        userRewardPerTokenPaid[_account] = rewardPerTokenStored;
    }

    /// @inheritdoc IGauge
    function left() external view returns (uint256) {
        if (block.timestamp >= periodFinish) return 0;
        uint256 _remaining = periodFinish - block.timestamp;
        return _remaining * rewardRate;
    }

    /// @inheritdoc IGauge
    function notifyRewardAmount(uint256 _amount) external nonReentrant {
        address sender = _msgSender();
        if (sender != voter) revert NotVoter();
        if (_amount == 0) revert ZeroAmount();
        _claimFees();
        _notifyRewardAmount(sender, _amount);
    }

    /// @inheritdoc IGauge
    function notifyRewardWithoutClaim(uint256 _amount) external nonReentrant {
        address sender = _msgSender();
        if (sender != IVotingEscrow(ve).team()) revert NotTeam();
        if (_amount == 0) revert ZeroAmount();
        _notifyRewardAmount(sender, _amount);
    }

    function updateClaimLockRate(uint256 _lockrate) external nonReentrant {
        address sender = _msgSender();
        if (sender != IVotingEscrow(ve).team()) revert NotTeam();
        if(_lockrate > 100) revert LockRateTooHigh();
        CLAIMLOCKRATE = _lockrate;
    }

    function _notifyRewardAmount(address sender, uint256 _amount) internal {
        rewardPerTokenStored = rewardPerToken();
        uint256 timestamp = block.timestamp;
        uint256 timeUntilNext = ProtocolTimeLibrary.epochNext(timestamp) - timestamp;

        if (timestamp >= periodFinish) {
            IERC20(rewardToken).safeTransferFrom(sender, address(this), _amount);
            rewardRate = _amount / timeUntilNext;
        } else {
            uint256 _remaining = periodFinish - timestamp;
            uint256 _leftover = _remaining * rewardRate;
            IERC20(rewardToken).safeTransferFrom(sender, address(this), _amount);
            rewardRate = (_amount + _leftover) / timeUntilNext;
        }
        rewardRateByEpoch[ProtocolTimeLibrary.epochStart(timestamp)] = rewardRate;
        if (rewardRate == 0) revert ZeroRewardRate();

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        if (rewardRate > balance / timeUntilNext) revert RewardRateTooHigh();

        lastUpdateTime = timestamp;
        periodFinish = timestamp + timeUntilNext;
        emit NotifyReward(sender, _amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {GovernorSimple} from "./GovernorSimple.sol";

/**
 * @dev Modified lightly from OpenZeppelin's GovernorCountingSimple to support a simple three option majority.
 *
 */
abstract contract GovernorCountingMajority is GovernorSimple {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(uint256 => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, uint256 tokenId) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[tokenId];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(
        uint256 proposalId
    ) public view virtual returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev Select winner of majority vote.
     */
    function _selectWinner(uint256 proposalId) internal view override returns (ProposalState) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        uint256 againstVotes = proposalVote.againstVotes;
        uint256 forVotes = proposalVote.forVotes;
        uint256 abstainVotes = proposalVote.abstainVotes;
        if ((againstVotes > forVotes) && (againstVotes > abstainVotes)) {
            return ProposalState.Defeated;
        } else if ((forVotes > againstVotes) && (forVotes > abstainVotes)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Expired;
        }
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[tokenId], "GovernorVotingSimple: vote already cast");
        require(weight > 0, "GovernorVotingSimple: zero voting weight");
        proposalVote.hasVoted[tokenId] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Timers} from "@openzeppelin/contracts/utils/Timers.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IGovernor} from "./IGovernor.sol";
import {IMinter} from "../interfaces/IMinter.sol";
import {ProtocolTimeLibrary} from "../libraries/ProtocolTimeLibrary.sol";

/**
 * @dev Modified lightly from OpenZeppelin's Governor contract to support three option voting via callback.
 * A counting module is only required to implement _selectWinner and _countVote.
 * Adheres to IGovernor interface, with the following changes:
 * - hashProposal(...) generates a hash that allows for only one proposal per epoch
 * - state(...) returns a simple majority
 * - _selectWinner(...) returns simple majority winner from the three outcomes.
 * - execute(...) requires one of three states (Suceeded, Defeated, Expired) to execute.
 * - execute(...) sets the result based on the current epoch.
 * - cancel(...) does not exist by default (Modified from OZ's IGovernor).
 *
 * propose(...) creates a proposal for the following epoch. This proposal can only be executed during that epoch.
 */
abstract contract GovernorSimple is ERC2771Context, ERC165, EIP712, IGovernor, IERC721Receiver, IERC1155Receiver {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    using SafeCast for uint256;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    // solhint-disable var-name-mixedcase
    struct ProposalCore {
        // --- start retyped from Timers.BlockNumber at offset 0x00 ---
        uint64 voteStart;
        address proposer;
        bytes4 __gap_unused0;
        // --- start retyped from Timers.BlockNumber at offset 0x20 ---
        uint64 voteEnd;
        bytes24 __gap_unused1;
        // --- Remaining fields starting at offset 0x40 ---------------
        bool executed;
        bool canceled;
    }
    // solhint-enable var-name-mixedcase

    string private _name;
    address public minter;

    mapping(uint256 => ProposalCore) private _proposals;

    /// @dev Stores most recent voting result. Will be either Defeated, Succeeded or Expired.
    ///      Any contracts that wish to use this governor must read from this to determine results.
    ProposalState public result;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueue.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "GovernorSimple: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}, and sets up meta-tx
     */
    constructor(
        address forwarder_,
        string memory name_,
        address minter_
    ) ERC2771Context(forwarder_) EIP712(name_, version()) {
        _name = name_;
        minter = minter_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IGovernor).interfaceId ^
                type(IERC6372).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            // Previous interface for backwards compatibility
            interfaceId == (type(IGovernor).interfaceId ^ type(IERC6372).interfaceId) ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     *
     * The proposal id ignores description hash and uses the epoch start time for the following week. This ensures that only
     * one proposal can be created per week.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 epochStart
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, epochStart)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("GovernorSimple: unknown proposal id");
        }

        uint256 currentTimepoint = clock();

        if (snapshot >= currentTimepoint) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= currentTimepoint) {
            return ProposalState.Active;
        }

        return _selectWinner(proposalId);
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Select winner of majority vote.
     */
    function _selectWinner(uint256 proposalId) internal view virtual returns (ProposalState);

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart;
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd;
    }

    /**
     * @dev Address of the proposer
     */
    function _proposalProposer(uint256 proposalId) internal view virtual returns (address) {
        return _proposals[proposalId].proposer;
    }

    /**
     * @dev Get the voting weight of `tokenId`, owned by `account` at a specific `timepoint`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote for `proposalId` by `tokenId` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     * description is ignored. The proposalId is created using the following epoch's start date.
     */
    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory /* description */
    ) public virtual override returns (uint256) {
        address proposer = _msgSender();
        uint256 currentTimepoint = clock();

        require(
            getVotes(proposer, tokenId, currentTimepoint - 1) >= proposalThreshold(),
            "GovernorSimple: proposer votes below proposal threshold"
        );
        require(targets.length == 1, "GovernorSimple: only one target allowed");
        require(address(targets[0]) == minter, "GovernorSimple: only minter allowed");
        require(calldatas.length == 1, "GovernorSimple: only one calldata allowed");
        require(bytes4(calldatas[0]) == IMinter.nudge.selector, "GovernorSimple: only nudge allowed");

        bytes32 epochStart = bytes32(ProtocolTimeLibrary.epochStart(block.timestamp) + (1 weeks));
        uint256 proposalId = hashProposal(targets, values, calldatas, epochStart);

        require(targets.length > 0, "GovernorSimple: empty proposal");
        require(_proposals[proposalId].proposer == address(0), "GovernorSimple: proposal already exists");

        uint256 snapshot = currentTimepoint + votingDelay();
        uint256 deadline = snapshot + votingPeriod();

        _proposals[proposalId] = ProposalCore({
            voteStart: snapshot.toUint64(),
            proposer: proposer,
            __gap_unused0: 0,
            voteEnd: deadline.toUint64(),
            __gap_unused1: 0,
            executed: false,
            canceled: false
        });

        emit ProposalCreated(
            proposalId,
            proposer,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            Strings.toString(uint256(epochStart))
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     * Executes a proposal with a start time at the beginning of this epoch.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        bytes32 epochStart = bytes32(ProtocolTimeLibrary.epochStart(block.timestamp));
        uint256 proposalId = hashProposal(targets, values, calldatas, epochStart);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Defeated || status == ProposalState.Expired,
            "GovernorSimple: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        result = status;

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256 /* proposalId */,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        uint256 _length = targets.length;
        for (uint256 i = 0; i < _length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256 /* proposalId */,
        address[] memory targets,
        uint256[] memory /* values */,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            uint256 _length = targets.length;
            for (uint256 i = 0; i < _length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256 /* proposalId */,
        address[] memory /* targets */,
        uint256[] memory /* values */,
        bytes[] memory /* calldatas */,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint
    ) public view virtual override returns (uint256) {
        return _getVotes(account, tokenId, timepoint, _defaultParams());
    }

    /**
     * @dev See {IGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, tokenId, timepoint, params);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint256 tokenId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, reason, params);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, tokenId, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, tokenId, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint256 tokenId,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, tokenId, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint256 tokenId,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "GovernorSimple: vote not currently active");

        uint256 weight = _getVotes(account, tokenId, proposal.voteStart, params);
        _countVote(proposalId, tokenId, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, tokenId, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, tokenId, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev Dummy quorum function to comply with IGovernor as quorum is not used.
     */
    function quorum(uint256 /* blockNumber */) public pure override returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import {IVotes} from "./IVotes.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {GovernorSimple} from "./GovernorSimple.sol";

/**
 * @dev Modified lightly from OpenZeppelin's GovernorVotes
 */
abstract contract GovernorSimpleVotes is GovernorSimple {
    IVotes public immutable token;

    constructor(IVotes tokenAddress) {
        token = IVotes(address(tokenAddress));
    }

    /**
     * @dev Clock (as specified in EIP-6372) is set to match the token's clock. Fallback to block numbers if the token
     * does not implement EIP-6372.
     */
    function clock() public view virtual override returns (uint48) {
        try IERC6372(address(token)).clock() returns (uint48 timepoint) {
            return timepoint;
        } catch {
            return SafeCast.toUint48(block.number);
        }
    }

    /**
     * @dev Machine-readable description of the clock as specified in EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory) {
        try IERC6372(address(token)).CLOCK_MODE() returns (string memory clockmode) {
            return clockmode;
        } catch {
            return "mode=blocknumber&from=default";
        }
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, tokenId, timepoint);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";

/**
 * @dev Taken from OpenZeppelin's IGovernor. Excludes `cancel`.
 */
abstract contract IGovernor is IERC165, IERC6372 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason
    );

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their interpepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev See {IERC6372}
     */
    function clock() public view virtual override returns (uint48);

    /**
     * @notice module:core
     * @dev See EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Timepoint used to retrieve user's votes and quorum. If using block number (as per Compound's Comp), the
     * snapshot is performed at the end of this block. Hence, voting for this proposal starts at the beginning of the
     * following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Timepoint at which votes close. If using block number, votes close at the end of this block, so it is
     * possible to cast a vote during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, between the proposal is created and the vote starts. The unit this duration is expressed in depends
     * on the clock (see EIP-6372) this contract uses.
     *
     * This can be increased to leave time for users to buy voting power, or delegate it, before the voting of a
     * proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, between the vote start and vote ends. The unit this duration is expressed in depends on the clock
     * (see EIP-6372) this contract uses.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * NOTE: The `timepoint` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this timepoint (see {ERC20Votes}).
     */
    function quorum(uint256 timepoint) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `tokenId` at a specific `timepoint`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 tokenId, uint256 timepoint) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `tokenId` at a specific `timepoint` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns whether `tokenId` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, uint256 tokenId) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start after a delay specified by {IGovernor-votingDelay} and lasts for a
     * duration specified by {IGovernor-votingPeriod}.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint256 tokenId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";

/**
 * @dev Taken from OpenZeppelin's IGovernor.
 *      Includes support for veto-ing as mitigation against a 51% attack.
 */
abstract contract IVetoGovernor is IERC165, IERC6372 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed,
        Vetoed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 voteStart,
        uint256 voteEnd,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is vetoed.
     */
    event ProposalVetoed(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason
    );

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their interpepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 indexed tokenId,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev See {IERC6372}
     */
    function clock() public view virtual override returns (uint48);

    /**
     * @notice module:core
     * @dev See EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Timepoint used to retrieve user's votes and quorum. If using block number (as per Compound's Comp), the
     * snapshot is performed at the end of this block. Hence, voting for this proposal starts at the beginning of the
     * following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Timepoint at which votes close. If using block number, votes close at the end of this block, so it is
     * possible to cast a vote during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, between the proposal is created and the vote starts. The unit this duration is expressed in depends
     * on the clock (see EIP-6372) this contract uses.
     *
     * This can be increased to leave time for users to buy voting power, or delegate it, before the voting of a
     * proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, between the vote start and vote ends. The unit this duration is expressed in depends on the clock
     * (see EIP-6372) this contract uses.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * NOTE: The `timepoint` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this timepoint (see {ERC20Votes}).
     */
    function quorum(uint256 timepoint) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `tokenId` at a specific `timepoint`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 tokenId, uint256 timepoint) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `tokenId` at a specific `timepoint` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns whether `tokenId` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, uint256 tokenId) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start after a delay specified by {IGovernor-votingDelay} and lasts for a
     * duration specified by {IGovernor-votingPeriod}.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cancel a proposal. A proposal is cancellable by the proposer, but only while it is Pending state, i.e.
     * before the vote starts.
     *
     * Emits a {ProposalCanceled} event.
     */
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint256 tokenId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// Modified IVotes interface for tokenId based voting
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the amount of votes that `tokenId` had at a specific moment in the past.
     *      If the account passed in is not the owner, returns 0.
     */
    function getPastVotes(address account, uint256 tokenId, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `tokenId` has chosen. Can never be equal to the delegator's `tokenId`.
     *      Returns 0 if not delegated.
     */
    function delegates(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(uint256 delegator, uint256 delegatee) external;

    /**
     * @dev Delegates votes from `delegator` to `delegatee`. Signer must own `delegator`.
     */
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (governance/Governor.sol)

pragma solidity ^0.8.0;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ERC165, IERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "./IVetoGovernor.sol";

/**
 * @dev Modified lightly from OpenZeppelin's Governor contract to support vetoing.
 */
abstract contract VetoGovernor is Context, ERC165, EIP712, IVetoGovernor, IERC721Receiver, IERC1155Receiver {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    using SafeCast for uint256;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    // solhint-disable var-name-mixedcase
    struct ProposalCore {
        // --- start retyped from Timers.BlockNumber at offset 0x00 ---
        uint64 voteStart;
        address proposer;
        bytes4 __gap_unused0;
        // --- start retyped from Timers.BlockNumber at offset 0x20 ---
        uint64 voteEnd;
        bytes24 __gap_unused1;
        // --- Remaining fields starting at offset 0x40 ---------------
        bool executed;
        bool canceled;
        bool vetoed;
    }
    // solhint-enable var-name-mixedcase

    string private _name;

    /// @custom:oz-retyped-from mapping(uint256 => Governor.ProposalCore)
    mapping(uint256 => ProposalCore) private _proposals;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueue.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IVetoGovernor).interfaceId ^
                type(IERC6372).interfaceId ^
                this.cancel.selector ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            // Previous interface for backwards compatibility
            interfaceId == (type(IVetoGovernor).interfaceId ^ type(IERC6372).interfaceId ^ this.cancel.selector) ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IVetoGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IVetoGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IVetoGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array,
     * the descriptionHash (bytes32 which itself is the keccak256 hash of the description string) and the `proposer` address.
     * This proposal id can be produced from the proposal data which is part of the {ProposalCreated} event. It can even
     * be computed in advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash, proposer)));
    }

    /**
     * @dev See {IVetoGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.vetoed) {
            return ProposalState.Vetoed;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        uint256 currentTimepoint = clock();

        if (snapshot >= currentTimepoint) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= currentTimepoint) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev See {IVetoGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart;
    }

    /**
     * @dev See {IVetoGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd;
    }

    /**
     * @dev Address of the proposer
     */
    function _proposalProposer(uint256 proposalId) internal view virtual returns (address) {
        return _proposals[proposalId].proposer;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Get the voting weight of `tokenId`, owned by `account` at a specific `timepoint`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote for `proposalId` by `tokenId` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IVetoGovernor-propose}.
     */
    function propose(
        uint256 tokenId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        address proposer = _msgSender();
        uint256 currentTimepoint = clock();

        require(
            getVotes(proposer, tokenId, currentTimepoint - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)), proposer);

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");
        require(_proposals[proposalId].proposer == address(0), "Governor: proposal already exists");

        uint256 snapshot = currentTimepoint + votingDelay();
        uint256 deadline = snapshot + votingPeriod();

        _proposals[proposalId] = ProposalCore({
            voteStart: snapshot.toUint64(),
            proposer: proposer,
            __gap_unused0: 0,
            voteEnd: deadline.toUint64(),
            __gap_unused1: 0,
            executed: false,
            canceled: false,
            vetoed: false
        });

        emit ProposalCreated(
            proposalId,
            proposer,
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IVetoGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash, proposer);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev See {IVetoGovernor-cancel}.
     */
    function cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public virtual override returns (uint256) {
        address proposer = _msgSender();
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash, proposer);
        require(state(proposalId) == ProposalState.Pending, "Governor: too late to cancel");
        require(proposer == _proposals[proposalId].proposer, "Governor: only proposer can cancel");
        return _cancel(targets, values, calldatas, descriptionHash, proposer);
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256 /* proposalId */,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        uint256 _length = targets.length;
        for (uint256 i = 0; i < _length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256 /* proposalId */,
        address[] memory targets,
        uint256[] memory /* values */,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            uint256 _length = targets.length;
            for (uint256 i = 0; i < _length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256 /* proposalId */,
        address[] memory /* targets */,
        uint256[] memory /* values */,
        bytes[] memory /* calldatas */,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev Internal veto mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * veto to allow distinguishing it from executed and canceled proposals.
     *
     * Emits a {IVetoGovernor-ProposalVetoed} event.
     */
    function _veto(uint256 proposalId) internal returns (uint256) {
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Vetoed &&
                status != ProposalState.Canceled &&
                status != ProposalState.Expired &&
                status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].vetoed = true;

        emit ProposalVetoed(proposalId);

        return proposalId;
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed and canceled proposals.
     *
     * Emits a {IVetoGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash,
        address proposer
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash, proposer);

        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Vetoed &&
                status != ProposalState.Canceled &&
                status != ProposalState.Expired &&
                status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IVetoGovernor-getVotes}.
     */
    function getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint
    ) public view virtual override returns (uint256) {
        return _getVotes(account, tokenId, timepoint, _defaultParams());
    }

    /**
     * @dev See {IVetoGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, tokenId, timepoint, params);
    }

    /**
     * @dev See {IVetoGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint256 tokenId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, "");
    }

    /**
     * @dev See {IVetoGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, reason);
    }

    /**
     * @dev See {IVetoGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, tokenId, support, reason, params);
    }

    /**
     * @dev See {IVetoGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, tokenId, support, "");
    }

    /**
     * @dev See {IVetoGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, tokenId, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IVetoGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IVetoGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint256 tokenId,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, tokenId, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IVetoGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IVetoGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint256 tokenId,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = _getVotes(account, tokenId, proposal.voteStart, params);
        _countVote(proposalId, tokenId, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, tokenId, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, tokenId, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(address target, uint256 value, bytes calldata data) external payable virtual onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import {VetoGovernor} from "./VetoGovernor.sol";

/**
 * @dev OpenZeppelin's GovernorCountingSimple using VetoGovernor
 */
abstract contract VetoGovernorCountingSimple is VetoGovernor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(uint256 => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, uint256 tokenId) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[tokenId];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(
        uint256 proposalId
    ) public view virtual returns (uint256 againstVotes, uint256 forVotes, uint256 abstainVotes) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        uint256 tokenId,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[tokenId], "GovernorVotingSimple: vote already cast");
        require(weight > 0, "GovernorVotingSimple: zero voting weight");
        proposalVote.hasVoted[tokenId] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import {VetoGovernor} from "./VetoGovernor.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import {IVotes} from "./IVotes.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev OpenZeppelin's GovernorVotes using VetoGovernor
 */
abstract contract VetoGovernorVotes is VetoGovernor {
    IVotes public immutable token;

    constructor(IVotes tokenAddress) {
        token = IVotes(address(tokenAddress));
    }

    /**
     * @dev Clock (as specified in EIP-6372) is set to match the token's clock. Fallback to block numbers if the token
     * does not implement EIP-6372.
     */
    function clock() public view virtual override returns (uint48) {
        try IERC6372(address(token)).clock() returns (uint48 timepoint) {
            return timepoint;
        } catch {
            return SafeCast.toUint48(block.number);
        }
    }

    /**
     * @dev Machine-readable description of the clock as specified in EIP-6372.
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() public view virtual override returns (string memory) {
        try IERC6372(address(token)).CLOCK_MODE() returns (string memory clockmode) {
            return clockmode;
        } catch {
            return "mode=blocknumber&from=default";
        }
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 tokenId,
        uint256 timepoint,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, tokenId, timepoint);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorVotesQuorumFraction.sol)

pragma solidity ^0.8.0;

import {VetoGovernorVotes} from "./VetoGovernorVotes.sol";
import {Checkpoints} from "@openzeppelin/contracts/utils/Checkpoints.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

/**
 * @dev OpenZeppelin's GovernorVotesQuorumFraction using VetoGovernor
 */
abstract contract VetoGovernorVotesQuorumFraction is VetoGovernorVotes {
    using SafeCast for *;
    using Checkpoints for Checkpoints.Trace224;

    uint256 private _quorumNumerator; // DEPRECATED in favor of _quorumNumeratorHistory

    /// @custom:oz-retyped-from Checkpoints.History
    Checkpoints.Trace224 private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     */
    constructor(uint256 quorumNumeratorValue) {
        _updateQuorumNumerator(quorumNumeratorValue);
    }

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory._checkpoints.length == 0 ? _quorumNumerator : _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific timepoint. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 timepoint) public view virtual returns (uint256) {
        // If history is empty, fallback to old storage
        uint256 length = _quorumNumeratorHistory._checkpoints.length;
        if (length == 0) {
            return _quorumNumerator;
        }

        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint224 memory latest = _quorumNumeratorHistory._checkpoints[length - 1];
        if (latest._key <= timepoint) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.upperLookupRecent(timepoint.toUint32());
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a timepoint, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 timepoint) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(timepoint) * quorumNumerator(timepoint)) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Make sure we keep track of the original numerator in contracts upgraded from a version without checkpoints.
        if (oldQuorumNumerator != 0 && _quorumNumeratorHistory._checkpoints.length == 0) {
            _quorumNumeratorHistory._checkpoints.push(
                Checkpoints.Checkpoint224({_key: 0, _value: oldQuorumNumerator.toUint224()})
            );
        }

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(clock().toUint32(), newQuorumNumerator.toUint224());

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFactoryRegistry {
    error FallbackFactory();
    error InvalidFactoriesToPoolFactory();
    error PathAlreadyApproved();
    error PathNotApproved();
    error SameAddress();
    error ZeroAddress();

    event Approve(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event Unapprove(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event SetManagedRewardsFactory(address indexed _newRewardsFactory);

    /// @notice Approve a set of factories used in the Protocol.
    ///         Router.sol is able to swap any poolFactories currently approved.
    ///         Cannot approve address(0) factories.
    ///         Cannot aprove path that is already approved.
    ///         Each poolFactory has one unique set and maintains state.  In the case a poolFactory is unapproved
    ///             and then re-approved, the same set of factories must be used.  In other words, you cannot overwrite
    ///             the factories tied to a poolFactory address.
    ///         VotingRewardsFactories and GaugeFactories may use the same address across multiple poolFactories.
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    /// @param votingRewardsFactory .
    /// @param gaugeFactory .
    function approve(address poolFactory, address votingRewardsFactory, address gaugeFactory) external;

    /// @notice Unapprove a set of factories used in the Protocol.
    ///         While a poolFactory is unapproved, Router.sol cannot swap with pools made from the corresponding factory
    ///         Can only unapprove an approved path.
    ///         Cannot unapprove the fallback path (core v2 factories).
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    function unapprove(address poolFactory) external;

    /// @notice Factory to create free and locked rewards for a managed veNFT
    function managedRewardsFactory() external view returns (address);

    /// @notice Set the rewards factory address
    /// @dev Callable by onlyOwner
    /// @param _newManagedRewardsFactory address of new managedRewardsFactory
    function setManagedRewardsFactory(address _newManagedRewardsFactory) external;

    /// @notice Get the factories correlated to a poolFactory.
    ///         Once set, this can never be modified.
    ///         Returns the correlated factories even after an approved poolFactory is unapproved.
    function factoriesToPoolFactory(
        address poolFactory
    ) external view returns (address votingRewardsFactory, address gaugeFactory);

    /// @notice Get all PoolFactories approved by the registry
    /// @dev The same PoolFactory address cannot be used twice
    /// @return Array of PoolFactory addresses
    function poolFactories() external view returns (address[] memory);

    /// @notice Check if a PoolFactory is approved within the factory registry.  Router uses this method to
    ///         ensure a pool swapped from is approved.
    /// @param poolFactory .
    /// @return True if PoolFactory is approved, else false
    function isPoolFactoryApproved(address poolFactory) external view returns (bool);

    /// @notice Get the length of the poolFactories array
    function poolFactoriesLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGaugeFactory {
    function createGauge(
        address _forwarder,
        address _pool,
        address _feesVotingReward,
        address _ve,
        bool isPool
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IManagedRewardsFactory {
    event ManagedRewardCreated(
        address indexed voter,
        address indexed lockedManagedReward,
        address indexed freeManagedReward
    );

    /// @notice creates a LockedManagedReward and a FreeManagedReward contract for a managed veNFT
    /// @param _forwarder Address of trusted forwarder
    /// @param _voter Address of Voter.sol
    /// @return lockedManagedReward Address of LockedManagedReward contract created
    /// @return freeManagedReward   Address of FreeManagedReward contract created
    function createRewards(
        address _forwarder,
        address _voter
    ) external returns (address lockedManagedReward, address freeManagedReward);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    /// @dev Only called once to set to Voter.sol - Voter does not have a function
    ///      to call this contract method, so once set it's immutable.
    ///      This also follows convention of setVoterAndDistributor() in VotingEscrow.sol
    /// @param _voter .
    function setVoter(address _voter) external;

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

    function isPaused() external view returns (bool);

    function voter() external view returns (address);

    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingRewardsFactory {
    /// @notice creates a BribeVotingReward and a FeesVotingReward contract for a gauge
    /// @param _forwarder            Address of trusted forwarder
    /// @param _rewards             Addresses of pool tokens to be used as valid rewards tokens
    /// @return feesVotingReward    Address of FeesVotingReward contract created
    /// @return bribeVotingReward   Address of BribeVotingReward contract created
    function createRewards(
        address _forwarder,
        address[] memory _rewards
    ) external returns (address feesVotingReward, address bribeVotingReward);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IPrfct} from "./IPrfct.sol";
import {IVotingEscrow} from "./IVotingEscrow.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

interface IAirdropDistributor {
    error InvalidParams();
    error InsufficientBalance();

    event Airdrop(address indexed _wallet, uint256 _amount, uint256 _tokenId);

    /// @notice Interface of Prfct.sol
    function prfct() external view returns (IPrfct);

    /// @notice Interface of IVotingEscrow.sol
    function ve() external view returns (IVotingEscrow);

    /// @notice Distributes permanently locked NFTs to the desired addresses
    /// @param _wallets Addresses of wallets to receive the Airdrop
    /// @param _amounts Amounts to be Airdropped
    function distributeTokens(address[] memory _wallets, uint256[] memory _amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEpochGovernor {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /// @dev Stores most recent voting result. Will be either Defeated, Succeeded or Expired.
    ///      Any contracts that wish to use this governor must read from this to determine results.
    function result() external returns (ProposalState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGauge {
    error NotAlive();
    error NotAuthorized();
    error NotVoter();
    error NotTeam();
    error LockRateTooHigh();
    error RewardRateTooHigh();
    error ZeroAmount();
    error ZeroRewardRate();

    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, uint256 amount);
    event NotifyReward(address indexed from, uint256 amount);
    event ClaimFees(address indexed from, uint256 claimed0, uint256 claimed1);
    event ClaimRewards(address indexed from, uint256 amount);

    /// @notice Address of the pool LP token which is deposited (staked) for rewards
    function stakingToken() external view returns (address);

    /// @notice Address of the token (PRFCT) rewarded to stakers
    function rewardToken() external view returns (address);

    /// @notice Address of the FeesVotingReward contract linked to the gauge
    function feesVotingReward() external view returns (address);

    /// @notice Address of Protocol Voter
    function voter() external view returns (address);

    /// @notice Address of Protocol Voting Escrow
    function ve() external view returns (address);

    /// @notice Returns if gauge is linked to a legitimate Protocol pool
    function isPool() external view returns (bool);

    /// @notice Timestamp end of current rewards period
    function periodFinish() external view returns (uint256);

    /// @notice Current reward rate of rewardToken to distribute per second
    function rewardRate() external view returns (uint256);

    /// @notice Most recent timestamp contract has updated state
    function lastUpdateTime() external view returns (uint256);

    /// @notice Most recent stored value of rewardPerToken
    function rewardPerTokenStored() external view returns (uint256);

    /// @notice Amount of stakingToken deposited for rewards
    function totalSupply() external view returns (uint256);

    /// @notice Get the amount of stakingToken deposited by an account
    function balanceOf(address) external view returns (uint256);

    /// @notice Cached rewardPerTokenStored for an account based on their most recent action
    function userRewardPerTokenPaid(address) external view returns (uint256);

    /// @notice Cached amount of rewardToken earned for an account
    function rewards(address) external view returns (uint256);

    /// @notice View to see the rewardRate given the timestamp of the start of the epoch
    function rewardRateByEpoch(uint256) external view returns (uint256);

    /// @notice Cached amount of fees generated from the Pool linked to the Gauge of token0
    function fees0() external view returns (uint256);

    /// @notice Cached amount of fees generated from the Pool linked to the Gauge of token1
    function fees1() external view returns (uint256);

    /// @notice Get the current reward rate per unit of stakingToken deposited
    function rewardPerToken() external view returns (uint256 _rewardPerToken);

    /// @notice Returns the last time the reward was modified or periodFinish if the reward has ended
    function lastTimeRewardApplicable() external view returns (uint256 _time);

    /// @notice Returns accrued balance to date from last claim / first deposit.
    function earned(address _account) external view returns (uint256 _earned);

    /// @notice Total amount of rewardToken to distribute for the current rewards period
    function left() external view returns (uint256 _left);

    /// @notice Retrieve rewards for an address.
    /// @dev Throws if not called by same address or voter.
    /// @param _account .
    function getReward(address _account) external;

    /// @notice Deposit LP tokens into gauge for msg.sender
    /// @param _amount .
    function deposit(uint256 _amount) external;

    /// @notice Deposit LP tokens into gauge for any user
    /// @param _amount .
    /// @param _recipient Recipient to give balance to
    function deposit(uint256 _amount, address _recipient) external;

    /// @notice Withdraw LP tokens for user
    /// @param _amount .
    function withdraw(uint256 _amount) external;

    /// @dev Notifies gauge of gauge rewards. Assumes gauge reward tokens is 18 decimals.
    ///      If not 18 decimals, rewardRate may have rounding issues.
    function notifyRewardAmount(uint256 amount) external;

    /// @dev Notifies gauge of gauge rewards without distributing its fees.
    ///      Assumes gauge reward tokens is 18 decimals.
    ///      If not 18 decimals, rewardRate may have rounding issues.
    function notifyRewardWithoutClaim(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPrfct} from "./IPrfct.sol";
import {IVoter} from "./IVoter.sol";
import {IVotingEscrow} from "./IVotingEscrow.sol";
import {IRewardsDistributor} from "./IRewardsDistributor.sol";

interface IMinter {
    struct AirdropParams {
        // List of addresses to receive Liquid Tokens from the airdrop
        address[] liquidWallets;
        // List of amounts of Liquid Tokens to be issued
        uint256[] liquidAmounts;
        // List of addresses to receive Locked NFTs from the airdrop
        address[] lockedWallets;
        // List of amounts of Locked NFTs to be issued
        uint256[] lockedAmounts;
    }

    error NotTeam();
    error RateTooHigh();
    error ZeroAddress();
    error InvalidParams();
    error AlreadyNudged();
    error NotPendingTeam();
    error NotEpochGovernor();
    error AlreadyInitialized();
    error AlreadyStartedReward();
    error NotStartedReward();
    error TailEmissionsInactive();

    event Mint(address indexed _sender, uint256 _weekly, uint256 _circulating_supply, bool indexed _tail);
    event DistributeLocked(address indexed _destination, uint256 _amount, uint256 _tokenId);
    event Nudge(uint256 indexed _period, uint256 _oldRate, uint256 _newRate);
    event DistributeLiquid(address indexed _destination, uint256 _amount);
    event AcceptTeam(address indexed _newTeam);

    /// @notice Interface of Prfct.sol
    function prfct() external view returns (IPrfct);

    /// @notice Interface of Voter.sol
    function voter() external view returns (IVoter);

    /// @notice Interface of IVotingEscrow.sol
    function ve() external view returns (IVotingEscrow);

    /// @notice Interface of RewardsDistributor.sol
    function rewardsDistributor() external view returns (IRewardsDistributor);

    /// @notice Duration of epoch in seconds
    function WEEK() external view returns (uint256);

    /// @notice Decay rate of emissions as percentage of `MAX_BPS`
    function WEEKLY_DECAY() external view returns (uint256);

    /// @notice Growth rate of emissions as percentage of `MAX_BPS` in first 14 weeks
    function WEEKLY_GROWTH() external view returns (uint256);

    /// @notice Maximum tail emission rate in basis points.
    function MAXIMUM_TAIL_RATE() external view returns (uint256);

    /// @notice Minimum tail emission rate in basis points.
    function MINIMUM_TAIL_RATE() external view returns (uint256);

    /// @notice Denominator for emissions calculations (as basis points)
    function MAX_BPS() external view returns (uint256);

    /// @notice Rate change per proposal
    function NUDGE() external view returns (uint256);

    /// @notice When emissions fall below this amount, begin tail emissions
    function TAIL_START() external view returns (uint256);

    /// @notice Maximum team percentage in basis points
    function MAXIMUM_TEAM_RATE() external view returns (uint256);

    /// @notice Current team percentage in basis points
    function teamRate() external view returns (uint256);

    /// @notice Tail emissions rate in basis points
    function tailEmissionRate() external view returns (uint256);

    /// @notice Starting weekly emission of 10M PRFCT (PRFCT has 18 decimals)
    function weekly() external view returns (uint256);

    /// @notice Timestamp of start of epoch that updatePeriod was last called in
    function activePeriod() external view returns (uint256);

    /// @notice Number of epochs in which updatePeriod was called
    function epochCount() external view returns (uint256);

    /// @notice Boolean used to verify if contract has been initialized
    function initialized() external returns (bool);

    /// @dev activePeriod => proposal existing, used to enforce one proposal per epoch
    /// @param _activePeriod Timestamp of start of epoch
    /// @return True if proposal has been executed, else false
    function proposals(uint256 _activePeriod) external view returns (bool);

    /// @notice Current team address in charge of emissions
    function team() external view returns (address);

    /// @notice Possible team address pending approval of current team
    function pendingTeam() external view returns (address);

    /// @notice Mints liquid tokens and permanently locked NFTs to the provided accounts
    /// @param params Struct that stores the wallets and amounts for the Airdrops
    function initialize(AirdropParams memory params) external;

    /// @notice Creates a request to change the current team's address
    /// @param _team Address of the new team to be chosen
    function setTeam(address _team) external;

    /// @notice Accepts the request to replace the current team's address
    ///         with the requested one, present on variable pendingTeam
    function acceptTeam() external;

    /// @notice Creates a request to change the current team's percentage
    /// @param _rate New team rate to be set in basis points
    function setTeamRate(uint256 _rate) external;

    /// @notice Allows epoch governor to modify the tail emission rate by at most 1 basis point
    ///         per epoch to a maximum of 100 basis points or to a minimum of 1 basis point.
    ///         Note: the very first nudge proposal must take place the week prior
    ///         to the tail emission schedule starting.
    /// @dev Throws if not epoch governor.
    ///      Throws if not currently in tail emission schedule.
    ///      Throws if already nudged this epoch.
    ///      Throws if nudging above maximum rate.
    ///      Throws if nudging below minimum rate.
    ///      This contract is coupled to EpochGovernor as it requires three option simple majority voting.
    function nudge() external;

    /// @notice Calculates rebases according to the formula
    ///         weekly * ((prfct.totalsupply - ve.totalSupply) / prfct.totalsupply) ^ 2 / 2
    ///         Note that ve.totalSupply is the locked ve supply
    ///         prfct.totalSupply is the total ve supply minted
    /// @param _minted Amount of PRFCT minted this epoch
    /// @return _growth Rebases
    function calculateGrowth(uint256 _minted) external view returns (uint256 _growth);

    /// @notice Processes emissions and rebases. Callable once per epoch (1 week).
    /// @return _period Start of current epoch.
    function updatePeriod() external returns (uint256 _period);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool {
    error DepositsNotEqual();
    error BelowMinimumK();
    error FactoryAlreadySet();
    error InsufficientLiquidity();
    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error InsufficientOutputAmount();
    error InsufficientInputAmount();
    error IsPaused();
    error InvalidTo();
    error K();
    error NotEmergencyCouncil();

    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, address indexed to, uint256 amount0, uint256 amount1);
    event Swap(
        address indexed sender,
        address indexed to,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(address indexed sender, address indexed recipient, uint256 amount0, uint256 amount1);

    // Struct to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint256 timestamp;
        uint256 reserve0Cumulative;
        uint256 reserve1Cumulative;
    }

    /// @notice Returns the decimal (dec), reserves (r), stable (st), and tokens (t) of token0 and token1
    function metadata()
        external
        view
        returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1);

    /// @notice Claim accumulated but unclaimed fees (claimable0 and claimable1)
    function claimFees() external returns (uint256, uint256);

    /// @notice Returns [token0, token1]
    function tokens() external view returns (address, address);

    /// @notice Address of token in the pool with the lower address value
    function token0() external view returns (address);

    /// @notice Address of token in the poool with the higher address value
    function token1() external view returns (address);

    /// @notice Address of linked PoolFees.sol
    function poolFees() external view returns (address);

    /// @notice Address of PoolFactory that created this contract
    function factory() external view returns (address);

    /// @notice Capture oracle reading every 30 minutes (1800 seconds)
    function periodSize() external view returns (uint256);

    /// @notice Amount of token0 in pool
    function reserve0() external view returns (uint256);

    /// @notice Amount of token1 in pool
    function reserve1() external view returns (uint256);

    /// @notice Timestamp of last update to pool
    function blockTimestampLast() external view returns (uint256);

    /// @notice Cumulative of reserve0 factoring in time elapsed
    function reserve0CumulativeLast() external view returns (uint256);

    /// @notice Cumulative of reserve1 factoring in time elapsed
    function reserve1CumulativeLast() external view returns (uint256);

    /// @notice Accumulated fees of token0 (global)
    function index0() external view returns (uint256);

    /// @notice Accumulated fees of token1 (global)
    function index1() external view returns (uint256);

    /// @notice Get an LP's relative index0 to index0
    function supplyIndex0(address) external view returns (uint256);

    /// @notice Get an LP's relative index1 to index1
    function supplyIndex1(address) external view returns (uint256);

    /// @notice Amount of unclaimed, but claimable tokens from fees of token0 for an LP
    function claimable0(address) external view returns (uint256);

    /// @notice Amount of unclaimed, but claimable tokens from fees of token1 for an LP
    function claimable1(address) external view returns (uint256);

    /// @notice Returns the value of K in the Pool, based on its reserves.
    function getK() external returns (uint256);

    /// @notice Set pool name
    ///         Only callable by Voter.emergencyCouncil()
    /// @param __name String of new name
    function setName(string calldata __name) external;

    /// @notice Set pool symbol
    ///         Only callable by Voter.emergencyCouncil()
    /// @param __symbol String of new symbol
    function setSymbol(string calldata __symbol) external;

    /// @notice Get the number of observations recorded
    function observationLength() external view returns (uint256);

    /// @notice Get the value of the most recent observation
    function lastObservation() external view returns (Observation memory);

    /// @notice True if pool is stable, false if volatile
    function stable() external view returns (bool);

    /// @notice Produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        external
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp);

    /// @notice Provides twap price with user configured granularity, up to the full window size
    /// @param tokenIn .
    /// @param amountIn .
    /// @param granularity .
    /// @return amountOut .
    function quote(address tokenIn, uint256 amountIn, uint256 granularity) external view returns (uint256 amountOut);

    /// @notice Returns a memory set of TWAP prices
    ///         Same as calling sample(tokenIn, amountIn, points, 1)
    /// @param tokenIn .
    /// @param amountIn .
    /// @param points Number of points to return
    /// @return Array of TWAP prices
    function prices(address tokenIn, uint256 amountIn, uint256 points) external view returns (uint256[] memory);

    /// @notice Same as prices with with an additional window argument.
    ///         Window = 2 means 2 * 30min (or 1 hr) between observations
    /// @param tokenIn .
    /// @param amountIn .
    /// @param points .
    /// @param window .
    /// @return Array of TWAP prices
    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) external view returns (uint256[] memory);

    /// @notice This low-level function should be called from a contract which performs important safety checks
    /// @param amount0Out   Amount of token0 to send to `to`
    /// @param amount1Out   Amount of token1 to send to `to`
    /// @param to           Address to recieve the swapped output
    /// @param data         Additional calldata for flashloans
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    /// @notice This low-level function should be called from a contract which performs important safety checks
    ///         standard uniswap v2 implementation
    /// @param to Address to receive token0 and token1 from burning the pool token
    /// @return amount0 Amount of token0 returned
    /// @return amount1 Amount of token1 returned
    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    /// @notice This low-level function should be called by addLiquidity functions in Router.sol, which performs important safety checks
    ///         standard uniswap v2 implementation
    /// @param to           Address to receive the minted LP token
    /// @return liquidity   Amount of LP token minted
    function mint(address to) external returns (uint256 liquidity);

    /// @notice Update reserves and, on the first call per block, price accumulators
    /// @return _reserve0 .
    /// @return _reserve1 .
    /// @return _blockTimestampLast .
    function getReserves() external view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast);

    /// @notice Get the amount of tokenOut given the amount of tokenIn
    /// @param amountIn Amount of token in
    /// @param tokenIn  Address of token
    /// @return Amount out
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256);

    /// @notice Force balances to match reserves
    /// @param to Address to receive any skimmed rewards
    function skim(address to) external;

    /// @notice Force reserves to match balances
    function sync() external;

    /// @notice Called on pool creation by PoolFactory
    /// @param _token0 Address of token0
    /// @param _token1 Address of token1
    /// @param _stable True if stable, false if volatile
    function initialize(address _token0, address _token1, bool _stable) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPoolCallee {
    function hook(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPrfct is IERC20 {
    error NotMinter();
    error NotOwner();

    /// @notice Mint an amount of tokens to an account
    ///         Only callable by Minter.sol
    /// @return True if success
    function mint(address account, uint256 amount) external returns (bool);

    /// @notice Address of Minter.sol
    function minter() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReward {
    error InvalidReward();
    error NotAuthorized();
    error NotGauge();
    error NotEscrowToken();
    error NotSingleToken();
    error NotVotingEscrow();
    error NotWhitelisted();
    error ZeroAmount();

    event Deposit(address indexed from, uint256 indexed tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 indexed tokenId, uint256 amount);
    event NotifyReward(address indexed from, address indexed reward, uint256 indexed epoch, uint256 amount);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    /// @notice Epoch duration constant (7 days)
    function DURATION() external view returns (uint256);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of VotingEscrow.sol
    function ve() external view returns (address);

    /// @dev Address which has permission to externally call _deposit() & _withdraw()
    function authorized() external view returns (address);

    /// @notice Total amount currently deposited via _deposit()
    function totalSupply() external view returns (uint256);

    /// @notice Current amount deposited by tokenId
    function balanceOf(uint256 tokenId) external view returns (uint256);

    /// @notice Amount of tokens to reward depositors for a given epoch
    /// @param token Address of token to reward
    /// @param epochStart Startime of rewards epoch
    /// @return Amount of token
    function tokenRewardsPerEpoch(address token, uint256 epochStart) external view returns (uint256);

    /// @notice Most recent timestamp a veNFT has claimed their rewards
    /// @param  token Address of token rewarded
    /// @param tokenId veNFT unique identifier
    /// @return Timestamp
    function lastEarn(address token, uint256 tokenId) external view returns (uint256);

    /// @notice True if a token is or has been an active reward token, else false
    function isReward(address token) external view returns (bool);

    /// @notice The number of checkpoints for each tokenId deposited
    function numCheckpoints(uint256 tokenId) external view returns (uint256);

    /// @notice The total number of checkpoints
    function supplyNumCheckpoints() external view returns (uint256);

    /// @notice Deposit an amount into the rewards contract to earn future rewards associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _deposit(uint256 amount, uint256 tokenId) external;

    /// @notice Withdraw an amount from the rewards contract associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _withdraw(uint256 amount, uint256 tokenId) external;

    /// @notice Claim the rewards earned by a veNFT staker
    /// @param tokenId  Unique identifier of the veNFT
    /// @param tokens   Array of tokens to claim rewards of
    function getReward(uint256 tokenId, address[] memory tokens) external;

    /// @notice Add rewards for stakers to earn
    /// @param token    Address of token to reward
    /// @param amount   Amount of token to transfer to rewards
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Determine the prior balance for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param tokenId      The token of the NFT to check
    /// @param timestamp    The timestamp to get the balance at
    /// @return The balance the account had as of the given block
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @notice Determine the prior index of supply staked by of a timestamp
    /// @dev Timestamp must be <= current timestamp
    /// @param timestamp The timestamp to get the index at
    /// @return Index of supply checkpoint
    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);

    /// @notice Get number of rewards tokens
    function rewardsListLength() external view returns (uint256);

    /// @notice Calculate how much in rewards are earned for a specific token and veNFT
    /// @param token Address of token to fetch rewards of
    /// @param tokenId Unique identifier of the veNFT
    /// @return Amount of token earned in rewards
    function earned(address token, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IVotingEscrow} from "./IVotingEscrow.sol";

interface IRewardsDistributor {
    event CheckpointToken(uint256 time, uint256 tokens);
    event Claimed(uint256 indexed tokenId, uint256 indexed epochStart, uint256 indexed epochEnd, uint256 amount);

    error NotMinter();
    error NotManagedOrNormalNFT();
    error UpdatePeriod();

    /// @notice 7 days in seconds
    function WEEK() external view returns (uint256);

    /// @notice Timestamp of contract creation
    function startTime() external view returns (uint256);

    /// @notice Timestamp of most recent claim of tokenId
    function timeCursorOf(uint256 tokenId) external view returns (uint256);

    /// @notice The last timestamp Minter has called checkpointToken()
    function lastTokenTime() external view returns (uint256);

    /// @notice Interface of VotingEscrow.sol
    function ve() external view returns (IVotingEscrow);

    /// @notice Address of token used for distributions (PRFCT)
    function token() external view returns (address);

    /// @notice Address of Minter.sol
    ///         Authorized caller of checkpointToken()
    function minter() external view returns (address);

    /// @notice Amount of token in contract when checkpointToken() was last called
    function tokenLastBalance() external view returns (uint256);

    /// @notice Called by Minter to notify Distributor of rebases
    function checkpointToken() external;

    /// @notice Returns the amount of rebases claimable for a given token ID
    /// @dev Allows claiming of rebases up to 50 epochs old
    /// @param tokenId The token ID to check
    /// @return The amount of rebases claimable for the given token ID
    function claimable(uint256 tokenId) external view returns (uint256);

    /// @notice Claims rebases for a given token ID
    /// @dev Allows claiming of rebases up to 50 epochs old
    ///      `Minter.updatePeriod()` must be called before claiming
    /// @param tokenId The token ID to claim for
    /// @return The amount of rebases claimed
    function claim(uint256 tokenId) external returns (uint256);

    /// @notice Claims rebases for a list of token IDs
    /// @dev    `Minter.updatePeriod()` must be called before claiming
    /// @param tokenIds The token IDs to claim for
    /// @return Whether or not the claim succeeded
    function claimMany(uint256[] calldata tokenIds) external returns (bool);

    /// @notice Used to set minter once on initialization
    /// @dev Callable once by Minter only, Minter is immutable
    function setMinter(address _minter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IWETH} from "./IWETH.sol";

interface IRouter {
    struct Route {
        address from;
        address to;
        bool stable;
        address factory;
    }

    error ETHTransferFailed();
    error Expired();
    error InsufficientAmount();
    error InsufficientAmountA();
    error InsufficientAmountB();
    error InsufficientAmountADesired();
    error InsufficientAmountBDesired();
    error InsufficientAmountAOptimal();
    error InsufficientLiquidity();
    error InsufficientOutputAmount();
    error InvalidAmountInForETHDeposit();
    error InvalidTokenInForETHDeposit();
    error InvalidPath();
    error InvalidRouteA();
    error InvalidRouteB();
    error OnlyWETH();
    error PoolDoesNotExist();
    error PoolFactoryDoesNotExist();
    error SameAddresses();
    error ZeroAddress();

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of Protocol PoolFactory.sol
    function defaultFactory() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Interface of WETH contract used for WETH => ETH wrapping/unwrapping
    function weth() external view returns (IWETH);

    /// @dev Represents Ether. Used by zapper to determine whether to return assets as ETH/WETH.
    function ETHER() external view returns (address);

    /// @dev Struct containing information necessary to zap in and out of pools
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           Stable or volatile pool
    /// @param factory          factory of pool
    /// @param amountOutMinA    Minimum amount expected from swap leg of zap via routesA
    /// @param amountOutMinB    Minimum amount expected from swap leg of zap via routesB
    /// @param amountAMin       Minimum amount of tokenA expected from liquidity leg of zap
    /// @param amountBMin       Minimum amount of tokenB expected from liquidity leg of zap
    struct Zap {
        address tokenA;
        address tokenB;
        bool stable;
        address factory;
        uint256 amountOutMinA;
        uint256 amountOutMinB;
        uint256 amountAMin;
        uint256 amountBMin;
    }

    /// @notice Sort two tokens by which address value is less than the other
    /// @param tokenA   Address of token to sort
    /// @param tokenB   Address of token to sort
    /// @return token0  Lower address value between tokenA and tokenB
    /// @return token1  Higher address value between tokenA and tokenB
    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    /// @notice Calculate the address of a pool by its' factory.
    ///         Used by all Router functions containing a `Route[]` or `_factory` argument.
    ///         Reverts if _factory is not approved by the FactoryRegistry
    /// @dev Returns a randomly generated address for a nonexistent pool
    /// @param tokenA   Address of token to query
    /// @param tokenB   Address of token to query
    /// @param stable   True if pool is stable, false if volatile
    /// @param _factory Address of factory which created the pool
    function poolFor(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) external view returns (address pool);

    /// @notice Fetch and sort the reserves for a pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param _factory     Address of PoolFactory for tokenA and tokenB
    /// @return reserveA    Amount of reserves of the sorted token A
    /// @return reserveB    Amount of reserves of the sorted token B
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) external view returns (uint256 reserveA, uint256 reserveB);

    /// @notice Perform chained getAmountOut calculations on any number of pools
    function getAmountsOut(uint256 amountIn, Route[] memory routes) external view returns (uint256[] memory amounts);

    // **** ADD LIQUIDITY ****

    /// @notice Quote the amount deposited into a Pool
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           True if pool is stable, false if volatile
    /// @param _factory         Address of PoolFactory for tokenA and tokenB
    /// @param amountADesired   Amount of tokenA desired to deposit
    /// @param amountBDesired   Amount of tokenB desired to deposit
    /// @return amountA         Amount of tokenA to actually deposit
    /// @return amountB         Amount of tokenB to actually deposit
    /// @return liquidity       Amount of liquidity token returned from deposit
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountADesired,
        uint256 amountBDesired
    ) external view returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Quote the amount of liquidity removed from a Pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param _factory     Address of PoolFactory for tokenA and tokenB
    /// @param liquidity    Amount of liquidity to remove
    /// @return amountA     Amount of tokenA received
    /// @return amountB     Amount of tokenB received
    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity
    ) external view returns (uint256 amountA, uint256 amountB);

    /// @notice Add liquidity of two tokens to a Pool
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           True if pool is stable, false if volatile
    /// @param amountADesired   Amount of tokenA desired to deposit
    /// @param amountBDesired   Amount of tokenB desired to deposit
    /// @param amountAMin       Minimum amount of tokenA to deposit
    /// @param amountBMin       Minimum amount of tokenB to deposit
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountA         Amount of tokenA to actually deposit
    /// @return amountB         Amount of tokenB to actually deposit
    /// @return liquidity       Amount of liquidity token returned from deposit
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    /// @notice Add liquidity of a token and WETH (transferred as ETH) to a Pool
    /// @param token                .
    /// @param stable               True if pool is stable, false if volatile
    /// @param amountTokenDesired   Amount of token desired to deposit
    /// @param amountTokenMin       Minimum amount of token to deposit
    /// @param amountETHMin         Minimum amount of ETH to deposit
    /// @param to                   Recipient of liquidity token
    /// @param deadline             Deadline to add liquidity
    /// @return amountToken         Amount of token to actually deposit
    /// @return amountETH           Amount of tokenETH to actually deposit
    /// @return liquidity           Amount of liquidity token returned from deposit
    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    // **** REMOVE LIQUIDITY ****

    /// @notice Remove liquidity of two tokens from a Pool
    /// @param tokenA       .
    /// @param tokenB       .
    /// @param stable       True if pool is stable, false if volatile
    /// @param liquidity    Amount of liquidity to remove
    /// @param amountAMin   Minimum amount of tokenA to receive
    /// @param amountBMin   Minimum amount of tokenB to receive
    /// @param to           Recipient of tokens received
    /// @param deadline     Deadline to remove liquidity
    /// @return amountA     Amount of tokenA received
    /// @return amountB     Amount of tokenB received
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    /// @notice Remove liquidity of a token and WETH (returned as ETH) from a Pool
    /// @param token            .
    /// @param stable           True if pool is stable, false if volatile
    /// @param liquidity        Amount of liquidity to remove
    /// @param amountTokenMin   Minimum amount of token to receive
    /// @param amountETHMin     Minimum amount of ETH to receive
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountToken     Amount of token received
    /// @return amountETH       Amount of ETH received
    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    /// @notice Remove liquidity of a fee-on-transfer token and WETH (returned as ETH) from a Pool
    /// @param token            .
    /// @param stable           True if pool is stable, false if volatile
    /// @param liquidity        Amount of liquidity to remove
    /// @param amountTokenMin   Minimum amount of token to receive
    /// @param amountETHMin     Minimum amount of ETH to receive
    /// @param to               Recipient of liquidity token
    /// @param deadline         Deadline to receive liquidity
    /// @return amountETH       Amount of ETH received
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    // **** SWAP ****

    /// @notice Swap one token for another
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Swap ETH for a token
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactETHForTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    /// @notice Swap a token for WETH (returned as ETH)
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired ETH
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    /// @return amounts     Array of amounts returned per route
    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    /// @notice Swap one token for another without slippage protection
    /// @return amounts     Array of amounts to swap  per route
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function UNSAFE_swapExactTokensForTokens(
        uint256[] memory amounts,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory);

    // **** SWAP (supporting fee-on-transfer tokens) ****

    /// @notice Swap one token for another supporting fee-on-transfer tokens
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external;

    /// @notice Swap ETH for a token supporting fee-on-transfer tokens
    /// @param amountOutMin Minimum amount of desired token received
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable;

    /// @notice Swap a token for WETH (returned as ETH) supporting fee-on-transfer tokens
    /// @param amountIn     Amount of token in
    /// @param amountOutMin Minimum amount of desired ETH
    /// @param routes       Array of trade routes used in the swap
    /// @param to           Recipient of the tokens received
    /// @param deadline     Deadline to receive tokens
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external;

    /// @notice Zap a token A into a pool (B, C). (A can be equal to B or C).
    ///         Supports standard ERC20 tokens only (i.e. not fee-on-transfer tokens etc).
    ///         Slippage is required for the initial swap.
    ///         Additional slippage may be required when adding liquidity as the
    ///         price of the token may have changed.
    /// @param tokenIn      Token you are zapping in from (i.e. input token).
    /// @param amountInA    Amount of input token you wish to send down routesA
    /// @param amountInB    Amount of input token you wish to send down routesB
    /// @param zapInPool    Contains zap struct information. See Zap struct.
    /// @param routesA      Route used to convert input token to tokenA
    /// @param routesB      Route used to convert input token to tokenB
    /// @param to           Address you wish to mint liquidity to.
    /// @param stake        Auto-stake liquidity in corresponding gauge.
    /// @return liquidity   Amount of LP tokens created from zapping in.
    function zapIn(
        address tokenIn,
        uint256 amountInA,
        uint256 amountInB,
        Zap calldata zapInPool,
        Route[] calldata routesA,
        Route[] calldata routesB,
        address to,
        bool stake
    ) external payable returns (uint256 liquidity);

    /// @notice Zap out a pool (B, C) into A.
    ///         Supports standard ERC20 tokens only (i.e. not fee-on-transfer tokens etc).
    ///         Slippage is required for the removal of liquidity.
    ///         Additional slippage may be required on the swap as the
    ///         price of the token may have changed.
    /// @param tokenOut     Token you are zapping out to (i.e. output token).
    /// @param liquidity    Amount of liquidity you wish to remove.
    /// @param zapOutPool   Contains zap struct information. See Zap struct.
    /// @param routesA      Route used to convert tokenA into output token.
    /// @param routesB      Route used to convert tokenB into output token.
    function zapOut(
        address tokenOut,
        uint256 liquidity,
        Zap calldata zapOutPool,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external;

    /// @notice Used to generate params required for zapping in.
    ///         Zap in => remove liquidity then swap.
    ///         Apply slippage to expected swap values to account for changes in reserves in between.
    /// @dev Output token refers to the token you want to zap in from.
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           .
    /// @param _factory         .
    /// @param amountInA        Amount of input token you wish to send down routesA
    /// @param amountInB        Amount of input token you wish to send down routesB
    /// @param routesA          Route used to convert input token to tokenA
    /// @param routesB          Route used to convert input token to tokenB
    /// @return amountOutMinA   Minimum output expected from swapping input token to tokenA.
    /// @return amountOutMinB   Minimum output expected from swapping input token to tokenB.
    /// @return amountAMin      Minimum amount of tokenA expected from depositing liquidity.
    /// @return amountBMin      Minimum amount of tokenB expected from depositing liquidity.
    function generateZapInParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountInA,
        uint256 amountInB,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin);

    /// @notice Used to generate params required for zapping out.
    ///         Zap out => swap then add liquidity.
    ///         Apply slippage to expected liquidity values to account for changes in reserves in between.
    /// @dev Output token refers to the token you want to zap out of.
    /// @param tokenA           .
    /// @param tokenB           .
    /// @param stable           .
    /// @param _factory         .
    /// @param liquidity        Amount of liquidity being zapped out of into a given output token.
    /// @param routesA          Route used to convert tokenA into output token.
    /// @param routesB          Route used to convert tokenB into output token.
    /// @return amountOutMinA   Minimum output expected from swapping tokenA into output token.
    /// @return amountOutMinB   Minimum output expected from swapping tokenB into output token.
    /// @return amountAMin      Minimum amount of tokenA expected from withdrawing liquidity.
    /// @return amountBMin      Minimum amount of tokenB expected from withdrawing liquidity.
    function generateZapOutParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin);

    /// @notice Used by zapper to determine appropriate ratio of A to B to deposit liquidity. Assumes stable pool.
    /// @dev Returns stable liquidity ratio of B to (A + B).
    ///      E.g. if ratio is 0.4, it means there is more of A than there is of B.
    ///      Therefore you should deposit more of token A than B.
    /// @param tokenA   tokenA of stable pool you are zapping into.
    /// @param tokenB   tokenB of stable pool you are zapping into.
    /// @param factory  Factory that created stable pool.
    /// @return ratio   Ratio of token0 to token1 required to deposit into zap.
    function quoteStableLiquidityRatio(
        address tokenA,
        address tokenB,
        address factory
    ) external view returns (uint256 ratio);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVeArtProxy {
    /// @dev Art configuration
    struct Config {
        // NFT metadata variables
        int256 _tokenId;
        int256 _balanceOf;
        int256 _lockedEnd;
        int256 _lockedAmount;
        // Line art variables
        int256 shape;
        uint256 palette;
        int256 maxLines;
        int256 dash;
        // Randomness variables
        int256 seed1;
        int256 seed2;
        int256 seed3;
    }

    /// @dev Individual line art path variables.
    struct lineConfig {
        string color;
        uint256 stroke;
        uint256 offset;
        uint256 offsetHalf;
        uint256 offsetDashSum;
        uint256 pathLength;
    }

    /// @dev Represents an (x,y) coordinate in a line.
    struct Point {
        int256 x;
        int256 y;
    }

    /// @notice Generate a SVG based on veNFT metadata
    /// @param _tokenId Unique veNFT identifier
    /// @return output SVG metadata as HTML tag
    function tokenURI(uint256 _tokenId) external view returns (string memory output);

    /// @notice Generate only the foreground <path> elements of the line art for an NFT (excluding SVG header), for flexibility purposes.
    /// @param _tokenId Unique veNFT identifier
    /// @return output Encoded output of generateShape()
    function lineArtPathsOnly(uint256 _tokenId) external view returns (bytes memory output);

    /// @notice Generate the master art config metadata for a veNFT
    /// @param _tokenId Unique veNFT identifier
    /// @return cfg Config struct
    function generateConfig(uint256 _tokenId) external view returns (Config memory cfg);

    /// @notice Generate the points for two stripe lines based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of line drawn
    /// @return Line (x, y) coordinates of the drawn stripes
    function twoStripes(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of circles drawn
    /// @return Line (x, y) coordinates of the drawn circles
    function circles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for interlocking circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of interlocking circles drawn
    /// @return Line (x, y) coordinates of the drawn interlocking circles
    function interlockingCircles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for corners based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of corners drawn
    /// @return Line (x, y) coordinates of the drawn corners
    function corners(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a curve based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of curve drawn
    /// @return Line (x, y) coordinates of the drawn curve
    function curves(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a spiral based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of spiral drawn
    /// @return Line (x, y) coordinates of the drawn spiral
    function spiral(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for an explosion based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of explosion drawn
    /// @return Line (x, y) coordinates of the drawn explosion
    function explosion(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a wormhole based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of wormhole drawn
    /// @return Line (x, y) coordinates of the drawn wormhole
    function wormhole(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVoter {
    error AlreadyVotedOrDeposited();
    error DistributeWindow();
    error FactoryPathNotApproved();
    error GaugeAlreadyKilled();
    error GaugeAlreadyRevived();
    error GaugeExists();
    error GaugeDoesNotExist(address _pool);
    error GaugeNotAlive(address _gauge);
    error InactiveManagedNFT();
    error MaximumVotingNumberTooLow();
    error NonZeroVotes();
    error NotAPool();
    error NotApprovedOrOwner();
    error NotGovernor();
    error NotEmergencyCouncil();
    error NotMinter();
    error NotWhitelistedNFT();
    error NotWhitelistedToken();
    error SameValue();
    error SpecialVotingWindow();
    error TooManyPools();
    error UnequalLengths();
    error ZeroBalance();
    error ZeroAddress();

    event GaugeCreated(
        address indexed poolFactory,
        address indexed votingRewardsFactory,
        address indexed gaugeFactory,
        address pool,
        address bribeVotingReward,
        address feeVotingReward,
        address gauge,
        address creator
    );
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event Abstained(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event WhitelistToken(address indexed whitelister, address indexed token, bool indexed _bool);
    event WhitelistNFT(address indexed whitelister, uint256 indexed tokenId, bool indexed _bool);

    /// @notice Store trusted forwarder address to pass into factories
    function forwarder() external view returns (address);

    /// @notice The ve token that governs these contracts
    function ve() external view returns (address);

    /// @notice Factory registry for valid pool / gauge / rewards factories
    function factoryRegistry() external view returns (address);

    /// @notice Address of Minter.sol
    function minter() external view returns (address);

    /// @notice Standard OZ IGovernor using ve for vote weights.
    function governor() external view returns (address);

    /// @notice Custom Epoch Governor using ve for vote weights.
    function epochGovernor() external view returns (address);

    /// @notice credibly neutral party similar to Curve's Emergency DAO
    function emergencyCouncil() external view returns (address);

    /// @dev Total Voting Weights
    function totalWeight() external view returns (uint256);

    /// @dev Most number of pools one voter can vote for at once
    function maxVotingNum() external view returns (uint256);

    // mappings
    /// @dev Pool => Gauge
    function gauges(address pool) external view returns (address);

    /// @dev Gauge => Pool
    function poolForGauge(address gauge) external view returns (address);

    /// @dev Gauge => Fees Voting Reward
    function gaugeToFees(address gauge) external view returns (address);

    /// @dev Gauge => Bribes Voting Reward
    function gaugeToBribe(address gauge) external view returns (address);

    /// @dev Pool => Weights
    function weights(address pool) external view returns (uint256);

    /// @dev NFT => Pool => Votes
    function votes(uint256 tokenId, address pool) external view returns (uint256);

    /// @dev NFT => Total voting weight of NFT
    function usedWeights(uint256 tokenId) external view returns (uint256);

    /// @dev Nft => Timestamp of last vote (ensures single vote per epoch)
    function lastVoted(uint256 tokenId) external view returns (uint256);

    /// @dev Address => Gauge
    function isGauge(address) external view returns (bool);

    /// @dev Token => Whitelisted status
    function isWhitelistedToken(address token) external view returns (bool);

    /// @dev TokenId => Whitelisted status
    function isWhitelistedNFT(uint256 tokenId) external view returns (bool);

    /// @dev Gauge => Liveness status
    function isAlive(address gauge) external view returns (bool);

    /// @dev Gauge => Amount claimable
    function claimable(address gauge) external view returns (uint256);

    /// @notice Number of pools with a Gauge
    function length() external view returns (uint256);

    /// @notice Called by Minter to distribute weekly emissions rewards for disbursement amongst gauges.
    /// @dev Assumes totalWeight != 0 (Will never be zero as long as users are voting).
    ///      Throws if not called by minter.
    /// @param _amount Amount of rewards to distribute.
    function notifyRewardAmount(uint256 _amount) external;

    /// @dev Utility to distribute to gauges of pools in range _start to _finish.
    /// @param _start   Starting index of gauges to distribute to.
    /// @param _finish  Ending index of gauges to distribute to.
    function distribute(uint256 _start, uint256 _finish) external;

    /// @dev Utility to distribute to gauges of pools in array.
    /// @param _gauges Array of gauges to distribute to.
    function distribute(address[] memory _gauges) external;

    /// @notice Called by users to update voting balances in voting rewards contracts.
    /// @param _tokenId Id of veNFT whose balance you wish to update.
    function poke(uint256 _tokenId) external;

    /// @notice Called by users to vote for pools. Votes distributed proportionally based on weights.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Can only vote for gauges that have not been killed.
    /// @dev Weights are distributed proportional to the sum of the weights in the array.
    ///      Throws if length of _poolVote and _weights do not match.
    /// @param _tokenId     Id of veNFT you are voting with.
    /// @param _poolVote    Array of pools you are voting for.
    /// @param _weights     Weights of pools.
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external;

    /// @notice Called by users to reset voting state. Required if you wish to make changes to
    ///         veNFT state (e.g. merge, split, deposit into managed etc).
    ///         Cannot reset in the same epoch that you voted in.
    ///         Can vote or deposit into a managed NFT again after reset.
    /// @param _tokenId Id of veNFT you are reseting.
    function reset(uint256 _tokenId) external;

    /// @notice Called by users to deposit into a managed NFT.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    /// @dev Throws if not approved or owner.
    ///      Throws if managed NFT is inactive.
    ///      Throws if depositing within privileged window (one hour prior to epoch flip).
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Called by users to withdraw from a managed NFT.
    ///         Cannot do it in the same epoch that you deposited into a managed NFT.
    ///         Can vote or deposit into a managed NFT again after withdrawing.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Claim emissions from gauges.
    /// @param _gauges Array of gauges to collect emissions from.
    function claimRewards(address[] memory _gauges) external;

    /// @notice Claim bribes for a given NFT.
    /// @dev Utility to help batch bribe claims.
    /// @param _bribes  Array of BribeVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as bribes.
    /// @param _tokenId Id of veNFT that you wish to claim bribes for.
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Claim fees for a given NFT.
    /// @dev Utility to help batch fee claims.
    /// @param _fees    Array of FeesVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as fees.
    /// @param _tokenId Id of veNFT that you wish to claim fees for.
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Set new governor.
    /// @dev Throws if not called by governor.
    /// @param _governor .
    function setGovernor(address _governor) external;

    /// @notice Set new epoch based governor.
    /// @dev Throws if not called by governor.
    /// @param _epochGovernor .
    function setEpochGovernor(address _epochGovernor) external;

    /// @notice Set new emergency council.
    /// @dev Throws if not called by emergency council.
    /// @param _emergencyCouncil .
    function setEmergencyCouncil(address _emergencyCouncil) external;

    /// @notice Set maximum number of gauges that can be voted for.
    /// @dev Throws if not called by governor.
    ///      Throws if _maxVotingNum is too low.
    ///      Throws if the values are the same.
    /// @param _maxVotingNum .
    function setMaxVotingNum(uint256 _maxVotingNum) external;

    /// @notice Whitelist (or unwhitelist) token for use in bribes.
    /// @dev Throws if not called by governor.
    /// @param _token .
    /// @param _bool .
    function whitelistToken(address _token, bool _bool) external;

    /// @notice Whitelist (or unwhitelist) token id for voting in last hour prior to epoch flip.
    /// @dev Throws if not called by governor.
    ///      Throws if already whitelisted.
    /// @param _tokenId .
    /// @param _bool .
    function whitelistNFT(uint256 _tokenId, bool _bool) external;

    /// @notice Create a new gauge (unpermissioned).
    /// @dev Governor can create a new gauge for a pool with any address.
    /// @param _poolFactory .
    /// @param _pool .
    function createGauge(address _poolFactory, address _pool) external returns (address);

    /// @notice Kills a gauge. The gauge will not receive any new emissions and cannot be deposited into.
    ///         Can still withdraw from gauge.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge already killed.
    /// @param _gauge .
    function killGauge(address _gauge) external;

    /// @notice Revives a killed gauge. Gauge will can receive emissions and deposits again.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge is not killed.
    /// @param _gauge .
    function reviveGauge(address _gauge) external;

    /// @dev Update claims to emissions for an array of gauges.
    /// @param _gauges Array of gauges to update emissions for.
    function updateFor(address[] memory _gauges) external;

    /// @dev Update claims to emissions for gauges based on their pool id as stored in Voter.
    /// @param _start   Starting index of pools.
    /// @param _end     Ending index of pools.
    function updateFor(uint256 _start, uint256 _end) external;

    /// @dev Update claims to emissions for single gauge
    /// @param _gauge .
    function updateFor(address _gauge) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165, IERC721, IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import {IERC6372} from "@openzeppelin/contracts/interfaces/IERC6372.sol";
import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {IVotes} from "../governance/IVotes.sol";

interface IVotingEscrow is IVotes, IERC4906, IERC6372, IERC721Metadata {
    struct LockedBalance {
        int128 amount;
        uint256 end;
        bool isPermanent;
    }

    struct UserPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanent;
    }

    struct GlobalPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanentLockBalance;
    }

    /// @notice A checkpoint for recorded delegated voting weights at a certain timestamp
    struct Checkpoint {
        uint256 fromTimestamp;
        address owner;
        uint256 delegatedBalance;
        uint256 delegatee;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @dev Different types of veNFTs:
    /// NORMAL  - typical veNFT
    /// LOCKED  - veNFT which is locked into a MANAGED veNFT
    /// MANAGED - veNFT which can accept the deposit of NORMAL veNFTs
    enum EscrowType {
        NORMAL,
        LOCKED,
        MANAGED
    }

    error AlreadyVoted();
    error AmountTooBig();
    error ERC721ReceiverRejectedTokens();
    error ERC721TransferToNonERC721ReceiverImplementer();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureS();
    error InvalidManagedNFTId();
    error LockDurationNotInFuture();
    error LockDurationTooLong();
    error LockExpired();
    error LockNotExpired();
    error NoLockFound();
    error NonExistentToken();
    error NotApprovedOrOwner();
    error NotDistributor();
    error NotEmergencyCouncilOrGovernor();
    error NotGovernor();
    error NotGovernorOrManager();
    error NotManagedNFT();
    error NotManagedOrNormalNFT();
    error NotLockedNFT();
    error NotNormalNFT();
    error NotPermanentLock();
    error NotOwner();
    error NotTeam();
    error NotVoter();
    error OwnershipChange();
    error PermanentLock();
    error SameAddress();
    error SameNFT();
    error SameState();
    error SplitNoOwner();
    error SplitNotAllowed();
    error SignatureExpired();
    error TooManyTokenIDs();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroBalance();

    event Deposit(
        address indexed provider,
        uint256 indexed tokenId,
        DepositType indexed depositType,
        uint256 value,
        uint256 locktime,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 indexed tokenId, uint256 value, uint256 ts);
    event LockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event UnlockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Merge(
        address indexed _sender,
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 _amountFrom,
        uint256 _amountTo,
        uint256 _amountFinal,
        uint256 _locktime,
        uint256 _ts
    );
    event Split(
        uint256 indexed _from,
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        address _sender,
        uint256 _splitAmount1,
        uint256 _splitAmount2,
        uint256 _locktime,
        uint256 _ts
    );
    event CreateManaged(
        address indexed _to,
        uint256 indexed _mTokenId,
        address indexed _from,
        address _lockedManagedReward,
        address _freeManagedReward
    );
    event DepositManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event WithdrawManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event SetAllowedManager(address indexed _allowedManager);

    // State variables
    /// @notice Address of Meta-tx Forwarder
    function forwarder() external view returns (address);

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of token (PRFCT) used to create a veNFT
    function token() external view returns (address);

    /// @notice Address of RewardsDistributor.sol
    function distributor() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of Protocol Team multisig
    function team() external view returns (address);

    /// @notice Address of art proxy used for on-chain art generation
    function artProxy() external view returns (address);

    /// @dev address which can create managed NFTs
    function allowedManager() external view returns (address);

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping of token id to escrow type
    ///      Takes advantage of the fact default value is EscrowType.NORMAL
    function escrowType(uint256 tokenId) external view returns (EscrowType);

    /// @dev Mapping of token id to managed id
    function idToManaged(uint256 tokenId) external view returns (uint256 managedTokenId);

    /// @dev Mapping of user token id to managed token id to weight of token id
    function weights(uint256 tokenId, uint256 managedTokenId) external view returns (uint256 weight);

    /// @dev Mapping of managed id to deactivated state
    function deactivated(uint256 tokenId) external view returns (bool inactive);

    /// @dev Mapping from managed nft id to locked managed rewards
    ///      `token` denominated rewards (rebases/rewards) stored in locked managed rewards contract
    ///      to prevent co-mingling of assets
    function managedToLocked(uint256 tokenId) external view returns (address);

    /// @dev Mapping from managed nft id to free managed rewards contract
    ///      these rewards can be freely withdrawn by users
    function managedToFree(uint256 tokenId) external view returns (address);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create managed NFT (a permanent lock) for use within ecosystem.
    /// @dev Throws if address already owns a managed NFT.
    /// @return _mTokenId managed token id.
    function createManagedLockFor(address _to) external returns (uint256 _mTokenId);

    /// @notice Delegates balance to managed nft
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    ///         Permanent locks that are deposited will automatically unlock.
    /// @dev Managed nft will remain max-locked as long as there is at least one
    ///      deposit or withdrawal per week.
    ///      Throws if deposit nft is managed.
    ///      Throws if recipient nft is not managed.
    ///      Throws if deposit nft is already locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited
    /// @param _mTokenId tokenId of managed NFT that will receive the deposit
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Retrieves locked rewards and withdraws balance from managed nft.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    /// @dev Throws if NFT not locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Permit one address to call createManagedLockFor() that is not Voter.governor()
    function setAllowedManager(address _allowedManager) external;

    /// @notice Set Managed NFT state. Inactive NFTs cannot be deposited into.
    /// @param _mTokenId managed nft state to set
    /// @param _state true => inactive, false => active
    function setManagedState(uint256 _mTokenId, bool _state) external;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setTeam(address _team) external;

    function setArtProxy(address _proxy) external;

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenId
    function ownerToNFTokenIdList(address _owner, uint256 _index) external view returns (uint256 _tokenId);

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) external view returns (address operator);

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Check whether spender is owner or an approved user for a given veNFT
    /// @param _spender .
    /// @param _tokenId .
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external;

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total count of epochs witnessed since contract creation
    function epoch() external view returns (uint256);

    /// @notice Total amount of token() deposited
    function supply() external view returns (uint256);

    /// @notice Aggregate permanent locked balances
    function permanentLockBalance() external view returns (uint256);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256 _epoch);

    /// @notice time -> signed slope change
    function slopeChanges(uint256 _timestamp) external view returns (int128);

    /// @notice account -> can split
    function canSplit(address _account) external view returns (bool);

    /// @notice Global point history at a given index
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory);

    /// @notice Get the LockedBalance (amount, end) of a _tokenId
    /// @param _tokenId .
    /// @return LockedBalance of _tokenId
    function locked(uint256 _tokenId) external view returns (LockedBalance memory);

    /// @notice User -> UserPoint[userEpoch]
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory);

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value) external;

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @return TokenId of created veNFT
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256);

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @return TokenId of created veNFT
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external returns (uint256);

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    /// @notice Extend the unlock time for `_tokenId`
    ///         Cannot extend lock time of permanent locks
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock is both expired and not permanent
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    function withdraw(uint256 _tokenId) external;

    /// @notice Merges `_from` into `_to`.
    /// @dev Cannot merge `_from` locks that are permanent or have already voted this epoch.
    ///      Cannot merge `_to` locks that have already expired.
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to merge from.
    /// @param _to VeNFT to merge into.
    function merge(uint256 _from, uint256 _to) external;

    /// @notice Splits veNFT into two new veNFTS - one with oldLocked.amount - `_amount`, and the second with `_amount`
    /// @dev    This burns the tokenId of the target veNFT
    ///         Callable by approved or owner
    ///         If this is called by approved, approved will not have permissions to manipulate the newly created veNFTs
    ///         Returns the two new split veNFTs to owner
    ///         If `from` is permanent, will automatically dedelegate.
    ///         This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///         will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to split.
    /// @param _amount Amount to split from veNFT.
    /// @return _tokenId1 Return tokenId of veNFT with oldLocked.amount - `_amount`.
    /// @return _tokenId2 Return tokenId of veNFT with `_amount`.
    function split(uint256 _from, uint256 _amount) external returns (uint256 _tokenId1, uint256 _tokenId2);

    /// @notice Toggle split for a specific address.
    /// @dev Toggle split for address(0) to enable or disable for all.
    /// @param _account Address to toggle split permissions
    /// @param _bool True to allow, false to disallow
    function toggleSplit(address _account, bool _bool) external;

    /// @notice Permanently lock a veNFT. Voting power will be equal to
    ///         `LockedBalance.amount` with no decay. Required to delegate.
    /// @dev Only callable by unlocked normal veNFTs.
    /// @param _tokenId tokenId to lock.
    function lockPermanent(uint256 _tokenId) external;

    /// @notice Unlock a permanently locked veNFT. Voting power will decay.
    ///         Will automatically dedelegate if delegated.
    /// @dev Only callable by permanently locked veNFTs.
    ///      Cannot unlock if already voted this epoch.
    /// @param _tokenId tokenId to unlock.
    function unlockPermanent(uint256 _tokenId) external;

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the voting power for _tokenId at the current timestamp
    /// @dev Returns 0 if called in the same block as a transfer.
    /// @param _tokenId .
    /// @return Voting power
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the voting power for _tokenId at a given timestamp
    /// @param _tokenId .
    /// @param _t Timestamp to query voting power
    /// @return Voting power
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power at current timestamp
    /// @return Total voting power at current timestamp
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total voting power at a given timestamp
    /// @param _t Timestamp to query total voting power
    /// @return Total voting power at given timestamp
    function totalSupplyAt(uint256 _t) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice See if a queried _tokenId has actively voted
    /// @param _tokenId .
    /// @return True if voted, else false
    function voted(uint256 _tokenId) external view returns (bool);

    /// @notice Set the global state voter and distributor
    /// @dev This is only called once, at setup
    function setVoterAndDistributor(address _voter, address _distributor) external;

    /// @notice Set `voted` for _tokenId to true or false
    /// @dev Only callable by voter
    /// @param _tokenId .
    /// @param _voted .
    function voting(uint256 _tokenId, bool _voted) external;

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of checkpoints for each tokenId
    function numCheckpoints(uint256 tokenId) external view returns (uint48);

    /// @notice A record of states for signing / validating signatures
    function nonces(address account) external view returns (uint256);

    /// @inheritdoc IVotes
    function delegates(uint256 delegator) external view returns (uint256);

    /// @notice A record of delegated token checkpoints for each account, by index
    /// @param tokenId .
    /// @param index .
    /// @return Checkpoint
    function checkpoints(uint256 tokenId, uint48 index) external view returns (Checkpoint memory);

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotes
    function delegate(uint256 delegator, uint256 delegatee) external;

    /// @inheritdoc IVotes
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC6372
    function clock() external view returns (uint48);

    /// @inheritdoc IERC6372
    function CLOCK_MODE() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

library ProtocolTimeLibrary {
    uint256 internal constant WEEK = 7 days;

    /// @dev Returns start of epoch based on current timestamp
    function epochStart(uint256 timestamp) internal pure returns (uint256) {
        unchecked {
            return timestamp - (timestamp % WEEK);
        }
    }

    /// @dev Returns start of next epoch / end of current epoch
    function epochNext(uint256 timestamp) internal pure returns (uint256) {
        unchecked {
            return timestamp - (timestamp % WEEK) + WEEK;
        }
    }

    /// @dev Returns start of voting window
    function epochVoteStart(uint256 timestamp) internal pure returns (uint256) {
        unchecked {
            return timestamp - (timestamp % WEEK) + 1 hours;
        }
    }

    /// @dev Returns end of voting window / beginning of unrestricted voting window
    function epochVoteEnd(uint256 timestamp) internal pure returns (uint256) {
        unchecked {
            return timestamp - (timestamp % WEEK) + WEEK - 1 hours;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

/// @title SafeCast Library
/// @notice Safely convert unsigned and signed integers without overflow / underflow
library SafeCastLibrary {
    error SafeCastOverflow();
    error SafeCastUnderflow();

    /// @dev Safely convert uint256 to int128
    function toInt128(uint256 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max)) revert SafeCastOverflow();
        return int128(uint128(value));
    }

    /// @dev Safely convert int128 to uint256
    function toUint256(int128 value) internal pure returns (uint256) {
        if (value < 0) revert SafeCastUnderflow();
        return uint256(int256(value));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {IRewardsDistributor} from "./interfaces/IRewardsDistributor.sol";
import {IPrfct} from "./interfaces/IPrfct.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IEpochGovernor} from "./interfaces/IEpochGovernor.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Minter
/// @notice Controls minting of emissions and rebases for the Protocol
contract Minter is IMinter {
    using SafeERC20 for IPrfct;
    /// @inheritdoc IMinter
    IPrfct public immutable prfct;
    /// @inheritdoc IMinter
    IVoter public immutable voter;
    /// @inheritdoc IMinter
    IVotingEscrow public immutable ve;
    /// @inheritdoc IMinter
    IRewardsDistributor public immutable rewardsDistributor;

    /// @inheritdoc IMinter
    uint256 public constant WEEK = 1 weeks;
    /// @inheritdoc IMinter
    uint256 public constant WEEKLY_DECAY = 9_900;
    /// @inheritdoc IMinter
    uint256 public constant WEEKLY_GROWTH = 10_200;
    /// @inheritdoc IMinter
    uint256 public constant MAXIMUM_TAIL_RATE = 100;
    /// @inheritdoc IMinter
    uint256 public constant MINIMUM_TAIL_RATE = 1;
    /// @inheritdoc IMinter
    uint256 public constant MAX_BPS = 10_000;
    /// @inheritdoc IMinter
    uint256 public constant NUDGE = 1;
    /// @inheritdoc IMinter
    uint256 public constant TAIL_START = 450_800 * 1e18;
    /// @inheritdoc IMinter
    uint256 public tailEmissionRate = 67;
    /// @inheritdoc IMinter
    uint256 public constant MAXIMUM_TEAM_RATE = 500;
    /// @inheritdoc IMinter
    uint256 public teamRate = 500; // team emissions start at 5%
    /// @inheritdoc IMinter
    uint256 public weekly = 500_000 * 1e18;
    /// @inheritdoc IMinter
    uint256 public activePeriod;
    /// @inheritdoc IMinter
    uint256 public epochCount;
    /// @inheritdoc IMinter
    mapping(uint256 => bool) public proposals;
    /// @inheritdoc IMinter
    address public team;
    /// @inheritdoc IMinter
    address public pendingTeam;
    /// @inheritdoc IMinter
    bool public initialized;

    bool public startedreward;
    

    constructor(
        address _voter, // the voting & distribution system
        address _ve, // the ve(3,3) system that will be locked into
        address _rewardsDistributor // the distribution system that ensures users aren't diluted
    ) {
        prfct = IPrfct(IVotingEscrow(_ve).token());
        voter = IVoter(_voter);
        ve = IVotingEscrow(_ve);
        team = msg.sender;
        rewardsDistributor = IRewardsDistributor(_rewardsDistributor);
        activePeriod = ((block.timestamp) / WEEK + 5) * WEEK; // allow emissions this coming epoch
    }

    /// @inheritdoc IMinter
    function initialize(AirdropParams memory params) external {
        if (initialized) revert AlreadyInitialized();
        if (msg.sender != team) revert NotTeam();
        if (
            (params.liquidWallets.length != params.liquidAmounts.length) ||
            (params.lockedWallets.length != params.lockedAmounts.length)
        ) revert InvalidParams();
        initialized = true;

        // Liquid Token Mint
        uint256 _len = params.liquidWallets.length;
        for (uint256 i = 0; i < _len; i++) {
            prfct.mint(params.liquidWallets[i], params.liquidAmounts[i]);
            emit DistributeLiquid(params.liquidWallets[i], params.liquidAmounts[i]);
        }

        // Locked NFT mint
        _len = params.lockedWallets.length;
        uint256 _sum;
        for (uint256 i = 0; i < _len; i++) {
            _sum += params.lockedAmounts[i];
        }
        uint256 _tokenId;
        prfct.mint(address(this), _sum);
        prfct.safeApprove(address(ve), _sum);
        for (uint256 i = 0; i < _len; i++) {
            _tokenId = ve.createLock(params.lockedAmounts[i], WEEK);
            ve.lockPermanent(_tokenId);
            ve.safeTransferFrom(address(this), params.lockedWallets[i], _tokenId);
            emit DistributeLocked(params.lockedWallets[i], params.lockedAmounts[i], _tokenId);
        }
        prfct.safeApprove(address(ve), 0);
    }


    function startReward() external {
        if (startedreward) revert AlreadyStartedReward();
        if (msg.sender != team) revert NotTeam();
        activePeriod = ((block.timestamp) / WEEK) * WEEK; // allow emissions this coming epoch
        startedreward = true;
    }

    /// @inheritdoc IMinter
    function setTeam(address _team) external {
        if (msg.sender != team) revert NotTeam();
        if (_team == address(0)) revert ZeroAddress();
        pendingTeam = _team;
    }

    /// @inheritdoc IMinter
    function acceptTeam() external {
        if (msg.sender != pendingTeam) revert NotPendingTeam();
        team = pendingTeam;
        delete pendingTeam;
        emit AcceptTeam(team);
    }

    /// @inheritdoc IMinter
    function setTeamRate(uint256 _rate) external {
        if (msg.sender != team) revert NotTeam();
        if (_rate > MAXIMUM_TEAM_RATE) revert RateTooHigh();
        teamRate = _rate;
    }

    /// @inheritdoc IMinter
    function calculateGrowth(uint256 _minted) public view returns (uint256 _growth) {
        uint256 _veTotal = ve.totalSupplyAt(activePeriod - 1);
        uint256 _prfctTotal = prfct.totalSupply();

        return (((_minted * (_prfctTotal - _veTotal)) / _prfctTotal) * (_prfctTotal - _veTotal)) / _prfctTotal / 2;
    }

    /// @inheritdoc IMinter
    function nudge() external {
        address _epochGovernor = voter.epochGovernor();
        if (msg.sender != _epochGovernor) revert NotEpochGovernor();
        IEpochGovernor.ProposalState _state = IEpochGovernor(_epochGovernor).result();
        if (weekly >= TAIL_START) revert TailEmissionsInactive();
        uint256 _period = activePeriod;
        if (proposals[_period]) revert AlreadyNudged();
        uint256 _newRate = tailEmissionRate;
        uint256 _oldRate = _newRate;

        if (_state != IEpochGovernor.ProposalState.Expired) {
            if (_state == IEpochGovernor.ProposalState.Succeeded) {
                _newRate = _oldRate + NUDGE > MAXIMUM_TAIL_RATE ? MAXIMUM_TAIL_RATE : _oldRate + NUDGE;
            } else {
                _newRate = _oldRate - NUDGE < MINIMUM_TAIL_RATE ? MINIMUM_TAIL_RATE : _oldRate - NUDGE;
            }
            tailEmissionRate = _newRate;
        }
        proposals[_period] = true;
        emit Nudge(_period, _oldRate, _newRate);
    }

    /// @inheritdoc IMinter
    function updatePeriod() external returns (uint256 _period) {
        if (!startedreward) revert NotStartedReward();
        _period = activePeriod;
        if (block.timestamp >= _period + WEEK) {
            epochCount++;
            _period = (block.timestamp / WEEK) * WEEK;
            activePeriod = _period;
            uint256 _weekly = weekly;
            uint256 _emission;
            uint256 _totalSupply = prfct.totalSupply();
            bool _tail = _weekly < TAIL_START;

            if (_tail) {
                _emission = (_totalSupply * tailEmissionRate) / MAX_BPS;
            } else {
                _emission = _weekly;
                if (epochCount < 15) {
                    _weekly = (_weekly * WEEKLY_GROWTH) / MAX_BPS;
                } else {
                    _weekly = (_weekly * WEEKLY_DECAY) / MAX_BPS;
                }
                weekly = _weekly;
            }

            uint256 _growth = calculateGrowth(_emission);

            uint256 _rate = teamRate;
            uint256 _teamEmissions = (_rate * (_growth + _weekly)) / (MAX_BPS - _rate);

            uint256 _required = _growth + _emission + _teamEmissions;
            uint256 _balanceOf = prfct.balanceOf(address(this));
            if (_balanceOf < _required) {
                prfct.mint(address(this), _required - _balanceOf);
            }

            prfct.safeTransfer(address(team), _teamEmissions);
            prfct.safeTransfer(address(rewardsDistributor), _growth);
            rewardsDistributor.checkpointToken(); // checkpoint token balance that was just minted in rewards distributor

            prfct.safeApprove(address(voter), _emission);
            voter.notifyRewardAmount(_emission);

            emit Mint(msg.sender, _emission, prfct.totalSupply(), _tail);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IPoolCallee} from "./interfaces/IPoolCallee.sol";
import {IPoolFactory} from "./interfaces/factories/IPoolFactory.sol";
import {PoolFees} from "./PoolFees.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Pool
/// @notice Protocol token pool, either stable or volatile
contract Pool is IPool, ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;

    string private _name;
    string private _symbol;
    address private _voter;

    /// @inheritdoc IPool
    bool public stable;

    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 internal constant MINIMUM_K = 10 ** 10;

    /// @inheritdoc IPool
    address public token0;
    /// @inheritdoc IPool
    address public token1;
    /// @inheritdoc IPool
    address public poolFees;
    /// @inheritdoc IPool
    address public factory;

    /// @inheritdoc IPool
    uint256 public constant periodSize = 1800;

    Observation[] public observations;

    uint256 internal decimals0;
    uint256 internal decimals1;

    /// @inheritdoc IPool
    uint256 public reserve0;
    /// @inheritdoc IPool
    uint256 public reserve1;
    /// @inheritdoc IPool
    uint256 public blockTimestampLast;

    /// @inheritdoc IPool
    uint256 public reserve0CumulativeLast;
    /// @inheritdoc IPool
    uint256 public reserve1CumulativeLast;

    /// @inheritdoc IPool
    uint256 public index0 = 0;
    /// @inheritdoc IPool
    uint256 public index1 = 0;

    /// @inheritdoc IPool
    mapping(address => uint256) public supplyIndex0;
    /// @inheritdoc IPool
    mapping(address => uint256) public supplyIndex1;

    /// @inheritdoc IPool
    mapping(address => uint256) public claimable0;
    /// @inheritdoc IPool
    mapping(address => uint256) public claimable1;

    constructor() ERC20("", "") ERC20Permit("") {}

    /// @inheritdoc IPool
    function initialize(address _token0, address _token1, bool _stable) external {
        if (factory != address(0)) revert FactoryAlreadySet();
        factory = _msgSender();
        _voter = IPoolFactory(factory).voter();
        (token0, token1, stable) = (_token0, _token1, _stable);
        poolFees = address(new PoolFees(_token0, _token1));
        string memory symbol0 = ERC20(_token0).symbol();
        string memory symbol1 = ERC20(_token1).symbol();
        if (_stable) {
            _name = string(abi.encodePacked("Stable AMM - ", symbol0, "/", symbol1));
            _symbol = string(abi.encodePacked("sAMM-", symbol0, "/", symbol1));
        } else {
            _name = string(abi.encodePacked("Volatile AMM - ", symbol0, "/", symbol1));
            _symbol = string(abi.encodePacked("vAMM-", symbol0, "/", symbol1));
        }

        decimals0 = 10 ** ERC20(_token0).decimals();
        decimals1 = 10 ** ERC20(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));
    }

    /// @inheritdoc IPool
    function setName(string calldata __name) external {
        if (msg.sender != IVoter(_voter).emergencyCouncil()) revert NotEmergencyCouncil();
        _name = __name;
    }

    /// @inheritdoc IPool
    function setSymbol(string calldata __symbol) external {
        if (msg.sender != IVoter(_voter).emergencyCouncil()) revert NotEmergencyCouncil();
        _symbol = __symbol;
    }

    /// @inheritdoc IPool
    function observationLength() external view returns (uint256) {
        return observations.length;
    }

    /// @inheritdoc IPool
    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length - 1];
    }

    /// @inheritdoc IPool
    function metadata()
        external
        view
        returns (uint256 dec0, uint256 dec1, uint256 r0, uint256 r1, bool st, address t0, address t1)
    {
        return (decimals0, decimals1, reserve0, reserve1, stable, token0, token1);
    }

    /// @inheritdoc IPool
    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    /// @inheritdoc IPool
    function getK() external nonReentrant returns (uint256) {
        return _k(reserve0, reserve1);
    }

    /// @inheritdoc IPool
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        address sender = _msgSender();
        _updateFor(sender);

        claimed0 = claimable0[sender];
        claimed1 = claimable1[sender];

        if (claimed0 > 0 || claimed1 > 0) {
            claimable0[sender] = 0;
            claimable1[sender] = 0;

            PoolFees(poolFees).claimFeesFor(sender, claimed0, claimed1);

            emit Claim(sender, sender, claimed0, claimed1);
        }
    }

    /// @dev Accrue fees on token0
    function _update0(uint256 amount) internal {
        // Only update on this pool if there is a fee
        if (amount == 0) return;
        IERC20(token0).safeTransfer(poolFees, amount); // transfer the fees out to PoolFees
        uint256 _ratio = (amount * 1e18) / totalSupply(); // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index0 += _ratio;
        }
        emit Fees(_msgSender(), amount, 0);
    }

    /// @dev Accrue fees on token1
    function _update1(uint256 amount) internal {
        // Only update on this pool if there is a fee
        if (amount == 0) return;
        IERC20(token1).safeTransfer(poolFees, amount);
        uint256 _ratio = (amount * 1e18) / totalSupply();
        if (_ratio > 0) {
            index1 += _ratio;
        }
        emit Fees(_msgSender(), 0, amount);
    }

    /// @dev This function MUST be called on any balance changes, otherwise can be used to infinitely claim fees
    ///      Fees are segregated from core funds, so fees can never put liquidity at risk.
    function _updateFor(address recipient) internal {
        uint256 _supplied = balanceOf(recipient); // get LP balance of `recipient`
        if (_supplied > 0) {
            uint256 _supplyIndex0 = supplyIndex0[recipient]; // get last adjusted index0 for recipient
            uint256 _supplyIndex1 = supplyIndex1[recipient];
            uint256 _index0 = index0; // get global index0 for accumulated fees
            uint256 _index1 = index1;
            supplyIndex0[recipient] = _index0; // update user current position to global position
            supplyIndex1[recipient] = _index1;
            uint256 _delta0 = _index0 - _supplyIndex0; // see if there is any difference that need to be accrued
            uint256 _delta1 = _index1 - _supplyIndex1;
            if (_delta0 > 0) {
                uint256 _share = (_supplied * _delta0) / 1e18; // add accrued difference for each supplied token
                claimable0[recipient] += _share;
            }
            if (_delta1 > 0) {
                uint256 _share = (_supplied * _delta1) / 1e18;
                claimable1[recipient] += _share;
            }
        } else {
            supplyIndex0[recipient] = index0; // new users are set to the default global state
            supplyIndex1[recipient] = index1;
        }
    }

    /// @inheritdoc IPool
    function getReserves() public view returns (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    /// @dev update reserves and, on the first call per block, price accumulators
    function _update(uint256 balance0, uint256 balance1, uint256 _reserve0, uint256 _reserve1) internal {
        uint256 blockTimestamp = block.timestamp;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(Observation(blockTimestamp, reserve0CumulativeLast, reserve1CumulativeLast));
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /// @inheritdoc IPool
    function currentCumulativePrices()
        public
        view
        returns (uint256 reserve0Cumulative, uint256 reserve1Cumulative, uint256 blockTimestamp)
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pool, mock the accumulated price values
        (uint256 _reserve0, uint256 _reserve1, uint256 _blockTimestampLast) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    /// @inheritdoc IPool
    function quote(address tokenIn, uint256 amountIn, uint256 granularity) external view returns (uint256 amountOut) {
        uint256[] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint256 priceAverageCumulative;
        uint256 _length = _prices.length;
        for (uint256 i = 0; i < _length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    /// @inheritdoc IPool
    function prices(address tokenIn, uint256 amountIn, uint256 points) external view returns (uint256[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

    /// @inheritdoc IPool
    function sample(
        address tokenIn,
        uint256 amountIn,
        uint256 points,
        uint256 window
    ) public view returns (uint256[] memory) {
        uint256[] memory _prices = new uint256[](points);

        uint256 length = observations.length - 1;
        uint256 i = length - (points * window);
        uint256 nextIndex = 0;
        uint256 index = 0;

        for (; i < length; i += window) {
            nextIndex = i + window;
            uint256 timeElapsed = observations[nextIndex].timestamp - observations[i].timestamp;
            uint256 _reserve0 = (observations[nextIndex].reserve0Cumulative - observations[i].reserve0Cumulative) /
                timeElapsed;
            uint256 _reserve1 = (observations[nextIndex].reserve1Cumulative - observations[i].reserve1Cumulative) /
                timeElapsed;
            _prices[index] = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
            // index < length; length cannot overflow
            unchecked {
                index = index + 1;
            }
        }
        return _prices;
    }

    /// @inheritdoc IPool
    function mint(address to) external nonReentrant returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(1), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens - cannot be address(0)
            if (stable) {
                if ((_amount0 * 1e18) / decimals0 != (_amount1 * 1e18) / decimals1) revert DepositsNotEqual();
                if (_k(_amount0, _amount1) <= MINIMUM_K) revert BelowMinimumK();
            }
        } else {
            liquidity = Math.min((_amount0 * _totalSupply) / _reserve0, (_amount1 * _totalSupply) / _reserve1);
        }
        if (liquidity == 0) revert InsufficientLiquidityMinted();
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(_msgSender(), _amount0, _amount1);
    }

    /// @inheritdoc IPool
    function burn(address to) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf(address(this));

        uint256 _totalSupply = totalSupply(); // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        if (amount0 == 0 || amount1 == 0) revert InsufficientLiquidityBurned();
        _burn(address(this), _liquidity);
        IERC20(_token0).safeTransfer(to, amount0);
        IERC20(_token1).safeTransfer(to, amount1);
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(_msgSender(), to, amount0, amount1);
    }

    /// @inheritdoc IPool
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external nonReentrant {
        if (IPoolFactory(factory).isPaused()) revert IsPaused();
        if (amount0Out == 0 && amount1Out == 0) revert InsufficientOutputAmount();
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        if (amount0Out >= _reserve0 || amount1Out >= _reserve1) revert InsufficientLiquidity();

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            if (to == _token0 || to == _token1) revert InvalidTo();
            if (amount0Out > 0) IERC20(_token0).safeTransfer(to, amount0Out); // optimistically transfer tokens
            if (amount1Out > 0) IERC20(_token1).safeTransfer(to, amount1Out); // optimistically transfer tokens
            if (data.length > 0) IPoolCallee(to).hook(_msgSender(), amount0Out, amount1Out, data); // callback, used for flash loans
            _balance0 = IERC20(_token0).balanceOf(address(this));
            _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out ? _balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out ? _balance1 - (_reserve1 - amount1Out) : 0;
        if (amount0In == 0 && amount1In == 0) revert InsufficientInputAmount();
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            if (amount0In > 0) _update0((amount0In * IPoolFactory(factory).getFee(address(this), stable)) / 10000); // accrue fees for token0 and move them out of pool
            if (amount1In > 0) _update1((amount1In * IPoolFactory(factory).getFee(address(this), stable)) / 10000); // accrue fees for token1 and move them out of pool
            _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - amountIn/ 10000, but doing balanceOf again as safety check
            _balance1 = IERC20(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            if (_k(_balance0, _balance1) < _k(_reserve0, _reserve1)) revert K();
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(_msgSender(), to, amount0In, amount1In, amount0Out, amount1Out);
    }

    /// @inheritdoc IPool
    function skim(address to) external nonReentrant {
        (address _token0, address _token1) = (token0, token1);
        IERC20(_token0).safeTransfer(to, IERC20(_token0).balanceOf(address(this)) - (reserve0));
        IERC20(_token1).safeTransfer(to, IERC20(_token1).balanceOf(address(this)) - (reserve1));
    }

    /// @inheritdoc IPool
    function sync() external nonReentrant {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
        uint256 _a = (x0 * y) / 1e18;
        uint256 _b = ((x0 * x0) / 1e18 + (y * y) / 1e18);
        return (_a * _b) / 1e18;
    }

    function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
        return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint256 x0, uint256 xy, uint256 y) internal view returns (uint256) {
        for (uint256 i = 0; i < 255; i++) {
            uint256 k = _f(x0, y);
            if (k < xy) {
                // there are two cases where dy == 0
                // case 1: The y is converged and we find the correct answer
                // case 2: _d(x0, y) is too large compare to (xy - k) and the rounding error
                //         screwed us.
                //         In this case, we need to increase y by 1
                uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy) {
                        // We found the correct answer. Return y
                        return y;
                    }
                    if (_k(x0, y + 1) > xy) {
                        // If _k(x0, y + 1) > xy, then we are close to the correct answer.
                        // There's no closer answer than y + 1
                        return y + 1;
                    }
                    dy = 1;
                }
                y = y + dy;
            } else {
                uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
                if (dy == 0) {
                    if (k == xy || _f(x0, y - 1) < xy) {
                        // Likewise, if k == xy, we found the correct answer.
                        // If _f(x0, y - 1) < xy, then we are close to the correct answer.
                        // There's no closer answer than "y"
                        // It's worth mentioning that we need to find y where f(x0, y) >= xy
                        // As a result, we can't return y - 1 even it's closer to the correct answer
                        return y;
                    }
                    dy = 1;
                }
                y = y - dy;
            }
        }
        revert("!y");
    }

    /// @inheritdoc IPool
    function getAmountOut(uint256 amountIn, address tokenIn) external view returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= (amountIn * IPoolFactory(factory).getFee(address(this), stable)) / 10000; // remove fee from amount received
        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    function _getAmountOut(
        uint256 amountIn,
        address tokenIn,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        if (stable) {
            uint256 xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            amountIn = tokenIn == token0 ? (amountIn * 1e18) / decimals0 : (amountIn * 1e18) / decimals1;
            uint256 y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint256 reserveA, uint256 reserveB) = tokenIn == token0 ? (_reserve0, _reserve1) : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _k(uint256 x, uint256 y) internal view returns (uint256) {
        if (stable) {
            uint256 _x = (x * 1e18) / decimals0;
            uint256 _y = (y * 1e18) / decimals1;
            uint256 _a = (_x * _y) / 1e18;
            uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
            return (_a * _b) / 1e18; // x3y+y3x >= k
        } else {
            return x * y; // xy >= k
        }
    }

    /*
    @dev OZ inheritance overrides
    These are needed as _name and _symbol are set privately before
    logic is executed within the constructor to set _name and _symbol.
    */
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function _beforeTokenTransfer(address from, address to, uint256) internal override {
        _updateFor(from);
        _updateFor(to);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title PoolFees
/// @notice Contract used as 1:1 pool relationship to split out fees.
/// @notice Ensures curve does not need to be modified for LP shares.
contract PoolFees {
    using SafeERC20 for IERC20;
    address internal immutable pool; // The pool it is bonded to
    address internal immutable token0; // token0 of pool, saved localy and statically for gas optimization
    address internal immutable token1; // Token1 of pool, saved localy and statically for gas optimization

    error NotPool();

    constructor(address _token0, address _token1) {
        pool = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    /// @notice Allow the pool to transfer fees to users
    function claimFeesFor(address _recipient, uint256 _amount0, uint256 _amount1) external {
        if (msg.sender != pool) revert NotPool();
        if (_amount0 > 0) IERC20(token0).safeTransfer(_recipient, _amount0);
        if (_amount1 > 0) IERC20(token1).safeTransfer(_recipient, _amount1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {IPrfct} from "./interfaces/IPrfct.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @title Prfct
/// @author perfect.swap
/// @notice The native token in the Protocol ecosystem
/// @dev Emitted by the Minter
contract Prfct is IPrfct, ERC20Permit {
    address public minter;
    address private owner;

    constructor() ERC20("PerfectSwap", "PRFCT") ERC20Permit("PerfectSwap") {
        minter = msg.sender;
        owner = msg.sender;
    }

    /// @dev No checks as its meant to be once off to set minting rights to BaseV1 Minter
    function setMinter(address _minter) external {
        if (msg.sender != minter) revert NotMinter();
        minter = _minter;
    }

    function mint(address account, uint256 amount) external returns (bool) {
        if (msg.sender != minter) revert NotMinter();
        _mint(account, amount);
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Forwarder} from "@opengsn/contracts/src/forwarder/Forwarder.sol";

contract ProtocolForwarder is Forwarder {
    constructor() Forwarder() {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IVotes} from "./governance/IVotes.sol";
import {IVotingEscrow} from "contracts/interfaces/IVotingEscrow.sol";

import {IVetoGovernor} from "./governance/IVetoGovernor.sol";
import {VetoGovernor} from "./governance/VetoGovernor.sol";
import {VetoGovernorCountingSimple} from "./governance/VetoGovernorCountingSimple.sol";
import {VetoGovernorVotes} from "./governance/VetoGovernorVotes.sol";
import {VetoGovernorVotesQuorumFraction} from "./governance/VetoGovernorVotesQuorumFraction.sol";

/// @title ProtocolGovernor
/// @notice Protocol governance with timestamp-based voting power from VotingEscrow NFTs
///         Supports vetoing of proposals as mitigation for 51% attacks
///         Votes are cast and counted on a per tokenId basis
contract ProtocolGovernor is
    VetoGovernor,
    VetoGovernorCountingSimple,
    VetoGovernorVotes,
    VetoGovernorVotesQuorumFraction
{
    address public immutable ve;
    address public vetoer;
    address public pendingVetoer;
    uint256 public constant MAX_PROPOSAL_NUMERATOR = 500; // max 5%
    uint256 public constant PROPOSAL_DENOMINATOR = 10_000;
    uint256 public proposalNumerator = 2; // start at 0.02%

    error NotTeam();
    error NotPendingVetoer();
    error NotVetoer();
    error ProposalNumeratorTooHigh();
    error ZeroAddress();

    constructor(
        IVotes _ve
    )
        VetoGovernor("Protocol Governor")
        VetoGovernorVotes(_ve)
        VetoGovernorVotesQuorumFraction(4) // 4%
    {
        ve = address(_ve);
        vetoer = msg.sender;
    }

    function votingDelay() public pure override(IVetoGovernor) returns (uint256) {
        return (15 minutes);
    }

    function votingPeriod() public pure override(IVetoGovernor) returns (uint256) {
        return (1 weeks);
    }

    function setProposalNumerator(uint256 numerator) external {
        if (msg.sender != IVotingEscrow(ve).team()) revert NotTeam();
        if (numerator > MAX_PROPOSAL_NUMERATOR) revert ProposalNumeratorTooHigh();
        proposalNumerator = numerator;
    }

    function proposalThreshold() public view override(VetoGovernor) returns (uint256) {
        return (token.getPastTotalSupply(block.timestamp - 1) * proposalNumerator) / PROPOSAL_DENOMINATOR;
    }

    /// @dev Vetoer can be removed once the risk of a 51% attack becomes unfeasible.
    ///      This can be done by transferring ownership of vetoer to a contract that is "bricked"
    ///      i.e. a non-zero address contract that is immutable with no ability to call this function.
    function setVetoer(address _vetoer) external {
        if (msg.sender != vetoer) revert NotVetoer();
        if (_vetoer == address(0)) revert ZeroAddress();
        pendingVetoer = _vetoer;
    }

    function acceptVetoer() external {
        if (msg.sender != pendingVetoer) revert NotPendingVetoer();
        vetoer = pendingVetoer;
        delete pendingVetoer;
    }

    /// @notice Support for vetoer to protect against 51% attacks
    function veto(uint256 _proposalId) external {
        if (msg.sender != vetoer) revert NotVetoer();
        _veto(_proposalId);
    }

    function renounceVetoer() external {
        if (msg.sender != vetoer) revert NotVetoer();
        delete vetoer;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {IVoter} from "../interfaces/IVoter.sol";
import {VotingReward} from "./VotingReward.sol";

/// @notice Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with Voter.vote())
contract BribeVotingReward is VotingReward {
    constructor(
        address _forwarder,
        address _voter,
        address[] memory _rewards
    ) VotingReward(_forwarder, _voter, _rewards) {}

    /// @inheritdoc VotingReward
    function notifyRewardAmount(address token, uint256 amount) external override nonReentrant {
        address sender = _msgSender();

        if (!isReward[token]) {
            if (!IVoter(voter).isWhitelistedToken(token)) revert NotWhitelisted();
            isReward[token] = true;
            rewards.push(token);
        }

        _notifyRewardAmount(sender, token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {VotingReward} from "./VotingReward.sol";
import {IVoter} from "../interfaces/IVoter.sol";

/// @notice Bribes pay out rewards for a given pool based on the votes that were received from the user (goes hand in hand with Voter.vote())
contract FeesVotingReward is VotingReward {
    constructor(
        address _forwarder,
        address _voter,
        address[] memory _rewards
    ) VotingReward(_forwarder, _voter, _rewards) {}

    /// @inheritdoc VotingReward
    function notifyRewardAmount(address token, uint256 amount) external override nonReentrant {
        address sender = _msgSender();
        if (IVoter(voter).gaugeToFees(sender) != address(this)) revert NotGauge();
        if (!isReward[token]) revert InvalidReward();

        _notifyRewardAmount(sender, token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ManagedReward} from "./ManagedReward.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IVoter} from "../interfaces/IVoter.sol";

/// @notice Stores rewards that are free to be distributed
/// @dev Rewards are distributed based on weight contribution to managed nft
contract FreeManagedReward is ManagedReward {
    constructor(address _forwarder, address _voter) ManagedReward(_forwarder, _voter) {}

    /// @inheritdoc ManagedReward
    function getReward(uint256 tokenId, address[] memory tokens) external override nonReentrant {
        if (!IVotingEscrow(ve).isApprovedOrOwner(_msgSender(), tokenId)) revert NotAuthorized();

        address owner = IVotingEscrow(ve).ownerOf(tokenId);

        _getReward(owner, tokenId, tokens);
    }

    /// @inheritdoc ManagedReward
    function notifyRewardAmount(address token, uint256 amount) external override nonReentrant {
        address sender = _msgSender();
        if (!isReward[token]) {
            if (!IVoter(voter).isWhitelistedToken(token)) revert NotWhitelisted();
            isReward[token] = true;
            rewards.push(token);
        }

        _notifyRewardAmount(sender, token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {ManagedReward} from "./ManagedReward.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";

/// @notice Stores rewards that are max-locked (i.e. rebases / tokens that were compounded)
/// @dev Rewards are distributed based on weight contribution to managed nft
contract LockedManagedReward is ManagedReward {
    constructor(address _forwarder, address _voter) ManagedReward(_forwarder, _voter) {}

    /// @inheritdoc ManagedReward
    /// @dev Called by VotingEscrow to retrieve locked rewards
    function getReward(uint256 tokenId, address[] memory tokens) external override nonReentrant {
        address sender = _msgSender();
        if (sender != ve) revert NotVotingEscrow();
        if (tokens.length != 1) revert NotSingleToken();
        if (tokens[0] != IVotingEscrow(ve).token()) revert NotEscrowToken();

        _getReward(sender, tokenId, tokens);
    }

    /// @inheritdoc ManagedReward
    /// @dev Called by VotingEscrow to add rebases / compounded rewards for disbursement
    function notifyRewardAmount(address token, uint256 amount) external override nonReentrant {
        address sender = _msgSender();
        if (sender != ve) revert NotVotingEscrow();
        if (token != IVotingEscrow(ve).token()) revert NotEscrowToken();

        _notifyRewardAmount(sender, token, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Reward} from "./Reward.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IVoter} from "../interfaces/IVoter.sol";

/// @title Base managed veNFT reward contract for distribution of rewards by token id
abstract contract ManagedReward is Reward {
    constructor(address _forwarder, address _voter) Reward(_forwarder, _voter) {
        address _ve = IVoter(_voter).ve();
        address _token = IVotingEscrow(_ve).token();
        rewards.push(_token);
        isReward[_token] = true;

        authorized = _ve;
    }

    /// @inheritdoc Reward
    function getReward(uint256 tokenId, address[] memory tokens) external virtual override {}

    /// @inheritdoc Reward
    function notifyRewardAmount(address token, uint256 amount) external virtual override {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IReward} from "../interfaces/IReward.sol";
import {IVoter} from "../interfaces/IVoter.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ProtocolTimeLibrary} from "../libraries/ProtocolTimeLibrary.sol";

/// @title Reward
/// @notice Base reward contract for distribution of rewards
abstract contract Reward is IReward, ERC2771Context, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @inheritdoc IReward
    uint256 public constant DURATION = 7 days;

    /// @inheritdoc IReward
    address public immutable voter;
    /// @inheritdoc IReward
    address public immutable ve;
    /// @inheritdoc IReward
    address public authorized;

    /// @inheritdoc IReward
    uint256 public totalSupply;
    /// @inheritdoc IReward
    mapping(uint256 => uint256) public balanceOf;
    /// @inheritdoc IReward
    mapping(address => mapping(uint256 => uint256)) public tokenRewardsPerEpoch;
    /// @inheritdoc IReward
    mapping(address => mapping(uint256 => uint256)) public lastEarn;

    address[] public rewards;
    /// @inheritdoc IReward
    mapping(address => bool) public isReward;

    /// @notice A record of balance checkpoints for each account, by index
    mapping(uint256 => mapping(uint256 => Checkpoint)) public checkpoints;
    /// @inheritdoc IReward
    mapping(uint256 => uint256) public numCheckpoints;
    /// @notice A record of balance checkpoints for each token, by index
    mapping(uint256 => SupplyCheckpoint) public supplyCheckpoints;
    /// @inheritdoc IReward
    uint256 public supplyNumCheckpoints;

    constructor(address _forwarder, address _voter) ERC2771Context(_forwarder) {
        voter = _voter;
        ve = IVoter(_voter).ve();
    }

    /// @inheritdoc IReward
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) public view returns (uint256) {
        uint256 nCheckpoints = numCheckpoints[tokenId];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[tokenId][nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (checkpoints[tokenId][0].timestamp > timestamp) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[tokenId][center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @inheritdoc IReward
    function getPriorSupplyIndex(uint256 timestamp) public view returns (uint256) {
        uint256 nCheckpoints = supplyNumCheckpoints;
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (supplyCheckpoints[nCheckpoints - 1].timestamp <= timestamp) {
            return (nCheckpoints - 1);
        }

        // Next check implicit zero balance
        if (supplyCheckpoints[0].timestamp > timestamp) {
            return 0;
        }

        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            SupplyCheckpoint memory cp = supplyCheckpoints[center];
            if (cp.timestamp == timestamp) {
                return center;
            } else if (cp.timestamp < timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    function _writeCheckpoint(uint256 tokenId, uint256 balance) internal {
        uint256 _nCheckPoints = numCheckpoints[tokenId];
        uint256 _timestamp = block.timestamp;

        if (
            _nCheckPoints > 0 &&
            ProtocolTimeLibrary.epochStart(checkpoints[tokenId][_nCheckPoints - 1].timestamp) ==
            ProtocolTimeLibrary.epochStart(_timestamp)
        ) {
            checkpoints[tokenId][_nCheckPoints - 1] = Checkpoint(_timestamp, balance);
        } else {
            checkpoints[tokenId][_nCheckPoints] = Checkpoint(_timestamp, balance);
            numCheckpoints[tokenId] = _nCheckPoints + 1;
        }
    }

    function _writeSupplyCheckpoint() internal {
        uint256 _nCheckPoints = supplyNumCheckpoints;
        uint256 _timestamp = block.timestamp;

        if (
            _nCheckPoints > 0 &&
            ProtocolTimeLibrary.epochStart(supplyCheckpoints[_nCheckPoints - 1].timestamp) ==
            ProtocolTimeLibrary.epochStart(_timestamp)
        ) {
            supplyCheckpoints[_nCheckPoints - 1] = SupplyCheckpoint(_timestamp, totalSupply);
        } else {
            supplyCheckpoints[_nCheckPoints] = SupplyCheckpoint(_timestamp, totalSupply);
            supplyNumCheckpoints = _nCheckPoints + 1;
        }
    }

    /// @inheritdoc IReward
    function rewardsListLength() external view returns (uint256) {
        return rewards.length;
    }

    /// @inheritdoc IReward
    function earned(address token, uint256 tokenId) public view returns (uint256) {
        if (numCheckpoints[tokenId] == 0) {
            return 0;
        }

        uint256 reward = 0;
        uint256 _supply = 1;
        uint256 _currTs = ProtocolTimeLibrary.epochStart(lastEarn[token][tokenId]); // take epoch last claimed in as starting point
        uint256 _index = getPriorBalanceIndex(tokenId, _currTs);
        Checkpoint memory cp0 = checkpoints[tokenId][_index];

        // accounts for case where lastEarn is before first checkpoint
        _currTs = Math.max(_currTs, ProtocolTimeLibrary.epochStart(cp0.timestamp));

        // get epochs between current epoch and first checkpoint in same epoch as last claim
        uint256 numEpochs = (ProtocolTimeLibrary.epochStart(block.timestamp) - _currTs) / DURATION;

        if (numEpochs > 0) {
            for (uint256 i = 0; i < numEpochs; i++) {
                // get index of last checkpoint in this epoch
                _index = getPriorBalanceIndex(tokenId, _currTs + DURATION - 1);
                // get checkpoint in this epoch
                cp0 = checkpoints[tokenId][_index];
                // get supply of last checkpoint in this epoch
                _supply = Math.max(supplyCheckpoints[getPriorSupplyIndex(_currTs + DURATION - 1)].supply, 1);
                reward += (cp0.balanceOf * tokenRewardsPerEpoch[token][_currTs]) / _supply;
                _currTs += DURATION;
            }
        }

        return reward;
    }

    /// @inheritdoc IReward
    function _deposit(uint256 amount, uint256 tokenId) external {
        address sender = _msgSender();
        if (sender != authorized) revert NotAuthorized();

        totalSupply += amount;
        balanceOf[tokenId] += amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Deposit(sender, tokenId, amount);
    }

    /// @inheritdoc IReward
    function _withdraw(uint256 amount, uint256 tokenId) external {
        address sender = _msgSender();
        if (sender != authorized) revert NotAuthorized();

        totalSupply -= amount;
        balanceOf[tokenId] -= amount;

        _writeCheckpoint(tokenId, balanceOf[tokenId]);
        _writeSupplyCheckpoint();

        emit Withdraw(sender, tokenId, amount);
    }

    /// @inheritdoc IReward
    function getReward(uint256 tokenId, address[] memory tokens) external virtual nonReentrant {}

    /// @dev used with all getReward implementations
    function _getReward(address recipient, uint256 tokenId, address[] memory tokens) internal {
        uint256 _length = tokens.length;
        for (uint256 i = 0; i < _length; i++) {
            uint256 _reward = earned(tokens[i], tokenId);
            lastEarn[tokens[i]][tokenId] = block.timestamp;
            if (_reward > 0) IERC20(tokens[i]).safeTransfer(recipient, _reward);

            emit ClaimRewards(recipient, tokens[i], _reward);
        }
    }

    /// @inheritdoc IReward
    function notifyRewardAmount(address token, uint256 amount) external virtual nonReentrant {}

    /// @dev used within all notifyRewardAmount implementations
    function _notifyRewardAmount(address sender, address token, uint256 amount) internal {
        if (amount == 0) revert ZeroAmount();
        IERC20(token).safeTransferFrom(sender, address(this), amount);

        uint256 epochStart = ProtocolTimeLibrary.epochStart(block.timestamp);
        tokenRewardsPerEpoch[token][epochStart] += amount;

        emit NotifyReward(sender, token, epochStart, amount);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Reward} from "./Reward.sol";
import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";

/// @title Base voting reward contract for distribution of rewards by token id
///        on a weekly basis
abstract contract VotingReward is Reward {
    constructor(address _forwarder, address _voter, address[] memory _rewards) Reward(_forwarder, _voter) {
        uint256 _length = _rewards.length;
        for (uint256 i; i < _length; i++) {
            if (_rewards[i] != address(0)) {
                isReward[_rewards[i]] = true;
                rewards.push(_rewards[i]);
            }
        }

        authorized = _voter;
    }

    /// @inheritdoc Reward
    function getReward(uint256 tokenId, address[] memory tokens) external override nonReentrant {
        address sender = _msgSender();
        if (!IVotingEscrow(ve).isApprovedOrOwner(sender, tokenId) && sender != voter) revert NotAuthorized();

        address _owner = IVotingEscrow(ve).ownerOf(tokenId);
        _getReward(_owner, tokenId, tokens);
    }

    /// @inheritdoc Reward
    function notifyRewardAmount(address token, uint256 amount) external virtual override {}
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IRewardsDistributor} from "./interfaces/IRewardsDistributor.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/*
 * @title Curve Fee Distribution modified for ve(3,3) emissions
 * @author Curve Finance, andrecronje
 * @license MIT
 */
contract RewardsDistributor is IRewardsDistributor {
    using SafeERC20 for IERC20;
    /// @inheritdoc IRewardsDistributor
    uint256 public constant WEEK = 7 * 86400;

    /// @inheritdoc IRewardsDistributor
    uint256 public startTime;
    /// @inheritdoc IRewardsDistributor
    mapping(uint256 => uint256) public timeCursorOf;

    /// @inheritdoc IRewardsDistributor
    uint256 public lastTokenTime;
    uint256[1000000000000000] public tokensPerWeek;

    /// @inheritdoc IRewardsDistributor
    IVotingEscrow public immutable ve;
    /// @inheritdoc IRewardsDistributor
    address public token;
    /// @inheritdoc IRewardsDistributor
    address public minter;
    /// @inheritdoc IRewardsDistributor
    uint256 public tokenLastBalance;

    constructor(address _ve) {
        uint256 _t = (block.timestamp / WEEK) * WEEK;
        startTime = _t;
        lastTokenTime = _t;
        ve = IVotingEscrow(_ve);
        address _token = ve.token();
        token = _token;
        minter = msg.sender;
        IERC20(_token).safeApprove(_ve, type(uint256).max);
    }

    function _checkpointToken() internal {
        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 thisWeek = (t / WEEK) * WEEK;
        uint256 nextWeek = 0;
        uint256 timestamp = block.timestamp;

        for (uint256 i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (timestamp < nextWeek) {
                if (sinceLast == 0 && timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (nextWeek - t)) / sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(timestamp, toDistribute);
    }

    /// @inheritdoc IRewardsDistributor
    function checkpointToken() external {
        if (msg.sender != minter) revert NotMinter();
        _checkpointToken();
    }

    function _claim(uint256 _tokenId, uint256 _lastTokenTime) internal returns (uint256) {
        (uint256 toDistribute, uint256 epochStart, uint256 weekCursor) = _claimable(_tokenId, _lastTokenTime);
        timeCursorOf[_tokenId] = weekCursor;
        if (toDistribute == 0) return 0;

        emit Claimed(_tokenId, epochStart, weekCursor, toDistribute);
        return toDistribute;
    }

    function _claimable(
        uint256 _tokenId,
        uint256 _lastTokenTime
    ) internal view returns (uint256 toDistribute, uint256 weekCursorStart, uint256 weekCursor) {
        uint256 _startTime = startTime;
        weekCursor = timeCursorOf[_tokenId];
        weekCursorStart = weekCursor;

        // case where token does not exist
        uint256 maxUserEpoch = ve.userPointEpoch(_tokenId);
        if (maxUserEpoch == 0) return (0, weekCursorStart, weekCursor);

        // case where token exists but has never been claimed
        if (weekCursor == 0) {
            IVotingEscrow.UserPoint memory userPoint = ve.userPointHistory(_tokenId, 1);
            weekCursor = (userPoint.ts / WEEK) * WEEK;
            weekCursorStart = weekCursor;
        }
        if (weekCursor >= _lastTokenTime) return (0, weekCursorStart, weekCursor);
        if (weekCursor < _startTime) weekCursor = _startTime;

        for (uint256 i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) break;

            uint256 balance = ve.balanceOfNFTAt(_tokenId, weekCursor + WEEK - 1);
            uint256 supply = ve.totalSupplyAt(weekCursor + WEEK - 1);
            supply = supply == 0 ? 1 : supply;
            toDistribute += (balance * tokensPerWeek[weekCursor]) / supply;
            weekCursor += WEEK;
        }
    }

    /// @inheritdoc IRewardsDistributor
    function claimable(uint256 _tokenId) external view returns (uint256 claimable_) {
        uint256 _lastTokenTime = (lastTokenTime / WEEK) * WEEK;
        (claimable_, , ) = _claimable(_tokenId, _lastTokenTime);
    }

    /// @inheritdoc IRewardsDistributor
    function claim(uint256 _tokenId) external returns (uint256) {
        if (IMinter(minter).activePeriod() < ((block.timestamp / WEEK) * WEEK)) revert UpdatePeriod();
        if (ve.escrowType(_tokenId) == IVotingEscrow.EscrowType.LOCKED) revert NotManagedOrNormalNFT();
        uint256 _timestamp = block.timestamp;
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        uint256 amount = _claim(_tokenId, _lastTokenTime);
        if (amount != 0) {
            IVotingEscrow.LockedBalance memory _locked = ve.locked(_tokenId);
            if (_timestamp >= _locked.end && !_locked.isPermanent) {
                address _owner = ve.ownerOf(_tokenId);
                IERC20(token).safeTransfer(_owner, amount);
            } else {
                ve.depositFor(_tokenId, amount);
            }
            tokenLastBalance -= amount;
        }
        return amount;
    }

    /// @inheritdoc IRewardsDistributor
    function claimMany(uint256[] calldata _tokenIds) external returns (bool) {
        if (IMinter(minter).activePeriod() < ((block.timestamp / WEEK) * WEEK)) revert UpdatePeriod();
        uint256 _timestamp = block.timestamp;
        uint256 _lastTokenTime = lastTokenTime;
        _lastTokenTime = (_lastTokenTime / WEEK) * WEEK;
        uint256 total = 0;
        uint256 _length = _tokenIds.length;

        for (uint256 i = 0; i < _length; i++) {
            uint256 _tokenId = _tokenIds[i];
            if (ve.escrowType(_tokenId) == IVotingEscrow.EscrowType.LOCKED) revert NotManagedOrNormalNFT();
            if (_tokenId == 0) break;
            uint256 amount = _claim(_tokenId, _lastTokenTime);
            if (amount != 0) {
                IVotingEscrow.LockedBalance memory _locked = ve.locked(_tokenId);
                if (_timestamp >= _locked.end && !_locked.isPermanent) {
                    address _owner = ve.ownerOf(_tokenId);
                    IERC20(token).safeTransfer(_owner, amount);
                } else {
                    ve.depositFor(_tokenId, amount);
                }
                total += amount;
            }
        }
        if (total != 0) {
            tokenLastBalance -= total;
        }

        return true;
    }

    /// @inheritdoc IRewardsDistributor
    function setMinter(address _minter) external {
        if (msg.sender != minter) revert NotMinter();
        minter = _minter;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IPoolFactory} from "./interfaces/factories/IPoolFactory.sol";
import {IRouter} from "./interfaces/IRouter.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IGauge} from "./interfaces/IGauge.sol";
import {IFactoryRegistry} from "./interfaces/factories/IFactoryRegistry.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";

/// @title Protocol Router
/// @notice Router allows routes through any pools created by any factory adhering to univ2 interface.
contract Router is IRouter, ERC2771Context {
    using SafeERC20 for IERC20;

    /// @inheritdoc IRouter
    address public immutable factoryRegistry;
    /// @inheritdoc IRouter
    address public immutable defaultFactory;
    /// @inheritdoc IRouter
    address public immutable voter;
    /// @inheritdoc IRouter
    IWETH public immutable weth;
    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    /// @inheritdoc IRouter
    address public constant ETHER = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    modifier ensure(uint256 deadline) {
        _ensureDeadline(deadline);
        _;
    }

    function _ensureDeadline(uint256 deadline) internal view {
        if (deadline < block.timestamp) revert Expired();
    }

    constructor(
        address _forwarder,
        address _factoryRegistry,
        address _factory,
        address _voter,
        address _weth
    ) ERC2771Context(_forwarder) {
        factoryRegistry = _factoryRegistry;
        defaultFactory = _factory;
        voter = _voter;
        weth = IWETH(_weth);
    }

    receive() external payable {
        if (msg.sender != address(weth)) revert OnlyWETH();
    }

    /// @inheritdoc IRouter
    function sortTokens(address tokenA, address tokenB) public pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert SameAddresses();
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress();
    }

    /// @inheritdoc IRouter
    function poolFor(address tokenA, address tokenB, bool stable, address _factory) public view returns (address pool) {
        address _defaultFactory = defaultFactory;
        address factory = _factory == address(0) ? _defaultFactory : _factory;
        if (!IFactoryRegistry(factoryRegistry).isPoolFactoryApproved(factory)) revert PoolFactoryDoesNotExist();

        (address token0, address token1) = sortTokens(tokenA, tokenB);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable));
        pool = Clones.predictDeterministicAddress(IPoolFactory(factory).implementation(), salt, factory);
    }

    /// @dev given some amount of an asset and pool reserves, returns an equivalent amount of the other asset
    /// @dev this only accounts for volatile pools and may return insufficient liquidity for stable pools
    function quoteLiquidity(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        if (amountA == 0) revert InsufficientAmount();
        if (reserveA == 0 || reserveB == 0) revert InsufficientLiquidity();
        amountB = (amountA * reserveB) / reserveA;
    }

    /// @inheritdoc IRouter
    function getReserves(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory
    ) public view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPool(poolFor(tokenA, tokenB, stable, _factory)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @inheritdoc IRouter
    function getAmountsOut(uint256 amountIn, Route[] memory routes) public view returns (uint256[] memory amounts) {
        if (routes.length < 1) revert InvalidPath();
        amounts = new uint256[](routes.length + 1);
        amounts[0] = amountIn;
        uint256 _length = routes.length;
        for (uint256 i = 0; i < _length; i++) {
            address factory = routes[i].factory == address(0) ? defaultFactory : routes[i].factory; // default to v2
            address pool = poolFor(routes[i].from, routes[i].to, routes[i].stable, factory);
            if (IPoolFactory(factory).isPool(pool)) {
                amounts[i + 1] = IPool(pool).getAmountOut(amounts[i], routes[i].from);
            }
        }
    }

    /// @inheritdoc IRouter
    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountADesired,
        uint256 amountBDesired
    ) public view returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        address _pool = IPoolFactory(_factory).getPool(tokenA, tokenB, stable);
        (uint256 reserveA, uint256 reserveB) = (0, 0);
        uint256 _totalSupply = 0;
        if (_pool != address(0)) {
            _totalSupply = IERC20(_pool).totalSupply();
            (reserveA, reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        }
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
            liquidity = Math.sqrt(amountA * amountB) - MINIMUM_LIQUIDITY;
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
                liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
                liquidity = Math.min((amountA * _totalSupply) / reserveA, (amountB * _totalSupply) / reserveB);
            }
        }
    }

    /// @inheritdoc IRouter
    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity
    ) public view returns (uint256 amountA, uint256 amountB) {
        address _pool = IPoolFactory(_factory).getPool(tokenA, tokenB, stable);

        if (_pool == address(0)) {
            return (0, 0);
        }

        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        uint256 _totalSupply = IERC20(_pool).totalSupply();

        amountA = (liquidity * reserveA) / _totalSupply; // using balances ensures pro-rata distribution
        amountB = (liquidity * reserveB) / _totalSupply; // using balances ensures pro-rata distribution
    }

    function _addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal returns (uint256 amountA, uint256 amountB) {
        if (amountADesired < amountAMin) revert InsufficientAmountADesired();
        if (amountBDesired < amountBMin) revert InsufficientAmountBDesired();
        // create the pool if it doesn't exist yet
        address _pool = IPoolFactory(defaultFactory).getPool(tokenA, tokenB, stable);
        if (_pool == address(0)) {
            _pool = IPoolFactory(defaultFactory).createPool(tokenA, tokenB, stable);
        }
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, stable, defaultFactory);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientAmountB();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert InsufficientAmountA();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @inheritdoc IRouter
    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        (amountA, amountB) = _addLiquidity(
            tokenA,
            tokenB,
            stable,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin
        );
        address pool = poolFor(tokenA, tokenB, stable, defaultFactory);
        _safeTransferFrom(tokenA, _msgSender(), pool, amountA);
        _safeTransferFrom(tokenB, _msgSender(), pool, amountB);
        liquidity = IPool(pool).mint(to);
    }

    /// @inheritdoc IRouter
    function addLiquidityETH(
        address token,
        bool stable,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        (amountToken, amountETH) = _addLiquidity(
            token,
            address(weth),
            stable,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );
        address pool = poolFor(token, address(weth), stable, defaultFactory);
        _safeTransferFrom(token, _msgSender(), pool, amountToken);
        weth.deposit{value: amountETH}();
        assert(weth.transfer(pool, amountETH));
        liquidity = IPool(pool).mint(to);
        // refund dust eth, if any
        if (msg.value > amountETH) _safeTransferETH(_msgSender(), msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****

    /// @inheritdoc IRouter
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountA, uint256 amountB) {
        address pool = poolFor(tokenA, tokenB, stable, defaultFactory);
        IERC20(pool).safeTransferFrom(_msgSender(), pool, liquidity);
        (uint256 amount0, uint256 amount1) = IPool(pool).burn(to);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < amountAMin) revert InsufficientAmountA();
        if (amountB < amountBMin) revert InsufficientAmountB();
    }

    /// @inheritdoc IRouter
    function removeLiquidityETH(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountToken, uint256 amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(weth),
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, amountToken);
        weth.withdraw(amountETH);
        _safeTransferETH(to, amountETH);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        bool stable,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) public ensure(deadline) returns (uint256 amountETH) {
        (, amountETH) = removeLiquidity(
            token,
            address(weth),
            stable,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );
        _safeTransfer(token, to, IERC20(token).balanceOf(address(this)));
        weth.withdraw(amountETH);
        _safeTransferETH(to, amountETH);
    }

    // **** SWAP ****
    /// @dev requires the initial amount to have already been sent to the first pool
    function _swap(uint256[] memory amounts, Route[] memory routes, address _to) internal virtual {
        uint256 _length = routes.length;
        for (uint256 i = 0; i < _length; i++) {
            (address token0, ) = sortTokens(routes[i].from, routes[i].to);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = routes[i].from == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < routes.length - 1
                ? poolFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable, routes[i + 1].factory)
                : _to;
            IPool(poolFor(routes[i].from, routes[i].to, routes[i].stable, routes[i].factory)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        amounts = getAmountsOut(amountIn, routes);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        _safeTransferFrom(
            routes[0].from,
            _msgSender(),
            poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory),
            amounts[0]
        );
        _swap(amounts, routes, to);
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) returns (uint256[] memory amounts) {
        if (routes[0].from != address(weth)) revert InvalidPath();
        amounts = getAmountsOut(msg.value, routes);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        weth.deposit{value: amounts[0]}();
        assert(weth.transfer(poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amounts[0]));
        _swap(amounts, routes, to);
    }

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory amounts) {
        if (routes[routes.length - 1].to != address(weth)) revert InvalidPath();
        amounts = getAmountsOut(amountIn, routes);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        _safeTransferFrom(
            routes[0].from,
            _msgSender(),
            poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory),
            amounts[0]
        );
        _swap(amounts, routes, address(this));
        weth.withdraw(amounts[amounts.length - 1]);
        _safeTransferETH(to, amounts[amounts.length - 1]);
    }

    function UNSAFE_swapExactTokensForTokens(
        uint256[] memory amounts,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) returns (uint256[] memory) {
        _safeTransferFrom(
            routes[0].from,
            _msgSender(),
            poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory),
            amounts[0]
        );
        _swap(amounts, routes, to);
        return amounts;
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    /// @dev requires the initial amount to have already been sent to the first pool
    function _swapSupportingFeeOnTransferTokens(Route[] memory routes, address _to) internal virtual {
        uint256 _length = routes.length;
        for (uint256 i; i < _length; i++) {
            (address token0, ) = sortTokens(routes[i].from, routes[i].to);
            address pool = poolFor(routes[i].from, routes[i].to, routes[i].stable, routes[i].factory);
            uint256 amountInput;
            uint256 amountOutput;
            {
                // stack too deep
                (uint256 reserveA, ) = getReserves(routes[i].from, routes[i].to, routes[i].stable, routes[i].factory); // getReserves sorts it for us i.e. reserveA is always for from
                amountInput = IERC20(routes[i].from).balanceOf(pool) - reserveA;
            }
            amountOutput = IPool(pool).getAmountOut(amountInput, routes[i].from);
            (uint256 amount0Out, uint256 amount1Out) = routes[i].from == token0
                ? (uint256(0), amountOutput)
                : (amountOutput, uint256(0));
            address to = i < routes.length - 1
                ? poolFor(routes[i + 1].from, routes[i + 1].to, routes[i + 1].stable, routes[i + 1].factory)
                : _to;
            IPool(pool).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /// @inheritdoc IRouter
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        _safeTransferFrom(
            routes[0].from,
            _msgSender(),
            poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory),
            amountIn
        );
        uint256 _length = routes.length - 1;
        uint256 balanceBefore = IERC20(routes[_length].to).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(routes, to);
        if (IERC20(routes[_length].to).balanceOf(to) - balanceBefore < amountOutMin) revert InsufficientOutputAmount();
    }

    /// @inheritdoc IRouter
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external payable ensure(deadline) {
        if (routes[0].from != address(weth)) revert InvalidPath();
        uint256 amountIn = msg.value;
        weth.deposit{value: amountIn}();
        assert(weth.transfer(poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory), amountIn));
        uint256 _length = routes.length - 1;
        uint256 balanceBefore = IERC20(routes[_length].to).balanceOf(to);
        _swapSupportingFeeOnTransferTokens(routes, to);
        if (IERC20(routes[_length].to).balanceOf(to) - balanceBefore < amountOutMin) revert InsufficientOutputAmount();
    }

    /// @inheritdoc IRouter
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        Route[] calldata routes,
        address to,
        uint256 deadline
    ) external ensure(deadline) {
        if (routes[routes.length - 1].to != address(weth)) revert InvalidPath();
        _safeTransferFrom(
            routes[0].from,
            _msgSender(),
            poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory),
            amountIn
        );
        _swapSupportingFeeOnTransferTokens(routes, address(this));
        uint256 amountOut = weth.balanceOf(address(this));
        if (amountOut < amountOutMin) revert InsufficientOutputAmount();
        weth.withdraw(amountOut);
        _safeTransferETH(to, amountOut);
    }

    /// @inheritdoc IRouter
    function zapIn(
        address tokenIn,
        uint256 amountInA,
        uint256 amountInB,
        Zap calldata zapInPool,
        Route[] calldata routesA,
        Route[] calldata routesB,
        address to,
        bool stake
    ) external payable returns (uint256 liquidity) {
        uint256 amountIn = amountInA + amountInB;
        address _tokenIn = tokenIn;
        uint256 value = msg.value;
        if (tokenIn == ETHER) {
            if (amountIn != value) revert InvalidAmountInForETHDeposit();
            _tokenIn = address(weth);
            weth.deposit{value: value}();
        } else {
            if (value != 0) revert InvalidTokenInForETHDeposit();
            _safeTransferFrom(_tokenIn, _msgSender(), address(this), amountIn);
        }

        _zapSwap(_tokenIn, amountInA, amountInB, zapInPool, routesA, routesB);
        _zapInLiquidity(zapInPool);
        address pool = poolFor(zapInPool.tokenA, zapInPool.tokenB, zapInPool.stable, zapInPool.factory);

        if (stake) {
            liquidity = IPool(pool).mint(address(this));
            address gauge = IVoter(voter).gauges(pool);
            IERC20(pool).safeApprove(address(gauge), liquidity);
            IGauge(gauge).deposit(liquidity, to);
            IERC20(pool).safeApprove(address(gauge), 0);
        } else {
            liquidity = IPool(pool).mint(to);
        }

        _returnAssets(tokenIn);
        _returnAssets(zapInPool.tokenA);
        _returnAssets(zapInPool.tokenB);
    }

    /// @dev Handles swap leg of zap in (i.e. convert tokenIn into tokenA and tokenB).
    function _zapSwap(
        address tokenIn,
        uint256 amountInA,
        uint256 amountInB,
        Zap calldata zapInPool,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) internal {
        address tokenA = zapInPool.tokenA;
        address tokenB = zapInPool.tokenB;
        bool stable = zapInPool.stable;
        address factory = zapInPool.factory;
        address pool = poolFor(tokenA, tokenB, stable, factory);

        {
            (uint256 reserve0, uint256 reserve1, ) = IPool(pool).getReserves();
            if (reserve0 <= MINIMUM_LIQUIDITY || reserve1 <= MINIMUM_LIQUIDITY) revert PoolDoesNotExist();
        }

        if (tokenIn != tokenA) {
            if (routesA[routesA.length - 1].to != tokenA) revert InvalidRouteA();
            _internalSwap(tokenIn, amountInA, zapInPool.amountOutMinA, routesA);
        }
        if (tokenIn != tokenB) {
            if (routesB[routesB.length - 1].to != tokenB) revert InvalidRouteB();
            _internalSwap(tokenIn, amountInB, zapInPool.amountOutMinB, routesB);
        }
    }

    /// @dev Handles liquidity adding component of zap in.
    function _zapInLiquidity(Zap calldata zapInPool) internal {
        address tokenA = zapInPool.tokenA;
        address tokenB = zapInPool.tokenB;
        bool stable = zapInPool.stable;
        address factory = zapInPool.factory;
        address pool = poolFor(tokenA, tokenB, stable, factory);
        (uint256 amountA, uint256 amountB) = _quoteZapLiquidity(
            tokenA,
            tokenB,
            stable,
            factory,
            IERC20(tokenA).balanceOf(address(this)),
            IERC20(tokenB).balanceOf(address(this)),
            zapInPool.amountAMin,
            zapInPool.amountBMin
        );
        _safeTransfer(tokenA, pool, amountA);
        _safeTransfer(tokenB, pool, amountB);
    }

    /// @dev Similar to _addLiquidity. Assumes a pool exists, and accepts a factory argument.
    function _quoteZapLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) internal view returns (uint256 amountA, uint256 amountB) {
        if (amountADesired < amountAMin) revert InsufficientAmountADesired();
        if (amountBDesired < amountBMin) revert InsufficientAmountBDesired();
        (uint256 reserveA, uint256 reserveB) = getReserves(tokenA, tokenB, stable, _factory);
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = quoteLiquidity(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                if (amountBOptimal < amountBMin) revert InsufficientAmountB();
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = quoteLiquidity(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                if (amountAOptimal < amountAMin) revert InsufficientAmountA();
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /// @dev Handles swaps internally for zaps.
    function _internalSwap(address tokenIn, uint256 amountIn, uint256 amountOutMin, Route[] memory routes) internal {
        uint256[] memory amounts = getAmountsOut(amountIn, routes);
        if (amounts[amounts.length - 1] < amountOutMin) revert InsufficientOutputAmount();
        address pool = poolFor(routes[0].from, routes[0].to, routes[0].stable, routes[0].factory);
        _safeTransfer(tokenIn, pool, amountIn);
        _swap(amounts, routes, address(this));
    }

    /// @inheritdoc IRouter
    function zapOut(
        address tokenOut,
        uint256 liquidity,
        Zap calldata zapOutPool,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external {
        address tokenA = zapOutPool.tokenA;
        address tokenB = zapOutPool.tokenB;
        address _tokenOut = (tokenOut == ETHER) ? address(weth) : tokenOut;
        _zapOutLiquidity(liquidity, zapOutPool);

        uint256 balance;
        if (tokenA != _tokenOut) {
            balance = IERC20(tokenA).balanceOf(address(this));
            if (routesA[routesA.length - 1].to != _tokenOut) revert InvalidRouteA();
            _internalSwap(tokenA, balance, zapOutPool.amountOutMinA, routesA);
        }
        if (tokenB != _tokenOut) {
            balance = IERC20(tokenB).balanceOf(address(this));
            if (routesB[routesB.length - 1].to != _tokenOut) revert InvalidRouteB();
            _internalSwap(tokenB, balance, zapOutPool.amountOutMinB, routesB);
        }

        _returnAssets(tokenOut);
    }

    /// @dev Handles liquidity removing component of zap out.
    function _zapOutLiquidity(uint256 liquidity, Zap calldata zapOutPool) internal {
        address tokenA = zapOutPool.tokenA;
        address tokenB = zapOutPool.tokenB;
        address pool = poolFor(tokenA, tokenB, zapOutPool.stable, zapOutPool.factory);
        IERC20(pool).safeTransferFrom(msg.sender, pool, liquidity);
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 amount0, uint256 amount1) = IPool(pool).burn(address(this));
        (uint256 amountA, uint256 amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        if (amountA < zapOutPool.amountAMin) revert InsufficientAmountA();
        if (amountB < zapOutPool.amountBMin) revert InsufficientAmountB();
    }

    /// @inheritdoc IRouter
    function generateZapInParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 amountInA,
        uint256 amountInB,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin) {
        amountOutMinA = amountInA;
        amountOutMinB = amountInB;
        uint256[] memory amounts;
        if (routesA.length > 0) {
            amounts = getAmountsOut(amountInA, routesA);
            amountOutMinA = amounts[amounts.length - 1];
        }
        if (routesB.length > 0) {
            amounts = getAmountsOut(amountInB, routesB);
            amountOutMinB = amounts[amounts.length - 1];
        }
        (amountAMin, amountBMin, ) = quoteAddLiquidity(tokenA, tokenB, stable, _factory, amountOutMinA, amountOutMinB);
    }

    /// @inheritdoc IRouter
    function generateZapOutParams(
        address tokenA,
        address tokenB,
        bool stable,
        address _factory,
        uint256 liquidity,
        Route[] calldata routesA,
        Route[] calldata routesB
    ) external view returns (uint256 amountOutMinA, uint256 amountOutMinB, uint256 amountAMin, uint256 amountBMin) {
        (amountAMin, amountBMin) = quoteRemoveLiquidity(tokenA, tokenB, stable, _factory, liquidity);
        amountOutMinA = amountAMin;
        amountOutMinB = amountBMin;
        uint256[] memory amounts;
        if (routesA.length > 0) {
            amounts = getAmountsOut(amountAMin, routesA);
            amountOutMinA = amounts[amounts.length - 1];
        }
        if (routesB.length > 0) {
            amounts = getAmountsOut(amountBMin, routesB);
            amountOutMinB = amounts[amounts.length - 1];
        }
    }

    /// @dev Return residual assets from zapping.
    /// @param token token to return, put `ETHER` if you want Ether back.
    function _returnAssets(address token) internal {
        address sender = _msgSender();
        uint256 balance;
        if (token == ETHER) {
            balance = IERC20(weth).balanceOf(address(this));
            if (balance > 0) {
                IWETH(weth).withdraw(balance);
                _safeTransferETH(sender, balance);
            }
        } else {
            balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).safeTransfer(sender, balance);
            }
        }
    }

    /// @inheritdoc IRouter
    function quoteStableLiquidityRatio(
        address tokenA,
        address tokenB,
        address _factory
    ) external view returns (uint256 ratio) {
        IPool pool = IPool(poolFor(tokenA, tokenB, true, _factory));

        uint256 decimalsA = 10 ** IERC20Metadata(tokenA).decimals();
        uint256 decimalsB = 10 ** IERC20Metadata(tokenB).decimals();

        uint256 investment = decimalsA;
        uint256 out = pool.getAmountOut(investment, tokenA);
        (uint256 amountA, uint256 amountB, ) = quoteAddLiquidity(tokenA, tokenB, true, _factory, investment, out);

        amountA = (amountA * 1e18) / decimalsA;
        amountB = (amountB * 1e18) / decimalsB;
        out = (out * 1e18) / decimalsB;
        investment = (investment * 1e18) / decimalsA;

        ratio = (((out * 1e18) / investment) * amountA) / amountB;

        return (investment * 1e18) / (ratio + 1e18);
    }

    function _safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        if (!success) revert ETHTransferFailed();
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function _safeTransferFrom(address token, address from, address to, uint256 value) internal {
        require(token.code.length > 0);
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;


// Library by https://github.com/0x10f/solidity-perlin-noise

/**
 * @notice An implementation of Perlin Noise that uses 16 bit fixed point arithmetic.
 * @notice Updated solidity version from 0.5.0 to 0.8.12.
 */

library PerlinNoise {

    /**
     * @notice Computes the noise value for a 2D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise2d(int256 x, int256 y) public pure returns (int256) {
        int256 temp = ptable(x >> 16 & 0xff /* Unit square X */);

        int256 a = ptable((temp >> 8  ) + (y >> 16 & 0xff /* Unit square Y */));
        int256 b = ptable((temp & 0xff) + (y >> 16 & 0xff                    ));

        x &= 0xffff; // Square relative X
        y &= 0xffff; // Square relative Y

        int256 u = fade(x);

        int256 c = lerp(u, grad2(a >> 8  , x, y        ), grad2(b >> 8  , x-0x10000, y        ));
        int256 d = lerp(u, grad2(a & 0xff, x, y-0x10000), grad2(b & 0xff, x-0x10000, y-0x10000));

        return lerp(fade(y), c, d);
    }

    /**
     * @notice Computes the noise value for a 3D point.
     *
     * @param x the x coordinate.
     * @param y the y coordinate.
     * @param z the z coordinate.
     *
     * @dev This function should be kept public. Inlining the bytecode for this function
     *      into other functions could explode its compiled size because of how `ftable`
     *      and `ptable` were written.
     */
    function noise3d(int256 x, int256 y, int256 z) public pure returns (int256) {
        int256[7] memory scratch = [
            x >> 16 & 0xff,  // Unit cube X
            y >> 16 & 0xff,  // Unit cube Y
            z >> 16 & 0xff,  // Unit cube Z
            0, 0, 0, 0
        ];

        x &= 0xffff; // Cube relative X
        y &= 0xffff; // Cube relative Y
        z &= 0xffff; // Cube relative Z

        // Temporary variables used for intermediate calculations.
        int256 u;
        int256 v;

        v = ptable(scratch[0]);

        u = ptable((v >> 8  ) + scratch[1]);
        v = ptable((v & 0xff) + scratch[1]);

        scratch[3] = ptable((u >> 8  ) + scratch[2]);
        scratch[4] = ptable((u & 0xff) + scratch[2]);
        scratch[5] = ptable((v >> 8  ) + scratch[2]);
        scratch[6] = ptable((v & 0xff) + scratch[2]);

        int256 a;
        int256 b;
        int256 c;

        u = fade(x);
        v = fade(y);

        a = lerp(u, grad3(scratch[3] >> 8, x, y        , z), grad3(scratch[5] >> 8, x-0x10000, y        , z));
        b = lerp(u, grad3(scratch[4] >> 8, x, y-0x10000, z), grad3(scratch[6] >> 8, x-0x10000, y-0x10000, z));
        c = lerp(v, a, b);

        a = lerp(u, grad3(scratch[3] & 0xff, x, y        , z-0x10000), grad3(scratch[5] & 0xff, x-0x10000, y        , z-0x10000));
        b = lerp(u, grad3(scratch[4] & 0xff, x, y-0x10000, z-0x10000), grad3(scratch[6] & 0xff, x-0x10000, y-0x10000, z-0x10000));

        return lerp(fade(z), c, lerp(v, a, b));
    }

    /**
     * @notice Computes the linear interpolation between two values, `a` and `b`, using fixed point arithmetic.
     *
     * @param t the time value of the equation.
     * @param a the lower point.
     * @param b the upper point.
     */
    function lerp(int256 t, int256 a, int256 b) internal pure returns (int256) {
        return a + (t * (b - a) >> 12);
    }

    /**
     * @notice Applies the fade function to a value.
     *
     * @param t the time value of the equation.
     *
     * @dev The polynomial for this function is: 6t^4-15t^4+10t^3.
     */
    function fade(int256 t) internal pure returns (int256) {
        int256 n = ftable(t >> 8);

        // Lerp between the two points grabbed from the fade table.
        (int256 lower, int256 upper) = (n >> 12, n & 0xfff);
        return lower + ((t & 0xff) * (upper - lower) >> 8);
    }

    /**
      * @notice Computes the gradient value for a 2D point.
      *
      * @param h the hash value to use for picking the vector.
      * @param x the x coordinate of the point.
      * @param y the y coordinate of the point.
      */
    function grad2(int256 h, int256 x, int256 y) internal pure returns (int256) {
        h &= 3;

        int256 u;
        if (h & 0x1 == 0) {
            u = x;
        } else {
            u = -x;
        }

        int256 v;
        if (h < 2) {
            v = y;
        } else {
            v = -y;
        }

        return u + v;
    }

    /**
     * @notice Computes the gradient value for a 3D point.
     *
     * @param h the hash value to use for picking the vector.
     * @param x the x coordinate of the point.
     * @param y the y coordinate of the point.
     * @param z the z coordinate of the point.
     */
    function grad3(int256 h, int256 x, int256 y, int256 z) internal pure returns (int256) {
        h &= 0xf;

        int256 u;
        if (h < 8) {
            u = x;
        } else {
            u = y;
        }

        int256 v;
        if (h < 4) {
            v = y;
        } else if (h == 12 || h == 14) {
            v = x;
        } else {
            v = z;
        }

        if ((h & 0x1) != 0) {
            u = -u;
        }

        if ((h & 0x2) != 0) {
            v = -v;
        }

        return u + v;
    }

    /**
     * @notice Gets a subsequent values in the permutation table at an index. The values are encoded
     *         into a single 24 bit integer with the  value at the specified index being the most
     *         significant 12 bits and the subsequent value being the least significant 12 bits.
     *
     * @param i the index in the permutation table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(255).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ptable' script.
     */
    function ptable(int256 i) internal pure returns (int256) {
        i &= 0xff;

        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 38816; } else { return 41097; }
                                } else {
                                    if (i == 2) { return 35163; } else { return 23386; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 23055; } else { return 3971; }
                                } else {
                                    if (i == 6) { return 33549; } else { return 3529; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 51551; } else { return 24416; }
                                } else {
                                    if (i == 10) { return 24629; } else { return 13762; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 49897; } else { return 59655; }
                                } else {
                                    if (i == 14) { return 2017; } else { return 57740; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 35876; } else { return 9319; }
                                } else {
                                    if (i == 18) { return 26398; } else { return 7749; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 17806; } else { return 36360; }
                                } else {
                                    if (i == 22) { return 2147; } else { return 25381; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 9712; } else { return 61461; }
                                } else {
                                    if (i == 26) { return 5386; } else { return 2583; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 6078; } else { return 48646; }
                                } else {
                                    if (i == 30) { return 1684; } else { return 38135; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 63352; } else { return 30954; }
                                } else {
                                    if (i == 34) { return 59979; } else { return 19200; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 26; } else { return 6853; }
                                } else {
                                    if (i == 38) { return 50494; } else { return 15966; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 24316; } else { return 64731; }
                                } else {
                                    if (i == 42) { return 56267; } else { return 52085; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 29987; } else { return 8971; }
                                } else {
                                    if (i == 46) { return 2848; } else { return 8249; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 14769; } else { return 45345; }
                                } else {
                                    if (i == 50) { return 8536; } else { return 22765; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 60821; } else { return 38200; }
                                } else {
                                    if (i == 54) { return 14423; } else { return 22446; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 44564; } else { return 5245; }
                                } else {
                                    if (i == 58) { return 32136; } else { return 34987; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 43944; } else { return 43076; }
                                } else {
                                    if (i == 62) { return 17583; } else { return 44874; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 19109; } else { return 42311; }
                                } else {
                                    if (i == 66) { return 18310; } else { return 34443; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 35632; } else { return 12315; }
                                } else {
                                    if (i == 70) { return 7078; } else { return 42573; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 19858; } else { return 37534; }
                                } else {
                                    if (i == 74) { return 40679; } else { return 59219; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 21359; } else { return 28645; }
                                } else {
                                    if (i == 78) { return 58746; } else { return 31292; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 15571; } else { return 54149; }
                                } else {
                                    if (i == 82) { return 34278; } else { return 59100; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 56425; } else { return 26972; }
                                } else {
                                    if (i == 86) { return 23593; } else { return 10551; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 14126; } else { return 12021; }
                                } else {
                                    if (i == 90) { return 62760; } else { return 10484; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 62566; } else { return 26255; }
                                } else {
                                    if (i == 94) { return 36662; } else { return 13889; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 16665; } else { return 6463; }
                                } else {
                                    if (i == 98) { return 16289; } else { return 41217; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 472; } else { return 55376; }
                                } else {
                                    if (i == 102) { return 20553; } else { return 18897; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 53580; } else { return 19588; }
                                } else {
                                    if (i == 106) { return 33979; } else { return 48080; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 53337; } else { return 22802; }
                                } else {
                                    if (i == 110) { return 4777; } else { return 43464; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 51396; } else { return 50311; }
                                } else {
                                    if (i == 114) { return 34690; } else { return 33396; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 29884; } else { return 48287; }
                                } else {
                                    if (i == 118) { return 40790; } else { return 22180; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 42084; } else { return 25709; }
                                } else {
                                    if (i == 122) { return 28102; } else { return 50861; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 44474; } else { return 47619; }
                                } else {
                                    if (i == 126) { return 832; } else { return 16436; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 13529; } else { return 55778; }
                                } else {
                                    if (i == 130) { return 58106; } else { return 64124; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 31867; } else { return 31493; }
                                } else {
                                    if (i == 134) { return 1482; } else { return 51750; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9875; } else { return 37750; }
                                } else {
                                    if (i == 138) { return 30334; } else { return 32511; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 65362; } else { return 21077; }
                                } else {
                                    if (i == 142) { return 21972; } else { return 54479; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 53198; } else { return 52795; }
                                } else {
                                    if (i == 146) { return 15331; } else { return 58159; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 12048; } else { return 4154; }
                                } else {
                                    if (i == 150) { return 14865; } else { return 4534; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 46781; } else { return 48412; }
                                } else {
                                    if (i == 154) { return 7210; } else { return 10975; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 57271; } else { return 47018; }
                                } else {
                                    if (i == 158) { return 43733; } else { return 54647; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 30712; } else { return 63640; }
                                } else {
                                    if (i == 162) { return 38914; } else { return 556; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 11418; } else { return 39587; }
                                } else {
                                    if (i == 166) { return 41798; } else { return 18141; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 56729; } else { return 39269; }
                                } else {
                                    if (i == 170) { return 26011; } else { return 39847; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 42795; } else { return 11180; }
                                } else {
                                    if (i == 174) { return 44041; } else { return 2433; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 33046; } else { return 5671; }
                                } else {
                                    if (i == 178) { return 10237; } else { return 64787; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 4962; } else { return 25196; }
                                } else {
                                    if (i == 182) { return 27758; } else { return 28239; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 20337; } else { return 29152; }
                                } else {
                                    if (i == 186) { return 57576; } else { return 59570; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 45753; } else { return 47472; }
                                } else {
                                    if (i == 190) { return 28776; } else { return 26842; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 56054; } else { return 63073; }
                                } else {
                                    if (i == 194) { return 25060; } else { return 58619; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 64290; } else { return 8946; }
                                } else {
                                    if (i == 198) { return 62145; } else { return 49646; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 61138; } else { return 53904; }
                                } else {
                                    if (i == 202) { return 36876; } else { return 3263; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 49075; } else { return 45986; }
                                } else {
                                    if (i == 206) { return 41713; } else { return 61777; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 20787; } else { return 13201; }
                                } else {
                                    if (i == 210) { return 37355; } else { return 60409; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 63758; } else { return 3823; }
                                } else {
                                    if (i == 214) { return 61291; } else { return 27441; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 12736; } else { return 49366; }
                                } else {
                                    if (i == 218) { return 54815; } else { return 8117; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 46535; } else { return 51050; }
                                } else {
                                    if (i == 222) { return 27293; } else { return 40376; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 47188; } else { return 21708; }
                                } else {
                                    if (i == 226) { return 52400; } else { return 45171; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 29561; } else { return 31026; }
                                } else {
                                    if (i == 230) { return 12845; } else { return 11647; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 32516; } else { return 1174; }
                                } else {
                                    if (i == 234) { return 38654; } else { return 65162; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 35564; } else { return 60621; }
                                } else {
                                    if (i == 238) { return 52573; } else { return 24030; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 56946; } else { return 29251; }
                                } else {
                                    if (i == 242) { return 17181; } else { return 7448; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 6216; } else { return 18675; }
                                } else {
                                    if (i == 246) { return 62349; } else { return 36224; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 32963; } else { return 49998; }
                                } else {
                                    if (i == 250) { return 20034; } else { return 17111; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 55101; } else { return 15772; }
                                } else {
                                    if (i == 254) { return 40116; } else { return 46231; }
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    /**
     * @notice Gets subsequent values in the fade table at an index. The values are encoded
     *         into a single 16 bit integer with the value at the specified index being the most
     *         significant 8 bits and the subsequent value being the least significant 8 bits.
     *
     * @param i the index in the fade table.
     *
     * @dev The values from the table are mapped out into a binary tree for faster lookups.
     *      Looking up any value in the table in this implementation is is O(8), in
     *      the implementation of sequential if statements it is O(256).
     *
     * @dev The body of this function is autogenerated. Check out the 'gen-ftable' script.
     */
    function ftable(int256 i) internal pure returns (int256) {
        if (i <= 127) {
            if (i <= 63) {
                if (i <= 31) {
                    if (i <= 15) {
                        if (i <= 7) {
                            if (i <= 3) {
                                if (i <= 1) {
                                    if (i == 0) { return 0; } else { return 0; }
                                } else {
                                    if (i == 2) { return 0; } else { return 0; }
                                }
                            } else {
                                if (i <= 5) {
                                    if (i == 4) { return 0; } else { return 0; }
                                } else {
                                    if (i == 6) { return 0; } else { return 1; }
                                }
                            }
                        } else {
                            if (i <= 11) {
                                if (i <= 9) {
                                    if (i == 8) { return 4097; } else { return 4098; }
                                } else {
                                    if (i == 10) { return 8195; } else { return 12291; }
                                }
                            } else {
                                if (i <= 13) {
                                    if (i == 12) { return 12292; } else { return 16390; }
                                } else {
                                    if (i == 14) { return 24583; } else { return 28681; }
                                }
                            }
                        }
                    } else {
                        if (i <= 23) {
                            if (i <= 19) {
                                if (i <= 17) {
                                    if (i == 16) { return 36874; } else { return 40972; }
                                } else {
                                    if (i == 18) { return 49166; } else { return 57361; }
                                }
                            } else {
                                if (i <= 21) {
                                    if (i == 20) { return 69651; } else { return 77846; }
                                } else {
                                    if (i == 22) { return 90137; } else { return 102429; }
                                }
                            }
                        } else {
                            if (i <= 27) {
                                if (i <= 25) {
                                    if (i == 24) { return 118816; } else { return 131108; }
                                } else {
                                    if (i == 26) { return 147496; } else { return 163885; }
                                }
                            } else {
                                if (i <= 29) {
                                    if (i == 28) { return 184369; } else { return 200758; }
                                } else {
                                    if (i == 30) { return 221244; } else { return 245825; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 47) {
                        if (i <= 39) {
                            if (i <= 35) {
                                if (i <= 33) {
                                    if (i == 32) { return 266311; } else { return 290893; }
                                } else {
                                    if (i == 34) { return 315476; } else { return 344155; }
                                }
                            } else {
                                if (i <= 37) {
                                    if (i == 36) { return 372834; } else { return 401513; }
                                } else {
                                    if (i == 38) { return 430193; } else { return 462969; }
                                }
                            }
                        } else {
                            if (i <= 43) {
                                if (i <= 41) {
                                    if (i == 40) { return 495746; } else { return 532619; }
                                } else {
                                    if (i == 42) { return 569492; } else { return 606366; }
                                }
                            } else {
                                if (i <= 45) {
                                    if (i == 44) { return 647335; } else { return 684210; }
                                } else {
                                    if (i == 46) { return 729276; } else { return 770247; }
                                }
                            }
                        }
                    } else {
                        if (i <= 55) {
                            if (i <= 51) {
                                if (i <= 49) {
                                    if (i == 48) { return 815315; } else { return 864478; }
                                } else {
                                    if (i == 50) { return 909546; } else { return 958711; }
                                }
                            } else {
                                if (i <= 53) {
                                    if (i == 52) { return 1011971; } else { return 1061137; }
                                } else {
                                    if (i == 54) { return 1118494; } else { return 1171756; }
                                }
                            }
                        } else {
                            if (i <= 59) {
                                if (i <= 57) {
                                    if (i == 56) { return 1229114; } else { return 1286473; }
                                } else {
                                    if (i == 58) { return 1347928; } else { return 1409383; }
                                }
                            } else {
                                if (i <= 61) {
                                    if (i == 60) { return 1470838; } else { return 1532294; }
                                } else {
                                    if (i == 62) { return 1597847; } else { return 1667496; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 95) {
                    if (i <= 79) {
                        if (i <= 71) {
                            if (i <= 67) {
                                if (i <= 65) {
                                    if (i == 64) { return 1737145; } else { return 1806794; }
                                } else {
                                    if (i == 66) { return 1876444; } else { return 1950190; }
                                }
                            } else {
                                if (i <= 69) {
                                    if (i == 68) { return 2023936; } else { return 2097683; }
                                } else {
                                    if (i == 70) { return 2175526; } else { return 2253370; }
                                }
                            }
                        } else {
                            if (i <= 75) {
                                if (i <= 73) {
                                    if (i == 72) { return 2335309; } else { return 2413153; }
                                } else {
                                    if (i == 74) { return 2495094; } else { return 2581131; }
                                }
                            } else {
                                if (i <= 77) {
                                    if (i == 76) { return 2667168; } else { return 2753205; }
                                } else {
                                    if (i == 78) { return 2839243; } else { return 2929377; }
                                }
                            }
                        }
                    } else {
                        if (i <= 87) {
                            if (i <= 83) {
                                if (i <= 81) {
                                    if (i == 80) { return 3019511; } else { return 3109646; }
                                } else {
                                    if (i == 82) { return 3203877; } else { return 3298108; }
                                }
                            } else {
                                if (i <= 85) {
                                    if (i == 84) { return 3392339; } else { return 3486571; }
                                } else {
                                    if (i == 86) { return 3584899; } else { return 3683227; }
                                }
                            }
                        } else {
                            if (i <= 91) {
                                if (i <= 89) {
                                    if (i == 88) { return 3781556; } else { return 3883981; }
                                } else {
                                    if (i == 90) { return 3986406; } else { return 4088831; }
                                }
                            } else {
                                if (i <= 93) {
                                    if (i == 92) { return 4191257; } else { return 4297778; }
                                } else {
                                    if (i == 94) { return 4400204; } else { return 4506727; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 111) {
                        if (i <= 103) {
                            if (i <= 99) {
                                if (i <= 97) {
                                    if (i == 96) { return 4617345; } else { return 4723868; }
                                } else {
                                    if (i == 98) { return 4834487; } else { return 4945106; }
                                }
                            } else {
                                if (i <= 101) {
                                    if (i == 100) { return 5055725; } else { return 5166345; }
                                } else {
                                    if (i == 102) { return 5281060; } else { return 5391680; }
                                }
                            }
                        } else {
                            if (i <= 107) {
                                if (i <= 105) {
                                    if (i == 104) { return 5506396; } else { return 5621112; }
                                } else {
                                    if (i == 106) { return 5735829; } else { return 5854641; }
                                }
                            } else {
                                if (i <= 109) {
                                    if (i == 108) { return 5969358; } else { return 6088171; }
                                } else {
                                    if (i == 110) { return 6206983; } else { return 6321700; }
                                }
                            }
                        }
                    } else {
                        if (i <= 119) {
                            if (i <= 115) {
                                if (i <= 113) {
                                    if (i == 112) { return 6440514; } else { return 6563423; }
                                } else {
                                    if (i == 114) { return 6682236; } else { return 6801050; }
                                }
                            } else {
                                if (i <= 117) {
                                    if (i == 116) { return 6923959; } else { return 7042773; }
                                } else {
                                    if (i == 118) { return 7165682; } else { return 7284496; }
                                }
                            }
                        } else {
                            if (i <= 123) {
                                if (i <= 121) {
                                    if (i == 120) { return 7407406; } else { return 7530316; }
                                } else {
                                    if (i == 122) { return 7653226; } else { return 7776136; }
                                }
                            } else {
                                if (i <= 125) {
                                    if (i == 124) { return 7899046; } else { return 8021956; }
                                } else {
                                    if (i == 126) { return 8144866; } else { return 8267776; }
                                }
                            }
                        }
                    }
                }
            }
        } else {
            if (i <= 191) {
                if (i <= 159) {
                    if (i <= 143) {
                        if (i <= 135) {
                            if (i <= 131) {
                                if (i <= 129) {
                                    if (i == 128) { return 8390685; } else { return 8509499; }
                                } else {
                                    if (i == 130) { return 8632409; } else { return 8755319; }
                                }
                            } else {
                                if (i <= 133) {
                                    if (i == 132) { return 8878229; } else { return 9001139; }
                                } else {
                                    if (i == 134) { return 9124049; } else { return 9246959; }
                                }
                            }
                        } else {
                            if (i <= 139) {
                                if (i <= 137) {
                                    if (i == 136) { return 9369869; } else { return 9492778; }
                                } else {
                                    if (i == 138) { return 9611592; } else { return 9734501; }
                                }
                            } else {
                                if (i <= 141) {
                                    if (i == 140) { return 9853315; } else { return 9976224; }
                                } else {
                                    if (i == 142) { return 10095037; } else { return 10213851; }
                                }
                            }
                        }
                    } else {
                        if (i <= 151) {
                            if (i <= 147) {
                                if (i <= 145) {
                                    if (i == 144) { return 10336760; } else { return 10455572; }
                                } else {
                                    if (i == 146) { return 10570289; } else { return 10689102; }
                                }
                            } else {
                                if (i <= 149) {
                                    if (i == 148) { return 10807914; } else { return 10922631; }
                                } else {
                                    if (i == 150) { return 11041443; } else { return 11156159; }
                                }
                            }
                        } else {
                            if (i <= 155) {
                                if (i <= 153) {
                                    if (i == 152) { return 11270875; } else { return 11385590; }
                                } else {
                                    if (i == 154) { return 11496210; } else { return 11610925; }
                                }
                            } else {
                                if (i <= 157) {
                                    if (i == 156) { return 11721544; } else { return 11832163; }
                                } else {
                                    if (i == 158) { return 11942782; } else { return 12053400; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 175) {
                        if (i <= 167) {
                            if (i <= 163) {
                                if (i <= 161) {
                                    if (i == 160) { return 12159923; } else { return 12270541; }
                                } else {
                                    if (i == 162) { return 12377062; } else { return 12479488; }
                                }
                            } else {
                                if (i <= 165) {
                                    if (i == 164) { return 12586009; } else { return 12688434; }
                                } else {
                                    if (i == 166) { return 12790859; } else { return 12893284; }
                                }
                            }
                        } else {
                            if (i <= 171) {
                                if (i <= 169) {
                                    if (i == 168) { return 12995708; } else { return 13094036; }
                                } else {
                                    if (i == 170) { return 13192364; } else { return 13290691; }
                                }
                            } else {
                                if (i <= 173) {
                                    if (i == 172) { return 13384922; } else { return 13479153; }
                                } else {
                                    if (i == 174) { return 13573384; } else { return 13667614; }
                                }
                            }
                        }
                    } else {
                        if (i <= 183) {
                            if (i <= 179) {
                                if (i <= 177) {
                                    if (i == 176) { return 13757748; } else { return 13847882; }
                                } else {
                                    if (i == 178) { return 13938015; } else { return 14024052; }
                                }
                            } else {
                                if (i <= 181) {
                                    if (i == 180) { return 14110089; } else { return 14196126; }
                                } else {
                                    if (i == 182) { return 14282162; } else { return 14364101; }
                                }
                            }
                        } else {
                            if (i <= 187) {
                                if (i <= 185) {
                                    if (i == 184) { return 14441945; } else { return 14523884; }
                                } else {
                                    if (i == 186) { return 14601727; } else { return 14679569; }
                                }
                            } else {
                                if (i <= 189) {
                                    if (i == 188) { return 14753315; } else { return 14827061; }
                                } else {
                                    if (i == 190) { return 14900806; } else { return 14970456; }
                                }
                            }
                        }
                    }
                }
            } else {
                if (i <= 223) {
                    if (i <= 207) {
                        if (i <= 199) {
                            if (i <= 195) {
                                if (i <= 193) {
                                    if (i == 192) { return 15044200; } else { return 15109753; }
                                } else {
                                    if (i == 194) { return 15179401; } else { return 15244952; }
                                }
                            } else {
                                if (i <= 197) {
                                    if (i == 196) { return 15306407; } else { return 15367862; }
                                } else {
                                    if (i == 198) { return 15429317; } else { return 15490771; }
                                }
                            }
                        } else {
                            if (i <= 203) {
                                if (i <= 201) {
                                    if (i == 200) { return 15548129; } else { return 15605486; }
                                } else {
                                    if (i == 202) { return 15658748; } else { return 15716104; }
                                }
                            } else {
                                if (i <= 205) {
                                    if (i == 204) { return 15765269; } else { return 15818529; }
                                } else {
                                    if (i == 206) { return 15867692; } else { return 15912760; }
                                }
                            }
                        }
                    } else {
                        if (i <= 215) {
                            if (i <= 211) {
                                if (i <= 209) {
                                    if (i == 208) { return 15961923; } else { return 16006989; }
                                } else {
                                    if (i == 210) { return 16047960; } else { return 16093025; }
                                }
                            } else {
                                if (i <= 213) {
                                    if (i == 212) { return 16129899; } else { return 16170868; }
                                } else {
                                    if (i == 214) { return 16207741; } else { return 16244614; }
                                }
                            }
                        } else {
                            if (i <= 219) {
                                if (i <= 217) {
                                    if (i == 216) { return 16281486; } else { return 16314262; }
                                } else {
                                    if (i == 218) { return 16347037; } else { return 16375716; }
                                }
                            } else {
                                if (i <= 221) {
                                    if (i == 220) { return 16404395; } else { return 16433074; }
                                } else {
                                    if (i == 222) { return 16461752; } else { return 16486334; }
                                }
                            }
                        }
                    }
                } else {
                    if (i <= 239) {
                        if (i <= 231) {
                            if (i <= 227) {
                                if (i <= 225) {
                                    if (i == 224) { return 16510915; } else { return 16531401; }
                                } else {
                                    if (i == 226) { return 16555982; } else { return 16576466; }
                                }
                            } else {
                                if (i <= 229) {
                                    if (i == 228) { return 16592855; } else { return 16613339; }
                                } else {
                                    if (i == 230) { return 16629727; } else { return 16646114; }
                                }
                            }
                        } else {
                            if (i <= 235) {
                                if (i <= 233) {
                                    if (i == 232) { return 16658406; } else { return 16674793; }
                                } else {
                                    if (i == 234) { return 16687084; } else { return 16699374; }
                                }
                            } else {
                                if (i <= 237) {
                                    if (i == 236) { return 16707569; } else { return 16719859; }
                                } else {
                                    if (i == 238) { return 16728053; } else { return 16736246; }
                                }
                            }
                        }
                    } else {
                        if (i <= 247) {
                            if (i <= 243) {
                                if (i <= 241) {
                                    if (i == 240) { return 16740344; } else { return 16748537; }
                                } else {
                                    if (i == 242) { return 16752635; } else { return 16760828; }
                                }
                            } else {
                                if (i <= 245) {
                                    if (i == 244) { return 16764924; } else { return 16764925; }
                                } else {
                                    if (i == 246) { return 16769022; } else { return 16773118; }
                                }
                            }
                        } else {
                            if (i <= 251) {
                                if (i <= 249) {
                                    if (i == 248) { return 16773119; } else { return 16777215; }
                                } else {
                                    if (i == 250) { return 16777215; } else { return 16777215; }
                                }
                            } else {
                                if (i <= 253) {
                                    if (i == 252) { return 16777215; } else { return 16777215; }
                                } else {
                                    if (i == 254) { return 16777215; } else { return 16777215; }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}




library Trig {

/*---
Trigonometry - Implementation 1
---*/

// Implementation 1 requires wrapping inputs between 2 * PI and 4 * PI to avoid precision errors, but it is more accurate than Implementation 2.

/*
 * Implementation by Matt Solomon, found here: https://github.com/mds1/solidity-trigonometry
 *
 * Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */

  // Table index into the trigonometric table
  uint256 constant INDEX_WIDTH        = 8;
  // Interpolation between successive entries in the table
  uint256 constant INTERP_WIDTH       = 16;
  uint256 constant INDEX_OFFSET       = 28 - INDEX_WIDTH;
  uint256 constant INTERP_OFFSET      = INDEX_OFFSET - INTERP_WIDTH;
  uint32  constant ANGLES_IN_CYCLE    = 1073741824;
  uint32  constant QUADRANT_HIGH_MASK = 536870912;
  uint32  constant QUADRANT_LOW_MASK  = 268435456;
  uint256 constant SINE_TABLE_SIZE    = 256;

  // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
  // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
  uint256 constant PI          = 3141592653589793238;
  uint256 constant TWO_PI      = 2 * PI;
  uint256 constant PI_OVER_TWO = PI / 2;

  // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
  // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
  // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
  // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
  // 256 defined above)
  uint8   constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
  uint256 constant entry_mask  = ((1 << 8*entry_bytes) - 1); // mask used to cast bytes32 -> lookup table entry
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

  /**
   * @notice Return the sine of a value, specified in radians scaled by 1e18
   * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
   * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
   * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
   * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
   * range of -1 to 1, again scaled by 1e18
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function sin(uint256 _angle) public pure returns (int256) {
    unchecked {
      // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
      // of 0 to 1,073,741,824
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;

      // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
      // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
      // and the offset is the offset of the bits (in bits) we want to extract. The result is an
      // integer containing _width bits of _value starting at the offset bit
      uint256 interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint256 index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);

      // The lookup table only contains data for one quadrant (since sin is symmetric around both
      // axes), so here we figure out which quadrant we're in, then we lookup the values in the
      // table then modify values accordingly
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }

      bytes memory table = sin_table;
      // We are looking for two consecutive indices in our lookup table
      // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
      // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
      uint256 offset1_2 = (index + 2) * entry_bytes;

      // This following snippet will function for any entry_bytes <= 15
      uint256 x1_2; assembly {
        // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
        x1_2 := mload(add(table, offset1_2))
      }

      // We now read the last two numbers of size entry_bytes from x1_2
      // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
      // therefore: entry_mask = 0xFFFFFFFF

      // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
      // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
      uint256 x1 = x1_2 >> 8*entry_bytes & entry_mask;
      // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
      uint256 x2 = x1_2 & entry_mask;

      // Approximate angle by interpolating in the table, accounting for the quadrant
      uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }

      // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
      // This can never overflow because sine is bounded by the above values
      return sine * 1e18 / 2_147_483_647;
    }
  }

  /**
   * @notice Return the cosine of a value, specified in radians scaled by 1e18
   * @dev This is identical to the sin() method, and just computes the value by delegating to the
   * sin() method using the identity cos(x) = sin(x + pi/2)
   * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function cos(uint256 _angle) public pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }

/*---
Trigonometry - Implementation 2
---*/

// Implementation 2 is less accurate than Implementation 1, but it allows for unbounded input in degrees. Output should be downscaled by 1e6. Sintable array loaded twice to avoid stack too deep errors.


  //Computes sine using degrees unit input.
  function dsin (int degrees) external pure returns (int) {
    int[360] memory sintable =
      [int(0),
      17452,
      34899,
      52336,
      69756,
      87156,
      104528,
      121869,
      139173,
      156434,
      173648,
      190809,
      207912,
      224951,
      241922,
      258819,
      275637,
      292372,
      309017,
      325568,
      342020,
      358368,
      374607,
      390731,
      406737,
      422618,
      438371,
      453990,
      469472,
      484810,
      500000,
      515038,
      529919,
      544639,
      559193,
      573576,
      587785,
      601815,
      615661,
      629320,
      642788,
      656059,
      669131,
      681998,
      694658,
      707107, 
      719340,
      731354,
      743145,
      754710,
      766044,
      777146,
      788011,
      798636,
      809017,
      819152,
      829038,
      838671,
      848048,
      857167,
      866025,
      874620,
      882948,
      891007,
      898794,
      906308,
      913545,
      920505,
      927184,
      933580,
      939693,
      945519,
      951057,
      956305,
      961262,
      965926,
      970296,
      974370,
      978148,
      981627,
      984808,
      987688,
      990268,
      992546,
      994522,
      996195,
      997564,
      998630,
      999391,
      999848,
      1000000,
      999848,
      999391,
      998630,
      997564,
      996195,
      994522,
      992546,
      990268,
      987688,
      984808,
      981627,
      978148,
      974370,
      970296,
      965926,
      961262,
      956305,
      951057,
      945519,
      939693,
      933580,
      927184,
      920505,
      913545,
      906308,
      898794,
      891007,
      882948,
      874620,
      866025,
      857167,
      848048,
      838671,
      829038,
      819152,
      809017,
      798636,
      788011,
      777146,
      766044,
      754710,
      743145,
      731354,
      719340,
      707107,
      694658,
      681998,
      669131,
      656059,
      642788,
      629320,
      615661,
      601815,
      587785,
      573576,
      559193,
      544639,
      529919,
      515038,
      500000,
      484810,
      469472,
      453990,
      438371,
      422618,
      406737,
      390731,
      374607,
      358368,
      342020,
      325568,
      309017,
      292372,
      275637,
      258819,
      241922,
      224951,
      207912,
      190809,
      173648,
      156434,
      139173,
      121869,
      104528,
      87156,
      69756,
      52336,
      34899,
      17452,
      0,
      -17452,
      -34899,
      -52336,
      -69756,
      -87156,
      -104528,
      -121869,
      -139173,
      -156434,
      -173648,
      -190809,
      -207912,
      -224951,
      -241922,
      -258819,
      -275637,
      -292372,
      -309017,
      -325568,
      -342020,
      -358368,
      -374607,
      -390731,
      -406737,
      -422618,
      -438371,
      -453990,
      -469472,
      -484810,
      -500000,
      -515038,
      -529919,
      -544639,
      -559193,
      -573576,
      -587785,
      -601815,
      -615661,
      -629320,
      -642788,
      -656059,
      -669131,
      -681998,
      -694658,
      -707107, 
      -719340,
      -731354,
      -743145,
      -754710,
      -766044,
      -777146,
      -788011,
      -798636,
      -809017,
      -819152,
      -829038,
      -838671,
      -848048,
      -857167,
      -866025,
      -874620,
      -882948,
      -891007,
      -898794,
      -906308,
      -913545,
      -920505,
      -927184,
      -933580,
      -939693,
      -945519,
      -951057,
      -956305,
      -961262,
      -965926,
      -970296,
      -974370,
      -978148,
      -981627,
      -984808,
      -987688,
      -990268,
      -992546,
      -994522,
      -996195,
      -997564,
      -998630,
      -999391,
      -999848,
      -1000000,
      -999848,
      -999391,
      -998630,
      -997564,
      -996195,
      -994522,
      -992546,
      -990268,
      -987688,
      -984808,
      -981627,
      -978148,
      -974370,
      -970296,
      -965926,
      -961262,
      -956305,
      -951057,
      -945519,
      -939693,
      -933580,
      -927184,
      -920505,
      -913545,
      -906308,
      -898794,
      -891007,
      -882948,
      -874620,
      -866025,
      -857167,
      -848048,
      -838671,
      -829038,
      -819152,
      -809017,
      -798636,
      -788011,
      -777146,
      -766044,
      -754710,
      -743145,
      -731354,
      -719340,
      -707107,
      -694658,
      -681998,
      -669131,
      -656059,
      -642788,
      -629320,
      -615661,
      -601815,
      -587785,
      -573576,
      -559193,
      -544639,
      -529919,
      -515038,
      -500000,
      -484810,
      -469472,
      -453990,
      -438371,
      -422618,
      -406737,
      -390731,
      -374607,
      -358368,
      -342020,
      -325568,
      -309017,
      -292372,
      -275637,
      -258819,
      -241922,
      -224951,
      -207912,
      -190809,
      -173648,
      -156434,
      -139173,
      -121869,
      -104528,
      -87156,
      -69756,
      -52336,
      -34899,
      -17452];
    if (degrees > -1) {
      return sintable[uint(degrees) % 360];
    }
    else {
      return sintable[uint(degrees * -1) % 360] * -1;
    }
  }

  //Computes cosine with degrees unit input.
  function dcos (int degrees) external pure returns (int) {
    int[360] memory sintable =
      [int(0),
      17452,
      34899,
      52336,
      69756,
      87156,
      104528,
      121869,
      139173,
      156434,
      173648,
      190809,
      207912,
      224951,
      241922,
      258819,
      275637,
      292372,
      309017,
      325568,
      342020,
      358368,
      374607,
      390731,
      406737,
      422618,
      438371,
      453990,
      469472,
      484810,
      500000,
      515038,
      529919,
      544639,
      559193,
      573576,
      587785,
      601815,
      615661,
      629320,
      642788,
      656059,
      669131,
      681998,
      694658,
      707107, 
      719340,
      731354,
      743145,
      754710,
      766044,
      777146,
      788011,
      798636,
      809017,
      819152,
      829038,
      838671,
      848048,
      857167,
      866025,
      874620,
      882948,
      891007,
      898794,
      906308,
      913545,
      920505,
      927184,
      933580,
      939693,
      945519,
      951057,
      956305,
      961262,
      965926,
      970296,
      974370,
      978148,
      981627,
      984808,
      987688,
      990268,
      992546,
      994522,
      996195,
      997564,
      998630,
      999391,
      999848,
      1000000,
      999848,
      999391,
      998630,
      997564,
      996195,
      994522,
      992546,
      990268,
      987688,
      984808,
      981627,
      978148,
      974370,
      970296,
      965926,
      961262,
      956305,
      951057,
      945519,
      939693,
      933580,
      927184,
      920505,
      913545,
      906308,
      898794,
      891007,
      882948,
      874620,
      866025,
      857167,
      848048,
      838671,
      829038,
      819152,
      809017,
      798636,
      788011,
      777146,
      766044,
      754710,
      743145,
      731354,
      719340,
      707107,
      694658,
      681998,
      669131,
      656059,
      642788,
      629320,
      615661,
      601815,
      587785,
      573576,
      559193,
      544639,
      529919,
      515038,
      500000,
      484810,
      469472,
      453990,
      438371,
      422618,
      406737,
      390731,
      374607,
      358368,
      342020,
      325568,
      309017,
      292372,
      275637,
      258819,
      241922,
      224951,
      207912,
      190809,
      173648,
      156434,
      139173,
      121869,
      104528,
      87156,
      69756,
      52336,
      34899,
      17452,
      0,
      -17452,
      -34899,
      -52336,
      -69756,
      -87156,
      -104528,
      -121869,
      -139173,
      -156434,
      -173648,
      -190809,
      -207912,
      -224951,
      -241922,
      -258819,
      -275637,
      -292372,
      -309017,
      -325568,
      -342020,
      -358368,
      -374607,
      -390731,
      -406737,
      -422618,
      -438371,
      -453990,
      -469472,
      -484810,
      -500000,
      -515038,
      -529919,
      -544639,
      -559193,
      -573576,
      -587785,
      -601815,
      -615661,
      -629320,
      -642788,
      -656059,
      -669131,
      -681998,
      -694658,
      -707107, 
      -719340,
      -731354,
      -743145,
      -754710,
      -766044,
      -777146,
      -788011,
      -798636,
      -809017,
      -819152,
      -829038,
      -838671,
      -848048,
      -857167,
      -866025,
      -874620,
      -882948,
      -891007,
      -898794,
      -906308,
      -913545,
      -920505,
      -927184,
      -933580,
      -939693,
      -945519,
      -951057,
      -956305,
      -961262,
      -965926,
      -970296,
      -974370,
      -978148,
      -981627,
      -984808,
      -987688,
      -990268,
      -992546,
      -994522,
      -996195,
      -997564,
      -998630,
      -999391,
      -999848,
      -1000000,
      -999848,
      -999391,
      -998630,
      -997564,
      -996195,
      -994522,
      -992546,
      -990268,
      -987688,
      -984808,
      -981627,
      -978148,
      -974370,
      -970296,
      -965926,
      -961262,
      -956305,
      -951057,
      -945519,
      -939693,
      -933580,
      -927184,
      -920505,
      -913545,
      -906308,
      -898794,
      -891007,
      -882948,
      -874620,
      -866025,
      -857167,
      -848048,
      -838671,
      -829038,
      -819152,
      -809017,
      -798636,
      -788011,
      -777146,
      -766044,
      -754710,
      -743145,
      -731354,
      -719340,
      -707107,
      -694658,
      -681998,
      -669131,
      -656059,
      -642788,
      -629320,
      -615661,
      -601815,
      -587785,
      -573576,
      -559193,
      -544639,
      -529919,
      -515038,
      -500000,
      -484810,
      -469472,
      -453990,
      -438371,
      -422618,
      -406737,
      -390731,
      -374607,
      -358368,
      -342020,
      -325568,
      -309017,
      -292372,
      -275637,
      -258819,
      -241922,
      -224951,
      -207912,
      -190809,
      -173648,
      -156434,
      -139173,
      -121869,
      -104528,
      -87156,
      -69756,
      -52336,
      -34899,
      -17452];
    if ((degrees + 90) > -1) {
      return sintable[uint(degrees + 90) % 360];
    }
    else {
      return sintable[uint((degrees + 90) * -1) % 360] * -1;
    }
  }
}




// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}


interface IVeArtProxy {
    /// @dev Art configuration
    struct Config {
        // NFT metadata variables
        int256 _tokenId;
        int256 _balanceOf;
        int256 _lockedEnd;
        int256 _lockedAmount;
        // Line art variables
        int256 shape;
        uint256 palette;
        int256 maxLines;
        int256 dash;
        // Randomness variables
        int256 seed1;
        int256 seed2;
        int256 seed3;
    }

    /// @dev Individual line art path variables.
    struct lineConfig {
        bytes8 color;
        uint256 stroke;
        uint256 offset;
        uint256 offsetHalf;
        uint256 offsetDashSum;
        uint256 pathLength;
    }

    /// @dev Represents an (x,y) coordinate in a line.
    struct Point {
        int256 x;
        int256 y;
    }

    /// @notice Generate a SVG based on veNFT metadata
    /// @param _tokenId Unique veNFT identifier
    /// @return output SVG metadata as HTML tag
    function tokenURI(uint256 _tokenId) external view returns (string memory output);

    /// @notice Generate only the foreground <path> elements of the line art for an NFT (excluding SVG header), for flexibility purposes.
    /// @param _tokenId Unique veNFT identifier
    /// @return output Encoded output of generateShape()
    function lineArtPathsOnly(uint256 _tokenId) external view returns (bytes memory output);

    /// @notice Generate the master art config metadata for a veNFT
    /// @param _tokenId Unique veNFT identifier
    /// @return cfg Config struct
    function generateConfig(uint256 _tokenId) external view returns (Config memory cfg);

    /// @notice Generate the points for two stripe lines based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of line drawn
    /// @return Line (x, y) coordinates of the drawn stripes
    function twoStripes(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of circles drawn
    /// @return Line (x, y) coordinates of the drawn circles
    function circles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for interlocking circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of interlocking circles drawn
    /// @return Line (x, y) coordinates of the drawn interlocking circles
    function interlockingCircles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for corners based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of corners drawn
    /// @return Line (x, y) coordinates of the drawn corners
    function corners(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a curve based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of curve drawn
    /// @return Line (x, y) coordinates of the drawn curve
    function curves(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a spiral based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of spiral drawn
    /// @return Line (x, y) coordinates of the drawn spiral
    function spiral(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for an explosion based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of explosion drawn
    /// @return Line (x, y) coordinates of the drawn explosion
    function explosion(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a wormhole based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of wormhole drawn
    /// @return Line (x, y) coordinates of the drawn wormhole
    function wormhole(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// OpenZeppelin Contracts (interfaces/IERC6372.sol)

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

/// Modified IVotes interface for tokenId based voting
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the amount of votes that `tokenId` had at a specific moment in the past.
     *      If the account passed in is not the owner, returns 0.
     */
    function getPastVotes(address account, uint256 tokenId, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `tokenId` has chosen. Can never be equal to the delegator's `tokenId`.
     *      Returns 0 if not delegated.
     */
    function delegates(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(uint256 delegator, uint256 delegatee) external;

    /**
     * @dev Delegates votes from `delegator` to `delegatee`. Signer must own `delegator`.
     */
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IVotingEscrow is IVotes, IERC4906, IERC6372, IERC721Metadata {
    struct LockedBalance {
        int128 amount;
        uint256 end;
        bool isPermanent;
    }

    struct UserPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanent;
    }

    struct GlobalPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanentLockBalance;
    }

    /// @notice A checkpoint for recorded delegated voting weights at a certain timestamp
    struct Checkpoint {
        uint256 fromTimestamp;
        address owner;
        uint256 delegatedBalance;
        uint256 delegatee;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @dev Different types of veNFTs:
    /// NORMAL  - typical veNFT
    /// LOCKED  - veNFT which is locked into a MANAGED veNFT
    /// MANAGED - veNFT which can accept the deposit of NORMAL veNFTs
    enum EscrowType {
        NORMAL,
        LOCKED,
        MANAGED
    }

    error AlreadyVoted();
    error AmountTooBig();
    error ERC721ReceiverRejectedTokens();
    error ERC721TransferToNonERC721ReceiverImplementer();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureS();
    error InvalidManagedNFTId();
    error LockDurationNotInFuture();
    error LockDurationTooLong();
    error LockExpired();
    error LockNotExpired();
    error NoLockFound();
    error NonExistentToken();
    error NotApprovedOrOwner();
    error NotDistributor();
    error NotEmergencyCouncilOrGovernor();
    error NotGovernor();
    error NotGovernorOrManager();
    error NotManagedNFT();
    error NotManagedOrNormalNFT();
    error NotLockedNFT();
    error NotNormalNFT();
    error NotPermanentLock();
    error NotOwner();
    error NotTeam();
    error NotVoter();
    error OwnershipChange();
    error PermanentLock();
    error SameAddress();
    error SameNFT();
    error SameState();
    error SplitNoOwner();
    error SplitNotAllowed();
    error SignatureExpired();
    error TooManyTokenIDs();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroBalance();

    event Deposit(
        address indexed provider,
        uint256 indexed tokenId,
        DepositType indexed depositType,
        uint256 value,
        uint256 locktime,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 indexed tokenId, uint256 value, uint256 ts);
    event LockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event UnlockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Merge(
        address indexed _sender,
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 _amountFrom,
        uint256 _amountTo,
        uint256 _amountFinal,
        uint256 _locktime,
        uint256 _ts
    );
    event Split(
        uint256 indexed _from,
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        address _sender,
        uint256 _splitAmount1,
        uint256 _splitAmount2,
        uint256 _locktime,
        uint256 _ts
    );
    event CreateManaged(
        address indexed _to,
        uint256 indexed _mTokenId,
        address indexed _from,
        address _lockedManagedReward,
        address _freeManagedReward
    );
    event DepositManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event WithdrawManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event SetAllowedManager(address indexed _allowedManager);

    // State variables
    /// @notice Address of Meta-tx Forwarder
    function forwarder() external view returns (address);

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of token (PRFCT) used to create a veNFT
    function token() external view returns (address);

    /// @notice Address of RewardsDistributor.sol
    function distributor() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of Protocol Team multisig
    function team() external view returns (address);

    /// @notice Address of art proxy used for on-chain art generation
    function artProxy() external view returns (address);

    /// @dev address which can create managed NFTs
    function allowedManager() external view returns (address);

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping of token id to escrow type
    ///      Takes advantage of the fact default value is EscrowType.NORMAL
    function escrowType(uint256 tokenId) external view returns (EscrowType);

    /// @dev Mapping of token id to managed id
    function idToManaged(uint256 tokenId) external view returns (uint256 managedTokenId);

    /// @dev Mapping of user token id to managed token id to weight of token id
    function weights(uint256 tokenId, uint256 managedTokenId) external view returns (uint256 weight);

    /// @dev Mapping of managed id to deactivated state
    function deactivated(uint256 tokenId) external view returns (bool inactive);

    /// @dev Mapping from managed nft id to locked managed rewards
    ///      `token` denominated rewards (rebases/rewards) stored in locked managed rewards contract
    ///      to prevent co-mingling of assets
    function managedToLocked(uint256 tokenId) external view returns (address);

    /// @dev Mapping from managed nft id to free managed rewards contract
    ///      these rewards can be freely withdrawn by users
    function managedToFree(uint256 tokenId) external view returns (address);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create managed NFT (a permanent lock) for use within ecosystem.
    /// @dev Throws if address already owns a managed NFT.
    /// @return _mTokenId managed token id.
    function createManagedLockFor(address _to) external returns (uint256 _mTokenId);

    /// @notice Delegates balance to managed nft
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    ///         Permanent locks that are deposited will automatically unlock.
    /// @dev Managed nft will remain max-locked as long as there is at least one
    ///      deposit or withdrawal per week.
    ///      Throws if deposit nft is managed.
    ///      Throws if recipient nft is not managed.
    ///      Throws if deposit nft is already locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited
    /// @param _mTokenId tokenId of managed NFT that will receive the deposit
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Retrieves locked rewards and withdraws balance from managed nft.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    /// @dev Throws if NFT not locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Permit one address to call createManagedLockFor() that is not Voter.governor()
    function setAllowedManager(address _allowedManager) external;

    /// @notice Set Managed NFT state. Inactive NFTs cannot be deposited into.
    /// @param _mTokenId managed nft state to set
    /// @param _state true => inactive, false => active
    function setManagedState(uint256 _mTokenId, bool _state) external;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setTeam(address _team) external;

    function setArtProxy(address _proxy) external;

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenId
    function ownerToNFTokenIdList(address _owner, uint256 _index) external view returns (uint256 _tokenId);

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) external view returns (address operator);

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Check whether spender is owner or an approved user for a given veNFT
    /// @param _spender .
    /// @param _tokenId .
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external;

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total count of epochs witnessed since contract creation
    function epoch() external view returns (uint256);

    /// @notice Total amount of token() deposited
    function supply() external view returns (uint256);

    /// @notice Aggregate permanent locked balances
    function permanentLockBalance() external view returns (uint256);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256 _epoch);

    /// @notice time -> signed slope change
    function slopeChanges(uint256 _timestamp) external view returns (int128);

    /// @notice account -> can split
    function canSplit(address _account) external view returns (bool);

    /// @notice Global point history at a given index
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory);

    /// @notice Get the LockedBalance (amount, end) of a _tokenId
    /// @param _tokenId .
    /// @return LockedBalance of _tokenId
    function locked(uint256 _tokenId) external view returns (LockedBalance memory);

    /// @notice User -> UserPoint[userEpoch]
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory);

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value) external;

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @return TokenId of created veNFT
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256);

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @return TokenId of created veNFT
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external returns (uint256);

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    /// @notice Extend the unlock time for `_tokenId`
    ///         Cannot extend lock time of permanent locks
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock is both expired and not permanent
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    function withdraw(uint256 _tokenId) external;

    /// @notice Merges `_from` into `_to`.
    /// @dev Cannot merge `_from` locks that are permanent or have already voted this epoch.
    ///      Cannot merge `_to` locks that have already expired.
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to merge from.
    /// @param _to VeNFT to merge into.
    function merge(uint256 _from, uint256 _to) external;

    /// @notice Splits veNFT into two new veNFTS - one with oldLocked.amount - `_amount`, and the second with `_amount`
    /// @dev    This burns the tokenId of the target veNFT
    ///         Callable by approved or owner
    ///         If this is called by approved, approved will not have permissions to manipulate the newly created veNFTs
    ///         Returns the two new split veNFTs to owner
    ///         If `from` is permanent, will automatically dedelegate.
    ///         This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///         will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to split.
    /// @param _amount Amount to split from veNFT.
    /// @return _tokenId1 Return tokenId of veNFT with oldLocked.amount - `_amount`.
    /// @return _tokenId2 Return tokenId of veNFT with `_amount`.
    function split(uint256 _from, uint256 _amount) external returns (uint256 _tokenId1, uint256 _tokenId2);

    /// @notice Toggle split for a specific address.
    /// @dev Toggle split for address(0) to enable or disable for all.
    /// @param _account Address to toggle split permissions
    /// @param _bool True to allow, false to disallow
    function toggleSplit(address _account, bool _bool) external;

    /// @notice Permanently lock a veNFT. Voting power will be equal to
    ///         `LockedBalance.amount` with no decay. Required to delegate.
    /// @dev Only callable by unlocked normal veNFTs.
    /// @param _tokenId tokenId to lock.
    function lockPermanent(uint256 _tokenId) external;

    /// @notice Unlock a permanently locked veNFT. Voting power will decay.
    ///         Will automatically dedelegate if delegated.
    /// @dev Only callable by permanently locked veNFTs.
    ///      Cannot unlock if already voted this epoch.
    /// @param _tokenId tokenId to unlock.
    function unlockPermanent(uint256 _tokenId) external;

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the voting power for _tokenId at the current timestamp
    /// @dev Returns 0 if called in the same block as a transfer.
    /// @param _tokenId .
    /// @return Voting power
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the voting power for _tokenId at a given timestamp
    /// @param _tokenId .
    /// @param _t Timestamp to query voting power
    /// @return Voting power
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power at current timestamp
    /// @return Total voting power at current timestamp
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total voting power at a given timestamp
    /// @param _t Timestamp to query total voting power
    /// @return Total voting power at given timestamp
    function totalSupplyAt(uint256 _t) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice See if a queried _tokenId has actively voted
    /// @param _tokenId .
    /// @return True if voted, else false
    function voted(uint256 _tokenId) external view returns (bool);

    /// @notice Set the global state voter and distributor
    /// @dev This is only called once, at setup
    function setVoterAndDistributor(address _voter, address _distributor) external;

    /// @notice Set `voted` for _tokenId to true or false
    /// @dev Only callable by voter
    /// @param _tokenId .
    /// @param _voted .
    function voting(uint256 _tokenId, bool _voted) external;

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of checkpoints for each tokenId
    function numCheckpoints(uint256 tokenId) external view returns (uint48);

    /// @notice A record of states for signing / validating signatures
    function nonces(address account) external view returns (uint256);

    /// @inheritdoc IVotes
    function delegates(uint256 delegator) external view returns (uint256);

    /// @notice A record of delegated token checkpoints for each account, by index
    /// @param tokenId .
    /// @param index .
    /// @return Checkpoint
    function checkpoints(uint256 tokenId, uint48 index) external view returns (Checkpoint memory);

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotes
    function delegate(uint256 delegator, uint256 delegatee) external;

    /// @inheritdoc IVotes
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC6372
    function clock() external view returns (uint48);

    /// @inheritdoc IERC6372
    function CLOCK_MODE() external view returns (string memory);
}


/// @title Protocol ArtProxy
/// @author perfectswap.io
/// @notice Official art proxy to generate Protocol veNFT artwork
contract VeArtProxy is IVeArtProxy {

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint256 private constant PI          = 3141592653589793238;
    uint256 private constant TWO_PI      = 2 * PI;
    uint256 private constant DASH = 50;
    uint256 private constant DASH_HALF = 25;

    IVotingEscrow public immutable ve;

    /// @dev art palette color codes used in drawing lines
    bytes8[5][10] palettes =
        [[bytes8('#E0A100'),'#CC9200','#A37500','#3C4150','#A3A3A3'], // yellow-gold
        [bytes8('#D40D0D'),'#A10808','#750606','#3C4150','#A3A3A3'], //red
        [bytes8('#03444C'),'#005F6B','#008C9E','#3C4150','#A3A3A3'], //teal
        [bytes8('#1A50F1'),'#1740BB','#102F8B','#3C4150','#A3A3A3'], //blue
        [bytes8('#C5BC8E'),'#696758','#45484b','#3C4150','#A3A3A3'], //silver
        [bytes8('#FD5821'),'#F23E02','#CA3402','#3C4150','#A3A3A3'], //amber
        [bytes8('#b48610'),'#123291','#cf3502','#3C4150','#A3A3A3'], //distinct
        [bytes8('#719E04'),'#8DB92E','#A9D54C','#3C4150','#A3A3A3'], //green
        [bytes8('#110E07'),'#110E07','#3A3935','#3C4150','#A3A3A3'], //black
        [bytes8('#CC1455'),'#A71145','#820D36','#3C4150','#A3A3A3']]; //pink

    bytes2[5] lineThickness =
        [bytes2('0'),
        '1',
        '1',
        '2',
        '2'];

    constructor(address _ve) {
        ve = IVotingEscrow(_ve);
    }

    /// @inheritdoc IVeArtProxy
    function tokenURI (uint256 _tokenId) external view returns (string memory output) {
        Config memory cfg = generateConfig(_tokenId);

        output = string(
            abi.encodePacked(
                '<svg width="350" height="350" viewBox="0 0 4000 4000" fill="none" xmlns="http://www.w3.org/2000/svg">',
                generateShape(cfg),
                '</svg>')
            );

        string memory readableBalance = tokenAmountToString(uint256(cfg._balanceOf));
        string memory readableAmount = tokenAmountToString(uint256(cfg._lockedAmount));

        uint256 year;
	    uint256 month;
	    uint256 day;
        (year, month, day) = BokkyPooBahsDateTimeLibrary.timestampToDate(uint256(cfg._lockedEnd));

        string memory attributes = string(abi.encodePacked(
	        '{ "trait_type": "Unlock Date", "value": "',
	            toString(year), '-', toString(month), '-', toString(day),
	            '"}, ',
	        '{ "trait_type": "Voting Power", "value": "',
	            readableBalance,
	            '"}, ',
	        '{ "trait_type": "Locked PRFCT", "value": "',
	            readableAmount, '"}'
        ));

        string memory json = Base64.encode(
		    bytes(
                string(
                    abi.encodePacked(
			            '{"name": "lock #',
                        toString(cfg._tokenId),
                        '", "background_color": "121a26", "description": "Perfect Swap is a next-generation AMM that combines the best of Curve, Solidly and Uniswap, designed to serve as a central liquidity hub. Protocol NFTs vote on token emissions and receive bribes and fees generated by the protocol.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)), '", ',
                        '"attributes": [', attributes, ']',
			            '}'
                    )
                )
            )
        );

        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    /// @inheritdoc IVeArtProxy
    function lineArtPathsOnly (uint256 _tokenId) external view returns (bytes memory output) {
        Config memory cfg = generateConfig(_tokenId);
        output = abi.encodePacked(generateShape(cfg));
    }


    /// @inheritdoc IVeArtProxy
    function generateConfig (uint256 _tokenId) public view returns (Config memory cfg) {
        cfg._tokenId = int256(_tokenId);
        cfg._balanceOf = int256(ve.balanceOfNFTAt(_tokenId, block.timestamp));
        IVotingEscrow.LockedBalance memory _locked = ve.locked(_tokenId);
        cfg._lockedEnd = int256(_locked.end);
        cfg._lockedAmount = int256(_locked.amount);

        cfg.shape = seedGen(_tokenId) % 8;
        cfg.palette = getPalette(_tokenId);
        cfg.maxLines = getLineCount(uint256(cfg._balanceOf));
        
        cfg.seed1 = seedGen(_tokenId);
        cfg.seed2 = seedGen(_tokenId * 1e18);
        cfg.seed3 = seedGen(_tokenId * 2e18);
    }

    /// @dev Generates characteristics for each line in the line art.
    function generateLineConfig (Config memory cfg, int256 l) internal view returns (lineConfig memory linecfg) {
        uint256 x = uint256(l);
        linecfg.color = palettes[cfg.palette][uint256(keccak256(abi.encodePacked((l + 20) * (cfg._lockedEnd + cfg._tokenId)))) % 5];
        linecfg.stroke = uint256(keccak256(abi.encodePacked((l + 1) * (cfg._lockedEnd + cfg._tokenId)))) % 5;
        linecfg.offset = uint256(keccak256(abi.encodePacked((l + 1) * (cfg._lockedEnd + cfg._tokenId)))) % 50 / 2 * 2 * 5; // ensure value is even
        linecfg.offsetHalf = linecfg.offset / 2 * 5;
        linecfg.offsetDashSum = linecfg.offset + DASH + linecfg.offsetHalf + DASH_HALF;
        if ((uint256(cfg.seed2) / (1 + x)) % 6 != 0) {
            linecfg.pathLength = linecfg.offsetDashSum * (10 + (uint256(cfg.seed1 * cfg.seed3) / (1 + x * x)) % 15);
        }
    }
       
    /// @dev Selects and draws line art shape.
    function generateShape (Config memory cfg) internal view returns (bytes memory shape) {
        if (cfg.shape == 0) {
            shape = drawCircles(cfg);
        }
        else if (cfg.shape == 1) {
            shape = drawTwoStripes(cfg);
        }
        else if (cfg.shape == 2) {
            shape = drawInterlockingCircles(cfg);
        }
        else if (cfg.shape == 3) {
            shape = drawCorners(cfg);
        }
        else if (cfg.shape == 4) {
            shape = drawCurves(cfg);
        }
        else if (cfg.shape == 5) {
            shape = drawSpiral(cfg);
        }
        else if (cfg.shape == 6) {
            shape = drawExplosion(cfg);
        }
        else {
            shape = drawWormhole(cfg);
        }
    }
        
    /// @dev Calculates the number of digits before the "decimal point" in an NFT's vePRFCT balance.
    ///      Input expressed in 1e18 format.
    function numBalanceDigits (uint256 _balanceOf) internal pure returns (int256 digitCount) {
        uint256 convertedvePRFCTvalue = _balanceOf / 1e18;
        while (convertedvePRFCTvalue != 0) {
            convertedvePRFCTvalue /= 10;
            digitCount++;
        }
    }

    /// @dev Generates a pseudorandom seed based on a veNFT token ID.
    function seedGen (uint256 _tokenId) internal pure returns (int256 seed) {
        seed = 1 + int256(uint256(keccak256(abi.encodePacked(_tokenId))) % 999);
    }

    /// @dev Determines the number of lines in the SVG. NFTs with less than 10 vePRFCT balance have zero lines.
    function getLineCount (uint256 _balanceOf) internal pure returns (int256 lineCount) {
        int256 threshhold = 2;
        lineCount = 4 * numBalanceDigits(_balanceOf);
        if (numBalanceDigits(_balanceOf) < threshhold) {
            lineCount = 0;
        }
    }

    /// @dev Determines the color palette of the SVG.
    function getPalette (uint256 _tokenId) internal pure returns (uint256 palette) {
        palette = uint256(keccak256(abi.encodePacked(_tokenId))) % 10;
    }

/*---
Line Art Generation
---*/

    function drawTwoStripes (Config memory cfg) internal view returns (bytes memory shape) {
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = twoStripes(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function twoStripes(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 k = ((l % 2) * ((200 + cfg.seed3) + (l * 1250 / cfg.maxLines)) + ((l + 1) % 2) * ((2200 + cfg.seed2) + (l * 1250 / cfg.maxLines)));
        int256 i1 = cfg.seed1 % 2;
        int256 i2 = (cfg.seed1 + 1) % 2;
        int256 o1 = i1 * k;
        int256 o2 = i2 * k;

        for (int256 p = 0; p < 100; p++) {
            Line[uint256(p)] = Point({
                x: 41 * p * i2 + o1,
                y: 41 * p * i1 + o2
            });
        }
    }

    function drawCircles (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = circles(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function circles(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 % 100 * 30);
        int256 baseY = 500 + (cfg.seed2 % 100 * 30);
        int256 k  = (cfg.seed3 % 250) + 250 + 100 * (1 + l);
        int256 i = (l % 2) * 2 - 1;

        for (uint256 p = 0; p < 100; p++) {
            uint256 angle = 1e18 * TWO_PI * p / 99;
            Line[p] = Point({
                x: baseX +     k * Trig.sin(angle) / 1e18,
                y: baseY + i * k * Trig.cos(angle) / 1e18
            });
        }        
    }

    function drawInterlockingCircles (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = interlockingCircles(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function interlockingCircles(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = (1500 + cfg.seed1) + (l * 100) * Trig.dcos(90 * l) / 1e6;
        int256 baseY = (1500 + cfg.seed2) + (l * 100) * Trig.dsin(90 * l) / 1e6;
        int256 k = (l + 1) * 100;

        for (uint256 p = 0; p < 100; p++) {
            uint256 angle = 1e18 * TWO_PI * p / 99;
            Line[p] = Point({
                x: baseX + k * Trig.cos(angle) / 1e18,                                   
                y: baseY + k * Trig.sin(angle) / 1e18
            });
        }
    }

    function drawCorners (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = corners(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
   function corners(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 degrees1 = 360 * cfg.seed1 / 1000;
        int256 degrees2 = 360 * (cfg.seed1 + 500) / 1000;
        int256 baseX = 2000 + ((l % 2) * 1200 * Trig.dcos(degrees1) / 1e6) + (((l + 1) % 2) * (1200 * Trig.dcos(degrees2)) / 1e6);
        int256 baseY = 2000 + ((l % 2) * 1200 * Trig.dsin(degrees1) / 1e6) + (((l + 1) % 2) * (1200 * Trig.dsin(degrees2)) / 1e6);
        int256 k = 100 + (1 + l) * 4000 / cfg.maxLines / 4;

        for (int256 p = 0; p < 100; p++) {
            int256 angle3 = 360 * l / cfg.maxLines + (360 * p / 99);
            Line[uint256(p)] = Point({
                x: baseX +                     k * Trig.dcos(angle3) / 1e6,
                y: baseY + ((l % 2) * 2 - 1) * k * Trig.dsin(angle3) / 1e6
            });
        }
    }

    function drawCurves (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = curves(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function curves(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 x = l * 65536 / 150;
        int256 z = cfg.seed1 * 65536;
        int256 k1 = (cfg.seed1 + 1) % 2;
        int256 k2 = cfg.seed1 % 2;
        int256 kA2 = -100 + 4200 * l / cfg.maxLines;
    
        for (int256 p = 0; p < 100; p++) {
            int256 _sin = Trig.sin(1e18 * TWO_PI * uint256(p) / 99);
            int256 noise = PerlinNoise.noise3d(x, p * 65536 / 2000, z);
            int256 a1 = (-100 + 4200 * p / 99) + _sin * noise * 1700 / 65536 / 1e18;
            int256 a2 = kA2                    + _sin * noise * 15000 / 65536 / 1e18;

            Line[uint256(p)] = Point({
                x: k1 * a1 + k2 * a2,
                y: k1 * a2 + k2 * a1
            });
        }
    }

    function drawSpiral (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = spiral(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function spiral(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 % 100 * 30);
        int256 baseY = 500 + (cfg.seed2 % 100 * 30);
        int256 degrees1 = 360 * l / cfg.maxLines;
        int256 cosine = Trig.dcos(degrees1);
        int256 sine = Trig.dsin(degrees1);

        for (int256 p = 0; p < 100; p++) {
            int256 degrees2 = degrees1 + 3 * p;            
            Line[uint256(p)] = Point({
                x: baseX + (325 * cosine / 1e6) + (40 * p) * Trig.dcos(degrees2) / 1e6,
                y: baseY + (325 * sine   / 1e6) + (40 * p) * Trig.dsin(degrees2) / 1e6
            });
        }
    }

    function drawExplosion (Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = explosion(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function explosion(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 1000 + (cfg.seed1 % 100 * 20);
        int256 baseY = 1000 + (cfg.seed2 % 100 * 20);
        int256 degrees = 360 * l / cfg.maxLines;
        int256 k = 300 + (cfg.seed3 * (l + 1) ** 2) % 300;
        int256 cosine = Trig.dcos(degrees);
        int256 sine = Trig.dsin(degrees);        

        for (int256 p = 0; p < 100; p++) {
            Line[99 - uint256(p)] = Point({
                x: baseX + k * cosine / 1e6 + (4000 * p / 99) * cosine / 1e6,
                y: baseY + k * sine   / 1e6 + (4000 * p / 99) * sine   / 1e6
            });
        }
    }

    function drawWormhole(Config memory cfg) internal view returns (bytes memory shape) { 
        for (int256 l = 0; l < cfg.maxLines; l++) {
            Point[100] memory Line = wormhole(cfg, l);
            shape = abi.encodePacked(shape, curveToSVG(l, cfg, Line));
        }
    }

    /// @inheritdoc IVeArtProxy
    function wormhole(Config memory cfg, int256 l) public pure returns (Point[100] memory Line) {
        int256 baseX = 500 + (cfg.seed1 * 3);
        int256 baseY = 500 + (cfg.seed2 * 3);
        int256 degrees = 360 * l / cfg.maxLines;
        int256 cosine = Trig.dcos(degrees);
        int256 sine = Trig.dsin(degrees);
        int256 k1 = 3500 - cfg.seed1 * 3;
        int256 k2 = 3500 - cfg.seed2 * 3;
                
        for (int256 p = 0; p < 100; p++) {
            Line[uint256(p)] = Point({
                x: baseX * (99 - p) / 99 + 250 * cosine / 1e6 +  cosine * (5000 * p / 99) * (99 - p) / 99 / 1e6 + p * k1 / 99,
                y: baseY * (99 - p) / 99 + 250 * sine   / 1e6 +  sine   * (5000 * p / 99) * (99 - p) / 99 / 1e6 + p * k2 / 99
            });
        }
    }

/*---
SVG Formatting
---*/

    /// @dev Converts an array of Point structs into an animated SVG path.
    function curveToSVG (int256 l, Config memory cfg, Point[100] memory Line) internal view returns (bytes memory SVGLine) {
        string memory lineBulk;
        bool priorPointOutOfCanvas = false;
        for (uint256 i = 1; i < Line.length; i++) {
            (int256 x, int256 y) = (Line[i].x, Line[i].y);
            if (x > -200 && x < 4200 && y > -200 && y < 4200) {
                if (priorPointOutOfCanvas) {
                    lineBulk = string.concat(lineBulk, "M", toString(x), ",", toString(y));
                    priorPointOutOfCanvas = false;
                } else {
                    lineBulk = string.concat(lineBulk, "L", toString(x), ",", toString(y));
                    priorPointOutOfCanvas = false;
                }
            } else {
                priorPointOutOfCanvas = true;
            }
        }
 
        lineConfig memory linecfg = generateLineConfig(cfg, l);
        {
            SVGLine = abi.encodePacked(
                '<path d="M',
                toString(Line[0].x), ',',toString(Line[0].y),
                lineBulk, '"',
                ' style="stroke-dasharray: ',
                toString(linecfg.offset), ',',
                toString(DASH), ',',
                toString(linecfg.offsetHalf), ',',
                toString(DASH_HALF), ';',
                ' --offset: '
            );
        }
 
        {
            SVGLine = abi.encodePacked(
                SVGLine,
                toString(linecfg.offsetDashSum), ';',
                ' stroke: ',
                linecfg.color, ';',
                ' stroke-width:',
                lineThickness[linecfg.stroke], '%',';" pathLength="',
                toString(linecfg.pathLength), '">',
                '<animate attributeName="stroke-dashoffset" values="0;',
                toString(linecfg.offsetDashSum), '" ',
                'dur="4s" calcMode="linear" repeatCount="indefinite" /></path>'
            );
        }
    }

/*---
Utility
---*/

    /// @dev Converts token amount to string with one decimal place.
    function tokenAmountToString(uint256 value) internal pure returns (string memory) {
        uint256 leftOfDecimal = value / 10**18;
        uint256 residual = value % 10**18;
        // show one decimal place
        uint256 rightOfDecimal = residual / 10**17;
        string memory s;
        if (residual > 0) {
            s = string(abi.encodePacked(toString(leftOfDecimal), ".", toString(rightOfDecimal)));
         } else {
            s = toString(leftOfDecimal);
        }
        return s;
    }

/*---
OpenZeppelin Functions
---*/

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(abs(value))));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IVotingRewardsFactory} from "./interfaces/factories/IVotingRewardsFactory.sol";
import {IGauge} from "./interfaces/IGauge.sol";
import {IGaugeFactory} from "./interfaces/factories/IGaugeFactory.sol";
import {IMinter} from "./interfaces/IMinter.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IPoolFactory} from "./interfaces/factories/IPoolFactory.sol";
import {IReward} from "./interfaces/IReward.sol";
import {IVoter} from "./interfaces/IVoter.sol";
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {IFactoryRegistry} from "./interfaces/factories/IFactoryRegistry.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC2771Context} from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {ProtocolTimeLibrary} from "./libraries/ProtocolTimeLibrary.sol";

/// @title Protocol Voter
/// @notice Manage votes, emission distribution, and gauge creation within the Protocol's ecosystem.
///         Also provides support for depositing and withdrawing from managed veNFTs.
contract Voter is IVoter, ERC2771Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    /// @inheritdoc IVoter
    address public immutable forwarder;
    /// @inheritdoc IVoter
    address public immutable ve;
    /// @inheritdoc IVoter
    address public immutable factoryRegistry;
    /// @notice Base token of ve contract
    address internal immutable rewardToken;
    /// @notice Rewards are released over 7 days
    uint256 internal constant DURATION = 7 days;
    /// @inheritdoc IVoter
    address public minter;
    /// @inheritdoc IVoter
    address public governor;
    /// @inheritdoc IVoter
    address public epochGovernor;
    /// @inheritdoc IVoter
    address public emergencyCouncil;

    /// @inheritdoc IVoter
    uint256 public totalWeight;
    /// @inheritdoc IVoter
    uint256 public maxVotingNum;
    uint256 internal constant MIN_MAXVOTINGNUM = 10;

    /// @dev All pools viable for incentives
    address[] public pools;
    /// @inheritdoc IVoter
    mapping(address => address) public gauges;
    /// @inheritdoc IVoter
    mapping(address => address) public poolForGauge;
    /// @inheritdoc IVoter
    mapping(address => address) public gaugeToFees;
    /// @inheritdoc IVoter
    mapping(address => address) public gaugeToBribe;
    /// @inheritdoc IVoter
    mapping(address => uint256) public weights;
    /// @inheritdoc IVoter
    mapping(uint256 => mapping(address => uint256)) public votes;
    /// @dev NFT => List of pools voted for by NFT
    mapping(uint256 => address[]) public poolVote;
    /// @inheritdoc IVoter
    mapping(uint256 => uint256) public usedWeights;
    /// @inheritdoc IVoter
    mapping(uint256 => uint256) public lastVoted;
    /// @inheritdoc IVoter
    mapping(address => bool) public isGauge;
    /// @inheritdoc IVoter
    mapping(address => bool) public isWhitelistedToken;
    /// @inheritdoc IVoter
    mapping(uint256 => bool) public isWhitelistedNFT;
    /// @inheritdoc IVoter
    mapping(address => bool) public isAlive;
    /// @dev Accumulated distributions per vote
    uint256 internal index;
    /// @dev Gauge => Accumulated gauge distributions
    mapping(address => uint256) internal supplyIndex;
    /// @inheritdoc IVoter
    mapping(address => uint256) public claimable;

    constructor(address _forwarder, address _ve, address _factoryRegistry) ERC2771Context(_forwarder) {
        forwarder = _forwarder;
        ve = _ve;
        factoryRegistry = _factoryRegistry;
        rewardToken = IVotingEscrow(_ve).token();
        address _sender = _msgSender();
        minter = _sender;
        governor = _sender;
        epochGovernor = _sender;
        emergencyCouncil = _sender;
        maxVotingNum = 30;
    }

    modifier onlyNewEpoch(uint256 _tokenId) {
        // ensure new epoch since last vote
        if (ProtocolTimeLibrary.epochStart(block.timestamp) <= lastVoted[_tokenId]) revert AlreadyVotedOrDeposited();
        if (block.timestamp <= ProtocolTimeLibrary.epochVoteStart(block.timestamp)) revert DistributeWindow();
        _;
    }

    function epochStart(uint256 _timestamp) external pure returns (uint256) {
        return ProtocolTimeLibrary.epochStart(_timestamp);
    }

    function epochNext(uint256 _timestamp) external pure returns (uint256) {
        return ProtocolTimeLibrary.epochNext(_timestamp);
    }

    function epochVoteStart(uint256 _timestamp) external pure returns (uint256) {
        return ProtocolTimeLibrary.epochVoteStart(_timestamp);
    }

    function epochVoteEnd(uint256 _timestamp) external pure returns (uint256) {
        return ProtocolTimeLibrary.epochVoteEnd(_timestamp);
    }

    /// @dev requires initialization with at least rewardToken
    function initialize(address[] calldata _tokens, address _minter) external {
        if (_msgSender() != minter) revert NotMinter();
        uint256 _length = _tokens.length;
        for (uint256 i = 0; i < _length; i++) {
            _whitelistToken(_tokens[i], true);
        }
        minter = _minter;
    }

    /// @inheritdoc IVoter
    function setGovernor(address _governor) public {
        if (_msgSender() != governor) revert NotGovernor();
        if (_governor == address(0)) revert ZeroAddress();
        governor = _governor;
    }

    /// @inheritdoc IVoter
    function setEpochGovernor(address _epochGovernor) public {
        if (_msgSender() != governor) revert NotGovernor();
        if (_epochGovernor == address(0)) revert ZeroAddress();
        epochGovernor = _epochGovernor;
    }

    /// @inheritdoc IVoter
    function setEmergencyCouncil(address _council) public {
        if (_msgSender() != emergencyCouncil) revert NotEmergencyCouncil();
        if (_council == address(0)) revert ZeroAddress();
        emergencyCouncil = _council;
    }

    /// @inheritdoc IVoter
    function setMaxVotingNum(uint256 _maxVotingNum) external {
        if (_msgSender() != governor) revert NotGovernor();
        if (_maxVotingNum < MIN_MAXVOTINGNUM) revert MaximumVotingNumberTooLow();
        if (_maxVotingNum == maxVotingNum) revert SameValue();
        maxVotingNum = _maxVotingNum;
    }

    /// @inheritdoc IVoter
    function reset(uint256 _tokenId) external onlyNewEpoch(_tokenId) nonReentrant {
        if (!IVotingEscrow(ve).isApprovedOrOwner(msg.sender, _tokenId)) revert NotApprovedOrOwner();
        _reset(_tokenId);
    }

    function _reset(uint256 _tokenId) internal {
        address[] storage _poolVote = poolVote[_tokenId];
        uint256 _poolVoteCnt = _poolVote.length;
        uint256 _totalWeight = 0;

        for (uint256 i = 0; i < _poolVoteCnt; i++) {
            address _pool = _poolVote[i];
            uint256 _votes = votes[_tokenId][_pool];

            if (_votes != 0) {
                _updateFor(gauges[_pool]);
                weights[_pool] -= _votes;
                delete votes[_tokenId][_pool];
                IReward(gaugeToFees[gauges[_pool]])._withdraw(_votes, _tokenId);
                IReward(gaugeToBribe[gauges[_pool]])._withdraw(_votes, _tokenId);
                _totalWeight += _votes;
                emit Abstained(_msgSender(), _pool, _tokenId, _votes, weights[_pool], block.timestamp);
            }
        }
        IVotingEscrow(ve).voting(_tokenId, false);
        totalWeight -= _totalWeight;
        usedWeights[_tokenId] = 0;
        delete poolVote[_tokenId];
    }

    /// @inheritdoc IVoter
    function poke(uint256 _tokenId) external nonReentrant {
        if (block.timestamp <= ProtocolTimeLibrary.epochVoteStart(block.timestamp)) revert DistributeWindow();
        uint256 _weight = IVotingEscrow(ve).balanceOfNFT(_tokenId);
        _poke(_tokenId, _weight);
    }

    function _poke(uint256 _tokenId, uint256 _weight) internal {
        address[] memory _poolVote = poolVote[_tokenId];
        uint256 _poolCnt = _poolVote.length;
        uint256[] memory _weights = new uint256[](_poolCnt);

        for (uint256 i = 0; i < _poolCnt; i++) {
            _weights[i] = votes[_tokenId][_poolVote[i]];
        }
        _vote(_tokenId, _weight, _poolVote, _weights);
    }

    function _vote(uint256 _tokenId, uint256 _weight, address[] memory _poolVote, uint256[] memory _weights) internal {
        _reset(_tokenId);
        uint256 _poolCnt = _poolVote.length;
        uint256 _totalVoteWeight = 0;
        uint256 _totalWeight = 0;
        uint256 _usedWeight = 0;

        for (uint256 i = 0; i < _poolCnt; i++) {
            _totalVoteWeight += _weights[i];
        }

        for (uint256 i = 0; i < _poolCnt; i++) {
            address _pool = _poolVote[i];
            address _gauge = gauges[_pool];
            if (_gauge == address(0)) revert GaugeDoesNotExist(_pool);
            if (!isAlive[_gauge]) revert GaugeNotAlive(_gauge);

            if (isGauge[_gauge]) {
                uint256 _poolWeight = (_weights[i] * _weight) / _totalVoteWeight;
                if (votes[_tokenId][_pool] != 0) revert NonZeroVotes();
                if (_poolWeight == 0) revert ZeroBalance();
                _updateFor(_gauge);

                poolVote[_tokenId].push(_pool);

                weights[_pool] += _poolWeight;
                votes[_tokenId][_pool] += _poolWeight;
                IReward(gaugeToFees[_gauge])._deposit(_poolWeight, _tokenId);
                IReward(gaugeToBribe[_gauge])._deposit(_poolWeight, _tokenId);
                _usedWeight += _poolWeight;
                _totalWeight += _poolWeight;
                emit Voted(_msgSender(), _pool, _tokenId, _poolWeight, weights[_pool], block.timestamp);
            }
        }
        if (_usedWeight > 0) IVotingEscrow(ve).voting(_tokenId, true);
        totalWeight += _totalWeight;
        usedWeights[_tokenId] = _usedWeight;
    }

    /// @inheritdoc IVoter
    function vote(
        uint256 _tokenId,
        address[] calldata _poolVote,
        uint256[] calldata _weights
    ) external onlyNewEpoch(_tokenId) nonReentrant {
        address _sender = _msgSender();
        if (!IVotingEscrow(ve).isApprovedOrOwner(_sender, _tokenId)) revert NotApprovedOrOwner();
        if (_poolVote.length != _weights.length) revert UnequalLengths();
        if (_poolVote.length > maxVotingNum) revert TooManyPools();
        if (IVotingEscrow(ve).deactivated(_tokenId)) revert InactiveManagedNFT();
        uint256 _timestamp = block.timestamp;
        if ((_timestamp > ProtocolTimeLibrary.epochVoteEnd(_timestamp)) && !isWhitelistedNFT[_tokenId])
            revert NotWhitelistedNFT();
        lastVoted[_tokenId] = _timestamp;
        uint256 _weight = IVotingEscrow(ve).balanceOfNFT(_tokenId);
        _vote(_tokenId, _weight, _poolVote, _weights);
    }

    /// @inheritdoc IVoter
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external nonReentrant onlyNewEpoch(_tokenId) {
        address _sender = _msgSender();
        if (!IVotingEscrow(ve).isApprovedOrOwner(_sender, _tokenId)) revert NotApprovedOrOwner();
        if (IVotingEscrow(ve).deactivated(_mTokenId)) revert InactiveManagedNFT();
        uint256 _timestamp = block.timestamp;
        if (_timestamp > ProtocolTimeLibrary.epochVoteEnd(_timestamp)) revert SpecialVotingWindow();
        lastVoted[_tokenId] = _timestamp;
        IVotingEscrow(ve).depositManaged(_tokenId, _mTokenId);
        uint256 _weight = IVotingEscrow(ve).balanceOfNFTAt(_mTokenId, block.timestamp);
        _poke(_mTokenId, _weight);
    }

    /// @inheritdoc IVoter
    function withdrawManaged(uint256 _tokenId) external nonReentrant onlyNewEpoch(_tokenId) {
        if (!IVotingEscrow(ve).isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        uint256 _mTokenId = IVotingEscrow(ve).idToManaged(_tokenId);
        IVotingEscrow(ve).withdrawManaged(_tokenId);
        // If the NORMAL veNFT was the last tokenId locked into _mTokenId, reset vote as there is
        // no longer voting power available to the _mTokenId.  Otherwise, updating voting power to accurately
        // reflect the withdrawn voting power.
        uint256 _weight = IVotingEscrow(ve).balanceOfNFTAt(_mTokenId, block.timestamp);
        if (_weight == 0) {
            _reset(_mTokenId);
            // clear out lastVoted to allow re-voting in the current epoch
            delete lastVoted[_mTokenId];
        } else {
            _poke(_mTokenId, _weight);
        }
    }

    /// @inheritdoc IVoter
    function whitelistToken(address _token, bool _bool) external {
        if (_msgSender() != governor) revert NotGovernor();
        _whitelistToken(_token, _bool);
    }

    function _whitelistToken(address _token, bool _bool) internal {
        isWhitelistedToken[_token] = _bool;
        emit WhitelistToken(_msgSender(), _token, _bool);
    }

    /// @inheritdoc IVoter
    function whitelistNFT(uint256 _tokenId, bool _bool) external {
        address _sender = _msgSender();
        if (_sender != governor) revert NotGovernor();
        isWhitelistedNFT[_tokenId] = _bool;
        emit WhitelistNFT(_sender, _tokenId, _bool);
    }

    /// @inheritdoc IVoter
    function createGauge(address _poolFactory, address _pool) external nonReentrant returns (address) {
        address sender = _msgSender();
        if (!IFactoryRegistry(factoryRegistry).isPoolFactoryApproved(_poolFactory)) revert FactoryPathNotApproved();
        if (gauges[_pool] != address(0)) revert GaugeExists();

        (address votingRewardsFactory, address gaugeFactory) = IFactoryRegistry(factoryRegistry).factoriesToPoolFactory(
            _poolFactory
        );
        address[] memory rewards = new address[](2);
        bool isPool = IPoolFactory(_poolFactory).isPool(_pool);
        {
            // stack too deep
            address token0;
            address token1;
            if (isPool) {
                token0 = IPool(_pool).token0();
                token1 = IPool(_pool).token1();
                rewards[0] = token0;
                rewards[1] = token1;
            }

            if (sender != governor) {
                if (!isPool) revert NotAPool();
                if (!isWhitelistedToken[token0] || !isWhitelistedToken[token1]) revert NotWhitelistedToken();
            }
        }

        (address _feeVotingReward, address _bribeVotingReward) = IVotingRewardsFactory(votingRewardsFactory)
            .createRewards(forwarder, rewards);

        address _gauge = IGaugeFactory(gaugeFactory).createGauge(
            forwarder,
            _pool,
            _feeVotingReward,
            rewardToken,
            isPool
        );

        gaugeToFees[_gauge] = _feeVotingReward;
        gaugeToBribe[_gauge] = _bribeVotingReward;
        gauges[_pool] = _gauge;
        poolForGauge[_gauge] = _pool;
        isGauge[_gauge] = true;
        isAlive[_gauge] = true;
        _updateFor(_gauge);
        pools.push(_pool);

        emit GaugeCreated(
            _poolFactory,
            votingRewardsFactory,
            gaugeFactory,
            _pool,
            _bribeVotingReward,
            _feeVotingReward,
            _gauge,
            sender
        );
        return _gauge;
    }

    /// @inheritdoc IVoter
    function killGauge(address _gauge) external {
        if (_msgSender() != emergencyCouncil) revert NotEmergencyCouncil();
        if (!isAlive[_gauge]) revert GaugeAlreadyKilled();
        // Return claimable back to minter
        uint256 _claimable = claimable[_gauge];
        if (_claimable > 0) {
            IERC20(rewardToken).safeTransfer(minter, _claimable);
            delete claimable[_gauge];
        }
        isAlive[_gauge] = false;
        emit GaugeKilled(_gauge);
    }

    /// @inheritdoc IVoter
    function reviveGauge(address _gauge) external {
        if (_msgSender() != emergencyCouncil) revert NotEmergencyCouncil();
        if (isAlive[_gauge]) revert GaugeAlreadyRevived();
        isAlive[_gauge] = true;
        emit GaugeRevived(_gauge);
    }

    /// @inheritdoc IVoter
    function length() external view returns (uint256) {
        return pools.length;
    }

    /// @inheritdoc IVoter
    function notifyRewardAmount(uint256 _amount) external {
        address sender = _msgSender();
        if (sender != minter) revert NotMinter();
        IERC20(rewardToken).safeTransferFrom(sender, address(this), _amount); // transfer the distribution in
        uint256 _ratio = (_amount * 1e18) / Math.max(totalWeight, 1); // 1e18 adjustment is removed during claim
        if (_ratio > 0) {
            index += _ratio;
        }
        emit NotifyReward(sender, rewardToken, _amount);
    }

    /// @inheritdoc IVoter
    function updateFor(address[] memory _gauges) external {
        uint256 _length = _gauges.length;
        for (uint256 i = 0; i < _length; i++) {
            _updateFor(_gauges[i]);
        }
    }

    /// @inheritdoc IVoter
    function updateFor(uint256 start, uint256 end) external {
        for (uint256 i = start; i < end; i++) {
            _updateFor(gauges[pools[i]]);
        }
    }

    /// @inheritdoc IVoter
    function updateFor(address _gauge) external {
        _updateFor(_gauge);
    }

    function _updateFor(address _gauge) internal {
        address _pool = poolForGauge[_gauge];
        uint256 _supplied = weights[_pool];
        if (_supplied > 0) {
            uint256 _supplyIndex = supplyIndex[_gauge];
            uint256 _index = index; // get global index0 for accumulated distribution
            supplyIndex[_gauge] = _index; // update _gauge current position to global position
            uint256 _delta = _index - _supplyIndex; // see if there is any difference that need to be accrued
            if (_delta > 0) {
                uint256 _share = (_supplied * _delta) / 1e18; // add accrued difference for each supplied token
                if (isAlive[_gauge]) {
                    claimable[_gauge] += _share;
                } else {
                    IERC20(rewardToken).safeTransfer(minter, _share); // send rewards back to Minter so they're not stuck in Voter
                }
            }
        } else {
            supplyIndex[_gauge] = index; // new users are set to the default global state
        }
    }

    /// @inheritdoc IVoter
    function claimRewards(address[] memory _gauges) external {
        uint256 _length = _gauges.length;
        for (uint256 i = 0; i < _length; i++) {
            IGauge(_gauges[i]).getReward(_msgSender());
        }
    }

    /// @inheritdoc IVoter
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external {
        if (!IVotingEscrow(ve).isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        uint256 _length = _bribes.length;
        for (uint256 i = 0; i < _length; i++) {
            IReward(_bribes[i]).getReward(_tokenId, _tokens[i]);
        }
    }

    /// @inheritdoc IVoter
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external {
        if (!IVotingEscrow(ve).isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        uint256 _length = _fees.length;
        for (uint256 i = 0; i < _length; i++) {
            IReward(_fees[i]).getReward(_tokenId, _tokens[i]);
        }
    }

    function _distribute(address _gauge) internal {
        _updateFor(_gauge); // should set claimable to 0 if killed
        uint256 _claimable = claimable[_gauge];
        if (_claimable > IGauge(_gauge).left() && _claimable > DURATION) {
            claimable[_gauge] = 0;
            IERC20(rewardToken).safeApprove(_gauge, _claimable);
            IGauge(_gauge).notifyRewardAmount(_claimable);
            IERC20(rewardToken).safeApprove(_gauge, 0);
            emit DistributeReward(_msgSender(), _gauge, _claimable);
        }
    }

    /// @inheritdoc IVoter
    function distribute(uint256 _start, uint256 _finish) external nonReentrant {
        IMinter(minter).updatePeriod();
        for (uint256 x = _start; x < _finish; x++) {
            _distribute(gauges[pools[x]]);
        }
    }

    /// @inheritdoc IVoter
    function distribute(address[] memory _gauges) external nonReentrant {
        IMinter(minter).updatePeriod();
        uint256 _length = _gauges.length;
        for (uint256 x = 0; x < _length; x++) {
            _distribute(_gauges[x]);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IVeArtProxy {
    /// @dev Art configuration
    struct Config {
        // NFT metadata variables
        int256 _tokenId;
        int256 _balanceOf;
        int256 _lockedEnd;
        int256 _lockedAmount;
        // Line art variables
        int256 shape;
        uint256 palette;
        int256 maxLines;
        int256 dash;
        // Randomness variables
        int256 seed1;
        int256 seed2;
        int256 seed3;
    }

    /// @dev Individual line art path variables.
    struct lineConfig {
        bytes8 color;
        uint256 stroke;
        uint256 offset;
        uint256 offsetHalf;
        uint256 offsetDashSum;
        uint256 pathLength;
    }

    /// @dev Represents an (x,y) coordinate in a line.
    struct Point {
        int256 x;
        int256 y;
    }

    /// @notice Generate a SVG based on veNFT metadata
    /// @param _tokenId Unique veNFT identifier
    /// @return output SVG metadata as HTML tag
    function tokenURI(uint256 _tokenId) external view returns (string memory output);

    /// @notice Generate only the foreground <path> elements of the line art for an NFT (excluding SVG header), for flexibility purposes.
    /// @param _tokenId Unique veNFT identifier
    /// @return output Encoded output of generateShape()
    function lineArtPathsOnly(uint256 _tokenId) external view returns (bytes memory output);

    /// @notice Generate the master art config metadata for a veNFT
    /// @param _tokenId Unique veNFT identifier
    /// @return cfg Config struct
    function generateConfig(uint256 _tokenId) external view returns (Config memory cfg);

    /// @notice Generate the points for two stripe lines based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of line drawn
    /// @return Line (x, y) coordinates of the drawn stripes
    function twoStripes(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of circles drawn
    /// @return Line (x, y) coordinates of the drawn circles
    function circles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for interlocking circles based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of interlocking circles drawn
    /// @return Line (x, y) coordinates of the drawn interlocking circles
    function interlockingCircles(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for corners based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of corners drawn
    /// @return Line (x, y) coordinates of the drawn corners
    function corners(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a curve based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of curve drawn
    /// @return Line (x, y) coordinates of the drawn curve
    function curves(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a spiral based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of spiral drawn
    /// @return Line (x, y) coordinates of the drawn spiral
    function spiral(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for an explosion based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of explosion drawn
    /// @return Line (x, y) coordinates of the drawn explosion
    function explosion(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);

    /// @notice Generate the points for a wormhole based on the config generated for a veNFT
    /// @param cfg Master art config metadata of a veNFT
    /// @param l Number of wormhole drawn
    /// @return Line (x, y) coordinates of the drawn wormhole
    function wormhole(Config memory cfg, int256 l) external pure returns (Point[100] memory Line);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// OpenZeppelin Contracts (interfaces/IERC6372.sol)

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

/// Modified IVotes interface for tokenId based voting
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, uint256 indexed fromDelegate, uint256 indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the amount of votes that `tokenId` had at a specific moment in the past.
     *      If the account passed in is not the owner, returns 0.
     */
    function getPastVotes(address account, uint256 tokenId, uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at a specific moment in the past. If the `clock()` is
     * configured to use block numbers, this will return the value the end of the corresponding block.
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 timepoint) external view returns (uint256);

    /**
     * @dev Returns the delegate that `tokenId` has chosen. Can never be equal to the delegator's `tokenId`.
     *      Returns 0 if not delegated.
     */
    function delegates(uint256 tokenId) external view returns (uint256);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(uint256 delegator, uint256 delegatee) external;

    /**
     * @dev Delegates votes from `delegator` to `delegatee`. Signer must own `delegator`.
     */
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IVotingEscrow is IVotes, IERC4906, IERC6372, IERC721Metadata {
    struct LockedBalance {
        int128 amount;
        uint256 end;
        bool isPermanent;
    }

    struct UserPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanent;
    }

    struct GlobalPoint {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
        uint256 permanentLockBalance;
    }

    /// @notice A checkpoint for recorded delegated voting weights at a certain timestamp
    struct Checkpoint {
        uint256 fromTimestamp;
        address owner;
        uint256 delegatedBalance;
        uint256 delegatee;
    }

    enum DepositType {
        DEPOSIT_FOR_TYPE,
        CREATE_LOCK_TYPE,
        INCREASE_LOCK_AMOUNT,
        INCREASE_UNLOCK_TIME
    }

    /// @dev Different types of veNFTs:
    /// NORMAL  - typical veNFT
    /// LOCKED  - veNFT which is locked into a MANAGED veNFT
    /// MANAGED - veNFT which can accept the deposit of NORMAL veNFTs
    enum EscrowType {
        NORMAL,
        LOCKED,
        MANAGED
    }

    error AlreadyVoted();
    error AmountTooBig();
    error ERC721ReceiverRejectedTokens();
    error ERC721TransferToNonERC721ReceiverImplementer();
    error InvalidNonce();
    error InvalidSignature();
    error InvalidSignatureS();
    error InvalidManagedNFTId();
    error LockDurationNotInFuture();
    error LockDurationTooLong();
    error LockExpired();
    error LockNotExpired();
    error NoLockFound();
    error NonExistentToken();
    error NotApprovedOrOwner();
    error NotDistributor();
    error NotEmergencyCouncilOrGovernor();
    error NotGovernor();
    error NotGovernorOrManager();
    error NotManagedNFT();
    error NotManagedOrNormalNFT();
    error NotLockedNFT();
    error NotNormalNFT();
    error NotPermanentLock();
    error NotOwner();
    error NotTeam();
    error NotVoter();
    error OwnershipChange();
    error PermanentLock();
    error SameAddress();
    error SameNFT();
    error SameState();
    error SplitNoOwner();
    error SplitNotAllowed();
    error SignatureExpired();
    error TooManyTokenIDs();
    error ZeroAddress();
    error ZeroAmount();
    error ZeroBalance();

    event Deposit(
        address indexed provider,
        uint256 indexed tokenId,
        DepositType indexed depositType,
        uint256 value,
        uint256 locktime,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 indexed tokenId, uint256 value, uint256 ts);
    event LockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event UnlockPermanent(address indexed _owner, uint256 indexed _tokenId, uint256 amount, uint256 _ts);
    event Supply(uint256 prevSupply, uint256 supply);
    event Merge(
        address indexed _sender,
        uint256 indexed _from,
        uint256 indexed _to,
        uint256 _amountFrom,
        uint256 _amountTo,
        uint256 _amountFinal,
        uint256 _locktime,
        uint256 _ts
    );
    event Split(
        uint256 indexed _from,
        uint256 indexed _tokenId1,
        uint256 indexed _tokenId2,
        address _sender,
        uint256 _splitAmount1,
        uint256 _splitAmount2,
        uint256 _locktime,
        uint256 _ts
    );
    event CreateManaged(
        address indexed _to,
        uint256 indexed _mTokenId,
        address indexed _from,
        address _lockedManagedReward,
        address _freeManagedReward
    );
    event DepositManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event WithdrawManaged(
        address indexed _owner,
        uint256 indexed _tokenId,
        uint256 indexed _mTokenId,
        uint256 _weight,
        uint256 _ts
    );
    event SetAllowedManager(address indexed _allowedManager);

    // State variables
    /// @notice Address of Meta-tx Forwarder
    function forwarder() external view returns (address);

    /// @notice Address of FactoryRegistry.sol
    function factoryRegistry() external view returns (address);

    /// @notice Address of token (PRFCT) used to create a veNFT
    function token() external view returns (address);

    /// @notice Address of RewardsDistributor.sol
    function distributor() external view returns (address);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of Protocol Team multisig
    function team() external view returns (address);

    /// @notice Address of art proxy used for on-chain art generation
    function artProxy() external view returns (address);

    /// @dev address which can create managed NFTs
    function allowedManager() external view returns (address);

    /// @dev Current count of token
    function tokenId() external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping of token id to escrow type
    ///      Takes advantage of the fact default value is EscrowType.NORMAL
    function escrowType(uint256 tokenId) external view returns (EscrowType);

    /// @dev Mapping of token id to managed id
    function idToManaged(uint256 tokenId) external view returns (uint256 managedTokenId);

    /// @dev Mapping of user token id to managed token id to weight of token id
    function weights(uint256 tokenId, uint256 managedTokenId) external view returns (uint256 weight);

    /// @dev Mapping of managed id to deactivated state
    function deactivated(uint256 tokenId) external view returns (bool inactive);

    /// @dev Mapping from managed nft id to locked managed rewards
    ///      `token` denominated rewards (rebases/rewards) stored in locked managed rewards contract
    ///      to prevent co-mingling of assets
    function managedToLocked(uint256 tokenId) external view returns (address);

    /// @dev Mapping from managed nft id to free managed rewards contract
    ///      these rewards can be freely withdrawn by users
    function managedToFree(uint256 tokenId) external view returns (address);

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Create managed NFT (a permanent lock) for use within ecosystem.
    /// @dev Throws if address already owns a managed NFT.
    /// @return _mTokenId managed token id.
    function createManagedLockFor(address _to) external returns (uint256 _mTokenId);

    /// @notice Delegates balance to managed nft
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    ///         Permanent locks that are deposited will automatically unlock.
    /// @dev Managed nft will remain max-locked as long as there is at least one
    ///      deposit or withdrawal per week.
    ///      Throws if deposit nft is managed.
    ///      Throws if recipient nft is not managed.
    ///      Throws if deposit nft is already locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited
    /// @param _mTokenId tokenId of managed NFT that will receive the deposit
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Retrieves locked rewards and withdraws balance from managed nft.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    /// @dev Throws if NFT not locked.
    ///      Throws if not called by voter.
    /// @param _tokenId tokenId of NFT being deposited.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Permit one address to call createManagedLockFor() that is not Voter.governor()
    function setAllowedManager(address _allowedManager) external;

    /// @notice Set Managed NFT state. Inactive NFTs cannot be deposited into.
    /// @param _mTokenId managed nft state to set
    /// @param _state true => inactive, false => active
    function setManagedState(uint256 _mTokenId, bool _state) external;

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function setTeam(address _team) external;

    function setArtProxy(address _proxy) external;

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from owner address to mapping of index to tokenId
    function ownerToNFTokenIdList(address _owner, uint256 _index) external view returns (uint256 _tokenId);

    /// @inheritdoc IERC721
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @inheritdoc IERC721
    function balanceOf(address owner) external view returns (uint256 balance);

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function getApproved(uint256 _tokenId) external view returns (address operator);

    /// @inheritdoc IERC721
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @notice Check whether spender is owner or an approved user for a given veNFT
    /// @param _spender .
    /// @param _tokenId .
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external returns (bool);

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC721
    function approve(address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external;

    /// @inheritdoc IERC721
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @inheritdoc IERC721
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total count of epochs witnessed since contract creation
    function epoch() external view returns (uint256);

    /// @notice Total amount of token() deposited
    function supply() external view returns (uint256);

    /// @notice Aggregate permanent locked balances
    function permanentLockBalance() external view returns (uint256);

    function userPointEpoch(uint256 _tokenId) external view returns (uint256 _epoch);

    /// @notice time -> signed slope change
    function slopeChanges(uint256 _timestamp) external view returns (int128);

    /// @notice account -> can split
    function canSplit(address _account) external view returns (bool);

    /// @notice Global point history at a given index
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory);

    /// @notice Get the LockedBalance (amount, end) of a _tokenId
    /// @param _tokenId .
    /// @return LockedBalance of _tokenId
    function locked(uint256 _tokenId) external view returns (LockedBalance memory);

    /// @notice User -> UserPoint[userEpoch]
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory);

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global data to checkpoint
    function checkpoint() external;

    /// @notice Deposit `_value` tokens for `_tokenId` and add to the lock
    /// @dev Anyone (even a smart contract) can deposit for someone else, but
    ///      cannot extend their locktime and deposit for a brand new user
    /// @param _tokenId lock NFT
    /// @param _value Amount to add to user's lock
    function depositFor(uint256 _tokenId, uint256 _value) external;

    /// @notice Deposit `_value` tokens for `msg.sender` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @return TokenId of created veNFT
    function createLock(uint256 _value, uint256 _lockDuration) external returns (uint256);

    /// @notice Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    /// @return TokenId of created veNFT
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external returns (uint256);

    /// @notice Deposit `_value` additional tokens for `_tokenId` without modifying the unlock time
    /// @param _value Amount of tokens to deposit and add to the lock
    function increaseAmount(uint256 _tokenId, uint256 _value) external;

    /// @notice Extend the unlock time for `_tokenId`
    ///         Cannot extend lock time of permanent locks
    /// @param _lockDuration New number of seconds until tokens unlock
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external;

    /// @notice Withdraw all tokens for `_tokenId`
    /// @dev Only possible if the lock is both expired and not permanent
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    function withdraw(uint256 _tokenId) external;

    /// @notice Merges `_from` into `_to`.
    /// @dev Cannot merge `_from` locks that are permanent or have already voted this epoch.
    ///      Cannot merge `_to` locks that have already expired.
    ///      This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///      will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to merge from.
    /// @param _to VeNFT to merge into.
    function merge(uint256 _from, uint256 _to) external;

    /// @notice Splits veNFT into two new veNFTS - one with oldLocked.amount - `_amount`, and the second with `_amount`
    /// @dev    This burns the tokenId of the target veNFT
    ///         Callable by approved or owner
    ///         If this is called by approved, approved will not have permissions to manipulate the newly created veNFTs
    ///         Returns the two new split veNFTs to owner
    ///         If `from` is permanent, will automatically dedelegate.
    ///         This will burn the veNFT. Any rebases or rewards that are unclaimed
    ///         will no longer be claimable. Claim all rebases and rewards prior to calling this.
    /// @param _from VeNFT to split.
    /// @param _amount Amount to split from veNFT.
    /// @return _tokenId1 Return tokenId of veNFT with oldLocked.amount - `_amount`.
    /// @return _tokenId2 Return tokenId of veNFT with `_amount`.
    function split(uint256 _from, uint256 _amount) external returns (uint256 _tokenId1, uint256 _tokenId2);

    /// @notice Toggle split for a specific address.
    /// @dev Toggle split for address(0) to enable or disable for all.
    /// @param _account Address to toggle split permissions
    /// @param _bool True to allow, false to disallow
    function toggleSplit(address _account, bool _bool) external;

    /// @notice Permanently lock a veNFT. Voting power will be equal to
    ///         `LockedBalance.amount` with no decay. Required to delegate.
    /// @dev Only callable by unlocked normal veNFTs.
    /// @param _tokenId tokenId to lock.
    function lockPermanent(uint256 _tokenId) external;

    /// @notice Unlock a permanently locked veNFT. Voting power will decay.
    ///         Will automatically dedelegate if delegated.
    /// @dev Only callable by permanently locked veNFTs.
    ///      Cannot unlock if already voted this epoch.
    /// @param _tokenId tokenId to unlock.
    function unlockPermanent(uint256 _tokenId) external;

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Get the voting power for _tokenId at the current timestamp
    /// @dev Returns 0 if called in the same block as a transfer.
    /// @param _tokenId .
    /// @return Voting power
    function balanceOfNFT(uint256 _tokenId) external view returns (uint256);

    /// @notice Get the voting power for _tokenId at a given timestamp
    /// @param _tokenId .
    /// @param _t Timestamp to query voting power
    /// @return Voting power
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256);

    /// @notice Calculate total voting power at current timestamp
    /// @return Total voting power at current timestamp
    function totalSupply() external view returns (uint256);

    /// @notice Calculate total voting power at a given timestamp
    /// @param _t Timestamp to query total voting power
    /// @return Total voting power at given timestamp
    function totalSupplyAt(uint256 _t) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice See if a queried _tokenId has actively voted
    /// @param _tokenId .
    /// @return True if voted, else false
    function voted(uint256 _tokenId) external view returns (bool);

    /// @notice Set the global state voter and distributor
    /// @dev This is only called once, at setup
    function setVoterAndDistributor(address _voter, address _distributor) external;

    /// @notice Set `voted` for _tokenId to true or false
    /// @dev Only callable by voter
    /// @param _tokenId .
    /// @param _voted .
    function voting(uint256 _tokenId, bool _voted) external;

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The number of checkpoints for each tokenId
    function numCheckpoints(uint256 tokenId) external view returns (uint48);

    /// @notice A record of states for signing / validating signatures
    function nonces(address account) external view returns (uint256);

    /// @inheritdoc IVotes
    function delegates(uint256 delegator) external view returns (uint256);

    /// @notice A record of delegated token checkpoints for each account, by index
    /// @param tokenId .
    /// @param index .
    /// @return Checkpoint
    function checkpoints(uint256 tokenId, uint48 index) external view returns (Checkpoint memory);

    /// @inheritdoc IVotes
    function getPastVotes(address account, uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @inheritdoc IVotes
    function getPastTotalSupply(uint256 timestamp) external view returns (uint256);

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotes
    function delegate(uint256 delegator, uint256 delegatee) external;

    /// @inheritdoc IVotes
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IERC6372
    function clock() external view returns (uint48);

    /// @inheritdoc IERC6372
    function CLOCK_MODE() external view returns (string memory);
}

interface IVoter {
    error AlreadyVotedOrDeposited();
    error DistributeWindow();
    error FactoryPathNotApproved();
    error GaugeAlreadyKilled();
    error GaugeAlreadyRevived();
    error GaugeExists();
    error GaugeDoesNotExist(address _pool);
    error GaugeNotAlive(address _gauge);
    error InactiveManagedNFT();
    error MaximumVotingNumberTooLow();
    error NonZeroVotes();
    error NotAPool();
    error NotApprovedOrOwner();
    error NotGovernor();
    error NotEmergencyCouncil();
    error NotMinter();
    error NotWhitelistedNFT();
    error NotWhitelistedToken();
    error SameValue();
    error SpecialVotingWindow();
    error TooManyPools();
    error UnequalLengths();
    error ZeroBalance();
    error ZeroAddress();

    event GaugeCreated(
        address indexed poolFactory,
        address indexed votingRewardsFactory,
        address indexed gaugeFactory,
        address pool,
        address bribeVotingReward,
        address feeVotingReward,
        address gauge,
        address creator
    );
    event GaugeKilled(address indexed gauge);
    event GaugeRevived(address indexed gauge);
    event Voted(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event Abstained(
        address indexed voter,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 weight,
        uint256 totalWeight,
        uint256 timestamp
    );
    event NotifyReward(address indexed sender, address indexed reward, uint256 amount);
    event DistributeReward(address indexed sender, address indexed gauge, uint256 amount);
    event WhitelistToken(address indexed whitelister, address indexed token, bool indexed _bool);
    event WhitelistNFT(address indexed whitelister, uint256 indexed tokenId, bool indexed _bool);

    /// @notice Store trusted forwarder address to pass into factories
    function forwarder() external view returns (address);

    /// @notice The ve token that governs these contracts
    function ve() external view returns (address);

    /// @notice Factory registry for valid pool / gauge / rewards factories
    function factoryRegistry() external view returns (address);

    /// @notice Address of Minter.sol
    function minter() external view returns (address);

    /// @notice Standard OZ IGovernor using ve for vote weights.
    function governor() external view returns (address);

    /// @notice Custom Epoch Governor using ve for vote weights.
    function epochGovernor() external view returns (address);

    /// @notice credibly neutral party similar to Curve's Emergency DAO
    function emergencyCouncil() external view returns (address);

    /// @dev Total Voting Weights
    function totalWeight() external view returns (uint256);

    /// @dev Most number of pools one voter can vote for at once
    function maxVotingNum() external view returns (uint256);

    // mappings
    /// @dev Pool => Gauge
    function gauges(address pool) external view returns (address);

    /// @dev Gauge => Pool
    function poolForGauge(address gauge) external view returns (address);

    /// @dev Gauge => Fees Voting Reward
    function gaugeToFees(address gauge) external view returns (address);

    /// @dev Gauge => Bribes Voting Reward
    function gaugeToBribe(address gauge) external view returns (address);

    /// @dev Pool => Weights
    function weights(address pool) external view returns (uint256);

    /// @dev NFT => Pool => Votes
    function votes(uint256 tokenId, address pool) external view returns (uint256);

    /// @dev NFT => Total voting weight of NFT
    function usedWeights(uint256 tokenId) external view returns (uint256);

    /// @dev Nft => Timestamp of last vote (ensures single vote per epoch)
    function lastVoted(uint256 tokenId) external view returns (uint256);

    /// @dev Address => Gauge
    function isGauge(address) external view returns (bool);

    /// @dev Token => Whitelisted status
    function isWhitelistedToken(address token) external view returns (bool);

    /// @dev TokenId => Whitelisted status
    function isWhitelistedNFT(uint256 tokenId) external view returns (bool);

    /// @dev Gauge => Liveness status
    function isAlive(address gauge) external view returns (bool);

    /// @dev Gauge => Amount claimable
    function claimable(address gauge) external view returns (uint256);

    /// @notice Number of pools with a Gauge
    function length() external view returns (uint256);

    /// @notice Called by Minter to distribute weekly emissions rewards for disbursement amongst gauges.
    /// @dev Assumes totalWeight != 0 (Will never be zero as long as users are voting).
    ///      Throws if not called by minter.
    /// @param _amount Amount of rewards to distribute.
    function notifyRewardAmount(uint256 _amount) external;

    /// @dev Utility to distribute to gauges of pools in range _start to _finish.
    /// @param _start   Starting index of gauges to distribute to.
    /// @param _finish  Ending index of gauges to distribute to.
    function distribute(uint256 _start, uint256 _finish) external;

    /// @dev Utility to distribute to gauges of pools in array.
    /// @param _gauges Array of gauges to distribute to.
    function distribute(address[] memory _gauges) external;

    /// @notice Called by users to update voting balances in voting rewards contracts.
    /// @param _tokenId Id of veNFT whose balance you wish to update.
    function poke(uint256 _tokenId) external;

    /// @notice Called by users to vote for pools. Votes distributed proportionally based on weights.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Can only vote for gauges that have not been killed.
    /// @dev Weights are distributed proportional to the sum of the weights in the array.
    ///      Throws if length of _poolVote and _weights do not match.
    /// @param _tokenId     Id of veNFT you are voting with.
    /// @param _poolVote    Array of pools you are voting for.
    /// @param _weights     Weights of pools.
    function vote(uint256 _tokenId, address[] calldata _poolVote, uint256[] calldata _weights) external;

    /// @notice Called by users to reset voting state. Required if you wish to make changes to
    ///         veNFT state (e.g. merge, split, deposit into managed etc).
    ///         Cannot reset in the same epoch that you voted in.
    ///         Can vote or deposit into a managed NFT again after reset.
    /// @param _tokenId Id of veNFT you are reseting.
    function reset(uint256 _tokenId) external;

    /// @notice Called by users to deposit into a managed NFT.
    ///         Can only vote or deposit into a managed NFT once per epoch.
    ///         Note that NFTs deposited into a managed NFT will be re-locked
    ///         to the maximum lock time on withdrawal.
    /// @dev Throws if not approved or owner.
    ///      Throws if managed NFT is inactive.
    ///      Throws if depositing within privileged window (one hour prior to epoch flip).
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external;

    /// @notice Called by users to withdraw from a managed NFT.
    ///         Cannot do it in the same epoch that you deposited into a managed NFT.
    ///         Can vote or deposit into a managed NFT again after withdrawing.
    ///         Note that the NFT withdrawn is re-locked to the maximum lock time.
    function withdrawManaged(uint256 _tokenId) external;

    /// @notice Claim emissions from gauges.
    /// @param _gauges Array of gauges to collect emissions from.
    function claimRewards(address[] memory _gauges) external;

    /// @notice Claim bribes for a given NFT.
    /// @dev Utility to help batch bribe claims.
    /// @param _bribes  Array of BribeVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as bribes.
    /// @param _tokenId Id of veNFT that you wish to claim bribes for.
    function claimBribes(address[] memory _bribes, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Claim fees for a given NFT.
    /// @dev Utility to help batch fee claims.
    /// @param _fees    Array of FeesVotingReward contracts to collect from.
    /// @param _tokens  Array of tokens that are used as fees.
    /// @param _tokenId Id of veNFT that you wish to claim fees for.
    function claimFees(address[] memory _fees, address[][] memory _tokens, uint256 _tokenId) external;

    /// @notice Set new governor.
    /// @dev Throws if not called by governor.
    /// @param _governor .
    function setGovernor(address _governor) external;

    /// @notice Set new epoch based governor.
    /// @dev Throws if not called by governor.
    /// @param _epochGovernor .
    function setEpochGovernor(address _epochGovernor) external;

    /// @notice Set new emergency council.
    /// @dev Throws if not called by emergency council.
    /// @param _emergencyCouncil .
    function setEmergencyCouncil(address _emergencyCouncil) external;

    /// @notice Set maximum number of gauges that can be voted for.
    /// @dev Throws if not called by governor.
    ///      Throws if _maxVotingNum is too low.
    ///      Throws if the values are the same.
    /// @param _maxVotingNum .
    function setMaxVotingNum(uint256 _maxVotingNum) external;

    /// @notice Whitelist (or unwhitelist) token for use in bribes.
    /// @dev Throws if not called by governor.
    /// @param _token .
    /// @param _bool .
    function whitelistToken(address _token, bool _bool) external;

    /// @notice Whitelist (or unwhitelist) token id for voting in last hour prior to epoch flip.
    /// @dev Throws if not called by governor.
    ///      Throws if already whitelisted.
    /// @param _tokenId .
    /// @param _bool .
    function whitelistNFT(uint256 _tokenId, bool _bool) external;

    /// @notice Create a new gauge (unpermissioned).
    /// @dev Governor can create a new gauge for a pool with any address.
    /// @param _poolFactory .
    /// @param _pool .
    function createGauge(address _poolFactory, address _pool) external returns (address);

    /// @notice Kills a gauge. The gauge will not receive any new emissions and cannot be deposited into.
    ///         Can still withdraw from gauge.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge already killed.
    /// @param _gauge .
    function killGauge(address _gauge) external;

    /// @notice Revives a killed gauge. Gauge will can receive emissions and deposits again.
    /// @dev Throws if not called by emergency council.
    ///      Throws if gauge is not killed.
    /// @param _gauge .
    function reviveGauge(address _gauge) external;

    /// @dev Update claims to emissions for an array of gauges.
    /// @param _gauges Array of gauges to update emissions for.
    function updateFor(address[] memory _gauges) external;

    /// @dev Update claims to emissions for gauges based on their pool id as stored in Voter.
    /// @param _start   Starting index of pools.
    /// @param _end     Ending index of pools.
    function updateFor(uint256 _start, uint256 _end) external;

    /// @dev Update claims to emissions for single gauge
    /// @param _gauge .
    function updateFor(address _gauge) external;
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IReward {
    error InvalidReward();
    error NotAuthorized();
    error NotGauge();
    error NotEscrowToken();
    error NotSingleToken();
    error NotVotingEscrow();
    error NotWhitelisted();
    error ZeroAmount();

    event Deposit(address indexed from, uint256 indexed tokenId, uint256 amount);
    event Withdraw(address indexed from, uint256 indexed tokenId, uint256 amount);
    event NotifyReward(address indexed from, address indexed reward, uint256 indexed epoch, uint256 amount);
    event ClaimRewards(address indexed from, address indexed reward, uint256 amount);

    /// @notice A checkpoint for marking balance
    struct Checkpoint {
        uint256 timestamp;
        uint256 balanceOf;
    }

    /// @notice A checkpoint for marking supply
    struct SupplyCheckpoint {
        uint256 timestamp;
        uint256 supply;
    }

    /// @notice Epoch duration constant (7 days)
    function DURATION() external view returns (uint256);

    /// @notice Address of Voter.sol
    function voter() external view returns (address);

    /// @notice Address of VotingEscrow.sol
    function ve() external view returns (address);

    /// @dev Address which has permission to externally call _deposit() & _withdraw()
    function authorized() external view returns (address);

    /// @notice Total amount currently deposited via _deposit()
    function totalSupply() external view returns (uint256);

    /// @notice Current amount deposited by tokenId
    function balanceOf(uint256 tokenId) external view returns (uint256);

    /// @notice Amount of tokens to reward depositors for a given epoch
    /// @param token Address of token to reward
    /// @param epochStart Startime of rewards epoch
    /// @return Amount of token
    function tokenRewardsPerEpoch(address token, uint256 epochStart) external view returns (uint256);

    /// @notice Most recent timestamp a veNFT has claimed their rewards
    /// @param  token Address of token rewarded
    /// @param tokenId veNFT unique identifier
    /// @return Timestamp
    function lastEarn(address token, uint256 tokenId) external view returns (uint256);

    /// @notice True if a token is or has been an active reward token, else false
    function isReward(address token) external view returns (bool);

    /// @notice The number of checkpoints for each tokenId deposited
    function numCheckpoints(uint256 tokenId) external view returns (uint256);

    /// @notice The total number of checkpoints
    function supplyNumCheckpoints() external view returns (uint256);

    /// @notice Deposit an amount into the rewards contract to earn future rewards associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _deposit(uint256 amount, uint256 tokenId) external;

    /// @notice Withdraw an amount from the rewards contract associated to a veNFT
    /// @dev Internal notation used as only callable internally by `authorized`.
    /// @param amount   Amount deposited for the veNFT
    /// @param tokenId  Unique identifier of the veNFT
    function _withdraw(uint256 amount, uint256 tokenId) external;

    /// @notice Claim the rewards earned by a veNFT staker
    /// @param tokenId  Unique identifier of the veNFT
    /// @param tokens   Array of tokens to claim rewards of
    function getReward(uint256 tokenId, address[] memory tokens) external;

    /// @notice Add rewards for stakers to earn
    /// @param token    Address of token to reward
    /// @param amount   Amount of token to transfer to rewards
    function notifyRewardAmount(address token, uint256 amount) external;

    /// @notice Determine the prior balance for an account as of a block number
    /// @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
    /// @param tokenId      The token of the NFT to check
    /// @param timestamp    The timestamp to get the balance at
    /// @return The balance the account had as of the given block
    function getPriorBalanceIndex(uint256 tokenId, uint256 timestamp) external view returns (uint256);

    /// @notice Determine the prior index of supply staked by of a timestamp
    /// @dev Timestamp must be <= current timestamp
    /// @param timestamp The timestamp to get the index at
    /// @return Index of supply checkpoint
    function getPriorSupplyIndex(uint256 timestamp) external view returns (uint256);

    /// @notice Get number of rewards tokens
    function rewardsListLength() external view returns (uint256);

    /// @notice Calculate how much in rewards are earned for a specific token and veNFT
    /// @param token Address of token to fetch rewards of
    /// @param tokenId Unique identifier of the veNFT
    /// @return Amount of token earned in rewards
    function earned(address token, uint256 tokenId) external view returns (uint256);
}

interface IFactoryRegistry {
    error FallbackFactory();
    error InvalidFactoriesToPoolFactory();
    error PathAlreadyApproved();
    error PathNotApproved();
    error SameAddress();
    error ZeroAddress();

    event Approve(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event Unapprove(address indexed poolFactory, address indexed votingRewardsFactory, address indexed gaugeFactory);
    event SetManagedRewardsFactory(address indexed _newRewardsFactory);

    /// @notice Approve a set of factories used in the Protocol.
    ///         Router.sol is able to swap any poolFactories currently approved.
    ///         Cannot approve address(0) factories.
    ///         Cannot aprove path that is already approved.
    ///         Each poolFactory has one unique set and maintains state.  In the case a poolFactory is unapproved
    ///             and then re-approved, the same set of factories must be used.  In other words, you cannot overwrite
    ///             the factories tied to a poolFactory address.
    ///         VotingRewardsFactories and GaugeFactories may use the same address across multiple poolFactories.
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    /// @param votingRewardsFactory .
    /// @param gaugeFactory .
    function approve(address poolFactory, address votingRewardsFactory, address gaugeFactory) external;

    /// @notice Unapprove a set of factories used in the Protocol.
    ///         While a poolFactory is unapproved, Router.sol cannot swap with pools made from the corresponding factory
    ///         Can only unapprove an approved path.
    ///         Cannot unapprove the fallback path (core v2 factories).
    /// @dev Callable by onlyOwner
    /// @param poolFactory .
    function unapprove(address poolFactory) external;

    /// @notice Factory to create free and locked rewards for a managed veNFT
    function managedRewardsFactory() external view returns (address);

    /// @notice Set the rewards factory address
    /// @dev Callable by onlyOwner
    /// @param _newManagedRewardsFactory address of new managedRewardsFactory
    function setManagedRewardsFactory(address _newManagedRewardsFactory) external;

    /// @notice Get the factories correlated to a poolFactory.
    ///         Once set, this can never be modified.
    ///         Returns the correlated factories even after an approved poolFactory is unapproved.
    function factoriesToPoolFactory(
        address poolFactory
    ) external view returns (address votingRewardsFactory, address gaugeFactory);

    /// @notice Get all PoolFactories approved by the registry
    /// @dev The same PoolFactory address cannot be used twice
    /// @return Array of PoolFactory addresses
    function poolFactories() external view returns (address[] memory);

    /// @notice Check if a PoolFactory is approved within the factory registry.  Router uses this method to
    ///         ensure a pool swapped from is approved.
    /// @param poolFactory .
    /// @return True if PoolFactory is approved, else false
    function isPoolFactoryApproved(address poolFactory) external view returns (bool);

    /// @notice Get the length of the poolFactories array
    function poolFactoriesLength() external view returns (uint256);
}

interface IManagedRewardsFactory {
    event ManagedRewardCreated(
        address indexed voter,
        address indexed lockedManagedReward,
        address indexed freeManagedReward
    );

    /// @notice creates a LockedManagedReward and a FreeManagedReward contract for a managed veNFT
    /// @param _forwarder Address of trusted forwarder
    /// @param _voter Address of Voter.sol
    /// @return lockedManagedReward Address of LockedManagedReward contract created
    /// @return freeManagedReward   Address of FreeManagedReward contract created
    function createRewards(
        address _forwarder,
        address _voter
    ) external returns (address lockedManagedReward, address freeManagedReward);
}

// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

/// @title SafeCast Library
/// @author perfectswap.io
/// @notice Safely convert unsigned and signed integers without overflow / underflow
library SafeCastLibrary {
    error SafeCastOverflow();
    error SafeCastUnderflow();

    /// @dev Safely convert uint256 to int128
    function toInt128(uint256 value) internal pure returns (int128) {
        if (value > uint128(type(int128).max)) revert SafeCastOverflow();
        return int128(uint128(value));
    }

    /// @dev Safely convert int128 to uint256
    function toUint256(int128 value) internal pure returns (uint256) {
        if (value < 0) revert SafeCastUnderflow();
        return uint256(int256(value));
    }
}

library DelegationLogicLibrary {
    using SafeCastLibrary for int128;

    /// @notice Used by `_mint`, `_transferFrom`, `_burn` and `delegate`
    ///         to update delegator voting checkpoints.
    ///         Automatically dedelegates, then updates checkpoint.
    /// @dev This function depends on `_locked` and must be called prior to token state changes.
    ///      If you wish to dedelegate only, use `_delegate(tokenId, 0)` instead.
    /// @param _locked State of all locked balances
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _delegates State of all user delegatees
    /// @param _delegator The delegator to update checkpoints for
    /// @param _delegatee The new delegatee for the delegator. Cannot be equal to `_delegator` (use 0 instead).
    /// @param _owner The new (or current) owner for the delegator
    function checkpointDelegator(
        mapping(uint256 => IVotingEscrow.LockedBalance) storage _locked,
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        mapping(uint256 => uint256) storage _delegates,
        uint256 _delegator,
        uint256 _delegatee,
        address _owner
    ) external {
        uint256 delegatedBalance = _locked[_delegator].amount.toUint256();
        uint48 numCheckpoint = _numCheckpoints[_delegator];
        IVotingEscrow.Checkpoint storage cpOld = numCheckpoint > 0
            ? _checkpoints[_delegator][numCheckpoint - 1]
            : _checkpoints[_delegator][0];
        // Dedelegate from delegatee if delegated
        checkpointDelegatee(_numCheckpoints, _checkpoints, cpOld.delegatee, delegatedBalance, false);
        IVotingEscrow.Checkpoint storage cp = _checkpoints[_delegator][numCheckpoint];
        cp.fromTimestamp = block.timestamp;
        cp.delegatedBalance = cpOld.delegatedBalance;
        cp.delegatee = _delegatee;
        cp.owner = _owner;

        if (_isCheckpointInNewBlock(_numCheckpoints, _checkpoints, _delegator)) {
            _numCheckpoints[_delegator]++;
        } else {
            _checkpoints[_delegator][numCheckpoint - 1] = cp;
            delete _checkpoints[_delegator][numCheckpoint];
        }

        _delegates[_delegator] = _delegatee;
    }

    /// @notice Update delegatee's `delegatedBalance` by `balance`.
    ///         Only updates if delegating to a new delegatee.
    /// @dev If used with `balance` == `_locked[_tokenId].amount`, then this is the same as
    ///      delegating or dedelegating from `_tokenId`
    ///      If used with `balance` < `_locked[_tokenId].amount`, then this is used to adjust
    ///      `delegatedBalance` when a user's balance is modified (e.g. `increaseAmount`, `merge` etc).
    ///      If `delegatee` is 0 (i.e. user is not delegating), then do nothing.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _delegatee The delegatee's tokenId
    /// @param balance_ The delta in balance change
    /// @param _increase True if balance is increasing, false if decreasing
    function checkpointDelegatee(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _delegatee,
        uint256 balance_,
        bool _increase
    ) public {
        if (_delegatee == 0) return;
        uint48 numCheckpoint = _numCheckpoints[_delegatee];
        IVotingEscrow.Checkpoint storage cpOld = numCheckpoint > 0
            ? _checkpoints[_delegatee][numCheckpoint - 1]
            : _checkpoints[_delegatee][0];
        IVotingEscrow.Checkpoint storage cp = _checkpoints[_delegatee][numCheckpoint];
        cp.fromTimestamp = block.timestamp;
        cp.owner = cpOld.owner;
        // do not expect balance_ > cpOld.delegatedBalance when decrementing but just in case
        cp.delegatedBalance = _increase
            ? cpOld.delegatedBalance + balance_
            : (balance_ < cpOld.delegatedBalance ? cpOld.delegatedBalance - balance_ : 0);
        cp.delegatee = cpOld.delegatee;

        if (_isCheckpointInNewBlock(_numCheckpoints, _checkpoints, _delegatee)) {
            _numCheckpoints[_delegatee]++;
        } else {
            _checkpoints[_delegatee][numCheckpoint - 1] = cp;
            delete _checkpoints[_delegatee][numCheckpoint];
        }
    }

    function _isCheckpointInNewBlock(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _tokenId
    ) internal view returns (bool) {
        uint48 _nCheckPoints = _numCheckpoints[_tokenId];

        if (_nCheckPoints > 0 && _checkpoints[_tokenId][_nCheckPoints - 1].fromTimestamp == block.timestamp) {
            return false;
        } else {
            return true;
        }
    }

    /// @notice Binary search to get the voting checkpoint for a token id at or prior to a given timestamp.
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return The index of the checkpoint.
    function getPastVotesIndex(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal view returns (uint48) {
        uint48 nCheckpoints = _numCheckpoints[_tokenId];
        if (nCheckpoints == 0) return 0;
        // First check most recent balance
        if (_checkpoints[_tokenId][nCheckpoints - 1].fromTimestamp <= _timestamp) return (nCheckpoints - 1);
        // Next check implicit zero balance
        if (_checkpoints[_tokenId][0].fromTimestamp > _timestamp) return 0;

        uint48 lower = 0;
        uint48 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint48 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.Checkpoint storage cp = _checkpoints[_tokenId][center];
            if (cp.fromTimestamp == _timestamp) {
                return center;
            } else if (cp.fromTimestamp < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Retrieves historical voting balance for a token id at a given timestamp.
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    ///      The user must also own the token at the time in order to receive a voting balance.
    /// @param _numCheckpoints State of all user checkpoint counts
    /// @param _checkpoints State of all user checkpoints
    /// @param _account .
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return Total voting balance including delegations at a given timestamp.
    function getPastVotes(
        mapping(uint256 => uint48) storage _numCheckpoints,
        mapping(uint256 => mapping(uint48 => IVotingEscrow.Checkpoint)) storage _checkpoints,
        address _account,
        uint256 _tokenId,
        uint256 _timestamp
    ) external view returns (uint256) {
        uint48 _checkIndex = getPastVotesIndex(_numCheckpoints, _checkpoints, _tokenId, _timestamp);
        IVotingEscrow.Checkpoint memory lastCheckpoint = _checkpoints[_tokenId][_checkIndex];
        // If no point exists prior to the given timestamp, return 0
        if (lastCheckpoint.fromTimestamp > _timestamp) return 0;
        // Check ownership
        if (_account != lastCheckpoint.owner) return 0;
        uint256 votes = lastCheckpoint.delegatedBalance;
        return
            lastCheckpoint.delegatee == 0
                ? votes + IVotingEscrow(address(this)).balanceOfNFTAt(_tokenId, _timestamp)
                : votes;
    }
}

library BalanceLogicLibrary {
    using SafeCastLibrary for uint256;
    using SafeCastLibrary for int128;

    uint256 internal constant WEEK = 1 weeks;

    /// @notice Binary search to get the user point index for a token id at or prior to a given timestamp
    /// @dev If a user point does not exist prior to the timestamp, this will return 0.
    /// @param _userPointEpoch State of all user point epochs
    /// @param _userPointHistory State of all user point history
    /// @param _tokenId .
    /// @param _timestamp .
    /// @return User point index
    function getPastUserPointIndex(
        mapping(uint256 => uint256) storage _userPointEpoch,
        mapping(uint256 => IVotingEscrow.UserPoint[1000000000]) storage _userPointHistory,
        uint256 _tokenId,
        uint256 _timestamp
    ) internal view returns (uint256) {
        uint256 _userEpoch = _userPointEpoch[_tokenId];
        if (_userEpoch == 0) return 0;
        // First check most recent balance
        if (_userPointHistory[_tokenId][_userEpoch].ts <= _timestamp) return (_userEpoch);
        // Next check implicit zero balance
        if (_userPointHistory[_tokenId][1].ts > _timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = _userEpoch;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.UserPoint storage userPoint = _userPointHistory[_tokenId][center];
            if (userPoint.ts == _timestamp) {
                return center;
            } else if (userPoint.ts < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Binary search to get the global point index at or prior to a given timestamp
    /// @dev If a checkpoint does not exist prior to the timestamp, this will return 0.
    /// @param _epoch Current global point epoch
    /// @param _pointHistory State of all global point history
    /// @param _timestamp .
    /// @return Global point index
    function getPastGlobalPointIndex(
        uint256 _epoch,
        mapping(uint256 => IVotingEscrow.GlobalPoint) storage _pointHistory,
        uint256 _timestamp
    ) internal view returns (uint256) {
        if (_epoch == 0) return 0;
        // First check most recent balance
        if (_pointHistory[_epoch].ts <= _timestamp) return (_epoch);
        // Next check implicit zero balance
        if (_pointHistory[1].ts > _timestamp) return 0;

        uint256 lower = 0;
        uint256 upper = _epoch;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            IVotingEscrow.GlobalPoint storage globalPoint = _pointHistory[center];
            if (globalPoint.ts == _timestamp) {
                return center;
            } else if (globalPoint.ts < _timestamp) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return lower;
    }

    /// @notice Get the current voting power for `_tokenId`
    /// @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
    ///      Fetches last user point prior to a certain timestamp, then walks forward to timestamp.
    /// @param _userPointEpoch State of all user point epochs
    /// @param _userPointHistory State of all user point history
    /// @param _tokenId NFT for lock
    /// @param _t Epoch time to return voting power at
    /// @return User voting power
    function balanceOfNFTAt(
        mapping(uint256 => uint256) storage _userPointEpoch,
        mapping(uint256 => IVotingEscrow.UserPoint[1000000000]) storage _userPointHistory,
        uint256 _tokenId,
        uint256 _t
    ) external view returns (uint256) {
        uint256 _epoch = getPastUserPointIndex(_userPointEpoch, _userPointHistory, _tokenId, _t);
        // epoch 0 is an empty point
        if (_epoch == 0) return 0;
        IVotingEscrow.UserPoint memory lastPoint = _userPointHistory[_tokenId][_epoch];
        if (lastPoint.permanent != 0) {
            return lastPoint.permanent;
        } else {
            lastPoint.bias -= lastPoint.slope * (_t - lastPoint.ts).toInt128();
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return lastPoint.bias.toUint256();
        }
    }

    /// @notice Calculate total voting power at some point in the past
    /// @param _slopeChanges State of all slopeChanges
    /// @param _pointHistory State of all global point history
    /// @param _epoch The epoch to start search from
    /// @param _t Time to calculate the total voting power at
    /// @return Total voting power at that time
    function supplyAt(
        mapping(uint256 => int128) storage _slopeChanges,
        mapping(uint256 => IVotingEscrow.GlobalPoint) storage _pointHistory,
        uint256 _epoch,
        uint256 _t
    ) external view returns (uint256) {
        uint256 epoch_ = getPastGlobalPointIndex(_epoch, _pointHistory, _t);
        // epoch 0 is an empty point
        if (epoch_ == 0) return 0;
        IVotingEscrow.GlobalPoint memory _point = _pointHistory[epoch_];
        int128 bias = _point.bias;
        int128 slope = _point.slope;
        uint256 ts = _point.ts;
        uint256 t_i = (ts / WEEK) * WEEK;
        for (uint256 i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 dSlope = 0;
            if (t_i > _t) {
                t_i = _t;
            } else {
                dSlope = _slopeChanges[t_i];
            }
            bias -= slope * (t_i - ts).toInt128();
            if (t_i == _t) {
                break;
            }
            slope += dSlope;
            ts = t_i;
        }

        if (bias < 0) {
            bias = 0;
        }
        return bias.toUint256() + _point.permanentLockBalance;
    }
}

/// @title Voting Escrow
/// @notice veNFT implementation that escrows ERC-20 tokens in the form of an ERC-721 NFT
/// @notice Votes have a weight depending on time, so that users are committed to the future of (whatever they are voting for)
/// @author Modified from Solidly (https://github.com/solidlyexchange/solidly/blob/master/contracts/ve.sol)
/// @author Modified from Curve (https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/VotingEscrow.vy)
/// @dev Vote weight decays linearly over time. Lock time cannot be more than `MAXTIME` (4 years).
contract VotingEscrow is IVotingEscrow, ERC2771Context, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCastLibrary for uint256;
    using SafeCastLibrary for int128;
    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    address public immutable forwarder;
    /// @inheritdoc IVotingEscrow
    address public immutable factoryRegistry;
    /// @inheritdoc IVotingEscrow
    address public immutable token;
    /// @inheritdoc IVotingEscrow
    address public distributor;
    /// @inheritdoc IVotingEscrow
    address public voter;
    /// @inheritdoc IVotingEscrow
    address public team;
    /// @inheritdoc IVotingEscrow
    address public artProxy;
    /// @inheritdoc IVotingEscrow
    address public allowedManager;

    mapping(uint256 => GlobalPoint) internal _pointHistory; // epoch -> unsigned global point

    /// @dev Mapping of interface id to bool about whether or not it's supported
    mapping(bytes4 => bool) internal supportedInterfaces;

    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @dev ERC165 interface ID of ERC4906
    bytes4 internal constant ERC4906_INTERFACE_ID = 0x49064906;

    /// @dev ERC165 interface ID of ERC6372
    bytes4 internal constant ERC6372_INTERFACE_ID = 0xda287a1d;

    /// @inheritdoc IVotingEscrow
    uint256 public tokenId;

    /// @param _forwarder address of trusted forwarder
    /// @param _token `PRFCT` token address
    /// @param _factoryRegistry Factory Registry address
    constructor(address _forwarder, address _token, address _factoryRegistry) ERC2771Context(_forwarder) {
        forwarder = _forwarder;
        token = _token;
        factoryRegistry = _factoryRegistry;
        team = _msgSender();
        voter = _msgSender();

        _pointHistory[0].blk = block.number;
        _pointHistory[0].ts = block.timestamp;

        supportedInterfaces[ERC165_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_INTERFACE_ID] = true;
        supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
        supportedInterfaces[ERC4906_INTERFACE_ID] = true;
        supportedInterfaces[ERC6372_INTERFACE_ID] = true;

        // mint-ish
        emit Transfer(address(0), address(this), tokenId);
        // burn-ish
        emit Transfer(address(this), address(0), tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => EscrowType) public escrowType;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => uint256) public idToManaged;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => mapping(uint256 => uint256)) public weights;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => bool) public deactivated;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => address) public managedToLocked;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => address) public managedToFree;

    /*///////////////////////////////////////////////////////////////
                            MANAGED NFT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function createManagedLockFor(address _to) external nonReentrant returns (uint256 _mTokenId) {
        address sender = _msgSender();
        if (sender != allowedManager && sender != IVoter(voter).governor()) revert NotGovernorOrManager();

        _mTokenId = ++tokenId;
        _mint(_to, _mTokenId);
        _depositFor(_mTokenId, 0, 0, LockedBalance(0, 0, true), DepositType.CREATE_LOCK_TYPE);

        escrowType[_mTokenId] = EscrowType.MANAGED;

        (address _lockedManagedReward, address _freeManagedReward) = IManagedRewardsFactory(
            IFactoryRegistry(factoryRegistry).managedRewardsFactory()
        ).createRewards(forwarder, voter);
        managedToLocked[_mTokenId] = _lockedManagedReward;
        managedToFree[_mTokenId] = _freeManagedReward;

        emit CreateManaged(_to, _mTokenId, sender, _lockedManagedReward, _freeManagedReward);
    }

    /// @inheritdoc IVotingEscrow
    function depositManaged(uint256 _tokenId, uint256 _mTokenId) external nonReentrant {
        if (_msgSender() != voter) revert NotVoter();
        if (escrowType[_mTokenId] != EscrowType.MANAGED) revert NotManagedNFT();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        if (_balanceOfNFTAt(_tokenId, block.timestamp) == 0) revert ZeroBalance();

        // adjust user nft
        int128 _amount = _locked[_tokenId].amount;
        if (_locked[_tokenId].isPermanent) {
            permanentLockBalance -= _amount.toUint256();
            _delegate(_tokenId, 0);
        }
        _checkpoint(_tokenId, _locked[_tokenId], LockedBalance(0, 0, false));
        _locked[_tokenId] = LockedBalance(0, 0, false);

        // adjust managed nft
        uint256 _weight = _amount.toUint256();
        permanentLockBalance += _weight;
        LockedBalance memory newLocked = _locked[_mTokenId];
        newLocked.amount += _amount;
        _checkpointDelegatee(_delegates[_mTokenId], _weight, true);
        _checkpoint(_mTokenId, _locked[_mTokenId], newLocked);
        _locked[_mTokenId] = newLocked;

        weights[_tokenId][_mTokenId] = _weight;
        idToManaged[_tokenId] = _mTokenId;
        escrowType[_tokenId] = EscrowType.LOCKED;

        address _lockedManagedReward = managedToLocked[_mTokenId];
        IReward(_lockedManagedReward)._deposit(_weight, _tokenId);
        address _freeManagedReward = managedToFree[_mTokenId];
        IReward(_freeManagedReward)._deposit(_weight, _tokenId);

        emit DepositManaged(_ownerOf(_tokenId), _tokenId, _mTokenId, _weight, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function withdrawManaged(uint256 _tokenId) external nonReentrant {
        uint256 _mTokenId = idToManaged[_tokenId];
        if (_msgSender() != voter) revert NotVoter();
        if (_mTokenId == 0) revert InvalidManagedNFTId();
        if (escrowType[_tokenId] != EscrowType.LOCKED) revert NotLockedNFT();

        // update accrued rewards
        address _lockedManagedReward = managedToLocked[_mTokenId];
        address _freeManagedReward = managedToFree[_mTokenId];
        uint256 _weight = weights[_tokenId][_mTokenId];
        uint256 _reward = IReward(_lockedManagedReward).earned(address(token), _tokenId);
        uint256 _total = _weight + _reward;
        uint256 _unlockTime = ((block.timestamp + MAXTIME) / WEEK) * WEEK;

        // claim locked rewards (rebases + compounded reward)
        address[] memory rewards = new address[](1);
        rewards[0] = address(token);
        IReward(_lockedManagedReward).getReward(_tokenId, rewards);

        // adjust user nft
        LockedBalance memory newLockedNormal = LockedBalance(_total.toInt128(), _unlockTime, false);
        _checkpoint(_tokenId, _locked[_tokenId], newLockedNormal);
        _locked[_tokenId] = newLockedNormal;

        // adjust managed nft
        LockedBalance memory newLockedManaged = _locked[_mTokenId];
        // do not expect _total > locked.amount / permanentLockBalance but just in case
        newLockedManaged.amount -= (
            _total.toInt128() < newLockedManaged.amount ? _total.toInt128() : newLockedManaged.amount
        );
        permanentLockBalance -= (_total < permanentLockBalance ? _total : permanentLockBalance);
        _checkpointDelegatee(_delegates[_mTokenId], _total, false);
        _checkpoint(_mTokenId, _locked[_mTokenId], newLockedManaged);
        _locked[_mTokenId] = newLockedManaged;

        IReward(_lockedManagedReward)._withdraw(_weight, _tokenId);
        IReward(_freeManagedReward)._withdraw(_weight, _tokenId);

        delete idToManaged[_tokenId];
        delete weights[_tokenId][_mTokenId];
        delete escrowType[_tokenId];

        emit WithdrawManaged(_ownerOf(_tokenId), _tokenId, _mTokenId, _total, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function setAllowedManager(address _allowedManager) external {
        if (_msgSender() != IVoter(voter).governor()) revert NotGovernor();
        if (_allowedManager == allowedManager) revert SameAddress();
        if (_allowedManager == address(0)) revert ZeroAddress();
        allowedManager = _allowedManager;
        emit SetAllowedManager(_allowedManager);
    }

    /// @inheritdoc IVotingEscrow
    function setManagedState(uint256 _mTokenId, bool _state) external {
        if (_msgSender() != IVoter(voter).emergencyCouncil() && _msgSender() != IVoter(voter).governor())
            revert NotEmergencyCouncilOrGovernor();
        if (escrowType[_mTokenId] != EscrowType.MANAGED) revert NotManagedNFT();
        if (deactivated[_mTokenId] == _state) revert SameState();
        deactivated[_mTokenId] = _state;
    }

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public constant name = "veNFT";
    string public constant symbol = "veNFT";
    string public constant version = "2.0.0";
    uint8 public constant decimals = 18;

    function setTeam(address _team) external {
        if (_msgSender() != team) revert NotTeam();
        if (_team == address(0)) revert ZeroAddress();
        team = _team;
    }

    function setArtProxy(address _proxy) external {
        if (_msgSender() != team) revert NotTeam();
        artProxy = _proxy;
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    /// @inheritdoc IVotingEscrow
    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        if (_ownerOf(_tokenId) == address(0)) revert NonExistentToken();
        return IVeArtProxy(artProxy).tokenURI(_tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to the address that owns it.
    mapping(uint256 => address) internal idToOwner;

    /// @dev Mapping from owner address to count of his tokens.
    mapping(address => uint256) internal ownerToNFTokenCount;

    function _ownerOf(uint256 _tokenId) internal view returns (address) {
        return idToOwner[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function ownerOf(uint256 _tokenId) external view returns (address) {
        return _ownerOf(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOf(address _owner) external view returns (uint256) {
        return ownerToNFTokenCount[_owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from NFT ID to approved address.
    mapping(uint256 => address) internal idToApprovals;

    /// @dev Mapping from owner address to mapping of operator addresses.
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    mapping(uint256 => uint256) internal ownershipChange;

    /// @inheritdoc IVotingEscrow
    function getApproved(uint256 _tokenId) external view returns (address) {
        return idToApprovals[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return (ownerToOperators[_owner])[_operator];
    }

    /// @inheritdoc IVotingEscrow
    function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
        return _isApprovedOrOwner(_spender, _tokenId);
    }

    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = _ownerOf(_tokenId);
        bool spenderIsOwner = owner == _spender;
        bool spenderIsApproved = _spender == idToApprovals[_tokenId];
        bool spenderIsApprovedForAll = (ownerToOperators[owner])[_spender];
        return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function approve(address _approved, uint256 _tokenId) external {
        address sender = _msgSender();
        address owner = _ownerOf(_tokenId);
        // Throws if `_tokenId` is not a valid NFT
        if (owner == address(0)) revert ZeroAddress();
        // Throws if `_approved` is the current owner
        if (owner == _approved) revert SameAddress();
        // Check requirements
        bool senderIsOwner = (_ownerOf(_tokenId) == sender);
        bool senderIsApprovedForAll = (ownerToOperators[owner])[sender];
        if (!senderIsOwner && !senderIsApprovedForAll) revert NotApprovedOrOwner();
        // Set the approval
        idToApprovals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function setApprovalForAll(address _operator, bool _approved) external {
        address sender = _msgSender();
        // Throws if `_operator` is the `msg.sender`
        if (_operator == sender) revert SameAddress();
        ownerToOperators[sender][_operator] = _approved;
        emit ApprovalForAll(sender, _operator, _approved);
    }

    /* TRANSFER FUNCTIONS */

    function _transferFrom(address _from, address _to, uint256 _tokenId, address _sender) internal {
        if (escrowType[_tokenId] == EscrowType.LOCKED) revert NotManagedOrNormalNFT();
        // Check requirements
        if (!_isApprovedOrOwner(_sender, _tokenId)) revert NotApprovedOrOwner();
        // Clear approval. Throws if `_from` is not the current owner
        if (_ownerOf(_tokenId) != _from) revert NotOwner();
        delete idToApprovals[_tokenId];
        // Remove NFT. Throws if `_tokenId` is not a valid NFT
        _removeTokenFrom(_from, _tokenId);
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, _to);
        // Add NFT
        _addTokenTo(_to, _tokenId);
        // Set the block of ownership transfer (for Flash NFT protection)
        ownershipChange[_tokenId] = block.number;
        // Log the transfer
        emit Transfer(_from, _to, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
        _transferFrom(_from, _to, _tokenId, _msgSender());
    }

    /// @inheritdoc IVotingEscrow
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function _isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @inheritdoc IVotingEscrow
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
        address sender = _msgSender();
        _transferFrom(_from, _to, _tokenId, sender);

        if (_isContract(_to)) {
            // Throws if transfer destination is a contract which does not implement 'onERC721Received'
            try IERC721Receiver(_to).onERC721Received(sender, _from, _tokenId, _data) returns (bytes4 response) {
                if (response != IERC721Receiver(_to).onERC721Received.selector) {
                    revert ERC721ReceiverRejectedTokens();
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(address => mapping(uint256 => uint256)) public ownerToNFTokenIdList;

    /// @dev Mapping from NFT ID to index of owner
    mapping(uint256 => uint256) internal tokenToOwnerIndex;

    /// @dev Add a NFT to an index mapping to a given address
    /// @param _to address of the receiver
    /// @param _tokenId uint ID Of the token to be added
    function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
        uint256 currentCount = ownerToNFTokenCount[_to];

        ownerToNFTokenIdList[_to][currentCount] = _tokenId;
        tokenToOwnerIndex[_tokenId] = currentCount;
    }

    /// @dev Add a NFT to a given address
    ///      Throws if `_tokenId` is owned by someone.
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Throws if `_tokenId` is owned by someone
        assert(_ownerOf(_tokenId) == address(0));
        // Change the owner
        idToOwner[_tokenId] = _to;
        // Update owner token index tracking
        _addTokenToOwnerList(_to, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_to] += 1;
    }

    /// @dev Function to mint tokens
    ///      Throws if `_to` is zero address.
    ///      Throws if `_tokenId` is owned by someone.
    /// @param _to The address that will receive the minted tokens.
    /// @param _tokenId The token id to mint.
    /// @return A boolean that indicates if the operation was successful.
    function _mint(address _to, uint256 _tokenId) internal returns (bool) {
        // Throws if `_to` is zero address
        assert(_to != address(0));
        // Add NFT. Throws if `_tokenId` is owned by someone
        _addTokenTo(_to, _tokenId);
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, _to);
        emit Transfer(address(0), _to, _tokenId);
        return true;
    }

    /// @dev Remove a NFT from an index mapping to a given address
    /// @param _from address of the sender
    /// @param _tokenId uint ID Of the token to be removed
    function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal {
        // Delete
        uint256 currentCount = ownerToNFTokenCount[_from] - 1;
        uint256 currentIndex = tokenToOwnerIndex[_tokenId];

        if (currentCount == currentIndex) {
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        } else {
            uint256 lastTokenId = ownerToNFTokenIdList[_from][currentCount];

            // Add
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[lastTokenId] = currentIndex;

            // Delete
            // update ownerToNFTokenIdList
            ownerToNFTokenIdList[_from][currentCount] = 0;
            // update tokenToOwnerIndex
            tokenToOwnerIndex[_tokenId] = 0;
        }
    }

    /// @dev Remove a NFT from a given address
    ///      Throws if `_from` is not the current owner.
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Throws if `_from` is not the current owner
        assert(_ownerOf(_tokenId) == _from);
        // Change the owner
        idToOwner[_tokenId] = address(0);
        // Update owner token index tracking
        _removeTokenFromOwnerList(_from, _tokenId);
        // Change count tracking
        ownerToNFTokenCount[_from] -= 1;
    }

    /// @dev Must be called prior to updating `LockedBalance`
    function _burn(uint256 _tokenId) internal {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        address owner = _ownerOf(_tokenId);

        // Clear approval
        delete idToApprovals[_tokenId];
        // Update voting checkpoints
        _checkpointDelegator(_tokenId, 0, address(0));
        // Remove token
        _removeTokenFrom(owner, _tokenId);
        emit Transfer(owner, address(0), _tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                             ESCROW STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WEEK = 1 weeks;
    uint256 internal constant MAXTIME = 4 * 365 * 86400;
    int128 internal constant iMAXTIME = 4 * 365 * 86400;
    uint256 internal constant MULTIPLIER = 1 ether;

    /// @inheritdoc IVotingEscrow
    uint256 public epoch;
    /// @inheritdoc IVotingEscrow
    uint256 public supply;

    mapping(uint256 => LockedBalance) internal _locked;
    mapping(uint256 => UserPoint[1000000000]) internal _userPointHistory;
    mapping(uint256 => uint256) public userPointEpoch;
    /// @inheritdoc IVotingEscrow
    mapping(uint256 => int128) public slopeChanges;
    /// @inheritdoc IVotingEscrow
    mapping(address => bool) public canSplit;
    /// @inheritdoc IVotingEscrow
    uint256 public permanentLockBalance;

    /// @inheritdoc IVotingEscrow
    function locked(uint256 _tokenId) external view returns (LockedBalance memory) {
        return _locked[_tokenId];
    }

    /// @inheritdoc IVotingEscrow
    function userPointHistory(uint256 _tokenId, uint256 _loc) external view returns (UserPoint memory) {
        return _userPointHistory[_tokenId][_loc];
    }

    /// @inheritdoc IVotingEscrow
    function pointHistory(uint256 _loc) external view returns (GlobalPoint memory) {
        return _pointHistory[_loc];
    }

    /*//////////////////////////////////////////////////////////////
                              ESCROW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Record global and per-user data to checkpoints. Used by VotingEscrow system.
    /// @param _tokenId NFT token ID. No user checkpoint if 0
    /// @param _oldLocked Pevious locked amount / end lock time for the user
    /// @param _newLocked New locked amount / end lock time for the user
    function _checkpoint(uint256 _tokenId, LockedBalance memory _oldLocked, LockedBalance memory _newLocked) internal {
        UserPoint memory uOld;
        UserPoint memory uNew;
        int128 oldDslope = 0;
        int128 newDslope = 0;
        uint256 _epoch = epoch;

        if (_tokenId != 0) {
            uNew.permanent = _newLocked.isPermanent ? _newLocked.amount.toUint256() : 0;
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                uOld.slope = _oldLocked.amount / iMAXTIME;
                uOld.bias = uOld.slope * (_oldLocked.end - block.timestamp).toInt128();
            }
            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                uNew.slope = _newLocked.amount / iMAXTIME;
                uNew.bias = uNew.slope * (_newLocked.end - block.timestamp).toInt128();
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY by in the FUTURE unless everything expired: than zeros
            oldDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    newDslope = oldDslope;
                } else {
                    newDslope = slopeChanges[_newLocked.end];
                }
            }
        }

        GlobalPoint memory lastPoint = GlobalPoint({
            bias: 0,
            slope: 0,
            ts: block.timestamp,
            blk: block.number,
            permanentLockBalance: 0
        });
        if (_epoch > 0) {
            lastPoint = _pointHistory[_epoch];
        }
        uint256 lastCheckpoint = lastPoint.ts;
        // initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        GlobalPoint memory initialLastPoint = GlobalPoint({
            bias: lastPoint.bias,
            slope: lastPoint.slope,
            ts: lastPoint.ts,
            blk: lastPoint.blk,
            permanentLockBalance: lastPoint.permanentLockBalance
        });
        uint256 blockSlope = 0; // dblock/dt
        if (block.timestamp > lastPoint.ts) {
            blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        {
            uint256 t_i = (lastCheckpoint / WEEK) * WEEK;
            for (uint256 i = 0; i < 255; ++i) {
                // Hopefully it won't happen that this won't get used in 5 years!
                // If it does, users will be able to withdraw but vote weight will be broken
                t_i += WEEK; // Initial value of t_i is always larger than the ts of the last point
                int128 d_slope = 0;
                if (t_i > block.timestamp) {
                    t_i = block.timestamp;
                } else {
                    d_slope = slopeChanges[t_i];
                }
                lastPoint.bias -= lastPoint.slope * (t_i - lastCheckpoint).toInt128();
                lastPoint.slope += d_slope;
                if (lastPoint.bias < 0) {
                    // This can happen
                    lastPoint.bias = 0;
                }
                if (lastPoint.slope < 0) {
                    // This cannot happen - just in case
                    lastPoint.slope = 0;
                }
                lastCheckpoint = t_i;
                lastPoint.ts = t_i;
                lastPoint.blk = initialLastPoint.blk + (blockSlope * (t_i - initialLastPoint.ts)) / MULTIPLIER;
                _epoch += 1;
                if (t_i == block.timestamp) {
                    lastPoint.blk = block.number;
                    break;
                } else {
                    _pointHistory[_epoch] = lastPoint;
                }
            }
        }

        if (_tokenId != 0) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            lastPoint.permanentLockBalance = permanentLockBalance;
        }

        // If timestamp of last global point is the same, overwrite the last global point
        // Else record the new global point into history
        // Exclude epoch 0 (note: _epoch is always >= 1, see above)
        // Two possible outcomes:
        // Missing global checkpoints in prior weeks. In this case, _epoch = epoch + x, where x > 1
        // No missing global checkpoints, but timestamp != block.timestamp. Create new checkpoint.
        // No missing global checkpoints, but timestamp == block.timestamp. Overwrite last checkpoint.
        if (_epoch != 1 && _pointHistory[_epoch - 1].ts == block.timestamp) {
            // _epoch = epoch + 1, so we do not increment epoch
            _pointHistory[_epoch - 1] = lastPoint;
        } else {
            // more than one global point may have been written, so we update epoch
            epoch = _epoch;
            _pointHistory[_epoch] = lastPoint;
        }

        if (_tokenId != 0) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // oldDslope was <something> - uOld.slope, so we cancel that
                oldDslope += uOld.slope;
                if (_newLocked.end == _oldLocked.end) {
                    oldDslope -= uNew.slope; // It was a new deposit, not extension
                }
                slopeChanges[_oldLocked.end] = oldDslope;
            }

            if (_newLocked.end > block.timestamp) {
                // update slope if new lock is greater than old lock and is not permanent or if old lock is permanent
                if ((_newLocked.end > _oldLocked.end)) {
                    newDslope -= uNew.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = newDslope;
                }
                // else: we recorded it already in oldDslope
            }
            // If timestamp of last user point is the same, overwrite the last user point
            // Else record the new user point into history
            // Exclude epoch 0
            uNew.ts = block.timestamp;
            uNew.blk = block.number;
            uint256 userEpoch = userPointEpoch[_tokenId];
            if (userEpoch != 0 && _userPointHistory[_tokenId][userEpoch].ts == block.timestamp) {
                _userPointHistory[_tokenId][userEpoch] = uNew;
            } else {
                userPointEpoch[_tokenId] = ++userEpoch;
                _userPointHistory[_tokenId][userEpoch] = uNew;
            }
        }
    }

    /// @notice Deposit and lock tokens for a user
    /// @param _tokenId NFT that holds lock
    /// @param _value Amount to deposit
    /// @param _unlockTime New time when to unlock the tokens, or 0 if unchanged
    /// @param _oldLocked Previous locked amount / timestamp
    /// @param _depositType The type of deposit
    function _depositFor(
        uint256 _tokenId,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _oldLocked,
        DepositType _depositType
    ) internal {
        uint256 supplyBefore = supply;
        supply = supplyBefore + _value;

        // Set newLocked to _oldLocked without mangling memory
        LockedBalance memory newLocked;
        (newLocked.amount, newLocked.end, newLocked.isPermanent) = (
            _oldLocked.amount,
            _oldLocked.end,
            _oldLocked.isPermanent
        );

        // Adding to existing lock, or if a lock is expired - creating a new one
        newLocked.amount += _value.toInt128();
        if (_unlockTime != 0) {
            newLocked.end = _unlockTime;
        }
        _locked[_tokenId] = newLocked;

        // Possibilities:
        // Both _oldLocked.end could be current or expired (>/< block.timestamp)
        // or if the lock is a permanent lock, then _oldLocked.end == 0
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // newLocked.end > block.timestamp (always)
        _checkpoint(_tokenId, _oldLocked, newLocked);

        address from = _msgSender();
        if (_value != 0) {
            IERC20(token).safeTransferFrom(from, address(this), _value);
        }

        emit Deposit(from, _tokenId, _depositType, _value, newLocked.end, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /// @inheritdoc IVotingEscrow
    function checkpoint() external nonReentrant {
        _checkpoint(0, LockedBalance(0, 0, false), LockedBalance(0, 0, false));
    }

    /// @inheritdoc IVotingEscrow
    function depositFor(uint256 _tokenId, uint256 _value) external nonReentrant {
        if (escrowType[_tokenId] == EscrowType.MANAGED && _msgSender() != distributor) revert NotDistributor();
        _increaseAmountFor(_tokenId, _value, DepositType.DEPOSIT_FOR_TYPE);
    }

    /// @dev Deposit `_value` tokens for `_to` and lock for `_lockDuration`
    /// @param _value Amount to deposit
    /// @param _lockDuration Number of seconds to lock tokens for (rounded down to nearest week)
    /// @param _to Address to deposit
    function _createLock(uint256 _value, uint256 _lockDuration, address _to) internal returns (uint256) {
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        if (_value == 0) revert ZeroAmount();
        if (unlockTime <= block.timestamp) revert LockDurationNotInFuture();
        if (unlockTime > block.timestamp + MAXTIME) revert LockDurationTooLong();

        uint256 _tokenId = ++tokenId;
        _mint(_to, _tokenId);

        _depositFor(_tokenId, _value, unlockTime, _locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
        return _tokenId;
    }

    /// @inheritdoc IVotingEscrow
    function createLock(uint256 _value, uint256 _lockDuration) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _msgSender());
    }

    /// @inheritdoc IVotingEscrow
    function createLockFor(uint256 _value, uint256 _lockDuration, address _to) external nonReentrant returns (uint256) {
        return _createLock(_value, _lockDuration, _to);
    }

    function _increaseAmountFor(uint256 _tokenId, uint256 _value, DepositType _depositType) internal {
        EscrowType _escrowType = escrowType[_tokenId];
        if (_escrowType == EscrowType.LOCKED) revert NotManagedOrNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];

        if (_value == 0) revert ZeroAmount();
        if (oldLocked.amount <= 0) revert NoLockFound();
        if (oldLocked.end <= block.timestamp && !oldLocked.isPermanent) revert LockExpired();

        if (oldLocked.isPermanent) permanentLockBalance += _value;
        _checkpointDelegatee(_delegates[_tokenId], _value, true);
        _depositFor(_tokenId, _value, 0, oldLocked, _depositType);

        if (_escrowType == EscrowType.MANAGED) {
            // increaseAmount called on managed tokens are treated as locked rewards
            address _lockedManagedReward = managedToLocked[_tokenId];
            address _token = token;
            IERC20(_token).safeApprove(_lockedManagedReward, _value);
            IReward(_lockedManagedReward).notifyRewardAmount(_token, _value);
            IERC20(_token).safeApprove(_lockedManagedReward, 0);
        }

        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function increaseAmount(uint256 _tokenId, uint256 _value) external nonReentrant {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        _increaseAmountFor(_tokenId, _value, DepositType.INCREASE_LOCK_AMOUNT);
    }

    /// @inheritdoc IVotingEscrow
    function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external nonReentrant {
        if (!_isApprovedOrOwner(_msgSender(), _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];
        if (oldLocked.isPermanent) revert PermanentLock();
        uint256 unlockTime = ((block.timestamp + _lockDuration) / WEEK) * WEEK; // Locktime is rounded down to weeks

        if (oldLocked.end <= block.timestamp) revert LockExpired();
        if (oldLocked.amount <= 0) revert NoLockFound();
        if (unlockTime <= oldLocked.end) revert LockDurationNotInFuture();
        if (unlockTime > block.timestamp + MAXTIME) revert LockDurationTooLong();

        _depositFor(_tokenId, 0, unlockTime, oldLocked, DepositType.INCREASE_UNLOCK_TIME);

        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function withdraw(uint256 _tokenId) external nonReentrant {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (voted[_tokenId]) revert AlreadyVoted();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();

        LockedBalance memory oldLocked = _locked[_tokenId];
        if (oldLocked.isPermanent) revert PermanentLock();
        if (block.timestamp < oldLocked.end) revert LockNotExpired();
        uint256 value = oldLocked.amount.toUint256();

        // Burn the NFT
        _burn(_tokenId);
        _locked[_tokenId] = LockedBalance(0, 0, false);
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        // oldLocked can have either expired <= timestamp or zero end
        // oldLocked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(_tokenId, oldLocked, LockedBalance(0, 0, false));

        IERC20(token).safeTransfer(sender, value);

        emit Withdraw(sender, _tokenId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /// @inheritdoc IVotingEscrow
    function merge(uint256 _from, uint256 _to) external nonReentrant {
        address sender = _msgSender();
        if (voted[_from]) revert AlreadyVoted();
        if (escrowType[_from] != EscrowType.NORMAL) revert NotNormalNFT();
        if (escrowType[_to] != EscrowType.NORMAL) revert NotNormalNFT();
        if (_from == _to) revert SameNFT();
        if (!_isApprovedOrOwner(sender, _from)) revert NotApprovedOrOwner();
        if (!_isApprovedOrOwner(sender, _to)) revert NotApprovedOrOwner();
        LockedBalance memory oldLockedTo = _locked[_to];
        if (oldLockedTo.end <= block.timestamp && !oldLockedTo.isPermanent) revert LockExpired();

        LockedBalance memory oldLockedFrom = _locked[_from];
        if (oldLockedFrom.isPermanent) revert PermanentLock();
        uint256 end = oldLockedFrom.end >= oldLockedTo.end ? oldLockedFrom.end : oldLockedTo.end;

        _burn(_from);
        _locked[_from] = LockedBalance(0, 0, false);
        _checkpoint(_from, oldLockedFrom, LockedBalance(0, 0, false));

        LockedBalance memory newLockedTo;
        newLockedTo.amount = oldLockedTo.amount + oldLockedFrom.amount;
        newLockedTo.isPermanent = oldLockedTo.isPermanent;
        if (newLockedTo.isPermanent) {
            permanentLockBalance += oldLockedFrom.amount.toUint256();
        } else {
            newLockedTo.end = end;
        }
        _checkpointDelegatee(_delegates[_to], oldLockedFrom.amount.toUint256(), true);
        _checkpoint(_to, oldLockedTo, newLockedTo);
        _locked[_to] = newLockedTo;

        emit Merge(
            sender,
            _from,
            _to,
            oldLockedFrom.amount.toUint256(),
            oldLockedTo.amount.toUint256(),
            newLockedTo.amount.toUint256(),
            newLockedTo.end,
            block.timestamp
        );
        emit MetadataUpdate(_to);
    }

    /// @inheritdoc IVotingEscrow
    function split(
        uint256 _from,
        uint256 _amount
    ) external nonReentrant returns (uint256 _tokenId1, uint256 _tokenId2) {
        address sender = _msgSender();
        address owner = _ownerOf(_from);
        if (owner == address(0)) revert SplitNoOwner();
        if (!canSplit[owner] && !canSplit[address(0)]) revert SplitNotAllowed();
        if (escrowType[_from] != EscrowType.NORMAL) revert NotNormalNFT();
        if (voted[_from]) revert AlreadyVoted();
        if (!_isApprovedOrOwner(sender, _from)) revert NotApprovedOrOwner();
        LockedBalance memory newLocked = _locked[_from];
        if (newLocked.end <= block.timestamp && !newLocked.isPermanent) revert LockExpired();
        int128 _splitAmount = _amount.toInt128();
        if (_splitAmount == 0) revert ZeroAmount();
        if (newLocked.amount <= _splitAmount) revert AmountTooBig();

        // Zero out and burn old veNFT
        _burn(_from);
        _locked[_from] = LockedBalance(0, 0, false);
        _checkpoint(_from, newLocked, LockedBalance(0, 0, false));

        // Create new veNFT using old balance - amount
        newLocked.amount -= _splitAmount;
        _tokenId1 = _createSplitNFT(owner, newLocked);

        // Create new veNFT using amount
        newLocked.amount = _splitAmount;
        _tokenId2 = _createSplitNFT(owner, newLocked);

        emit Split(
            _from,
            _tokenId1,
            _tokenId2,
            sender,
            _locked[_tokenId1].amount.toUint256(),
            _splitAmount.toUint256(),
            newLocked.end,
            block.timestamp
        );
    }

    function _createSplitNFT(address _to, LockedBalance memory _newLocked) private returns (uint256 _tokenId) {
        _tokenId = ++tokenId;
        _locked[_tokenId] = _newLocked;
        _checkpoint(_tokenId, LockedBalance(0, 0, false), _newLocked);
        _mint(_to, _tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function toggleSplit(address _account, bool _bool) external {
        if (_msgSender() != team) revert NotTeam();
        canSplit[_account] = _bool;
    }

    /// @inheritdoc IVotingEscrow
    function lockPermanent(uint256 _tokenId) external {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        LockedBalance memory _newLocked = _locked[_tokenId];
        if (_newLocked.isPermanent) revert PermanentLock();
        if (_newLocked.end <= block.timestamp) revert LockExpired();
        if (_newLocked.amount <= 0) revert NoLockFound();

        uint256 _amount = _newLocked.amount.toUint256();
        permanentLockBalance += _amount;
        _newLocked.end = 0;
        _newLocked.isPermanent = true;
        _checkpoint(_tokenId, _locked[_tokenId], _newLocked);
        _locked[_tokenId] = _newLocked;

        emit LockPermanent(sender, _tokenId, _amount, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /// @inheritdoc IVotingEscrow
    function unlockPermanent(uint256 _tokenId) external {
        address sender = _msgSender();
        if (!_isApprovedOrOwner(sender, _tokenId)) revert NotApprovedOrOwner();
        if (escrowType[_tokenId] != EscrowType.NORMAL) revert NotNormalNFT();
        if (voted[_tokenId]) revert AlreadyVoted();
        LockedBalance memory _newLocked = _locked[_tokenId];
        if (!_newLocked.isPermanent) revert NotPermanentLock();

        uint256 _amount = _newLocked.amount.toUint256();
        permanentLockBalance -= _amount;
        _newLocked.end = ((block.timestamp + MAXTIME) / WEEK) * WEEK;
        _newLocked.isPermanent = false;
        _delegate(_tokenId, 0);
        _checkpoint(_tokenId, _locked[_tokenId], _newLocked);
        _locked[_tokenId] = _newLocked;

        emit UnlockPermanent(sender, _tokenId, _amount, block.timestamp);
        emit MetadataUpdate(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                           GAUGE VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    function _balanceOfNFTAt(uint256 _tokenId, uint256 _t) internal view returns (uint256) {
        return BalanceLogicLibrary.balanceOfNFTAt(userPointEpoch, _userPointHistory, _tokenId, _t);
    }

    function _supplyAt(uint256 _timestamp) internal view returns (uint256) {
        return BalanceLogicLibrary.supplyAt(slopeChanges, _pointHistory, epoch, _timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOfNFT(uint256 _tokenId) public view returns (uint256) {
        if (ownershipChange[_tokenId] == block.number) return 0;
        return _balanceOfNFTAt(_tokenId, block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256) {
        return _balanceOfNFTAt(_tokenId, _t);
    }

    /// @inheritdoc IVotingEscrow
    function totalSupply() external view returns (uint256) {
        return _supplyAt(block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function totalSupplyAt(uint256 _timestamp) external view returns (uint256) {
        return _supplyAt(_timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                            GAUGE VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => bool) public voted;

    /// @inheritdoc IVotingEscrow
    function setVoterAndDistributor(address _voter, address _distributor) external {
        if (_msgSender() != voter) revert NotVoter();
        voter = _voter;
        distributor = _distributor;
    }

    /// @inheritdoc IVotingEscrow
    function voting(uint256 _tokenId, bool _voted) external {
        if (_msgSender() != voter) revert NotVoter();
        voted[_tokenId] = _voted;
    }

    /*///////////////////////////////////////////////////////////////
                            DAO VOTING STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(uint256 delegator,uint256 delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of each accounts delegate
    mapping(uint256 => uint256) private _delegates;

    /// @notice A record of delegated token checkpoints for each tokenId, by index
    mapping(uint256 => mapping(uint48 => Checkpoint)) private _checkpoints;

    /// @inheritdoc IVotingEscrow
    mapping(uint256 => uint48) public numCheckpoints;

    /// @inheritdoc IVotingEscrow
    mapping(address => uint256) public nonces;

    /// @inheritdoc IVotingEscrow
    function delegates(uint256 delegator) external view returns (uint256) {
        return _delegates[delegator];
    }

    /// @inheritdoc IVotingEscrow
    function checkpoints(uint256 _tokenId, uint48 _index) external view returns (Checkpoint memory) {
        return _checkpoints[_tokenId][_index];
    }

    /// @inheritdoc IVotingEscrow
    function getPastVotes(address _account, uint256 _tokenId, uint256 _timestamp) external view returns (uint256) {
        return DelegationLogicLibrary.getPastVotes(numCheckpoints, _checkpoints, _account, _tokenId, _timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function getPastTotalSupply(uint256 _timestamp) external view returns (uint256) {
        return _supplyAt(_timestamp);
    }

    /*///////////////////////////////////////////////////////////////
                             DAO VOTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function _checkpointDelegator(uint256 _delegator, uint256 _delegatee, address _owner) internal {
        DelegationLogicLibrary.checkpointDelegator(
            _locked,
            numCheckpoints,
            _checkpoints,
            _delegates,
            _delegator,
            _delegatee,
            _owner
        );
    }

    function _checkpointDelegatee(uint256 _delegatee, uint256 balance_, bool _increase) internal {
        DelegationLogicLibrary.checkpointDelegatee(numCheckpoints, _checkpoints, _delegatee, balance_, _increase);
    }

    /// @notice Record user delegation checkpoints. Used by voting system.
    /// @dev Skips delegation if already delegated to `delegatee`.
    function _delegate(uint256 _delegator, uint256 _delegatee) internal {
        LockedBalance memory delegateLocked = _locked[_delegator];
        if (!delegateLocked.isPermanent) revert NotPermanentLock();
        if (_delegatee != 0 && _ownerOf(_delegatee) == address(0)) revert NonExistentToken();
        if (ownershipChange[_delegator] == block.number) revert OwnershipChange();
        if (_delegatee == _delegator) _delegatee = 0;
        uint256 currentDelegate = _delegates[_delegator];
        if (currentDelegate == _delegatee) return;

        uint256 delegatedBalance = delegateLocked.amount.toUint256();
        _checkpointDelegator(_delegator, _delegatee, _ownerOf(_delegator));
        _checkpointDelegatee(_delegatee, delegatedBalance, true);

        emit DelegateChanged(_msgSender(), currentDelegate, _delegatee);
    }

    /// @inheritdoc IVotingEscrow
    function delegate(uint256 delegator, uint256 delegatee) external {
        if (!_isApprovedOrOwner(_msgSender(), delegator)) revert NotApprovedOrOwner();
        return _delegate(delegator, delegatee);
    }

    /// @inheritdoc IVotingEscrow
    function delegateBySig(
        uint256 delegator,
        uint256 delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) revert InvalidSignatureS();
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegator, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        if (!_isApprovedOrOwner(signatory, delegator)) revert NotApprovedOrOwner();
        if (signatory == address(0)) revert InvalidSignature();
        if (nonce != nonces[signatory]++) revert InvalidNonce();
        if (block.timestamp > expiry) revert SignatureExpired();
        return _delegate(delegator, delegatee);
    }

    /*//////////////////////////////////////////////////////////////
                              ERC6372 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IVotingEscrow
    function clock() external view returns (uint48) {
        return uint48(block.timestamp);
    }

    /// @inheritdoc IVotingEscrow
    function CLOCK_MODE() external pure returns (string memory) {
        return "mode=timestamp";
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IForwarder.sol";

contract Forwarder is IForwarder {
    using ECDSA for bytes32;

    string public constant GENERIC_PARAMS = "address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil";

    string public constant EIP712_DOMAIN_TYPE = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";

    mapping(bytes32 => bool) public typeHashes;
    mapping(bytes32 => bool) public domains;

    // Nonces of senders, used to prevent replay attacks
    mapping(address => uint256) private nonces;

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function getNonce(address from)
    public view override
    returns (uint256) {
        return nonces[from];
    }

    constructor() {

        string memory requestType = string(abi.encodePacked("ForwardRequest(", GENERIC_PARAMS, ")"));
        registerRequestTypeInternal(requestType);
    }

    function verify(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    external override view {

        _verifyNonce(req);
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
    }

    function execute(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig
    )
    external payable
    override
    returns (bool success, bytes memory ret) {
        _verifySig(req, domainSeparator, requestTypeHash, suffixData, sig);
        _verifyAndUpdateNonce(req);

        require(req.validUntil == 0 || req.validUntil > block.number, "FWD: request expired");

        uint gasForTransfer = 0;
        if ( req.value != 0 ) {
            gasForTransfer = 40000; //buffer in case we need to move eth after the transaction.
        }
        bytes memory callData = abi.encodePacked(req.data, req.from);
        require(gasleft()*63/64 >= req.gas + gasForTransfer, "FWD: insufficient gas");
        // solhint-disable-next-line avoid-low-level-calls
        (success,ret) = req.to.call{gas : req.gas, value : req.value}(callData);
        if ( req.value != 0 && address(this).balance>0 ) {
            // can't fail: req.from signed (off-chain) the request, so it must be an EOA...
            payable(req.from).transfer(address(this).balance);
        }

        return (success,ret);
    }


    function _verifyNonce(ForwardRequest calldata req) internal view {
        require(nonces[req.from] == req.nonce, "FWD: nonce mismatch");
    }

    function _verifyAndUpdateNonce(ForwardRequest calldata req) internal {
        require(nonces[req.from]++ == req.nonce, "FWD: nonce mismatch");
    }

    function registerRequestType(string calldata typeName, string calldata typeSuffix) external override {

        for (uint i = 0; i < bytes(typeName).length; i++) {
            bytes1 c = bytes(typeName)[i];
            require(c != "(" && c != ")", "FWD: invalid typename");
        }

        string memory requestType = string(abi.encodePacked(typeName, "(", GENERIC_PARAMS, ",", typeSuffix));
        registerRequestTypeInternal(requestType);
    }

    function registerDomainSeparator(string calldata name, string calldata version) external override {
        uint256 chainId;
        /* solhint-disable-next-line no-inline-assembly */
        assembly { chainId := chainid() }

        bytes memory domainValue = abi.encode(
            keccak256(bytes(EIP712_DOMAIN_TYPE)),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId,
            address(this));

        bytes32 domainHash = keccak256(domainValue);

        domains[domainHash] = true;
        emit DomainRegistered(domainHash, domainValue);
    }

    function registerRequestTypeInternal(string memory requestType) internal {

        bytes32 requestTypehash = keccak256(bytes(requestType));
        typeHashes[requestTypehash] = true;
        emit RequestTypeRegistered(requestTypehash, requestType);
    }

    function _verifySig(
        ForwardRequest calldata req,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata sig)
    internal
    view
    {
        require(domains[domainSeparator], "FWD: unregistered domain sep.");
        require(typeHashes[requestTypeHash], "FWD: unregistered typehash");
        bytes32 digest = keccak256(abi.encodePacked(
                "\x19\x01", domainSeparator,
                keccak256(_getEncoded(req, requestTypeHash, suffixData))
            ));
        require(digest.recover(sig) == req.from, "FWD: signature mismatch");
    }

    function _getEncoded(
        ForwardRequest calldata req,
        bytes32 requestTypeHash,
        bytes calldata suffixData
    )
    public
    pure
    returns (
        bytes memory
    ) {
        // we use encodePacked since we append suffixData as-is, not as dynamic param.
        // still, we must make sure all first params are encoded as abi.encode()
        // would encode them - as 256-bit-wide params.
        return abi.encodePacked(
            requestTypeHash,
            uint256(uint160(req.from)),
            uint256(uint160(req.to)),
            req.value,
            req.gas,
            req.nonce,
            keccak256(req.data),
            req.validUntil,
            suffixData
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IForwarder {

    struct ForwardRequest {
        address from;
        address to;
        uint256 value;
        uint256 gas;
        uint256 nonce;
        bytes data;
        uint256 validUntil;
    }

    event DomainRegistered(bytes32 indexed domainSeparator, bytes domainValue);

    event RequestTypeRegistered(bytes32 indexed typeHash, string typeStr);

    function getNonce(address from)
    external view
    returns(uint256);

    /**
     * verify the transaction would execute.
     * validate the signature and the nonce of the request.
     * revert if either signature or nonce are incorrect.
     * also revert if domainSeparator or requestTypeHash are not registered.
     */
    function verify(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    ) external view;

    /**
     * execute a transaction
     * @param forwardRequest - all transaction parameters
     * @param domainSeparator - domain used when signing this request
     * @param requestTypeHash - request type used when signing this request.
     * @param suffixData - the extension data used when signing this request.
     * @param signature - signature to validate.
     *
     * the transaction is verified, and then executed.
     * the success and ret of "call" are returned.
     * This method would revert only verification errors. target errors
     * are reported using the returned "success" and ret string
     */
    function execute(
        ForwardRequest calldata forwardRequest,
        bytes32 domainSeparator,
        bytes32 requestTypeHash,
        bytes calldata suffixData,
        bytes calldata signature
    )
    external payable
    returns (bool success, bytes memory ret);

    /**
     * Register a new Request typehash.
     * @param typeName - the name of the request type.
     * @param typeSuffix - any extra data after the generic params.
     *  (must add at least one param. The generic ForwardRequest type is always registered by the constructor)
     */
    function registerRequestType(string calldata typeName, string calldata typeSuffix) external;

    /**
     * Register a new domain separator.
     * The domain separator must have the following fields: name,version,chainId, verifyingContract.
     * the chainId is the current network's chainId, and the verifyingContract is this forwarder.
     * This method is given the domain name and version to create and register the domain separator value.
     * @param name the domain's display name
     * @param version the domain/protocol version
     */
    function registerDomainSeparator(string calldata name, string calldata version) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC5267 {
    /**
     * @dev MAY be emitted to signal that the domain could have changed.
     */
    event EIP712DomainChanged();

    /**
     * @dev returns the fields and values that describe the domain separator used by this contract for EIP-712
     * signature.
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (interfaces/IERC6372.sol)

pragma solidity ^0.8.0;

interface IERC6372 {
    /**
     * @dev Clock used for flagging checkpoints. Can be overridden to implement timestamp based checkpoints (and voting).
     */
    function clock() external view returns (uint48);

    /**
     * @dev Description of the clock
     */
    // solhint-disable-next-line func-name-mixedcase
    function CLOCK_MODE() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
     * block, the requested block number must be in the past, excluding the current block.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(
        History storage self
    ) internal view returns (bool exists, uint32 _blockNumber, uint224 _value) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(Checkpoint[] storage self, uint32 key, uint224 value) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._blockNumber <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(Trace224 storage self, uint32 key, uint224 value) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     *
     * NOTE: This is a variant of {upperLookup} that is optimised to find "recent" checkpoint (checkpoints with high keys).
     */
    function upperLookupRecent(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self) internal view returns (bool exists, uint32 _key, uint224 _value) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(Checkpoint224[] storage self, uint32 key, uint224 value) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._key <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(
        Checkpoint224[] storage self,
        uint256 pos
    ) private pure returns (Checkpoint224 storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(Trace160 storage self, uint96 key, uint160 value) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     *
     * NOTE: This is a variant of {upperLookup} that is optimised to find "recent" checkpoint (checkpoints with high keys).
     */
    function upperLookupRecent(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self) internal view returns (bool exists, uint96 _key, uint160 _value) {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(Checkpoint160[] storage self, uint96 key, uint160 value) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._key <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(
        Checkpoint160[] storage self,
        uint256 pos
    ) private pure returns (Checkpoint160 storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    /**
     * @dev Returns an Ethereum Signed Data with intended validator, created from a
     * `validator` and `data` according to the version 0 of EIP-191.
     *
     * See {recover}.
     */
    function toDataWithIntendedValidatorHash(address validator, bytes memory data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x00", validator, data));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.8;

import "./ECDSA.sol";
import "../ShortStrings.sol";
import "../../interfaces/IERC5267.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * NOTE: In the upgradeable version of this contract, the cached values will correspond to the address, and the domain
 * separator of the implementation contract. This will cause the `_domainSeparatorV4` function to always rebuild the
 * separator from the immutable values, which is cheaper than accessing a cached version in cold storage.
 *
 * _Available since v3.4._
 *
 * @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
 */
abstract contract EIP712 is IERC5267 {
    using ShortStrings for *;

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _cachedDomainSeparator;
    uint256 private immutable _cachedChainId;
    address private immutable _cachedThis;

    ShortString private immutable _name;
    ShortString private immutable _version;
    string private _nameFallback;
    string private _versionFallback;

    bytes32 private immutable _hashedName;
    bytes32 private immutable _hashedVersion;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        _name = name.toShortStringWithFallback(_nameFallback);
        _version = version.toShortStringWithFallback(_versionFallback);
        _hashedName = keccak256(bytes(name));
        _hashedVersion = keccak256(bytes(version));

        _cachedChainId = block.chainid;
        _cachedDomainSeparator = _buildDomainSeparator();
        _cachedThis = address(this);
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _cachedThis && block.chainid == _cachedChainId) {
            return _cachedDomainSeparator;
        } else {
            return _buildDomainSeparator();
        }
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev See {EIP-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        override
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _name.toStringWithFallback(_nameFallback),
            _version.toStringWithFallback(_versionFallback),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "./StorageSlot.sol";

type ShortString is bytes32;

/**
 * @dev This library provides functions to convert short memory strings
 * into a `ShortString` type that can be used as an immutable variable.
 * Strings of arbitrary length can be optimized if they are short enough by
 * the addition of a storage variable used as fallback.
 *
 * Usage example:
 *
 * ```solidity
 * contract Named {
 *     using ShortStrings for *;
 *
 *     ShortString private immutable _name;
 *     string private _nameFallback;
 *
 *     constructor(string memory contractName) {
 *         _name = contractName.toShortStringWithFallback(_nameFallback);
 *     }
 *
 *     function name() external view returns (string memory) {
 *         return _name.toStringWithFallback(_nameFallback);
 *     }
 * }
 * ```
 */
library ShortStrings {
    error StringTooLong(string str);

    /**
     * @dev Encode a string of at most 31 chars into a `ShortString`.
     *
     * This will trigger a `StringTooLong` error is the input string is too long.
     */
    function toShortString(string memory str) internal pure returns (ShortString) {
        bytes memory bstr = bytes(str);
        if (bstr.length > 31) {
            revert StringTooLong(str);
        }
        return ShortString.wrap(bytes32(uint256(bytes32(bstr)) | bstr.length));
    }

    /**
     * @dev Decode a `ShortString` back to a "normal" string.
     */
    function toString(ShortString sstr) internal pure returns (string memory) {
        uint256 len = length(sstr);
        // using `new string(len)` would work locally but is not memory safe.
        string memory str = new string(32);
        /// @solidity memory-safe-assembly
        assembly {
            mstore(str, len)
            mstore(add(str, 0x20), sstr)
        }
        return str;
    }

    /**
     * @dev Return the length of a `ShortString`.
     */
    function length(ShortString sstr) internal pure returns (uint256) {
        return uint256(ShortString.unwrap(sstr)) & 0xFF;
    }

    /**
     * @dev Encode a string into a `ShortString`, or write it to storage if it is too long.
     */
    function toShortStringWithFallback(string memory value, string storage store) internal returns (ShortString) {
        if (bytes(value).length < 32) {
            return toShortString(value);
        } else {
            StorageSlot.getStringSlot(store).value = value;
            return ShortString.wrap(0);
        }
    }

    /**
     * @dev Decode a string that was encoded to `ShortString` or written to storage using {setWithFallback}.
     */
    function toStringWithFallback(ShortString value, string storage store) internal pure returns (string memory) {
        if (length(value) > 0) {
            return toString(value);
        } else {
            return store;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, `uint256`._
 * _Available since v4.9 for `string`, `bytes`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    struct StringSlot {
        string value;
    }

    struct BytesSlot {
        bytes value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` with member `value` located at `slot`.
     */
    function getStringSlot(bytes32 slot) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `StringSlot` representation of the string storage pointer `store`.
     */
    function getStringSlot(string storage store) internal pure returns (StringSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` with member `value` located at `slot`.
     */
    function getBytesSlot(bytes32 slot) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BytesSlot` representation of the bytes storage pointer `store`.
     */
    function getBytesSlot(bytes storage store) internal pure returns (BytesSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := store.slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```solidity
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 *
 * CAUTION: This file is deprecated as of 4.9 and will be removed in the next major release.
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}