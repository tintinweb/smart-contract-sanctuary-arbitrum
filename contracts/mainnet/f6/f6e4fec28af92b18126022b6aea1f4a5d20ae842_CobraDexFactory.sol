// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './interfaces/ICobraDexFactory.sol';
import './interfaces/IRebateEstimator.sol';
import './interfaces/IMevController.sol';
import './CobraDexPair.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

contract CobraDexFactory is ICobraDexFactory, Ownable, IRebateEstimator {
    address public override feeTo;
    address public override migrator;

    // fee customizability
    uint64 public fee = 100;
    uint64 public cobradexFeeProportion = 5000;
    uint64 public constant FEE_DIVISOR = 10000;
    mapping(address => bool) public isFeeManager_;
    mapping(address => bool) public rebateApprovedRouters;
    address public override rebateManager;
    address mevController;

    mapping(address => mapping(address => address)) public override getPair;
    address[] public override allPairs;

    address public rebateEstimator;

    constructor() public {
    }

    function allPairsLength() external override view returns (uint) {
        return allPairs.length;
    }

    function pairCodeHash() external override pure returns (bytes32) {
        return keccak256(type(CobraDexPair).creationCode);
    }

    function createPair(address tokenA, address tokenB) external override returns (address pair) {
        require(tokenA != tokenB, 'CobraDex: IDENTICAL_ADDRESSES');
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'CobraDex: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'CobraDex: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(CobraDexPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        CobraDexPair(pair).initialize(token0, token1, fee, cobradexFeeProportion);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function mevControlPre(address sender) public override {
        if (mevController != address(0)) {
            IMevController(mevController).pre(msg.sender, sender);
        }
    }
    function mevControlPost(address sender) public override {
        if (mevController != address(0)) {
            IMevController(mevController).post(msg.sender, sender);
        }
    }

    function setMevController(address _mevController) public onlyOwner {
        mevController = _mevController;
    }

    function setFeeTo(address _feeTo) external override onlyOwner {
        feeTo = _feeTo;
    }

    function setMigrator(address _migrator) external override onlyOwner {
        migrator = _migrator;
    }

    function setFee(uint64 _fee, uint64 _cobradexFeeProportion) external override onlyOwner {
        require(_fee <= FEE_DIVISOR, 'CobraDex: FEE_TOO_HIGH');
        require(_cobradexFeeProportion <= FEE_DIVISOR, 'CobraDex: PROPORTION_TOO_HIGH');
        fee = _fee;
        cobradexFeeProportion = _cobradexFeeProportion;
    }

    function setFeeManager(address manager, bool _isFeeManager) external override onlyOwner {
        isFeeManager_[manager] = _isFeeManager;
    }

    function setRebateApprovedRouter(address router, bool state) external onlyOwner {
        rebateApprovedRouters[router] = state;
    }

    function setRebateManager(address _rebateManager) external onlyOwner {
        rebateManager = _rebateManager;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), "CobraDex: ZERO_ADDRESS");

        transferOwnership(_newOwner);
    }

    function isFeeManager(address manager) external override view returns (bool) {
        return isFeeManager_[manager];
    }

    function isRebateApprovedRouter(address router) external override view returns (bool) {
        return rebateApprovedRouters[router];
    }

    function setRebateEstimator(address _rebateEstimator) external onlyOwner {
        rebateEstimator = _rebateEstimator;
    }

    function getRebate(address recipient) public override view returns (uint64) {
        if (rebateEstimator == address(0x0)) {
            return 0;
        }
        return IRebateEstimator(rebateEstimator).getRebate(recipient);
    }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './CobraDexERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/ICobraDexFactory.sol';
import './interfaces/ICobraDexCallee.sol';
import './interfaces/IRebateEstimator.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract CobraDexPair is CobraDexERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));

    address public factory;
    address public token0;
    address public token1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    // to set aside fees
    uint public feeCache0 = 0;
    uint public feeCache1 = 0;

    // fee customizability
    uint64 public fee;
    uint64 public cobradexFeeProportion;
    uint64 public constant FEE_DIVISOR = 10000;

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'CobraDex: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
    modifier mevControl() {
        ICobraDexFactory(factory).mevControlPre(msg.sender);
        _;
        ICobraDexFactory(factory).mevControlPost(msg.sender);
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'CobraDex: TRANSFER_FAILED');
    }

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event SwapWithFee(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        uint feeTaken0,
        uint feeTaken1,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, uint64 _fee, uint64 _cobradexFeeProportion) external {
        require(msg.sender == factory, 'CobraDex: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;

        setFee(_fee, _cobradexFeeProportion);
    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'CobraDex: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = ICobraDexFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(5).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this)).sub(feeCache0);
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this)).sub(feeCache1);
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = ICobraDexFactory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != type(uint256).max, "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'CobraDex: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this)).sub(feeCache0);
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this)).sub(feeCache1);
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'CobraDex: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this)).sub(feeCache0);
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this)).sub(feeCache1);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swapCalculatingRebate(uint amount0Out, uint amount1Out, address to, address feeController, bytes calldata data) external lock mevControl {
        require(feeController == msg.sender || feeController == tx.origin || feeController == to, "CobraDex: INVALID_FEE_CONTROLLER");
        uint64 feeRebate = IRebateEstimator(factory).getRebate(feeController);
        (uint amount0In, uint amount1In, uint feeTaken0, uint feeTaken1) = _swap(amount0Out, amount1Out, to, feeRebate, data);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        emit SwapWithFee(msg.sender, amount0In, amount1In, amount0Out, amount1Out, feeTaken0, feeTaken1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock mevControl {
        (uint amount0In, uint amount1In, uint feeTaken0, uint feeTaken1) = _swap(amount0Out, amount1Out, to, 0, data);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        emit SwapWithFee(msg.sender, amount0In, amount1In, amount0Out, amount1Out, feeTaken0, feeTaken1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    function swapWithRebate(uint amount0Out, uint amount1Out, address to, uint64 feeRebate, bytes calldata data) external lock mevControl {
        require(ICobraDexFactory(factory).isRebateApprovedRouter(msg.sender), "CobraDex: INVALID_REBATE_ORIGIN");
        require(feeRebate <= FEE_DIVISOR, "CobraDex: INVALID_REBATE");
        (uint amount0In, uint amount1In, uint feeTaken0, uint feeTaken1) = _swap(amount0Out, amount1Out, to, feeRebate, data);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
        emit SwapWithFee(msg.sender, amount0In, amount1In, amount0Out, amount1Out, feeTaken0, feeTaken1, to);
    }

    function _swap(uint amount0Out, uint amount1Out, address to, uint64 feeRebate, bytes calldata data) internal returns (uint, uint, uint, uint){
        require(amount0Out > 0 || amount1Out > 0, 'CobraDex: INSUFFICIENT_OUTPUT_AMOUNT');
        uint112[] memory _reserve = new uint112[](2);
        (_reserve[0], _reserve[1],) = getReserves(); // gas savings
        require(amount0Out < _reserve[0] && amount1Out < _reserve[1], 'CobraDex: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;
        { // avoids stack too deep errors
        require(to != token0 && to != token1, 'CobraDex: INVALID_TO');
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out); // optimistically transfer tokens
        if (data.length > 0) ICobraDexCallee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
        balance0 = IERC20Uniswap(token0).balanceOf(address(this)).sub(feeCache0);
        balance1 = IERC20Uniswap(token1).balanceOf(address(this)).sub(feeCache1);
        }
        uint amount0In = balance0 > _reserve[0] - amount0Out ? balance0 - (_reserve[0] - amount0Out) : 0;
        uint amount1In = balance1 > _reserve[1] - amount1Out ? balance1 - (_reserve[1] - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'CobraDex: INSUFFICIENT_INPUT_AMOUNT');

        uint feeTaken0;
        uint feeTaken1;
        { // stack depth
        // calculate total fee
        { // stack depth
        uint _fee = _calculateFee(feeRebate);
        feeTaken0 = amount0In.mul(_fee);
        feeTaken1 = amount1In.mul(_fee);
        }
        { // stack depth
        // calculate resulting swap balances
        uint balance0Adjusted = balance0.mul(FEE_DIVISOR).sub(feeTaken0);
        uint balance1Adjusted = balance1.mul(FEE_DIVISOR).sub(feeTaken1);
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve[0]).mul(_reserve[1]).mul(FEE_DIVISOR**2), 'CobraDex: K');
        }
        // account for retained fees
        uint cobradexFee0;
        uint cobradexFee1;
        { // stack depth
        uint64 _cobradexFeeProportion = cobradexFeeProportion; // gas savings
        cobradexFee0 = feeTaken0.div(FEE_DIVISOR).mul(_cobradexFeeProportion).div(FEE_DIVISOR);
        cobradexFee1 = feeTaken1.div(FEE_DIVISOR).mul(_cobradexFeeProportion).div(FEE_DIVISOR);
        }
        balance0 = balance0.sub(cobradexFee0);
        balance1 = balance1.sub(cobradexFee1);
        feeCache0 = uint(feeCache0).add(cobradexFee0);
        feeCache1 = uint(feeCache1).add(cobradexFee1);
        }

        _update(balance0, balance1, _reserve[0], _reserve[1]);

        return (amount0In, amount1In, feeTaken0, feeTaken1);
    }

    function _calculateFee(uint64 feeRebate) internal view returns (uint256) {
        if (feeRebate == 0) {
            return fee;
        }
        // calculate fee rebate
        uint rebateFactor = uint(FEE_DIVISOR).sub(feeRebate);
        return uint(fee).mul(rebateFactor).div(FEE_DIVISOR);
    }
    function calculateFee(uint64 feeRebate) external view returns (uint256) {
        return _calculateFee(feeRebate);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(feeCache0).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(feeCache1).sub(reserve1));
    }

    function withdrawFee(address _to, bool _send0, bool _send1) external lock {
        uint256 _toSend0 = feeCache0;
        uint256 _toSend1 = feeCache1;
        feeCache0 = 0;
        feeCache1 = 0;
        require(ICobraDexFactory(factory).isFeeManager(msg.sender), 'CobraDex: FORBIDDEN');

        if (_send0) {
            _safeTransfer(token0, _to, _toSend0);
            _toSend0 = 0;
        }
        if (_send1) {
            _safeTransfer(token1, _to, _toSend1);
            _toSend1 = 0;
        }

        feeCache0 = _toSend0;
        feeCache1 = _toSend1;
    }

    function setFee(uint64 _fee, uint64 _cobradexFeeProportion) public {
        require(msg.sender == factory || ICobraDexFactory(factory).isFeeManager(msg.sender), 'CobraDex: FORBIDDEN');
        require(_fee <= FEE_DIVISOR, 'CobraDex: FEE_TOO_HIGH');
        require(_cobradexFeeProportion <= FEE_DIVISOR, 'CobraDex: PROPORTION_TOO_HIGH');
        fee = _fee;
        cobradexFeeProportion = _cobradexFeeProportion;
    }

    function getFeeDivisor() external pure returns (uint64) {
        return FEE_DIVISOR;
    }

    // force reserves to match balances
    function sync() external lock {
        _update(IERC20Uniswap(token0).balanceOf(address(this)).sub(feeCache0), IERC20Uniswap(token1).balanceOf(address(this)).sub(feeCache1), reserve0, reserve1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IMevController {
    function pre(address sender1, address sender2) external;
    function post(address sender1, address sender2) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IRebateEstimator {
    function getRebate(address account) external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ICobraDexFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function mevControlPre(address sender) external;
    function mevControlPost(address sender) external;
    function setFeeTo(address) external;
    function setMigrator(address) external;

    function setFee(uint64 _fee, uint64 _cobradexFeeProportion) external;
    function setFeeManager(address manager, bool _isFeeManager) external;
    function isFeeManager(address manager) external view returns (bool);
    function isRebateApprovedRouter(address router) external view returns (bool);
    function rebateManager() external view returns (address);

    function pairCodeHash() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface ICobraDexCallee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

import './libraries/SafeMath.sol';

contract CobraDexERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'CobraDex LP Token';
    string public constant symbol = 'OLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'CobraDex: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'CobraDex: INVALID_SIGNATURE');
        _approve(owner, spender, value);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }

    function div(uint x, uint y) internal pure returns (uint z) {
        require(y != 0, 'ds-math-div-overflow');
        z = x / y;
    }
}