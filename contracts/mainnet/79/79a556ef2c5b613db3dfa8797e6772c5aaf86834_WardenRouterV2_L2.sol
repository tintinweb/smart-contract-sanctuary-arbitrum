/**
 *Submitted for verification at Arbiscan on 2022-04-28
*/

// SPDX-License-Identifier: MIT

// ((/*,                                                                    ,*((/,.
// &&@@&&%#/*.                                                        .*(#&&@@@@%. 
// &&@@@@@@@&%(.                                                    ,#%&@@@@@@@@%. 
// &&@@@@@@@@@&&(,                                                ,#&@@@@@@@@@@@%. 
// &&@@@@@@@@@@@&&/.                                            .(&&@@@@@@@@@@@@%. 
// %&@@@@@@@@@@@@@&(,                                          *#&@@@@@@@@@@@@@@%. 
// #&@@@@@@@@@@@@@@&#*                                       .*#@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@#.                                      ,%&@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@%(,                                    ,(&@@@@@@@@@@@@@@@@&#. 
// #&@@@@@@@@@@@@@@@@&&/                                   .(%&@@@@@@@@@@@@@@@@&#. 
// #%@@@@@@@@@@@@@@@@@@(.               ,(/,.              .#&@@@@@@@@@@@@@@@@@&#. 
// (%@@@@@@@@@@@@@@@@@@#*.            ./%&&&/.            .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#*.           *#&@@@@&%*.          .*%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.         ./#@@@@@@@@%(.         ./%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@#/.        ./&@@@@@@@@@@&(*        ,/%@@@@@@@@@@@@@@@@@@%(. 
// (%@@@@@@@@@@@@@@@@@@%/.       ,#&@@@@@@@@@@@@&#,.      ,/%@@@@@@@@@@@@@@@@@@%(. 
// /%@@@@@@@@@@@@@@@@@@#/.      *(&@@@@@@@@@@@@@@&&*      ./%@@@@@@@@@@@@@@@@@&%(. 
// /%@@@@@@@@@@@@@@@@@@#/.     .(&@@@@@@@@@@@@@@@@@#*.    ,/%@@@@@@@@@@@@@@@@@&#/. 
// ,#@@@@@@@@@@@@@@@@@@#/.    ./%@@@@@@@@@@@@@@@@@@&#,    ,/%@@@@@@@@@@@@@@@@@&(,  
//  /%&@@@@@@@@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@&*    ,/%@@@@@@@@@@@@@@@@&%*   
//  .*#&@@@@@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/.   ,/%@@@@@@@@@@@@@@@@#*.   
//    ,(&@@@@@@@@@@@@@@#/.    /@@@@@@@@@@@@@@@@@@@@@&(,   ,/%@@@@@@@@@@@@@@%(,     
//     .*(&&@@@@@@@@@@@#/.    /&&@@@@@@@@@@@@@@@@@@@&/,   ,/%@@@@@@@@@@@&%/,       
//        ./%&@@@@@@@@@#/.    *#&@@@@@@@@@@@@@@@@@@@%*    ,/%@@@@@@@@@&%*          
//           ,/#%&&@@@@#/.     ,#&@@@@@@@@@@@@@@@@@#/.    ,/%@@@@&&%(/,            
//               ./#&@@%/.      ,/&@@@@@@@@@@@@@@%(,      ,/%@@%#*.                
//                   .,,,         ,/%&@@@@@@@@&%(*        .,,,.                    
//                                   ,/%&@@@%(*.                                   
//  .,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,**((/*,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
//                                                                                                                                                                                                                                                                                                            
//

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File @openzeppelin/contracts/token/ERC20/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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


// File contracts/libraries/TransferHelper.sol

pragma solidity ^0.8.0;

