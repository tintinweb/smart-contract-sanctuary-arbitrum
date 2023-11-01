//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./EpochCampaign.sol";

contract CampaignFactory is Ownable, Pausable {
  using SafeERC20 for IERC20;

  /// @notice implementation of EpochCampaign to clone from
  address public immutable epochCampaignImplementation;

  /// @notice the default commission for the created campaigns
  uint256 public defaultCommissionBp = 100;

  event EpochCampaignEvent(
    address indexed creator,
    address indexed campaignAddress
  );
  event UpdatedDefaultCommission(
    uint256 oldDefaultCommission,
    uint256 newDefaultCommission
  );
  error InvalidDefaultCommissionInput(
    uint256 commissionBp,
    uint256 minCommissionBp,
    uint256 maxCommissionBp
  );

  constructor() {
    epochCampaignImplementation = address(new EpochCampaign());
  }

  /// @notice creates a new Epoch campaign.
  /// @param tokens defines the ERC20 contract addresses to be used in the campaign contract.
  function createEpochCampaign(IERC20[] calldata tokens)
    external
    whenNotPaused
    returns (address)
  {
    // This will prevent creating the same campaign twice (with the same reward tokens, owner, postmint address and PPT Allocator)
    bytes32 salt = keccak256(abi.encodePacked(tokens, msg.sender, owner()));

    address payable clone = payable(
      Clones.cloneDeterministic(epochCampaignImplementation, salt)
    );
    EpochCampaign(clone).initialize(
      tokens,
      msg.sender,
      owner(),
      defaultCommissionBp
    );

    emit EpochCampaignEvent(msg.sender, clone);

    return clone;
  }

  function predictCampaignAddress(IERC20[] calldata tokens, address deployer)
    external
    view
    returns (address predicted)
  {
    bytes32 salt = keccak256(abi.encodePacked(tokens, deployer, owner()));
    return
      Clones.predictDeterministicAddress(epochCampaignImplementation, salt);
  }

  /// @notice set the default commission
  /// @param _defaultCommissionBp defines the default commission in basis points
  function setDefaultCommission(uint256 _defaultCommissionBp)
    external
    onlyOwner
  {
    if (_defaultCommissionBp > 10000) {
      revert InvalidDefaultCommissionInput(_defaultCommissionBp, 0, 10000);
    }
    uint256 oldDefaultCommission = defaultCommissionBp;
    defaultCommissionBp = _defaultCommissionBp;
    emit UpdatedDefaultCommission(oldDefaultCommission, _defaultCommissionBp);
  }

  /// @notice pauses the factory.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice unpauses the factory.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice utility function for withdrawing stuck ERC20s
  function transferERC20(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyOwner {
    require(token.balanceOf(address(this)) >= amount, "Not enough funds");
    token.safeTransfer(to, amount);
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract EpochCampaign is OwnableUpgradeable, PausableUpgradeable {
  using SafeERC20 for IERC20;

  event EpochClaimed(
    address indexed claimant,
    uint256 indexed epoch,
    Funds[] funds
  );
  event EpochAdded(uint256 indexed epoch, bytes32 indexed merkleRoot);
  event EpochExpired(uint256 indexed epoch);
  event AddedFunds(address indexed sender, Funds[] funds);
  event UpdatedCommission(uint256 oldCommission, uint256 newCommission);

  struct MultiProof {
    bytes32[] merkleProof;
    bool[] proofFlags;
  }

  struct Funds {
    IERC20 token;
    uint256 amount;
  }

  error Unauthorized(address caller, address authorized);
  error NoFundsProvided();
  error NoTokensProvided();
  error NoAmountProvided();
  error BadToken(address token);
  error DuplicateToken(address token);
  error UnsupportedToken(address token);
  error InvalidCommissionInput(
    uint256 commissionBp,
    uint256 minCommissionBp,
    uint256 maxCommissionBp
  );
  error EpochAlreadyAllocated(uint256 epoch);
  error EpochInTheFuture(uint256 epoch);
  error InvalidClaimInputs(uint256 epochs, uint256 funds, uint256 proofs);
  error RewardsAlreadyClaimed(uint256 epoch, address account);
  error InsufficientFunds(uint256 available, uint256 requested);
  error BadCommissionTransfer();
  error BadFundsTransfer();

  /// @notice the postmint address, to which commissions will be transferred to.
  address public postmint;

  /// @notice helper variable token mapping
  address internal constant SENTINEL_TOKEN = address(0x1);

  /// @notice is in base points, ex: 1% in base points would be 100
  uint256 public commissionBp;

  /// @notice helper variable for base point conversion.
  uint256 internal constant BASE = 10000;

  /// @notice the number of tokens in the campaign.
  uint256 internal numTokens;

  /// @notice running epochs counter
  uint256 public epochCount;

  /// @notice the tokens to be used for the rewards.
  mapping(address => address) public tokens;

  /// @notice the Merkle Tree Root hash for certain epoch.
  /// @dev maps epoch => merkleRoot.
  mapping(uint256 => bytes32) public merkleRoots;

  /// @notice whether a given address has claimed for a given token for a given epoch.
  /// @dev the mapping maps epochs => user =>  claimed.
  mapping(uint256 => mapping(address => bool)) public claimed;

  /// @notice the campaign budget.
  mapping(IERC20 => uint256) public budgets;

  /// @notice the rootUploaders
  mapping(address => bool) public isRootUploader;

  /// @notice checks whether the caller is postmint.
  modifier onlyPostmint() {
    _checkPostmint();
    _;
  }

  function _checkPostmint() internal view virtual {
    if (msg.sender != postmint) {
      revert Unauthorized(msg.sender, postmint);
    }
  }

  /// @notice checks whether the caller is postmint.
  modifier onlyRootUploaders() {
    _checkRootUploaders();
    _;
  }

  function _checkRootUploaders() internal view virtual {
    if (!isRootUploader[msg.sender]) {
      revert Unauthorized(msg.sender, owner());
    }
  }

  /// @notice Initialize a new (paused) epoch campaign.
  /// @param _tokens the ERC20 tokens to be used for this campaign.
  /// @param _creator the address of the campaign creator.
  /// @param _postmint the postmint address.
  function initialize(
    IERC20[] calldata _tokens,
    address _creator,
    address _postmint,
    uint256 _defaultCommissionBp
  ) external initializer {
    uint256 tokensLen = _tokens.length;
    if (tokensLen == 0) {
      revert NoTokensProvided();
    }
    // SENTINEL_TOKEN here acts as the head of the "linked list"
    address prevToken = SENTINEL_TOKEN;
    for (uint256 i = 0; i < tokensLen; ) {
      address currentToken = address(_tokens[i]);
      // check that the token has a sensible address.
      if (
        currentToken == address(0) ||
        currentToken == SENTINEL_TOKEN ||
        currentToken == address(this) ||
        prevToken == currentToken
      ) {
        revert BadToken(currentToken);
      }
      // Check that the owner is not a duplicate.
      if (tokens[currentToken] != address(0)) {
        revert DuplicateToken(currentToken);
      }
      tokens[prevToken] = currentToken;
      prevToken = currentToken;
      unchecked {
        i++;
      }
    }
    // SENTINEL_TOKEN here acts as the tail of the "linked list"
    tokens[prevToken] = SENTINEL_TOKEN;
    numTokens = tokensLen;

    postmint = _postmint;
    commissionBp = _defaultCommissionBp;
    isRootUploader[_creator] = true;
    __Ownable_init();
    transferOwnership(_creator);
    _pause();
  }

  /// @notice Creates a new epoch and allocates funds to it.
  /// @param _merkleRoot defines the merkleRoot for the epoch.
  /// @param funds defines the tokens and amount allocated for this epoch.
  function seedNewAllocations(bytes32 _merkleRoot, Funds[] calldata funds)
    public
    returns (uint256 epochId)
  {
    addFunds(funds);

    epochId = epochCount;

    if (merkleRoots[epochId] != bytes32(0)) {
      revert EpochAlreadyAllocated(epochId);
    }
    merkleRoots[epochId] = _merkleRoot;

    uint256 eCount = epochId + 1;
    epochCount = eCount;

    if (paused()) {
      _unpause();
    }

    emit EpochAdded(epochId, _merkleRoot);
  }

  /// @notice transfers {_tokens, amounts} for each token, amount pair provided from the tx sender to the campaign address
  /// while taking commission for postmint.
  /// @param funds defines the tokens and amounts to transfer, they MUST be part of the tokens supported by the campaign.
  /// @dev this function transfers amounts[i] for tokens[i] to the campaign.
  /// The number of tokens MUST match the number of amounts.
  function addFunds(Funds[] calldata funds) public onlyOwner {
    uint256 fundsLen = funds.length;
    if (fundsLen == 0) {
      revert NoFundsProvided();
    }
    for (uint256 i = 0; i < fundsLen; ) {
      bool supported = supportedToken(funds[i].token);
      if (!supported) {
        revert UnsupportedToken(address(funds[i].token));
      }
      if (funds[i].amount == 0) {
        revert NoAmountProvided();
      }
      _handleAddFunds(funds[i].token, funds[i].amount);

      unchecked {
        i++;
      }
    }
    emit AddedFunds(msg.sender, funds);
  }

  /// @notice helper function that checks if the provided token is supported by the campaign.
  /// @param token the token to check for support
  function supportedToken(IERC20 token) public view returns (bool) {
    return
      address(token) != SENTINEL_TOKEN && tokens[address(token)] != address(0);
  }

  /// @notice uploads Merkle Tree Root hash for epoch and unpauses, only the postmint address can invoke this.
  /// @param _merkleRoot is the root hash.
  function uploadRoot(bytes32 _merkleRoot)
    external
    onlyRootUploaders
    returns (uint256 epochId)
  {
    epochId = epochCount;
    if (merkleRoots[epochId] != bytes32(0)) {
      revert EpochAlreadyAllocated(epochId);
    }
    merkleRoots[epochCount] = _merkleRoot;

    uint256 eCount = epochId + 1;
    epochCount = eCount;
    if (paused()) {
      _unpause();
    }

    emit EpochAdded(epochId, _merkleRoot);
  }

  /// @notice updates the commission amount, only the postmint address can invoke this.
  /// @param _commissionBp is in base points, not percents, ex: 1% in base points would be 100.
  function updateCommission(uint256 _commissionBp) external onlyPostmint {
    if (_commissionBp > BASE) {
      revert InvalidCommissionInput(_commissionBp, 0, BASE);
    }
    uint256 oldCommission = commissionBp;
    commissionBp = _commissionBp;
    emit UpdatedCommission(oldCommission, _commissionBp);
  }

  /// @notice updates the root uploader account, only the owner can invoke this.
  /// @param rootUploader is the adress of the root uploader
  /// @param active whether the root uploader is active or not (allows removing the authoritiy)
  function updateRootUploader(address rootUploader, bool active)
    external
    onlyOwner
  {
    isRootUploader[rootUploader] = active;
  }

  /// @notice handles transfers, budget adjustment and commission calculation.
  /// @param token is the token to be allocated.
  /// @param amount is the amount to be allocated.
  function _handleAddFunds(IERC20 token, uint256 amount) private {
    // calculate commission
    uint256 commission = (amount * commissionBp) / BASE;
    uint256 amountLeft = amount - commission;

    // transfer commission to postmint.
    uint256 commissionBefore = token.balanceOf(postmint);
    token.safeTransferFrom(msg.sender, postmint, commission);
    uint256 commissionAfter = token.balanceOf(postmint);
    if (commissionAfter - commissionBefore != commission) {
      revert BadCommissionTransfer();
    }

    // transfer the amount left to the campaign.
    uint256 amountLeftBefore = token.balanceOf(address(this));
    token.safeTransferFrom(msg.sender, address(this), amountLeft);
    uint256 amountLeftAfter = token.balanceOf(address(this));
    if (amountLeftAfter - amountLeftBefore != amountLeft) {
      revert BadFundsTransfer();
    }

    uint256 budget = budgets[token];
    budget += amountLeft;
    budgets[token] = budget;
  }

  /// @notice marks the provided epoch as expired.
  /// @param epochId the epoch to be marked expired.
  function expireEpoch(uint256 epochId) public onlyOwner {
    merkleRoots[epochId] = bytes32(0);

    emit EpochExpired(epochId);
  }

  /// @notice claim funds from an epoch, only when the campaign is not paused.
  /// @param epochId defines the epoch to claim from.
  /// @param account is the account to claim the funds for.
  /// @param funds are the amounts to claim.
  /// @param multiProof is the proof for the epoch claim.
  function claimEpoch(
    uint256 epochId,
    address account,
    Funds[] calldata funds,
    MultiProof calldata multiProof
  ) public whenNotPaused {
    uint256 fundsLen = funds.length;
    if (fundsLen == 0) {
      revert NoFundsProvided();
    }
    _claimAllocations(account, epochId, funds, multiProof);
    for (uint256 i = 0; i < fundsLen; ) {
      _disburse(account, funds[i].token, funds[i].amount);
      unchecked {
        i++;
      }
    }
  }

  /// @notice claim funds from multiple epochs, only when the campaign is not paused. If any claim is invalid the tx is reverted.
  /// @param epochIds defines the epochs to claim from.
  /// @param account is the account to claim the funds for.
  /// @param funds is the amounts to claim per token per epoch.
  /// @param multiProofs defines the proofs the for the claims.
  function claimEpochs(
    uint256[] calldata epochIds,
    address account,
    Funds[][] calldata funds,
    MultiProof[] calldata multiProofs
  ) public whenNotPaused {
    uint256 numEpochs = epochIds.length;
    if (numEpochs != funds.length || numEpochs != multiProofs.length) {
      revert InvalidClaimInputs(numEpochs, funds.length, multiProofs.length);
    }

    // claim every epoch individually
    for (uint256 i = 0; i < numEpochs; ) {
      claimEpoch(epochIds[i], account, funds[i], multiProofs[i]);
      unchecked {
        i++;
      }
    }
  }

  /// @notice verifies whether the claims for an epoch are valid.
  /// @param epochId defines the epoch to claim from.
  /// @param account is the account to claim the funds for.
  /// @param funds are the funds to claim.
  /// @param multiProof is the multiProof for the epoch claim.
  function verifyClaims(
    uint256 epochId,
    address account,
    Funds[] calldata funds,
    MultiProof calldata multiProof
  ) public view returns (bool valid) {
    return _verifyClaims(epochId, account, funds, multiProof);
  }

  /// @notice marks a claim as claimed.
  /// @param epochId defines the epoch to mark as claimed.
  /// @param account is the account who claimed.
  /// @param funds are the funds claimed.
  /// @param multiProof is the multiProof for the claim.
  function _claimAllocations(
    address account,
    uint256 epochId,
    Funds[] calldata funds,
    MultiProof calldata multiProof
  ) private {
    if (epochId > epochCount) {
      revert EpochInTheFuture(epochId);
    }

    if (claimed[epochId][account]) {
      revert RewardsAlreadyClaimed(epochId, account);
    }
    uint256 fundsLen = funds.length;
    for (uint256 i = 0; i < fundsLen; ) {
      if (funds[i].amount > budgets[funds[i].token]) {
        revert InsufficientFunds(budgets[funds[i].token], funds[i].amount);
      }
      unchecked {
        i++;
      }
    }

    require(_verifyClaims(epochId, account, funds, multiProof), "InvalidProof");

    claimed[epochId][account] = true;

    emit EpochClaimed(account, epochId, funds);
  }

  /// @notice verifies whether the merkle multiProof is valid, and the account hasn't claimed.
  /// @param epochId defines the epoch to claim from.
  /// @param account is the account to claim the funds for.
  /// @param funds are the funds to claim.
  /// @param multiProof is the mutliproof for the epoch claim.
  function _verifyClaims(
    uint256 epochId,
    address account,
    Funds[] calldata funds,
    MultiProof calldata multiProof
  ) private view returns (bool valid) {
    uint256 fundsLen = funds.length;
    if (fundsLen == 0) {
      revert NoFundsProvided();
    }
    bytes32[] memory leaves = new bytes32[](fundsLen);
    for (uint256 i = 0; i < fundsLen; ) {
      // double hashed for better resistance to (second) pre-image attacks
      bytes32 leaf = keccak256(
        abi.encode(
          keccak256(abi.encode(funds[i].amount, funds[i].token, account))
        )
      );
      leaves[i] = leaf;
      unchecked {
        i++;
      }
    }
    return
      MerkleProof.multiProofVerifyCalldata(
        multiProof.merkleProof,
        multiProof.proofFlags,
        merkleRoots[epochId],
        leaves
      ) && !claimed[epochId][account];
  }

  /// @notice transfers "amount" to "account".
  /// @param account is the account to transfer funds to.
  /// @param token is the token to transfer.
  /// @param amount is the amount to transfer.
  function _disburse(
    address account,
    IERC20 token,
    uint256 amount
  ) private {
    if (amount > 0 && amount <= budgets[token]) {
      budgets[token] -= amount;
      token.safeTransfer(account, amount);
    } else {
      revert("No balance");
    }
  }

  /// @notice returns the tokens the campaign is using.
  function getTokens() public view returns (address[] memory) {
    address[] memory _tokens = new address[](numTokens);

    uint256 index = 0;
    address currentToken = tokens[SENTINEL_TOKEN];
    while (currentToken != SENTINEL_TOKEN) {
      // set the current token at the current index
      _tokens[index] = currentToken;
      // currentToken now is the next token in the "linked list"
      currentToken = tokens[currentToken];
      index++;
    }
    return _tokens;
  }

  /// @notice pauses the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice unpauses the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice utility function for withdrawing stuck ERC20s or unused budget
  function transferERC20(
    IERC20 token,
    address to,
    uint256 amount
  ) external onlyOwner whenPaused {
    if (amount > token.balanceOf(address(this))) {
      revert InsufficientFunds(token.balanceOf(address(this)), amount);
    }

    uint256 budget = budgets[token];
    if (amount > budget) {
      revert InsufficientFunds(budget, amount);
    }
    budget -= amount;
    budgets[token] = budget;

    token.safeTransfer(to, amount);
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract EpochCampaignV2 is OwnableUpgradeable, PausableUpgradeable {
    using SafeERC20 for IERC20;

    event EpochClaimed(
        address indexed claimant,
        uint256 indexed epoch,
        Funds[] funds
    );
    event EpochAdded(uint256 indexed epoch, bytes32 indexed merkleRoot);
    event EpochExpired(uint256 indexed epoch);
    event AddedFunds(address indexed sender, Funds[] funds);
    event RemovedFunds(address indexed remover, Funds funds);
    event UpdatedCommission(uint256 oldCommission, uint256 newCommission);

    struct MultiProof {
        bytes32[] merkleProof;
        bool[] proofFlags;
    }

    struct Funds {
        IERC20 token;
        uint256 amount;
    }

    error Unauthorized(address caller, address authorized);
    error NoFundsProvided();
    error NoTokensProvided();
    error NoAmountProvided();
    error BadToken(address token);
    error DuplicateToken(address token);
    error UnsupportedToken(address token);
    error InvalidCommissionInput(
        uint256 commissionBp,
        uint256 minCommissionBp,
        uint256 maxCommissionBp
    );
    error EpochAlreadyAllocated(uint256 epoch);
    error EpochInTheFuture(uint256 epoch);
    error InvalidClaimInputs(uint256 epochs, uint256 funds, uint256 proofs);
    error RewardsAlreadyClaimed(uint256 epoch, address account);
    error InsufficientFunds(uint256 available, uint256 requested);
    error BadCommissionTransfer();
    error BadFundsTransfer();

    /// @notice the postmint address, to which commissions will be transferred to.
    address public postmint;

    /// @notice helper variable token mapping
    address internal constant SENTINEL_TOKEN = address(0x1);

    /// @notice is in base points, ex: 1% in base points would be 100
    uint256 public commissionBp;

    /// @notice helper variable for base point conversion.
    uint256 internal constant BASE = 10000;

    /// @notice the number of tokens in the campaign.
    uint256 internal numTokens;

    /// @notice running epochs counter
    uint256 public epochCount;

    /// @notice the tokens to be used for the rewards.
    mapping(address => address) public tokens;

    /// @notice the Merkle Tree Root hash for certain epoch.
    /// @dev maps epoch => merkleRoot.
    mapping(uint256 => bytes32) public merkleRoots;

    /// @notice whether a given address has claimed for a given token for a given epoch.
    /// @dev the mapping maps epochs => user =>  claimed.
    mapping(uint256 => mapping(address => bool)) public claimed;

    /// @notice the campaign budget.
    mapping(IERC20 => uint256) public budgets;

    /// @notice the rootUploaders
    mapping(address => bool) public isRootUploader;

    /// @notice the add funds managers
    mapping(address => bool) public isFundsAdder;

    /// @notice the remove funds managers
    mapping(address => bool) public isFundsRemover;

    /// @notice checks whether the caller is postmint.
    modifier onlyPostmint() {
        _checkPostmint();
        _;
    }

    function _checkPostmint() internal view virtual {
        if (msg.sender != postmint) {
            revert Unauthorized(msg.sender, postmint);
        }
    }

    /// @notice checks whether the caller is postmint.
    modifier onlyRootUploaders() {
        _checkRootUploaders();
        _;
    }

    /// @notice checks whether the caller is add funds manager.
    modifier onlyAddFundsManagers() {
        _checkFundAdders();
        _;
    }

    /// @notice checks whether the caller is remove funds manager.
    modifier onlyRemoveFundsManagers() {
        _checkFundRemovers();
        _;
    }

    function _checkRootUploaders() internal view virtual {
        if (!isRootUploader[msg.sender]) {
            revert Unauthorized(msg.sender, owner());
        }
    }

    function _checkFundAdders() internal view virtual {
        if (!isFundsAdder[msg.sender]) {
            revert Unauthorized(msg.sender, owner());
        }
    }

    function _checkFundRemovers() internal view virtual {
        if (!isFundsRemover[msg.sender]) {
            revert Unauthorized(msg.sender, owner());
        }
    }

    /// @notice Initialize a new (paused) epoch campaign.
    /// @param _tokens the ERC20 tokens to be used for this campaign.
    /// @param _creator the address of the campaign creator.
    /// @param _postmint the postmint address.
    function initialize(
        IERC20[] calldata _tokens,
        address _creator,
        address _postmint,
        uint256 _defaultCommissionBp
    ) external initializer {
        uint256 tokensLen = _tokens.length;
        if (tokensLen == 0) {
            revert NoTokensProvided();
        }
        // SENTINEL_TOKEN here acts as the head of the "linked list"
        address prevToken = SENTINEL_TOKEN;
        for (uint256 i = 0; i < tokensLen; ) {
            address currentToken = address(_tokens[i]);
            // check that the token has a sensible address.
            if (
                currentToken == address(0) ||
                currentToken == SENTINEL_TOKEN ||
                currentToken == address(this) ||
                prevToken == currentToken
            ) {
                revert BadToken(currentToken);
            }
            // Check that the owner is not a duplicate.
            if (tokens[currentToken] != address(0)) {
                revert DuplicateToken(currentToken);
            }
            tokens[prevToken] = currentToken;
            prevToken = currentToken;
            unchecked {
                i++;
            }
        }
        // SENTINEL_TOKEN here acts as the tail of the "linked list"
        tokens[prevToken] = SENTINEL_TOKEN;
        numTokens = tokensLen;

        postmint = _postmint;
        commissionBp = _defaultCommissionBp;
        isRootUploader[_creator] = true;
        isFundsAdder[_creator] = true;
        isFundsRemover[_creator] = true;
        __Ownable_init();
        transferOwnership(_creator);
        _pause();
    }

    /// @notice Creates a new epoch and allocates funds to it.
    /// @param _merkleRoot defines the merkleRoot for the epoch.
    /// @param funds defines the tokens and amount allocated for this epoch.
    function seedNewAllocations(
        bytes32 _merkleRoot,
        Funds[] calldata funds
    ) public returns (uint256 epochId) {
        addFunds(funds);

        epochId = epochCount;

        if (merkleRoots[epochId] != bytes32(0)) {
            revert EpochAlreadyAllocated(epochId);
        }
        merkleRoots[epochId] = _merkleRoot;

        uint256 eCount = epochId + 1;
        epochCount = eCount;

        if (paused()) {
            _unpause();
        }

        emit EpochAdded(epochId, _merkleRoot);
    }

    /// @notice transfers {_tokens, amounts} for each token, amount pair provided from the tx sender to the campaign address
    /// while taking commission for postmint.
    /// @param funds defines the tokens and amounts to transfer, they MUST be part of the tokens supported by the campaign.
    /// @dev this function transfers amounts[i] for tokens[i] to the campaign.
    /// The number of tokens MUST match the number of amounts.
    function addFunds(Funds[] calldata funds) public onlyAddFundsManagers {
        uint256 fundsLen = funds.length;
        if (fundsLen == 0) {
            revert NoFundsProvided();
        }
        for (uint256 i = 0; i < fundsLen; ) {
            bool supported = supportedToken(funds[i].token);
            if (!supported) {
                revert UnsupportedToken(address(funds[i].token));
            }
            if (funds[i].amount == 0) {
                revert NoAmountProvided();
            }
            _handleAddFunds(funds[i].token, funds[i].amount);

            unchecked {
                i++;
            }
        }
        emit AddedFunds(msg.sender, funds);
    }

    /// @notice helper function that checks if the provided token is supported by the campaign.
    /// @param token the token to check for support
    function supportedToken(IERC20 token) public view returns (bool) {
        return
            address(token) != SENTINEL_TOKEN &&
            tokens[address(token)] != address(0);
    }

    /// @notice uploads Merkle Tree Root hash for epoch and unpauses, only the postmint address can invoke this.
    /// @param _merkleRoot is the root hash.
    function uploadRoot(
        bytes32 _merkleRoot
    ) external onlyRootUploaders returns (uint256 epochId) {
        epochId = epochCount;
        if (merkleRoots[epochId] != bytes32(0)) {
            revert EpochAlreadyAllocated(epochId);
        }
        merkleRoots[epochCount] = _merkleRoot;

        uint256 eCount = epochId + 1;
        epochCount = eCount;
        if (paused()) {
            _unpause();
        }

        emit EpochAdded(epochId, _merkleRoot);
    }

    /// @notice updates the commission amount, only the postmint address can invoke this.
    /// @param _commissionBp is in base points, not percents, ex: 1% in base points would be 100.
    function updateCommission(uint256 _commissionBp) external onlyPostmint {
        if (_commissionBp > BASE) {
            revert InvalidCommissionInput(_commissionBp, 0, BASE);
        }
        uint256 oldCommission = commissionBp;
        commissionBp = _commissionBp;
        emit UpdatedCommission(oldCommission, _commissionBp);
    }

    /// @notice updates the root uploader account, only the owner can invoke this.
    /// @param rootUploader is the adress of the root uploader
    /// @param active whether the root uploader is active or not (allows removing the authoritiy)
    function updateRootUploader(
        address rootUploader,
        bool active
    ) external onlyOwner {
        isRootUploader[rootUploader] = active;
    }

    /// @notice updates the root uploader account, only the owner can invoke this.
    /// @param fundsAdder is the adress of the root uploader
    /// @param active whether the root uploader is active or not (allows removing the authoritiy)
    function updateAddFundsManager(
        address fundsAdder,
        bool active
    ) external onlyOwner {
        isFundsAdder[fundsAdder] = active;
    }

    /// @notice updates the root uploader account, only the owner can invoke this.
    /// @param fundsRemover is the adress of the root uploader
    /// @param active whether the root uploader is active or not (allows removing the authoritiy)
    function updateRemoveFundsManager(
        address fundsRemover,
        bool active
    ) external onlyOwner {
        isFundsRemover[fundsRemover] = active;
    }

    /// @notice handles transfers, budget adjustment and commission calculation.
    /// @param token is the token to be allocated.
    /// @param amount is the amount to be allocated.
    function _handleAddFunds(IERC20 token, uint256 amount) private {
        // calculate commission
        uint256 commission = (amount * commissionBp) / BASE;
        uint256 amountLeft = amount - commission;

        // transfer commission to postmint.
        uint256 commissionBefore = token.balanceOf(postmint);
        token.safeTransferFrom(msg.sender, postmint, commission);
        uint256 commissionAfter = token.balanceOf(postmint);
        if (commissionAfter - commissionBefore != commission) {
            revert BadCommissionTransfer();
        }

        // transfer the amount left to the campaign.
        uint256 amountLeftBefore = token.balanceOf(address(this));
        token.safeTransferFrom(msg.sender, address(this), amountLeft);
        uint256 amountLeftAfter = token.balanceOf(address(this));
        if (amountLeftAfter - amountLeftBefore != amountLeft) {
            revert BadFundsTransfer();
        }

        uint256 budget = budgets[token];
        budget += amountLeft;
        budgets[token] = budget;
    }

    /// @notice marks the provided epoch as expired.
    /// @param epochId the epoch to be marked expired.
    function expireEpoch(uint256 epochId) public onlyRootUploaders {
        merkleRoots[epochId] = bytes32(0);

        emit EpochExpired(epochId);
    }

    /// @notice claim funds from an epoch, only when the campaign is not paused.
    /// @param epochId defines the epoch to claim from.
    /// @param account is the account to claim the funds for.
    /// @param funds are the amounts to claim.
    /// @param multiProof is the proof for the epoch claim.
    function claimEpoch(
        uint256 epochId,
        address account,
        Funds[] calldata funds,
        MultiProof calldata multiProof
    ) public whenNotPaused {
        uint256 fundsLen = funds.length;
        if (fundsLen == 0) {
            revert NoFundsProvided();
        }
        _claimAllocations(account, epochId, funds, multiProof);
        for (uint256 i = 0; i < fundsLen; ) {
            _disburse(account, funds[i].token, funds[i].amount);
            unchecked {
                i++;
            }
        }
    }

    /// @notice claim funds from multiple epochs, only when the campaign is not paused. If any claim is invalid the tx is reverted.
    /// @param epochIds defines the epochs to claim from.
    /// @param account is the account to claim the funds for.
    /// @param funds is the amounts to claim per token per epoch.
    /// @param multiProofs defines the proofs the for the claims.
    function claimEpochs(
        uint256[] calldata epochIds,
        address account,
        Funds[][] calldata funds,
        MultiProof[] calldata multiProofs
    ) external whenNotPaused {
        uint256 numEpochs = epochIds.length;
        if (numEpochs != funds.length || numEpochs != multiProofs.length) {
            revert InvalidClaimInputs(
                numEpochs,
                funds.length,
                multiProofs.length
            );
        }

        // claim every epoch individually
        for (uint256 i = 0; i < numEpochs; ) {
            claimEpoch(epochIds[i], account, funds[i], multiProofs[i]);
            unchecked {
                i++;
            }
        }
    }

    /// @notice verifies whether the claims for an epoch are valid.
    /// @param epochId defines the epoch to claim from.
    /// @param account is the account to claim the funds for.
    /// @param funds are the funds to claim.
    /// @param multiProof is the multiProof for the epoch claim.
    function verifyClaims(
        uint256 epochId,
        address account,
        Funds[] calldata funds,
        MultiProof calldata multiProof
    ) public view returns (bool valid) {
        return _verifyClaims(epochId, account, funds, multiProof);
    }

    /// @notice marks a claim as claimed.
    /// @param epochId defines the epoch to mark as claimed.
    /// @param account is the account who claimed.
    /// @param funds are the funds claimed.
    /// @param multiProof is the multiProof for the claim.
    function _claimAllocations(
        address account,
        uint256 epochId,
        Funds[] calldata funds,
        MultiProof calldata multiProof
    ) private {
        if (epochId > epochCount) {
            revert EpochInTheFuture(epochId);
        }

        if (claimed[epochId][account]) {
            revert RewardsAlreadyClaimed(epochId, account);
        }
        uint256 fundsLen = funds.length;
        for (uint256 i = 0; i < fundsLen; ) {
            if (funds[i].amount > budgets[funds[i].token]) {
                revert InsufficientFunds(
                    budgets[funds[i].token],
                    funds[i].amount
                );
            }
            unchecked {
                i++;
            }
        }

        require(
            _verifyClaims(epochId, account, funds, multiProof),
            "InvalidProof"
        );

        claimed[epochId][account] = true;

        emit EpochClaimed(account, epochId, funds);
    }

    /// @notice verifies whether the merkle multiProof is valid, and the account hasn't claimed.
    /// @param epochId defines the epoch to claim from.
    /// @param account is the account to claim the funds for.
    /// @param funds are the funds to claim.
    /// @param multiProof is the mutliproof for the epoch claim.
    function _verifyClaims(
        uint256 epochId,
        address account,
        Funds[] calldata funds,
        MultiProof calldata multiProof
    ) private view returns (bool valid) {
        uint256 fundsLen = funds.length;
        if (fundsLen == 0) {
            revert NoFundsProvided();
        }
        bytes32[] memory leaves = new bytes32[](fundsLen);
        for (uint256 i = 0; i < fundsLen; ) {
            // double hashed for better resistance to (second) pre-image attacks
            bytes32 leaf = keccak256(
                abi.encode(
                    keccak256(
                        abi.encode(funds[i].amount, funds[i].token, account)
                    )
                )
            );
            leaves[i] = leaf;
            unchecked {
                i++;
            }
        }
        return
            MerkleProof.multiProofVerifyCalldata(
                multiProof.merkleProof,
                multiProof.proofFlags,
                merkleRoots[epochId],
                leaves
            ) && !claimed[epochId][account];
    }

    /// @notice transfers "amount" to "account".
    /// @param account is the account to transfer funds to.
    /// @param token is the token to transfer.
    /// @param amount is the amount to transfer.
    function _disburse(address account, IERC20 token, uint256 amount) private {
        if (amount > 0 && amount <= budgets[token]) {
            budgets[token] -= amount;
            token.safeTransfer(account, amount);
        } else {
            revert("No balance");
        }
    }

    /// @notice returns the tokens the campaign is using.
    function getTokens() public view returns (address[] memory) {
        address[] memory _tokens = new address[](numTokens);

        uint256 index = 0;
        address currentToken = tokens[SENTINEL_TOKEN];
        while (currentToken != SENTINEL_TOKEN) {
            // set the current token at the current index
            _tokens[index] = currentToken;
            // currentToken now is the next token in the "linked list"
            currentToken = tokens[currentToken];
            index++;
        }
        return _tokens;
    }

    /// @notice pauses the contract.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpauses the contract.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice utility function for withdrawing stuck ERC20s or unused budget
    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyRemoveFundsManagers {
        if (amount > token.balanceOf(address(this))) {
            revert InsufficientFunds(token.balanceOf(address(this)), amount);
        }

        token.safeTransfer(to, amount);
        emit RemovedFunds(msg.sender, Funds(token, amount));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract SigCampaign is EIP712, Ownable, Pausable {
  using SafeERC20 for IERC20;

  /// @notice the token to be used for the rewards.
  IERC20 public immutable token;

  /// @notice the campaign budget.
  uint256 public budget;

  /// @notice whether a given address has claimed their rewards or not.
  /// @dev maps nonce => claimer => isClaimed
  mapping(uint256 => mapping(address => bool)) public isClaimed;

  event Received(address indexed sender, uint256 amount);
  event Claim(address indexed claimer, uint256 amount);
  event AddedFunds(address indexed sender, uint256 amount);

  /// @notice Creates a new signature-based (paused) campaign.
  /// @param _token the ERC20 token to be used for this campaign.
  constructor(IERC20 _token) EIP712("campaign", "1.0.0") {
    token = _token;
    _pause();
  }

  /// @notice claim the rewarded amount from the campaign.
  /// @param nonce defines the nonce of the signature
  /// @param account defines the account that is rewarded the tokens.
  /// @param amount defines the amount to be claimed, MUST match the amount rewarded to the account.
  /// @param signature is the proof for the reward, MUST be for the (amount, account) pair above.
  function claim(
    uint256 nonce,
    address account,
    uint256 amount,
    bytes calldata signature
  ) external whenNotPaused {
    require(!isClaimed[nonce][account], "Rewards already claimed.");
    require(budget >= amount, "Not enough funds in campaign.");

    require(
      _verify(_hash(amount, account, nonce), signature),
      "Invalid signature."
    );

    budget -= amount;
    isClaimed[nonce][account] = true;
    IERC20(token).safeTransfer(account, amount);
    emit Claim(account, amount);
  }

  function _hash(
    uint256 amount,
    address account,
    uint256 nonce
  ) internal view returns (bytes32) {
    return
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256("Reward(uint256 amount,address account,uint256 nonce)"),
            amount,
            account,
            nonce
          )
        )
      );
  }

  function _verify(bytes32 digest, bytes memory signature)
    internal
    view
    returns (bool)
  {
    return SignatureChecker.isValidSignatureNow(owner(), digest, signature);
  }

  /// @notice transfers {amount} from the tx sender to the campaign address
  /// @param amount defines the amount to transfers.
  function addFunds(uint256 amount) external onlyOwner {
    // transfer the amount  to the campaign.
    IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    budget += amount;

    if (paused()) {
      _unpause();
    }

    emit AddedFunds(msg.sender, amount);
  }

  /// @notice pauses the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice unpauses the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice fallback function for ETH transfers.
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /// @notice utility function for withdrawing stuck ETH
  function withdrawETH() external onlyOwner {
    require(address(this).balance > 0, "Contract balance is zero.");
    (bool success, ) = msg.sender.call{ value: address(this).balance }("");
    require(success);
  }

  /// @notice utility function for withdrawing stuck ERC20s or unused budget
  function transferERC20(
    IERC20 _token,
    address to,
    uint256 amount
  ) external onlyOwner whenPaused {
    require(_token.balanceOf(address(this)) >= amount, "Not enough funds");
    uint256 budgetMem = budget; // assign budget to memory variable, to save on gas
    if (_token == token) {
      require(budgetMem >= amount, "Not enough budget");
      budgetMem -= amount;
    }
    budget = budgetMem; // assign memory variable back to budget
    _token.safeTransfer(to, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract SoulBoundPPT is ERC20, AccessControl {
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
  bytes32 public constant SLASH_ROLE = keccak256("SLASH_ROLE");

  constructor(uint256 initialSupply) ERC20("PostmintPointToken", "PPT") {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(MINTER_ROLE, msg.sender);
    _grantRole(TRANSFER_ROLE, msg.sender);
    _grantRole(SLASH_ROLE, msg.sender);
    _mint(msg.sender, initialSupply);
  }

  /// @notice guarded transfer to enable soul-bound non-transferrable token
  /// @param _to is the contract address receiving the tokens if unpaused
  /// @param _value is the amount of tokens transffered if unpaused
  function transfer(address _to, uint256 _value)
    public
    override
    onlyRole(TRANSFER_ROLE)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  /// @notice guarded transferFrom to enable soul-bound non-transferrable token
  /// @param _from is the address sending the tokens if unpaused
  /// @param _to is the address receiving the tokens if unpaused
  /// @param _value is the amount of tokens transffered if unpaused
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public override onlyRole(TRANSFER_ROLE) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /// @notice mintTo mints new PPT.
  /// @param receiver is the address receiving the tokens to be minted.
  /// @param amount is the amount of PPT to be minted.
  function mintTo(address receiver, uint256 amount)
    external
    onlyRole(MINTER_ROLE)
  {
    _mint(receiver, amount);
  }

  /// @notice slashes the balance of {account} by {amount}.
  /// @param account is the account getting slashed.
  /// @param amount is the amount to slash on {account}.
  function slash(address account, uint256 amount)
    external
    onlyRole(SLASH_ROLE)
  {
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract NewCampaign is Pausable {
  using SafeERC20 for IERC20;

  /// @notice whether it is initialized
  bool public isInitialized;

  /// @notice is in base points, ex: 1% in base points would be 100
  uint256 public commissionBp = 100;

  /// @notice the token to be used for the rewards.
  IERC20 public token;

  /// @notice the Merkle Tree Root hash.
  bytes32 public merkleRoot;

  /// @notice the postmint address, to which commissions will be transferred to.
  address public postmint;

  /// @notice the campaign budget.
  uint256 public budget;

  /// @notice the owner
  address public owner;

  /// @notice whether a given address has claimed their rewards or not.
  mapping(address => bool) public isClaimed;

  event Claim(address indexed claimer, uint256 amount);
  event Received(address, uint256);
  event AddedFunds(address index, uint256 amount);

  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  /// @notice Initialize a new (paused) epoch campaign.
  /// @param _token the ERC20 tokens to be used for this campaign.
  /// @param _creator the address of the campaign creator.
  /// @param _postmint the postmint address.
  function initialize(
    IERC20 _token,
    address _creator,
    address _postmint
  ) external {
    require(!isInitialized, "Already initialized");
    isInitialized = true;
    token = _token;
    owner = _creator;
    postmint = _postmint;
    commissionBp = 100;
    _pause();
  }

  /// @notice claim the rewarded amount from the campaign.
  /// @param account defines the account that is rewarded the tokens.
  /// @param amount defines the amount to be claimed, MUST match the amount rewarded to the account.
  /// @param merkleProof is the merkle proof for the reward, MUST be for the (amount, account) pair above.
  function claim(
    address account,
    uint256 amount,
    bytes32[] calldata merkleProof
  ) external whenNotPaused {
    require(!isClaimed[account], "Already claimed.");
    require(budget >= amount, "Not enough funds in campaign.");

    bytes32 node = keccak256(abi.encodePacked(amount, account));
    bool isValidProof = MerkleProof.verify(merkleProof, merkleRoot, node);
    require(isValidProof, "Invalid proof.");

    budget -= amount;
    isClaimed[account] = true;
    IERC20(token).safeTransfer(account, amount);
    emit Claim(account, amount);
  }

  /// @notice uploads Merkle Tree Root hash and unpauses, only the postmint address can invoke this. CAN only be invoked once!
  /// @param _merkleRoot is the root hash.
  function uploadRoot(bytes32 _merkleRoot) external onlyPostmint {
    require(merkleRoot == bytes32(0), "The merkle root is already set");
    merkleRoot = _merkleRoot;
    _unpause();
  }

  /// @notice checks whether the caller is postmint.
  modifier onlyPostmint() {
    require(msg.sender == postmint, "Caller is not the postmint account");
    _;
  }

  /// @notice updated the commission amount, only the postmint address can invoke this.
  /// @param _commissionBp is in base points, not percents, ex: 1% in base points would be 100.
  function updateCommission(uint256 _commissionBp) external onlyPostmint {
    require(
      _commissionBp > 0 && _commissionBp < 10000,
      "commissionBp must be between 0 and 10000"
    );
    commissionBp = _commissionBp;
  }

  /// @notice transfers {amount} from the tx sender to the campaign address, while taking commission for postmint.
  /// @param amount defines the amount to transfers.
  function addFunds(uint256 amount) external onlyOwner {
    // calculate commission
    uint256 commission = uint256((amount * commissionBp) / 10000);
    uint256 amountLeft = amount - commission;

    // transfer commission to postmint.
    IERC20(token).safeTransferFrom(msg.sender, postmint, commission);

    // transfer the amount left to the campaign.
    IERC20(token).safeTransferFrom(msg.sender, address(this), amountLeft);
    budget += amountLeft;

    emit AddedFunds(msg.sender, amount);
  }

  /// @notice pauses the contract.
  function pause() external onlyOwner {
    _pause();
  }

  /// @notice unpauses the contract.
  function unpause() external onlyOwner {
    _unpause();
  }

  /// @notice fallback function for ETH transfers.
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /// @notice utility function for withdrawing stuck ETH
  function withdrawETH() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  /// @notice utility function for withdrawing stuck ERC20s or unused budget
  function transferERC20(
    IERC20 _token,
    address to,
    uint256 amount
  ) external onlyOwner whenPaused {
    require(_token.balanceOf(address(this)) >= amount, "Not enough funds");
    if (_token == token) {
      require(budget >= amount, "Not enough budget");
      budget -= amount;
    }
    _token.safeTransfer(to, amount);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PostmintPointToken is Ownable, ERC20 {
    constructor(uint256 initialSupply) ERC20("PostmintPointToken", "PPT") {
        _mint(msg.sender, initialSupply);
    }

    /// @notice mintTo mints new PPT.
    /// @param receiver is the address receiving the tokens to be minted.
    /// @param amount is the amount of PPT to be minted.
    function mintTo(address receiver, uint256 amount) external onlyOwner {
        _mint(receiver, amount);
    }

    /// @notice slashes the balance of {account} by {amount}.
    /// @param account is the account getting slashed.
    /// @param amount is the amount to slash on {account}.
    function slash(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./EpochCampaignV2.sol";

contract CampaignFactoryV2 is Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @notice implementation of EpochCampaign to clone from
    address public epochCampaignImplementation;

    /// @notice the default commission for the created campaigns
    uint256 public defaultCommissionBp = 100;

    /// @notice helper variable for base point conversion.
    uint256 internal constant BASE = 10000;

    event EpochCampaignEvent(
        address indexed creator,
        address indexed campaignAddress,
        address indexed campaignImplementation
    );
    event UpdatedDefaultCommission(
        uint256 oldDefaultCommission,
        uint256 newDefaultCommission
    );
    event UpgradedEpochCampaign(
        address oldEpochCampaignImplementation,
        address newEpochCampaignImplementation
    );
    error InvalidDefaultCommissionInput(
        uint256 commissionBp,
        uint256 minCommissionBp,
        uint256 maxCommissionBp
    );
    error InvalidContractAddress(address invalidAddress);

    constructor() {
        epochCampaignImplementation = address(new EpochCampaignV2());
    }

    /// @notice set new Epoch Campaign Implementation
    /// @param _newEpochCampaignImplementation defines the address of the new Epoch Campaign Implementation
    function setEpochCampaignImplementation(
        address _newEpochCampaignImplementation
    ) external onlyOwner {
        if (
            _newEpochCampaignImplementation == address(0) ||
            _newEpochCampaignImplementation.code.length == 0
        ) {
            revert InvalidContractAddress(_newEpochCampaignImplementation);
        }
        address oldEpochCampaignImplementation = epochCampaignImplementation;
        epochCampaignImplementation = _newEpochCampaignImplementation;
        emit UpgradedEpochCampaign(
            oldEpochCampaignImplementation,
            _newEpochCampaignImplementation
        );
    }

    /// @notice creates a new Epoch campaign.
    /// @param tokens defines the ERC20 contract addresses to be used in the campaign contract.
    function createEpochCampaign(
        IERC20[] calldata tokens
    ) external whenNotPaused returns (address) {
        // This will prevent creating the same campaign twice (with the same reward tokens, owner, postmint address and PPT Allocator)
        bytes32 salt = keccak256(abi.encodePacked(tokens, msg.sender, owner()));

        address payable clone = payable(
            Clones.cloneDeterministic(epochCampaignImplementation, salt)
        );
        EpochCampaignV2(clone).initialize(
            tokens,
            msg.sender,
            owner(),
            defaultCommissionBp
        );

        emit EpochCampaignEvent(msg.sender, clone, epochCampaignImplementation);

        return clone;
    }

    function predictCampaignAddress(
        IERC20[] calldata tokens,
        address deployer
    ) external view returns (address predicted) {
        bytes32 salt = keccak256(abi.encodePacked(tokens, deployer, owner()));
        return
            Clones.predictDeterministicAddress(
                epochCampaignImplementation,
                salt
            );
    }

    /// @notice set the default commission
    /// @param _defaultCommissionBp defines the default commission in basis points
    function setDefaultCommission(
        uint256 _defaultCommissionBp
    ) external onlyOwner {
        if (_defaultCommissionBp > BASE) {
            revert InvalidDefaultCommissionInput(_defaultCommissionBp, 0, BASE);
        }
        uint256 oldDefaultCommission = defaultCommissionBp;
        defaultCommissionBp = _defaultCommissionBp;
        emit UpdatedDefaultCommission(
            oldDefaultCommission,
            _defaultCommissionBp
        );
    }

    /// @notice pauses the factory.
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice unpauses the factory.
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice utility function for withdrawing stuck ERC20s
    function transferERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough funds");
        token.safeTransfer(to, amount);
    }
}