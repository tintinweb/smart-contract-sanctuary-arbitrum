// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IAnima is IERC20, IERC20Metadata {
  function CAP() external view returns (uint256);

  function mintFor(address _for, uint256 _amount) external;

  function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IAnimaChamber is IERC721 {
  function burn(uint256 _tokenId) external;

  function mintFor(address _for) external returns (uint256);

  function tokensOfOwner(
    address _owner
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStaker {
  function stake(uint256 _amount) external;

  function stakeBatch(uint256[] calldata _amounts) external;

  function unstake(uint256 _tokenId) external;

  function unstakeBatch(uint256[] calldata _tokenId) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStakerStorage {
  function unstakeAndChangeDelta(address _for, uint256 _amount) external;

  function getTotal() external view returns (uint);

  function getEpochChanges(uint _epoch) external view returns (int);

  function getEpochChangesBatch(
    uint startEpoch,
    uint endEpoch
  ) external view returns (int[] memory result);

  function changeDelta(int _delta) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IAnimaStakingRewards {
  function stakerCollect(
    uint256 _tokenId,
    bool _compound,
    uint[] calldata _params
  ) external;

  function stakerCollectBatch(
    uint256[] calldata _tokenId,
    bool[] calldata _compound,
    uint[][] calldata _params
  ) external;

  function realmerCollect(uint256 _realmId) external;

  function realmerCollectBatch(uint256[] calldata _realmIds) external;

  function collectManager(
    uint256 _tokenId,
    bool _forStaker,
    bool _forRealmer
  ) external;

  function registerChamberStaked(uint256 _chamberId, uint256 _realmId) external;

  function unregisterChamberStaked(
    uint256 _chamberId,
    uint256 _realmId
  ) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../Manager/ManagerModifier.sol";
import "../AnimaStaking/IAnimaStaker.sol";
import "../AnimaStaking/IAnimaChamber.sol";
import "../AnimaStaking/IAnimaStakingRewards.sol";
import "../Anima/IAnima.sol";
import "../AnimaStaking/IAnimaStakerStorage.sol";
import "../Utils/ArrayUtils.sol";
import "../Utils/EpochConfigurable.sol";
import "./IGloballyStakedTokenCalculatorStorage.sol";
import { IGloballyStakedTokenCalculator } from "./IGloballyStakedTokenCalculator.sol";
import "../Utils/Totals.sol";

contract GloballyStakedTokenCalculator is
  EpochConfigurable,
  IGloballyStakedTokenCalculator
{
  address[] public STAKING_ADDRESSES;
  int[] public WEIGHTS;
  IGloballyStakedTokenCalculatorStorage public STORAGE;
  IERC20 public TOKEN;

  uint public LAST_UPDATE_EPOCH;

  address public immutable TOTAL_SUPPLY_STORAGE_ADDRESS = address(0);

  constructor(
    address _manager,
    address _calculatorStorage,
    address _token,
    address[] memory _stakingAddresses,
    int[] memory _weights
  ) EpochConfigurable(_manager, 1 days, 0 hours) {
    STORAGE = IGloballyStakedTokenCalculatorStorage(_calculatorStorage);
    TOKEN = IERC20(_token);
    _updateStakingAddressesInternal(_stakingAddresses, _weights);
  }

  function currentGloballyStakedAverage(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    uint epoch = currentEpoch();
    if (epoch != LAST_UPDATE_EPOCH) {
      _updateCurrentEpochValues(epoch);
    }

    return globallyStakedAverageView(currentEpoch(), _epochSpan, true);
  }

  function globallyStakedAverageView(
    uint _epoch,
    uint _epochSpan,
    bool _includeCurrent
  )
    public
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    //load storage values for all addresses and save to array of arrays
    uint[][] memory stakedAmounts = new uint[][](STAKING_ADDRESSES.length);
    for (uint i = 0; i < STAKING_ADDRESSES.length; i++) {
      stakedAmounts[i] = STORAGE.getEpochValueBatch(
        STAKING_ADDRESSES[i],
        _epoch - _epochSpan,
        _epoch
      );
    }

    return
      _globallyStakedAverageInternal(
        STORAGE.getEpochValueBatch(
          TOTAL_SUPPLY_STORAGE_ADDRESS,
          _epoch - _epochSpan,
          _epoch
        ),
        stakedAmounts,
        0,
        stakedAmounts.length > 0 ? stakedAmounts[0].length : 0,
        _includeCurrent
      );
  }

  function circulatingSupplyBatch(
    uint _epochStart,
    uint _epochEnd
  ) public view returns (uint[] memory circulatingSupplies) {
    return
      STORAGE.getEpochValueBatch(
        TOTAL_SUPPLY_STORAGE_ADDRESS,
        _epochStart,
        _epochEnd
      );
  }

  function stakedAmountsBatch(
    uint _epochStart,
    uint _epochEnd
  )
    public
    view
    returns (address[] memory stakingAddresses, uint[][] memory stakedAmounts)
  {
    stakedAmounts = new uint[][](STAKING_ADDRESSES.length);
    for (uint i = 0; i < STAKING_ADDRESSES.length; i++) {
      stakedAmounts[i] = STORAGE.getEpochValueBatch(
        STAKING_ADDRESSES[i],
        _epochStart,
        _epochEnd
      );
    }

    return (STAKING_ADDRESSES, stakedAmounts);
  }

  function globallyStakedAverageBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    public
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupplies,
      int[] memory effectiveSupply,
      uint[] memory percentage
    )
  {
    uint historyStart = _epochStart - _epochSpan;
    uint[] memory circulatingSupply = STORAGE.getEpochValueBatch(
      TOTAL_SUPPLY_STORAGE_ADDRESS,
      historyStart,
      _epochEnd
    );

    uint[][] memory stakedAmounts = new uint[][](STAKING_ADDRESSES.length);
    for (uint i = 0; i < STAKING_ADDRESSES.length; i++) {
      stakedAmounts[i] = STORAGE.getEpochValueBatch(
        STAKING_ADDRESSES[i],
        historyStart,
        _epochEnd
      );
    }

    rawTotalStaked = new uint[](circulatingSupply.length);
    totalStaked = new int[](circulatingSupply.length);
    circulatingSupplies = new uint[](circulatingSupply.length);
    effectiveSupply = new int[](circulatingSupply.length);
    percentage = new uint[](circulatingSupply.length);
    for (uint i = 0; i < circulatingSupply.length; i++) {
      (
        rawTotalStaked[i],
        totalStaked[i],
        circulatingSupplies[i],
        effectiveSupply[i],
        percentage[i]
      ) = _globallyStakedAverageInternal(
        circulatingSupply,
        stakedAmounts,
        i,
        i + _epochSpan,
        false
      );
    }
  }

  function _globallyStakedAverageInternal(
    uint[] memory _circulatingSupply,
    uint[][] memory _stakedAmounts,
    uint _indexStart,
    uint _indexEnd,
    bool _includeCurrent
  )
    private
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    )
  {
    (uint circSupplyTotal, uint circSupplyEpochs) = Totals
      .calculateSubTotalWithNonZeroCount(
        _circulatingSupply,
        _indexStart,
        _indexEnd
      );

    if (_includeCurrent) {
      circSupplyTotal += TOKEN.totalSupply();
      circSupplyEpochs++;
    }

    // NO history data
    if (circSupplyEpochs == 0) {
      uint currentSupply = TOKEN.totalSupply();
      return (0, 0, currentSupply, int(currentSupply), 0);
    }

    circulatingSupply = circSupplyTotal / circSupplyEpochs;
    effectiveSupply = int(circulatingSupply);

    for (uint i = 0; i < _stakedAmounts.length; i++) {
      (uint stakedEpochValue, uint nonZeroEpochs) = Totals
        .calculateSubTotalWithNonZeroCount(
          _stakedAmounts[i],
          _indexStart,
          _indexEnd
        );

      if (_includeCurrent) {
        stakedEpochValue += TOKEN.balanceOf(STAKING_ADDRESSES[i]);
        nonZeroEpochs++;
      }

      int averageStakedEpochValue = int(stakedEpochValue / nonZeroEpochs);
      rawTotalStaked += uint(averageStakedEpochValue);
      totalStaked +=
        (averageStakedEpochValue * WEIGHTS[i]) /
        SIGNED_ONE_HUNDRED;

      int reverseWeight = SIGNED_ONE_HUNDRED - WEIGHTS[i];
      effectiveSupply -=
        (reverseWeight * averageStakedEpochValue) /
        SIGNED_ONE_HUNDRED;
    }

    if (effectiveSupply <= 0) {
      return
        totalStaked > 0
          ? (
            rawTotalStaked,
            totalStaked,
            circulatingSupply,
            int(0),
            ONE_HUNDRED
          )
          : (rawTotalStaked, int(0), circulatingSupply, int(0), 0);
    } else if (totalStaked > effectiveSupply) {
      return (
        rawTotalStaked,
        totalStaked,
        circulatingSupply,
        effectiveSupply,
        ONE_HUNDRED
      );
    }

    percentage = uint((totalStaked * SIGNED_ONE_HUNDRED) / effectiveSupply);
  }

  function _updateCurrentEpochValues(uint epoch) internal {
    for (uint i = 0; i < STAKING_ADDRESSES.length; i++) {
      uint currentStaked = TOKEN.balanceOf(STAKING_ADDRESSES[i]);
      STORAGE.setStorageValueForEpoch(
        epoch,
        STAKING_ADDRESSES[i],
        currentStaked
      );
    }

    uint256 currentSupply = TOKEN.totalSupply();
    STORAGE.setStorageValueForEpoch(
      epoch,
      TOTAL_SUPPLY_STORAGE_ADDRESS,
      currentSupply
    );
  }

  function _updateStakingAddressesInternal(
    address[] memory _stakingAddresses,
    int[] memory _weights
  ) internal {
    STAKING_ADDRESSES = new address[](_stakingAddresses.length);
    WEIGHTS = new int[](_weights.length);
    for (uint i = 0; i < _stakingAddresses.length; i++) {
      require(
        _stakingAddresses[i] != TOTAL_SUPPLY_STORAGE_ADDRESS,
        "GloballyStakedAnimaCalculator: INVALID_ADDRESS"
      );
      require(_weights[i] > 0, "GloballyStakedAnimaCalculator: INVALID_WEIGHT");
      STAKING_ADDRESSES[i] = _stakingAddresses[i];
      WEIGHTS[i] = _weights[i];
    }
  }

  //==============================================================================
  // Admin
  //==============================================================================

  function updateStakingAddresses(
    address[] memory _stakingAdresses,
    int[] memory weights
  ) external onlyAdmin {
    _updateStakingAddressesInternal(_stakingAdresses, weights);
  }

  function forceUpdateCurrentEpoch() external onlyAdmin {
    _updateCurrentEpochValues(currentEpoch());
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGloballyStakedTokenCalculator {
  function currentGloballyStakedAverage(
    uint _epochSpan
  )
    external
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageView(
    uint _epoch,
    uint _epochSpan,
    bool _includeCurrent
  )
    external
    view
    returns (
      uint rawTotalStaked,
      int totalStaked,
      uint circulatingSupply,
      int effectiveSupply,
      uint percentage
    );

  function globallyStakedAverageBatch(
    uint _epochStart,
    uint _epochEnd,
    uint _epochSpan
  )
    external
    view
    returns (
      uint[] memory rawTotalStaked,
      int[] memory totalStaked,
      uint[] memory circulatingSupply,
      int[] memory effectiveSupply,
      uint[] memory percentage
    );

  function stakedAmountsBatch(
    uint _epochStart,
    uint _epochEnd
  )
    external
    view
    returns (address[] memory stakingAddresses, uint[][] memory stakedAmounts);

  function circulatingSupplyBatch(
    uint _epochStart,
    uint _epochEnd
  ) external view returns (uint[] memory circulatingSupplies);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IGloballyStakedTokenCalculatorStorage {
  function getEpochValueBatch(
    address lp,
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint[] memory result);

  function getEpochValueBatchTotal(
    address lp,
    uint startEpoch,
    uint endEpoch
  ) external view returns (uint result, uint nonZeroEpochs);

  function setStorageValueForEpoch(uint epoch, address lp, uint value) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

uint256 constant DECIMAL_POINT = 10 ** 3;
uint256 constant ROUNDING_ADJUSTER = DECIMAL_POINT - 1;

int256 constant SIGNED_DECIMAL_POINT = int256(DECIMAL_POINT);

uint256 constant ONE_HUNDRED = 100 * DECIMAL_POINT;
uint256 constant ONE_HUNDRED_SQUARE = ONE_HUNDRED * ONE_HUNDRED;
int256 constant SIGNED_ONE_HUNDRED = 100 * SIGNED_DECIMAL_POINT;
int256 constant SIGNED_ONE_HUNDRED_SQUARE = SIGNED_ONE_HUNDRED * SIGNED_ONE_HUNDRED;

int256 constant SIGNED_ZERO = 0;

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IManager {
  function isAdmin(address _addr) external view returns (bool);

  function isManager(address _addr, uint256 _type) external view returns (bool);

  function addManager(address _addr, uint256 _type) external;

  function removeManager(address _addr, uint256 _type) external;

  function addAdmin(address _addr) external;

  function removeAdmin(address _addr) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../Manager/IManager.sol";

abstract contract ManagerModifier {
  //=======================================
  // Immutables
  //=======================================
  IManager public immutable MANAGER;

  //=======================================
  // Constructor
  //=======================================
  constructor(address _manager) {
    MANAGER = IManager(_manager);
  }

  //=======================================
  // Modifiers
  //=======================================
  modifier onlyAdmin() {
    require(MANAGER.isAdmin(msg.sender), "Manager: Not an Admin");
    _;
  }

  modifier onlyManager() {
    require(MANAGER.isManager(msg.sender, 0), "Manager: Not manager");
    _;
  }

  modifier onlyMinter() {
    require(MANAGER.isManager(msg.sender, 1), "Manager: Not minter");
    _;
  }

  modifier onlyTokenMinter() {
    require(MANAGER.isManager(msg.sender, 2), "Manager: Not token minter");
    _;
  }

  modifier onlyBinder() {
    require(MANAGER.isManager(msg.sender, 3), "Manager: Not binder");
    _;
  }

  modifier onlyConfigManager() {
    require(MANAGER.isManager(msg.sender, 4), "Manager: Not config manager");
    _;
  }

  modifier onlyTokenSpender() {
    require(MANAGER.isManager(msg.sender, 5), "Manager: Not token spender");
    _;
  }

  modifier onlyTokenEmitter() {
    require(MANAGER.isManager(msg.sender, 6), "Manager: Not token emitter");
    _;
  }

  modifier onlyPauser() {
    require(
      MANAGER.isAdmin(msg.sender) || MANAGER.isManager(msg.sender, 6),
      "Manager: Not pauser"
    );
    _;
  }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

library ArrayUtils {
  error ArrayLengthMismatch(uint _length1, uint _length2);
  error InvalidArrayOrder(uint index);

  function ensureSameLength(uint _l1, uint _l2) internal pure {
    if (_l1 != _l2) {
      revert ArrayLengthMismatch(_l1, _l2);
    }
  }

  function ensureSameLength(uint _l1, uint _l2, uint _l3) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
  }

  function ensureSameLength(
    uint _l1,
    uint _l2,
    uint _l3,
    uint _l4,
    uint _l5
  ) internal pure {
    ensureSameLength(_l1, _l2);
    ensureSameLength(_l1, _l3);
    ensureSameLength(_l1, _l4);
    ensureSameLength(_l1, _l5);
  }

  function checkAddressesForDuplicates(
    address[] memory _tokenAddrs
  ) internal pure {
    address lastAddress;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (lastAddress > _tokenAddrs[i]) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
    }
  }

  function checkForDuplicates(uint[] memory _ids) internal pure {
    uint lastId;
    for (uint i = 0; i < _ids.length; i++) {
      if (lastId > _ids[i]) {
        revert InvalidArrayOrder(i);
      }
      lastId = _ids[i];
    }
  }

  function checkForDuplicates(
    address[] memory _tokenAddrs,
    uint[] memory _tokenIds
  ) internal pure {
    address lastAddress;
    int256 lastTokenId = -1;
    for (uint i = 0; i < _tokenAddrs.length; i++) {
      if (_tokenAddrs[i] > lastAddress) {
        lastTokenId = -1;
      }

      if (_tokenAddrs[i] < lastAddress || int(_tokenIds[i]) <= lastTokenId) {
        revert InvalidArrayOrder(i);
      }
      lastAddress = _tokenAddrs[i];
      lastTokenId = int(_tokenIds[i]);
    }
  }

  function toSingleValueDoubleArray(
    uint[] memory _vals
  ) internal pure returns (uint[][] memory result) {
    result = new uint[][](_vals.length);
    for (uint i = 0; i < _vals.length; i++) {
      result[i] = ArrayUtils.toMemoryArray(_vals[i], 1);
    }
  }

  function toMemoryArray(
    uint _value,
    uint _length
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _value;
    }
  }

  function toMemoryArray(
    uint[] calldata _value
  ) internal pure returns (uint[] memory result) {
    result = new uint[](_value.length);
    for (uint i = 0; i < _value.length; i++) {
      result[i] = _value[i];
    }
  }

  function toMemoryArray(
    address _address,
    uint _length
  ) internal pure returns (address[] memory result) {
    result = new address[](_length);
    for (uint i = 0; i < _length; i++) {
      result[i] = _address;
    }
  }

  function toMemoryArray(
    address[] calldata _addresses
  ) internal pure returns (address[] memory result) {
    result = new address[](_addresses.length);
    for (uint i = 0; i < _addresses.length; i++) {
      result[i] = _addresses[i];
    }
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: Unlicensed

import "../lib/FloatingPointConstants.sol";

uint256 constant MASK_128 = ((1 << 128) - 1);
uint128 constant MASK_64 = ((1 << 64) - 1);

library Epoch {
  // Converts a given timestamp to an epoch using the specified duration and offset.
  // Example for battle timers resetting at noon UTC is: _duration = 1 days; _offset = 12 hours;
  function toEpochNumber(
    uint256 _timestamp,
    uint256 _duration,
    uint256 _offset
  ) internal pure returns (uint256) {
    return (_timestamp + _offset) / _duration;
  }

  // Here we assume that _config is a packed _duration (left 64 bits) and _offset (right 64 bits)
  function toEpochNumber(uint256 _timestamp, uint128 _config) internal pure returns (uint256) {
    return (_timestamp + (_config & MASK_64)) / ((_config >> 64) & MASK_64);
  }

  // Returns a value between 0 and ONE_HUNDRED which is the percentage of "completeness" of the epoch
  // result variable is reused for memory efficiency
  function toEpochCompleteness(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = (_config >> 64) & MASK_64;
    result = (ONE_HUNDRED * ((_timestamp + (_config & MASK_64)) % result)) / result;
  }

  // Converts a given epoch to a timestamp at the start of the epoch
  function epochToTimestamp(
    uint256 _epoch,
    uint128 _config
  ) internal pure returns (uint256 result) {
    result = _epoch * ((_config >> 64) & MASK_64);
    if (result > 0) {
      result -= (_config & MASK_64);
    }
  }

  // Create a config for the function above
  function toConfig(uint64 _duration, uint64 _offset) internal pure returns (uint128) {
    return (uint128(_duration) << 64) | uint128(_offset);
  }

  // Pack the epoch number with the config into a single uint256 for mappings
  function packEpoch(uint256 _epochNumber, uint128 _config) internal pure returns (uint256) {
    return (uint256(_config) << 128) | uint128(_epochNumber);
  }

  // Convert timestamp to Epoch and pack it with the config into a single uint256 for mappings
  function packTimestampToEpoch(
    uint256 _timestamp,
    uint128 _config
  ) internal pure returns (uint256) {
    return packEpoch(toEpochNumber(_timestamp, _config), _config);
  }

  // Unpack packedEpoch to epochNumber and config
  function unpack(
    uint256 _packedEpoch
  ) internal pure returns (uint256 epochNumber, uint128 config) {
    config = uint128(_packedEpoch >> 128);
    epochNumber = _packedEpoch & MASK_128;
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

import "./Epoch.sol";
import "../Manager/ManagerModifier.sol";
import "./IEpochConfigurable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract EpochConfigurable is Pausable, ManagerModifier, IEpochConfigurable {
  uint128 public EPOCH_CONFIG;

  constructor(
    address _manager,
    uint64 _epochDuration,
    uint64 _epochOffset
  ) ManagerModifier(_manager) {
    EPOCH_CONFIG = Epoch.toConfig(_epochDuration, _epochOffset);
  }

  function currentEpoch() public view returns (uint) {
    return epochAtTimestamp(block.timestamp);
  }

  function epochAtTimestamp(uint _timestamp) public view returns (uint) {
    return Epoch.toEpochNumber(_timestamp, EPOCH_CONFIG);
  }

  //=======================================
  // Admin
  //=======================================
  function pause() external onlyAdmin {
    _pause();
  }

  function unpause() external onlyAdmin {
    _unpause();
  }

  function updateEpochConfig(uint64 duration, uint64 offset) external onlyAdmin {
    EPOCH_CONFIG = Epoch.toConfig(duration, offset);
  }
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IEpochConfigurable {
  function currentEpoch() external view returns (uint);

  function epochAtTimestamp(uint _timestamp) external view returns (uint);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

import "./ArrayUtils.sol";

library Totals {
  /*
   * @dev Calculate the total value of an array of uints
   * @param _values An array of uints
   * @return sum The total value of the array
   */

  function calculateTotal(uint[] memory _values) internal pure returns (uint) {
    return calculateSubTotal(_values, 0, _values.length);
  }

  function calculateSubTotal(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint sum) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      sum += _values[i];
    }
  }

  function calculateTotalWithNonZeroCount(
    uint[] memory _values
  ) internal pure returns (uint total, uint nonZeroCount) {
    return calculateSubTotalWithNonZeroCount(_values, 0, _values.length);
  }

  function calculateSubTotalWithNonZeroCount(
    uint[] memory _values,
    uint _indexStart,
    uint _indexEnd
  ) internal pure returns (uint total, uint nonZeroCount) {
    for (uint i = _indexStart; i < _indexEnd; i++) {
      if (_values[i] > 0) {
        total += _values[i];
        nonZeroCount++;
      }
    }
  }

  /*
   * @dev Calculate the total value of an the current state and an array of gains, but only if the value is greater than 0 at any given point of time
   * @param _values An array of uints
   * @return sum The total value of the array
   */
  function calculateTotalBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint sum) {
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      sum += uint(currentValue);
    }
  }

  function calculateTotalBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
  }

  function calculateAverageBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint sum) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    for (uint i = _gains.length; i > 0; i--) {
      currentValue += _losses[i - 1];
      currentValue -= _gains[i - 1];
      sum += currentValue;
    }
    sum = sum / _gains.length;
  }

  function calculateEachDayValueBasedOnDeltas(
    uint currentValue,
    int[] memory _deltas
  ) internal pure returns (uint[] memory values) {
    values = new uint[](_deltas.length);
    int signedCurrent = int(currentValue);
    for (uint i = _deltas.length; i > 0; i--) {
      signedCurrent -= _deltas[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }

  function calculateEachDayValueBasedOnGainsAndLosses(
    uint currentValue,
    uint[] memory _gains,
    uint[] memory _losses
  ) internal pure returns (uint[] memory values) {
    ArrayUtils.ensureSameLength(_gains.length, _losses.length);

    values = new uint[](_gains.length);
    uint signedCurrent = currentValue;
    for (uint i = _gains.length; i > 0; i--) {
      signedCurrent += _losses[i - 1];
      signedCurrent -= _gains[i - 1];
      values[i - 1] = uint(signedCurrent);
    }
  }
}