interface IERC20NoReturn {
    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

// helper methods for interacting with ERC20 tokens that do not consistently return boolean
library TransferHelper {
    function safeTransfer(IERC20 token, address to, uint value) internal {
        try IERC20NoReturn(address(token)).transfer(to, value) {

        } catch Error(string memory reason) {
            // catch failing revert() and require()
            revert(reason);
        } catch  {
            revert("TransferHelper: transfer failed");
        }
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        try IERC20NoReturn(address(token)).transferFrom(from, to, value) {

        } catch Error(string memory reason) {
            // catch failing revert() and require()
            revert(reason);
        } catch {
            revert("TransferHelper: transferFrom failed");
        }
    }
}


// File contracts/interface/IWETH.sol


pragma solidity ^0.8.0;


interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


// File contracts/interface/IWardenPreTrade2.sol

pragma solidity ^0.8.0;

interface IWardenPreTrade2 {
    function preTradeAndFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        address     _trader,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        external
        returns (
            uint256[] memory _fees,
            address[] memory _collectors
        );
}


// File @openzeppelin/contracts/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/interface/IWardenSwap2.sol

pragma solidity ^0.8.0;

interface IWardenSwap2 {
    function trade(
        bytes calldata  _data,
        IERC20      _src,
        uint256     _srcAmount,
        uint256     _originalSrcAmount,
        IERC20      _dest,
        address     _receiver,
        address     _trader,
        uint256     _partnerId,
        uint256     _metaData
    )
        external;
    
