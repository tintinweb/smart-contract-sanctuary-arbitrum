// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { StorageSlotUpgradeable as StorageSlot } from "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

import "../interfaces/frabric/IBond.sol";
import "../interfaces/thread/IThreadDeployer.sol";
import "../interfaces/thread/IThread.sol";

import "../dao/FrabricDAO.sol";

import "../interfaces/frabric/IInitialFrabric.sol";
import "../interfaces/frabric/IFrabric.sol";

contract Frabric is FrabricDAO, IFrabricUpgradeable {
  using ERC165Checker for address;

  mapping(address => ParticipantType) public override participant;
  mapping(address => GovernorStatus) public override governor;

  address public override bond;
  address public override threadDeployer;

  struct Participant {
    ParticipantType pType;
    address addr;
  }
  // The proposal structs are private as their events are easily grabbed and contain the needed information
  mapping(uint256 => Participant) private _participants;

  struct BondRemoval {
    address governor;
    bool slash;
    uint256 amount;
  }
  mapping(uint256 => BondRemoval) private _bondRemovals;

  struct Thread {
    uint8 variant;
    address governor;
    // This may not actually pack yet it's small enough to theoretically
    string symbol;
    bytes32 descriptor;
    string name;
    bytes data;
  }
  mapping(uint256 => Thread) private _threads;

  struct ThreadProposalStruct {
    address thread;
    bytes4 selector;
    bytes data;
  }
  mapping(uint256 => ThreadProposalStruct) private _threadProposals;

  mapping(address => uint256) public override vouchers;

  mapping(uint16 => bytes4) private _proposalSelectors;

  function validateUpgrade(uint256 _version, bytes calldata data) external view override {
    if (_version != 2) {
      revert InvalidVersion(_version, 2);
    }

    (address _bond, address _threadDeployer, ) = abi.decode(data, (address, address, address));
    if (!_bond.supportsInterface(type(IBondCore).interfaceId)) {
      revert UnsupportedInterface(_bond, type(IBondCore).interfaceId);
    }
    if (!_threadDeployer.supportsInterface(type(IThreadDeployer).interfaceId)) {
      revert UnsupportedInterface(_threadDeployer, type(IThreadDeployer).interfaceId);
    }
  }

  function _changeParticipant(address _participant, ParticipantType pType) private {
    participant[_participant] = pType;
    emit ParticipantChange(pType, _participant);
  }

  function _changeParticipantAndKYC(address _participant, ParticipantType pType, bytes32 kycHash) private {
    _changeParticipant(_participant, pType);
    IFrabricWhitelistCore(erc20).setKYC(_participant, kycHash, 0);
  }

  function _whitelistAndAdd(address _participant, ParticipantType pType, bytes32 kycHash) private {
    IFrabricWhitelistCore(erc20).whitelist(_participant);
    _changeParticipantAndKYC(_participant, pType, kycHash);
  }

  function _addKYC(address kyc) private {
    _whitelistAndAdd(kyc, ParticipantType.KYC, keccak256(abi.encodePacked("KYC ", kyc)));
  }

  function upgrade(uint256 _version, bytes calldata data) external override {
    address beacon = StorageSlot.getAddressSlot(
      // Beacon storage slot
      0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50
    ).value;
    if (msg.sender != beacon) {
      revert NotBeacon(msg.sender, beacon);
    }

    // While this isn't possible for this version (2), it is possible if this was
    // code version 3 yet triggerUpgrade was never called for version 2
    // In that scenario, this could be called with version 2 data despite expecting
    // version 3 data
    if (_version != (version + 1)) {
      revert InvalidVersion(_version, version + 1);
    }
    version++;

    // Drop support for IInitialFrabric
    // While we do still match it, and it shouldn't hurt to keep it around,
    // we never want to encourage its usage, nor do we want to forget about it
    // if we ever do introduce an incompatibility
    supportsInterface[type(IInitialFrabric).interfaceId] = false;

    // Add support for the new Frabric interfaces
    supportsInterface[type(IFrabricCore).interfaceId] = true;
    supportsInterface[type(IFrabric).interfaceId] = true;

    // Set bond, threadDeployer, and an initial KYC/governor
    address kyc;
    address _governor;
    (bond, threadDeployer, kyc, _governor) = abi.decode(data, (address, address, address, address));

    _addKYC(kyc);

    _whitelistAndAdd(_governor, ParticipantType.Governor, keccak256("Initial Governor"));
    governor[_governor] = GovernorStatus.Active;

    _proposalSelectors[uint16(CommonProposalType.Paper)       ^ commonProposalBit] = IFrabricDAO.proposePaper.selector;
    _proposalSelectors[uint16(CommonProposalType.Upgrade)     ^ commonProposalBit] = IFrabricDAO.proposeUpgrade.selector;
    _proposalSelectors[uint16(CommonProposalType.TokenAction) ^ commonProposalBit] = IFrabricDAO.proposeTokenAction.selector;

    _proposalSelectors[uint16(IThread.ThreadProposalType.DescriptorChange)] = IThread.proposeDescriptorChange.selector;
    _proposalSelectors[uint16(IThread.ThreadProposalType.GovernorChange)]   = IThread.proposeGovernorChange.selector;
    _proposalSelectors[uint16(IThread.ThreadProposalType.Dissolution)]      = IThread.proposeDissolution.selector;

    // Correct the voting time as well
    votingPeriod = 1 weeks;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() Composable("Frabric") initializer {
    // Only set in the constructor as this has no value being in the live contract
    supportsInterface[type(IUpgradeable).interfaceId] = true;
  }

  function canPropose(address proposer) public view override(DAO, IDAOCore) returns (bool) {
    return uint8(participant[proposer]) >= uint8(ParticipantType.Genesis);
  }

  function proposeParticipant(
    ParticipantType participantType,
    address _participant,
    bytes32 info
  ) external override returns (uint256 id) {
    if (
      (participantType < ParticipantType.KYC) ||
      (ParticipantType.Voucher < participantType)
    ) {
      revert InvalidParticipantType(participantType);
    }

    if (
      (participant[_participant] != ParticipantType.Null) ||
      IFrabricWhitelistCore(erc20).whitelisted(_participant)
    ) {
      revert ParticipantAlreadyApproved(_participant);
    }

    id = _createProposal(uint16(FrabricProposalType.Participant), false, info);
    _participants[id] = Participant(participantType, _participant);
    emit ParticipantProposal(id, participantType, msg.sender, _participant);
  }

  function proposeBondRemoval(
    address _governor,
    bool slash,
    uint256 amount,
    bytes32 info
  ) external override returns (uint256 id) {
    id = _createProposal(uint16(FrabricProposalType.RemoveBond), false, info);
    _bondRemovals[id] = BondRemoval(_governor, slash, amount);
    if (governor[_governor] < GovernorStatus.Active) {
      // Arguably a misuse as this actually checks they were never an active governor
      // Not that they aren't currently an active governor, which the error name suggests
      // This should be better to handle from an integration perspective however
      revert NotActiveGovernor(_governor, governor[_governor]);
    }
    emit BondRemovalProposal(id, _governor, slash, amount);
  }

  function proposeThread(
    uint8 variant,
    string calldata name,
    string calldata symbol,
    bytes32 descriptor,
    bytes calldata data,
    bytes32 info
  ) external override returns (uint256 id) {
    if (version < 2) {
      revert NotUpgraded(version, 2);
    }

    if (governor[msg.sender] != GovernorStatus.Active) {
      revert NotActiveGovernor(msg.sender, governor[msg.sender]);
    }

    // Doesn't check for being alphanumeric due to iteration costs
    if (
      (bytes(name).length < 6) || (bytes(name).length > 64) ||
      (bytes(symbol).length < 2) || (bytes(symbol).length > 5)
    ) {
      revert InvalidName(name, symbol);
    }
    // Validate the data now before creating the proposal
    // ThreadProposal doesn't have this same level of validation yet not only are
    // Threads a far more integral part of the system, ThreadProposal deals with an enum
    // for proposal type. This variant field is a uint256 which has a much larger impact scope
    IThreadDeployer(threadDeployer).validate(variant, data);

    id = _createProposal(uint16(FrabricProposalType.Thread), false, info);
    Thread storage proposal = _threads[id];
    proposal.variant = variant;
    proposal.name = name;
    proposal.symbol = symbol;
    proposal.descriptor = descriptor;
    proposal.governor = msg.sender;
    proposal.data = data;
    emit ThreadProposal(id, variant, msg.sender, name, symbol, descriptor, data);
  }

  // This does assume the Thread's API meets expectations compiled into the Frabric
  // They can individually change their Frabric, invalidating this entirely, or upgrade their code, potentially breaking specific parts
  // These are both valid behaviors intended to be accessible by Threads
  function proposeThreadProposal(
    address thread,
    uint16 _proposalType,
    bytes calldata data,
    bytes32 info
  ) external returns (uint256 id) {
    // Technically not needed given we check for interface support, yet a healthy check to have
    if (IComposable(thread).contractName() != keccak256("Thread")) {
      revert DifferentContract(IComposable(thread).contractName(), keccak256("Thread"));
    }

    // Lock down the selector to prevent arbitrary calls
    // While data is still arbitrary, it has reduced scope thanks to this, and can only be decoded in expected ways
    // data isn't validated to be technically correct as the UI is trusted to sanity check it
    // and present it accurately for humans to deliberate on
    bytes4 selector;
    if (_isCommonProposal(_proposalType)) {
      if (!thread.supportsInterface(type(IFrabricDAO).interfaceId)) {
        revert UnsupportedInterface(thread, type(IFrabricDAO).interfaceId);
      }
    } else {
      if (!thread.supportsInterface(type(IThread).interfaceId)) {
        revert UnsupportedInterface(thread, type(IThread).interfaceId);
      }
    }
    selector = _proposalSelectors[_proposalType];
    if (selector == bytes4(0)) {
      revert UnhandledEnumCase("Frabric proposeThreadProposal", _proposalType);
    }

    id = _createProposal(uint16(FrabricProposalType.ThreadProposal), false, info);
    _threadProposals[id] = ThreadProposalStruct(thread, selector, data);
    emit ThreadProposalProposal(id, thread, _proposalType, data);
  }

  function _participantRemoval(address _participant) internal override {
    if (governor[_participant] != GovernorStatus.Null) {
      governor[_participant] = GovernorStatus.Removed;
    }
    _changeParticipant(_participant, ParticipantType.Removed);
  }

  function _completeSpecificProposal(uint256 id, uint256 _pType) internal override {
    FrabricProposalType pType = FrabricProposalType(_pType);
    if (pType == FrabricProposalType.Participant) {
      Participant storage _participant = _participants[id];
      // This check also exists in proposeParticipant, yet that doesn't prevent
      // the same participant from being proposed multiple times simultaneously
      // This is an edge case which should never happen, yet handling it means
      // checking here to ensure if they already exist, they're not overwritten
      // While we could error here, we may as well delete the invalid proposal and move on with life
      if (participant[_participant.addr] != ParticipantType.Null) {
        delete _participants[id];
        return;
      }

      if (_participant.pType == ParticipantType.KYC) {
        _addKYC(_participant.addr);
        delete _participants[id];
      } else {
        // Whitelist them until they're KYCd
        IFrabricWhitelistCore(erc20).whitelist(_participant.addr);
      }

    } else if (pType == FrabricProposalType.RemoveBond) {
      if (version < 2) {
        revert NotUpgraded(version, 2);
      }

      BondRemoval storage remove = _bondRemovals[id];
      if (remove.slash) {
        IBondCore(bond).slash(remove.governor, remove.amount);
      } else {
        IBondCore(bond).unbond(remove.governor, remove.amount);
      }
      delete _bondRemovals[id];

    } else if (pType == FrabricProposalType.Thread) {
      Thread storage proposal = _threads[id];
      // This governor may no longer be viable for usage yet the Thread will check
      // When proposing this proposal type, we validate we upgraded which means this has been set
      IThreadDeployer(threadDeployer).deploy(
        proposal.variant, proposal.name, proposal.symbol, proposal.descriptor, proposal.governor, proposal.data
      );
      delete _threads[id];

    } else if (pType == FrabricProposalType.ThreadProposal) {
      ThreadProposalStruct storage proposal = _threadProposals[id];
      (bool success, bytes memory data) = proposal.thread.call(
        abi.encodePacked(proposal.selector, proposal.data)
      );
      if (!success) {
        revert ExternalCallFailed(proposal.thread, proposal.selector, data);
      }
      delete _threadProposals[id];
    } else {
      revert UnhandledEnumCase("Frabric _completeSpecificProposal", _pType);
    }
  }

  function vouch(address _participant, bytes calldata signature) external override {
    // Places signer in a variable to make the information available for the error
    // While generally, the errors include an abundance of information with the expectation they'll be caught in a call,
    // and even if they are executed on chain, we don't care about the increased gas costs for the extreme minority,
    // this calculation is extensive enough it's worth the variable (which shouldn't even change gas costs?)
    address signer = ECDSA.recover(
      _hashTypedDataV4(
        keccak256(
          abi.encode(keccak256("Vouch(address participant)"), _participant)
        )
      ),
      signature
    );

    if (!IFrabricWhitelistCore(erc20).hasKYC(signer)) {
      revert NotKYC(signer);
    }

    if (participant[signer] != ParticipantType.Voucher) {
      // Declared optimal growth number
      if (vouchers[signer] == 6) {
        revert OutOfVouchers(signer);
      }
      vouchers[signer] += 1;
    }

    // The fact whitelist can only be called once for a given participant makes this secure against replay attacks
    IFrabricWhitelistCore(erc20).whitelist(_participant);
    emit Vouch(signer, _participant);
  }

  function approve(
    ParticipantType pType,
    address approving,
    bytes32 kycHash,
    bytes calldata signature
  ) external override {
    if ((pType == ParticipantType.Null) && passed[uint160(approving)]) {
      address temp = _participants[uint160(approving)].addr;
      if (temp == address(0)) {
        // While approving is actually a proposal ID, it's the most info we have
        revert ParticipantAlreadyApproved(approving);
      }
      pType = _participants[uint160(approving)].pType;
      delete _participants[uint160(approving)];
      approving = temp;
    } else if ((pType != ParticipantType.Individual) && (pType != ParticipantType.Corporation)) {
      revert InvalidParticipantType(pType);
    }

    address signer = ECDSA.recover(
      _hashTypedDataV4(
        keccak256(
          abi.encode(
            keccak256("KYCVerification(uint8 participantType,address participant,bytes32 kyc,uint256 nonce)"),
            pType,
            approving,
            kycHash,
            0 // For now, don't allow updating KYC hashes
          )
        )
      ),
      signature
    );
    if (participant[signer] != ParticipantType.KYC) {
      revert InvalidKYCSignature(signer, participant[signer]);
    }

    if (participant[approving] != ParticipantType.Null) {
      revert ParticipantAlreadyApproved(approving);
    }

    _changeParticipantAndKYC(approving, pType, kycHash);
    if (pType == ParticipantType.Governor) {
      governor[approving] = GovernorStatus.Active;
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IComposable.sol";

import "../erc20/IDistributionERC20.sol";

import "../frabric/IFrabric.sol";

interface IBondCore is IComposable {
  event Unbond(address governor, uint256 amount);
  event Slash(address governor, uint256 amount);

  function unbond(address bonder, uint256 amount) external;
  function slash(address bonder, uint256 amount) external;
}

interface IBond is IBondCore, IDistributionERC20 {
  event Bond(address governor, uint256 amount);

  function usd() external view returns (address);
  function bondToken() external view returns (address);

  function bond(uint256 amount) external;

  function recover(address token) external;
}

interface IBondInitializable is IBond {
  function initialize(address usd, address bond) external;
}

error BondTransfer();
error NotActiveGovernor(address governor, IFrabric.GovernorStatus status);
// Obvious, yet tells people the exact address to look for avoiding the need to
// then pull it up to double check it
error RecoveringBond(address bond);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IComposable.sol";

interface IThreadDeployer is IComposable {
  event Thread(
    address indexed thread,
    uint8 indexed variant,
    address indexed governor,
    address erc20,
    bytes32 descriptor
  );

  event CrowdfundedThread(address indexed thread, address indexed token, address indexed crowdfund, uint112 target);

  function percentage() external view returns (uint8);
  function crowdfundProxy() external view returns (address);
  function erc20Beacon() external view returns (address);
  function threadBeacon() external view returns (address);
  function auction() external view returns (address);
  function timelock() external view returns (address);

  function validate(uint8 variant, bytes calldata data) external view;

  function deploy(
    uint8 variant,
    string memory name,
    string memory symbol,
    bytes32 descriptor,
    address governor,
    bytes calldata data
  ) external;

  function recover(address erc20) external;
  function claimTimelock(address erc20) external;
}

interface IThreadDeployerInitializable is IThreadDeployer {
  function initialize(
    address crowdfundProxy,
    address erc20Beacon,
    address threadBeacon,
    address auction,
    address timelock
  ) external;
}

error UnknownVariant(uint8 id);
error NonStaticDecimals(uint8 beforeDecimals, uint8 afterDecimals);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../dao/IFrabricDAO.sol";

interface IThreadTimelock {
  function upgradesEnabled() external view returns (uint256);
}

interface IThread is IFrabricDAO, IThreadTimelock {
  event DescriptorChangeProposal(uint256 id, bytes32 indexed descriptor);
  event FrabricChangeProposal(uint256 indexed id, address indexed frabric, address indexed governor);
  event GovernorChangeProposal(uint256 indexed id, address indexed governor);
  event EcosystemLeaveWithUpgradesProposal(uint256 indexed id, address indexed frabric, address indexed governor);
  event DissolutionProposal(uint256 indexed id, address indexed token, uint256 price);

  event DescriptorChange(bytes32 indexed oldDescriptor, bytes32 indexed newDescriptor);
  event FrabricChange(address indexed oldFrabric, address indexed newFrabric);
  event GovernorChange(address indexed oldGovernor, address indexed newGovernor);

  enum ThreadProposalType {
    DescriptorChange,
    FrabricChange,
    GovernorChange,
    EcosystemLeaveWithUpgrades,
    Dissolution
  }

  function descriptor() external view returns (bytes32);
  function governor() external view returns (address);
  function frabric() external view returns (address);
  function irremovable(address participant) external view returns (bool);

  function proposeDescriptorChange(
    bytes32 _descriptor,
    bytes32 info
  ) external returns (uint256);
  function proposeFrabricChange(
    address _frabric,
    address _governor,
    bytes32 info
  ) external returns (uint256);
  function proposeGovernorChange(
    address _governor,
    bytes32 info
  ) external returns (uint256);
  function proposeEcosystemLeaveWithUpgrades(
    address newFrabric,
    address newGovernor,
    bytes32 info
  ) external returns (uint256);
  function proposeDissolution(
    address token,
    uint112 price,
    bytes32 info
  ) external returns (uint256);
}

interface IThreadInitializable is IThread {
  function initialize(
    string memory name,
    address erc20,
    bytes32 descriptor,
    address frabric,
    address governor,
    address[] calldata irremovable
  ) external;
}

error NotGovernor(address caller, address governor);
error ProposingUpgrade(address beacon, address instance, address code);
error NotLeaving(address frabric, address newFrabric);

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import { SafeERC20Upgradeable as SafeERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ERC165CheckerUpgradeable as ERC165Checker } from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

import { ECDSAUpgradeable as ECDSA } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

// Using a draft contract isn't great, as is using EIP712 which is technically still under "Review"
// EIP712 was created over 4 years ago and has undegone multiple versions since
// Metamask supports multiple various versions of EIP712 and is committed to maintaing "v3" and "v4" support
// The only distinction between the two is the support for arrays/structs in structs, which aren't used by these contracts
// Therefore, this usage is fine, now and in the long-term, as long as one of those two versions is indefinitely supported
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";

import { IERC20MetadataUpgradeable as IERC20Metadata } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../interfaces/erc20/IIntegratedLimitOrderDEX.sol";
import "../interfaces/erc20/IAuction.sol";
import "../interfaces/beacon/IFrabricBeacon.sol";

import "./DAO.sol";

import "../interfaces/dao/IFrabricDAO.sol";

/**
 * @title FrabricDAO Contract
 * @author Fractional Finance
 *
 * @dev Implements proposals mutual to both Threads and the Frabric
 * This could be merged directly into DAO, as the Thread and Frabric contracts use this,
 * yet DAO is only used by this
 * This offers smaller, more compartamentalized code, and directly integrating the two
 * doesn't actually offer any efficiency benefits. The new structs, the new variables, and
 * the new code are still needed, meaning it really just inlines _completeProposal
 */
abstract contract FrabricDAO is EIP712Upgradeable, DAO, IFrabricDAO {
  using SafeERC20 for IERC20;
  using ERC165Checker for address;

  /// @notice Bit value indicating a proposal is a common proposal
  uint16 constant public override commonProposalBit = 1 << 8;

  /// @notice Maximum percentage fee to enforce upon removal of a participant
  uint8 public override maxRemovalFee;

  struct Upgrade {
    address beacon;
    address instance;
    address code;
    uint256 version;
    bytes data;
  }
  mapping(uint256 => Upgrade) private _upgrades;

  struct TokenAction {
    address token;
    address target;
    bool mint;
    uint256 price;
    uint256 amount;
  }
  mapping(uint256 => TokenAction) private _tokenActions;

  struct Removal {
    address participant;
    uint8 fee;
  }
  mapping(uint256 => Removal) private _removals;

  uint256[100] private __gap;

  function __FrabricDAO_init(
    string memory name,
    address _erc20,
    uint64 _votingPeriod,
    uint8 _maxRemovalFee
  ) internal onlyInitializing {
    // This unfortunately doesn't use the Composable version, yet unless we change
    // the signing structs, we shouldn't need to upgrade this (even if EIP 712 would like us to)
    __EIP712_init(name, "1");
    __DAO_init(_erc20, _votingPeriod);
    supportsInterface[type(IFrabricDAO).interfaceId] = true;

    // Ensure this is a valid percentage
    if (_maxRemovalFee > 100) {
      revert InvalidRemovalFee(_maxRemovalFee, 100);
    }
    maxRemovalFee = _maxRemovalFee;
  }

  function _isCommonProposal(uint16 pType) internal pure returns (bool) {
    // Uses a shift instead of a bit mask to ensure this is the only bit set
    return (pType >> 8) == 1;
  }

  /**
   * @notice Create a new paper proposal (a statement agreed upon by the DAO without technical action)
   * @param supermajority true if a supermajority is required for the proposal to pass
   * @param info Statement to be put to a vote
   * @return uint256 ID of the created proposal
   */
  function proposePaper(bool supermajority, bytes32 info) external override returns (uint256) {
    // No dedicated event as the DAO emits type and info
    return _createProposal(uint16(CommonProposalType.Paper) | commonProposalBit, supermajority, info);
  }

  /**
   * @notice Propose a contract upgrade for this contract or one owned by it
   * @param beacon Address of the beacon contract facilitating upgrades
   * @param instance Address of the contract instance to be upgraded
   * @param version Version number of the new contract
   * @param code Address of the contract with the new code
   * @param data Data to be passed to new contract when triggering the upgrade
   * @param info Additional information about proposal
   * @return id ID of created proposal
   * @dev Specifying any irrelevant beacon will work yet won't have any impact
   * Specifying an arbitrary contract would also work if it has functions/
   * a fallback function which doesn't error when called
   * Between human review, function definition requirements, and the lack of privileges bestowed,
   * this is considered to be appropriately managed
   */
  function proposeUpgrade(
    address beacon,
    address instance,
    uint256 version,
    address code,
    bytes calldata data,
    bytes32 info
  ) public virtual override returns (uint256 id) {
    if (!beacon.supportsInterface(type(IFrabricBeacon).interfaceId)) {
      revert UnsupportedInterface(beacon, type(IFrabricBeacon).interfaceId);
    }
    bytes32 beaconName = IFrabricBeacon(beacon).beaconName();

    if (!code.supportsInterface(type(IComposable).interfaceId)) {
      revert UnsupportedInterface(code, type(IComposable).interfaceId);
    }
    bytes32 codeName = IComposable(code).contractName();

    // This check is also performed by the Beacon itself when calling upgrade
    // It's just optimal to prevent this proposal from ever existing and being pending if it's not valid
    // Since this doesn't check instance's contractName, it could be setting an implementation of X
    // on beacon X, yet this is pointless. Because the instance is X, its actual beacon must be X,
    // and it will never accept this implementation (which isn't even being passed to it)
    if (beaconName != codeName) {
      revert DifferentContract(beaconName, codeName);
    }

    id = _createProposal(uint16(CommonProposalType.Upgrade) | commonProposalBit, true, info);
    _upgrades[id] = Upgrade(beacon, instance, code, version, data);
    // Doesn't index code as parsing the Beacon's logs for its indexed code argument
    // will return every time a contract upgraded to it
    // This combination of options should be competent for almost all use cases
    // The only missing indexing case is when it's proposed to upgrade, yet that never passes/executes
    // This should be minimally considerable and coverable by outside solutions if truly needed
    emit UpgradeProposal(id, beacon, instance, version, code, data);
  }

  /**
   * @notice Create a proposal to mint, transfer, sell, auction tokens, or cancel a standing sell order.
   * Combined actions are supported
   * @param token Address of the token to act on
   * @param target Target address for the action. Either the recipient, this contract if selling on the DEX,
   * or the auction contract if selling at auction
   * @param price Price of tokens to create/cancel a DEX sell order at
   * @param amount Quantity of tokens to act with. 0 if cancelling an order
   * @param info Information on this proposal
   * @return id Id of created proposal
   */
  function proposeTokenAction(
    address token,
    address target,
    bool mint,
    uint256 price,
    uint256 amount,
    bytes32 info
  ) external override returns (uint256 id) {
    bool supermajority = false;

    if (mint) {
      // All of this mint code should work and will be reviewed by auditors to confirm that
      // That said, at this time, we are not launching with any form of minting enabled
      // Solely commented during development to enable running tests on this code
      // revert Minting();

      supermajority = true;
      if (token != erc20) {
        revert MintingDifferentToken(token, erc20);
      }
    }

    if (price != 0) {
      // Target is ignored when selling tokens, yet not when minting them
      // This enables minting and directly selling tokens, and removes mutability reducing scope
      if (target != address(this)) {
        revert TargetMalleability(target, address(this));
      }

      // Ensure that we know how to sell this token
      if (!token.supportsInterface(type(IIntegratedLimitOrderDEXCore).interfaceId)) {
        revert UnsupportedInterface(token, type(IIntegratedLimitOrderDEXCore).interfaceId);
      }

      // Because this is an ILO DEX, amount here will be atomic yet the ILO DEX
      // will expect it to be whole
      uint256 whole = 10 ** IERC20Metadata(token).decimals();
      if ((amount / whole * whole) != amount) {
        revert NotRoundAmount(amount);
      }
    // Only allow a zero amount to cancel an order at a given price
    } else if (amount == 0) {
      revert ZeroAmount();
    }

    id = _createProposal(uint16(CommonProposalType.TokenAction) | commonProposalBit, supermajority, info);
    _tokenActions[id] = TokenAction(token, target, mint, price, amount);
    emit TokenActionProposal(id, token, target, mint, price, amount);
  }

  /**
   * @notice Propose removal of `participant`
   * @param participant Address of participant proposed for removal
   * @param removalFee Percentage fee to charge `participant` on removal, intended to recover financial damage
   * @param signatures Array of signatures from users voting on this proposal in advance, in order to freeze the
   * funds of the participant for the duration of this proposal
   * @param info Any extra information about the proposal
   * @return id ID of created proposal
   */
  function proposeParticipantRemoval(
    address participant,
    uint8 removalFee,
    bytes[] calldata signatures,
    bytes32 info
  ) public virtual override returns (uint256 id) {
    if (participant == address(this)) {
      revert Irremovable(participant);
    }

    if (removalFee > maxRemovalFee) {
      revert InvalidRemovalFee(removalFee, maxRemovalFee);
    }

    id =  _createProposal(uint16(CommonProposalType.ParticipantRemoval) | commonProposalBit, false, info);
    _removals[id] = Removal(participant, removalFee);
    emit ParticipantRemovalProposal(id, participant, removalFee);

    // If signatures were provided, then the purpose is to freeze this participant's
    // funds for the duration of the proposal. This will not affect any existing
    // DEX orders yet will prevent further DEX orders from being placed. This prevents
    // dumping (which already isn't incentivized as tokens will be put up for auction)
    // and games of hot potato where they're transferred to friends/associates to
    // prevent their re-distribution. While they can also buy their own tokens off
    // the Auction contract (with an alt), this is a step closer to being an optimal
    // system

    // If this is done maliciously, whoever proposed this should be removed themselves
    if (signatures.length != 0) {
      if (!erc20.supportsInterface(type(IFreeze).interfaceId)) {
        revert UnsupportedInterface(erc20, type(IFreeze).interfaceId);
      }

      // Create a nonce out of freezeUntil, as this will solely increase
      uint256 freezeUntilNonce = IFreeze(erc20).frozenUntil(participant) + 1;
      for (uint256 i = 0; i < signatures.length; i++) {
        // Vote with the recovered signer. This will tell us how many votes they
        // have in the end, and if these people are voting to freeze their funds,
        // they believe they should be removed. They can change their mind later

        // Safe usage as this proposal is guaranteed to be active
        // If this account had already voted, _voteUnsafe will remove their votes
        // before voting again, making this safe against repeat signers
        _voteUnsafe(
          id,
          ECDSA.recover(
            _hashTypedDataV4(
              keccak256(
                abi.encode(
                  keccak256("Removal(address participant,uint8 removalFee,uint64 freezeUntilNonce)"),
                  participant,
                  removalFee,
                  freezeUntilNonce
                )
              )
            ),
            signatures[i]
          )
        );
      }

      // If the votes of these holders doesn't meet the required participation threshold, throw
      // Guaranteed to be positive as all votes have been for so far
      if (uint112(netVotes(id)) < requiredParticipation()) {
        // Uses an ID of type(uint256).max since this proposal doesn't have an ID yet
        // While we have an id variable, if this transaction reverts, it'll no longer be valid
        // We could also use 0 yet that would overlap with an actual proposal
        revert NotEnoughParticipation(type(uint256).max, uint112(netVotes(id)), requiredParticipation());
      }

      // Freeze the token until this proposal completes, with an extra 1 day buffer
      // for someone to call completeProposal
      IFrabricERC20(erc20).freeze(participant, uint64(block.timestamp) + votingPeriod + queuePeriod + uint64(1 days));
    }
  }

  // Has an empty body as it doesn't have to be overriden
  function _participantRemoval(address /*participant*/) internal virtual {}
  // Has to be overriden
  function _completeSpecificProposal(uint256 id, uint256 proposalType) internal virtual;

  // Re-entrancy isn't a concern due to completeProposal being safe from re-entrancy
  // That's the only thing which should call this
  function _completeProposal(uint256 id, uint16 _pType, bytes calldata data) internal override {
    if (_isCommonProposal(_pType)) {
      CommonProposalType pType = CommonProposalType(_pType ^ commonProposalBit);
      if (pType == CommonProposalType.Paper) {
        // NOP as the DAO emits ProposalStateChange which is all that's needed for this

      } else if (pType == CommonProposalType.Upgrade) {
        Upgrade storage upgrade = _upgrades[id];
        IFrabricBeacon(upgrade.beacon).upgrade(upgrade.instance, upgrade.version, upgrade.code, upgrade.data);
        delete _upgrades[id];

      } else if (pType == CommonProposalType.TokenAction) {
        TokenAction storage action = _tokenActions[id];
        if (action.amount == 0) {
          (uint256 i) = abi.decode(data, (uint256));
          // cancelOrder returns a bool of our own order was cancelled or merely *an* order was cancelled
          if (!IIntegratedLimitOrderDEXCore(action.token).cancelOrder(action.price, i)) {
            // Uses address(0) as it's unknown who this trader was
            revert NotOrderTrader(address(this), address(0));
          }
        } else {
          bool auction = action.target == IFrabricERC20(erc20).auction();
          if (!auction) {
            if (action.mint) {
              IFrabricERC20(erc20).mint(action.target, action.amount);
            // The ILO DEX doesn't require transfer or even approve
            } else if (action.price == 0) {
              IERC20(action.token).safeTransfer(action.target, action.amount);
            }
          } else if (action.mint) {
            // If minting to sell at Auction, mint to sell as the Auction contract uses transferFrom
            IFrabricERC20(erc20).mint(address(this), action.amount);
          }

          // Not else to allow direct mint + sell
          if (action.price != 0) {
            // These orders cannot be cancelled at this time without the DAO wash trading
            // through the order, yet that may collide with others orders at the same price
            // point, so this isn't actually a viable method
            IIntegratedLimitOrderDEXCore(action.token).sell(action.price, action.amount / (10 ** IERC20Metadata(action.token).decimals()));

          // Technically, TokenAction could not acknowledge Auction
          // By transferring the tokens to another contract, the Auction can be safely created
          // This is distinct from the ILO DEX as agreement is needed on what price to list at
          // The issue is that the subcontract wouldn't know who transferred it tokens,
          // so it must have an owner for its funds. This means creating a new contract per Frabric/Thread
          // (or achieving global ERC777 adoptance yet that would be incredibly problematic for several reasons)
          // The easiest solution is just to write a few lines into this contract to handle it
          } else if (auction) {
            IERC20(action.token).safeIncreaseAllowance(action.target, action.amount);
            IAuctionCore(action.target).list(
              address(this),
              action.token,
              // Use our ERC20's DEX token as the Auction token to receive
              IIntegratedLimitOrderDEXCore(erc20).tradeToken(),
              action.amount,
              1,
              uint64(block.timestamp),
              // A longer time period can be decided on and utilized via the above method
              1 weeks
            );
          }
        }
        delete _tokenActions[id];

      } else if (pType == CommonProposalType.ParticipantRemoval) {
        Removal storage removal = _removals[id];
        IFrabricERC20(erc20).remove(removal.participant, removal.fee);
        _participantRemoval(removal.participant);
        delete _removals[id];

      } else {
        revert UnhandledEnumCase("FrabricDAO _completeProposal CommonProposal", _pType);
      }

    } else {
      _completeSpecificProposal(id, _pType);
    }
  }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../dao/IFrabricDAO.sol";

interface IInitialFrabric is IFrabricDAO {
  enum FrabricProposalType {
    Participant
  }

  enum ParticipantType {
    Null,
    // Removed is before any other type to allow using > Removed to check validity
    Removed,
    Genesis
  }

  event ParticipantProposal(
    uint256 indexed id,
    ParticipantType indexed participantType,
    address participant
  );
  event ParticipantChange(ParticipantType indexed participantType, address indexed participant);

  function participant(address participant) external view returns (ParticipantType);
}

interface IInitialFrabricInitializable is IInitialFrabric {
  function initialize(
    address erc20,
    address[] calldata genesis
  ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/IUpgradeable.sol";
import "../dao/IFrabricDAO.sol";

interface IFrabricCore is IFrabricDAO {
  enum GovernorStatus {
    Null,
    Active,
    // Removed is last as GovernorStatus is written as a linear series of transitions
    // > Unverified will work to find any Governor which was ever active
    Removed
  }

  function governor(address governor) external view returns (GovernorStatus);
}

interface IFrabric is IFrabricCore {
  enum FrabricProposalType {
    Participant,
    RemoveBond,
    Thread,
    ThreadProposal
  }

  enum ParticipantType {
    Null,
    // Removed is before any other type to allow using > Removed to check validity
    Removed,
    Genesis,
    KYC,
    Governor,
    Voucher,
    Individual,
    Corporation
  }

  event ParticipantProposal(
    uint256 indexed id,
    ParticipantType indexed participantType,
    address indexed proposer,
    address participant
  );
  event BondRemovalProposal(
    uint256 indexed id,
    address indexed participant,
    bool indexed slash,
    uint256 amount
  );
  event ThreadProposal(
    uint256 indexed id,
    uint256 indexed variant,
    address indexed governor,
    string name,
    string symbol,
    bytes32 descriptor,
    bytes data
  );
  event ThreadProposalProposal(
    uint256 indexed id,
    address indexed thread,
    uint256 indexed proposalType,
    bytes data
  );
  event ParticipantChange(ParticipantType indexed participantType, address indexed participant);
  event Vouch(address indexed voucher, address indexed vouchee);

  function participant(address participant) external view returns (ParticipantType);

  function bond() external view returns (address);
  function threadDeployer() external view returns (address);

  function vouchers(address) external view returns (uint256);

  function proposeParticipant(
    ParticipantType participantType,
    address participant,
    bytes32 info
  ) external returns (uint256);
  function proposeBondRemoval(
    address governor,
    bool slash,
    uint256 amount,
    bytes32 info
  ) external returns (uint256);
  function proposeThread(
    uint8 variant,
    string calldata name,
    string calldata symbol,
    bytes32 descriptor,
    bytes calldata data,
    bytes32 info
  ) external returns (uint256);
  function proposeThreadProposal(
    address thread,
    uint16 proposalType,
    bytes calldata data,
    bytes32 info
  ) external returns (uint256);

  function vouch(address participant, bytes calldata signature) external;
  function approve(
    ParticipantType pType,
    address approving,
    bytes32 kycHash,
    bytes calldata signature
  ) external;
}

interface IFrabricUpgradeable is IFrabric, IUpgradeable {}

error InvalidParticipantType(IFrabric.ParticipantType pType);
error ParticipantAlreadyApproved(address participant);
error InvalidName(string name, string symbol);
error OutOfVouchers(address voucher);
error DifferentParticipantType(address participant, IFrabric.ParticipantType current, IFrabric.ParticipantType expected);
error InvalidKYCSignature(address signer, IFrabric.ParticipantType status);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";

interface IComposable is IERC165Upgradeable {
  function contractName() external returns (bytes32);
  // Returns uint256 max if not upgradeable
  function version() external returns (uint256);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IDistributionERC20 is IVotesUpgradeable, IERC20, IComposable {
  event Distribution(uint256 indexed id, address indexed token, uint112 amount);
  event Claim(uint256 indexed id, address indexed person, uint112 amount);

  function claimed(uint256 id, address person) external view returns (bool);

  function distribute(address token, uint112 amount) external returns (uint256 id);
  function claim(uint256 id, address person) external;
}

error Delegation();
error FeeOnTransfer(address token);
error AlreadyClaimed(uint256 id, address person);

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

error UnhandledEnumCase(string label, uint256 enumValue);

error ZeroPrice();
error ZeroAmount();

error UnsupportedInterface(address contractAddress, bytes4 interfaceID);

error ExternalCallFailed(address called, bytes4 selector, bytes error);

error Unauthorized(address caller, address user);
error Replay(uint256 nonce, uint256 expected);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

interface IUpgradeable {
  function validateUpgrade(uint256 version, bytes calldata data) external view;
  function upgrade(uint256 version, bytes calldata data) external;
}

error NotBeacon(address caller, address beacon);
error NotUpgraded(uint256 version, uint256 versionRequired);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "./IDAO.sol";

interface IFrabricDAO is IDAO {
  enum CommonProposalType {
    Paper,
    Upgrade,
    TokenAction,
    ParticipantRemoval
  }

  event UpgradeProposal(
    uint256 indexed id,
    address indexed beacon,
    address indexed instance,
    uint256 version,
    address code,
    bytes data
  );
  event TokenActionProposal(
    uint256 indexed id,
    address indexed token,
    address indexed target,
    bool mint,
    uint256 price,
    uint256 amount
  );
  event ParticipantRemovalProposal(uint256 indexed id, address participant, uint8 fee);

  function commonProposalBit() external view returns (uint16);
  function maxRemovalFee() external view returns (uint8);

  function proposePaper(bool supermajority, bytes32 info) external returns (uint256);
  function proposeUpgrade(
    address beacon,
    address instance,
    uint256 version,
    address code,
    bytes calldata data,
    bytes32 info
  ) external returns (uint256);
  function proposeTokenAction(
    address token,
    address target,
    bool mint,
    uint256 price,
    uint256 amount,
    bytes32 info
  ) external returns (uint256);
  function proposeParticipantRemoval(
    address participant,
    uint8 removalFee,
    bytes[] calldata signatures,
    bytes32 info
  ) external returns (uint256);
}

error Irremovable(address participant);
error InvalidRemovalFee(uint8 fee, uint8 max);
error Minting();
error MintingDifferentToken(address specified, address token);
error TargetMalleability(address target, address expected);
error NotRoundAmount(uint256 amount);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

// Only commit to a fraction of the DAO API at this time
// Voting/cancellation/queueing may undergo significant changes in the future
interface IDAOCore is IComposable {
  enum ProposalState {
    Null,
    Active,
    Queued,
    Executed,
    Cancelled
  }

  event Proposal(
    uint256 indexed id,
    uint256 indexed proposalType,
    address indexed creator,
    bool supermajority,
    bytes32 info
  );
  event ProposalStateChange(uint256 indexed id, ProposalState indexed state);

  function erc20() external view returns (address);
  function votingPeriod() external view returns (uint64);
  function passed(uint256 id) external view returns (bool);

  function canPropose(address proposer) external view returns (bool);
  function proposalActive(uint256 id) external view returns (bool);

  function completeProposal(uint256 id, bytes calldata data) external;
  function withdrawProposal(uint256 id) external;
}

interface IDAO is IDAOCore {
  // Solely used to provide indexing based on how people voted
  // Actual voting uses a signed integer at this time
  enum VoteDirection {
    Abstain,
    Yes,
    No
  }

  event Vote(uint256 indexed id, VoteDirection indexed direction, address indexed voter, uint112 votes);

  function queuePeriod() external view returns (uint64);
  function lapsePeriod() external view returns (uint64);
  function requiredParticipation() external view returns (uint112);

  function vote(uint256[] calldata id, int112[] calldata votes) external;
  function queueProposal(uint256 id) external;
  function cancelProposal(uint256 id, address[] calldata voters) external;

  function nextProposalID() external view returns (uint256);

  // Will only work for proposals pre-finalization
  function supermajorityRequired(uint256 id) external view returns (bool);
  function voteBlock(uint256 id) external view returns (uint32);
  function netVotes(uint256 id) external view returns (int112);
  function totalVotes(uint256 id) external view returns (uint112);

  // Will work even with finalized proposals (cancelled/completed)
  function voteRecord(uint256 id, address voter) external view returns (int112);
}

error DifferentLengths(uint256 lengthA, uint256 lengthB);
error InactiveProposal(uint256 id);
error ActiveProposal(uint256 id, uint256 time, uint256 endTime);
error ProposalFailed(uint256 id, int256 votes);
error NotEnoughParticipation(uint256 id, uint256 totalVotes, uint256 required);
error NotQueued(uint256 id, IDAO.ProposalState state);
// Doesn't include what they did vote as it's irrelevant
error NotYesVote(uint256 id, address voter);
error UnsortedVoter(address voter);
error ProposalPassed(uint256 id, int256 votes);
error StillQueued(uint256 id, uint256 time, uint256 queuedUntil);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IIntegratedLimitOrderDEXCore {
  enum OrderType { Null, Buy, Sell }

  event Order(OrderType indexed orderType, uint256 indexed price);
  event OrderIncrease(address indexed trader, uint256 indexed price, uint256 amount);
  event OrderFill(address indexed orderer, uint256 indexed price, address indexed executor, uint256 amount);
  event OrderCancelling(address indexed trader, uint256 indexed price);
  event OrderCancellation(address indexed trader, uint256 indexed price, uint256 amount);

  // Part of core to symbolize amount should always be whole while price is atomic
  function atomic(uint256 amount) external view returns (uint256);

  function tradeToken() external view returns (address);

  // sell is here as the FrabricDAO has the ability to sell tokens on their integrated DEX
  // That means this function API can't change (along with cancelOrder which FrabricDAO also uses)
  // buy is meant to be used by users, offering greater flexibility, especially as it has a router for a frontend
  function sell(uint256 price, uint256 amount) external returns (uint256);
  function cancelOrder(uint256 price, uint256 i) external returns (bool);
}

interface IIntegratedLimitOrderDEX is IComposable, IIntegratedLimitOrderDEXCore {
  function tradeTokenBalance() external view returns (uint256);
  function tradeTokenBalances(address trader) external view returns (uint256);
  function locked(address trader) external view returns (uint256);

  function withdrawTradeToken(address trader) external;

  function buy(
    address trader,
    uint256 price,
    uint256 minimumAmount
  ) external returns (uint256);

  function pointType(uint256 price) external view returns (IIntegratedLimitOrderDEXCore.OrderType);
  function orderQuantity(uint256 price) external view returns (uint256);
  function orderTrader(uint256 price, uint256 i) external view returns (address);
  function orderAmount(uint256 price, uint256 i) external view returns (uint256);
}

error LessThanMinimumAmount(uint256 amount, uint256 minimumAmount);
error NotEnoughFunds(uint256 required, uint256 balance);
error NotOrderTrader(address caller, address trader);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

// When someone is removed, each FrabricERC20 will list the removed party's tokens
// for auction. This is done with the following listing API which is separated out
// for greater flexibility in the future
interface IAuctionCore is IComposable {
  // Indexes the ID as expected, the seller so people can find their own auctions
  // which they need to complete, and the token so people can find auctions by the token being sold
  event Auctions(
    uint256 indexed startID,
    address indexed seller,
    address indexed token,
    address traded,
    uint256 total,
    uint8 quantity,
    uint64 start,
    uint32 length
  );

  function list(
    address seller,
    address token,
    address traded,
    uint256 amount,
    uint8 batches,
    uint64 start,
    uint32 length
  ) external returns (uint256 id);
}

interface IAuction is IAuctionCore {
  event Bid(uint256 indexed id, address bidder, uint256 amount);
  event AuctionComplete(uint256 indexed id);
  event BurnFailed(address indexed token, uint256 amount);

  function balances(address token, address amount) external returns (uint256);

  function bid(uint256 id, uint256 amount) external;
  function complete(uint256 id) external;
  function withdraw(address token, address trader) external;

  function active(uint256 id) external view returns (bool);
  // Will only work for auctions which have yet to complete
  function token(uint256 id) external view returns (address);
  function traded(uint256 id) external view returns (address);
  function amount(uint256 id) external view returns (uint256);
  function highBidder(uint256 id) external view returns (address);
  function highBid(uint256 id) external view returns (uint256);
  function end(uint256 id) external view returns (uint64);
}

interface IAuctionInitializable is IAuction {
  function initialize() external;
}

error AuctionPending(uint256 time, uint256 start);
error AuctionOver(uint256 time, uint256 end);
error BidTooLow(uint256 bid, uint256 currentBid);
error HighBidder(address bidder);
error AuctionActive(uint256 time, uint256 end);

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";

import "../common/IComposable.sol";

interface IFrabricBeacon is IBeacon, IComposable {
  event Upgrade(address indexed instance, uint256 indexed version, address indexed code, bytes data);
  event Upgraded(address indexed instance, uint256 indexed version);

  // Name of the contract this beacon points to
  function beaconName() external view returns (bytes32);

  // Amount of release channels
  function releaseChannels() external view returns (uint8);

  // Raw address mapping. This does not perform resolution
  function implementations(address code) external view returns (address);

  // Raw upgrade data mapping. This does not perform resolution
  function upgradeDatas(address instance, uint256 version) external view returns (bytes memory);

  // Implementation resolver for a given instance
  // IBeacon has an implementation function defined yet it doesn't take an argument
  // as OZ beacons only expect to handle a single implementation address
  function implementation(address instance) external view returns (address);

  // Upgrade data resolution for a given instance
  function upgradeData(address instance, uint256 version) external view returns (bytes memory);

  // Upgrade to different code/forward to a different beacon
  function upgrade(address instance, uint256 version, address code, bytes calldata data) external;

  // Trigger an upgrade for the specified contract
  function triggerUpgrade(address instance, uint256 version) external;
}

// Errors used by Beacon
error InvalidCode(address code);
// Caller may be a bit extra, yet these only cost gas when executed
// The fact wallets try execution before sending transactions should mean this is a non-issue
error NotOwner(address caller, address owner);
error NotUpgradeAuthority(address caller, address instance);
error DifferentContract(bytes32 oldName, bytes32 newName);
error InvalidVersion(uint256 version, uint256 expectedVersion);
error NotUpgrade(address code);
error UpgradeDataForInitial(address instance);

// Errors used by SingleBeacon
// SingleBeacons only allow its singular release channel to be upgraded
error UpgradingInstance(address instance);

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import { IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IVotesUpgradeable as IVotes } from "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";

import "../interfaces/erc20/IFrabricERC20.sol";

import "../common/Composable.sol";

import "../interfaces/dao/IDAO.sol";

/**
 * @title DAO Contract
 * @author Fractional Finance
 * @notice This contracts, based around a FrabricERC20, implements the core logic used by all DAOs in the ecosystem
 * @dev Upgradeable contract
 */
abstract contract DAO is Composable, IDAO {
  struct ProposalStruct {
    // The following are embedded into easily accessible events
    address creator;
    ProposalState state;
    // This actually requires getting the block of the event as well, yet generally isn't needed
    uint64 stateStartTime;

    // Used by inheriting contracts
    // This is intended to be an enum (limited to the 8-bit space) with a bit flag
    // This allows 8 different categories of enums with a simple bit flag
    // If they were shifted and used as a number...
    uint16 pType;

    // Whether or not this proposal requires a supermajority to pass
    bool supermajority;

    // The following are exposed via getters
    // This won't be deleted yet this struct is used in _proposals which atomically increments keys
    // Therefore, this usage is safe
    mapping(address => int112) voters;
    // Safe due to the FrabricERC20 being int112 as well
    int112 votes;
    uint112 totalVotes;
    // This would be the 2038 problem if this was denominated in seconds, which
    // wouldn't be acceptable. Instead, since it's denominated in blocks, we have
    // not 68 years from the epoch yet ~884 years from the start of Ethereum
    // Accepting the protocol's forced upgrade/death at that point to save
    // a decent amount of gas now is worth it
    // It may be much sooner if the block time decreases significantly yet
    // this is solely used in maps, which means we can extend this struct without
    // issue
    uint32 voteBlock;
  }

  /// @notice Address of the FrabricERC20 used by this DAO
  address public override erc20;
  /// @notice Proposal voting period length in seconds
  uint64 public override votingPeriod;
  /// @notice Time before a passed proposal can be enacted
  uint64 public override queuePeriod;
  /// @notice Time a proposal can be enacted before no longer being completable
  uint64 public override lapsePeriod;

  uint256 private _nextProposalID;
  mapping(uint256 => ProposalStruct) private _proposals;

  /// @notice Whether or not a proposal passed
  mapping(uint256 => bool) public override passed;

  uint256[100] private __gap;

  function __DAO_init(address _erc20, uint64 _votingPeriod) internal onlyInitializing {
    supportsInterface[type(IDAOCore).interfaceId] = true;
    supportsInterface[type(IDAO).interfaceId] = true;

    erc20 = _erc20;
    votingPeriod = _votingPeriod;
    queuePeriod = 48 hours;
    lapsePeriod = 48 hours;
  }


  /// @notice Get required amount of participation for a proposal to passable
  /// @return uint112 Amount of participation required
  function requiredParticipation() public view returns (uint112) {
    // Uses the current total supply instead of the historical total supply in
    // order to represent the current community
    // Subtracts any reserves held by the DAO itself as those can't be voted with
    // Requires 10% participation
    return uint112(IERC20(erc20).totalSupply() - IERC20(erc20).balanceOf(address(this))) / 10;
  }

  /// @notice Check if `proposer` can propose
  /// @return bool true if `proposer` can propose, false otherwise
  /// @dev Check to be implemented by inheriting contracts
  function canPropose(address proposer) public virtual view returns (bool);
  modifier beforeProposal() {
    if (!canPropose(msg.sender)) {
      // Presumably a lack of whitelisting
      revert NotWhitelisted(msg.sender);
    }
    _;
  }

  // Uses storage as all proposals checked for activity are storage
  function proposalActive(ProposalStruct storage proposal) private view returns (bool) {
    return (
      (proposal.state == ProposalState.Active) &&
      (block.timestamp < (proposal.stateStartTime + votingPeriod))
    );
  }

  /**
   * @notice Check if proposal `id` is currently active
   * @param id ID of proposal to be checked
   * @return bool true if proposal `id` is active, false otherwise
   * @dev proposal.state == ProposalState.Active is not reliable as expired proposals
   * which didn't pass will forever have their state set to ProposalState.Active
   * This call will check the proposal's expiry status as well
  */
  function proposalActive(uint256 id) external view override returns (bool) {
    return proposalActive(_proposals[id]);
  }

  // Used to be a modifier yet that caused the modifier to perform a map read,
  // just for the function to do the same. By making this an private function
  // returning the storage reference, it maintains performance and functions the same
  function activeProposal(uint256 id) private view returns (ProposalStruct storage proposal) {
    proposal = _proposals[id];
    if (!proposalActive(proposal)) {
      // Doesn't include the inactivity reason as proposalActive doesn't return it
      revert InactiveProposal(id);
    }
  }

  function _createProposal(
    uint16 proposalType,
    bool supermajority,
    bytes32 info
  ) internal beforeProposal() returns (uint256 id) {
    id = _nextProposalID;
    _nextProposalID++;

    ProposalStruct storage proposal = _proposals[id];
    proposal.creator = msg.sender;
    proposal.state = ProposalState.Active;
    proposal.stateStartTime = uint64(block.timestamp);
    // Use the previous block as it's finalized
    // While the creator could have sold in this block, they can also sell over the next few weeks
    // This is why cancelProposal exists
    proposal.voteBlock = uint32(block.number) - 1;
    proposal.pType = proposalType;
    proposal.supermajority = supermajority;

    // Separate event to allow indexing by type/creator while maintaining state machine consistency
    // Also exposes info
    emit Proposal(id, proposalType, proposal.creator, supermajority, info);
    emit ProposalStateChange(id, proposal.state);

    // Automatically vote in favor for the creator if they have votes and are actively KYCd
    _voteUnsafe(id, msg.sender);
  }

  // Labeled unsafe due to its split checks with the various callers and lack of guarantees
  // on what checks it'll perform. This can only be used in a carefully designed, cohesive ecosystemm
  function _voteUnsafe(
    address voter,
    uint256 id,
    ProposalStruct storage proposal,
    int112 votes,
    int112 absVotes
  ) private {
    // Cap voting power per user at 10% of the current total supply, a legally valuable number
    // This will hopefully not be executed 99% of the time and then only for select Threads
    // This isn't perfect yet we are somewhat sybil resistant thanks to requiring KYC
    // 10% isn't requiredParticipation, despite currently having the same value,
    // yet rather a number with some legal consideration
    // requiredParticipation was also moved to circulating supply while this remains total
    int112 tenPercent = int112(uint112(IVotes(erc20).getPastTotalSupply(proposal.voteBlock) / 10));
    if (absVotes > tenPercent) {
      votes = tenPercent * (votes / absVotes);
      absVotes = tenPercent;
    }

    // Remove old votes
    int112 standing = proposal.voters[voter];
    if (standing != 0) {
      proposal.votes -= standing;
      // Decrease from totalVotes as well in case the participant no longer feels as strongly
      if (standing < 0) {
        standing = -standing;
      }
      proposal.totalVotes -= uint112(standing);
    }
    // Increase the amount of total votes
    // If they're now abstaining, these will mean totalVotes is not increased at all
    // While explicitly abstaining could be considered valid as participation,
    // requiring opinionation is simpler and fine
    proposal.totalVotes += uint112(absVotes);

    // Set new votes
    proposal.voters[voter] = votes;
    // Update the vote sums
    VoteDirection direction;
    if (votes != 0) {
      proposal.votes += votes;
      direction = votes > 0 ? VoteDirection.Yes : VoteDirection.No;
    } else {
      direction = VoteDirection.Abstain;
    }

    emit Vote(id, direction, voter, uint112(absVotes));
  }

  function _voteUnsafe(uint256 id, address voter) internal {
    ProposalStruct storage proposal = _proposals[id];
    int112 votes = int112(uint112(IVotes(erc20).getPastVotes(voter, proposal.voteBlock)));
    if ((votes != 0) && IFrabricWhitelistCore(erc20).hasKYC(voter)) {
      _voteUnsafe(voter, id, proposal, votes, votes);
    }
  }

  /**
   * @notice Vote on one or multiple proposals, where all must be active
   * @param ids Array of proposal IDs to vote on
   * @param votes Array of number of votes to cast for each corresponding proposal ID
   */
  function vote(uint256[] memory ids, int112[] memory votes) external override {
    if (ids.length != votes.length) {
      revert DifferentLengths(ids.length, votes.length);
    }

    // Require the caller to be KYCd
    if (!IFrabricWhitelistCore(erc20).hasKYC(msg.sender)) {
      revert NotKYC(msg.sender);
    }

    for (uint256 i = 0; i < ids.length; i++) {
      ProposalStruct storage proposal = activeProposal(ids[i]);
      int112 actualVotes = int112(uint112(IVotes(erc20).getPastVotes(msg.sender, proposal.voteBlock)));
      if (actualVotes == 0) {
        return;
      }

      // Since Solidity arrays are bounds checked, this will simply error if votes
      // is too short. If it's too long, it ignores the extras, and the actually processed
      // data doesn't suffer from any mutability
      int112 votesI = votes[i];

      // If they're abstaining, don't check if they have enough votes
      // 0 will be less than (or equal to) whatever amount they do have
      int112 absVotes;
      if (votesI == 0) {
        absVotes = 0;
      } else {
        absVotes = votesI > 0 ? votesI : -votesI;
        // If they're voting with more votes then they actually have, correct votes
        // Also allows UIs to simply vote with type(int112).max
        if (absVotes > actualVotes) {
          // votesI / absVotes will return 1 or -1, representing the vote direction
          votesI = actualVotes * (votesI / absVotes);
          absVotes = actualVotes;
        }
      }

      _voteUnsafe(msg.sender, ids[i], proposal, votesI, absVotes);
    }
  }

  /// @notice Queue a successful proposal to be enacted
  /// @param id ID of proposal to be enacted
  function queueProposal(uint256 id) external override {
    ProposalStruct storage proposal = _proposals[id];

    // Proposal should be Active to be queued
    if (proposal.state != ProposalState.Active) {
      revert InactiveProposal(id);
    }

    // Proposal's voting period should be over
    uint256 end = proposal.stateStartTime + votingPeriod;
    if (block.timestamp < end) {
      revert ActiveProposal(id, block.timestamp, end);
    }

    // Proposal should've gotten enough votes to pass
    // Since votes is a signed integer, anything greater than 0 signifies more
    // people votes yes than no
    int112 passingVotes = 0;
    if (proposal.supermajority) {
      // Utilize a 66% supermajority requirement
      // With 33% of the votes being against, and 33% of the votes being for,
      // totalVotes will be at 0. In order for a supermajority of 66%, the
      // other 33% must be in excess of this neutral state, hence / 3
      // Doesn't add 1 to handle rounding due to the following if statement
      passingVotes = int112(proposal.totalVotes / 3);
    }

    // In case of a tie, err on the side of caution and fail the proposal
    if (proposal.votes <= passingVotes) {
      revert ProposalFailed(id, proposal.votes);
    }

    // Require sufficient participation to ensure this actually represents the community
    if (proposal.totalVotes < requiredParticipation()) {
      revert NotEnoughParticipation(id, proposal.totalVotes, requiredParticipation());
    }

    proposal.state = ProposalState.Queued;
    proposal.stateStartTime = uint64(block.timestamp);
    emit ProposalStateChange(id, proposal.state);
  }


  /// @notice Cancel enacting a queued proposal if the voters no longer have sufficient voting power
  /// @param id ID of queued proposal to be cancelled
  /// @param voters Sorted list of voters who voted in favour of proposal `id`
  function cancelProposal(uint256 id, address[] calldata voters) external override {
    // Must be queued. Even if it's completable, if it has yet to be completed, allow this
    ProposalStruct storage proposal = _proposals[id];
    if (proposal.state != ProposalState.Queued) {
      revert NotQueued(id, proposal.state);
    }

    // If the supply has shrunk, this will potentially apply a value greater than the modern 10%
    // If the supply has expanded, this will use the historic vote cap which is smaller than the modern 10%
    // The latter is more accurate and more likely
    int112 tenPercent = int112(uint112(IVotes(erc20).getPastTotalSupply(proposal.voteBlock) / 10));

    int112 newVotes = proposal.votes;
    uint160 prevVoter = 0;
    for (uint i = 0; i < voters.length; i++) {
      address voter = voters[i];
      if (uint160(voter) <= prevVoter) {
        revert UnsortedVoter(voter);
      }
      prevVoter = uint160(voter);

      // If a voter who voted against this proposal (or abstained) is included,
      // whoever wrote JS to handle this has a broken script which isn't working as intended
      int112 voted = proposal.voters[voter];
      if (voted <= 0) {
        revert NotYesVote(id, voter);
      }

      int112 votes = int112(uint112(IERC20(erc20).balanceOf(voter)));
      if (votes > tenPercent) {
        votes = tenPercent;
      }

      // If they currently have enough votes to maintain their historical vote, continue
      // If we errored here, cancelProposal TXs could be vulnerable to frontrunning
      // designed to bork these cancellations
      // This will force those who sold their voting power to regain it and hold it
      // for as long as cancelProposal can be issued
      if (votes >= voted) {
        continue;
      }

      newVotes -= voted - votes;
    }

    int112 passingVotes = 0;
    if (proposal.supermajority) {
      passingVotes = int112(proposal.totalVotes / 3);
    }

    // If votes are tied, it would've failed queueProposal
    // Fail it here as well (by not using >=)
    if (newVotes > passingVotes) {
      revert ProposalPassed(id, newVotes);
    }

    delete _proposals[id];
    emit ProposalStateChange(id, ProposalState.Cancelled);
  }

  function _completeProposal(uint256 id, uint16 proposalType, bytes calldata data) internal virtual;

  /**
   * @notice Complete a queued proposal `id`
   * @param id ID of the proposal to be completed
   * @param data Arbitrary data to complete this specific proposal with
   * @dev Does not require canonically ordering when executing proposals in case a proposal has invalid actions, halting everything
   */
  function completeProposal(uint256 id, bytes calldata data) external override {
    // Safe against re-entrancy (regarding multiple execution of the same proposal)
    // as long as this block is untouched. While multiple proposals can be executed
    // simultaneously, that should not be an issue
    ProposalStruct storage proposal = _proposals[id];
    // Cheaper than copying the entire thing into memory
    uint16 pType = proposal.pType;
    if (proposal.state != ProposalState.Queued) {
      revert NotQueued(id, proposal.state);
    }
    uint256 end = proposal.stateStartTime + queuePeriod;
    if (block.timestamp < end) {
      revert StillQueued(id, block.timestamp, end);
    }

    // If no one executed this proposal for so long it lapsed, cancel it
    if (block.timestamp > (end + lapsePeriod)) {
      delete _proposals[id];
      emit ProposalStateChange(id, ProposalState.Cancelled);
      return;
    }

    delete _proposals[id];
    // Solely used for getter functionality
    // While we could use it for state checks, we already need to check it's specifically Queued
    passed[id] = true;
    emit ProposalStateChange(id, ProposalState.Executed);

    // Re-entrancy here would do nothing as the proposal has had its state updated
    _completeProposal(id, pType, data);
  }


  /// @notice Lets the proposal creator withdraw an active/queued proposal
  /// @param id ID of proposal to be withdrawn
  function withdrawProposal(uint256 id) external override {
    ProposalStruct storage proposal = _proposals[id];
    // A proposal which didn't pass will pass this check
    // It's not worth checking the timestamp when marking the proposal as Cancelled is more accurate than Active anyways
    if ((proposal.state != ProposalState.Active) && (proposal.state != ProposalState.Queued)) {
      revert InactiveProposal(id);
    }
    // Only allow the proposer to withdraw a proposal.
    if (proposal.creator != msg.sender) {
      revert Unauthorized(msg.sender, proposal.creator);
    }
    delete _proposals[id];
    emit ProposalStateChange(id, ProposalState.Cancelled);
  }

  /// @notice Get the ID of the next proposal to be created
  /// @return uint256 ID of the next proposal to be created
  function nextProposalID() external view override returns (uint256) {
    return _nextProposalID;
  }

  /**
   * @notice Check if a supermajority (circ. supply / 6) is required to approve proposal `id`
   * @param id ID of proposal to be checked
   * @return bool True if proposal `id` requires a supermajority to pass
   * @dev Will only work with proposals which have yet to complete in some form
   * After that, the sole information available onchain is passed, and voteRecord
   * as mappings are not deleted
   */
  function supermajorityRequired(uint256 id) external view override returns (bool) {
    return _proposals[id].supermajority;
  }

  /// @notice Get the vote block (block created at - 1) for proposal `id`
  /// @param id ID of proposal to be checked
  /// @return uint32 Vote block for proposal `id`
  function voteBlock(uint256 id) external view override returns (uint32) {
    return _proposals[id].voteBlock;
  }

  /// @notice Get net number of token votes in approval of proposal `id`
  /// @param id ID of proposal to be checked
  /// @return int112 Number of net token votes in approval of proposal `id`
  function netVotes(uint256 id) public view override returns (int112) {
    return _proposals[id].votes;
  }

  /// @notice Get total number of token votes cast on proposal `id`
  /// @param id ID of proposal to be checked
  /// @return uint112 Number of total votes cast on proposal `id`
  function totalVotes(uint256 id) external view override returns (uint112) {
    return _proposals[id].totalVotes;
  }

  /**
   * @notice Get voting record of address `voter` for proposal `id`
   * @param id ID of the proposal to be checked
   * @param voter Address of the voter to get the record of
   * @return int112 Votes cast by `voter` on proposal `id`
   */
  function voteRecord(uint256 id, address voter) external view override returns (int112) {
    return _proposals[id].voters[voter];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "./IDistributionERC20.sol";
import "./IFrabricWhitelist.sol";
import "./IIntegratedLimitOrderDEX.sol";

interface IRemovalFee {
  function removalFee(address person) external view returns (uint8);
}

interface IFreeze {
  event Freeze(address indexed person, uint64 until);

  function frozenUntil(address person) external view returns (uint64);
  function frozen(address person) external returns (bool);

  function freeze(address person, uint64 until) external;
  function triggerFreeze(address person) external;
}

interface IFrabricERC20 is IDistributionERC20, IFrabricWhitelist, IRemovalFee, IFreeze, IIntegratedLimitOrderDEX {
  event Removal(address indexed person, uint256 balance);

  function auction() external view returns (address);

  function mint(address to, uint256 amount) external;
  function burn(uint256 amount) external;

  function remove(address participant, uint8 fee) external;
  function triggerRemoval(address person) external;

  function paused() external view returns (bool);
  function pause() external;
}

interface IFrabricERC20Initializable is IFrabricERC20 {
  function initialize(
    string memory name,
    string memory symbol,
    uint256 supply,
    address parent,
    address tradeToken,
    address auction
  ) external;
}

error SupplyExceedsInt112(uint256 supply, int112 max);
error Frozen(address person);
error NothingToRemove(address person);
// Not Paused due to an overlap with the event
error CurrentlyPaused();
error Locked(address person, uint256 balanceAfterTransfer, uint256 lockedBalance);

// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.9;

import "../interfaces/common/IComposable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Composable is Initializable, IComposable {
  // Doesn't use "name" due to IERC20 using "name"
  bytes32 public override contractName;
  // Version is global, and not per-interface, as interfaces aren't "DAO" and "FrabricDAO"
  // Any version which changes the API would change the interface ID, so checking
  // for supported functionality should be via supportsInterface, not version
  uint256 public override version;
  mapping(bytes4 => bool) public override supportsInterface;

  // While this could probably get away with 5 variables, and other contracts
  // with 20, the fact this is free (and a permanent decision) leads to using
  // these large gaps
  uint256[100] private __gap;

  // Code should set its name so Beacons can identify code
  // That said, code shouldn't declare support for interfaces or have any version
  // Hence this
  // Due to solidity requirements, final constracts (non-proxied) which call init
  // yet still use constructors will have to call this AND init. It's a minor
  // gas inefficiency not worth optimizing around
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor(string memory name) {
    contractName = keccak256(bytes(name));

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }

  function __Composable_init(string memory name, bool finalized) internal onlyInitializing {
    contractName = keccak256(bytes(name));
    if (!finalized) {
      version = 1;
    } else {
      version = type(uint256).max;
    }

    supportsInterface[type(IERC165Upgradeable).interfaceId] = true;
    supportsInterface[type(IComposable).interfaceId] = true;
  }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >=0.8.9;

import "../common/Errors.sol";
import "../common/IComposable.sol";

interface IFrabricWhitelistCore is IComposable {
  event Whitelisted(address indexed person, bool indexed whitelisted);

  // The ordinal value of the enum increases with accreditation
  enum Status {
    Null,
    Removed,
    Whitelisted,
    KYC
  }

  function parent() external view returns (address);

  function setParent(address parent) external;
  function whitelist(address person) external;
  function setKYC(address person, bytes32 hash, uint256 nonce) external;

  function whitelisted(address person) external view returns (bool);
  function hasKYC(address person) external view returns (bool);
  function removed(address person) external view returns (bool);
  function status(address person) external view returns (Status);
}

interface IFrabricWhitelist is IFrabricWhitelistCore {
  event ParentChange(address oldParent, address newParent);
  // Info shouldn't be indexed when you consider it's unique per-person
  // Indexing it does allow retrieving the address of a person by their KYC however
  // It's also just 750 gas on an infrequent operation
  event KYCUpdate(address indexed person, bytes32 indexed oldInfo, bytes32 indexed newInfo, uint256 nonce);
  event GlobalAcceptance();

  function global() external view returns (bool);

  function kyc(address person) external view returns (bytes32);
  function kycNonces(address person) external view returns (uint256);
  function explicitlyWhitelisted(address person) external view returns (bool);
  function removedAt(address person) external view returns (uint256);
}

error AlreadyWhitelisted(address person);
error Removed(address person);
error NotWhitelisted(address person);
error NotRemoved(address person);
error NotKYC(address person);