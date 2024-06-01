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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool value) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

pragma solidity ^0.8.7;

interface IExchange {
    function deposit(address receiver) external payable;
}

contract SealedFunding {
    constructor(address _owner, address _exchange) {
        IExchange(_exchange).deposit{value: address(this).balance}(_owner);
        assembly {
            // Ensures the runtime bytecode is a single opcode: `INVALID`. This reduces contract
            // deploy costs & ensures that no one can accidentally send ETH to the contract once
            // deployed.
            mstore8(0, 0xfe)
            return(0, 1)
        }
    }
}

pragma solidity ^0.8.7;

import "./SealedFunding.sol";

contract SealedFundingFactory {
    address public immutable exchange;

    constructor(address _exchange) {
        exchange = _exchange;
    }

    event SealedFundingRevealed(bytes32 salt, address owner);

    function deploySealedFunding(bytes32 salt, address owner) public {
        new SealedFunding{salt: salt}(owner, exchange);
        emit SealedFundingRevealed(salt, owner);
    }

    function computeSealedFundingAddress(bytes32 salt, address owner)
        external
        view
        returns (address predictedAddress, bool isDeployed)
    {
        predictedAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(abi.encodePacked(type(SealedFunding).creationCode, abi.encode(owner, exchange)))
                        )
                    )
                )
            )
        );
        isDeployed = predictedAddress.code.length != 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;
import "../shared/EIP712Base.sol";