    function tradeSplit(
        bytes calldata  _data,
        uint256[] calldata _volumes,
        IERC20      _src,
        uint256     _totalSrcAmount,
        uint256     _originalSrcAmount,
        IERC20      _dest,
        address     _receiver,
        address     _trader,
        uint256     _partnerId,
        uint256     _metaData
    )
        external;
}


// File contracts/swap/WardenRouterV2.sol

pragma solidity ^0.8.0;





contract WardenRouterV2 is Ownable {
    using TransferHelper for IERC20;
    
    IWardenPreTrade2 public preTrade;

    IWETH public immutable weth;
    IERC20 private constant ETHER_ERC20 = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    
    event UpdatedWardenPreTrade(
        IWardenPreTrade2 indexed preTrade
    );

    /**
    * @dev When fee is collected by WardenSwap for a trade, this event will be emitted
    * @param token Collected token
    * @param wallet Collector address
    * @param amount Amount of fee collected
    */
    event ProtocolFee(
        IERC20  indexed   token,
        address indexed   wallet,
        uint256           amount
    );

    /**
    * @dev When fee is collected by WardenSwap's partners for a trade, this event will be emitted
    * @param partnerId Partner ID
    * @param token Collected token
    * @param wallet Collector address
    * @param amount Amount of fee collected
    */
    event PartnerFee(
        uint256 indexed   partnerId,
        IERC20  indexed   token,
        address indexed   wallet,
        uint256           amount
    );

    /**
    * @dev When the new trade occurs (and success), this event will be emitted.
    * @param srcAsset Source token
    * @param srcAmount Amount of source token
    * @param destAsset Destination token
    * @param destAmount Amount of destination token
    * @param trader User address
    */
    event Trade(
        address indexed srcAsset,
        uint256         srcAmount,
        address indexed destAsset,
        uint256         destAmount,
        address indexed trader,
        address         receiver,
        bool            hasSplitted
    );

    constructor(
        IWardenPreTrade2 _preTrade,
        IWETH _weth
    ) {
        preTrade = _preTrade;
        weth = _weth;
        
        emit UpdatedWardenPreTrade(_preTrade);
    }

    function updateWardenPreTrade(
        IWardenPreTrade2 _preTrade
    )
        external
        onlyOwner
    {
        preTrade = _preTrade;
        emit UpdatedWardenPreTrade(_preTrade);
    }

    /**
    * @dev Performs a trade with single volume
    * @param _swap Warden Swap contract
    * @param _data Warden Swap payload
    * @param _deposits Source token receiver
    * @param _src Source token
    * @param _srcAmount Amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount Minimum of destination token amount
    * @param _receiver Destination token receiver
    * @param _partnerId Partner id for fee sharing / Referral
    * @param _metaData Reserved for upcoming features
    * @return _destAmount Amount of actual destination tokens
    */
    function swap(
        IWardenSwap2    _swap,
        bytes calldata  _data,
        address     _deposits,
        IERC20      _src,
        uint256     _srcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        public
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        // Collect fee
        uint256 newSrcAmount = _preTradeAndCollectFee(
            _src,
            _dest,
            _srcAmount,
            msg.sender,
            _receiver,
            _partnerId,
            _metaData
        );

        // Wrap ETH
        if (ETHER_ERC20 == _src) {
            require(msg.value == _srcAmount, "WardenRouter::swap: Ether source amount mismatched");
            weth.deposit{value: newSrcAmount}();
            
            // Transfer user tokens to target
            IERC20(address(weth)).safeTransfer(_deposits, newSrcAmount);
        } else {
            // Transfer user tokens to target
            _src.safeTransferFrom(msg.sender, _deposits, newSrcAmount);
        }

        bytes memory payload = abi.encodeWithSelector(IWardenSwap2.trade.selector,
            _data,
            _src,
            newSrcAmount,
            _srcAmount,
            _dest,
            _receiver,
            msg.sender,
            _partnerId,
            _metaData
        );

        _destAmount = _internalSwap(
            _swap,
            payload,
            _dest,
            _minDestAmount,
            _receiver
        );
        emit Trade(address(_src), _srcAmount, address(_dest), _destAmount, msg.sender, _receiver, false);
    }

    /**
    * @dev Performs a trade by splitting volumes
    * @param _swap Warden Swap contract
    * @param _data Warden Swap payload
    * @param _deposits Source token receivers
    * @param _volumes Volume percentages
    * @param _src Source token
    * @param _totalSrcAmount Amount of source tokens
    * @param _dest Destination token
    * @param _minDestAmount Minimum of destination token amount
    * @param _receiver Destination token receiver
    * @param _partnerId Partner id for fee sharing / Referral
    * @param _metaData Reserved for upcoming features
    * @return _destAmount Amount of actual destination tokens
    */
    function swapSplit(
        IWardenSwap2    _swap,
        bytes calldata  _data,
        address[] memory _deposits,
        uint256[] memory _volumes,
        IERC20      _src,
        uint256     _totalSrcAmount,
        IERC20      _dest,
        uint256     _minDestAmount,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        public
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        // Collect fee
        uint256 newTotalSrcAmount = _preTradeAndCollectFee(
            _src,
            _dest,
            _totalSrcAmount,
            msg.sender,
            _receiver,
            _partnerId,
            _metaData
        );

        // Wrap ETH
        if (ETHER_ERC20 == _src) {
            require(msg.value == _totalSrcAmount, "WardenRouter::swapSplit: Ether source amount mismatched");
            weth.deposit{value: newTotalSrcAmount}();
        }

        // Transfer user tokens to targets
        _depositVolumes(
            newTotalSrcAmount,
            _deposits,
            _volumes,
            _src
        );
        

        bytes memory payload = abi.encodeWithSelector(IWardenSwap2.tradeSplit.selector,
            _data,
            _volumes,
            _src,
            newTotalSrcAmount,
            _totalSrcAmount,
            _dest,
            _receiver,
            msg.sender,
            _partnerId,
            _metaData
        );

        _destAmount = _internalSwap(
            _swap,
            payload,
            _dest,
            _minDestAmount,
            _receiver
        );
        emit Trade(address(_src), _totalSrcAmount, address(_dest), _destAmount, msg.sender, _receiver, true);
    }

    function _depositVolumes(
        uint256 newTotalSrcAmount,
        address[] memory _deposits,
        uint256[] memory _volumes,
        IERC20           _src
    )
        private
    {
        {
            uint256 amountRemain = newTotalSrcAmount;
            for (uint i = 0; i < _deposits.length; i++) {
                uint256 amountForThisRound;
                if (i == _deposits.length - 1) {
                    amountForThisRound = amountRemain;
                } else {
                    amountForThisRound = newTotalSrcAmount * _volumes[i] / 100;
                    amountRemain = amountRemain - amountForThisRound;
                }
            
                if (ETHER_ERC20 == _src) {
                    IERC20(address(weth)).safeTransfer(_deposits[i], amountForThisRound);
                } else {
                    _src.safeTransferFrom(msg.sender, _deposits[i], amountForThisRound);
                }
            }
        }
    }

    function _internalSwap(
        IWardenSwap2 _swap,
        bytes memory _payload,
        IERC20       _dest,
        uint256      _minDestAmount,
        address      _receiver
    )
        private
        returns (uint256 _destAmount)
    {
        // Record dest asset for later consistency check.
        uint256 destAmountBefore = ETHER_ERC20 == _dest ? _receiver.balance : _dest.balanceOf(_receiver);

        {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory result) = address(_swap).call(_payload);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
        }

        _destAmount = ETHER_ERC20 == _dest ? _receiver.balance - destAmountBefore : _dest.balanceOf(_receiver) - destAmountBefore;

        // Throw exception if destination amount doesn't meet user requirement.
        require(_destAmount >= _minDestAmount, "WardenRouter::_internalSwap: destination amount is too low.");
    }

