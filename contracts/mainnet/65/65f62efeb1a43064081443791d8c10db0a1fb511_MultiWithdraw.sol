/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// SPDX-License-Identifier: MIT
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


contract GovManager is Ownable {
    event GovernorUpdated (
        address indexed oldGovernor,
        address indexed newGovernor
    );

    address public GovernorContract;

    modifier onlyOwnerOrGov() {
        require(
            msg.sender == owner() || msg.sender == GovernorContract,
            "Authorization Error"
        );
        _;
    }

    function setGovernorContract(address _address) external onlyOwnerOrGov {
        address oldGov = GovernorContract;
        GovernorContract = _address;
        emit GovernorUpdated(oldGov, GovernorContract);
    }

    constructor() {
        GovernorContract = address(0);
    }
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


contract MultiManageable is GovManager {
    constructor(address _LockedDealAddress, uint256 _transactionLimit) {
        // isContract function will always return false when used in constructor
        _lockedDealAddress = _LockedDealAddress;
        _setMaxTransactionLimit(_transactionLimit);
    }

    uint256 private _maxTransactionLimit;
    address private _lockedDealAddress;

    event maxTransactionChange(uint256 OldVaule, uint256 NewValue);
    event lockedDealChange(address OldVaule, address NewValue);

    function lockedDealAddress() public view returns (address) {
        return _lockedDealAddress;
    }

    function maxTransactionLimit() public view returns (uint256) {
        return _maxTransactionLimit;
    }

    function setLockedDealAddress(
        address _LockedDealAddress
    ) external onlyOwnerOrGov {
        _setLockDealAddresss(_LockedDealAddress);
    }

    ///@dev The LockedDeal address should be a contract or null address 
    /// Null address is a way to stop contract using.
    function _setLockDealAddresss(address newAddress) internal {
        require(
            _lockedDealAddress != newAddress,
            "Can't set the same LockedDeal address"
        );
        require(
            newAddress == address(0x0) || Address.isContract(newAddress),
            "Invalid contract address LockedDeal or is not null"
        );
        address Old = _lockedDealAddress;
        _lockedDealAddress = newAddress;
        emit lockedDealChange(Old, _lockedDealAddress);
    }

    function setMaxTransactionLimit(uint256 _newLimit) external onlyOwnerOrGov {
        _setMaxTransactionLimit(_newLimit);
    }

    function _setMaxTransactionLimit(uint256 _newLimit) internal {
        uint256 Old = _maxTransactionLimit;
        _maxTransactionLimit = _newLimit;
        emit maxTransactionChange(Old, _maxTransactionLimit);
    }
}


interface ILockedDealV2 {
    function CreateNewPool(
        address _Token, //token to lock address
        uint256 _StartTime, //Until what time the pool will start
        uint256 _CliffTime, //Before CliffTime can't withdraw tokens
        uint256 _FinishTime, //Until what time the pool will end
        uint256 _StartAmount, //Total amount of the tokens to sell in the pool
        address _Owner // Who the tokens belong to
    ) external payable;

    function CreatePoolsWrtTime(
        address _Token,
        uint256[] calldata _StartTime,
        uint256[] calldata _CliffTime,
        uint256[] calldata _FinishTime,
        uint256[] calldata _StartAmount,
        address[] calldata _Owner
    ) external payable;

    function Index() external returns (uint256);

    function GetMyPoolsId(
        address _UserAddress
    ) external view returns (uint256[] memory);

    function GetMyPoolsIdByToken(
        address _UserAddress,
        address[] memory _Tokens
    ) external view returns (uint256[] memory);

    function WithdrawToken(
        uint256 _PoolId
    ) external returns (uint256 withdrawnAmount);

    function SplitPoolAmountFrom(
        uint256 _LDpoolId,
        uint256 _Amount,
        address _Address
    ) external returns(uint256 poolId);

    function Allowance(
        uint256 _poolId,
        address _user
    ) external view returns(uint256 amount);

    function AllPoolz(uint256 _LDpoolId) external view returns (
        uint256 StartTime,
        uint256 CliffTime,
        uint256 FinishTime,
        uint256 StartAmount,
        uint256 DebitedAmount,
        address Owner,
        address Token
    );
}


/// @title contains array utility functions
library Array {
    /// @dev returns a new slice of the array
    function KeepNElementsInArray(uint256[] memory _arr, uint256 _n)
        internal
        pure
        returns (uint256[] memory newArray)
    {
        if (_arr.length == _n) return _arr;
        require(_arr.length > _n, "can't cut more then got");
        newArray = new uint256[](_n);
        for (uint256 i = 0; i < _n; ++i) {
            newArray[i] = _arr[i];
        }
        return newArray;
    }

    function KeepNElementsInArray(address[] memory _arr, uint256 _n)
        internal
        pure
        returns (address[] memory newArray)
    {
        if (_arr.length == _n) return _arr;
        require(_arr.length > _n, "can't cut more then got");
        newArray = new address[](_n);
        for (uint256 i = 0; i < _n; ++i) {
            newArray[i] = _arr[i];
        }
        return newArray;
    }

    /// @return true if the array is ordered
    function isArrayOrdered(uint256[] memory _arr)
        internal
        pure
        returns (bool)
    {
        require(_arr.length > 0, "array should be greater than zero");
        uint256 temp = _arr[0];
        for (uint256 i = 1; i < _arr.length; ++i) {
            if (temp > _arr[i]) {
                return false;
            }
            temp = _arr[i];
        }
        return true;
    }

    /// @return sum of the array elements
    function getArraySum(uint256[] memory _array)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 0;
        for (uint256 i = 0; i < _array.length; ++i) {
            sum = sum + _array[i];
        }
        return sum;
    }

    /// @return true if the element exists in the array
    function isInArray(address[] memory _arr, address _elem)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < _arr.length; ++i) {
            if (_arr[i] == _elem) return true;
        }
        return false;
    }

    function addIfNotExsist(address[] storage _arr, address _elem) internal {
        if (!Array.isInArray(_arr, _elem)) {
            _arr.push(_elem);
        }
    }
}


