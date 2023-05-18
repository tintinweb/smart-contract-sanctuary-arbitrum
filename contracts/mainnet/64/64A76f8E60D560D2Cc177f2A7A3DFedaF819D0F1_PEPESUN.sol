/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

/**
 *Submitted for verification at BscScan.com on 2023-05-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

interface ICamelotFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function owner() external view returns (address);

    function feePercentOwner() external view returns (address);

    function setStableOwner() external view returns (address);

    function feeTo() external view returns (address);

    function ownerFeeShare() external view returns (uint256);

    function referrersFeeShare(address) external view returns (uint256);

    function getPair(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);

    function setFeeTo(address) external;

    function feeInfo()
        external
        view
        returns (uint _ownerFeeShare, address _feeTo);
}

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
        returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

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

    function initialize(address, address) external;
}


interface IUniswapV2Router01 {
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ICamelotRouter is IUniswapV2Router01 {
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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        address referrer,
        uint deadline
    ) external;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}

contract PEPESUN is Context, IERC20, Ownable {
    using Address for address;

    //Definition of Wallets for Marketing or team.
    address payable public marketingWallet =
        payable(0x9CdeAC0AB81E817d48AD6C95410FF4bE597AC24D);
    
    address public safuWallet = 0xDaA6D667C1FaB9c02C88D56f05f60042b2563eb0;

    address public airCT = 0xe5913fFAE4b5fDE43CAbe8d70A8411D2872C12ee;

    address public mktCT = 0x787703Fd05a8294350C18E23ae6A879ef527d209;
    
    address public teamCT = 0x350aD82069BB78EB433de3FD2b223650536E51D1;

    address public cexListing = 0x64E401f0beed67958A337A8671f02bF3455d9E1d;


    //Mapping section for better tracking.
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;

    //Loging and Event Information for better troubleshooting.
    event Log(string, uint256);
    event AuditLog(string, address);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapTokensForUSDT(uint256 amountIn, address[] path);
    //Supply Definition.
    uint256 private _tTotal = 500_000_000_000_000 ether;
    //Token Definition.
    string public constant name = "PEPE SUN";
    string public constant symbol = "PPSUN";
    uint8 public constant decimals = 18;
    //Taxes Definition.
    uint public buyFee = 8;

    uint256 public sellFee = 8;

    uint256 public marketingTokensCollected = 0;
    uint256 public totalMarketingTokensCollected = 0;

    uint256 public minimumTokensBeforeSwap = 10 ether;

    //Oracle Price Update, Manual Process.
    uint256 public swapOutput = 0;
    //Trading Controls
    bool public tradingEnabled;
    bool private initialized;
    //Router and Pair Configuration.
    ICamelotRouter public immutable uniswapV2Router;
    address public  uniswapV2Pair;
    IERC20 private USDT;
    //Tracking of Automatic Swap vs Manual Swap.
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(IERC20 _usdt) {
        address currentRouter = 0xc873fEcbd354f5A56E00E710B90EF4201db2448d;
        //Owner of balance
        _tOwned[airCT] = 200_000_000_000_000 ether;
        _tOwned[safuWallet] = 175_000_000_000_000 ether;
        _tOwned[mktCT] = 50_000_000_000_000 ether;
        _tOwned[teamCT] = 25_000_000_000_000 ether;
        _tOwned[cexListing] = 50_000_000_000_000 ether;
       
        
        //Create Pair in the contructor, this may fail on some blockchains and can be done in a separate line if needed.
        ICamelotRouter _uniswapV2Router = ICamelotRouter(currentRouter);
        USDT = _usdt;
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[safuWallet] = true;
        _isExcludedFromFee[airCT] = true;
        _isExcludedFromFee[mktCT] = true;
        _isExcludedFromFee[teamCT] = true;
        _isExcludedFromFee[cexListing] = true;
        emit Transfer(address(0), airCT, 200_000_000_000_000 ether);
        emit Transfer(address(0), safuWallet, 175_000_000_000_000 ether);
        emit Transfer(address(0), mktCT, 50_000_000_000_000 ether);
        emit Transfer(address(0), teamCT, 25_000_000_000_000 ether);
        emit Transfer(address(0), cexListing, 50_000_000_000_000 ether);
    }

    function initializePair() external onlyOwner {
        require(!initialized, "Already initialized");
        uniswapV2Pair = ICamelotFactory(uniswapV2Router.factory()).createPair(address(this), address(USDT));
        initialized = true;
    }

    //Readable Functions.
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    //ERC 20 Standard Transfer Functions
    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    //ERC 20 Standard Allowance Function
    function allowance(
        address _owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }

    //ERC 20 Standard Approve Function
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    //ERC 20 Standard Transfer From
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        uint currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    //ERC 20 Standard increase Allowance
    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    //ERC 20 Standard decrease Allowance
    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    //Approve Function
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }

    //Transfer function, validate correct wallet structure, take fees, and other custom taxes are done during the transfer.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            _tOwned[from] >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        //Enable Trade after sale is finilized
        require(tradingEnabled || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading not yet enabled!");

        //Adding logic for automatic swap.
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >=
            minimumTokensBeforeSwap;
        uint fee = 0;
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            overMinimumTokenBalance &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify();
        }
        if (to == uniswapV2Pair && !_isExcludedFromFee[from]) {
            fee = (sellFee * amount) / 100;
        }
        if (from == uniswapV2Pair && !_isExcludedFromFee[to]) {
            fee = (buyFee * amount) / 100;
        }
        amount -= fee;
        if (fee > 0) {
            _tokenTransfer(from, address(this), fee);
            marketingTokensCollected += fee;
            totalMarketingTokensCollected += fee;
        }
        _tokenTransfer(from, to, amount);
    }

    //Swap Tokens for USDT or to add liquidity either automatically or manual, by default this is set to manual.
    //Corrected newBalance bug, it sending usdt to wallet and any remaining is on contract and can be recoverred.
    function swapAndLiquify() public lockTheSwap {
        uint256 totalTokens = balanceOf(address(this));
        swapTokensForUSDT(totalTokens);
        marketingTokensCollected = 0;
    }

    //swap for usdt is to support the converstion of tokens to usdt during swapandliquify this is a supporting function
    function swapTokensForUSDT(uint256 tokenAmount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDT);
        _approve(address(this), address(uniswapV2Router), tokenAmount);
       
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(tokenAmount,0,path,marketingWallet,address(0),block.timestamp);
    
        emit SwapTokensForUSDT(tokenAmount, path);
    }

    //ERC 20 standard transfer, only added if taking fees to countup the amount of fees for better tracking and split purpose.
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _tOwned[sender] -= amount;
        _tOwned[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    //exclude wallets from fees, this is needed for launch or other contracts.
    function excludeFromFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] != true, "The wallet is already excluded!");
        _isExcludedFromFee[account] = true;
        emit AuditLog(
            "We have excluded the following walled in fees:",
            account
        );
    }

    //include wallet back in fees.
    function includeInFee(address account) external onlyOwner {
        require(_isExcludedFromFee[account] != false, "The wallet is already included!");
        _isExcludedFromFee[account] = false;
        emit AuditLog(
            "We have including the following walled in fees:",
            account
        );
    }

    //Automatic Swap Configuration.
    function setTokensToSwap(
        uint256 _minimumTokensBeforeSwap
    ) external onlyOwner {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
        emit Log(
            "We have updated minimunTokensBeforeSwap to:",
            minimumTokensBeforeSwap
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(swapAndLiquifyEnabled != _enabled, "Value already set");
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //set a new marketing wallet.
    function setMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != address(0), "setmarketingWallet: ZERO");
        marketingWallet = payable(_marketingWallet);
        emit AuditLog("We have Updated the MarketingWallet:", marketingWallet);
    }

    //set fee trading.
    function setFee(uint256 _feeBuy, uint256 _feeSell) external onlyOwner {
        require(_feeBuy <= 25, "Fee Limit");
        require(_feeSell <= 25, "Fee Limit");
        buyFee =  _feeBuy;
        sellFee = _feeSell;
    }


    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    // Withdraw ETH that's potentially stuck in the Contract
    function recoverETHfromContract() external onlyOwner {
        uint ethBalance = address(this).balance;
        (bool succ, ) = payable(marketingWallet).call{value: ethBalance}("");
        require(succ, "Transfer failed");
        emit AuditLog(
            "We have recover the stuck eth from contract.",
            marketingWallet
        );
    }

    // Withdraw ERC20 tokens that are potentially stuck in Contract
    function recoverTokensFromContract(
        address _tokenAddress,
        uint256 _amount
    ) external onlyOwner {
        require(
            _tokenAddress != address(this),
            "Owner can't claim contract's balance of its own tokens"
        );
        bool succ = IERC20(_tokenAddress).transfer(marketingWallet, _amount);
        require(succ, "Transfer failed");
        emit Log("We have recovered tokens from contract:", _amount);
    }

    //Trading Controls for SAFU Contract
    //Updated code to enable swapAndLiquify at the time of enable trade.
    function enableTrading() external onlyOwner{
        require(!tradingEnabled, "Trading already enabled.");
        tradingEnabled = true;
        swapAndLiquifyEnabled = true;
        emit AuditLog("We have Enable Trading and Automatic Swaps:", msg.sender);
    }
}