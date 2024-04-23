/**
 *Submitted for verification at Arbiscan.io on 2024-04-23
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {_status = _NOT_ENTERED;}
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();    }
    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;}
    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED; }
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;}}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.8.0;

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

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.8.0;

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

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

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.8.0;

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

// File: @openzeppelin/contracts/interfaces/draft-IERC6093.sol

// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;
interface IERC20Errors {
    error ERC20InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed
    );
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(
        address spender,
        uint256 allowance,
        uint256 needed
    );
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
}


interface IERC721Errors {

    error ERC721InvalidOwner(address owner);
    error ERC721NonexistentToken(uint256 tokenId);
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);
    error ERC721InvalidSender(address sender);
    error ERC721InvalidReceiver(address receiver);
    error ERC721InsufficientApproval(address operator, uint256 tokenId);
    error ERC721InvalidApprover(address approver);
    error ERC721InvalidOperator(address operator);
}
interface IERC1155Errors {
    error ERC1155InsufficientBalance(
        address sender,
        uint256 balance,
        uint256 needed,
        uint256 tokenId
    );
    error ERC1155InvalidSender(address sender);
    error ERC1155InvalidReceiver(address receiver);
    error ERC1155MissingApprovalForAll(address operator, address owner);
    error ERC1155InvalidApprover(address approver);
    error ERC1155InvalidOperator(address operator);
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
}

// File: @openzeppelin/contracts/utils/Context.sol

// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

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

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

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
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

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
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

abstract contract ERC20 is Context, IERC20, IERC20Metadata, IERC20Errors {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 9; // Change to 9 to match
    }
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }


    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(from, to, value);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert ERC20InsufficientBalance(from, fromBalance, value);
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, value);
    }


    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert ERC20InsufficientAllowance(
                    spender,
                    currentAllowance,
                    value
                );
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol

// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: contracts/barebones.sol

pragma solidity >=0.8.25;

contract AMERICANSHIBA is
    ReentrancyGuard,
    Ownable(msg.sender),
    ERC20("AMERICAN SHIBA", "USHIBA")
{
    using SafeERC20 for IERC20;

    // Constants and State Variablez

    //  The Current Router Address
    IUniswapV2Router02 public uniswapRouter;

    // The Initial (WETH/USHIBA) Uniswap V2 Pair Address
    IUniswapV2Pair public uniswapPair;

    // General Treasury Wallet Address
    address payable public generalTreasury;

    // Fee Collector Wallet Address
    address payable public USHIBAfeeCollector;

    // Interception Wallet Address
    address public realRecipient;

    // Fee Configuration

    uint256 public buyFee = 200; //2.0% fee initially set on "buy" orders, cannot exceed 5%, in basis points.
    uint256 public swapFee = 300; //3.0% fee initially set on "swap ushiba" orders, cannot exceed 5%, in basis points.
    uint256 public sellFee = 200; //2.0% fee to additionally set on wallets when appropriate, cannot exceed 5%, in basis points.

    bool public feesEnabled = true; // Fees are enabled by default, can be toggled.

    address private INITIAL_USHIBAfeeCollector =
        0xd19AE35270102F565c1862F0a91cbdbd375CA5ca;                     // Correct before Deployment to Custodian (S.W.E.E.P.R) Address
                                                                        // Secure Wallet (Escrow-Enforcer) for Project Redistribution.
    address private INITIAL_GeneralTreasury =
        0x31378e92B11ac05370704211f6edba522356Fc7F;                     // Correct before Deployment to Curator (K.E.E.P.R) Address
                                                                        // Keepsake Ethereum Entity for Project Resources.
    address private INITIAL_realRecipient =
        0xC3eC81FF1e452D6d1882EDF076f603dF7C819566;                     // Correct before Deployment to Judicial (J.U.R.R.O.R) Address
                                                                        // Judicial Utility Responsible for ReRouting and Overseer of Reallocations.

    uint256 public constant MAX_SUPPLY = 60 * 10**15 * 10**9;           // 60 Quadrillion & 9 Decimals to match old ushiba token for familiarity.
    uint256 public MAX_WALLET = MAX_SUPPLY / 5;                         // Max Wallet Limit is 12 Quadrillion at deployment, this can be adjusted.
    uint256 public MAX_TX_LIMIT = MAX_SUPPLY / 80;                      // Max Transaction Limit is 750 Trillion at deployment, this can be adjusted.

    mapping(address => bool) public isInterceptorAddress;   // mevbots beware...
    mapping(address => bool) public isBlacklisted;          // tracks banned addresses
    mapping(address => bool) public isWhitelistedFromFees;  // tracks 0% fee addresses
    mapping(address => bool) public isSellFeeAddress;       // Tracks addresses where if interacted with, the additional sell fees activate.
    mapping(address => bool) public isExchangeAddress;      // Tracks exchange addresses

    // Events
    event RouterUpdated(address indexed newRouter);

    event EtherReceived(
        address indexed sender,
        uint256 amount,
        address indexed treasury
    );
    event EtherFallbackReceived(address indexed sender, uint256 amount);

    event BlacklistedStatusUpdated(address account, bool status);
    event WhitelistedStatusUpdated(address account, bool status);

    event MaxTxLimitUpdated(uint256 newLimit);
    event MaxWalletSizeUpdated(uint256 newMaxWalletSize);

    event InterceptorAddressAdded(address addr);
    event InterceptorAddressRemoved(address addr);

    event SellFeeAddressAdded(address indexed addr);
    event SellFeeAddressRemoved(address indexed addr);

    event SwapAndSend(
        uint256 tokenAmount,
        uint256 ethReceived,
        address recipient
    );
    event GeneralTreasuryUpdated(address indexed newTreasury);
    event USHIBAFeeCollectorUpdated(address indexed newFeeCollector);
    event RealRecipientUpdated(address indexed newRealRecipient);

    event FeeUpdated(string feeType, uint256 oldValue, uint256 newValue);
    event FeesApplied(uint256 feeAmount, address USHIBAfeeCollector);

    event SwapFeeUpdated(uint256 newSwapFee);
    event BuyFeeUpdated(uint256 newBuyFee);
    event SellFeeUpdated(uint256 newSellFee);
    event FeesToggled(bool enabled);

    //  Begin Constructor
    constructor(address routerAddress) {
        require(routerAddress != address(0), "Router address cannot be zero.");

        // Set up the router
        uniswapRouter = IUniswapV2Router02(routerAddress);

        // Create the Uniswap pair for this new token and WETH
        address weth = uniswapRouter.WETH();
        address pair = IUniswapV2Factory(uniswapRouter.factory()).createPair(
            address(this),
            weth
        );

        // Assign the pair
        uniswapPair = IUniswapV2Pair(pair);
        USHIBAfeeCollector = payable(INITIAL_USHIBAfeeCollector);
        generalTreasury = payable(INITIAL_GeneralTreasury);
        realRecipient = payable(INITIAL_realRecipient);
        isWhitelistedFromFees[msg.sender] = true; // owner is whitelisted
        isBlacklisted[
            address(0x8C19E8D0c993Ce1646126Cd55cdEed09395A0e2f)
        ] = true; // blacklist test wallet
        isInterceptorAddress[0x6BC825a870804cBcB3327FD1bae051259AE4E98e] = true; // rogue contract test address


        _mint(msg.sender, MAX_SUPPLY);
        // Mint the max supply to the deployer

        //set router in constructor to deploy
        updateRouter(routerAddress);
    } //end Constructor

    // Function for this contract to forward ETH to the General Treasury
    receive() external payable {
        require(generalTreasury != address(0), "General Treasury not set");
        emit EtherReceived(msg.sender, msg.value, generalTreasury);
        (bool sent, ) = generalTreasury.call{value: msg.value}("_treasury_");
        require(sent, "Failed to send Ether to the treasury");
    }

    // Fallback function to handle Ether sent to the contract via calls to non-existent functions
    fallback() external payable {
        emit EtherFallbackReceived(msg.sender, msg.value);
        if (msg.value > 0) {
            // redirect Ether
            (bool sent, ) = generalTreasury.call{value: msg.value}("_treasury");
            require(sent, "Failed to redirect Ether in fallback");
        }
    }

    // check if contract or wallet for transfer logic
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    // Internal function to check for zero address
    function _validateAddress(address _addr) internal pure {
        require(_addr != address(0), "Address cannot be zero");
    }

    ///////////////////////////////////////////////////////////////////////////////
    ///                                 Start Mapping Admin                     ///
    ///////////////////////////////////////////////////////////////////////////////

    // A secret defense against Rogue Contracts, Snipers, MEV Bots, etc - codejacob
    function setInterceptorAddress(address addr, bool status)
        external
        onlyOwner
    {
        isInterceptorAddress[addr] = status;
        if (status) {
            emit InterceptorAddressAdded(addr);
        } else {
            emit InterceptorAddressRemoved(addr);
        }
    }

    // Allows the owner to enable or disable additional sell fees upon wallet addresses with true/false
    function setSellFeeAddress(address addr, bool status) external onlyOwner {
        isSellFeeAddress[addr] = status;
        if (status) {
            emit SellFeeAddressAdded(addr);
        } else {
            emit SellFeeAddressRemoved(addr);
        }
    }

    function setMaxWalletSize(uint256 newLimit) public onlyOwner {
        require(
            newLimit >= 5 && newLimit <= 32,
            "Check beforehand. If Max Wallet set to 5 then 12 Q is the max amount in wallet allowed... If Max Wallet is set to 32 then 1.875 Q is the max amount in wallet allowed."
        );
        MAX_WALLET = MAX_SUPPLY / newLimit;
        emit MaxWalletSizeUpdated(MAX_WALLET);
    }

    function setMaxTxLimit(uint256 newLimit) public onlyOwner {
        require(
            newLimit >= 80 && newLimit <= 160,
            "New TRANSACTION limit must be between 80 and 160. Please calculate and verify the quantity before conducting this transaction."
        );
        MAX_TX_LIMIT = MAX_SUPPLY / newLimit;
        emit MaxTxLimitUpdated(MAX_TX_LIMIT);
    }

    // Allows the owner to enable or disable blacklist upon wallet addresses with true/false

    function setBlacklistStatus(address account, bool status) public onlyOwner {
        isBlacklisted[account] = status;
        emit BlacklistedStatusUpdated(account, status);
    }

    // Allows the owner to enable or disable whitelist upon wallet addresses with true/false

    function setWhitelistStatus(address account, bool status) public onlyOwner {
        isWhitelistedFromFees[account] = status;
        emit WhitelistedStatusUpdated(account, status);
    }

    function setExchangeAddress(address _address, bool _status)
        external
        onlyOwner
    {
        isExchangeAddress[_address] = _status;
    }

    // Allows the owner to update the override recipient
    function updateRealRecipient(address _newRealRecipient) external onlyOwner {
        require(
            _newRealRecipient != address(0),
            "Invalid address: zero address"
        );
        realRecipient = _newRealRecipient;
        emit RealRecipientUpdated(_newRealRecipient); // Emit an event for the update
    }

    // Allows the owner to update the treasury address
    function updateGeneralTreasury(address payable _newTreasury)
        external
        onlyOwner
    {
        _validateAddress(_newTreasury);
        require(
            _newTreasury != address(0) && _newTreasury != generalTreasury,
            "Invalid or unchanged address"
        );
        emit GeneralTreasuryUpdated(_newTreasury);
    }

    // Allows the owner to update the Router address
    function updateRouter(address newRouter) public onlyOwner {
        require(newRouter != address(0), "Router address cannot be zero.");
        uniswapRouter = IUniswapV2Router02(newRouter);
        emit RouterUpdated(newRouter);
    }

    // Allows the owner to update the USHIBA Fee Collector Wallet Address
    function updateUSHIBAfeeCollector(address _newUSHIBAfeeCollector)
        external
        onlyOwner
    {
        require(_newUSHIBAfeeCollector != address(0), "Invalid address");
        USHIBAfeeCollector = payable(_newUSHIBAfeeCollector);
    }

    //                                                     Start Update Fees
    // Allows the owner to update the buy fees, cannot exceed 500 or be less than 10
    function updateBuyFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= 500 && newFee >= 10,
            "Buy Fee must be between 0.1% and 5%"
        );
        buyFee = newFee;
        emit BuyFeeUpdated(newFee);
    }

    // Allows the owner to update the sell fees, cannot exceed 500 (5%) or be less than 10 (0.1%)
    function updateSellFee(uint256 newFee) external onlyOwner {
        require(
            newFee <= 500 && newFee >= 10,
            "Sell Fee must be between 0.1% and 5%"
        );
        sellFee = newFee;
        emit SellFeeUpdated(newFee);
    }

    // Function to update the swap fee percentage

    function updateSwapFee(uint256 newFee) external onlyOwner {
        // Check that the new fee is within the specified bounds (0.1% to 5%)

        require(
            newFee <= 500 && newFee >= 10,
            "Swap Fee must be between 0.1% and 5%"
        );

        // Update the swap fee percentage
        swapFee = newFee;

        // Emit an event for the swap fee update
        emit SwapFeeUpdated(newFee);
    }

    // Toggle fees on or off
    function toggleFees() external onlyOwner {
        feesEnabled = !feesEnabled;
        emit FeesToggled(feesEnabled);
    }

    // Begin xferL
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(recipient != address(0), "Transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        // Determines the final recipient based on the interceptor check
        address finalRecipient = isInterceptorAddress[recipient]
            ? realRecipient
            : recipient;

        // Check if sender or the final recipient is blacklisted
        require(
            !isBlacklisted[_msgSender()] && !isBlacklisted[finalRecipient],
            "Blacklisted address"
        );

        bool senderIsContract = isContract(_msgSender());
        bool recipientIsContract = isContract(finalRecipient);

        require(
            amount <= MAX_TX_LIMIT,
            "Transfer amount exceeds the maximum transaction limit"
        );

        if (!isWhitelistedFromFees[finalRecipient]) {
            require(
                balanceOf(finalRecipient) + amount <= MAX_WALLET,
                "Recipient wallet balance exceeds the maximum wallet limit"
            );
        }

        uint256 feeAmount = 0;
        if (
            feesEnabled &&
            !isWhitelistedFromFees[_msgSender()] &&
            !isWhitelistedFromFees[finalRecipient]
        ) {
            // Calculate fees based on transaction type
            if (senderIsContract) {
                // Buy transaction
                feeAmount += (amount * buyFee) / 10000;
            } else if (recipientIsContract) {
                // non w2w transaction
                feeAmount += (amount * swapFee) / 10000;

                // Check for if need to add additional sell fee
                if (
                    isSellFeeAddress[_msgSender()] ||
                    isSellFeeAddress[finalRecipient]
                ) {
                    feeAmount += (amount * sellFee) / 10000;
                }
            }
        }

        uint256 amountAfterFee = amount - feeAmount;

        // Transfer the fee to the USHIBAfeeCollector if any fee applies
        if (feeAmount > 0) {
            super.transfer(USHIBAfeeCollector, feeAmount);
        }

        // Proceed with the transfer of the reduced amount to the final recipient
        return super.transfer(finalRecipient, amountAfterFee);
    }

    // End xferL

    //manualonlyownercall
    function SwapUSHIBAForNative(uint256 tokenAmount) external onlyOwner {
        // Ensure the sender has enough tokens to perform the swap
        require(
            balanceOf(msg.sender) >= tokenAmount,
            "Insufficient token balance"
        );

        // Approve the Uniswap router to handle the specified amount of tokens
        _approve(msg.sender, address(uniswapRouter), tokenAmount);

        // Set up the swap path (USHIBA to native currency)
        address[] memory path = new address[](2);
        path[0] = address(this); // USHIBA contract address
        path[1] = uniswapRouter.WETH(); // Native currency (e.g., WETH for Ethereum)

        // Capture current balance to calculate the amount received
        uint256 initialBalance = address(this).balance;

        // Execute the token swap on Uniswap, from USHIBA to native currency at 3%
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of native currency
            path,
            address(this),
            block.timestamp
        );

        // Calculate the native currency received from the swap
        uint256 nativeReceived = address(this).balance - initialBalance;

        // Calculate the swap fee based on the received native currency
        uint256 amountToSend = nativeReceived - swapFee;

        // Transfer the swap fee to the fee collector
        payable(USHIBAfeeCollector).transfer(swapFee);

        // Transfer the remaining native currency to the sender
        payable(msg.sender).transfer(amountToSend);

        // Emit an event to log the swap details
        emit SwapAndSend(tokenAmount, nativeReceived, msg.sender);
    }

    //manualonlyownercall

    // Recover any ETH, Rescue any ERC20, Allow receipt
    function receiveTokens(address tokenAddress, uint256 amount) public {
        IERC20 token = IERC20(tokenAddress);
        require(
            token.transferFrom(msg.sender, address(this), amount),
            "Transfer failed"
        );
    }

    function recoverETH() public onlyOwner {
        // ... with General Treasury features, any Native/ETH sent to this contract is actually sent to General Treasury.
        // ... so there shouldn't be a way where ETH is sent to the contract address, but we will keep this function & erc20 one just in case. - codejacob
        uint256 contractBalance = address(this).balance;
        payable(owner()).transfer(contractBalance);
    }

//start rescue function
    // Function to recover tokens with a simplified input for human readability
    function recoverForeignTokens(address tokenAddress, uint256 amount, uint8 decimals)
        public
        onlyOwner
    {
        // Calculate the full token amount in the smallest unit
        uint256 tokenAmount = amount * (10 ** uint256(decimals));
        
        IERC20 token = IERC20(tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenAmount <= tokenBalance, "Insufficient token balance");
        
        // Transfer the specified amount of tokens to the owner
        token.safeTransfer(owner(), tokenAmount);
    }
//end rescue function
    //
}

//                                                      Begin Matic Chain - Additional Router Addresses
//CafeSwap		    0x9055682E58C74fc8DdBFC55Ad2428aB1F96098Fc
//DFYN Network		0xA102072A4C07F06EC3B4900FDC4C7B80b6c57429
//DODO			    0x2fA4334cfD7c56a0E7Ca02BD81455205FcBDc5E9
//Metamask Swap		0x1a1ec25DC08e98e5E93F1104B5e5cdD298707d31
//Rubic Exchange	0xeC52A30E4bFe2D6B0ba1D0dbf78f265c0a119286
//Uni V1V2 Supt     0xec7BE89e9d109e7e3Fec59c222CF297125FEFda2
//QuickSwap         0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff
//UniSwap V2        0xedf6066a2b290C185783862C7F4776A2C8077AD1

//                                                      End Matic Chain - Additional Router Addresses

//                                                      Begin Uniswap V2 Router Addresses
//Ethereum	        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
//GoerliTN	        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
//Base		        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
//BSC		        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
//Arbitrum	        0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
//Optimism	        0x4A7b5Da61326A6379179b40d00F57E5bbDC962c2
//Polygon	        0xedf6066a2b290C185783862C7F4776A2C8077AD1
//                                                      End Uniswap V2 Router Addresses

//                                                      Begin Ethereum Mainnet - Additional Router Addresses
//UniswapEX		    0xbD2a43799B83d9d0ff56B85d4c140bcE3d1d1c6c
//Uniswap U r2		0xEf1c6E67703c7BD7107eed8303Fbe6EC2554BF6B
//Uniswap U r1		0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD
//UniswapV3:r2		0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
//UniswapV3:r1		0xE592427A0AEce92De3Edee1F18E0157C05861564
//UniswapV2:r2		0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
//THORSwap: rV2		0xC145990E84155416144C532E31f89B840Ca8c2cE
//MM Swap r		    0x881D40237659C251811CEC9c364ef91dC08D300C
//Kyber:MetaAgg rV2	0x6131B5fae19EA4f9D964eAc0408E4408b66337b5
//Kyber:Agg r2		0xDF1A1b60f2D438842916C0aDc43748768353EC25
//BTswap: r		    0xA4dc97a565e2364cDeB4EFe38C0F153bcCB62b01
//MistX r2		    0xfcadF926669E7caD0e50287eA7D563020289Ed2C
//MistX r1		    0xA58f22e0766B3764376c92915BA545d583c19DBc
//1inch v5 r		0x1111111254EEB25477B68fb85Ed929f73A960582
//1inch v4 r		0x1111111254fb6c44bAC0beD2854e76F90643097d
//1inch v2 r		0x111111125434b319222CdBf8C261674aDB56F3ae
//                                                      End Ethereum Mainnet - Additional Router Addresses

//                                                      Begin PancakeSwap V2 Router Addresses
//BSC	            0x10ED43C718714eb63d5aA57B78B54704E256024E
//BSCTN	            0xD99D1c33F9fC3444f8101754aBC46c52416550D1
//ETH	            0xEfF92A263d31888d860bD50809A8D171709b7b1c
//ARB	            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb
//BASE	            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb
//Linea	            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb
//zkEVM	            0x8cFe327CEc66d1C090Dd72bd0FF11d690C33a2Eb
//zkSync            0x5aEaF2883FBf30f3D62471154eDa3C0c1b05942d
//                                                      End PancakeSwap V2 Router Addresses

//                                                      Begin SushiSwap V2 Router Addresses
//Arbitrum		    0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Avalanche	        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//AvaxTN		    0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//BSC		        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//BSCTN		        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Goerli TN		    0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Polygon		    0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Boba		        0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Gnosis		    0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
//Base		        0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891
//Ethereum	        0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F
//Celo		        0x1421bDe4B10e8dd459b3BCb598810B1337D56842
//                                                      End SushiSwap V2 Router Addresses

//                                                      Begin TraderJoe V2 Router Addresses
//Avalanche		    0x60aE616a2155Ee3d9A68541Ba4544862310933d4
//Avax TN			0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901
//Arbitrum One		0xbeE5c10Cf6E4F68f831E11C1D9E59B43560B3642
//BSC			    0x89Fa1974120d2a7F83a0cb80df3654721c6a38Cd
//BSC Testnet		0x0007963AE06b1771Ee5E979835D82d63504Cf11d
//                                                      End TraderJoe V2 Router Addresses

//                                                      Begin Base Network V2 Router Addresses
//BaseSwap	        0x327Df1E6de05895d2ab08513aaDD9313Fe505d86
//RocketSwap	    0x4cf76043B3f97ba06917cBd90F9e3A2AAC1B306e
//SwapBased	        0xaaa3b1F1bd7BCc97fD1917c18ADE665C5D31F066
//SynthSwap	        0x8734B3264Dbd22F899BCeF4E92D442d538aBefF0
//                                                      End Base Network V2 Router Addresses

//                                                      Begin Pulse Chain V2 Router Addresses
//PulseX		    0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02
//                                                      End Pulse Chain V2 Router Addresses

//                                                      Begin Arbitrum Network V2 Router Addresses
//Camelot	        0xc873fEcbd354f5A56E00E710B90EF4201db2448d
//                                                      End Arbitrum Network V2 Router Addresses

/**
---

American Shiba is a multi-chain project aimed towards improving
the lives of veterans and the organizations that 
serve them through strategic charity partnerships.

Join us today at https://www.americanshiba.info 
or join our telegram at https://t.me/OFFICIALUSHIBA

---

Please see the instructions in this contract or visit the official website to Migrate.

---

Ready to Migrate from Obsolete USHIBA to Renewed USHIBA?

---

Step 1: 
        Verify Obsolete USHIBA Token Balance

- Open your preferred web3 wallet (e.g., MetaMask, Trust Wallet).
- Add the Obsolete USHIBA Token using its contract address: 
        0xB893A8049f250b57eFA8C62D51527a22404D7c9A
- Confirm the Obsolete USHIBA Token balance in your wallet.

---

Step 2: 
        Connect to the Migration Interface Dapp's website

- Navigate to the official website:
            https://www.americanshiba.info 
- Use the official MIGRATE button located in the menu/banner.
- You will be taken to the Migration Interface Dapp's website.
- Once the dapp's website has loaded, connect your wallet to the Migration Interface Dapp's website.
- Ensure your wallet is set to the correct network (Ethereum).

---

Step 3:
        Initiate the Migration

- Enter the amount of Obsolete USHIBA Tokens you wish to migrate to Renewed USHIBA Tokens.
- You will need to approve the amount of Obsolete USHIBA you wish to migrate in an approval transaction first, before you are able to migrate them!
- Review any fees or gas costs that will be incurred during the transactions.
- Confirm the second transaction within your wallet once prompted to officially migrate into Renewed USHIBA Tokens.

---

Step 4: 
        Add the Renewed ERC20 USHIBA Token's smart contract address to your wallet

- After the migration transaction is complete, you will need to add the Renewed USHIBA Token's contract address to your wallet.

- Use the “Add Token” feature in your wallet, then paste this smart contract's address into the field.

- The Renewed ERC20 USHIBA Token will appear, and you will be able to see your balance.

---

Step 5:
        Verify the Migration is Complete

- Check your wallet balance on Etherscan to ensure that the Obsolete ERC20 USHIBA Tokens have been deducted and the Renewed ERC20 USHIBA Tokens are indeed present.
- After these steps have been finished, you have successfully migrated from Obsolete USHIBA to Renewed USHIBA. Well done!!
- If there are any issues, check the transaction status on a blockchain explorer by using your transaction hash to see if it confirmed or not.

---

If you encounter any problems during the migration, reach out to the support team via official channels (e.g. Telegram) with your transaction hash.

ENSURE THAT ALL URLS AND CONTRACT ADDRESSES ARE FROM OFFICIAL SOURCES TO AVOID PHISHING ATTACKS!

---

American Shiba is a multi-chain project aimed towards improving
the lives of veterans and the organizations that 
serve them through strategic charity partnerships.

Join us today at https://www.americanshiba.info 
or join our telegram at https://t.me/OFFICIALUSHIBA

 */