    function _preTradeAndCollectFee(
        IERC20      _src,
        IERC20      _dest,
        uint256     _srcAmount,
        address     _trader,
        address     _receiver,
        uint256     _partnerId,
        uint256     _metaData
    )
        private
        returns (uint256 _newSrcAmount)
    {
        // Collect fee
        (uint256[] memory fees, address[] memory feeWallets) = preTrade.preTradeAndFee(
            _src,
            _dest,
            _srcAmount,
            _trader,
            _receiver,
            _partnerId,
            _metaData
        );
        _newSrcAmount = _srcAmount;
        if (fees.length > 0) {
            if (fees[0] > 0) {
                _collectFee(
                    _trader,
                    _src,
                    fees[0],
                    feeWallets[0]
                );
                _newSrcAmount -= fees[0];
            }
            if (fees.length == 2 && fees[1] > 0) {
                _partnerFee(
                    _trader,
                    _partnerId, // partner id
                    _src,
                    fees[1],
                    feeWallets[1]
                );
                _newSrcAmount -= fees[1];
            }
        }
    }
    
    function _collectFee(
        address _trader,
        IERC20  _token,
        uint256 _fee,
        address _feeWallet
    )
        private
    {
        if (ETHER_ERC20 == _token) {
            (bool success, ) = payable(_feeWallet).call{value: _fee}(""); // Send ether to fee collector
            require(success, "WardenRouter::_collectFee: Transfer fee of ether failed.");
        } else {
            _token.safeTransferFrom(_trader, _feeWallet, _fee); // Send token to fee collector
        }
        emit ProtocolFee(_token, _feeWallet, _fee);
    }

    function _partnerFee(
        address _trader,
        uint256 _partnerId,
        IERC20  _token,
        uint256 _fee,
        address _feeWallet
    )
        private
    {
        if (ETHER_ERC20 == _token) {
            (bool success, ) = payable(_feeWallet).call{value: _fee}(""); // Send back ether to partner
            require(success, "WardenRouter::_partnerFee: Transfer fee of ether failed.");
        } else {
            _token.safeTransferFrom(_trader, _feeWallet, _fee);
        }
        emit PartnerFee(_partnerId, _token, _feeWallet, _fee);
    }

    /**
    * @dev Performs a trade ETH -> WETH
    * @param _receiver Receiver address
    * @return _destAmount Amount of actual destination tokens
    */
    function tradeEthToWeth(
        address     _receiver
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        weth.deposit{value: msg.value}();
        IERC20(address(weth)).safeTransfer(_receiver, msg.value);
        _destAmount = msg.value;
        emit Trade(address(ETHER_ERC20), msg.value, address(weth), _destAmount, msg.sender, _receiver, false);
    }
    
    /**
    * @dev Performs a trade WETH -> ETH
    * @param _srcAmount Amount of source tokens
    * @param _receiver Receiver address
    * @return _destAmount Amount of actual destination tokens
    */
    function tradeWethToEth(
        uint256     _srcAmount,
        address     _receiver
    )
        external
        returns(uint256 _destAmount)
    {
        if (_receiver == address(0)) {
            _receiver = msg.sender;
        }

        IERC20(address(weth)).safeTransferFrom(msg.sender, address(this), _srcAmount);
        weth.withdraw(_srcAmount);
        (bool success, ) = _receiver.call{value: _srcAmount}(""); // Send back ether to receiver
        require(success, "WardenRouter::tradeWethToEth: Transfer ether back to receiver failed.");
        _destAmount = _srcAmount;
        emit Trade(address(weth), _srcAmount, address(ETHER_ERC20), _destAmount, msg.sender, _receiver, false);
    }

    // Receive ETH in case of trade WETH -> ETH
    receive() external payable {
        require(msg.sender == address(weth), "WardenRouter: Receive Ether only from WETH");
    }

    // In case of an expected and unexpected event that has some token amounts remain in this contract, owner can call to collect them.
    function collectRemainingToken(
        IERC20  _token,
        uint256 _amount
    )
      external
      onlyOwner
    {
        _token.safeTransfer(msg.sender, _amount);
    }

