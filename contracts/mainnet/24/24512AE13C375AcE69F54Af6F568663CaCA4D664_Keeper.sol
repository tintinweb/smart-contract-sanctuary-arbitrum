// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IManager is IERC721Enumerable {
  function maxVaultsPerUser() external view returns (uint256);
  function keeperRegistry() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

interface IPersonalVault {
  function initialize(uint256 vaultId, address keeper, address _strategy, address[] memory inputs, bytes memory config) external payable;
  function deposit(uint256 amount) external;
  function withdraw(address recipient, uint256 amount, bool forced) external;
  function prepareBurn() external;
  function run() external payable;
  function estimatedTotalAsset() external view returns (uint256);
  function strategy() external view returns (address);
}

interface IPerpetualVault is IPersonalVault {
  function lookback() external view returns (uint256);
  function indexToken() external view returns (address);
  function hedgeToken() external view returns (address);
  function isLong() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

interface IStrategy {
  function name() external view returns (string memory);
  function getSignal(address, uint256) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import "./interfaces/IStrategy.sol";
import "./interfaces/IManager.sol";
import "./interfaces/IPersonalVault.sol";

/**
 * @notice
 *  This is a keeper contract that uses chainlink automation to check signal and trigger actions
 *   based on that signal data
 */
contract Keeper is AutomationCompatibleInterface {
  IManager public _manager;
  address public owner;
  uint256 public upkeepId;                    
  uint256 public vaultCount;
  uint256 public upkeepDelay;
  uint256 public lastTimestamp;
  mapping (uint256 => address) public vaults;
  mapping (address => bool) public vaultExist;
  bool public paused;

  event VaultAdded(address vault);
  event VaultRemoved(address vault);

  modifier onlyManager() {
    require(msg.sender == address(_manager), "!manager");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "!owner");
    _;
  }

  function initialize(address _owner) public {
    require(_owner != address(0), "zero address");
    _manager = IManager(msg.sender);
    owner = _owner;
    upkeepDelay = 60 * 60;    // 1 hour
  }

  function addVault(address _vault) external onlyManager {
    require(_vault != address(0), "zero address");
    require(vaultExist[_vault] == false, "already exist");
    require(vaultCount < _manager.maxVaultsPerUser(), "exceed maximum");
    vaults[vaultCount] = _vault;
    vaultCount = vaultCount + 1;
    vaultExist[_vault] = true;

    emit VaultAdded(_vault);
  }

  function removeVault(address _vault) external onlyManager {
    require(_vault != address(0), "zero address");
    require(vaultExist[_vault] == true, "not exist");
    for (uint8 i = 0; i < vaultCount; i++) {
      if (vaults[i] == _vault) {
        vaults[i] = vaults[vaultCount];
        vaultExist[_vault] = false;
        delete vaults[vaultCount];
        vaultCount = vaultCount - 1;
        break;
      }
    }

    emit VaultRemoved(_vault);
  }

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
    for (uint256 i = 0; i < vaultCount; i++) {
      IPerpetualVault vault = IPerpetualVault(vaults[i]);
      address tradeToken = vault.indexToken();
      uint256 lookback = vault.lookback();
      bool _signal = IStrategy(vault.strategy()).getSignal(tradeToken, lookback);
      if (vault.isLong() == _signal) {
        IERC20 hedgeToken = IERC20(vault.hedgeToken());
        if (hedgeToken.balanceOf(address(vault)) > 0) {
          upkeepNeeded = true;
          performData = abi.encode(address(vault));
        } else {
          upkeepNeeded = false;
        }
      } else {
        upkeepNeeded = true;
        performData = abi.encode(address(vault));
      }
    }
  }

  function performUpkeep(bytes calldata performData) external override {
    require(msg.sender == _manager.keeperRegistry(), "not a keeper registry");
    require(paused == false, "paused");
    require(block.timestamp - lastTimestamp >= upkeepDelay, "delay");
    (address vault) = abi.decode(
      performData,
      (address)
    );

    // double check upkeep condition
    address tradeToken = IPerpetualVault(vault).indexToken();
    uint256 lookback = IPerpetualVault(vault).lookback();
    bool _signal = IStrategy(IPersonalVault(vault).strategy()).getSignal(tradeToken, lookback);
    require(
      IPerpetualVault(vault).isLong() != _signal || 
      IERC20(IPerpetualVault(vault).hedgeToken()).balanceOf(vault) > 0,
      "invalid condition"
    );
    
    IPersonalVault(vault).run();
    lastTimestamp = block.timestamp;
  }

  function pauseUpkeep(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function setUpkeepId(uint256 _upkeepId) external onlyManager {
    upkeepId = _upkeepId;
  }

  function setUpkeepDelay(uint256 _upkeepDelay) external onlyOwner {
    upkeepDelay = _upkeepDelay;
  }

  //////////////////////////////
  ////    View Functions    ////
  //////////////////////////////

  function manager() external view returns (address) {
    return address(_manager);
  }

  function delayed() external view returns (bool) {
    return block.timestamp - lastTimestamp >= upkeepDelay;
  }

}