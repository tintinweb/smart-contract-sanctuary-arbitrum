// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC2612 is IERC20 {
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./IERC2612.sol";

interface IPair is IERC2612 {
    event Fees(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint256 reserve0, uint256 reserve1);
    event Claim(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1
    );

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint timestamp;
        uint reserve0Cumulative;
        uint reserve1Cumulative;
    }

    function initialize(address token0, address token1, bool stable) external;

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable() external view returns (bool);

    function feeRatio() external view returns (uint256);

    function fees() external view returns (address);

    function reserve0CumulativeLast() external view returns (uint256);

    function reserve1CumulativeLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(
        address to
    ) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function claimFees() external returns (uint256 claimed0, uint256 claimed1);

    function syncFees() external;

    function observationLength() external view returns (uint256);

    function lastObservation() external view returns (Observation memory);

    function metadata()
        external
        view
        returns (
            uint256 decimals0,
            uint256 decimals1,
            uint256 reserve0,
            uint256 reserve1,
            bool stable,
            address token0,
            address token1,
            uint256 feeRatio
        );

    function tokens() external view returns (address token0, address token1);

    function getReserves()
        external
        view
        returns (
            uint256 reserve0,
            uint256 reserve1,
            uint256 blockTimestampLast
        );

    function currentCumulativePrices()
        external
        view
        returns (
            uint reserve0Cumulative,
            uint reserve1Cumulative,
            uint blockTimestamp
        );

    function current(
        address tokenIn,
        uint amountIn
    ) external view returns (uint amountOut);

    function quote(
        address tokenIn,
        uint amountIn,
        uint granularity
    ) external view returns (uint amountOut);

    function prices(
        address tokenIn,
        uint amountIn,
        uint points
    ) external view returns (uint[] memory);

    function sample(
        address tokenIn,
        uint amountIn,
        uint points,
        uint window
    ) external view returns (uint[] memory);

    function getAmountOut(uint256, address) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPairFees {
    function initialize(address pair) external;

    function factory() external view returns (address);

    function pair() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function lastDistributed0() external view returns (uint256);

    function lastDistributed1() external view returns (uint256);

    function claimFeesFor(
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IPairFees.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPair.sol";

contract PairFees is IPairFees {
    address public factory;
    address public pair; // The pair it is bonded to
    address public token0; // token0 of pair, saved localy and statically for gas optimization
    address public token1; // Token1 of pair, saved localy and statically for gas optimization
    uint256 public lastDistributed0; // last time fee0 was distributed towards bribe
    uint256 public lastDistributed1; // last time fee1 was distributed towards bribe

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(address _pair) external onlyFactory {
        pair = _pair;
        token0 = IPair(_pair).token0();
        token1 = IPair(_pair).token1();
    }

    // Allow the pair to transfer fees to gauges
    function claimFeesFor(
        address recipient,
        uint256 amount0,
        uint256 amount1
    ) external {
        require(msg.sender == pair, "Only pair");
        if (amount0 > 0) {
            _safeTransfer(token0, recipient, amount0);
            lastDistributed0 = block.timestamp;
        }
        if (amount1 > 0) {
            _safeTransfer(token1, recipient, amount1);
            lastDistributed1 = block.timestamp;
        }
    }

    function _safeTransfer(address token, address to, uint256 value) internal {
        require(token.code.length > 0, "!contract");
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "SafeERC20: safeTransfer low-level call failed"
        );
    }
}