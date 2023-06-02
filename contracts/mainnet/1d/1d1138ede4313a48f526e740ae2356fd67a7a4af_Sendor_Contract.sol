/**
 *Submitted for verification at Arbiscan on 2023-06-02
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/4_Test.sol


pragma solidity ^0.8.0;




contract Sendor_Contract {
  using SafeMath for uint256;
  using Address for address;

  address private _owner;
  uint256 public _maxLimitPerBatch = 50;
  address[] private _tokenAddresses;
  mapping (address => uint256) private _walletCoinBalances;
  mapping (address => mapping (address => uint256)) private _walletTokenBalances;
  mapping (string => uint256) private _userCoinBalances;
  mapping (string => mapping (address => uint256)) private _userTokenBalances;

  uint256 public _tax = 3;   // 3%
  address public walletRewards = 0x860976A56ad6db6aab289C487d966A7c6873a66A;
  address public walletDevelopmentAndMarketing = 0xdF25947dD50Cd2941cF7D43D3e3405fb17d39264;  
  address public walletPartnerChain = address(0);
  
  modifier onlyOwner() {
    require(msg.sender == _owner, "Only the contract owner can call this function");
    _;
  }

  // Constructor function
  constructor() {
    _owner = msg.sender;
  }

  // If chain partnerned with us, we can give them 1% of every tip made from their chain
  function setWalletForPartnerChain(address wallet) external onlyOwner {
    walletPartnerChain = wallet;
  }

  // Update the max limit of recipients per batch
  function updateMaxLimitPerBatch(uint256 limit) external onlyOwner {
    require(limit > 0, "Invalid limit");
    _maxLimitPerBatch = limit;
  }

  // Move user balance to wallet balance
  function moveUserBalanceToWallet(string calldata user, address wallet) external onlyOwner {
    // Transfer coin if has balance
    if(_userCoinBalances[user] >= 0){
      uint256 balance = _userCoinBalances[user];

      // Subtract to user balance
      _userCoinBalances[user] = _userCoinBalances[user].sub(balance);
      
      // Add to wallet balance
      _walletCoinBalances[wallet] = _walletCoinBalances[wallet].add(balance);
    }

    // Transfer tokens if has balance
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      address token = _tokenAddresses[i];
      if(_userTokenBalances[user][token] >= 0){
        uint256 balance = _userTokenBalances[user][token];

        // Subtract to user balance
        _userTokenBalances[user][token] = _userTokenBalances[user][token].sub(balance);

        // Add to wallet balance
        _walletTokenBalances[wallet][token] = _walletTokenBalances[wallet][token].add(balance);
      }
    }
  }

  // Move wallet balance to a different wallet balance
  function moveWalletBalanceToWallet(address previousWallet, address newWallet) external onlyOwner {
    // Transfer coin if has balance
    if(_walletCoinBalances[previousWallet] >= 0){
      uint256 balance = _walletCoinBalances[previousWallet];

      // Subtract to previous wallet balance
      _walletCoinBalances[previousWallet] = _walletCoinBalances[previousWallet].sub(balance);
      
      // Add to new wallet balance
      _walletCoinBalances[newWallet] = _walletCoinBalances[newWallet].add(balance);
    }

    // Transfer tokens if has balance
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      address token = _tokenAddresses[i];
      if(_walletTokenBalances[previousWallet][token] >= 0){
        uint256 balance = _walletTokenBalances[previousWallet][token];

        // Subtract to previous wallet balance
        _walletTokenBalances[previousWallet][token] = _walletTokenBalances[previousWallet][token].sub(balance);

        // Add to new wallet balance
        _walletTokenBalances[newWallet][token] = _walletTokenBalances[newWallet][token].add(balance);
      }
    }
  }

  // Deposit coins - fallback function
  receive() external payable {
    _walletCoinBalances[msg.sender] = _walletCoinBalances[msg.sender].add(msg.value);
  }

  // Deposit coins
  function depositCoin() external payable {
    _walletCoinBalances[msg.sender] = _walletCoinBalances[msg.sender].add(msg.value);
  }

  // Withdraw coins
  function withdrawCoin(uint256 amount) external {
    require(_walletCoinBalances[msg.sender] >= amount, "Insufficient coin balance");

    _walletCoinBalances[msg.sender] = _walletCoinBalances[msg.sender].sub(amount);
    payable(msg.sender).transfer(amount);
  }

  // Send a coin tip
  function sendCoin(address senderWallet, address[] calldata receiverWallets, string[] calldata receiverUsers, uint256 amount) external onlyOwner {
    require(receiverWallets.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(receiverUsers.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(receiverWallets.length == receiverUsers.length, "Wallets and users should have same length");

    uint256 totalTips = amount.mul(receiverWallets.length);
    require(_walletCoinBalances[senderWallet] >= totalTips, "Insufficient coin balance");
    _walletCoinBalances[senderWallet] = _walletCoinBalances[senderWallet].sub(totalTips);

    uint256 forRewards = 0;
    uint256 forDevelopmentAndMarketing = 0;
    uint256 forPartnerChain = 0;
    for (uint256 i = 0; i < receiverWallets.length; i++) {
      address receiverWallet = receiverWallets[i];
      string memory receiverUser = receiverUsers[i];
      
      uint256 amount100 = amount.div(100);
      uint256 forTax = amount100.mul(_tax);
      uint256 forRecipient = amount.sub(forTax);
      uint256 percent_1 = forTax.div(3);  // 1%
      
      // Tip
      if(receiverWallet != address(0)){
        payable(receiverWallet).transfer(forRecipient); // 97%
      } else{
        _userCoinBalances[receiverUser] = _userCoinBalances[receiverUser].add(forRecipient); // 97%
      }

      // Tax distribution
      if(walletPartnerChain != address(0)){
        forRewards = forRewards.add(percent_1); // 1%
        forDevelopmentAndMarketing = forDevelopmentAndMarketing.add(percent_1); // 1%
        forPartnerChain = forPartnerChain.add(percent_1);  // 1%
      } else{
        forRewards = forRewards.add(percent_1.add(percent_1));  // 2%
        forDevelopmentAndMarketing = forDevelopmentAndMarketing.add(percent_1); // 1%
      }
    }

    payable(walletRewards).transfer(forRewards);
    payable(walletDevelopmentAndMarketing).transfer(forDevelopmentAndMarketing);
    if(forPartnerChain > 0){
      payable(walletPartnerChain).transfer(forPartnerChain); 
    }
  }
  
  // Deposit tokens
  function depositToken(address token, uint256 amount) external {
    IERC20(token).transferFrom(msg.sender, address(this), amount);

    // Check if the token address is already in the list
    bool alreadyOnTheList = false;
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      if (_tokenAddresses[i] == token) {
        alreadyOnTheList = true;
      }
    }
    if(!alreadyOnTheList){
      _tokenAddresses.push(token);
    }

    _walletTokenBalances[msg.sender][token] = _walletTokenBalances[msg.sender][token].add(amount);
  }

  // Withdraw tokens
  function withdrawToken(address token, uint256 amount) external {
    require(_walletTokenBalances[msg.sender][token] >= amount, "Insufficient token balance");

    _walletTokenBalances[msg.sender][token] = _walletTokenBalances[msg.sender][token].sub(amount);
    IERC20(token).transfer(msg.sender, amount);
  }

  // Send a token tip
  function sendToken(address token, address senderWallet, address[] calldata receiverWallets, string[] calldata receiverUsers, uint256 amount) external onlyOwner {
    require(receiverWallets.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(receiverUsers.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(receiverWallets.length == receiverUsers.length, "Wallets and users should have same length");

    IERC20 tipToken = IERC20(token);
    address tokenAddress = address(tipToken);

    uint256 totalTips = amount.mul(receiverWallets.length);
    require(_walletTokenBalances[senderWallet][tokenAddress] >= totalTips, "Insufficient coin balance");
    _walletTokenBalances[senderWallet][tokenAddress] = _walletTokenBalances[senderWallet][tokenAddress].sub(totalTips);

    uint256 forRewards = 0;
    uint256 forDevelopmentAndMarketing = 0;
    uint256 forPartnerChain = 0;
    for (uint256 i = 0; i < receiverWallets.length; i++) {
      address receiverWallet = receiverWallets[i];
      string memory receiverUser = receiverUsers[i];
      
      uint256 amount100 = amount.div(100);
      uint256 forTax = amount100.mul(_tax);
      uint256 forRecipient = amount.sub(forTax);
      uint256 percent_1 = forTax.div(3);  // 1%
      
      // Tip
      if(receiverWallet != address(0)){
        tipToken.transfer(receiverWallet, forRecipient); // 97%
      } else{
        _userTokenBalances[receiverUser][tokenAddress] = _userTokenBalances[receiverUser][tokenAddress].add(forRecipient); // 97%
      }

      // Tax distribution
      if(walletPartnerChain != address(0)){
        forRewards = forRewards.add(percent_1); // 1%
        forDevelopmentAndMarketing = forDevelopmentAndMarketing.add(percent_1); // 1%
        forPartnerChain = forPartnerChain.add(percent_1);  // 1%
      } else{
        forRewards = forRewards.add(percent_1.add(percent_1));  // 2%
        forDevelopmentAndMarketing = forDevelopmentAndMarketing.add(percent_1); // 1%
      }
    }

    tipToken.transfer(walletRewards, forRewards);
    tipToken.transfer(walletDevelopmentAndMarketing, forDevelopmentAndMarketing); 
    if(forPartnerChain > 0){
      tipToken.transfer(walletPartnerChain, forPartnerChain);
    }
  }

  // Distribute rewards
  function distributeRewards(address[] calldata diamondHands, uint256[] calldata rewards) external onlyOwner {
    require(diamondHands.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(rewards.length <= _maxLimitPerBatch, "Exceeded maximum recipients");
    require(diamondHands.length == rewards.length, "DiamondHands and rewards should have same length");

    uint256 rewardsTotal = 0;
    for (uint256 i = 0; i < diamondHands.length; i++) {
      address payable recipient = payable(diamondHands[i]);
      uint256 reward = rewards[i];
      require(reward > 0, "Amount must be greater than zero");
      recipient.transfer(reward);
      rewardsTotal = rewardsTotal.add(reward);
    }

    _walletCoinBalances[walletRewards] = _walletCoinBalances[walletRewards].sub(rewardsTotal);
  }

  // Get coin balance
  function getWalletCoinBalance(address owner) public view returns (uint256) {
    return _walletCoinBalances[owner];
  }

  // Get token balance
  function getWalletTokenBalance(address owner, address token) public view returns (uint256) {
    return _walletTokenBalances[owner][token];
  }

  // Get coin balance of the user
  function getUserCoinBalance(string calldata user) public view returns (uint256) {
    return _userCoinBalances[user];
  }

  // Get token balance of the user
  function getUserTokenBalance(string calldata user, address token) public view returns (uint256) {
    return _userTokenBalances[user][token];
  }

}