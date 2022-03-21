pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "./inheritance/Constants.sol";
import "./inheritance/ControllableInit.sol";
import "./interfaces/IController.sol";
import "./interfaces/IUpgradeSource.sol";
import "./interfaces/IUniversalLiquidator.sol";
import "./interfaces/uniswap/IUniswapV2Router02.sol";
import "./interfaces/uniswap/IUniswapV3Router.sol";
import "./upgradability/BaseUpgradeableStrategyStorage.sol";


/**
 * @dev This contract can be redeployed many times, as new routers are added into `Constants.sol` since fields are added
 *      via slots. This contract is responsible for liquidating tokens and is intended to be called by the
 *      `RewardForwarder` when `doHardWork` is initiated
 */
contract UniversalLiquidatorV1 is IUniversalLiquidator, ControllableInit, BaseUpgradeableStrategyStorage, Constants {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // ==================== Constants ====================

    bytes32 internal constant _PATH_TO_ROUTER_MAP_SLOT = 0xec75aba63bae097c93338983427905512acbafbbc4eeae15ba15b9aa6496e824;
    bytes32 internal constant _PATH_MAP_SLOT = 0x0e02e180b6adbb3b4f2512fc78c9b64fc852c781e663bd17448786d7fe4d2252;

    // ==================== Modifiers ====================

    modifier restricted() {
        require(msg.sender == controller() || msg.sender == governance(),
            "The sender has to be the controller, governance, or vault");
        _;
    }

    constructor() public {
        assert(_PATH_TO_ROUTER_MAP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pathToRouterMap")) - 1));
        assert(_PATH_MAP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pathMap")) - 1));
    }

    // ==================== Events ====================

    event SwapConfigured(address inputToken, address outputToken, address router, address[] path);

    // ==================== Functions ====================

    function initializeUniversalLiquidator(
        address _storage
    ) public initializer {
        ControllableInit.initialize(_storage);

        // WETH output token
        _configureSwap(_address2ToMemory([CRV, WETH]), UNISWAP_V3_ROUTER);
        _configureSwap(_address2ToMemory([DAI, WETH]), UNISWAP_V3_ROUTER);
        _configureSwap(_address2ToMemory([SUSHI, WETH]), SUSHI_ROUTER);
        _configureSwap(_address2ToMemory([USDC, WETH]), UNISWAP_V3_ROUTER);
        _configureSwap(_address2ToMemory([USDT, WETH]), UNISWAP_V3_ROUTER);
        _configureSwap(_address2ToMemory([WBTC, WETH]), UNISWAP_V3_ROUTER);

        // USDC output token
        _configureSwap(_address2ToMemory([WETH, USDC]), UNISWAP_V3_ROUTER);
    }

    function shouldUpgrade() public view returns (bool, address) {
        return (nextImplementation() != address(0), nextImplementation());
    }

    function scheduleUpgrade(
        address _nextImplementation
    ) external onlyGovernance {
        _setNextImplementation(_nextImplementation);
        emit UpgradeScheduled(_nextImplementation, block.timestamp);
    }

    function finalizeUpgrade() public onlyGovernance {
        _setNextImplementation(address(0));
    }

    function configureSwap(
        address[] calldata _path,
        address _router
    ) external onlyGovernance {
        _configureSwap(_path, _router);
    }

    function configureSwaps(
        address[][] memory _paths,
        address[] memory _routers
    ) public onlyGovernance {
        require(_paths.length == _routers.length, "invalid paths or routers length");
        for (uint i = 0; i < _routers.length; i++) {
            _configureSwap(_paths[i], _routers[i]);
        }
    }

    function getSwapRouter(
        address _inputToken,
        address _outputToken
    ) public view returns (address router) {
        bytes32 slot = _getSlotForRouter(_inputToken, _outputToken);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            router := sload(slot)
        }
    }

    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) external returns (uint) {
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);

        if (_tokenIn == _tokenOut) {
            // if the input and output tokens are the same, return amountIn
            uint amountOut = _amountIn;
            IERC20(_tokenIn).safeTransfer(_recipient, amountOut);
            return amountOut;
        }

        address[] memory path = new address[](_tokenOut != WETH ? 3 : 2);
        path[0] = _tokenIn;
        if (_tokenOut != WETH) {
            path[1] = WETH;
        }
        path[path.length - 1] = _tokenOut;

        for (uint i = 0; i < path.length - 1; i++) {
            address router = getAddress(_getSlotForRouter(path[i], path[i + 1]));
            require(
                router != address(0),
                "invalid router for path"
            );
            if (IERC20(path[i]).allowance(address(this), router) < _amountIn) {
                IERC20(path[i]).safeApprove(router, 0);
                IERC20(path[i]).safeApprove(router, _amountIn);
            }

            _amountIn = _performSwap(
                router,
                path[i],
                path[i + 1],
                _amountIn,
                i == path.length - 2 ? _amountOutMin : 1,
                i == path.length - 2 ? _recipient : address(this)
            );
        }

        // we re-assigned amountIn to be eq to amountOut, so this require statement makes sense
        require(
            _amountIn >= _amountOutMin,
            "insufficient amount out"
        );

        return _amountIn;
    }

    function _address2ToMemory(
        address[2] memory _tokens
    ) internal pure returns (address[] memory) {
        address[] memory dynamicTokens = new address[](_tokens.length);
        for (uint i = 0; i < _tokens.length; i++) {
            dynamicTokens[i] = _tokens[i];
        }
        return dynamicTokens;
    }

    function _performSwap(
        address _router,
        address _tokenIn,
        address _tokenOut,
        uint _amountIn,
        uint _amountOutMin,
        address _recipient
    ) internal returns (uint amountOut) {
        // TODO add Dolomite router
        if (_router == SUSHI_ROUTER) {
            address[] memory path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;

            amountOut = IUniswapV2Router02(_router).swapExactTokensForTokens(
                _amountIn,
                _amountOutMin,
                path,
                _recipient,
                block.timestamp
            )[path.length - 1];
        } else if (_router == UNISWAP_V3_ROUTER) {
            IUniswapV3Router.ExactInputSingleParams memory params = IUniswapV3Router.ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: 3000,
                recipient: _recipient,
                deadline: block.timestamp,
                amountIn: _amountIn,
                amountOutMinimum: _amountOutMin,
                sqrtPriceLimitX96: 0
            });
            amountOut = IUniswapV3Router(_router).exactInputSingle(params);
        } else {
            revert("unknown router");
        }
    }

    function _configureSwap(
        address[] memory path,
        address router
    ) internal {
        require(
            path.length == 2,
            "invalid path length, expected == 2"
        );
        setAddressArray(_getSlotForPath(path[0], path[path.length - 1]), path);
        setAddress(_getSlotForRouter(path[0], path[path.length - 1]), router);
        emit SwapConfigured(path[0], path[path.length - 1], router, path);
    }

    function _getSlotForPath(address _inputToken, address _outputToken) internal pure returns (bytes32) {
        bytes32 valueSlot = keccak256(abi.encodePacked(_inputToken, _outputToken));
        return keccak256(abi.encodePacked(_PATH_MAP_SLOT, valueSlot));
    }

    function _getSlotForRouter(address _inputToken, address _outputToken) internal pure returns (bytes32) {
        bytes32 valueSlot = keccak256(abi.encodePacked(_inputToken, _outputToken));
        return keccak256(abi.encodePacked(_PATH_TO_ROUTER_MAP_SLOT, valueSlot));
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

pragma solidity ^0.5.16;


contract Constants {

    address constant public CRV = 0x11cDb42B0EB46D95f990BeDD4695A6e3fA034978;

    address constant public CRV_TRI_CRYPTO = 0x8e0B8c8BB9db49a46697F3a5Bb8A308e744821D2;

    address constant public CRV_TRI_CRYPTO_GAUGE = 0x97E2768e8E73511cA874545DC5Ff8067eB19B787;

    address constant public CRV_TRI_CRYPTO_POOL = 0x960ea3e3C7FB317332d990873d354E18d7645590;

    address constant public DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;

    /// @notice Used as governance
    address constant public DEFAULT_MULTI_SIG_ADDRESS = 0xb39710a1309847363b9cBE5085E427cc2cAeE563;

    // We can set this later once we know the address
//    address constant public FARM = 0x0000000000000000000000000000000000000000;

    address constant public LINK = 0xf97f4df75117a78c1A5a0DBb814Af92458539FB4;

    address constant public ONE_INCH = 0x0000000000000000000000000000000000000000;

    address constant public ONE_INCH_CALLER = 0x0000000000000000000000000000000000000000;

    address constant public SUSHI = 0xd4d42F0b6DEF4CE0383636770eF773390d85c61A;

    address constant public SUSHI_ROUTER = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    address constant public UNI = 0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0;

    address constant public UNISWAP_V3_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;

    address constant public USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;

    address constant public USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    address constant public WBTC = 0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f;

    address constant public WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
}

pragma solidity ^0.5.16;

import "./GovernableInit.sol";


/**
 * A clone of Governable supporting the Initializable interface and pattern
 */
contract ControllableInit is GovernableInit {

    constructor() public {
    }

    function initialize(address _storage) public initializer {
        GovernableInit.initialize(_storage);
    }

    modifier onlyController() {
        require(Storage(_storage()).isController(msg.sender), "Not a controller");
        _;
    }

    modifier onlyControllerOrGovernance(){
        require(
          Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender),
          "The caller must be controller or governance"
        );
        _;
    }

    function controller() public view returns (address) {
        return Storage(_storage()).controller();
    }
}

