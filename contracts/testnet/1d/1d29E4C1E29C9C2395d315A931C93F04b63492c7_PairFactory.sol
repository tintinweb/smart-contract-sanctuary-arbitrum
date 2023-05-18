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

interface IPairCallee {
    function hook(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IPairFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        bool stable,
        address pair,
        uint256
    );
    event SetGovernance(address governance);
    event SetVoter(address voter);
    event SetOperator(address operator, bool state);

    function governance() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function isPair(address) external view returns (bool);

    function isPaused() external view returns (bool);

    function isOperator(address) external view returns (bool);

    function voter() external view returns (address);

    function poolFees(address pool) external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair);

    function createFees() external returns (address fees);

    function setGovernance(address governance) external;

    function setVoter(address voter) external;

    function setOperator(address operator, bool state) external;

    function pairCodeHash() external pure returns (bytes32);
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
pragma solidity ^0.8.0;

interface IVoter {
    function feeDists(address pool) external view returns (address);

    function generalFees() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IPair.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IPairCallee.sol";
import "./interfaces/IVoter.sol";
import "./interfaces/IPairFees.sol";
import "./libraries/Math.sol";

contract Pair is IPair {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    // Used to denote stable or volatile pair,
    uint256 public reserve0CumulativeLast;
    uint256 public reserve1CumulativeLast;

    bool public stable;
    uint8 public constant decimals = 18;

    address public immutable factory;
    address public token0;
    address public token1;
    address public fees;
    uint256 public feeRatio;

    // Capture oracle reading every 30 minutes
    uint constant periodSize = 1800;

    Observation[] public observations;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    uint256 internal decimals0;
    uint256 internal decimals1;

    uint256 internal constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 internal constant feeDivider = 1e6;

    uint256 private reserve0;
    uint256 private reserve1;
    uint256 private blockTimestampLast;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1);
        unlocked = 2;
        _;
        unlocked = 1;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _token0,
        address _token1,
        bool _stable
    ) external onlyFactory {
        (token0, token1, stable) = (_token0, _token1, _stable);
        fees = IPairFactory(factory).createFees();
        if (_stable) {
            name = string(
                abi.encodePacked(
                    "Stable AMM - ",
                    IERC20(_token0).symbol(),
                    "/",
                    IERC20(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "sAMM-",
                    IERC20(_token0).symbol(),
                    "/",
                    IERC20(_token1).symbol()
                )
            );
        } else {
            name = string(
                abi.encodePacked(
                    "Volatile AMM - ",
                    IERC20(_token0).symbol(),
                    "/",
                    IERC20(_token1).symbol()
                )
            );
            symbol = string(
                abi.encodePacked(
                    "vAMM-",
                    IERC20(_token0).symbol(),
                    "/",
                    IERC20(_token1).symbol()
                )
            );
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );

        decimals0 = 10 ** IERC20(_token0).decimals();
        decimals1 = 10 ** IERC20(_token1).decimals();

        observations.push(Observation(block.timestamp, 0, 0));

        syncFees();
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            uint256 newAllowance = spenderAllowance - value;
            allowance[from][spender] = newAllowance;

            emit Approval(from, spender, newAllowance);
        }

        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Pair: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Pair: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external lock returns (uint256 liquidity) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves(); // gas savings
        uint256 _balance0 = IERC20(token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(token1).balanceOf(address(this));
        uint256 _amount0 = _balance0 - _reserve0;
        uint256 _amount1 = _balance1 - _reserve1;

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(_amount0 * _amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            liquidity = Math.min(
                (_amount0 * _totalSupply) / _reserve0,
                (_amount1 * _totalSupply) / _reserve1
            );
        }
        require(liquidity > 0, "ILM"); // Pair: INSUFFICIENT_LIQUIDITY_MINTED
        _mint(to, liquidity);

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Mint(msg.sender, _amount0, _amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(
        address to
    ) external lock returns (uint256 amount0, uint256 amount1) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves(); // gas savings
        (address _token0, address _token1) = (token0, token1);
        uint256 _balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 _balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 _liquidity = balanceOf[address(this)];

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = (_liquidity * _balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = (_liquidity * _balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, "ILB"); // Pair: INSUFFICIENT_LIQUIDITY_BURNED
        _burn(address(this), _liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        _balance0 = IERC20(_token0).balanceOf(address(this));
        _balance1 = IERC20(_token1).balanceOf(address(this));

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external lock {
        require(!IPairFactory(factory).isPaused(), "PAUSED"); // Pair: PAUSED
        require(amount0Out > 0 || amount1Out > 0, "IOA"); // Pair: INSUFFICIENT_OUTPUT_AMOUNT
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "IL"); // Pair: INSUFFICIENT_LIQUIDITY

        uint256 _balance0;
        uint256 _balance1;
        {
            // scope for _token{0,1}, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);
            require(to != _token0 && to != _token1, "IT"); // Pair: INVALID_TO
            if (amount0Out > 0) {
                _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
            }
            if (amount1Out > 0) {
                _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens
            }
            if (data.length > 0) {
                IPairCallee(to).hook(msg.sender, amount0Out, amount1Out, data); // callback, used for flash loans
            }
            _balance0 = IERC20(_token0).balanceOf(address(this));
            _balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = _balance0 > _reserve0 - amount0Out
            ? _balance0 - (_reserve0 - amount0Out)
            : 0;
        uint256 amount1In = _balance1 > _reserve1 - amount1Out
            ? _balance1 - (_reserve1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "IIA"); // Pair: INSUFFICIENT_INPUT_AMOUNT
        {
            // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            (address _token0, address _token1) = (token0, token1);

            if (amount0In > 0) {
                _update0((amount0In * feeRatio) / feeDivider); // accrue fees for token0 and move them out of pool
            }
            if (amount1In > 0) {
                _update1((amount1In * feeRatio) / feeDivider); // accrue fees for token1 and move them out of pool
            }
            _balance0 = IERC20(_token0).balanceOf(address(this)); // since we removed tokens, we need to reconfirm balances, can also simply use previous balance - fee, but doing balanceOf again as safety check
            _balance1 = IERC20(_token1).balanceOf(address(this));
            // The curve, either x3y+y3x for stable pools, or x*y for volatile pools
            require(_k(_balance0, _balance1) >= _k(_reserve0, _reserve1), "K");
        }

        _update(_balance0, _balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        (address _token0, address _token1) = (token0, token1);
        _safeTransfer(
            _token0,
            to,
            IERC20(_token0).balanceOf(address(this)) - (reserve0)
        );
        _safeTransfer(
            _token1,
            to,
            IERC20(_token1).balanceOf(address(this)) - (reserve1)
        );
    }

    // force reserves to match balances
    function sync() external lock {
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0,
            reserve1
        );
    }

    /**
     * @notice directs the fees toward the gauge if it exists, goes to common pool if not
     */
    function claimFees() external returns (uint256 claimed0, uint256 claimed1) {
        // Determine whether gauge exists
        IVoter voter = IVoter(IPairFactory(factory).voter());
        address feeDistAddress = voter.feeDists(address(this));
        bool gaugeExists = feeDistAddress != address(0);

        if (!gaugeExists) {
            feeDistAddress = voter.generalFees();
        }

        require(
            msg.sender == feeDistAddress,
            "Only feeDist or only general fees if gauge doesn't exist"
        );

        // Sending directly instead of calling notifyRewardAmount(),
        // relying on the assumption that this method is only callable by feeDists and generalFees
        // and that those contracts will deal with the accounting properly
        address _fees = fees;
        claimed0 = IERC20(token0).balanceOf(_fees);
        claimed1 = IERC20(token1).balanceOf(_fees);
        IPairFees(_fees).claimFeesFor(msg.sender, claimed0, claimed1);

        emit Claim(msg.sender, msg.sender, claimed0, claimed1);
    }

    function metadata()
        external
        view
        returns (
            uint256 dec0,
            uint256 dec1,
            uint256 r0,
            uint256 r1,
            bool st,
            address t0,
            address t1,
            uint256 _feeRatio
        )
    {
        return (
            decimals0,
            decimals1,
            reserve0,
            reserve1,
            stable,
            token0,
            token1,
            feeRatio
        );
    }

    function tokens() external view returns (address, address) {
        return (token0, token1);
    }

    function getReserves()
        public
        view
        returns (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        )
    {
        (_reserve0, _reserve1, _blockTimestampLast) = (
            reserve0,
            reserve1,
            blockTimestampLast
        );
    }

    function getAmountOut(
        uint256 amountIn,
        address tokenIn
    ) external view returns (uint256) {
        (uint256 _reserve0, uint256 _reserve1) = (reserve0, reserve1);
        amountIn -= (amountIn * feeRatio) / feeDivider; // remove fee from amount received

        return _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    /**
     * @notice Syncs fees from pair factory
     */
    function syncFees() public {
        feeRatio = IPairFactory(factory).poolFees(address(this));
    }

    function lastObservation() public view returns (Observation memory) {
        return observations[observations.length - 1];
    }

    function observationLength() external view returns (uint256) {
        return observations.length;
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices()
        public
        view
        returns (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,
            uint256 blockTimestamp
        )
    {
        blockTimestamp = block.timestamp;
        reserve0Cumulative = reserve0CumulativeLast;
        reserve1Cumulative = reserve1CumulativeLast;

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (
            uint256 _reserve0,
            uint256 _reserve1,
            uint256 _blockTimestampLast
        ) = getReserves();
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint256 timeElapsed = blockTimestamp - _blockTimestampLast;
            reserve0Cumulative += _reserve0 * timeElapsed;
            reserve1Cumulative += _reserve1 * timeElapsed;
        }
    }

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(
        address tokenIn,
        uint256 amountIn
    ) external view returns (uint256 amountOut) {
        Observation memory _observation = lastObservation();
        (
            uint256 reserve0Cumulative,
            uint256 reserve1Cumulative,

        ) = currentCumulativePrices();
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[observations.length - 2];
        }

        uint256 timeElapsed = block.timestamp - _observation.timestamp;
        uint256 _reserve0 = (reserve0Cumulative -
            _observation.reserve0Cumulative) / timeElapsed;
        uint256 _reserve1 = (reserve1Cumulative -
            _observation.reserve1Cumulative) / timeElapsed;
        amountOut = _getAmountOut(amountIn, tokenIn, _reserve0, _reserve1);
    }

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(
        address tokenIn,
        uint256 amountIn,
        uint256 granularity
    ) external view returns (uint256 amountOut) {
        uint256[] memory _prices = sample(tokenIn, amountIn, granularity, 1);
        uint256 priceAverageCumulative;
        for (uint256 i = 0; i < _prices.length; i++) {
            priceAverageCumulative += _prices[i];
        }
        return priceAverageCumulative / granularity;
    }

    // returns a memory set of twap prices
    function prices(
        address tokenIn,
        uint256 amountIn,
        uint256 points
    ) external view returns (uint256[] memory) {
        return sample(tokenIn, amountIn, points, 1);
    }

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
            uint256 timeElapsed = observations[nextIndex].timestamp -
                observations[i].timestamp;
            uint256 _reserve0 = (observations[nextIndex].reserve0Cumulative -
                observations[i].reserve0Cumulative) / timeElapsed;
            uint256 _reserve1 = (observations[nextIndex].reserve1Cumulative -
                observations[i].reserve1Cumulative) / timeElapsed;
            _prices[index] = _getAmountOut(
                amountIn,
                tokenIn,
                _reserve0,
                _reserve1
            );
            index = index + 1;
        }
        return _prices;
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(
        uint256 balance0,
        uint256 balance1,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal {
        uint blockTimestamp = block.timestamp;
        uint timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            reserve0CumulativeLast += _reserve0 * timeElapsed;
            reserve1CumulativeLast += _reserve1 * timeElapsed;
        }

        Observation memory _point = lastObservation();
        timeElapsed = blockTimestamp - _point.timestamp; // compare the last observation with current timestamp, if greater than 30 minutes, record a new event
        if (timeElapsed > periodSize) {
            observations.push(
                Observation(
                    blockTimestamp,
                    reserve0CumulativeLast,
                    reserve1CumulativeLast
                )
            );
        }
        reserve0 = balance0;
        reserve1 = balance1;
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    /**
     * @notice Accrue fees on token0
     */
    function _update0(uint256 amount) internal {
        _safeTransfer(token0, fees, amount); // transfer the fees out to PairFees
        emit Fees(msg.sender, amount, 0);
    }

    /**
     * @notice Accrue fees on token1
     */
    function _update1(uint256 amount) internal {
        _safeTransfer(token1, fees, amount); // transfer the fees out to PairFees
        emit Fees(msg.sender, amount, 0);
    }

    function _f(uint x0, uint y) internal pure returns (uint) {
        return
            (x0 * ((((y * y) / 1e18) * y) / 1e18)) /
            1e18 +
            (((((x0 * x0) / 1e18) * x0) / 1e18) * y) /
            1e18;
    }

    function _d(uint x0, uint y) internal pure returns (uint) {
        return
            (3 * x0 * ((y * y) / 1e18)) /
            1e18 +
            ((((x0 * x0) / 1e18) * x0) / 1e18);
    }

    function _get_y(uint x0, uint xy, uint y) internal pure returns (uint) {
        for (uint i = 0; i < 255; i++) {
            uint y_prev = y;
            uint k = _f(x0, y);
            if (k < xy) {
                uint dy = ((xy - k) * 1e18) / _d(x0, y);
                y = y + dy;
            } else {
                uint dy = ((k - xy) * 1e18) / _d(x0, y);
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

    function _getAmountOut(
        uint amountIn,
        address tokenIn,
        uint _reserve0,
        uint _reserve1
    ) internal view returns (uint256) {
        if (stable) {
            uint xy = _k(_reserve0, _reserve1);
            _reserve0 = (_reserve0 * 1e18) / decimals0;
            _reserve1 = (_reserve1 * 1e18) / decimals1;
            (uint reserveA, uint reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            amountIn = tokenIn == token0
                ? (amountIn * 1e18) / decimals0
                : (amountIn * 1e18) / decimals1;
            uint y = reserveB - _get_y(amountIn + reserveA, xy, reserveB);
            return (y * (tokenIn == token0 ? decimals1 : decimals0)) / 1e18;
        } else {
            (uint reserveA, uint reserveB) = tokenIn == token0
                ? (_reserve0, _reserve1)
                : (_reserve1, _reserve0);
            return (amountIn * reserveB) / (reserveA + amountIn);
        }
    }

    function _mint(address to, uint256 value) internal {
        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./interfaces/IPairFactory.sol";
import "./interfaces/IPair.sol";
import "./Pair.sol";
import "./PairFees.sol";

contract PairFactory is IPairFactory {
    bool public isPaused;
    address public voter;
    address public governance;
    mapping(address => bool) public isOperator;

    mapping(address => mapping(address => mapping(bool => address)))
        public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair; // simplified check if its a pair, given that `stable` flag might not be available in peripherals

    uint256 public maxFees; // 1_000_000 = 100%
    uint256 public stableFees;
    uint256 public volatileFees;
    mapping(address => bool) public poolSpecificFeesEnabled;
    mapping(address => uint256) public poolSpecificFees;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }

    modifier onlyGovernanceOrOperator() {
        require(msg.sender == governance || isOperator[msg.sender]);
        _;
    }

    constructor(address _voter) {
        _setGovernance(msg.sender);
        _setVoter(_voter);
        stableFees = 200; // 0.02%
        volatileFees = 2000; // 0.20%
        maxFees = 30000; // 3%
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /**
     * @notice Set governance
     */
    function setGovernance(address _governance) external onlyGovernance {
        _setGovernance(_governance);
    }

    /**
     * @notice Set voter
     */
    function setVoter(address _voter) external onlyGovernance {
        _setVoter(_voter);
    }

    /**
     * @notice Sets operator status
     * @dev Operators are allowed to pause and set pool fees
     */
    function setOperator(address operator, bool state) external onlyGovernance {
        if (isOperator[operator] != state) {
            isOperator[operator] = state;
            emit SetOperator(operator, state);
        }
    }

    function setPause(bool _state) external onlyGovernanceOrOperator {
        isPaused = _state;
    }

    function setMaxFees(uint256 _maxFees) external onlyGovernance {
        require(_maxFees <= 1e6, "Over 100%");
        maxFees = _maxFees;
    }

    function setStableFees(
        uint256 _stableFees
    ) external onlyGovernanceOrOperator {
        require(_stableFees < maxFees, "Over max fees");
        stableFees = _stableFees;
    }

    function setVolatileFees(
        uint256 _volatileFees
    ) external onlyGovernanceOrOperator {
        require(_volatileFees < maxFees, "Over max fees");
        volatileFees = _volatileFees;
    }

    /**
     * @notice Returns fee in basis points for a pool
     */
    function poolFees(address pool) external view returns (uint256) {
        // Return pool specific fees if enabled
        if (poolSpecificFeesEnabled[pool]) {
            return poolSpecificFees[pool];
        }

        // Return volatile fees if not stable
        if (!IPair(pool).stable()) {
            return volatileFees;
        }

        // Return stable fees otherwise
        return stableFees;
    }

    /**
     * @notice Sets specific pool's fees
     * @dev _enabled needs to be set to true, to differentiate between
     *      pools with 0% fees and pools without specific fees
     */
    function setPoolSpecificFees(
        address _pool,
        uint256 _fees,
        bool _enabled
    ) external onlyGovernanceOrOperator {
        require(_fees < maxFees, "Over max fees");
        poolSpecificFeesEnabled[_pool] = _enabled;
        poolSpecificFees[_pool] = _fees;

        // Sync pool's fees
        IPair(_pool).syncFees();
    }

    function createPair(
        address tokenA,
        address tokenB,
        bool stable
    ) external returns (address pair) {
        require(tokenA != tokenB, "IA"); // Pair: IDENTICAL_ADDRESSES
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "ZA"); // Pair: ZERO_ADDRESS
        require(getPair[token0][token1][stable] == address(0), "PE"); // Pair: PAIR_EXISTS - single check is sufficient

        bytes32 salt = keccak256(abi.encodePacked(token0, token1, stable));
        pair = address(new Pair{salt: salt}());

        IPair(pair).initialize(token0, token1, stable); // notice salt includes stable as well, 3 parameters

        getPair[token0][token1][stable] = pair;
        getPair[token1][token0][stable] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        isPair[pair] = true;

        emit PairCreated(token0, token1, stable, pair, allPairs.length);
    }

    /**
     * @notice Create fees contract
     * @dev Must be called by pair contract
     */
    function createFees() external returns (address fees) {
        fees = address(new PairFees());
        PairFees(fees).initialize(msg.sender);
    }

    function pairCodeHash() external pure returns (bytes32) {
        return keccak256(type(Pair).creationCode);
    }

    function _setGovernance(address _governance) private {
        governance = _governance;
        emit SetGovernance(_governance);
    }

    function _setVoter(address _voter) private {
        voter = _voter;
        emit SetVoter(_voter);
    }
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