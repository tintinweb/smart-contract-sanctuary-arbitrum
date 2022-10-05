/**
 *Submitted for verification at Arbiscan on 2022-10-03
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IRouter {
  function addPlugin(address _plugin) external;

  function approvePlugin(address _plugin) external;

  function pluginTransfer(
    address _token,
    address _account,
    address _receiver,
    uint256 _amount
  ) external;

  function pluginIncreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _sizeDelta,
    bool _isLong
  ) external;

  function pluginDecreasePosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver
  ) external returns (uint256);

  function swap(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address _receiver
  ) external;

  function swapTokensToETH(
    address[] memory _path,
    uint256 _amountIn,
    uint256 _minOut,
    address payable _receiver
  ) external;
}

interface IPositionRouter {
  function executeIncreasePositions(
    uint256 _count,
    address payable _executionFeeReceiver
  ) external;

  function executeDecreasePositions(
    uint256 _count,
    address payable _executionFeeReceiver
  ) external;

  function executeDecreasePosition(
    bytes32 key,
    address payable _executionFeeReceiver
  ) external;

  function executeIncreasePosition(
    bytes32 key,
    address payable _executionFeeReceiver
  ) external;

  // AKA open position /  add to position
  function createIncreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _sizeDelta,
    bool _isLong,
    uint256 _acceptablePrice,
    uint256 _executionFee,
    bytes32 _referralCode
  ) external payable;

  // AKA close position /  remove from position
  function createDecreasePosition(
    address[] memory _path,
    address _indexToken,
    uint256 _collateralDelta,
    uint256 _sizeDelta,
    bool _isLong,
    address _receiver,
    uint256 _acceptablePrice,
    uint256 _minOut,
    uint256 _executionFee,
    bool _withdrawETH
  ) external payable;

  function decreasePositionsIndex(address) external view returns (uint256);
  function increasePositionsIndex(address) external view returns (uint256);

  function getRequestKey(address, uint256) external view returns (bytes32);

  function  minExecutionFee() external view returns (uint256);
}

interface IERC20 {

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

}

struct Addresses {
    address gmxVault;
    address gmxRouter;
    address gmxPositionRouter;
    address feeDistributor;
    address governance;
    address positionManagerFactory;
}

interface IDopexPositionManager {
    function enableAndCreateIncreaseOrder(
        enableStrategyParams calldata params,
        address _gmxVault,
        address _gmxRouter,
        address _gmxPositionRouter,
        address _user
    ) external payable;

    function increaseOrder(
        address[] memory path,
        address indexToken,
        uint256 collateralDelta,
        uint256 positionSizeDelta
    ) external payable;

    function decreaseOrder(
        address[] memory path,
        address indexToken,
        address receiver,
        uint256 collateralDelta,
        uint256 positionSizeDelta,
        bool withdrawETH
    ) external payable;

    function release() external;

    error PositionNotReleased();
    error InsufficientExecutionFee();
    error CallerNotStrategyController();
    error AlreadyInitialized();
    error InvalidUserForPositionManager();

    event IncreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );

    event DecreaseOrderCreated(
        address[] _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _acceptablePrice
    );

    event ReferralCodeSet(bytes32 _newReferralCode);
    event Released();
}

struct enableStrategyParams {
    address[] path;
    address indexToken;
    uint256 positionCollateralSize;
    uint256 positionSize;
    uint256 executionFee;
    bytes32 referralCode;
    bool depositUnderlying;
}

struct Tokens {
    address indexToken;
    address collateralToken;
}

struct Insurance {
    // Amount of puts pool collateral accessible
    uint256 collateralAccess;
    // Puts pool strike
    uint256 putStrike;
    // Amount of calls and put options
    uint256 optionsAmount;
    // Epoch of the pool in context of the future position
    uint256 poolsEpoch;
    // Key for accessing collateral from puts pool
    uint256 purchaseId;
    // Expiry = puts pool expiry = calls pool expiry
    uint256 expiry;
    // has user deposited underlying
    bool hasDepositedUnderlying;
    // Whether position has added collateral or not
    bool hasBorrowed;
    // Preference to gmx position persist after expiry
    bool keepCollateral;
}

struct StrategyPosition {
    // Address of the position manager
    address dopexPositionManager;
    // Address of the index token / underlying
    Tokens tokens;
    // Address of the user of the position manager
    address user;
    Insurance insurance;
}


struct TokenStrategyConfig {
    uint256 optionStrikeOffsetPercentage;
    uint256 decreaseThreshold;
    uint256 feeBasisPoints;
    bool isStable;
}

interface IAtlanticPutsPool {
  struct Addresses2 {
    address quoteToken;
    address baseToken;
    address feeDistributor;
    address feeStrategy;
    address optionPricing;
    address priceOracle;
    address volatilityOracle;
  }

  struct VaultState {
    // Settlement price set on expiry
    uint256 settlementPrice;
    // Timestamp at which the epoch expires
    uint256 expiryTime;
    // Start timestamp of the epoch
    uint256 startTime;
    // Whether vault has been bootstrapped
    bool isVaultReady;
    // Whether vault is expired
    bool isVaultExpired;
  }

  struct VaultConfiguration {
    // Weights influencing collateral utilization rate
    uint256 collateralUtilizationWeight;
    // Base funding rate
    uint256 baseFundingRate;
    // Delay tolerance for edge cases
    uint256 expireDelayTolerance;
  }

  struct Checkpoint {
    uint256 startTime;
    uint256 totalLiquidity;
    uint256 totalLiquidityBalance;
    uint256 activeCollateral;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 fundingAccrued;
    uint256 underlyingAccrued;
  }

  struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 expiryDelta;
    uint256 fundingRate;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    address user;
  }

  struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 timestamp;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
  }

  function addresses() external view returns (Addresses2 memory);

  // Deposits collateral as a writer with a specified max strike for the next epoch
  function deposit(uint256 maxStrike, address user)
    external
    payable
    returns (bool);

  // Purchases an atlantic for a specified strike
  function purchase(
    uint256 strike,
    uint256 amount,
    address user
  ) external returns (uint256);

  // Unlocks collateral from an atlantic by depositing underlying. Callable by dopex managed contract integrations.
  function unlockCollateral(uint256, address to) external returns (uint256);

  // Gracefully exercises an atlantic, sends collateral to integrated protocol,
  // underlying to writer and charges an unwind fee as well as remaining funding fees
  // to the option holder/protocol
  function unwind(uint256) external returns (uint256);

  // Re-locks collateral into an atlatic option. Withdraws underlying back to user, sends collateral back
  // from dopex managed contract to option, deducts remainder of funding fees.
  // Handles exceptions where collateral may get stuck due to failures in other protocols.
  function relockCollateral(uint256)
    external
    returns (uint256 collateralCollected);

  function calculatePnl(
    uint256 price,
    uint256 strike,
    uint256 amount
  ) external returns (uint256);

  function calculatePremium(uint256, uint256) external view returns (uint256);

  function calculatePurchaseFees(uint256, uint256)
    external
    view
    returns (uint256);

  function settle(uint256 purchaseId, address receiver)
    external
    returns (uint256 pnl);

  function epochTickSize(uint256 epoch) external view returns (uint256);

  function calculateFundingTillExpiry(uint256 totalCollateral)
    external
    view
    returns (uint256);

  function getRefundOnRelock(uint256 _purchaseId)
    external
    view
    returns (uint256 refund);

  function eligiblePutPurchaseStrike(
    uint256 liquidationPrice,
    uint256 optionStrikeOffset
  ) external pure returns (uint256);

  function checkpointIntervalTime() external view returns (uint256);

  function getEpochHighestMaxStrike(uint256 _epoch)
    external
    view
    returns (uint256 _highestMaxStrike);

  function calculateFunding(uint256 totalCollateral, uint256 epoch)
    external
    view
    returns (uint256 funding);

  function calculateUnwindFees(uint256 underlyingAmount)
    external
    view
    returns (uint256);

  function calculateSettlementFees(
    uint256 settlementPrice,
    uint256 pnl,
    uint256 amount
  ) external view returns (uint256);

  function getUsdPrice() external view returns (uint256);

  function getEpochSettlementPrice(uint256 _epoch)
    external
    view
    returns (uint256 _settlementPrice);

  function currentEpoch() external view returns (uint256);

  function getOptionsPurchase(uint256 _tokenId)
    external
    view
    returns (OptionsPurchase memory);

  function getDepositPosition(uint256 _tokenId)
    external
    view
    returns (DepositPosition memory);

  function depositIdCount() external view returns (uint256);

  function purchaseIdCount() external view returns (uint256);

  function getEpochCheckpoints(uint256, uint256)
    external
    view
    returns (Checkpoint[] memory);

  function epochVaultStates(uint256 _epoch)
    external
    view
    returns (VaultState memory);

  function vaultConfiguration()
    external
    view
    returns (VaultConfiguration memory);

  function getEpochStrikes(uint256 _epoch)
    external
    view
    returns (uint256[] memory _strike_s);

  function getUnwindAmount(uint256 _optionsAmount, uint256 _optionStrike)
    external
    view
    returns (uint256 unwindAmount);

  function strikeMulAmount(uint256 _strike, uint256 _amount)
    external
    view
    returns (uint256);
}


abstract contract ContractWhitelist {
    /// @dev contract => whitelisted or not
    mapping(address => bool) public whitelistedContracts;

    /*==== SETTERS ====*/

    /// @dev add to the contract whitelist
    /// @param _contract the address of the contract to add to the contract whitelist
    function _addToContractWhitelist(address _contract) internal {
        require(isContract(_contract), "Address must be a contract");
        require(
            !whitelistedContracts[_contract],
            "Contract already whitelisted"
        );

        whitelistedContracts[_contract] = true;

        emit AddToContractWhitelist(_contract);
    }

    /// @dev remove from  the contract whitelist
    /// @param _contract the address of the contract to remove from the contract whitelist
    function _removeFromContractWhitelist(address _contract) internal {
        require(whitelistedContracts[_contract], "Contract not whitelisted");

        whitelistedContracts[_contract] = false;

        emit RemoveFromContractWhitelist(_contract);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        // the below condition checks whether the caller is a contract or not
        if (msg.sender != tx.origin)
            require(
                whitelistedContracts[msg.sender],
                "Contract must be whitelisted"
            );
    }

    /*==== VIEWS ====*/

    /// @dev checks for contract or eoa addresses
    /// @param addr the address to check
    /// @return bool whether the passed address is a contract address
    function isContract(address addr) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    /*==== EVENTS ====*/

    event AddToContractWhitelist(address indexed _contract);

    event RemoveFromContractWhitelist(address indexed _contract);
}

abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Internal function to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _whenNotPaused() internal view {
        if (paused()) revert ContractPaused();
    }

    /**
     * @dev Internal function to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _whenPaused() internal view {
        if (!paused()) revert ContractNotPaused();
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual {
        _whenNotPaused();
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual {
        _whenPaused();
        _paused = false;
        emit Unpaused(msg.sender);
    }

    error ContractPaused();
    error ContractNotPaused();
}

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
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
}

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

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

interface IDopexPositionManagerFactory {
  function createPositionmanager() external returns (address positionManager);
}

interface IVault {
  function getFeeBasisPoints(
    address _token,
    uint256 _usdgDelta,
    uint256 _feeBasisPoints,
    uint256 _taxBasisPoints,
    bool _increment
  ) external view returns (uint256);

  function swapFeeBasisPoints() external view returns (uint256);

  function taxBasisPoints() external view returns (uint256);

  function getFundingFee(
    address _token,
    uint256 _size,
    uint256 _entryFundingRate
  ) external view returns (uint256);

  function getMaxPrice(address _token) external view returns (uint256);

  function getMinPrice(address _token) external view returns (uint256);

  function getPosition(
    address _account,
    address _collateralToken,
    address _indexToken,
    bool _isLong
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      bool,
      uint256
    );

  function usdToTokenMin(address _token, uint256 _usdAmount)
    external
    view
    returns (uint256);

  function usdg() external view returns (address);

  function adjustForDecimals(
    uint256 _amount,
    address _tokenDiv,
    address _tokenMul
  ) external view returns (uint256);

  function lastFundingTimes(address) external view returns (uint256);

  function fundingInterval() external view returns (uint256);

  function getNextFundingRate(address _token) external view returns (uint256);

  function cumulativeFundingRates(address _token)
    external
    view
    returns (uint256);

  function tokenToUsdMin(address _token, uint256 _tokenAmount)
    external
    view
    returns (uint256);
}

contract DopexLongPerpStrategyArbitrum is
  Ownable,
  ContractWhitelist,
  ReentrancyGuard,
  Pausable
{
  using SafeERC20 for IERC20;

  uint256 public minimumLeverage; // in 1e30 decimals
  uint256 public maximumLeverage; // in 1e30 decimals
  uint256 public minimumExecutionFee; // in 1e18 decimals
  uint256 public constant FEE_BASIS_DIVISOR = 10000;
  uint256 public strategyPositionFeeBasisPoints;

  Addresses public addresses;

  mapping(address => TokenStrategyConfig) public tokenStrategyConfigs;
  mapping(address => bool) public isKeeper;
  mapping(address => bool) public isValidPositionManager;
  mapping(address => bool) public isValidKeeper;
  mapping(uint256 => bool) public isPositionSettled;
  mapping(address => uint256[]) private userStrategyPositions;
  mapping(bytes32 => address) private atlanticPools;

  StrategyPosition[] public strategyPositions;

  mapping(address => bool) public whitelistedUsers;

  bool public isWhitelistUserMode = true;

  event ManagedPositionIncreased(uint256 _positionIndex);
  event ManagedPositionDecreased(uint256 _positionIndex);
  event ManagedPositionClosed(uint256 _positionIndex);
  event ManagedPositionKeptCollateral(uint256 _positionIndex);
  event TokenConfigurationSet(
    address _tokenAddress,
    uint256 _optionStrikeOffsetPercentage,
    uint256 _decreaseThreshold,
    uint256 _feeBasisPoints,
    bool _isStable
  );
  event LeveragesSet(uint256 _maxLeverage, uint256 _minLeverage);
  event MinimumExecutionFeeSet(uint256 _fees);
  event EmergencyWithdraw(address _sender);
  event AddressesSet(Addresses _addresses);
  event NewManagedPosition(address _managedPositionAddress, uint256 _index);
  event ForceReleasedPosition(address spositionManager);

  error LongPerpStrategyError(uint256 errorCode);

  receive() external payable {}

  constructor(
    Addresses memory _addresses,
    uint256 _minLeverage,
    uint256 _maxLeverage,
    uint256 _minExecutionFee,
    uint256 _strategyPositionFeeBasisPoints
  ) {
    addresses = _addresses;
    minimumLeverage = _minLeverage;
    maximumLeverage = _maxLeverage;
    minimumExecutionFee = _minExecutionFee;
    strategyPositionFeeBasisPoints = _strategyPositionFeeBasisPoints;
  }

  /**
   * @notice Set minimum and max leverage
   * @param  maxLeverage Maxmium leverage multiplier
   * @param  minLeverage Minium leverage multiplier
   * @return success
   */
  function setLeverages(uint256 maxLeverage, uint256 minLeverage)
    external
    onlyOwner
    returns (bool)
  {
    minimumLeverage = minLeverage;
    maximumLeverage = maxLeverage;
    emit LeveragesSet(minimumLeverage, maxLeverage);
    return true;
  }

  /**
   * @notice Set minimum and max leverage
   *@param  _addresses Addresses of contracts to set
   *@return success
   */
  function setAddresses(Addresses calldata _addresses)
    external
    onlyOwner
    returns (bool)
  {
    addresses = _addresses;
    emit AddressesSet(_addresses);
    return true;
  }

  /**
  @notice Set minium execution fee for opening orders of longs
  @param executionFee Amount of fee (1e18 decimals)
  @return success
   */
  function setMinimumExecutionFee(uint256 executionFee)
    external
    onlyOwner
    returns (bool)
  {
    minimumExecutionFee = executionFee;
    emit MinimumExecutionFeeSet(executionFee);
    return true;
  }

  /** @notice Creates a long position, collected underlying / atlantic call options as collateral.
   *          Purchases required amount of put options and call options if underlying is not
   *         submitted as collateral
   * @param params                 Parameters required for using the strategy and opening a long position
   * @param keepCollateralOnExpiry Whether to keep collateral if puts are ITM, otherwise closes position
   * @param expiry                 Timestamp of expiry of options in context
   */
  function useStrategyAndOpenLongPosition(
    enableStrategyParams memory params,
    bool keepCollateralOnExpiry,
    uint256 expiry
  ) public payable whitelistCheck nonReentrant {
    _whenNotPaused();
    _isEligibleSender();
    // Tokens configuratinos must be set. This way un-whitelisted tokens are avoided
    _validate(
      tokenStrategyConfigs[params.path[params.path.length - 1]]
        .optionStrikeOffsetPercentage != 0,
      21
    );
    // Fetch a AP pool depending on given expiry
    IAtlanticPutsPool putsPool = _getAtlanticPutsPool(
      params.indexToken,
      expiry
    );

    _validate(address(putsPool) != address(0), 2);
    _validate(params.indexToken == params.path[params.path.length - 1], 26);
    if (keepCollateralOnExpiry) {
      _validate(params.depositUnderlying, 16);
    }

    StrategyPosition memory strategyPosition = StrategyPosition(
      // position manager
      address(0),
      Tokens( // Index token
        params.indexToken,
        // collateral token
        putsPool.addresses().quoteToken
      ),
      // user
      msg.sender,
      Insurance(
        // collateralAccess
        0,
        // Put option strike
        0,
        // Put options balance
        0,
        // Puts pool epoch
        putsPool.currentEpoch(),
        // Puts pool collateral index
        0,
        expiry,
        false,
        // Has borrowed
        false,
        // To keep collateral or not when keepers settle the position before expiry
        keepCollateralOnExpiry
      )
    );

    // Purchase put options and opens a long position
    _enableStrategy(
      params,
      strategyPosition.tokens.collateralToken,
      putsPool,
      strategyPosition
    );

    // Collateral added to a position can only be kept underlying is submitted as collateral
    if (params.depositUnderlying) {
      IERC20(params.indexToken).safeTransferFrom(
        msg.sender,
        address(this),
        strategyPosition.insurance.optionsAmount +
          putsPool.calculateUnwindFees(strategyPosition.insurance.optionsAmount)
      );
      strategyPosition.insurance.hasDepositedUnderlying = true;
    }

    // Save user's position manager
    userStrategyPositions[msg.sender].push(strategyPositions.length);

    // Save position
    strategyPositions.push(strategyPosition);

    emit NewManagedPosition(
      strategyPosition.dopexPositionManager,
      strategyPositions.length
    );
  }

  /**
   * @notice Increase position balance of a managed position
   * @param StrategyPositionKey key in strategyPositionsManagers mapping
   */
  function increaseManagedPosition(uint256 StrategyPositionKey)
    public
    payable
    nonReentrant
  {
    _whenNotPaused();
    _validate(!isPositionSettled[StrategyPositionKey], 9);
    StrategyPosition memory _position = strategyPositions[StrategyPositionKey];

    // Posiiton must have added collateral
    _validate(_position.insurance.hasBorrowed == false, 17);
    _validate(_position.user != address(0), 14);

    // Atlantic pools instance
    IAtlanticPutsPool putsPool = _getAtlanticPutsPool(
      _position.tokens.indexToken,
      _position.insurance.expiry
    );

    // Spot must be > strike + threshold
    // _validate(
    //   isWithinThreshold(
    //     putsPool.getUsdPrice(),
    //     _position.insurance.putStrike,
    //     _position.tokens.indexToken,
    //     true
    //   ),
    //   0
    // );

    // Set hasBorrowed of the postion to true
    strategyPositions[StrategyPositionKey].insurance.hasBorrowed = true;

    // unlock collateral and send to position manager
    uint256 collateralDelta = putsPool.unlockCollateral(
      _position.insurance.purchaseId,
      address(this)
    );

    IERC20(_position.tokens.collateralToken).safeTransfer(
      _position.dopexPositionManager,
      collateralDelta
    );

    // Create increase order
    IDopexPositionManager(_position.dopexPositionManager).increaseOrder{
      value: minimumExecutionFee
    }(
      // swap path
      _getPath(_position.tokens.collateralToken, _position.tokens.indexToken),
      // index Token
      _position.tokens.indexToken,
      // Collaterel delta
      collateralDelta,
      // size delta
      0
    );

    // Execute order
    _executeOrder(_position.dopexPositionManager, true, payable(msg.sender));
  }

  /**
   * @notice decrease position balance of a managed position
   * @param StrategyPositionKey key in strategyPositionsManagers mapping
   */
  function decreaseManagedPosition(uint256 StrategyPositionKey)
    public
    payable
    nonReentrant
  {
    _whenNotPaused();
    (
      IAtlanticPutsPool pool,
      StrategyPosition memory _position
    ) = _getPositionAndPool(StrategyPositionKey);

    _validate(!isPositionSettled[StrategyPositionKey], 9);
    _validate(_position.insurance.hasBorrowed == true, 18);
    _validate(_position.user != address(0), 14);

    strategyPositions[StrategyPositionKey].insurance.hasBorrowed = false;

    // _validate(
    //   isWithinThreshold(
    //     pool.getUsdPrice(),
    //     _position.insurance.putStrike,
    //     _position.tokens.indexToken,
    //     false
    //   ),
    //   1
    // );

    _decreaseManagedPosition(_position, pool);
  }

  /**
   * @dev Exiss strategy. unwinds underlying if puts are ITM, settles calls if ITM, else releases position
   * @param index Index in strategyPositions array
   */
  function exitStrategyAndLongPosition(uint256 index)
    external
    payable
    nonReentrant
  {
    _whenNotPaused();
    _validate(!isPositionSettled[index], 9);

    (
      IAtlanticPutsPool putsPool,
      StrategyPosition memory position
    ) = _getPositionAndPool(index);

    // Set position closed
    isPositionSettled[index] = true;

    // Release position
    _releasePosition(position.dopexPositionManager);

    // Delete position
    delete strategyPositions[index];

    // Check if position has already been closed
    _validate(position.user != address(0), 14);

    // Checks if position user is caller or a keeper
    if (position.user != msg.sender) {
      _validate(isValidKeeper[msg.sender], 13);
      _validate(position.insurance.expiry - 1 hours <= block.timestamp, 20);
    }

    // current price in 1e8 decimals (same as strike)
    uint256 currentPrice = putsPool.getUsdPrice();

    address currentToken;

    // Get path of exiting position
    address[] memory path = _getSwapPathOnOptionsSettlement(
      position.tokens,
      currentPrice < position.insurance.putStrike
    );

    currentToken = path[path.length - 1];

    uint256 toUser = IERC20(currentToken).balanceOf(address(this));

    // Close position and receive margin + pnl
    _closePosition(position.dopexPositionManager, path);

    toUser = IERC20(currentToken).balanceOf(address(this)) - toUser;

    uint256 toPutsPool;

    if (position.insurance.hasBorrowed) {
      // Cash settle case
      if (currentPrice > position.insurance.putStrike) {
        toPutsPool =
          position.insurance.collateralAccess -
          putsPool.getRefundOnRelock(position.insurance.purchaseId);
        IERC20(currentToken).safeTransfer(address(putsPool), toPutsPool);
        putsPool.relockCollateral(position.insurance.purchaseId);

        // Return underlying to user
        if (position.insurance.hasDepositedUnderlying) {
          IERC20(position.tokens.indexToken).safeTransfer(
            position.user,
            position.insurance.optionsAmount +
              putsPool.calculateUnwindFees(position.insurance.optionsAmount)
          );
        }
      }
      // ASset settle case
      else {
        toPutsPool =
          position.insurance.optionsAmount +
          putsPool.calculateUnwindFees(position.insurance.optionsAmount);
        IERC20(currentToken).safeTransfer(address(putsPool), toPutsPool);
        putsPool.unwind(position.insurance.purchaseId);
      }
    } else {
      // Return collateral to the user
      if (position.insurance.hasDepositedUnderlying) {
        IERC20(position.tokens.indexToken).safeTransfer(
          position.user,
          position.insurance.optionsAmount +
            putsPool.calculateUnwindFees(position.insurance.optionsAmount)
        );
      }
    }

    toUser -= toPutsPool;

    // Transfer remaining
    if (toUser > 0) {
      uint256 fees = toUser -
        ((toUser *
          (FEE_BASIS_DIVISOR -
            tokenStrategyConfigs[currentToken].feeBasisPoints)) /
          FEE_BASIS_DIVISOR);
      IERC20(currentToken).safeTransfer(position.user, toUser - fees);
      IERC20(currentToken).safeTransfer(addresses.feeDistributor, fees);
    }
  }

  /**
   * @dev Keep borrowed collateral and release gmx position
   * @param index Index in strategy positions index
   */
  function keepCollateral(uint256 index) external payable nonReentrant {
    _whenNotPaused();
    (
      IAtlanticPutsPool putsPool,
      StrategyPosition memory position
    ) = _getPositionAndPool(index);

    // Checks if position user is caller or a keeper
    if (position.user != msg.sender) {
      _validate(isValidKeeper[msg.sender], 13);
      _validate(position.insurance.expiry - 1 hours <= block.timestamp, 20);
    }

    _validate(!isPositionSettled[index], 9);
    _validate(position.insurance.hasDepositedUnderlying, 12);
    _validate(position.user != address(0), 14);
    _validate(position.insurance.hasBorrowed, 11);

    if (putsPool.getUsdPrice() > position.insurance.putStrike) {
      uint256 refund = putsPool.getRefundOnRelock(
        position.insurance.purchaseId
      );

      uint256 toUser = IERC20(position.tokens.collateralToken).balanceOf(
        (address(this))
      );

      uint256 collateralTokenReceived = _swap(
        _getPath(position.tokens.indexToken, position.tokens.collateralToken),
        position.insurance.optionsAmount,
        address(this)
      );

      (uint256 size, , uint256 entryFundingRate) = _getPosition(
        position.tokens.indexToken,
        position.dopexPositionManager
      );

      uint256 fundingFee = _getPositionFundingFee(
        position.tokens.indexToken,
        position.tokens.collateralToken,
        size,
        entryFundingRate
      );

      if (position.insurance.collateralAccess > collateralTokenReceived) {
        (uint256 amountInWithFee, ) = _getAmountIn(
          ((position.insurance.collateralAccess - collateralTokenReceived) +
            fundingFee) - refund,
          position.tokens.collateralToken,
          position.tokens.indexToken
        );

        _decreaseOrder(
          position.dopexPositionManager,
          _getPath(position.tokens.indexToken, position.tokens.collateralToken),
          (amountInWithFee *
            IVault(addresses.gmxVault).getMinPrice(
              position.tokens.indexToken
            )) / 1e18,
          0,
          address(this)
        );

        _executeOrder(
          position.dopexPositionManager,
          false,
          payable(msg.sender)
        );
      } else {
        payable(msg.sender).transfer(msg.value);
      }

      IERC20(position.tokens.collateralToken).safeTransfer(
        address(putsPool),
        position.insurance.collateralAccess - refund
      );

      putsPool.relockCollateral(position.insurance.purchaseId);

      IERC20(position.tokens.indexToken).safeTransfer(
        addresses.feeDistributor,
        putsPool.calculateUnwindFees(position.insurance.optionsAmount)
      );

      toUser =
        IERC20(position.tokens.collateralToken).balanceOf((address(this))) -
        toUser;

      IERC20(position.tokens.collateralToken).safeTransfer(
        position.user,
        toUser
      );
    } else {
      // unwind
      IERC20(position.tokens.indexToken).safeTransfer(
        address(putsPool),
        putsPool.getUnwindAmount(
          position.insurance.optionsAmount,
          position.insurance.putStrike
        )
      );

      IERC20(position.tokens.indexToken).safeTransfer(
        addresses.feeDistributor,
        putsPool.calculateUnwindFees(position.insurance.optionsAmount)
      );

      putsPool.unwind(position.insurance.purchaseId);
    }

    _releasePosition(position.dopexPositionManager);

    isPositionSettled[index] = true;
    delete strategyPositions[index];
  }

  function exitStrategyAndKeepLongPosition(uint256 index)
    external
    payable
    nonReentrant
  {
    _whenNotPaused();
    _validate(!isPositionSettled[index], 9);

    (
      IAtlanticPutsPool putsPool,
      StrategyPosition memory position
    ) = _getPositionAndPool(index);

    // Checks if position user is caller or a keeper
    if (position.user != msg.sender) {
      _validate(isValidKeeper[msg.sender], 13);
      _validate(position.insurance.expiry - 1 hours <= block.timestamp, 20);
    }

    _validate(position.user != address(0), 14);
    _validate(putsPool.getUsdPrice() > position.insurance.putStrike, 10);

    if (position.insurance.hasBorrowed) {
      _decreaseManagedPosition(position, putsPool);
    }

    if (position.insurance.hasDepositedUnderlying) {
      IERC20(position.tokens.indexToken).safeTransfer(
        position.user,
        position.insurance.optionsAmount +
          putsPool.calculateUnwindFees(position.insurance.optionsAmount)
      );
    }

    _releasePosition(position.dopexPositionManager);
    isPositionSettled[index] = true;
    delete strategyPositions[index];
  }

  /**
   * @notice Remove borrowed collateral from position and relock it back to puts pool
   * @param _position Strategy position to decrease
   * @param pool      Atlantic puts pool instance
   */
  function _decreaseManagedPosition(
    StrategyPosition memory _position,
    IAtlanticPutsPool pool
  ) private {
    // Refund any extra funding
    uint256 toRelock = _position.insurance.collateralAccess;
    uint256 fundingFee;

    toRelock -= pool.getRefundOnRelock(_position.insurance.purchaseId);
    (uint256 size, , uint256 entryFundingRate) = _getPosition(
      _position.tokens.indexToken,
      _position.dopexPositionManager
    );

    fundingFee = _getPositionFundingFee(
      _position.tokens.indexToken,
      _position.tokens.collateralToken,
      size,
      entryFundingRate
    );

    (uint256 amountInWithFee, ) = _getAmountIn(
      toRelock + fundingFee,
      _position.tokens.collateralToken,
      _position.tokens.indexToken
    );

    uint256 tokensReceived = IERC20(_position.tokens.collateralToken).balanceOf(
      address(this)
    );

    _decreaseOrder(
      _position.dopexPositionManager,
      _getPath(_position.tokens.indexToken, _position.tokens.collateralToken),
      (amountInWithFee *
        IVault(addresses.gmxVault).getMinPrice(_position.tokens.indexToken)) /
        1e18,
      0,
      address(this)
    );

    _executeOrder(_position.dopexPositionManager, false, payable(msg.sender));

    tokensReceived =
      IERC20(_position.tokens.collateralToken).balanceOf(address(this)) -
      tokensReceived;

    IERC20(_position.tokens.collateralToken).safeTransfer(
      address(pool),
      toRelock
    );

    IERC20(_position.tokens.collateralToken).safeTransfer(
      addresses.feeDistributor,
      tokensReceived - toRelock
    );

    // relock collateral
    pool.relockCollateral(_position.insurance.purchaseId);
  }

  /// @dev Release position allowing user to manage it post options expiry
  function _releasePosition(address positionManager) private {
    IDopexPositionManager(positionManager).release();
  }

  /// @dev Checks if spot price is within threshold before increasing/decreasing
  function isWithinThreshold(
    uint256 currentPrice,
    uint256 strike,
    address indexToken,
    bool isIncrease
  ) public view returns (bool) {
    uint256 withThreshold = ((strike *
      tokenStrategyConfigs[indexToken].decreaseThreshold) / 1e30) + strike;

    /** @dev Increase position if put strike > current price 
             decrease if current price > putStrike + threshod
     */
    return isIncrease ? currentPrice < strike : currentPrice > withThreshold;
  }

  /**
   * @dev Create derease position order
   * @param managedPosition address of the dopex managed position
   * @param path            Path to specify tokens to receive in
   * @param collateralDelta Change in collateral size
   * @param sizeDelta       Change in position size
   * @param receiver        Address of the receiver once order is executed
   */
  function _decreaseOrder(
    address managedPosition,
    address[] memory path,
    uint256 collateralDelta,
    uint256 sizeDelta,
    address receiver
  ) private {
    IDopexPositionManager(managedPosition).decreaseOrder{
      value: minimumExecutionFee
    }(path, path[0], receiver, collateralDelta, sizeDelta, false);
  }

  /**
   * @notice Close future position
   * @param managedPosition address of the managed position
   * @param path            Swap path
   */
  function _closePosition(address managedPosition, address[] memory path)
    private
  {
    (uint256 size, , ) = _getPosition(path[0], managedPosition);
    _decreaseOrder(managedPosition, path, 0, size, address(this));
    _executeOrder(managedPosition, false, payable(msg.sender));
  }

  /// @dev Execute pending increase / decrease order
  function _executeOrder(
    address positionOwner,
    bool isIncrease,
    address payable receiver
  ) private {
    uint256 index;
    bytes32 key;
    IPositionRouter positionRouter = IPositionRouter(
      addresses.gmxPositionRouter
    );

    if (isIncrease) {
      index = positionRouter.increasePositionsIndex(positionOwner);
      key = positionRouter.getRequestKey(positionOwner, index);
      positionRouter.executeIncreasePosition(key, receiver);
    } else {
      index = positionRouter.decreasePositionsIndex(positionOwner);
      key = positionRouter.getRequestKey(positionOwner, index);
      positionRouter.executeDecreasePosition(key, receiver);
    }
  }

  /**
    @notice Set atlantic pool info
    @param underlying  Base token / underlying of the atlantic pool
    @param isPut       Whether the pool is of put type or call type
    @param expiry      unix timestamp of expiry of the atlantic pool
    @param poolAddress Address of the atlantic pool
    @return success
   */
  function setAtlanticPools(
    address underlying,
    bool isPut,
    uint256 expiry,
    address poolAddress
  ) external onlyOwner returns (bool) {
    _validate(expiry > 1 days / 2, 19);
    _validate(underlying != address(0) && poolAddress != address(0), 15);
    bytes32 key = getPoolKey(underlying, isPut, expiry);
    atlanticPools[key] = poolAddress;
    return true;
  }

  /**
    @notice Helper function that creates increase order / long order
            and executes it. purchase of put options takes place here  
   */
  function _enableStrategy(
    enableStrategyParams memory params,
    address quoteToken,
    IAtlanticPutsPool putsPool,
    StrategyPosition memory strategyPosition
  ) private {
    strategyPosition.dopexPositionManager = IDopexPositionManagerFactory(
      addresses.positionManagerFactory
    ).createPositionmanager();

    IERC20(params.path[0]).safeTransferFrom(
      msg.sender,
      addresses.feeDistributor,
      getStrategyPositionFee(params.positionSize, params.path[0])
    );

    IERC20(params.path[0]).safeTransferFrom(
      msg.sender,
      strategyPosition.dopexPositionManager,
      params.positionCollateralSize
    );

    // create long position
    IDopexPositionManager(strategyPosition.dopexPositionManager)
      .enableAndCreateIncreaseOrder{ value: minimumExecutionFee }(
      params,
      addresses.gmxVault,
      addresses.gmxRouter,
      addresses.gmxPositionRouter,
      msg.sender
    );

    _executeOrder(
      strategyPosition.dopexPositionManager,
      true,
      payable(msg.sender)
    );

    (uint256 size, uint256 collateral, ) = _getPosition(
      params.indexToken,
      strategyPosition.dopexPositionManager
    );

    uint256 leverage = (size * 1e30) / collateral;

    _validate(minimumLeverage != 0 || maximumLeverage != 0, 23);

    // Must be above or equal to min leverage
    _validate(leverage >= minimumLeverage, 4);
    // Must be below or equal to max leverage
    _validate(leverage <= maximumLeverage, 5);

    //   Collateral required to add to position on increase
    strategyPosition.insurance.collateralAccess = getRequiredCollateralAccess(
      collateral,
      leverage
    );

    // strike of the put option to purchase
    strategyPosition.insurance.putStrike =
      putsPool.eligiblePutPurchaseStrike(
        _getLiquidationPrice((putsPool.getUsdPrice() * 1e22), leverage),
        tokenStrategyConfigs[strategyPosition.tokens.indexToken]
          .optionStrikeOffsetPercentage
      ) /
      1e22;

    // Required Put options to buy
    strategyPosition.insurance.optionsAmount =
      (strategyPosition.insurance.collateralAccess * 1e20) /
      strategyPosition.insurance.putStrike;

    // Premium for put options
    uint256 premiumForPuts = putsPool.calculatePremium(
      strategyPosition.insurance.putStrike,
      strategyPosition.insurance.optionsAmount
    ) +
      putsPool.calculatePurchaseFees(
        strategyPosition.insurance.putStrike,
        strategyPosition.insurance.optionsAmount
      );

    // Receive premium
    IERC20(quoteToken).safeTransferFrom(
      msg.sender,
      address(putsPool),
      premiumForPuts
    );

    // Purchase put options
    strategyPosition.insurance.purchaseId = putsPool.purchase(
      strategyPosition.insurance.putStrike,
      strategyPosition.insurance.optionsAmount,
      address(this)
    );
  }

  /**
    @notice get the atlantic pools and position details in context
    @param  index     Index of position in strategyPositions[]
    @return putsPool  Instance of the atlantic puts pool in context
    @return position  strategy position in context
   */
  function _getPositionAndPool(uint256 index)
    private
    view
    returns (IAtlanticPutsPool putsPool, StrategyPosition memory position)
  {
    position = strategyPositions[index];
    putsPool = _getAtlanticPutsPool(
      position.tokens.indexToken,
      position.insurance.expiry
    );
  }

  /**
    @notice Helper function to view swap path required
            for closing the position. resulting path depends
            on if the put option is ITM or not & whether
            the collateral user provided is an option token or not
    @param tokens             tokens in context
    @param isPutsITM          Whether the put option is ITM or not
    @return path Swap path 
   */
  function _getSwapPathOnOptionsSettlement(Tokens memory tokens, bool isPutsITM)
    private
    pure
    returns (address[] memory path)
  {
    if (isPutsITM) {
      path = _getSingularPath(tokens.indexToken);
    } else {
      path = _getPath(tokens.indexToken, tokens.collateralToken);
    }
  }

  /**
   * @notice Returns all strategy positions
   * @return result ALl strategy positions created so far
   */
  function getAllStrategyPositions()
    external
    view
    returns (StrategyPosition[] memory result)
  {
    result = new StrategyPosition[](strategyPositions.length);
    result = strategyPositions;
  }

  /// @notice Sets positions keeper
  function setPositionKeeper(address keeper, bool asKeeper) external onlyOwner {
    _validate(keeper != address(0), 15);
    isValidKeeper[keeper] = asKeeper;
  }

  /**
   * @notice Gets the address of the atlantic pool based parameter specifications
   * @param  underlying Underlying token of the atlantic pool
   * @param  expiry     Type of expiry from enum Expiry
   * @return pool       of the atlantic pool
   */
  function _getAtlanticPutsPool(address underlying, uint256 expiry)
    private
    view
    returns (IAtlanticPutsPool)
  {
    return
      IAtlanticPutsPool(atlanticPools[getPoolKey(underlying, true, expiry)]);
  }

  /**
   * @notice Gets bytes32 pool key in the atlanticPools mapping
   * @return poolKey
   */
  function getPoolKey(
    address underlying,
    bool isPut,
    uint256 expiry
  ) private pure returns (bytes32) {
    return keccak256(abi.encodePacked(underlying, isPut, expiry));
  }

  function getRequiredCollateralAccess(uint256 collateral, uint256 leverage)
    public
    pure
    returns (uint256)
  {
    return (collateral * (leverage - 1e30)) / 1e54;
  }

  /**
   * @dev Calculate liquidation price
   * @param markPrice Mark price of the underlying
   * @param leverage  Leverage multiplier
   */
  function _getLiquidationPrice(uint256 markPrice, uint256 leverage)
    private
    pure
    returns (uint256)
  {
    return markPrice - ((markPrice * 1e30) / leverage);
  }

  function _validate(bool requiredCondition, uint256 errorCode) private pure {
    if (!requiredCondition) revert LongPerpStrategyError(errorCode);
  }

  /// @dev Gets single length array of a token
  function _getSingularPath(address token)
    private
    pure
    returns (address[] memory path)
  {
    path = new address[](1);
    path[0] = token;
  }

  function _getPositionFundingFee(
    address _indexToken,
    address _collateralToken,
    
    uint256 _size,
    uint256 _entryFundingRate
  ) private view returns (uint256 fundingFee) {
    IVault vault = IVault(addresses.gmxVault);

    uint256 currentCummulativeFundingRate = vault.cumulativeFundingRates(
      _indexToken
    ) + vault.getNextFundingRate(_indexToken);
    if (currentCummulativeFundingRate != 0) {
      return
        vault.usdToTokenMin(
          _collateralToken,
          (_size * (currentCummulativeFundingRate - _entryFundingRate)) /
            1000000
        );
    }
  }

  /**
   * @notice Get variables required by strategy contract with regards to the position
   * @param  indexToken       Address of the index token of the position
   * @param  positionOwner    Address of the dopex position manager contract
   * @return size             Position size in 1e30 decimals USD value
   * @return collateral       Current collateral in 1e30 decimals USD value
   * @return entryFundingRate Funding rate stored when position was opened
   */
  function _getPosition(address indexToken, address positionOwner)
    private
    view
    returns (
      uint256 size,
      uint256 collateral,
      uint256 entryFundingRate
    )
  {
    (size, collateral, , entryFundingRate, , , , ) = IVault(addresses.gmxVault)
      .getPosition(positionOwner, indexToken, indexToken, true);
  }

  /**
    @notice Set configuration for a token. also acts as a whitelisting feature
    @param _tokenAddress           Address of the token
    @param _strikeOffsetPercentage Amount% to add over the liquidaition price
    @param _decreaseThreshold      % away from strike before removing collateral
    @param _feeBasisPoints         fee basis points
   */
  function setTokenConfiguration(
    address _tokenAddress,
    uint256 _strikeOffsetPercentage,
    uint256 _decreaseThreshold,
    uint256 _feeBasisPoints,
    bool _isStable
  ) external onlyOwner {
    tokenStrategyConfigs[_tokenAddress] = TokenStrategyConfig(
      _strikeOffsetPercentage,
      _decreaseThreshold,
      _feeBasisPoints,
      _isStable
    );
    emit TokenConfigurationSet(
      _tokenAddress,
      _strikeOffsetPercentage,
      _decreaseThreshold,
      _feeBasisPoints,
      _isStable
    );
  }

  /// @return path Array of two token as swap path
  function _getPath(address tokenA, address tokenB)
    private
    pure
    returns (address[] memory path)
  {
    path = new address[](2);
    path[0] = tokenA;
    path[1] = tokenB;
  }

  /**
   * @notice Add a contract to the whitelist
   * @dev    Can only be called by the owner
   * @param _contract Address of the contract that needs to be added to the whitelist
   */
  function addToContractWhitelist(address _contract) external onlyOwner {
    _addToContractWhitelist(_contract);
  }

  function _swap(
    address[] memory _path,
    uint256 _amountIn,
    address _receiver
  ) private returns (uint256 _received) {
    IERC20(_path[0]).approve(addresses.gmxRouter, _amountIn);

    _received = IERC20(_path[_path.length - 1]).balanceOf(_receiver);

    IRouter(addresses.gmxRouter).swap(_path, _amountIn, 0, _receiver);

    _received =
      IERC20(_path[_path.length - 1]).balanceOf(_receiver) -
      _received;
  }

  /**
   * @param _positionSize      Size of the position in 1e30 decimals
   * @param _collateralToken   Address of the token used as collateral
   */
  function getStrategyPositionFee(
    uint256 _positionSize,
    address _collateralToken
  ) public view returns (uint256) {
    IVault vault = IVault(addresses.gmxVault);
    uint256 _30DecimalusdToToken = vault.usdToTokenMin(
      _collateralToken,
      _positionSize
    );
    return
      _30DecimalusdToToken -
      (_30DecimalusdToToken *
        (FEE_BASIS_DIVISOR - strategyPositionFeeBasisPoints)) /
      FEE_BASIS_DIVISOR;
  }

  /**
   * @notice Get amount to give in required for expecting a certain amount after swapping
   * @param _amountOut Expected amount out of token out
   * @param _tokenOut  Address of the token to swap to
   * @param _tokenIn   Address of the token to swap from
   */
  function _getAmountIn(
    uint256 _amountOut,
    address _tokenOut,
    address _tokenIn
  ) private view returns (uint256 _amountIn, uint256 fees) {
    IVault vault = IVault(addresses.gmxVault);
    uint256 amountIn = (_amountOut * vault.getMaxPrice(_tokenOut)) /
      vault.getMinPrice(_tokenIn);
    uint256 usdgAmount = (amountIn * vault.getMaxPrice(_tokenOut)) / 1e30;
    usdgAmount = vault.adjustForDecimals(usdgAmount, _tokenIn, vault.usdg());
    uint256 feeBps = _getSwapFeeBasisPoints(
      vault,
      usdgAmount,
      _tokenIn,
      _tokenOut
    ) + tokenStrategyConfigs[_tokenIn].feeBasisPoints;
    uint256 amountInWithoutFees = vault.adjustForDecimals(
      amountIn,
      _tokenOut,
      _tokenIn
    );
    uint256 amountInWithFees = (amountIn * FEE_BASIS_DIVISOR) /
      (FEE_BASIS_DIVISOR - feeBps);
    _amountIn = vault.adjustForDecimals(amountInWithFees, _tokenOut, _tokenIn);
    fees = _amountIn - amountInWithoutFees;
  }

  function _getSwapFeeBasisPoints(
    IVault vault,
    uint256 _usdgAmount,
    address _tokenIn,
    address _tokenOut
  ) private view returns (uint256 feeBasisPoints) {
    uint256 baseBps = vault.swapFeeBasisPoints(); // swapFeeBasisPoints
    uint256 taxBps = vault.taxBasisPoints(); // taxBasisPoints
    uint256 feesBasisPoints0 = vault.getFeeBasisPoints(
      _tokenIn,
      _usdgAmount,
      baseBps,
      taxBps,
      true
    );
    uint256 feesBasisPoints1 = vault.getFeeBasisPoints(
      _tokenOut,
      _usdgAmount,
      baseBps,
      taxBps,
      false
    );
    // use the higher of the two fee basis points
    feeBasisPoints = feesBasisPoints0 > feesBasisPoints1
      ? feesBasisPoints0
      : feesBasisPoints1;
  }

  function forceRelease(address _positionManager) external onlyOwner {
    _releasePosition(_positionManager);
    emit ForceReleasedPosition(_positionManager);
  }

  function getUserStrategyPositionKeys(address _user)
    external
    view
    returns (uint256[] memory _keys)
  {
    _keys = new uint256[](userStrategyPositions[_user].length);
    _keys = userStrategyPositions[_user];
  }

  /** @notice Pauses the vault for emergency cases
   * @dev    Can only be called by DEFAULT_ADMIN_ROLE
   * @return Whether it was successfully paused
   */
  function pause() external onlyOwner returns (bool) {
    _pause();
    return true;
  }

  /** @notice Unpauses the vault
   *  @dev    Can only be called by DEFAULT_ADMIN_ROLE
   *  @return success it was successfully unpaused
   */
  function unpause() external onlyOwner returns (bool) {
    _unpause();
    return true;
  }

  /// @notice Transfers all funds to msg.sender
  /// @dev Can only be called by DEFAULT_ADMIN_ROLE
  /// @param tokens The list of erc20 tokens to withdraw
  /// @param transferNative Whether should transfer the native currency
  function emergencyWithdraw(address[] calldata tokens, bool transferNative)
    external
    onlyOwner
    returns (bool)
  {
    _whenPaused();
    if (transferNative) payable(msg.sender).transfer(address(this).balance);

    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20 token = IERC20(tokens[i]);
      token.safeTransfer(msg.sender, token.balanceOf(address(this)));
    }

    emit EmergencyWithdraw(msg.sender);

    return true;
  }

  function setStrategyFeePositionFeeBps(uint256 _feeBps) external {
    strategyPositionFeeBasisPoints = _feeBps;
  }

  function whitelistUser(address _user, bool _whitelist) external onlyOwner {
    whitelistedUsers[_user] = _whitelist;
  }

  function setWhitelistUserMode(bool _mode) external onlyOwner {
    isWhitelistUserMode = _mode;
  }

  modifier whitelistCheck() {
    if (isWhitelistUserMode) {
      require(whitelistedUsers[msg.sender], "Strategy: Not whitelisted");
    }
    _;
  }
}