pragma solidity ^0.5.16;

interface IController {

    // ==================== Events ====================

    event SharePriceChangeLog(
        address indexed vault,
        address indexed strategy,
        uint256 oldSharePrice,
        uint256 newSharePrice,
        uint256 timestamp
    );

    // ==================== Functions ====================

    /**
     * An EOA can safely interact with the system no matter what. If you're using Metamask, you're using an EOA. Only
     * smart contracts may be affected by this grey list. This contract will not be able to ban any EOA from the system
     * even if an EOA is being added to the greyList, he/she will still be able to interact with the whole system as if
     * nothing happened. Only smart contracts will be affected by being added to the greyList. This grey list is only
     * used in VaultV3.sol, see the code there for reference
     */
    function greyList(address _target) external view returns (bool);

    function stakingWhiteList(address _target) external view returns (bool);

    function store() external view returns (address);

    function governance() external view returns (address);

    function hasVault(address _vault) external view returns (bool);

    function hasStrategy(address _strategy) external view returns (bool);

    function addVaultAndStrategy(address _vault, address _strategy) external;

    function addVaultsAndStrategies(address[] calldata _vaults, address[] calldata _strategies) external;

    function doHardWork(
        address _vault,
        uint256 _hint,
        uint256 _deviationNumerator,
        uint256 _deviationDenominator
    ) external;

