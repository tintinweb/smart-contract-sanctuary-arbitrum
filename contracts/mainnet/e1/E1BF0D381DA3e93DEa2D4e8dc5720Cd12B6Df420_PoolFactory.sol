// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Output {
    address recipient;
    uint eip;           // token standard: 0 for ETH or EIP number
    address token;      // token contract address
    uint id;            // token id for EIP721 and EIP1155
    uint amountOutMin;
}

struct Input {
    uint mode;
    address recipient;
    uint eip;           // token standard: 0 for ETH or EIP number
    address token;      // token contract address
    uint id;            // token id for EIP721 and EIP1155
    uint amountIn;
}

struct Action {
    Input[] inputs;
    address code;       // contract code address
    bytes data;         // contract input data
}

interface IUniversalTokenRouter {
    function exec(
        Output[] memory outputs,
        Action[] memory actions
    ) external payable;

    function pay(
        address sender,
        address recipient,
        uint eip,
        address token,
        uint id,
        uint amount
    ) external;

    function discard(
        address sender,
        uint eip,
        address token,
        uint id,
        uint amount
    ) external;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

struct Config {
    address TOKEN;
    address TOKEN_R;
    bytes32 ORACLE;
    uint K;
    uint MARK;
    uint INIT_TIME; // TODO: change to uint32
    uint HALF_LIFE; // TODO: change to uint32
}

struct Market {
    uint xkA;
    uint xkB;
}

struct State {
    uint R;
    uint a;
    uint b;
}

interface IAsymptoticPerpetual {
    function init(
        Config memory config,
        uint a,
        uint b
    ) external returns (uint rA, uint rB, uint rC);

    /**
     * @param payload passed to Helper.swapToState callback, should not used by this function
     */
    function swap(
        Config calldata config,
        uint sideIn,
        uint sideOut,
        address helper,
        bytes calldata payload
    ) external returns(uint amountIn, uint amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155Supply {
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) external view returns (uint256);

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) external view returns (bool);

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) external;