abstract contract EIP712 is EIP712Base {
    struct WithdrawalPacket {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        uint256 amount;
        uint256 nonce;
        address account;
    }

    function _verifyWithdrawal(WithdrawalPacket calldata packet) internal virtual returns (address) {
        // verify deadline
        require(block.timestamp < packet.deadline, ">deadline");

        // verify signature
        address recoveredAddress = _verifySig(
            abi.encode(
                keccak256("VerifyWithdrawal(uint256 deadline,uint256 amount,uint256 nonce,address account)"),
                packet.deadline,
                packet.amount,
                packet.nonce,
                packet.account
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return recoveredAddress; // Invariant: sequencer != address(0), we maintain this every time sequencer is set
    }

    struct Action {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 maxAmount;
        address operator;
        bytes4 sigHash;
        bytes data;
    }

    function _verifyAction(Action calldata packet) internal virtual returns (address) {
        address recoveredAddress = _verifySig(
            abi.encode(keccak256("Action(uint256 maxAmount,address operator,bytes4 sigHash,bytes data)"),
            packet.maxAmount, packet.operator, packet.sigHash, keccak256(packet.data)),
            packet.v,
            packet.r,
            packet.s
        );
        require(recoveredAddress != address(0), "sig");
        return recoveredAddress;
    }

    struct ActionAttestation {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
        uint256 amount;
        uint256 nonce;
        address account;
        bytes32 callHash;
        bytes attestationData;
    }

    function _verifyActionAttestation(ActionAttestation calldata packet) internal virtual returns (address) {
        require(block.timestamp < packet.deadline, ">deadline");
        address recoveredAddress = _verifySig(
            abi.encode(keccak256("ActionAttestation(uint256 deadline,uint256 amount,uint256 nonce,address account,bytes32 callHash,bytes attestationData)"), 
                packet.deadline,
                packet.amount,
                packet.nonce,
                packet.account,
                packet.callHash,
                keccak256(packet.attestationData)
            ),
            packet.v,
            packet.r,
            packet.s
        );
        return recoveredAddress;
    }
}

pragma solidity ^0.8.7;

import "./EIP712.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../funding/SealedFundingFactory.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

contract SealedPool is EIP712, Ownable {
    using BitMaps for BitMaps.BitMap;

    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _balances;
    string public constant name = "Sealed ETH";
    string public constant symbol = "SETH";
    uint8 public constant decimals = 18;

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    // having multiple separated sequencers by rank is an extra security measure against key leakage through side attacks
    // If a side channel attack is possible that requires multiple signatures to be made, higher rank sequencers will be more protected
    // against it because each signature will require an onchain action, which will make the attack extremely expensive
    // It also allows us to use different security systems for the multiple sequencer keys
    mapping(address => uint256) public sequencers; // Invariant: sequencer[address(0)] == 0 always
    SealedFundingFactory public immutable sealedFundingFactory;
    uint256 public forcedWithdrawDelay = 7 days;

    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public pendingWithdrawals;
    mapping(address => bool) public guardians;

    BitMaps.BitMap private usedNonces;

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    constructor(address _sequencer) {
        require(_sequencer != address(0), "0x0 sequencer not allowed");
        sequencers[_sequencer] = 1;
        sealedFundingFactory = new SealedFundingFactory(address(this));
    }

    event SequencerChanged(address sequencer, uint rank);

    function changeSequencer(address sequencer, uint rank) external onlyOwner {
        require(sequencer != address(0), "0x0 sequencer not allowed");
        sequencers[sequencer] = rank;
        emit SequencerChanged(sequencer, rank);
    }

    event ForcedWithdrawDelayChanged(uint256 newDelay);

    function changeForcedWithdrawDelay(uint256 newDelay) external onlyOwner {
        require(newDelay < 10 days, "<10 days");
        forcedWithdrawDelay = newDelay;
        emit ForcedWithdrawDelayChanged(newDelay);
    }

    event GuardianSet(address guardian, bool value);

    function setGuardian(address guardian, bool value) external onlyOwner {
        guardians[guardian] = value;
        emit GuardianSet(guardian, value);
    }

    event SequencerDisabled(address guardian, address sequencer);

    function emergencyDisableSequencer(address sequencer) external {
        require(guardians[msg.sender] == true, "not guardian");
        sequencers[sequencer] = 0; // Maintains the invariant that sequencers[0] == 0
        emit SequencerDisabled(msg.sender, sequencer);
    }

    function deposit(address receiver) public payable {
        _balances[receiver] += msg.value;
        emit Transfer(address(0), receiver, msg.value);
    }

    function _withdraw(uint256 amount) internal {
        _balances[msg.sender] -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success);
        emit Transfer(msg.sender, address(0), amount);
    }

    function withdraw(WithdrawalPacket calldata packet) public {
        address signer = _verifyWithdrawal(packet);
        require(sequencers[signer] == 1, "!sequencer");
        require(nonceState(packet.nonce) == false, "replayed");
        usedNonces.set(packet.nonce);
        require(packet.account == msg.sender, "not sender");
        _withdraw(packet.amount);
    }

    event StartWithdrawal(
        address owner,
        uint256 timestamp,
        uint256 nonce,
        uint256 amount
    );

    function startWithdrawal(uint256 amount, uint256 nonce) external {
        pendingWithdrawals[msg.sender][block.timestamp][nonce] = amount;
        emit StartWithdrawal(msg.sender, block.timestamp, nonce, amount);
    }

    event CancelWithdrawal(address owner, uint256 timestamp, uint256 nonce);

    function cancelPendingWithdrawal(
        uint256 timestamp,
        uint256 nonce
    ) external {
        pendingWithdrawals[msg.sender][timestamp][nonce] = 0;
        emit CancelWithdrawal(msg.sender, timestamp, nonce);
    }

    event ExecuteDelayedWithdrawal(
        address owner,
        uint256 timestamp,
        uint256 nonce
    );

    function executePendingWithdrawal(
        uint256 timestamp,
        uint256 nonce
    ) external {
        require(timestamp + forcedWithdrawDelay < block.timestamp, "too soon");
        uint256 amount = pendingWithdrawals[msg.sender][timestamp][nonce];
        pendingWithdrawals[msg.sender][timestamp][nonce] = 0;
        _withdraw(amount);
        emit ExecuteDelayedWithdrawal(msg.sender, timestamp, nonce);
    }

    function _revealBids(bytes32[] calldata salts, address owner) internal {
        for (uint256 i = 0; i < salts.length; ) {
            // We use try/catch here to prevent a griefing attack where someone could deploySealedFunding() one of the
            // sealed fundings of the buyer right before another user calls this function, thus making it revert
            // It's still possible for the buyer to perform this attack by frontrunning the call with a withdraw()
            // but that's trivial to solve by just revealing all the salts of the griefing user
            try sealedFundingFactory.deploySealedFunding{gas: 100_000}(salts[i], owner) {} // cost of deploySealedFunding() is between 55k and 82k
                catch {}
            unchecked {
                ++i;
            }
        }
    }

    function withdrawWithSealedBids(
        bytes32[] calldata salts,
        WithdrawalPacket calldata packet
    ) external {
        _revealBids(salts, msg.sender);
        withdraw(packet);
    }

    function settle(
        Action calldata action,
        ActionAttestation calldata actionAttestation
    ) public payable {
        uint sequencerRank = sequencers[
            _verifyActionAttestation(actionAttestation)
        ];
        require(sequencerRank > 0, "!sequencer");
        if (actionAttestation.account != msg.sender) {
            require(
                actionAttestation.account == _verifyAction(action),
                "diff user"
            );
        }
        require(nonceState(actionAttestation.nonce) == false, "replayed");
        usedNonces.set(actionAttestation.nonce);
        require(actionAttestation.amount <= action.maxAmount);
        require(keccak256(abi.encode(action.operator, action.data)) == actionAttestation.callHash, "!callHash");
        if(msg.value < actionAttestation.amount){ // WARNING! If msg.value > amount, ETH will be stuck in the contract!
            _balances[actionAttestation.account] -= actionAttestation.amount;
            emit Transfer(actionAttestation.account, address(0), actionAttestation.amount);
        }
        // Replay protection for users is left to the called contract, since in some cases (eg auctionHash) its not needed
        (bool success, bytes memory data) = action.operator.call{
            value: actionAttestation.amount
        }(
            abi.encodeWithSelector(action.sigHash,
                msg.sender,
                actionAttestation.account,
                sequencerRank,
                action.data,
                actionAttestation.attestationData
            )
        );
        if(!success) {
            assembly{
                let revertStringLength := mload(data)
                let revertStringPtr := add(data, 0x20)
                revert(revertStringPtr, revertStringLength)
            }
        }
        require(success, "failed");
    }


    function settleWithSealedBids(
        bytes32[] calldata salts,
        Action calldata action,
        ActionAttestation calldata actionAttestation
    ) external {
        _revealBids(salts, actionAttestation.account);
        settle(action, actionAttestation);
    }

    function nonceState(uint256 nonce) public view returns (bool) {
        return usedNonces.get(nonce);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.4;

abstract contract EIP712Base {
    /// -----------------------------------------------------------------------
    /// Structs
    /// -----------------------------------------------------------------------

    /// -----------------------------------------------------------------------
    /// Immutable parameters
    /// -----------------------------------------------------------------------

    /// @notice The chain ID used by EIP-712
    uint256 internal immutable INITIAL_CHAIN_ID;

    /// @notice The domain separator used by EIP-712
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    /// -----------------------------------------------------------------------
    /// Constructor
    /// -----------------------------------------------------------------------

    constructor() {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = _computeDomainSeparator();
    }

    /// -----------------------------------------------------------------------
    /// Packet verification
    /// -----------------------------------------------------------------------

    function _verifySig(bytes memory data, uint8 v, bytes32 r, bytes32 s) internal virtual returns (address) {
        // verify signature
        address recoveredAddress =
            ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), keccak256(data))), v, r, s);
        return recoveredAddress;
    }

    /// -----------------------------------------------------------------------
    /// EIP-712 compliance
    /// -----------------------------------------------------------------------

    /// @notice The domain separator used by EIP-712
    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : _computeDomainSeparator();
    }

    /// @notice Computes the domain separator used by EIP-712
    function _computeDomainSeparator() internal view virtual returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("SealedArtMarket"),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );
    }
}