    function addHardWorker(address _worker) external;

    function removeHardWorker(address _worker) external;

    function salvage(address _token, uint256 amount) external;

    function salvageStrategy(address _strategy, address _token, uint256 amount) external;

    /**
     * @return The targeted profit token to convert all-non-compounding rewards to. Defaults to WETH.
     */
    function targetToken() external view returns (address);

    function setTargetToken(address _targetToken) external;

    function rewardForwarder() external view returns (address);

    function setRewardForwarder(address _rewardForwarder) external;

    function setUniversalLiquidator(address _universalLiquidator) external;

    function universalLiquidator() external view returns (address);

    function dolomiteYieldFarmingRouter() external view returns (address);

    function setDolomiteYieldFarmingRouter(address _value) external;

    function nextImplementationDelay() external view returns (uint256);

    function profitSharingNumerator() external view returns (uint256);

    function strategistFeeNumerator() external view returns (uint256);

    function platformFeeNumerator() external view returns (uint256);

    function profitSharingDenominator() external view returns (uint256);

    function strategistFeeDenominator() external view returns (uint256);

    function platformFeeDenominator() external view returns (uint256);

    function setProfitSharingNumerator(uint _profitSharingNumerator) external;

    function confirmSetProfitSharingNumerator() external;

    function setStrategistFeeNumerator(uint _strategistFeeNumerator) external;