    // In case of an expected and unexpected event that has some ether amounts remain in this contract, owner can call to collect them.
    function collectRemainingEther(
        uint256 _amount
    )
      external
      onlyOwner
    {
        (bool success, ) = msg.sender.call{value: _amount}(""); // Send back ether to sender
        require(success, "WardenRouter::collectRemainingEther: Transfer ether back to caller failed.");
    }
}


// File contracts/library/byte/BytesLib.sol


// MODIFIED VERSION FROM https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol

pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }
    
    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_bytes.length >= _start + 3, "toUint24_outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }
    
    function toUint80(bytes memory _bytes, uint256 _start) internal pure returns (uint80) {
        require(_bytes.length >= _start + 10, "toUint80_outOfBounds");
        uint80 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xa), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }
    
    function toUint112(bytes memory _bytes, uint256 _start) internal pure returns (uint112) {
        require(_bytes.length >= _start + 14, "toUint112_outOfBounds");
        uint112 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xe), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}


// File contracts/arbitrum/interface/IArbAddressTable.sol

pragma solidity ^0.8.0;

/** @title Precompiled contract that exists in every Arbitrum chain at 0x0000000000000000000000000000000000000066.
* Allows registering / retrieving addresses at uint indices, saving calldata.
*/
interface IArbAddressTable {
    /**
    * @notice Register an address in the address table
    * @param addr address to register
    * @return index of the address (existing index, or newly created index if not already registered)
    */
    function register(address addr) external returns(uint);

    /**
    * @param addr address to lookup
    * @return index of an address in the address table (revert if address isn't in the table)
    */
    function lookup(address addr) external view returns(uint);

    /**
    * @notice Check whether an address exists in the address table
    * @param addr address to check for presence in table
    * @return true if address is in table
    */
    function addressExists(address addr) external view returns(bool);

    /**
    * @return size of address table (= first unused index)
     */
    function size() external view returns(uint);

    /**
    * @param index index to lookup address
    * @return address at a given index in address table (revert if index is beyond end of table)
    */
    function lookupIndex(uint index) external view returns(address);

    /**
    * @notice read a compressed address from a bytes buffer
    * @param buf bytes buffer containing an address
    * @param offset offset of target address
    * @return resulting address and updated offset into the buffer (revert if buffer is too short)
    */
    function decompress(bytes calldata buf, uint offset) external pure returns(address, uint);

    /**
    * @notice compress an address and return the result
    * @param addr address to compress
    * @return compressed address bytes
    */
    function compress(address addr) external returns(bytes memory);
}


// File contracts/libraries/WardenDataDeserialize2.sol

pragma solidity ^0.8.0;