/// @author The-Poolz contracts team
contract MultiWithdraw is MultiManageable {
    constructor(
        address _LockedDealAddress,
        uint256 _maxTransactionLimit
    ) MultiManageable(_LockedDealAddress, _maxTransactionLimit) {}

    event TokensWithdrawn(
        uint256[] withdrawnPoolIds,
        uint256[] emptyPoolIds,
        uint256 amount
    );

    modifier notZeroAddress(address _LockedDeal) {
        require(
            _LockedDeal != address(0x0),
            "LockedDeal can't be zero address"
        );
        _;
    }

    modifier isBelowLimit(uint256 _num) {
        require(_num <= maxTransactionLimit(), " Invalid array length limit");
        _;
    }

    function MultiWithdrawAllMyDeals()
        external
        notZeroAddress(lockedDealAddress())
    {
        _processTokenWithdrawals(
            ILockedDealV2(lockedDealAddress()).GetMyPoolsId(msg.sender)
        );
    }

    function MultiWithdrawTokens(
        uint256[] calldata _poolIds
    ) external notZeroAddress(lockedDealAddress()) {
        _processTokenWithdrawals(_poolIds);
    }

    function MultiWithdrawByToken(
        address _token
    ) external notZeroAddress(lockedDealAddress()) notZeroAddress(_token) {
        address[] memory tokenElement = new address[](1);
        tokenElement[0] = _token;
        _processTokenWithdrawals(
            ILockedDealV2(lockedDealAddress()).GetMyPoolsIdByToken(
                msg.sender,
                tokenElement
            )
        );
    }

    function _processTokenWithdrawals(
        uint256[] memory _poolIds
    ) internal isBelowLimit(_poolIds.length) {
        uint256 arrLength = _poolIds.length;
        uint256[] memory withdrawnPoolIds = new uint256[](arrLength);
        uint256[] memory emptyPoolIds = new uint256[](arrLength);
        uint256 totalAmount;
        uint256 tempAmount;
        uint256 j = 0;
        uint256 k = 0;
        for (uint256 i = 0; i < arrLength; ++i) {
            tempAmount = ILockedDealV2(lockedDealAddress()).WithdrawToken(
                _poolIds[i]
            );
            if (tempAmount > 0) {
                withdrawnPoolIds[j++] = _poolIds[i];
                totalAmount += tempAmount;
            } else {
                emptyPoolIds[k++] = _poolIds[i];
            }
        }
        emit TokensWithdrawn(
            Array.KeepNElementsInArray(withdrawnPoolIds, j),
            Array.KeepNElementsInArray(emptyPoolIds, k),
            totalAmount
        );
    }
}