    function confirmSetStrategistFeeNumerator() external;

    function setPlatformFeeNumerator(uint _platformFeeNumerator) external;

    function confirmSetPlatformFeeNumerator() external;

    function nextProfitSharingNumerator() external view returns (uint256);

    function nextProfitSharingNumeratorTimestamp() external view returns (uint256);

    function nextStrategistFeeNumerator() external view returns (uint256);

    function nextStrategistFeeNumeratorTimestamp() external view returns (uint256);

    function nextPlatformFeeNumerator() external view returns (uint256);

    function nextPlatformFeeNumeratorTimestamp() external view returns (uint256);
}

pragma solidity ^0.5.16;


interface IUpgradeSource {

  function shouldUpgrade() external view returns (bool, address);

  function finalizeUpgrade() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


/**
 * @dev A contract that handles all liquidations from an `inputToken` to an `outputToken`. This contract simplifies
 *      all swap logic so strategies can be focused on management of funds and forwarding gains to this contract
 *      for the most efficient liquidation. If the liquidation path of an asset changes, governance needs only to
 *      create a new instance of this contract or modify the liquidation path via `configureSwap`, and all callers of
 *      the contract benefit from the change and uniformity.
 */
interface IUniversalLiquidator {

    // ==================== Events ====================

    event Swap(
        address indexed buyToken,
        address indexed sellToken,
        address indexed recipient,
        address initiator,
        uint256 amountIn,
        uint256 slippage,
        uint256 total
    );

    // ==================== Functions ====================

    function governance() external view returns (address);

    function controller() external view returns (address);

    function nextImplementation() external view returns (address);

    function scheduleUpgrade(address _nextImplementation) external;

    /**
     * Constructor replacement because this contract is meant to be upgradable
     */
    function initializeUniversalLiquidator(
        address _storage
    ) external;

    /**
     * @param _path     The path that is used for selling token at path[0] into path[path.length - 1].
     * @param _router   The router to use for this path.
     */
    function configureSwap(
        address[] calldata _path,
        address _router
    ) external;

    /**
     * @param _paths    The paths that are used for selling token at path[i][0] into path[i][path[i].length - 1].
     * @param _routers  The routers to use for each index, `i`.
     */
    function configureSwaps(
        address[][] calldata _paths,
        address[] calldata _routers
    ) external;

    /**
     * @return The router used to execute the swap from `_inputToken` to `_outputToken`
     */
    function getSwapRouter(
        address _inputToken,
        address _outputToken
    ) external view returns (address);

