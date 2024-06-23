/**
 *Submitted for verification at Arbiscan.io on 2024-06-23
*/

// SPDX-License-Identifier: MIT
// https://psychoinu.com

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// File: @openzeppelin\contracts\token\ERC20\extensions\IERC20Permit.sol

pragma solidity ^0.8.20;

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin\contracts\utils\Address.sol

pragma solidity ^0.8.20;

library Address {
    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function verifyCallResult(bool success, bytes memory returndata)
        internal
        pure
        returns (bytes memory)
    {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// File: @openzeppelin\contracts\token\ERC20\utils\SafeERC20.sol

pragma solidity ^0.8.20;

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 requestedDecrease
    );

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeCall(token.transferFrom, (from, to, value))
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 requestedDecrease
    ) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(
                    spender,
                    currentAllowance,
                    requestedDecrease
                );
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            token.approve,
            (spender, value)
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeCall(token.approve, (spender, 0))
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data)
        private
        returns (bool)
    {
        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            address(token).code.length > 0;
    }
}

// File: @openzeppelin\contracts\utils\Context.sol

pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.8.20;

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin\contracts\utils\structs\EnumerableSet.sol

pragma solidity ^0.8.20;

library EnumerableSet {
    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _positions;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._positions[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 position = set._positions[value];

        if (position != 0) {
            uint256 valueIndex = position - 1;
            uint256 lastIndex = set._values.length - 1;

            if (valueIndex != lastIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[valueIndex] = lastValue;
                set._positions[lastValue] = position;
            }

            set._values.pop();
            delete set._positions[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._positions[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin\contracts\utils\ReentrancyGuard.sol

pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// File: @uniswap\v2-core\contracts\interfaces\IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

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
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap\v2-periphery\contracts\interfaces\IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: contracts\Contract.sol

pragma solidity ^0.8.20;

contract PSYCHOINU is Context, IERC20, Ownable, ReentrancyGuard {
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    string private _name = unicode"PSYCHO INU";
    string private _symbol = unicode"P$YCHO";
    uint8 private _decimals = 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private excluded;

    EnumerableSet.AddressSet private affiliates;
    EnumerableSet.AddressSet private buyers;

    enum PreState {
        NULL,
        STARTED,
        CANCELED,
        COMPLETED
    }

    struct Presale {
        PreState state;
        uint256 startBlock;
        uint256 buyers;
        uint256 minBuy;
        uint256 startedAt;
        uint256 endsAt;
        uint256 endedAt;
        uint256 price;
        uint256 tokens;
        uint256 ethers;
        uint256 softcap;
        uint256 hardcap;
        uint256 deposits;
    }
    Presale private presale;

    struct User {
        bool firstBuy;
        bool referred;
        bytes4 code;
        address referrer;
    }
    mapping(address => User) private user;

    struct Buyer {
        bool referred;
        address referrer;
        uint256 tokens;
        uint256 ethers;
    }
    mapping(address => Buyer) private buyer;

    struct Accounts {
        address admin;
        address payable marketing;
        address liquify;
        address pair;
        address router;
    }
    Accounts private accounts =
        Accounts({
            admin: address(0),
            marketing: payable(0x6015A1704DC7CE01b056b3675787e87b094Fd4b3),
            liquify: address(0x0e5CA5E45Ad0D9334D28ff1B5eaEa7e4B7c047Fb),
            pair: address(0),
            router: address(0)
        });

    struct Balances {
        uint256 marketingTokens;
        uint256 marketingEthers;
        uint256 contractTokens;
        uint256 contractEthers;
    }

    uint256 private lastEmergencyWithdraw;

    IUniswapV2Router02 private router;
    IUniswapV2Pair private pair;

    struct Total {
        uint256 inviteAmount;
        uint256 inviteCount;
        uint256 affiliates;
        uint256 referredCount;
        uint256 supply;
        uint256 airdrop;
        uint256 payoutEthers;
        uint256 rewardsEthers;
    }
    Total private total = Total(0, 0, 0, 0, 0, 0, 0, 0);

    struct State {
        bool swapPaused;
        bool diffpos;
        uint256 diff;
        uint256 affiliatesBalance;
        uint256 circulatingSupply;
        uint256 currentMinter;
        uint256 currentPrice;
        uint256 swapThreshold;
        uint256 swapThresholdPercent;
        uint256 liquifyTokens;
        uint256 liquidityTokens;
        uint256 liquidityEthers;
    }
    State private state = State(false, false, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0);

    mapping(bytes4 => address) private affiliateByCode;

    struct Affiliate {
        bytes4 code;
        address account;
        uint256 balance;
        uint256 referred;
        uint256 rewards;
        uint256 payout;
    }
    mapping(address => Affiliate) private affiliate;

    struct Config {
        bool inviteEnabled;
        bool mintifyEnabled;
        bool mintEnabled;
        bool swapEnabled;
        bool liquifyEnabled;
        bool tradingEnabled;
        bool presaleEnabled;
        uint16 rewardPercent;
        uint16 upThreshold;
        uint16 liquifyPercent;
        uint256 baseline;
        uint256 lastManual;
        uint256 sendThreshold;
        uint256 mintifyThreshold;
        uint256 minSupply;
        uint256 maxSupply;
    }
    Config private config =
        Config({
            inviteEnabled: true,
            mintifyEnabled: true,
            mintEnabled: true,
            swapEnabled: true,
            liquifyEnabled: true,
            tradingEnabled: false,
            presaleEnabled: false,
            upThreshold: 10, // 10% diff percent
            liquifyPercent: 5000,
            rewardPercent: 300, // 3% of buy amount
            baseline: 0,
            lastManual: 0,
            sendThreshold: 1e17, // 0.1 eth
            mintifyThreshold: 5e21, // 5000 tokens
            minSupply: 2e24,
            maxSupply: 1e27
        });

    error AffiliateExists();
    error AlreadySubmited(address affiliate);
    error AmountTooLow();
    error ApproveFromZeroAddress();
    error ApproveToZeroAddress();
    error BalanceTooLow();
    error CantAfterFirstBuy();
    error ContractCantBeReferred();
    error ContractCantBeReferrer();
    error DecreasedAllowanceBelowZero();
    error InsufficientAllowance();
    error InvalidAddress(address account);
    error InvalidAffiliate(address sender, address affiliate);
    error InvalidInviteCode(bytes4 code);
    error MintEnded();
    error MintingDisabled();
    error NextWithdrawAt(uint256 timestamp);
    error OutOfBounds(uint256 min, uint256 max);
    error OverHardCap();
    error OverSoftCap();
    error PresaleStateError(PreState state);
    error SelfRefer();
    error SameValue();
    error TradingIsEnabled();
    error TradingNotEnabled();
    error TransferAmountExceedsBalance();
    error WaitUntil(uint256 time);
    error ZeroAddress();
    error ZeroAddressTransfer();
    error ZeroAmount();
    error ZeroBalance();

    event AffiliateAccountCreated(address account, bytes4 code);
    event AffiliatePayout(address account, uint256 ethers);
    event AffiliateRewarded(address affiliate, uint256 reward);
    event Airdropped(address to, uint256 amount);
    event ConfigInviteEnabled(bool enabled);
    event ConfigLiquifyEnabled(bool enabled);
    event ConfigMintEnabled(bool enabled);
    event ConfigMintifyEnabled(bool enabled);
    event ConfigSwapEnabled(bool enabled);
    event ConfigSwapPaused(bool paused);
    event ConfigUpThresholdSet(uint16 amount);
    event EmergencyWithdraw(uint256 tokens, uint256 ethers);
    event EthersSent(address to, uint256 amount);
    event Excluded(address account, bool excluded);
    event InviteCodeApplied(address sender, address affiliate);
    event LiquidityAdded(uint256 tokens, uint256 ethers);
    event LiquifyAddressSet(address account);
    event LiquifyPercentSet(uint256 percent);
    event MarketingAddressSet(address account);
    event MintingComplete();
    event PresaleBuy(address account, uint256 ethers);
    event PresaleCanceled(Presale presale);
    event PresaleCompleted(Presale presale);
    event PresaleSet(Presale presale);
    event PresaleStarted(Presale presale);
    event PresaleTokensClaimed(address account, uint256 tokens);
    event PresaleWithdraw(address account, uint256 ethers);
    event RewardPercentSet(uint256 percent);
    event SendThresholdSet(uint256 amount);
    event Swapped(uint256 tokens, uint256 ethers);
    event TokensWithdrawn(address account, uint256 amount);
    event TradingEnabled(bool enabled);

    bool private inSwap;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyAdmin() {
        if (_msgSender() != accounts.admin) revert OwnableUnauthorizedAccount(_msgSender());
        _;
    }

    constructor(address router_) Ownable(msg.sender) {
        accounts.admin = payable(_msgSender());
        accounts.router = router_;
        router = IUniswapV2Router02(router_);
        accounts.pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        pair = IUniswapV2Pair(accounts.pair);
        excluded[address(this)] = true;
        excluded[accounts.admin] = true;
        excluded[accounts.marketing] = true;
        excluded[accounts.liquify] = true;
        excluded[accounts.router] = true;
    }

    receive() external payable {}

    fallback() external payable {}

    function EnableTrading() external payable onlyOwner {
        if (config.tradingEnabled) revert TradingIsEnabled();
        config.tradingEnabled = true;
        (state.liquidityTokens, state.liquidityEthers) = getReserves();
        (state.swapThresholdPercent, state.swapThreshold) = calcLTP(
            total.supply
        );
        config.baseline = currentPrice();
        uint256 balance = address(this).balance;
        uint256 affBalance = state.affiliatesBalance;
        if (balance > affBalance) {
            accounts.marketing.transfer(balance - affBalance);
        }
        emit TradingEnabled(true);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return total.supply;
    }

    function circulatingSupply() public view returns (uint256 supply) {
        unchecked {
            supply =
                total.supply -
                _balances[accounts.admin] -
                _balances[accounts.marketing] -
                _balances[accounts.liquify] -
                _balances[address(this)];
        }
        return supply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance < subtractedValue)
            revert DecreasedAllowanceBelowZero();
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        if (owner == address(0)) revert ApproveFromZeroAddress();
        if (spender == address(0)) revert ApproveToZeroAddress();
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if (from == address(0) || to == address(0))
            revert ZeroAddressTransfer();
        if (_balances[from] < amount) revert TransferAmountExceedsBalance();
        if (excluded[from] || excluded[to] || inSwap || amount < 1e4) {
            subTransfer(from, to, amount);
            return;
        }

        Accounts memory _accounts = accounts;
        bool isBuy = from == _accounts.pair;
        bool isSell = to == _accounts.pair && from != address(this);
        bool isTransfer = !isBuy && !isSell;

        Config storage _config = config;
        if (!_config.tradingEnabled) revert TradingNotEnabled();
        State storage _state = state;
        Total storage _total = total;

        if (_config.mintEnabled && isBuy && _config.mintifyEnabled) {
            unchecked {
                _state.currentMinter += (amount * _config.liquifyPercent) / 1e4;
                uint256 _diff = _config.maxSupply - _total.supply;
                if (_state.currentMinter > _diff) _state.currentMinter = _diff;
            }
        }

        if (isSell) {
            if (
                _config.liquifyEnabled &&
                _balances[_accounts.liquify] > _state.swapThreshold
            ) {
                if (_state.swapPaused) {
                    uint256 currentPriceValue = currentPrice();
                    (_state.diff, _state.diffpos) = diff(
                        _config.baseline,
                        currentPriceValue
                    );
                    if (_state.diff >= _config.upThreshold) {
                        if (!_state.diffpos) {
                            _config.baseline = currentPriceValue;
                        } else {
                            _state.swapPaused = false;
                        }
                    }
                }
                if (!_state.swapPaused) {
                    _swapAndLiquify(
                        _state.swapThreshold,
                        _config.sendThreshold,
                        _state.affiliatesBalance
                    );
                }
            } else if (_config.swapEnabled) {
                processFees(
                    _state.swapThreshold,
                    _config.sendThreshold,
                    _state.affiliatesBalance
                );
            }
        }

        uint256 fee;

        if (
            _config.presaleEnabled &&
            (isSell || isTransfer) &&
            buyers.contains(from)
        ) {
            Buyer storage _buyer = buyer[from];
            if (_buyer.tokens >= 1e18) {
                if (isTransfer || (isSell && !_buyer.referred)) {
                    _buyer.tokens = (amount >= _buyer.tokens)
                        ? 0
                        : _buyer.tokens - amount;
                } else if (isSell && _buyer.referred && _buyer.tokens >= 1e18) {
                    (fee, _buyer.tokens) = processPresaleTokens(
                        amount,
                        _buyer.tokens
                    );
                }
            }
            if (_buyer.tokens < 1e18 && clearBuyer(from))
                _config.presaleEnabled = false;
        }

        if (!isTransfer && fee == 0) {
            User storage _user = user[isSell ? from : to];
            unchecked {
                fee = (amount * 800) / 1e4;
            }
            if (
                isBuy &&
                _config.inviteEnabled &&
                _user.referred &&
                affiliates.contains(_user.referrer) &&
                !isContract(to)
            ) {
                uint256 reward = processReward(_user.referrer, amount);
                if (reward > 0) {
                    unchecked {
                        _total.rewardsEthers += reward;
                        _state.affiliatesBalance += reward;
                    }
                }
                if (_user.firstBuy) {
                    unchecked {
                        _total.inviteAmount += amount;
                        _total.inviteCount++;
                    }
                    _user.firstBuy = false;
                    fee = (amount * 300) / 1e4;
                }
            }
        }

        (_state.swapThresholdPercent, _state.swapThreshold) = calcLTP(
            _total.supply
        );
        if (_config.mintEnabled) {
            uint256 totals = _total.supply + _state.swapThreshold;
            if (totals > _config.maxSupply) {
                _config.mintifyEnabled = false;
                _config.mintEnabled = false;
                _config.inviteEnabled = false;
                _state.currentMinter = 0;
                uint256 excess = totals - _config.maxSupply;
                endMinting(excess);
                _total.supply += excess;
            } else if (_state.currentMinter > _state.swapThreshold) {
                unchecked {
                    _balances[_accounts.liquify] += _state.swapThreshold;
                    _total.supply += _state.swapThreshold;
                    _state.currentMinter -= _state.swapThreshold;
                }
                emit Transfer(
                    address(0),
                    _accounts.liquify,
                    _state.swapThreshold
                );
            }
        }

        if (fee > 0) {
            subTransfer(from, _accounts.marketing, fee);
            unchecked {
                amount -= fee;
            }
        }

        subTransfer(from, to, amount);
    }

    function subTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        unchecked {
            _balances[from] -= amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function processPresaleTokens(uint256 amount, uint256 buyerToken)
        private
        pure
        returns (uint256 fee, uint256 tokens)
    {
        if (buyerToken < 1e9) {
            fee = 0;
            tokens = 0;
        } else if (amount == buyerToken) {
            unchecked {
                fee = (buyerToken * 300) / 1e4;
            }
            tokens = 0;
        } else if (amount >= buyerToken) {
            unchecked {
                fee =
                    ((buyerToken * 300) / 1e4) +
                    (((amount - buyerToken) * 800) / 1e4);
            }
            tokens = 0;
        } else if (buyerToken > amount) {
            unchecked {
                fee = (amount * 300) / 1e4;
                tokens = buyerToken - amount;
            }
        }
        return (fee, tokens);
    }

    function processFees(
        uint256 swapThreshold,
        uint256 sendThreshold,
        uint256 affiliatesBalance
    ) private {
        if (_balances[accounts.marketing] > swapThreshold) {
            subTransfer(accounts.marketing, address(this), swapThreshold);
        }
        if (_balances[address(this)] > swapThreshold) {
            _swap(swapThreshold);
            uint256 balance = address(this).balance;
            if (balance > sendThreshold + affiliatesBalance) {
                unchecked {
                    balance -= affiliatesBalance;
                }
                sendEthers(accounts.marketing, balance);
            }
        }
    }

    function processReward(address account, uint256 amount)
        private
        returns (uint256 ethers)
    {
        if (amount == 0) return 0;
        Affiliate storage _affiliate = affiliate[account];
        uint256 price = currentPrice();
        unchecked {
            ethers = (((amount * config.rewardPercent) / 1e4) * price) / 1e18;
            _affiliate.balance += ethers;
            _affiliate.rewards += ethers;
        }
        emit AffiliateRewarded(account, ethers);
        return ethers;
    }

    function _swapAndLiquify(
        uint256 threshold,
        uint256 sendThreshold,
        uint256 affiliatesBalance
    ) private returns (uint256 tokens, uint256 ethers) {
        uint256 half = 0;
        uint256 m = 0;
        bool r = _balances[accounts.marketing] > threshold;
        unchecked {
            half = threshold / 2;
            tokens = threshold - half;
        }
        subTransfer(accounts.liquify, address(this), threshold);
        if (r) {
            subTransfer(accounts.marketing, address(this), threshold);
            uint256 price = currentPrice();
            uint256 amount = half + threshold;
            unchecked {
                m = (threshold * price) / 1e18;
                amount = half + threshold;
            }
            ethers = _swap(amount) - m;
            if (address(this).balance > sendThreshold + affiliatesBalance) {
                sendEthers(accounts.marketing, address(this).balance - affiliatesBalance);
            }
        } else {
            ethers = _swap(half);
        }
        unchecked {
            tokens -= tokens / 10;
            ethers -= ethers / 10;
        }
        _addLiquidity(tokens, ethers);
        return (tokens, ethers);
    }

    function affiliatePayout() external nonReentrant {
        if (!config.tradingEnabled) revert TradingNotEnabled();
        address account = msg.sender;
        Affiliate storage _affiliate = affiliate[account];
        uint256 ethers = _affiliate.balance;
        if (address(this).balance < ethers)
            revert TransferAmountExceedsBalance();
        unchecked {
            _affiliate.balance = 0;
            _affiliate.payout += ethers;
            state.affiliatesBalance -= ethers;
            total.payoutEthers += ethers;
        }
        payable(account).transfer(ethers);
        emit AffiliatePayout(account, ethers);
    }

    function _swap(uint256 tokens) private lockTheSwap returns (uint256) {
        uint256 balance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), accounts.router, tokens);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 ethers = address(this).balance - balance;
        emit Swapped(tokens, ethers);
        return ethers;
    }

    function endMinting(uint256 amount) private {
        uint256 balance = _balances[accounts.liquify];
        if (balance > 0) {
            subTransfer(accounts.liquify, accounts.marketing, balance);
        }
        _balances[address(this)] += amount;
        emit Transfer(address(0), address(this), amount);
        emit ConfigMintifyEnabled(false);
        emit ConfigMintEnabled(false);
        emit ConfigInviteEnabled(false);
        emit MintingComplete();
    }

    function _addLiquidity(uint256 tokens, uint256 ethers) private lockTheSwap {
        _approve(address(this), accounts.router, tokens);
        router.addLiquidityETH{value: ethers}(
            address(this),
            tokens,
            0,
            0,
            accounts.admin,
            block.timestamp
        );
        emit LiquidityAdded(tokens, ethers);
    }

    function calcLTP(uint256 supply)
        private
        view
        returns (uint256 percent, uint256 threshold)
    {
        (uint256 tokens, ) = getReserves();
        unchecked {
            percent = (500 * (supply - tokens)) / supply;
            threshold = (tokens * (percent < 200 ? 200 : percent)) / 1e4;
        }
        return (percent, threshold);
    }

    function diff(uint256 a, uint256 b) private pure returns (uint256 c, bool) {
        if (a == 0 || b == 0 || b == a) return (0, false);
        uint256 d = (a > b ? a - b : b - a);
        unchecked {
            c = ((d * 200) * 1e18) / (a + b) / 1e18;
        }
        return (c, b > a);
    }

    function isContract(address _address) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_address)
        }
        return (size > 0);
    }

    function sendEthers(address to, uint256 amount) private {
        payable(to).transfer(amount);
        emit EthersSent(to, amount);
    }

    /** external */
    /** Config */

    function setLiquifyEnabled(bool enabled) external onlyAdmin {
        if (config.liquifyEnabled == enabled) revert SameValue();
        if (total.supply >= config.maxSupply) revert MintEnded();
        config.liquifyEnabled = enabled;
        emit ConfigLiquifyEnabled(enabled);
    }

    function setMintifyEnabled(bool enabled) external onlyAdmin {
        if (config.mintifyEnabled == enabled) revert SameValue();
        if (total.supply >= config.maxSupply) revert MintEnded();
        config.mintifyEnabled = enabled;
        emit ConfigMintifyEnabled(enabled);
    }

    function setMintEnabled(bool enabled) external onlyAdmin {
        if (config.mintEnabled == enabled) revert SameValue();
        if (total.supply >= config.maxSupply) revert MintEnded();
        config.mintEnabled = enabled;
        emit ConfigMintEnabled(enabled);
    }

    function setSwapEnabled(bool enabled) external onlyAdmin {
        if (config.swapEnabled == enabled) revert SameValue();
        config.swapEnabled = enabled;
        emit ConfigSwapEnabled(enabled);
    }

    function setInviteEnabled(bool enabled) external onlyAdmin {
        if (config.inviteEnabled == enabled) revert SameValue();
        config.inviteEnabled = enabled;
        emit ConfigInviteEnabled(enabled);
    }

    function setSwapPaused(bool paused) external onlyAdmin {
        if (state.swapPaused == paused) revert SameValue();
        state.swapPaused = paused;
        emit ConfigSwapPaused(paused);
    }

    function setRewardPercent(uint16 percent) external onlyAdmin {
        /// 2.5 to 5 %
        if (config.rewardPercent == percent) revert SameValue();
        if (percent < 250 || percent > 500) revert OutOfBounds(250, 500);
        config.rewardPercent = percent;
        emit RewardPercentSet(percent);
    }

    function setLiquifyPercent(uint16 percent) external onlyAdmin {
        if (config.liquifyPercent == percent) revert SameValue();
        if (total.supply >= config.maxSupply) revert MintEnded();
        /// 0.1 to 100 %
        if (percent < 10 || percent > 1e4) revert OutOfBounds(10, 1e4);
        config.liquifyPercent = percent;
        emit LiquifyPercentSet(percent);
    }

    function setSendThreshold(uint256 amount) external onlyAdmin {
        if (config.sendThreshold == amount) revert SameValue();
        if (amount < 1e16 || amount > 1e19) revert OutOfBounds(1e16, 1e19);
        config.sendThreshold = amount;
        emit SendThresholdSet(amount);
    }

    function setUpThreshold(uint16 percent) external onlyAdmin {
        if (config.upThreshold == percent) revert SameValue();
        if (percent < 5 || percent > 10000) revert OutOfBounds(5, 10000);
        config.upThreshold = percent;
        emit ConfigUpThresholdSet(percent);
    }

    function setMarketingAddress(address account) external onlyAdmin {
        if (accounts.marketing == account) revert SameValue();
        if (account == address(0)) revert ZeroAddress();
        if (_balances[account] > 0) revert InvalidAddress(account);
        accounts.marketing = payable(account);
        emit MarketingAddressSet(account);
    }

    function setLiquifyAddress(address account) external onlyAdmin {
        if (accounts.liquify == account) revert SameValue();
        if (account == address(0)) revert ZeroAddress();
        if (_balances[account] > 0) revert InvalidAddress(account);
        accounts.liquify = account;
        emit LiquifyAddressSet(account);
    }

    //** Getters */

    function currentPrice() public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        return router.getAmountsOut(1e18, path)[1];
    }

    function getReserves()
        public
        view
        returns (uint256 tokens, uint256 ethers)
    {
        (uint112 token0, uint112 token1, ) = IUniswapV2Pair(accounts.pair)
            .getReserves();
        return
            pair.token0() == address(this)
                ? (token0, token1)
                : (token1, token0);
    }

    function getAffiliateByCode(bytes4 code)
        external
        view
        returns (Affiliate memory _affiliate)
    {
        return affiliate[affiliateByCode[code]];
    }

    function getAccount(address account)
        external
        view
        returns (
            User memory _user,
            bool isAffiliate,
            uint256 balanceTokens,
            uint256 balanceEthers
        )
    {
        return (
            user[account],
            affiliates.contains(account),
            _balances[account],
            address(account).balance
        );
    }

    function getAffiliate(address account)
        external
        view
        returns (Affiliate memory)
    {
        return affiliate[account];
    }

    function getData()
        external
        view
        returns (
            State memory _state,
            Total memory _total,
            Config memory _config,
            Balances memory balances
        )
    {
        _state = state;
        if (config.tradingEnabled) {
            (_state.liquidityTokens, _state.liquidityEthers) = getReserves();
            _state.currentPrice = currentPrice();
        }
        _state.liquifyTokens = _balances[accounts.liquify];
        _state.circulatingSupply = circulatingSupply();
        balances = Balances(
            _balances[accounts.marketing],
            accounts.marketing.balance,
            _balances[address(this)],
            address(this).balance
        );
        return (_state, total, config, balances);
    }

    function getAccounts() external view returns (Accounts memory) {
        return accounts;
    }

    function getPresale() external view returns (Presale memory, uint256 cc) {
        return (presale, buyers.length());
    }

    function getBuyer(address account) external view returns (Buyer memory) {
        return buyer[account];
    }

    function getAffiliates() external view returns (address[] memory) {
        return affiliates.values();
    }

    function getBuyers() external view returns (address[] memory) {
        return buyers.values();
    }

    //** Other */

    /// max total airdrop = 1% of total supply or 10.000 per 1.000.000 tokens
    function airdrop(address to, uint256 amount) external onlyAdmin {
        amount *= 1e18;
        uint256 supply = total.supply;
        if (!config.mintEnabled) revert MintingDisabled();
        if (state.currentMinter < amount)
            revert OutOfBounds(amount, state.currentMinter);
        if (amount + supply > config.maxSupply)
            revert OutOfBounds(amount + supply, config.maxSupply);
        if (total.airdrop + amount > supply / 100)
            revert OutOfBounds(total.airdrop + amount, supply / 100);
        unchecked {
            _balances[to] += amount;
            total.supply += amount;
            total.airdrop += amount;
            state.currentMinter -= amount;
        }
        emit Transfer(address(0), to, amount);
        emit Airdropped(to, amount);
    }

    function exclude(address address_) external onlyAdmin {
        excluded[address_] = !excluded[address_];
        emit Excluded(address_, excluded[address_]);
    }

    function withdrawEthers() external onlyAdmin {
        if (
            address(this).balance >
            config.sendThreshold + state.affiliatesBalance
        ) {
            uint256 amount = address(this).balance - state.affiliatesBalance;
            sendEthers(accounts.marketing, amount);
        }
    }

    function withdrawTokens(uint256 amount) external onlyAdmin {
        if (amount > _balances[address(this)])
            revert TransferAmountExceedsBalance();
        subTransfer(address(this), accounts.admin, amount);
        emit TokensWithdrawn(accounts.admin, amount);
    }

    function emergencyWithdraw() external onlyAdmin {
        uint256 next = lastEmergencyWithdraw + 30 days;
        if (block.timestamp < next)
            revert NextWithdrawAt(next);
        uint256 ethers = 0;
        uint256 affBalance = state.affiliatesBalance;
        if (address(this).balance > affBalance) {
            ethers = address(this).balance - affBalance;
            sendEthers(accounts.admin, ethers);
        }
        uint256 tokens = _balances[address(this)];
        subTransfer(address(this), accounts.admin, tokens);
        lastEmergencyWithdraw = block.timestamp;
        emit EmergencyWithdraw(tokens, ethers);
    }
    
    function swapAndLiquify(uint256 amount) external onlyAdmin {
        if (amount == 0) revert ZeroAmount();
        if (_balances[accounts.liquify] < amount) revert AmountTooLow();
        if (block.timestamp < config.lastManual + 5 minutes)
            revert WaitUntil(config.lastManual + 5 minutes);
        config.lastManual = block.timestamp;
        config.baseline = currentPrice();
        state.swapPaused = true;
        _swapAndLiquify(
            state.swapThreshold,
            config.sendThreshold,
            state.affiliatesBalance
        );
    }

    /** Public */

    function registerAffiliateAccount() external {
        address sender = msg.sender;
        if (affiliates.contains(sender)) revert AffiliateExists();
        if (isContract(sender)) revert ContractCantBeReferrer();
        bytes4 code = bytes4(keccak256(abi.encodePacked(sender)));
        Affiliate memory newAffiliate = Affiliate({
            code: code,
            account: sender,
            balance: 0,
            referred: 0,
            rewards: 0,
            payout: 0
        });
        affiliate[sender] = newAffiliate;
        affiliateByCode[code] = sender;
        affiliates.add(sender);
        total.affiliates++;
        emit AffiliateAccountCreated(sender, code);
    }

    function submitInviteCode(bytes4 code) external {
        address sender = msg.sender;
        address _affiliate = affiliateByCode[code];
        if (isContract(sender)) revert ContractCantBeReferred();
        if (_affiliate == address(0) || code == 0)
            revert InvalidInviteCode(code);
        if (sender == _affiliate) revert SelfRefer();
        if (!affiliates.contains(_affiliate))
            revert InvalidAffiliate(sender, _affiliate);
        if (user[sender].code != 0) 
            revert AlreadySubmited(_affiliate);
        if (_balances[sender] > 0) 
            revert CantAfterFirstBuy();
        user[sender] = User({
            firstBuy: true,
            referred: true,
            code: code,
            referrer: _affiliate
        });
        affiliate[_affiliate].referred++;
        total.referredCount++;
        emit InviteCodeApplied(sender, _affiliate);
    }

    //** PRESALE */

    function presaleDeposit() external payable {
        address sender = msg.sender;
        uint256 ethers = msg.value;
        Presale storage _presale = presale;
        if (_presale.state != PreState.STARTED)
            revert PresaleStateError(_presale.state);
        if (ethers == 0) revert ZeroAmount();
        if (ethers < _presale.minBuy) revert AmountTooLow();
        if (_presale.ethers + ethers > _presale.hardcap) revert OverHardCap();
        Buyer storage _buyer = buyer[sender];
        Affiliate storage _affiliate = affiliate[user[sender].referrer];
        if (_affiliate.account != address(0)) {
            _buyer.referrer = _affiliate.account;
            _buyer.referred = true;
        }
        unchecked {
            if (_buyer.ethers == 0) {
                _presale.buyers++;
                _buyer.ethers = ethers;
            } else {
                _buyer.ethers += ethers;
            }
            _presale.ethers += ethers;
            _presale.deposits++;
            _presale.price = _presale.ethers / (_presale.tokens / 1e18);
        }
        if (_buyer.referred) {
            uint256 reward = (ethers * config.rewardPercent) / 1e4;
            unchecked {
                _affiliate.balance += reward;
                _affiliate.rewards += reward;
                state.affiliatesBalance += reward;
                total.rewardsEthers += reward;
            }
            buyers.add(sender);       
            emit AffiliateRewarded(_affiliate.account, reward);
        }
        emit PresaleBuy(sender, ethers);
    }

    function presaleWithdraw() external nonReentrant {
        address sender = msg.sender;
        Presale storage _presale = presale;
        if (_presale.state != PreState.CANCELED)
            revert PresaleStateError(_presale.state);
        Buyer storage _buyer = buyer[sender];
        uint256 ethers = _buyer.ethers;
        if (ethers == 0) revert ZeroBalance();
        if (ethers > _presale.ethers) revert BalanceTooLow();
        _presale.ethers -= ethers;
        delete buyer[sender];
        buyers.remove(sender);
        payable(sender).transfer(ethers);
        emit PresaleWithdraw(sender, ethers);
    }

    function startPresale(
        uint256 tokens,
        uint256 softcap,
        uint256 hardcap,
        uint256 minBuy,
        uint256 endsAt
    ) external onlyOwner {
        if (presale.state != PreState.NULL)
            revert PresaleStateError(presale.state);
        if (endsAt > block.timestamp + 10 days) revert OutOfBounds(0, 10 days);
        _setPresale(
            true,
            block.timestamp,
            block.number,
            tokens * 1e18,
            softcap,
            hardcap,
            minBuy,
            endsAt
        );
        emit PresaleStarted(presale);
    }

    function cancelPresale() external onlyOwner {
        Presale storage _presale = presale;
        if (_presale.state != PreState.STARTED)
            revert PresaleStateError(presale.state);
        if (_presale.ethers >= _presale.softcap) revert OverSoftCap();
        _presale.endedAt = block.timestamp;
        _presale.state = PreState.CANCELED;
        _presale.deposits = 0;
        total.rewardsEthers = 0;
        state.affiliatesBalance = 0;
        config.presaleEnabled = false;
        emit PresaleCanceled(_presale);
    }

    function completePresale() external onlyOwner {
        Presale storage _presale = presale;
        if (_presale.state != PreState.STARTED)
            revert PresaleStateError(_presale.state);
        uint256 ethers = _presale.ethers;
        if (ethers < presale.softcap) revert BalanceTooLow();
        _balances[address(this)] = presale.tokens;
        total.supply = presale.tokens;
        ethers -= ethers / 10;
        _presale.endedAt = block.timestamp;
        _presale.state = PreState.COMPLETED;
        config.presaleEnabled = true;
        emit Transfer(address(0), address(this), _presale.tokens);
        emit PresaleCompleted(_presale);
        _addLiquidity(_presale.tokens, ethers);
    }

    function claimPresaleTokens() external nonReentrant returns (uint256 tokens) {
        Presale storage _presale = presale;
        if (_presale.state != PreState.COMPLETED)
            revert PresaleStateError(_presale.state);
        address sender = msg.sender;
        Buyer storage _buyer = buyer[sender];
        if (_buyer.ethers == 0) revert ZeroBalance();
        unchecked {
            tokens = (_buyer.ethers * 1e18) / _presale.price;
            _balances[address(this)] += tokens;
            total.supply += tokens;
        }
        unchecked {
            if (!_buyer.referred) tokens -= (tokens * 500) / 1e4;
            _buyer.tokens = tokens;
            _buyer.ethers = 0;
            _balances[sender] += tokens;
        }
        _balances[address(this)] -= tokens;
        emit Transfer(address(0), address(this), tokens);
        emit Transfer(address(this), sender, tokens);
        emit PresaleTokensClaimed(sender, tokens);
        return tokens;
    }

    function backup() external onlyOwner {
        if (presale.state == PreState.STARTED ||
            presale.state == PreState.COMPLETED
        ) revert PresaleStateError(presale.state);
        if (config.tradingEnabled) 
            revert TradingIsEnabled();
        _resetPresale();
        total.supply = 1e24; /// 1,000,000.000000000000000000
        _balances[accounts.admin] += total.supply;
        emit Transfer(address(0), accounts.admin, total.supply);
    }

    function resetPresale() external onlyOwner {
        _resetPresale();
    }

    function _resetPresale() private {
        if (
            presale.state == PreState.STARTED ||
            presale.state == PreState.COMPLETED
        ) revert PresaleStateError(presale.state);
        if (config.tradingEnabled) 
            revert TradingIsEnabled();
        uint256 length = buyers.length();
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                buyers.remove(buyers.at(0));
            }
        }
        length = affiliates.length();
        if (length > 0) {
            for (uint256 i = 0; i < length; i++) {
                Affiliate storage _affiliate = affiliate[affiliates.at(i)];
                _affiliate.balance = 0;
                _affiliate.rewards = 0;
            }
        }
        _setPresale(false, 0, 0, 0, 0, 0, 0, 0);
        emit PresaleSet(presale);
    }

    function _setPresale(
        bool started,
        uint256 timestamp,
        uint256 startBlock,
        uint256 tokens,
        uint256 softcap,
        uint256 hardcap,
        uint256 minbuy,
        uint256 endsAt
    ) private {
        presale = Presale({
            state: started ? PreState.STARTED : PreState.NULL,
            startBlock: startBlock,
            buyers: 0,
            minBuy: minbuy,
            startedAt: timestamp,
            endsAt: endsAt,
            endedAt: 0,
            price: 0,
            tokens: tokens,
            ethers: 0,
            softcap: softcap,
            hardcap: hardcap,
            deposits: 0
        });
    }

    function clearBuyer(address account) private returns (bool) {
        delete buyer[account];
        buyers.remove(account);
        return buyers.length() == 0;
    }
}