    function mintVirtualSupply(
        uint256 id,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

interface IPool {
    function TOKEN_R() external returns (address);
    function swap(
        uint sideIn,
        uint sideOut,
        address helper,
        bytes calldata payload,
        address payer,
        address recipient
    ) external returns(uint amountIn, uint amountOut);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

struct Params {
    address utr;
    address token;
    address logic;
    bytes32 oracle; // 1bit QTI, 31bit reserve, 32bit WINDOW, ... PAIR ADDRESS
    address reserveToken;
    address recipient;
    uint mark;
    uint32  initTime;
    uint    halfLife;
    uint k;
    uint a;
    uint b;
}

interface IPoolFactory {
    function getParams() external view returns (Params memory);
    function createPool(Params memory params) external returns (address pool);
    function computePoolAddress(Params memory params) external view returns (address pool);
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

contract Constants {
    uint internal constant Q64  = 1 << 64;
    uint internal constant Q80  = 1 << 80;
    uint internal constant Q192 = 1 << 192;
    uint internal constant Q255 = 1 << 255;
    uint internal constant Q128 = 1 << 128;
    uint internal constant Q256M = type(uint).max;

    uint internal constant SIDE_R = 0x00;
    uint internal constant SIDE_A = 0x10;
    uint internal constant SIDE_B = 0x20;
    uint internal constant SIDE_C = 0x30;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Events {
    event Derivable(
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        bytes32 indexed topic3,
        bytes data
    );

    struct SwapEvent {
        uint sideIn;
        uint sideOut;
        uint amountIn;
        uint amountOut;
        address payer;
        address recipient;
    }

    struct PoolCreated {
        address UTR;
        address TOKEN;
        address LOGIC;
        bytes32 ORACLE;
        address TOKEN_R;
        uint256 MARK;
        uint256 INIT_TIME;
        uint256 HALF_LIFE;
        uint256 k;
    }

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(addr)) << 96);
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

contract Storage {
    uint internal s_a;
    uint internal s_b;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@derivable/utr/contracts/interfaces/IUniversalTokenRouter.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IPoolFactory.sol";
import "./logics/Constants.sol";
import "./interfaces/IERC1155Supply.sol";
import "./interfaces/IAsymptoticPerpetual.sol";
import "./interfaces/IPool.sol";
import "./logics/Storage.sol";
import "./logics/Events.sol";

contract Pool is IPool, Storage, Events, Constants {
    uint public constant MINIMUM_LIQUIDITY = 10 ** 3;

    /// Immutables
    address internal immutable UTR;
    address internal immutable LOGIC;
    bytes32 internal immutable ORACLE;
    uint internal immutable K;
    address internal immutable TOKEN;
    address public immutable TOKEN_R;
    uint internal immutable MARK;
    uint internal immutable INIT_TIME;
    uint internal immutable HALF_LIFE;

    constructor() {
        Params memory params = IPoolFactory(msg.sender).getParams();
        // TODO: require(4*params.a*params.b <= params.R, "invalid (R,a,b)");
        UTR = params.utr;
        TOKEN = params.token;
        LOGIC = params.logic;
        ORACLE = params.oracle;
        TOKEN_R = params.reserveToken;
        K = params.k;
        MARK = params.mark;
        HALF_LIFE = params.halfLife;
        INIT_TIME = params.initTime > 0 ? params.initTime : block.timestamp;
        require(block.timestamp >= INIT_TIME, "PAST_INIT_TIME");

        (bool success, bytes memory result) = LOGIC.delegatecall(
            abi.encodeWithSelector(
                IAsymptoticPerpetual.init.selector,
                Config(
                    TOKEN,
                    TOKEN_R,
                    ORACLE,
                    K,
                    MARK,
                    INIT_TIME,
                    HALF_LIFE
                ),
                params.a,
                params.b
            )
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        (uint rA, uint rB, uint rC) = abi.decode(result, (uint, uint, uint));
        uint idA = _packID(address(this), SIDE_A);
        uint idB = _packID(address(this), SIDE_B);
        uint idC = _packID(address(this), SIDE_C);

        // permanently lock MINIMUM_LIQUIDITY for each side
        IERC1155Supply(TOKEN).mintVirtualSupply(idA, MINIMUM_LIQUIDITY);
        IERC1155Supply(TOKEN).mintVirtualSupply(idB, MINIMUM_LIQUIDITY);
        IERC1155Supply(TOKEN).mintVirtualSupply(idC, MINIMUM_LIQUIDITY);

        // mint tokens to recipient
        IERC1155Supply(TOKEN).mint(params.recipient, idA, rA - MINIMUM_LIQUIDITY, "");
        IERC1155Supply(TOKEN).mint(params.recipient, idB, rB - MINIMUM_LIQUIDITY, "");
        IERC1155Supply(TOKEN).mint(params.recipient, idC, rC - MINIMUM_LIQUIDITY, "");


        emit Derivable(
            'PoolCreated',                 // topic1: eventName
            _addressToBytes32(msg.sender), // topic2: factory
            _addressToBytes32(LOGIC),      // topic3: logic
            abi.encode(PoolCreated(
                UTR,
                TOKEN,
                LOGIC,
                ORACLE,
                TOKEN_R,
                MARK,
                INIT_TIME,
                HALF_LIFE,
                params.k
            ))
        );
    }

    function _packID(address pool, uint side) internal pure returns (uint id) {
        id = (side << 160) + uint160(pool);
    }

    function swap(
        uint sideIn,
        uint sideOut,
        address helper,
        bytes calldata payload,
        address payer,
        address recipient
    ) external override returns(uint amountIn, uint amountOut) {
        (bool success, bytes memory result) = LOGIC.delegatecall(
            abi.encodeWithSelector(
                IAsymptoticPerpetual.swap.selector,
                Config(TOKEN, TOKEN_R, ORACLE, K, MARK, INIT_TIME, HALF_LIFE),
                sideIn,
                sideOut,
                helper,
                payload
            )
        );
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
        (amountIn, amountOut) = abi.decode(result, (uint, uint));
        // TODO: reentrancy guard
        if (sideOut == SIDE_R) {
            TransferHelper.safeTransfer(TOKEN_R, recipient, amountOut);
        } else {
            IERC1155Supply(TOKEN).mint(recipient, _packID(address(this), sideOut), amountOut, "");
        }
        // TODO: flash callback here
        if (sideIn == SIDE_R) {
            if (payer != address(0)) {
                IUniversalTokenRouter(UTR).pay(payer, address(this), 20, TOKEN_R, 0, amountIn);
            } else {
                TransferHelper.safeTransferFrom(TOKEN_R, msg.sender, address(this), amountIn);
            }
        } else {
            uint idIn = _packID(address(this), sideIn);
            if (payer != address(0)) {
                IUniversalTokenRouter(UTR).discard(payer, 1155, TOKEN, idIn, amountIn);
                IERC1155Supply(TOKEN).burn(payer, idIn, amountIn);
            } else {
                IERC1155Supply(TOKEN).burn(msg.sender, idIn, amountIn);
            }
        }
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";
import "./interfaces/IPoolFactory.sol";
import "./Pool.sol";

contract PoolFactory is IPoolFactory {
    bytes32 immutable BYTECODE_HASH = keccak256(type(Pool).creationCode);

    // transient storage
    Params t_params;

    function getParams() external view override returns (Params memory) {
        return t_params;
    }

    function _salt(Params memory params) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                params.token,
                params.logic,
                params.oracle,
                params.reserveToken,
                params.mark,
                params.k,
                params.halfLife
            )
        );
    }

    function createPool(Params memory params) external returns (address pool) {
        t_params = params;
        pool = Create2.deploy(0, _salt(params), type(Pool).creationCode);
        delete t_params;
    }

    function computePoolAddress(
        Params memory params
    ) external view returns (address pool) {
        return Create2.computeAddress(_salt(params), BYTECODE_HASH, address(this));
    }
}