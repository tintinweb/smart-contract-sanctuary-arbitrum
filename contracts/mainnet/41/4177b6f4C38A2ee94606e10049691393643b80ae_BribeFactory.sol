// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/Clones.sol)

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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity 0.8.12;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IBribeMarket} from "./interfaces/IBribeMarket.sol";
import {IBribeVault} from "./interfaces/IBribeVault.sol";
import {Errors} from "./libraries/Errors.sol";

contract BribeFactory is Ownable2Step {
    address public bribeMarketImplementation;
    address public bribeVault;
    uint256 public constant MAX_PERIODS = 10;
    uint256 public constant MAX_PERIOD_DURATION = 30 days;

    event BribeMarketCreated(address indexed bribeMarket);
    event BribeMarketImplementationUpdated(
        address indexed bribeMarketImplementation
    );
    event BribeVaultUpdated(address indexed bribeVault);

    /**
        @notice Check if the specified address is a contract
        @param  _address  Address to be checked
     */
    modifier isContract(address _address) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }
        if (codeSize == 0) revert Errors.NotAContract();
        _;
    }

    /**
        @param  _implementation  Address of the implementation contract
        @param  _bribeVault      Address of the bribe vault
     */
    constructor(address _implementation, address _bribeVault) {
        _setBribeMarketImplementation(_implementation);
        _setBribeVault(_bribeVault);
    }

    /**
        @notice Deploy a new bribe market
        @param  _protocol        address  Market name/identifier
        @param  _maxPeriods      uint256  Maximum number of periods for bribe deposits
        @param  _periodDuration  uint256  Period duration in each voting round
     */
    function createBribeMarket(
        string calldata _protocol,
        uint256 _maxPeriods,
        uint256 _periodDuration
    ) external returns (address) {
        if (_maxPeriods == 0 || _maxPeriods > MAX_PERIODS)
            revert Errors.InvalidMaxPeriod();
        if (_periodDuration == 0 || _periodDuration > MAX_PERIOD_DURATION)
            revert Errors.InvalidPeriodDuration();

        address bribeMarket = Clones.clone(bribeMarketImplementation);

        IBribeMarket(bribeMarket).initialize(
            bribeVault,
            msg.sender,
            _protocol,
            _maxPeriods,
            _periodDuration
        );
        IBribeVault(bribeVault).grantDepositorRole(bribeMarket);

        emit BribeMarketCreated(bribeMarket);

        return bribeMarket;
    }

    /**
        @notice Set the bribe market implementation address
        @param  _implementation  address  Implementation address
     */
    function setBribeMarketImplementation(
        address _implementation
    ) external onlyOwner {
        _setBribeMarketImplementation(_implementation);

        emit BribeMarketImplementationUpdated(_implementation);
    }

    /**
        @notice Set the bribe vault address
        @param  _bribeVault  address  Bribe vault address
     */
    function setBribeVault(address _bribeVault) external onlyOwner {
        _setBribeVault(_bribeVault);

        emit BribeVaultUpdated(_bribeVault);
    }

    /**
        @notice Internal method to set the bribe market implementation address
        @param  _implementation  address  Implementation address
     */
    function _setBribeMarketImplementation(
        address _implementation
    ) internal isContract(_implementation) {
        bribeMarketImplementation = _implementation;
    }

    /**
        @notice Internal method to set the bribe vault address
        @param  _bribeVault  address  Bribe vault address
     */
    function _setBribeVault(
        address _bribeVault
    ) internal isContract(_bribeVault) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_bribeVault)
        }
        if (codeSize == 0) revert Errors.NotAContract();

        bribeVault = _bribeVault;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IBribeMarket {
    /**
        @notice Initialize the contract
        @param  _bribeVault  Bribe vault address
        @param  _admin       Admin address
        @param  _protocol    Protocol name
        @param  _maxPeriods  Maximum number of periods
        @param  _periodDuration  Period duration
     */
    function initialize(
        address _bribeVault,
        address _admin,
        string calldata _protocol,
        uint256 _maxPeriods,
        uint256 _periodDuration
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "../libraries/Common.sol";

interface IBribeVault {
    /**
        @notice Deposit bribe (ERC20 only)
        @param  _depositParams  DepositBribeParams  Deposit data
     */
    function depositBribe(
        Common.DepositBribeParams calldata _depositParams
    ) external;

    /**
        @notice Get bribe information based on the specified identifier
        @param  _bribeIdentifier  bytes32  The specified bribe identifier
     */
    function getBribe(
        bytes32 _bribeIdentifier
    ) external view returns (address token, uint256 amount);

    /**
        @notice Transfer fees to fee recipient and bribes to distributor and update rewards metadata
        @param  _rewardIdentifiers  bytes32[]  List of rewardIdentifiers
     */
    function transferBribes(bytes32[] calldata _rewardIdentifiers) external;

    /**
        @notice Grant the depositor role to an address
        @param  _depositor  address  Address to grant the depositor role
     */
    function grantDepositorRole(address _depositor) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Common {
    /**
     * @param identifier  bytes32  Identifier of the distribution
     * @param token       address  Address of the token to distribute
     * @param merkleRoot  bytes32  Merkle root of the distribution
     * @param proof       bytes32  Proof of the distribution
     */
    struct Distribution {
        bytes32 identifier;
        address token;
        bytes32 merkleRoot;
        bytes32 proof;
    }

    /**
     * @param proposal          bytes32  Proposal to bribe
     * @param token             address  Token to bribe with
     * @param briber            address  Address of the briber
     * @param amount            uint256  Amount of tokens to bribe with
     * @param maxTokensPerVote  uint256  Maximum amount of tokens to use per vote
     * @param periods           uint256  Number of periods to bribe for
     * @param periodDuration    uint256  Duration of each period
     * @param proposalDeadline  uint256  Deadline for the proposal
     * @param permitDeadline    uint256  Deadline for the permit2 signature
     * @param signature         bytes    Permit2 signature
     */
    struct DepositBribeParams {
        bytes32 proposal;
        address token;
        address briber;
        uint256 amount;
        uint256 maxTokensPerVote;
        uint256 periods;
        uint256 periodDuration;
        uint256 proposalDeadline;
        uint256 permitDeadline;
        bytes signature;
    }

    /**
     * @param rwIdentifier      bytes32    Identifier for claiming reward
     * @param fromToken         address    Address of token to swap from
     * @param toToken           address    Address of token to swap to
     * @param fromAmount        uint256    Amount of fromToken to swap
     * @param toAmount          uint256    Amount of toToken to receive
     * @param deadline          uint256    Timestamp until which swap may be fulfilled
     * @param callees           address[]  Array of addresses to call (DEX addresses)
     * @param callLengths       uint256[]  Index of the beginning of each call in exchangeData
     * @param values            uint256[]  Array of encoded values for each call in exchangeData
     * @param exchangeData      bytes      Calldata to execute on callees
     * @param rwMerkleProof     bytes32[]  Merkle proof for the reward claim
     */
    struct ClaimAndSwapData {
        bytes32 rwIdentifier;
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        uint256 deadline;
        address[] callees;
        uint256[] callLengths;
        uint256[] values;
        bytes exchangeData;
        bytes32[] rwMerkleProof;
    }

    /**
     * @param identifier   bytes32    Identifier for claiming reward
     * @param account      address    Address of the account to claim for
     * @param amount       uint256    Amount of tokens to claim
     * @param merkleProof  bytes32[]  Merkle proof for the reward claim
     */
    struct Claim {
        bytes32 identifier;
        address account;
        uint256 amount;
        bytes32[] merkleProof;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

library Errors {
    /**
     * @notice max period 0 or greater than MAX_PERIODS
     */
    error InvalidMaxPeriod();

    /**
     * @notice period duration 0 or greater than MAX_PERIOD_DURATION
     */
    error InvalidPeriodDuration();

    /**
     * @notice address provided is not a contract
     */
    error NotAContract();

    /**
     * @notice not authorized
     */
    error NotAuthorized();

    /**
     * @notice contract already initialized
     */
    error AlreadyInitialized();

    /**
     * @notice address(0)
     */
    error InvalidAddress();

    /**
     * @notice empty bytes identifier
     */
    error InvalidIdentifier();

    /**
     * @notice invalid protocol name
     */
    error InvalidProtocol();

    /**
     * @notice invalid number of choices
     */
    error InvalidChoiceCount();

    /**
     * @notice invalid input amount
     */
    error InvalidAmount();

    /**
     * @notice not team member
     */
    error NotTeamMember();

    /**
     * @notice cannot whitelist BRIBE_VAULT
     */
    error NoWhitelistBribeVault();

    /**
     * @notice token already whitelisted
     */
    error TokenWhitelisted();

    /**
     * @notice token not whitelisted
     */
    error TokenNotWhitelisted();

    /**
     * @notice voter already blacklisted
     */
    error VoterBlacklisted();

    /**
     * @notice voter not blacklisted
     */
    error VoterNotBlacklisted();

    /**
     * @notice deadline has passed
     */
    error DeadlinePassed();

    /**
     * @notice invalid period
     */
    error InvalidPeriod();

    /**
     * @notice invalid deadline
     */
    error InvalidDeadline();

    /**
     * @notice invalid max fee
     */
    error InvalidMaxFee();

    /**
     * @notice invalid fee
     */
    error InvalidFee();

    /**
     * @notice invalid fee recipient
     */
    error InvalidFeeRecipient();

    /**
     * @notice invalid distributor
     */
    error InvalidDistributor();

    /**
     * @notice invalid briber
     */
    error InvalidBriber();

    /**
     * @notice address does not have DEPOSITOR_ROLE
     */
    error NotDepositor();

    /**
     * @notice no array given
     */
    error InvalidArray();

    /**
     * @notice invalid reward identifier
     */
    error InvalidRewardIdentifier();

    /**
     * @notice bribe has already been transferred
     */
    error BribeAlreadyTransferred();

    /**
     * @notice distribution does not exist
     */
    error InvalidDistribution();

    /**
     * @notice invalid merkle root
     */
    error InvalidMerkleRoot();

    /**
     * @notice token is address(0)
     */
    error InvalidToken();

    /**
     * @notice claim does not exist
     */
    error InvalidClaim();

    /**
     * @notice reward is not yet active for claiming
     */
    error RewardInactive();

    /**
     * @notice timer duration is invalid
     */
    error InvalidTimerDuration();

    /**
     * @notice merkle proof is invalid
     */
    error InvalidProof();

    /**
     * @notice ETH transfer failed
     */
    error ETHTransferFailed();

    /**
     * @notice Invalid operator address
     */
    error InvalidOperator();

    /**
     * @notice call to TokenTransferProxy contract
     */
    error TokenTransferProxyCall();

    /**
     * @notice calling TransferFrom
     */
    error TransferFromCall();

    /**
     * @notice external call failed
     */
    error ExternalCallFailure();

    /**
     * @notice returned tokens too few
     */
    error InsufficientReturn();

    /**
     * @notice swapDeadline expired
     */
    error DeadlineBreach();

    /**
     * @notice expected tokens returned are 0
     */
    error ZeroExpectedReturns();

    /**
     * @notice arrays in SwapData.exchangeData have wrong lengths
     */
    error ExchangeDataArrayMismatch();
}