contract WardenDataDeserialize2 {
    using BytesLib for bytes;

    IArbAddressTable public immutable addressTable;
    bool public autoRegisterAddressMapping;

    event SetAutoRegisterAddressMapping(bool _enable);
    
    constructor(
        IArbAddressTable _addressTable,
        bool _autoRegisterAddressMapping
    ) {
        addressTable = _addressTable;
        autoRegisterAddressMapping = _autoRegisterAddressMapping;
    }

    function _setAutoRegisterAddressMapping(
        bool _enable
    )
        internal
    {
        autoRegisterAddressMapping = _enable;
        emit SetAutoRegisterAddressMapping(_enable);
    }

    function toBytes(bytes32 _data) private pure returns (bytes memory) {
        return abi.encodePacked(_data);
    }

    function _lookupAddress(
        bytes memory _data,
        uint256 _cursor
    )
        internal
        returns (
            address _address,
            uint256 _newCursor
        )
    {
        uint8 instruction = _data.toUint8(_cursor);
        _cursor += 1;
        
        if (instruction == 0) { // not registered
            _address =  _data.toAddress(_cursor);
            _cursor += 20;

            if (autoRegisterAddressMapping) {
                addressTable.register(_address);
            }
            
        } else if (instruction == 1) { // registered (32-bit)
            _address = addressTable.lookupIndex(_data.toUint32(_cursor));
            _cursor += 4;

        } else if (instruction == 2) { // registered (24-bit)
            _address = addressTable.lookupIndex(_data.toUint24(_cursor));
            _cursor += 3;

        } else if (instruction == 3) { // skip
            _address = 0x0000000000000000000000000000000000000000;
            
        } else {
            revert("WardenDataDeserialize:_lookupAddress bad instruction");
        }

        _newCursor = _cursor;
    }

    function _decodeAmount(
        bytes memory _data,
        uint256 _cursor
    )
        internal
        pure
        returns (
            uint256 _amount,
            uint256 _newCursor
        )
    {
        uint8 instruction = _data.toUint8(_cursor);
        _cursor += 1;

        if (instruction == 0) { // 64-bit, 18 (denominated in 1e18)
            _amount = _data.toUint64(_cursor);
            _cursor += 8;
            
        } else if (instruction == 1) { // 80-bit, 1.2m (denominated in 1e18)
            _amount = _data.toUint80(_cursor);
            _cursor += 10;

        } else if (instruction == 2) { // 96-bit, 79.2b (denominated in 1e18)
            _amount = _data.toUint96(_cursor);
            _cursor += 12;

        } else if (instruction == 3) { // 112-bit, 5,192mm (denominated in 1e18)
            _amount = _data.toUint112(_cursor);
            _cursor += 14;
        
        } else if (instruction == 4) { // zero
            _amount = 0;

        } else {
            revert("WardenDataDeserialize:_decodeAmount bad instruction");
        }

        _newCursor = _cursor;
    }

    struct SwapData {
        address swap;
        address src;
        address dest;
        address receiver;

        uint256 srcAmount;
        uint256 minDestAmount;
        uint256 partnerId;
        uint256 metaData;
    }

    function decodeSwapData(
        bytes memory _data,
        uint256 _cursor
    )
        public
        returns (
            SwapData memory _swapData,
            uint256 _newCursor
        )
    {
        (_swapData.swap, _cursor) = _lookupAddress(_data, _cursor);
        (_swapData.src, _cursor) = _lookupAddress(_data, _cursor);
        (_swapData.dest, _cursor) = _lookupAddress(_data, _cursor);
        (_swapData.receiver, _cursor) = _lookupAddress(_data, _cursor);

        (_swapData.srcAmount, _cursor) = _decodeAmount(_data, _cursor);
        (_swapData.minDestAmount, _cursor) = _decodeAmount(_data, _cursor);
        (_swapData.partnerId, _cursor) = _decodeAmount(_data, _cursor);
        (_swapData.metaData, _cursor) = _decodeAmount(_data, _cursor);

        _newCursor = _cursor;
    }
}


// File contracts/swap/L2/WardenRouterV2_L2.sol

pragma solidity ^0.8.0;


contract WardenRouterV2_L2 is WardenRouterV2, WardenDataDeserialize2 {
    constructor(
        IWardenPreTrade2 _preTrade,
        IWETH _weth,
        IArbAddressTable _addressTable,
        bool _autoRegisterAddressMapping
    )
        WardenRouterV2(_preTrade, _weth)
        WardenDataDeserialize2(_addressTable, _autoRegisterAddressMapping)
    {
    }

    function setAutoRegisterAddressMapping(
        bool _enable
    )
        external
        onlyOwner
    {
        _setAutoRegisterAddressMapping(_enable);
    }

    function swapCompressed(
        bytes calldata _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        (
            SwapData memory swapData,
            uint256 cursor
        ) = decodeSwapData(_data, 0);

        return WardenRouterV2.swap(
            IWardenSwap2(swapData.swap),
            _data[cursor:],
            swapData.swap,
            IERC20(swapData.src),
            swapData.srcAmount,
            IERC20(swapData.dest),
            swapData.minDestAmount,
            swapData.receiver,
            swapData.partnerId,
            swapData.metaData
        );
    }

    function swapSplitCompressed(
        bytes calldata _data
    )
        external
        payable
        returns(uint256 _destAmount)
    {
        (
            SwapData memory swapData,
            uint256 cursor
        ) = decodeSwapData(_data, 0);

        address[] memory _deposits = new address[](1);
        uint256[] memory _volumes = new uint256[](0);
        _deposits[0] = swapData.swap;

        return WardenRouterV2.swapSplit(
            IWardenSwap2(swapData.swap),
            _data[cursor:],
            _deposits,
            _volumes,
            IERC20(swapData.src),
            swapData.srcAmount,
            IERC20(swapData.dest),
            swapData.minDestAmount,
            swapData.receiver,
            swapData.partnerId,
            swapData.metaData
        );
    }
}