    function swapTokens(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _recipient
    ) external returns (uint _amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IUniswapV2Router02 {

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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

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
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity ^0.5.4;
pragma experimental ABIEncoderV2;


interface IUniswapV3Router {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/upgrades/contracts/Initializable.sol";

import "../inheritance/ControllableInit.sol";

import "../interfaces/IController.sol";
import "../interfaces/IRewardForwarder.sol";
import "../interfaces/IUpgradeSource.sol";


contract BaseUpgradeableStrategyStorage is IUpgradeSource, ControllableInit {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ==================== Events ====================

    event ProfitsNotCollected(
        address indexed rewardToken,
        bool sell,
        bool floor
    );
    event ProfitLogInReward(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event ProfitAndBuybackLog(
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event PlatformFeeLogInReward(
        address indexed treasury,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );
    event StrategistFeeLogInReward(
        address indexed strategist,
        address indexed rewardToken,
        uint256 profitAmount,
        uint256 feeAmount,
        uint256 timestamp
    );

    event UnderlyingSet(address underlying);
    event RewardPoolSet(address rewardPool);
    event RewardTokensSet(address[] rewardTokens);
    event VaultSet(address vault);
    event StrategistSet(address strategist);
    event SellSet(bool shouldSell);
    event PausedInvestingSet(bool isInvestingPaused);
    event SellFloorSet(uint sellFloor);
    event UpgradeScheduled(address newImplementation, uint readyAtTimestamp);

    // ==================== Internal Constants ====================

    bytes32 internal constant _UNDERLYING_SLOT = 0xa1709211eeccf8f4ad5b6700d52a1a9525b5f5ae1e9e5f9e5a0c2fc23c86e530;
    bytes32 internal constant _VAULT_SLOT = 0xefd7c7d9ef1040fc87e7ad11fe15f86e1d11e1df03c6d7c87f7e1f4041f08d41;

    bytes32 internal constant _REWARD_TOKENS_SLOT = 0x45418d9b5c2787ae64acbffccad43f2b487c1a16e24385aa9d2b059f9d1d163c;
    bytes32 internal constant _REWARD_POOL_SLOT = 0x3d9bb16e77837e25cada0cf894835418b38e8e18fbec6cfd192eb344bebfa6b8;
    bytes32 internal constant _SELL_FLOOR_SLOT = 0xc403216a7704d160f6a3b5c3b149a1226a6080f0a5dd27b27d9ba9c022fa0afc;
    bytes32 internal constant _SELL_SLOT = 0x656de32df98753b07482576beb0d00a6b949ebf84c066c765f54f26725221bb6;
    bytes32 internal constant _PAUSED_INVESTING_SLOT = 0xa07a20a2d463a602c2b891eb35f244624d9068572811f63d0e094072fb54591a;

    bytes32 internal constant _PROFIT_SHARING_NUMERATOR_SLOT = 0xe3ee74fb7893020b457d8071ed1ef76ace2bf4903abd7b24d3ce312e9c72c029;
    bytes32 internal constant _PROFIT_SHARING_DENOMINATOR_SLOT = 0x0286fd414602b432a8c80a0125e9a25de9bba96da9d5068c832ff73f09208a3b;

    bytes32 internal constant _NEXT_IMPLEMENTATION_SLOT = 0x29f7fcd4fe2517c1963807a1ec27b0e45e67c60a874d5eeac7a0b1ab1bb84447;
    bytes32 internal constant _NEXT_IMPLEMENTATION_TIMESTAMP_SLOT = 0x414c5263b05428f1be1bfa98e25407cc78dd031d0d3cd2a2e3d63b488804f22e;
    bytes32 internal constant _NEXT_IMPLEMENTATION_DELAY_SLOT = 0x82b330ca72bcd6db11a26f10ce47ebcfe574a9c646bccbc6f1cd4478eae16b31;

    bytes32 internal constant _STRATEGIST_SLOT = 0x6a7b588c950d46e2de3db2f157e5e0e4f29054c8d60f17bf0c30352e223a458d;

    constructor() public {
        assert(_UNDERLYING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.underlying")) - 1));
        assert(_VAULT_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.vault")) - 1));
        assert(_REWARD_TOKENS_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardTokens")) - 1));
        assert(_REWARD_POOL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.rewardPool")) - 1));
        assert(_SELL_FLOOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sellFloor")) - 1));
        assert(_SELL_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.sell")) - 1));
        assert(_PAUSED_INVESTING_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.pausedInvesting")) - 1));

        assert(_PROFIT_SHARING_NUMERATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingNumerator")) - 1));
        assert(_PROFIT_SHARING_DENOMINATOR_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.profitSharingDenominator")) - 1));

        assert(_NEXT_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementation")) - 1));
        assert(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationTimestamp")) - 1));
        assert(_NEXT_IMPLEMENTATION_DELAY_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.nextImplementationDelay")) - 1));

        assert(_STRATEGIST_SLOT == bytes32(uint256(keccak256("eip1967.strategyStorage.strategist")) - 1));
    }

    // ==================== Internal Functions ====================

    function _setUnderlying(address _underlying) internal {
        setAddress(_UNDERLYING_SLOT, _underlying);
        emit UnderlyingSet(_underlying);
    }

    function underlying() public view returns (address) {
        return getAddress(_UNDERLYING_SLOT);
    }

    function _setRewardPool(address _rewardPool) internal {
        setAddress(_REWARD_POOL_SLOT, _rewardPool);
        emit RewardPoolSet(_rewardPool);
    }

    function rewardPool() public view returns (address) {
        return getAddress(_REWARD_POOL_SLOT);
    }

    function _setRewardTokens(address[] memory _rewardTokens) internal {
        setAddressArray(_REWARD_TOKENS_SLOT, _rewardTokens);
        emit RewardTokensSet(_rewardTokens);
    }

    function isRewardToken(address _token) public view returns (bool) {
        return _isAddressInList(_token, rewardTokens());
    }

    function rewardTokens() public view returns (address[] memory) {
        return getAddressArray(_REWARD_TOKENS_SLOT);
    }

    function _isAddressInList(address _searchValue, address[] memory _list) internal pure returns (bool) {
        for (uint i = 0; i < _list.length; i++) {
            if (_list[i] == _searchValue) {
                return true;
            }
        }
        return false;
    }

    function _setVault(address _vault) internal {
        setAddress(_VAULT_SLOT, _vault);
        emit VaultSet(_vault);
    }

    function vault() public view returns (address) {
        return getAddress(_VAULT_SLOT);
    }

    function _setStrategist(address _strategist) internal {
        setAddress(_STRATEGIST_SLOT, _strategist);
        emit StrategistSet(_strategist);
    }

    function strategist() public view returns (address) {
        return getAddress(_STRATEGIST_SLOT);
    }

    /**
     * @dev a flag for disabling selling for simplified emergency exit
     */
    function _setSell(bool _shouldSell) internal {
        setBoolean(_SELL_SLOT, _shouldSell);
        emit SellSet(_shouldSell);
    }

    function sell() public view returns (bool) {
        return getBoolean(_SELL_SLOT);
    }

    function _setPausedInvesting(bool _isInvestingPaused) internal {
        setBoolean(_PAUSED_INVESTING_SLOT, _isInvestingPaused);
        emit PausedInvestingSet(_isInvestingPaused);
    }

    function pausedInvesting() public view returns (bool) {
        return getBoolean(_PAUSED_INVESTING_SLOT);
    }

    function _setSellFloor(uint256 _value) internal {
        setUint256(_SELL_FLOOR_SLOT, _value);
        emit SellFloorSet(_value);
    }

    function sellFloor() public view returns (uint256) {
        return getUint256(_SELL_FLOOR_SLOT);
    }

    function profitSharingNumerator() public view returns (uint256) {
        return IController(controller()).profitSharingNumerator();
    }

    function profitSharingDenominator() public view returns (uint256) {
        return IController(controller()).profitSharingDenominator();
    }

    function strategistFeeNumerator() public view returns (uint256) {
        return IController(controller()).strategistFeeNumerator();
    }

    function strategistFeeDenominator() public view returns (uint256) {
        return IController(controller()).strategistFeeDenominator();
    }

    function platformFeeNumerator() public view returns (uint256) {
        return IController(controller()).platformFeeNumerator();
    }

    function platformFeeDenominator() public view returns (uint256) {
        return IController(controller()).platformFeeDenominator();
    }

    // ========================= Internal Functions for Upgradability =========================

    function _setNextImplementation(address _address) internal {
        // event is emitted in caller in subclass
        setAddress(_NEXT_IMPLEMENTATION_SLOT, _address);
    }

    function nextImplementation() public view returns (address) {
        return getAddress(_NEXT_IMPLEMENTATION_SLOT);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        // event is emitted in caller in subclass
        setUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT, _value);
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return getUint256(_NEXT_IMPLEMENTATION_TIMESTAMP_SLOT);
    }

    function nextImplementationDelay() public view returns (uint256) {
        return IController(controller()).nextImplementationDelay();
    }

    // ========================= Internal Functions for Primitives =========================

    function setBoolean(bytes32 slot, bool _value) internal {
        setUint256(slot, _value ? 1 : 0);
    }

    function getBoolean(bytes32 slot) internal view returns (bool) {
        return (getUint256(slot) == 1);
    }

    function setAddress(bytes32 slot, address _address) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _address)
        }
    }

    function setUint256(bytes32 slot, uint256 _value) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

    function setUint256Array(bytes32 slot, uint256[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setUint256(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function setAddressArray(bytes32 slot, address[] memory _values) internal {
        // solhint-disable-next-line no-inline-assembly
        setUint256(slot, _values.length);
        for (uint i = 0; i < _values.length; i++) {
            setAddress(bytes32(uint(slot) + 1 + i), _values[i]);
        }
    }

    function getUint256Array(bytes32 slot) internal view returns (uint[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new uint[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getUint256(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddressArray(bytes32 slot) internal view returns (address[] memory values) {
        // solhint-disable-next-line no-inline-assembly
        values = new address[](getUint256(slot));
        for (uint i = 0; i < values.length; i++) {
            values[i] = getAddress(bytes32(uint(slot) + 1 + i));
        }
    }

    function getAddress(bytes32 slot) internal view returns (address str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 str) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
    }
}

pragma solidity ^0.5.5;

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
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

pragma solidity ^0.5.16;

import "@openzeppelin/upgrades/contracts/Initializable.sol";
import "../upgradability/UpgradeableReentrancyGuard.sol";
import "./Storage.sol";


/**
 * A clone of Governable supporting the Initializable interface and pattern
 */
contract GovernableInit is UpgradeableReentrancyGuard {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor() public {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function initialize(address _store) public initializer {
    UpgradeableReentrancyGuard.initialize();
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "new storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

pragma solidity >=0.5.4;

import "@openzeppelin/upgrades/contracts/Initializable.sol";


/**
 * Same old `ReentrancyGuard`, but can be used by upgradable contracts
 */
contract UpgradeableReentrancyGuard is Initializable {

    bytes32 internal constant _NOT_ENTERED_SLOT = 0x62ae7bf2df4e95c187ea09c8c47c3fc3d9abc36298f5b5b6c5e2e7b4b291fe25;

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_getNotEntered(_NOT_ENTERED_SLOT), "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _setNotEntered(_NOT_ENTERED_SLOT, false);

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    constructor() public {
        assert(_NOT_ENTERED_SLOT == bytes32(uint256(keccak256("eip1967.reentrancyGuard.notEntered")) - 1));
    }

    function initialize() public initializer {
        _setNotEntered(_NOT_ENTERED_SLOT, true);
    }

    function _getNotEntered(bytes32 slot) private view returns (bool) {
        uint str;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            str := sload(slot)
        }
        return str == 1;
    }

    function _setNotEntered(bytes32 slot, bool _value) private {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _value)
        }
    }

}

pragma solidity ^0.5.16;

import "../interfaces/IController.sol";


contract Storage {

  event GovernanceChanged(address newGovernance);
  event GovernanceQueued(address newGovernance, uint implementationTimestamp);
  event ControllerChanged(address newController);
  event ControllerQueued(address newController, uint implementationTimestamp);

  address public governance;
  address public controller;

  address public nextGovernance;
  uint256 public nextGovernanceTimestamp;

  address public nextController;
  uint256 public nextControllerTimestamp;

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  constructor () public {
    governance = msg.sender;
    emit GovernanceChanged(msg.sender);
  }

  function setInitialController(address _controller) public onlyGovernance {
    require(
      controller == address(0),
      "controller already set"
    );
    require(
      IController(_controller).nextImplementationDelay() >= 0,
      "new controller doesn't get delay properly"
    );

    controller = _controller;
    emit ControllerChanged(_controller);
  }

  function nextImplementationDelay() public view returns (uint) {
    return IController(controller).nextImplementationDelay();
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    nextGovernance = _governance;
    nextGovernanceTimestamp = block.timestamp + nextImplementationDelay();
    emit GovernanceQueued(nextGovernance, nextGovernanceTimestamp);
  }

  function confirmGovernance() public onlyGovernance {
    require(
      nextGovernance != address(0) && nextGovernanceTimestamp != 0,
      "no governance queued"
    );
    require(
      block.timestamp >= nextGovernanceTimestamp,
      "governance not yet ready"
    );
    governance = nextGovernance;
    emit GovernanceChanged(governance);

    nextGovernance = address(0);
    nextGovernanceTimestamp = 0;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    require(IController(_controller).nextImplementationDelay() >= 0, "new controller doesn't get delay properly");

    nextController = _controller;
    nextControllerTimestamp = block.timestamp + nextImplementationDelay();
    emit ControllerQueued(nextController, nextControllerTimestamp);
  }

  function confirmController() public onlyGovernance {
    require(
      nextController != address(0) && nextControllerTimestamp != 0,
      "no controller queued"
    );
    require(
      block.timestamp >= nextControllerTimestamp,
      "controller not yet ready"
    );
    controller = nextController;
    emit ControllerChanged(controller);

    nextController = address(0);
    nextControllerTimestamp = 0;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}

pragma solidity ^0.5.16;


/**
 * @dev A routing contract that is responsible for taking the harvested gains and routing them into FARM and additional
 *      buyback tokens for the corresponding strategy
 */
interface IRewardForwarder {

    function store() external view returns (address);

    function governance() external view returns (address);

    /**
     * @dev This function sends converted `_buybackTokens` to `msg.sender`. The returned amounts will match the
     *      `amounts` return value. The fee amounts are converted to the profit sharing token and sent to the proper
     *      addresses (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @param _buybackTokens    the output tokens that `_buyBackAmounts` should be swapped to (outputToken)
     * @param _buybackAmounts   the amounts of `_token` that will be bought into more `_buybackTokens` token
     * @return The amounts that were purchased of _buybackTokens
     */
    function notifyFeeAndBuybackAmounts(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee,
        address[] calldata _buybackTokens,
        uint256[] calldata _buybackAmounts
    ) external returns (uint[] memory amounts);

    /**
     * @dev This function converts the fee amounts to the profit sharing token and sends them to the proper addresses
     *      (profit sharing, strategist, and governance (platform)).
     *
     * @param _token            the token that will be compounded or sold into the profit sharing token for the Harvest
     *                          collective (users that stake iFARM)
     * @param _profitSharingFee the amount of `_token` that will be sold into the profit sharing token
     * @param _strategistFee    the amount of `_token` that will be sold into the profit sharing token for the
     *                          strategist
     * @param _platformFee      the amount of `_token` that will be sold into the profit sharing token for the Harvest
     *                          treasury
     * @return The amounts that were purchased of _buybackTokens
     */
    function notifyFee(
        address _token,
        uint256 _profitSharingFee,
        uint256 _strategistFee,
        uint256 _platformFee
    ) external;

    function profitSharingPool() external view returns (address);
}