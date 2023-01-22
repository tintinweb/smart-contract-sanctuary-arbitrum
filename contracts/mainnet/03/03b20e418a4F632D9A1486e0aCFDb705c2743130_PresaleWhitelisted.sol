// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";


interface IDecimals {
    function decimals() external view returns (uint8);
}

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint );
}

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

contract PresaleWhitelisted {

    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint;
    using SafeERC20 for IERC20;



    /* ========== STRUCTS ========== */

    struct Term {
        uint whitelistedAmount; // how much is a user allowed to buy
        uint claimedAmount; // how much has a user already claimed
        uint boughtAmount; // how much has the user bought in total
        uint boughtAt; // when did the user pay for this
    }

    /* ========== STATE VARIABLES ========== */
    
    address owner; // can set terms
    address newOwner; // push/pull model for changing ownership
    
    IERC20 immutable baseToken; // claim token
    IERC20 immutable principalToken; // payment token

    ITreasury immutable treasury; // mints claim token

    address immutable DAO; // holds non-circulating supply
    
    mapping( address => Term ) public terms; // tracks address info
    
    mapping( address => address ) public walletChange; // facilitates address change

    // vesting details
    uint public vestingStart;
    uint public vestingPeriod;

    // price details
    uint public pricePerBase;
    uint public claimPrincipalPerBase;

    // principal maximum amount
    uint public principalMaximumSpend;
    uint public principalSpent;

    /* ========== CONSTRUCTOR ========== */
    
    constructor( 
        address _baseToken, 
        address _principalToken, 
        address _treasury, 
        address _DAO, 
        uint _vestingStart,
        uint _vestingPeriod,
        uint _pricePerBase,
        uint _claimPrincipalPerBase
    ) {
        owner = msg.sender;

        require( _baseToken != address(0) );
        baseToken = IERC20( _baseToken );

        require( _principalToken != address(0) );
        principalToken = IERC20( _principalToken );

        require( _treasury != address(0) );
        treasury = ITreasury( _treasury );

        require( _DAO != address(0) );
        DAO = _DAO;

        vestingStart = _vestingStart;
        vestingPeriod = _vestingPeriod;

        require (_pricePerBase*1000 >= 10**IDecimals(_principalToken).decimals(), "Price must be at least 0.001");
        pricePerBase = _pricePerBase;

        claimPrincipalPerBase = _claimPrincipalPerBase;
    }


    /* ========== USER FUNCTIONS ========== */
    
    /**
     *  @notice allows wallet to claim baseToken
     *  @param _amount uint
     */
    function claim( uint _amount ) external {
        baseToken.safeTransfer( msg.sender, _claim( _amount ) ); // send claimed to sender
    }

    function buy(uint _baseAmount) external {
        require(pricePerBase > 0, "Price must be set");
        uint _principalAmount = baseToPrincipalWhenBuying(_baseAmount);

        // spending cap for contract
        if (principalMaximumSpend > 0) {
            require(principalMaximumSpend > principalSpent, 'Contract maximum reached');
            uint remainingSpend = principalMaximumSpend - principalSpent;
            if (_principalAmount > remainingSpend) {
                // cap user to not exceed maximum spend
                _principalAmount = remainingSpend;
                _baseAmount = principalToBaseWhenBuying(_principalAmount);
            }
        }
        principalSpent += _principalAmount;

        require( buyableForInPrincipal( msg.sender ) >= _principalAmount, 'Paying for more than whitelisted for' );

        principalToken.safeTransferFrom( msg.sender, address( this ), _principalAmount ); // transfer principalToken payment in

        // calculate how much to keep
        uint retainAmount = baseToPrincipalWhenClaiming(_baseAmount);
        uint daoAmount = _principalAmount.sub(retainAmount);

        Term storage info = terms[ msg.sender ];
        info.boughtAmount = info.boughtAmount.add(_baseAmount);
        info.boughtAt = block.number > vestingStart ? block.number : vestingStart;
        require(info.whitelistedAmount >= info.boughtAmount, "Buying more than whitelisted for");

        // send off the DAO share
        principalToken.transfer(address(DAO), daoAmount);
    }

    /**
     *  @notice logic for claiming baseToken
     *  @param _baseAmount uint
     *  @return ToSend_ uint
     */
    function _claim( uint _baseAmount ) internal returns ( uint ToSend_ ) {
        uint principalAmount = baseToPrincipalWhenClaiming(_baseAmount);
        principalToken.approve( address( treasury ), principalAmount ); // approve and
        ToSend_ = treasury.deposit( principalAmount, address( principalToken ), 0 ); // deposit into treasury, receive baseToken
        require(ToSend_ == _baseAmount, 'ToSend needs to match baseAmount');

        // ensure claim is within bounds
        require( claimableForInBase( msg.sender ) >= _baseAmount, 'Not enough vested' );

        // add amount to tracked balance
        Term storage info = terms[ msg.sender ];
        info.claimedAmount = info.claimedAmount.add(_baseAmount);
    }

    /**
     *  @notice allows address to push terms to new address
     *  @param _newAddress address
     */
    function pushWalletChange( address _newAddress ) external {
        require( terms[ msg.sender ].whitelistedAmount != 0 );
        walletChange[ msg.sender ] = _newAddress;
    }
    
    /**
     *  @notice allows new address to pull terms
     *  @param _oldAddress address
     */
    function pullWalletChange( address _oldAddress ) external {
        require( walletChange[ _oldAddress ] == msg.sender, "wallet did not push" );
        
        walletChange[ _oldAddress ] = address(0);
        terms[ msg.sender ] = terms[ _oldAddress ];
        delete terms[ _oldAddress ];
    }



    /* ========== VIEW FUNCTIONS ========== */

    function claimableForInBase( address _address ) public view returns (uint) {
        Term memory info = terms[ _address ];

        if (block.number < info.boughtAt) {
            return 0; // vesting not yet begun
        }

        if (block.number > info.boughtAt.add(vestingPeriod)) {
            // maximum amount as vesting is done
            return info.boughtAmount.sub(info.claimedAmount);
        }

        // calculate based on vesting
        return info.boughtAmount.mul(uint(block.number).sub(info.boughtAt)).div(vestingPeriod).sub(info.claimedAmount); //.mul(pricePerBase).div(10**IDecimals(address(baseToken)).decimals());
    }
    function claimableForInPrincipal( address _address ) public view returns (uint) {
        return baseToPrincipalWhenClaiming(claimableForInBase(_address));
    }
    function baseToPrincipalWhenClaiming(uint _baseAmount) public view returns (uint) {
        return _baseAmount.mul(claimPrincipalPerBase).div(10**IDecimals(address(baseToken)).decimals());
    }

    function buyableForInBase( address _address ) public view returns (uint) {
        if (pricePerBase == 0) {
            return 0; // nobody can buy anything
        }

        Term memory info = terms[ _address ];

        return info.whitelistedAmount.sub(info.boughtAmount);
    }
    function buyableForInPrincipal( address _address ) public view returns (uint) {
        return baseToPrincipalWhenBuying(buyableForInBase(_address));
    }
    function baseToPrincipalWhenBuying(uint _baseAmount) public view returns (uint) {
        return _baseAmount.mul(pricePerBase).div(10**IDecimals(address(baseToken)).decimals());
    }
    function principalToBaseWhenBuying(uint _principalAmount) public view returns (uint) {
        return _principalAmount.mul(10**IDecimals(address(baseToken)).decimals()).div(pricePerBase);
    }

    /**
     *  @notice view baseToken claimed by address. baseToken decimals (9).
     *  @param _address address
     *  @return uint
     */
    function claimed( address _address ) public view returns ( uint ) {
        return terms[_address].claimedAmount;
    }


    /* ========== OWNER FUNCTIONS ========== */

    /**
     *  @notice set terms for new address
     *  @notice cannot lower for address or exceed maximum total allocation
     *  @param _addresses addresses
     *  @param _whitelistedAmounts uints
     */
    function setTerms(address[] memory _addresses, uint[] memory _whitelistedAmounts ) external {
        require( msg.sender == owner, "Sender is not owner" );
        for (uint i = 0;  i < _addresses.length;  ++i) {
            require( _whitelistedAmounts[i] >= terms[ _addresses[i] ].boughtAmount, "Cannot lower whitelist below bought amount" );

            terms[ _addresses[i] ].whitelistedAmount = _whitelistedAmounts[i];
        }
    }

    function setVesting(uint _vestingPeriod) external {
        require( msg.sender == owner, "Sender is not owner" );
        vestingPeriod = _vestingPeriod;
    }


    function setPrincipalMaximumSpend(uint _principalMaximumSpend) external {
        require( msg.sender == owner, "Sender is not owner" );
        principalMaximumSpend = _principalMaximumSpend;
    }


    function setPricePerBase(uint _pricePerBase) external {
        require( msg.sender == owner, "Sender is not owner" );
        require (_pricePerBase*1000 >= 10**IDecimals(address(principalToken)).decimals() || _pricePerBase == 0, "Price must be at least 0.001");
        pricePerBase = _pricePerBase;
    }

    /**
     *  @notice push ownership of contract
     *  @param _newOwner address
     */
    function pushOwnership( address _newOwner ) external {
        require( msg.sender == owner, "Sender is not owner" );
        require( _newOwner != address(0) );
        newOwner = _newOwner;
    }
    
    /**
     *  @notice pull ownership of contract
     */
    function pullOwnership() external {
        require( msg.sender == newOwner );
        owner = newOwner;
        newOwner = address(0);
    }

    /**
     *  @notice renounce ownership of contract (no owner)
     */
     function renounceOwnership() external {
         require( msg.sender == owner, "Sender is not owner" );
         owner = address(0);
         newOwner = address(0);
     }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}