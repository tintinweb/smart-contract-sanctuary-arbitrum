// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../constants/BaseConstants.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV3Pool.sol";
import "./interfaces/IUniswapV3SwapCallback.sol";
import "../core/interfaces/IVault.sol";
import "../core/interfaces/IPriceManager.sol";
import "../core/interfaces/ISettingsManager.sol";

import {SwapRequest} from "../constants/Structs.sol";

pragma solidity ^0.8.12;

contract SwapRouter is Ownable, ReentrancyGuard, BaseConstants, ISwapRouter, IUniswapV3SwapCallback {
    using SafeERC20 for IERC20;
    
    IVault public vault;
    ISettingsManager public settingsManager;
    IPriceManager public priceManager;
    address public positionRouter;

    bool public isEnableVaultSwap;
    bool public isEnableUniswapV3;
    uint256 public swapFee;

    //V3
    address public uniswapV3Router;
    mapping(address => address) public swapV3Pools;

    //V2
    address public swapV2Factory;
    address public swapV2Router;

    //Vault config events
    event SetVault(address vault);
    event SetSettingsManager(address settingsManager);
    event SetPriceManager(address priceManager);
    event SetPositionRouter(address positionRouter);
    
    //Swap events
    event SetEnableVaultSwap(bool isEnableVaultSwap);
    event SetSwapFee(uint256 swapFee);

    event SetEnableUniswapV3(bool isEnableUniswapV3);
    event SetUniswapV3Router(address uniswapV3Router);
    event SetSwapV3Pool(address colalteralToken, address poolV3Address);

    event SetSwapV2Factory(address swapV2Factory);
    event SetSwapV2Router(address swapV2Router);

    event Swap(
        bytes32 key, 
        address sender, 
        address indexed tokenIn, 
        uint256 amountIn, 
        address indexed tokenOut, 
        address indexed receiver, 
        uint256 amountOut, 
        bool isVaultSwap
    );

    constructor(address _vault, address _settingsManager, address _priceManager) {
        require(Address.isContract(_vault), "Invalid vault");
        require(Address.isContract(_settingsManager), "Invalid settingsManager");
        require(Address.isContract(_priceManager), "Invalid priceManager");
       
        vault = IVault(_vault);
        emit SetVault(_vault);

        settingsManager = ISettingsManager(_settingsManager);
        emit SetSettingsManager(_settingsManager);

        priceManager = IPriceManager(_priceManager);
        emit SetPriceManager(_priceManager);
    }

    function setVault(address _vault) external onlyOwner {
        require(Address.isContract(_vault), "Invalid vault");
        vault = IVault(_vault);
        emit SetVault(_vault);
    }

    function setPositionRouter(address _positionRouter) external onlyOwner {
        require(Address.isContract(_positionRouter), "Invalid positionRouter");
        positionRouter = _positionRouter;
        emit SetPositionRouter(_positionRouter);
    }

    function setSettingsManager(address _settingsManager) external onlyOwner {
        require(Address.isContract(_settingsManager), "Invalid settingsManager");
        settingsManager = ISettingsManager(_settingsManager);
        emit SetSettingsManager(_settingsManager);
    }

    function setPriceManager(address _priceManager) external onlyOwner {
        require(Address.isContract(_priceManager), "Invalid priceManager");
        priceManager = IPriceManager(_priceManager);
        emit SetPriceManager(_priceManager);
    }

    function setEnableVaultSwap(bool _isEnableVaultSwap) external onlyOwner {
        isEnableVaultSwap = _isEnableVaultSwap;
        emit SetEnableVaultSwap(_isEnableVaultSwap);
    }

    function setSwapV2Factory(address _swapV2Factory) external onlyOwner {
        swapV2Factory = _swapV2Factory;
        emit SetSwapV2Factory(_swapV2Factory);
    }

    function setSwapV2Router(address _swapV2Router) external onlyOwner {
        swapV2Router = _swapV2Router;
        emit SetSwapV2Router(_swapV2Router);
    }

    function setEnableUniswapV3(bool _isEnableUniswapV3) external onlyOwner {
        isEnableUniswapV3 = _isEnableUniswapV3;
        emit SetEnableUniswapV3(_isEnableUniswapV3);
    }

    function setUniswapV3Router(address _uniswapV3Router) external onlyOwner {
        uniswapV3Router = _uniswapV3Router;
        emit SetUniswapV3Router(_uniswapV3Router);
    }

    function setSwapPoolV3(address _token, address _poolV3Address) external onlyOwner {
        swapV3Pools[_token] = _poolV3Address;
        emit SetSwapV3Pool(_token, _poolV3Address);
    }

    function swapFromInternal(
        bytes32 _key,
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        uint256 _amountOutMin
    ) external override nonReentrant returns (uint256) {
        require(msg.sender == positionRouter, "Forbidden");
        require(_amountIn > 0, "Invalid amountIn");
        require(_amountOutMin > 0, "Amount out mint must greater than zero");
        uint256 amountOut = _swap(
            _key,
            true,
            _tokenIn, 
            _amountIn, 
            _tokenOut,
            address(vault),
            address(vault)
        );
        require(amountOut > 0 && amountOut >= _amountOutMin, "Too little received");

        return amountOut;
    }

    function swap(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _receiver, 
        uint256 _amountOutMin 
    ) external override nonReentrant returns (uint256) {
        require(_amountOutMin > 0, "AmountOutMin must greater than zero");
        address sender = msg.sender;
        require(IERC20(_tokenIn).balanceOf(sender) >= _amountIn, "Insufficient swap amount");
        require(IERC20(_tokenIn).allowance(sender, address(this)) >= _amountIn, 
            "Please approve vault to use swap amount first");
        uint256 amountOut = _swap(
            "0x", 
            false,
            _tokenIn, 
            _amountIn, 
            _tokenOut, 
            sender, 
            _receiver
        );
        require(amountOut >= _amountOutMin, "Too little received");

        return amountOut;
    }

    function _swap(
        bytes32 _key, 
        bool _hasPaid,
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _sender, 
        address _receiver
    ) internal returns (uint256) {
        uint256 amountOut;
        bool isDirectExecuted;

        if (isEnableVaultSwap) {
            (amountOut, isDirectExecuted) = _vaultSwap(
                _tokenIn, 
                _amountIn, 
                _tokenOut, 
                _sender, 
                _receiver,  
                _hasPaid
            );
        }

        if (!isEnableVaultSwap || !isDirectExecuted) {
            amountOut = isEnableUniswapV3 ? 
                _ammSwapV3(
                    _tokenIn, 
                    _amountIn, 
                    _tokenOut, 
                    _sender, 
                    _receiver, 
                    _key, 
                    _hasPaid
                ) : 
                _ammSwapV2(
                    _tokenIn, 
                    _amountIn, 
                    _tokenOut, 
                    _sender, 
                    _receiver, 
                    _hasPaid
                );
        }
        require(amountOut > 0, "Invalid received swap amount");

        emit Swap(
            _key, 
            _sender, 
            _tokenIn, 
            _amountIn, 
            _tokenOut, 
            _receiver, 
            amountOut, 
            isEnableVaultSwap && isDirectExecuted
        );

        return amountOut;
    }

    function _vaultSwap(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _sender, 
        address _receiver, 
        bool _hasPaid
    ) internal returns (uint256, bool) {
        uint256 tokenInPrice;
        uint256 tokenOutPrice;
        bool isDirectExecuted;

        {
            (tokenInPrice, isDirectExecuted) = _isDirectExecuted(_tokenIn);
            (tokenOutPrice, isDirectExecuted) = _isDirectExecuted(_tokenOut);
        }

        if (!isDirectExecuted) {
            return (0, false);
        }

        uint256 amountInUSD = _fromTokenToUSD(_tokenIn, _amountIn, tokenInPrice);
        uint256 fee = amountInUSD * swapFee / BASIS_POINTS_DIVISOR;
        uint256 amountOutAfterFee = _fromUSDToToken(_tokenOut, amountInUSD - fee, tokenOutPrice);

        if (_receiver != address(vault) && vault.getBalance(_tokenOut) < amountOutAfterFee) {
            return (0, false);
        }

        if (!_hasPaid) {
            _transferFrom(_tokenIn, _sender, _amountIn);
            _transferTo(_tokenIn, _amountIn, address(vault));
        }

        if (_receiver != address(vault)) {
            _takeAssetOut(_receiver, fee, amountOutAfterFee, _tokenOut);
        }

        return (amountOutAfterFee, true);
    }

    function _ammSwapV2(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _sender, 
        address _receiver, 
        bool _hasPaid
    ) internal returns (uint256) {
        require(swapV2Factory != address(0), "SwapV2Factory has not been configured yet");
        address swapV2Pool = IUniswapV2Factory(swapV2Factory).getPair(_tokenIn, _tokenOut);
        require(swapV2Pool != address(0), "Invalid swapV2Pool");
        require(swapV3Pools[_tokenIn] == _tokenOut, "Invalid pool address");

        if (!_hasPaid) {
            _transferFrom(_tokenIn, _sender, _amountIn);
            _transferTo(_tokenIn, _amountIn, swapV2Pool);
        }

        address token0 = IUniswapV2Pair(swapV2Pool).token0();
        bool isZeroForOne = _tokenIn == token0;
        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = isZeroForOne ? _tokenOut : _tokenIn;
        uint[] memory estAmounts = IUniswapV2Router(swapV2Router).getAmountsOut(swapV2Factory, _amountIn, path);
        require(estAmounts.length == 2, "Invalid estAmounts length");
        require(estAmounts[1] > 0, "Invalid estAmounts");

        if (isZeroForOne) {
            IUniswapV2Pair(swapV2Pool).swap(
                0,
                estAmounts[1],
                _receiver,
                new bytes(0)
            );
        } else {
            IUniswapV2Pair(swapV2Pool).swap(
                estAmounts[1],
                0,
                _receiver,
                new bytes(0)
            );
        }

        return estAmounts[1];
    }

    function _ammSwapV3(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _sender, 
        address _receiver, 
        bytes32 _key, 
        bool _hasPaid
    ) internal returns (uint256) {
        require(uniswapV3Router != address(0), "Uniswap router has not configured yet");
        require(swapV3Pools[_tokenIn] != address(0), "Pool has not configured yet");
        require(swapV3Pools[_tokenIn] == _tokenOut, "Invalid pool address");

        if (!_hasPaid) {
            _transferFrom(_tokenIn, _sender, _amountIn);
        }

        bool zeroForOne = _tokenIn < _tokenOut;
        SwapRequest memory swapRequest = SwapRequest(
                _key, 
                zeroForOne ? _tokenIn : _tokenOut, 
                swapV3Pools[_tokenIn], 
                _amountIn
        );
        bytes memory callData = abi.encode(swapRequest);
        (int256 amount0, int256 amount1) = IUniswapV3Pool(swapV3Pools[_tokenIn]).swap(
            _receiver, 
            zeroForOne, 
            int256(_amountIn), 
            0, 
            callData
        );

        return uint256(zeroForOne ? amount1 : amount0);
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        SwapRequest memory swapRequest = abi.decode(data, (SwapRequest));
        uint256 transferAmount = swapRequest.amountIn;
        require(transferAmount > 0, "Invalid swap callback amount");
        address tokenIn = swapRequest.tokenIn;
        require(msg.sender == swapV3Pools[tokenIn], "Invalid pool sender");
        require(IERC20(tokenIn).balanceOf(address(this)) >= transferAmount, "Insufficient to swap");
        IERC20(tokenIn).safeTransfer(swapRequest.pool, transferAmount);
    }

    function _takeAssetOut(
        address _receiver,
        uint256 fee,
        uint256 amountOutAfterFee, 
        address _tokenOut
    ) internal {
        vault.takeAssetOut(_receiver, address(0), fee, amountOutAfterFee + fee, _tokenOut, PRICE_PRECISION);
    }

    function _fromTokenToUSD(address _token, uint256 _tokenAmount, uint256 _price) internal view returns (uint256) {
        if (_tokenAmount == 0) {
            return 0;
        }

        uint256 decimals = priceManager.tokenDecimals(_token);
        require(decimals > 0, "Invalid decimals while converting from token to USD");
        return (_tokenAmount * _price) / (10 ** decimals);
    }

    function _fromUSDToToken(address _token, uint256 _usdAmount, uint256 _price) internal view returns (uint256) {
        if (_usdAmount == 0) {
            return 0;
        }
        
        uint256 decimals = priceManager.tokenDecimals(_token);
        require(decimals > 0, "Invalid decimals while converting from USD to token");
        return (_usdAmount * (10 ** decimals)) / _price;
    }

    function _isDirectExecuted(address _indexToken) internal view returns (uint256, bool) {
        (uint256 price, uint256 updatedAt, bool isFastPrice) = priceManager.getLatestSynchronizedPrice(_indexToken);
        uint256 maxPriceUpdatedDelay = settingsManager.maxPriceUpdatedDelay();
        bool isDirectExecuted = isFastPrice && price > 0 
            && maxPriceUpdatedDelay > 0  && block.timestamp - updatedAt <= maxPriceUpdatedDelay;

        return (price, isDirectExecuted);
    }

    function _transferFrom(address _token, address _account, uint256 _amount) internal {
        IERC20(_token).safeTransferFrom(_account, address(this), _amount);
    }

    function _transferTo(address _token, uint256 _amount, address _receiver) internal {
        IERC20(_token).safeTransfer(_receiver, _amount);
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract BaseConstants {
    uint256 public constant BASIS_POINTS_DIVISOR = 100000;

    uint256 public constant PRICE_PRECISION = 10 ** 18; //Base on RUSD decimals

    uint256 public constant DEFAULT_ROLP_PRICE = 100000; //1 USDC

    uint256 public constant ROLP_DECIMALS = 18;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISwapRouter {
    function swapFromInternal(
        bytes32 _key,
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut,
        uint256 _amountOutMin
    ) external returns (uint256);

    function swap(
        address _tokenIn, 
        uint256 _amountIn, 
        address _tokenOut, 
        address _receiver, 
        uint256 _amountOutMin 
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV2Router {
    function getAmountsOut(address factory, uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function token0() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IUniswapV3Pool {
    function swap(
            address recipient,
            bool zeroForOne,
            int256 amountSpecified,
            uint160 sqrtPriceLimitX96,
            bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IVault {
    function accountDeltaAndFeeIntoTotalBalance(
        bool _hasProfit, 
        uint256 _adjustDelta, 
        uint256 _fee,
        address _token
    ) external;

    function distributeFee(address _account, address _refer, uint256 _fee, address _token) external;

    function takeAssetIn(
        address _account, 
        address _refer, 
        uint256 _amount, 
        uint256 _fee, 
        address _token
    ) external;

    function takeAssetOut(
        address _account, 
        address _refer, 
        uint256 _fee, 
        uint256 _usdOut, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function transferBounty(
        address _account, 
        uint256 _amount, 
        address _token, 
        uint256 _tokenPrice
    ) external;

    function ROLP() external view returns(address);

    function RUSD() external view returns(address);

    function totalUSD() external view returns(uint256);

    function totalROLP() external view returns(uint256);

    function updateTotalROLP() external;

    function updateBalance(address _token) external;

    function updateBalances() external;

    function getBalance(address _token) external view returns (uint256);

    function getBalances() external view returns (address[] memory, uint256[] memory);

    function convertRUSD(
        address _account,
        address _recipient, 
        address _tokenOut, 
        uint256 _amount
    ) external;

    function stake(address _account, address _token, uint256 _amount) external;

    function unstake(address _tokenOut, uint256 _rolpAmount, address _receiver) external;

    function emergencyDeposit(address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IPriceManager {
    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _indexPrice
    ) external view returns (bool, uint256);

    function getLastPrice(address _token) external view returns (uint256);

    function getLatestSynchronizedPrice(address _token) external view returns (uint256, uint256, bool);

    function getLatestSynchronizedPrices(uint256 _maxDelayAllowance, address[] memory _tokens) external view returns (uint256[] memory, bool);

    function setLatestPrice(address _token, uint256 _latestPrice) external;

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function isForex(address _token) external view returns (bool);

    function maxLeverage(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function fromUSDToToken(address _token, uint256 _usdAmount) external view returns (uint256);

    function fromTokenToUSD(address _token, uint256 _tokenAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface ISettingsManager {
    function decreaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(address _token, address _sender, bool _isLong, uint256 _amount) external;

    function updateCumulativeFundingRate(address _token, bool _isLong) external;

    function openInterestPerAsset(address _token) external view returns (uint256);

    function openInterestPerSide(bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint256);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function closeDeltaTime() external view returns (uint256);

    function collectMarginFees(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function cumulativeFundingRates(address _token, bool _isLong) external view returns (uint256);

    function delayDeltaTime() external view returns (uint256);

    function depositFee() external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function fundingInterval() external view returns (uint256);

    function fundingRateFactor(address _token, bool _isLong) external view returns (uint256);

    function getFundingFee(
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getPositionFee(address _indexToken, bool _isLong, uint256 _sizeDelta) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isCollateral(address _token) external view returns (bool);

    function isTradable(address _token) external view returns (bool);

    function isStable(address _token) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function isStaking(address _token) external view returns (bool);

    function lastFundingTimes(address _token, bool _isLong) external view returns (uint256);

    function maxPriceUpdatedDelay() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function liquidateThreshold(address) external view returns (uint256);

    function marginFeeBasisPoints(address _token, bool _isLong) external view returns (uint256);

    function marketOrderEnabled() external view returns (bool);
    
    function pauseForexForCloseTime() external view returns (bool);

    function priceMovementPercent() external view returns (uint256);

    function referFee() external view returns (uint256);

    function referEnabled() external view returns (bool);

    function stakingFee() external view returns (uint256);

    function unstakingFee() external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function positionDefaultSlippage() external view returns (uint256);

    function setPositionDefaultSlippage(uint256 _slippage) external;

    function isOnBeta() external view returns (bool);

    function isEnableNonStableCollateral() external view returns (bool);

    function isEnableConvertRUSD() external view returns (bool);

    function isEnableUnstaking() external view returns (bool);

    function validatePosition(
        address _account,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _collateral
    ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT,
    TRAILING_STOP
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    OPEN,
    TRIGGERED,
    CANCELLED
}

enum DataType {
    POSITION,
    ORDER,
    TRANSACTION
}

struct OrderInfo {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 pendingSize;
    uint256 pendingCollateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 amountOutMin;
    address collateralToken;
}

struct Position {
    address owner;
    address refer;
    int256 realisedPnl;
    uint256 averagePrice;
    uint256 collateral;
    uint256 entryFundingRate;
    uint256 lastIncreasedTime;
    uint256 lastPrice;
    uint256 reserveAmount;
    uint256 size;
    uint256 deadline;
    uint256 slippage;
    uint256 totalFee;
}

struct TriggerOrder {
    bytes32 key;
    uint256[] slPrices;
    uint256[] slAmountPercents;
    uint256[] slTriggeredAmounts;
    uint256[] tpPrices;
    uint256[] tpAmountPercents;
    uint256[] tpTriggeredAmounts;
    TriggerStatus status;
}

struct ConvertOrder {
    uint256 index;
    address indexToken;
    address sender;
    address recipient;
    uint256 amountIn;
    uint256 amountOut;
    uint256 state;
}

struct SwapPath {
    address pairAddress;
    uint256 fee;
}

struct SwapRequest {
    bytes32 orderKey;
    address tokenIn;
    address pool;
    uint256 amountIn;
}

struct PrepareTransaction {
    uint256 txType;
    uint256 startTime;
    uint256 status; //0 = pending, 1 = executed
    uint256 deadline;
    uint256 amountOutMin;
    uint256[] params;
    address[] path;
}

struct PositionBond {
    address owner;
    address indexToken;
    address token; //Collateral token
    uint256 amount; //Collateral amount
    uint256 leverage;
    uint256 posId;
    bool isLong;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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