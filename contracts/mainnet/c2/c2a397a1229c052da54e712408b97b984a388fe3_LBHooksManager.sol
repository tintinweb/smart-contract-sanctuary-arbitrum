// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {
    Ownable2StepUpgradeable,
    OwnableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ImmutableClone} from "@lb-protocol/src/libraries/ImmutableClone.sol";
import {Hooks, ILBHooks} from "@lb-protocol/src/libraries/Hooks.sol";
import {ILBFactory} from "@lb-protocol/src/interfaces/ILBFactory.sol";
import {ILBPair} from "@lb-protocol/src/interfaces/ILBPair.sol";
import {IMasterChef} from "@moe-core/src/interfaces/IMasterChef.sol";
import {IMasterChefRewarder} from "@moe-core/src/interfaces/IMasterChef.sol";
import {ILBHooksBaseParentRewarder} from "./interfaces/ILBHooksBaseParentRewarder.sol";
import {ILBHooksExtraRewarder} from "./interfaces/ILBHooksExtraRewarder.sol";
import {ILBHooksManager} from "./interfaces/ILBHooksManager.sol";

/**
 * @title LB Hooks Manager
 * @dev This contract is used to create and set LB Hooks.
 * Currently, it is used to manage the creation of LB Hooks Rewarder and LB Hooks Extra Rewarder.
 */
contract LBHooksManager is Ownable2StepUpgradeable, ILBHooksManager {
    ILBFactory internal immutable _lbFactory;
    IMasterChef internal immutable _masterChef;

    mapping(LBHooksType => bytes32) private _lbHooksParameters;

    mapping(LBHooksType => ILBHooks[]) private _hooks;
    mapping(ILBHooks => LBHooksType) private _lbHooksTypes;

    /**
     * @dev Constructor of the contract
     * @param lbFactory The address of the LBFactory contract
     * @param masterChef The address of the MasterChef contract
     */
    constructor(ILBFactory lbFactory, IMasterChef masterChef) {
        _lbFactory = lbFactory;
        _masterChef = masterChef;

        _disableInitializers();
    }

    /**
     * @dev Initializes the contract
     * @param initialOwner The address of the initial owner
     */
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
    }

    /**
     * @dev Returns the LB Hooks parameters for the given LB Hooks type
     * @param lbHooksType The LB Hooks type
     * @return hooksParameters The LB Hooks parameters
     */
    function getLBHooksParameters(LBHooksType lbHooksType) external view override returns (bytes32 hooksParameters) {
        return _lbHooksParameters[lbHooksType];
    }

    /**
     * @dev Returns the LB Hooks at the given index for the given LB Hooks type
     * @param lbHooksType The LB Hooks type
     * @param index The index of the LB Hooks
     * @return hooks The LB Hooks
     */
    function getHooksAt(LBHooksType lbHooksType, uint256 index) external view override returns (ILBHooks hooks) {
        return _hooks[lbHooksType][index];
    }

    /**
     * @dev Returns the length of the LB Hooks for the given LB Hooks type
     * @param lbHooksType The LB Hooks type
     * @return length The length of the LB Hooks
     */
    function getHooksLength(LBHooksType lbHooksType) external view override returns (uint256 length) {
        return _hooks[lbHooksType].length;
    }

    /**
     * @dev Returns the LB Hooks type for the given LB Hooks
     * @param hooks The LB Hooks
     * @return lbHooksType The LB Hooks type
     */
    function getLBHooksType(ILBHooks hooks) external view override returns (LBHooksType lbHooksType) {
        return _lbHooksTypes[hooks];
    }

    /**
     * @dev Sets the LB Hooks parameters for the given LB Hooks type
     * Only callable by the owner
     * @param lbHooksType The LB Hooks type
     * @param hooksParameters The LB Hooks parameters
     */
    function setLBHooksParameters(LBHooksType lbHooksType, bytes32 hooksParameters) external override onlyOwner {
        if (lbHooksType == LBHooksType.Invalid) revert LBHooksManager__InvalidLBHooksType();

        _lbHooksParameters[lbHooksType] = hooksParameters;

        emit HooksParametersSet(lbHooksType, hooksParameters);
    }

    /**
     * @dev Creates a new LB Hooks Rewarder
     * This will also try to set the LB Hooks parameters on the pair
     * Only callable by the owner
     * @param tokenX The address of the token X
     * @param tokenY The address of the token Y
     * @param binStep The bin step
     * @param initialOwner The address of the initial owner
     * @return rewarder The address of the LB Hooks Rewarder
     */
    function createLBHooksMCRewarder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, address initialOwner)
        external
        override
        onlyOwner
        returns (address rewarder)
    {
        (ILBPair lbPair, bytes32 hooksParameters) =
            _getLBPairAndHooksParameters(LBHooksType.MCRewarder, tokenX, tokenY, binStep);

        uint256 pid = _masterChef.getNumberOfFarms();
        bytes memory immutableData = abi.encodePacked(lbPair, pid);

        rewarder = _cloneHooks(LBHooksType.MCRewarder, Hooks.getHooks(hooksParameters), immutableData);

        _masterChef.add(IERC20(rewarder), IMasterChefRewarder(address(0)));

        _lbFactory.setLBHooksParametersOnPair(
            tokenX,
            tokenY,
            binStep,
            Hooks.setHooks(hooksParameters, rewarder),
            abi.encode(initialOwner, tokenX, tokenY, binStep)
        );
    }

    /**
     * @dev Creates a new LB Hooks Simple Rewarder
     * Only callable by the owner
     * @param tokenX The address of the token X
     * @param tokenY The address of the token Y
     * @param binStep The bin step
     * @param rewardToken The address of the reward token
     * @param initialOwner The address of the initial owner
     * @return rewarder The address of the LB Hooks Simple Rewarder
     */
    function createLBHooksSimpleRewarder(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        IERC20 rewardToken,
        address initialOwner
    ) external override onlyOwner returns (address rewarder) {
        (ILBPair lbPair, bytes32 hooksParameters) =
            _getLBPairAndHooksParameters(LBHooksType.SimpleRewarder, tokenX, tokenY, binStep);

        address lbHooksAddress = Hooks.getHooks(lbPair.getLBHooksParameters());

        bytes memory immutableData = abi.encodePacked(lbPair, rewardToken, lbHooksAddress);

        rewarder = _cloneHooks(LBHooksType.SimpleRewarder, Hooks.getHooks(hooksParameters), immutableData);

        _lbFactory.setLBHooksParametersOnPair(
            tokenX, tokenY, binStep, Hooks.setHooks(hooksParameters, rewarder), abi.encode(initialOwner)
        );
    }

    /**
     * @dev Creates a new LB Hooks Extra Rewarder
     * This will also try to set the LB Hooks Extra Rewarder on the Rewarder of the pair
     * Only callable by the owner
     * @param tokenX The address of the token X
     * @param tokenY The address of the token Y
     * @param binStep The bin step
     * @param rewardToken The address of the reward token
     * @param initialOwner The address of the initial owner
     * @return extraRewarder The address of the LB Hooks Extra Rewarder
     */
    function createLBHooksExtraRewarder(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        IERC20 rewardToken,
        address initialOwner
    ) external override onlyOwner returns (address extraRewarder) {
        (ILBPair lbPair, bytes32 hooksParameters) =
            _getLBPairAndHooksParameters(LBHooksType.ExtraRewarder, tokenX, tokenY, binStep);

        address lbHooksAddress = Hooks.getHooks(lbPair.getLBHooksParameters());

        if (lbHooksAddress == address(0)) revert LBHooksManager__LBHooksNotSetOnPair();

        bytes memory immutableData = abi.encodePacked(lbPair, rewardToken, lbHooksAddress);

        extraRewarder = _cloneHooks(LBHooksType.ExtraRewarder, Hooks.getHooks(hooksParameters), immutableData);

        ILBHooksBaseParentRewarder(lbHooksAddress).setLBHooksExtraRewarder(extraRewarder, abi.encode(initialOwner));
    }

    /**
     * @dev Internal function to get the LB Pair and the LB Hooks parameters for the given LB Hooks type
     * @param lbHooksType The LB Hooks type
     * @param tokenX The address of the token X
     * @param tokenY The address of the token Y
     * @param binStep The bin step
     * @return lbPair The LB Pair
     * @return hooksParameters The LB Hooks parameters
     */
    function _getLBPairAndHooksParameters(LBHooksType lbHooksType, IERC20 tokenX, IERC20 tokenY, uint16 binStep)
        internal
        view
        returns (ILBPair lbPair, bytes32 hooksParameters)
    {
        lbPair = _lbFactory.getLBPairInformation(tokenX, tokenY, binStep).LBPair;

        if (address(lbPair) == address(0)) revert LBHooksManager__LBPairNotFound();
        if (lbPair.getTokenX() != tokenX) revert LBHooksManager__UnorderedTokens();

        hooksParameters = _lbHooksParameters[lbHooksType];

        if (hooksParameters == bytes32(0)) revert LBHooksManager__LBHooksParametersNotSet();
    }

    /**
     * @dev Internal function to create a new rewarder using the given implementation and immutable data
     * @param lbHooksType The LB Hooks type
     * @param implementation The address of the implementation
     * @param immutableData The immutable data
     * @return hooks The address of the LB Hooks
     */
    function _cloneHooks(LBHooksType lbHooksType, address implementation, bytes memory immutableData)
        internal
        returns (address)
    {
        uint256 id = _hooks[lbHooksType].length;

        ILBHooks hooks = ILBHooks(
            ImmutableClone.cloneDeterministic(
                implementation, immutableData, bytes32((uint256(uint8(lbHooksType)) << 248) | id)
            )
        );

        _hooks[lbHooksType].push(hooks);
        _lbHooksTypes[hooks] = lbHooksType;

        emit HooksCreated(lbHooksType, id, hooks);

        return address(hooks);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.20;

import {OwnableUpgradeable} from "./OwnableUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This extension of the {Ownable} contract includes a two-step mechanism to transfer
 * ownership, where the new owner must call {acceptOwnership} in order to replace the
 * old one. This can help prevent common mistakes, such as transfers of ownership to
 * incorrect accounts, or to contracts that are unable to interact with the
 * permission system.
 *
 * The initial owner is specified at deployment time in the constructor for `Ownable`. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable2Step
    struct Ownable2StepStorage {
        address _pendingOwner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable2Step")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant Ownable2StepStorageLocation = 0x237e158222e3e6968b72b9db0d8043aacf074ad9f650f0d1606b4d82ee432c00;

    function _getOwnable2StepStorage() private pure returns (Ownable2StepStorage storage $) {
        assembly {
            $.slot := Ownable2StepStorageLocation
        }
    }

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    function __Ownable2Step_init() internal onlyInitializing {
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        return $._pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        $._pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        Ownable2StepStorage storage $ = _getOwnable2StepStorage();
        delete $._pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-20 standard as defined in the ERC.
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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Immutable Clone Library
 * @notice Minimal immutable proxy library.
 * @author Trader Joe
 * @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibClone.sol)
 * @author Minimal proxy by 0age (https://github.com/0age)
 * @author Clones with immutable args by wighawag, zefram.eth, Saw-mon & Natalie
 * (https://github.com/Saw-mon-and-Natalie/clones-with-immutable-args)
 * @dev Minimal proxy:
 * Although the sw0nt pattern saves 5 gas over the erc-1167 pattern during runtime,
 * it is not supported out-of-the-box on Etherscan. Hence, we choose to use the 0age pattern,
 * which saves 4 gas over the erc-1167 pattern during runtime, and has the smallest bytecode.
 * @dev Clones with immutable args (CWIA):
 * The implementation of CWIA here doesn't implements a `receive()` as it is not needed for LB.
 */
library ImmutableClone {
    error DeploymentFailed();
    error PackedDataTooBig();

    /**
     * @dev Deploys a deterministic clone of `implementation` using immutable arguments encoded in `data`, with `salt`
     * @param implementation The address of the implementation
     * @param data The encoded immutable arguments
     * @param salt The salt
     */
    function cloneDeterministic(address implementation, bytes memory data, bytes32 salt)
        internal
        returns (address instance)
    {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 63`
            // The `runSize` is `creationSize - 10`.

            // if `extraLength` is greater than `0xffca` revert as the `creationSize` would be greater than `0xffff`.
            if gt(extraLength, 0xffca) {
                // Store the function selector of `PackedDataTooBig()`.
                mstore(0x00, 0xc8c78139)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            /**
             * ---------------------------------------------------------------------------------------------------+
             * CREATION (10 bytes)                                                                                |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode     | Mnemonic          | Stack     | Memory                                                |
             * ---------------------------------------------------------------------------------------------------|
             * 61 runSize | PUSH2 runSize     | r         |                                                       |
             * 3d         | RETURNDATASIZE    | 0 r       |                                                       |
             * 81         | DUP2              | r 0 r     |                                                       |
             * 60 offset  | PUSH1 offset      | o r 0 r   |                                                       |
             * 3d         | RETURNDATASIZE    | 0 o r 0 r |                                                       |
             * 39         | CODECOPY          | 0 r       | [0..runSize): runtime code                            |
             * f3         | RETURN            |           | [0..runSize): runtime code                            |
             * ---------------------------------------------------------------------------------------------------|
             * RUNTIME (98 bytes + extraLength)                                                                   |
             * ---------------------------------------------------------------------------------------------------|
             * Opcode   | Mnemonic       | Stack                    | Memory                                      |
             * ---------------------------------------------------------------------------------------------------|
             *                                                                                                    |
             * ::: copy calldata to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds                      |                                             |
             * 3d       | RETURNDATASIZE | 0 cds                    |                                             |
             * 3d       | RETURNDATASIZE | 0 0 cds                  |                                             |
             * 37       | CALLDATACOPY   |                          | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: keep some values in stack :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | 0                        | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0                      | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0                    | [0..cds): calldata                          |
             * 3d       | RETURNDATASIZE | 0 0 0 0                  | [0..cds): calldata                          |
             * 61 extra | PUSH2 extra    | e 0 0 0 0                | [0..cds): calldata                          |
             *                                                                                                    |
             * ::: copy extra data to memory :::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 80       | DUP1           | e e 0 0 0 0              | [0..cds): calldata                          |
             * 60 0x35  | PUSH1 0x35     | 0x35 e e 0 0 0 0         | [0..cds): calldata                          |
             * 36       | CALLDATASIZE   | cds 0x35 e e 0 0 0 0     | [0..cds): calldata                          |
             * 39       | CODECOPY       | e 0 0 0 0                | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: delegate call to the implementation contract ::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 36       | CALLDATASIZE   | cds e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 01       | ADD            | cds+e 0 0 0 0            | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | 0 cds+e 0 0 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 73 addr  | PUSH20 addr    | addr 0 cds+e 0 0 0 0     | [0..cds): calldata, [cds..cds+e): extraData |
             * 5a       | GAS            | gas addr 0 cds+e 0 0 0 0 | [0..cds): calldata, [cds..cds+e): extraData |
             * f4       | DELEGATECALL   | success 0 0              | [0..cds): calldata, [cds..cds+e): extraData |
             *                                                                                                    |
             * ::: copy return data to memory ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 3d       | RETURNDATASIZE | rds success 0 0          | [0..cds): calldata, [cds..cds+e): extraData |
             * 3d       | RETURNDATASIZE | rds rds success 0 0      | [0..cds): calldata, [cds..cds+e): extraData |
             * 93       | SWAP4          | 0 rds success 0 rds      | [0..cds): calldata, [cds..cds+e): extraData |
             * 80       | DUP1           | 0 0 rds success 0 rds    | [0..cds): calldata, [cds..cds+e): extraData |
             * 3e       | RETURNDATACOPY | success 0 rds            | [0..rds): returndata                        |
             *                                                                                                    |
             * 60 0x33  | PUSH1 0x33     | 0x33 success 0 rds       | [0..rds): returndata                        |
             * 57       | JUMPI          | 0 rds                    | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: revert ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * fd       | REVERT         |                          | [0..rds): returndata                        |
             *                                                                                                    |
             * ::: return ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: |
             * 5b       | JUMPDEST       | 0 rds                    | [0..rds): returndata                        |
             * f3       | RETURN         |                          | [0..rds): returndata                        |
             * ---------------------------------------------------------------------------------------------------+
             */
            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e603357fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            mstore(
                sub(data, 0x21),
                or(
                    shl(0xd8, add(extraLength, 0x35)),
                    or(shl(0x48, extraLength), 0x6100003d81600a3d39f3363d3d373d3d3d3d610000806035363936013d73)
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            instance := create2(0, sub(data, 0x1f), add(extraLength, 0x3f), salt)

            // If `instance` is zero, revert.
            if iszero(instance) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
        }
    }

    /**
     * @dev Returns the initialization code hash of the clone of `implementation`
     * using immutable arguments encoded in `data`.
     * Used for mining vanity addresses with create2crunch.
     * @param implementation The address of the implementation contract.
     * @param data The encoded immutable arguments.
     * @return hash The initialization code hash.
     */
    function initCodeHash(address implementation, bytes memory data) internal pure returns (bytes32 hash) {
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore2 := mload(sub(data, 0x40))
            let mBefore1 := mload(sub(data, 0x20))
            let dataLength := mload(data)
            let dataEnd := add(add(data, 0x20), dataLength)
            let mAfter1 := mload(dataEnd)

            // +2 bytes for telling how much data there is appended to the call.
            let extraLength := add(dataLength, 2)
            // The `creationSize` is `extraLength + 63`
            // The `runSize` is `creationSize - 10`.

            // if `extraLength` is greater than `0xffca` revert as the `creationSize` would be greater than `0xffff`.
            if gt(extraLength, 0xffca) {
                // Store the function selector of `PackedDataTooBig()`.
                mstore(0x00, 0xc8c78139)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Write the bytecode before the data.
            mstore(data, 0x5af43d3d93803e603357fd5bf3)
            // Write the address of the implementation.
            mstore(sub(data, 0x0d), implementation)
            mstore(
                sub(data, 0x21),
                or(
                    shl(0xd8, add(extraLength, 0x35)),
                    or(shl(0x48, extraLength), 0x6100003d81600a3d39f3363d3d373d3d3d3d610000806035363936013d73)
                )
            )
            mstore(dataEnd, shl(0xf0, extraLength))

            // Create the instance.
            hash := keccak256(sub(data, 0x1f), add(extraLength, 0x3f))

            // Restore the overwritten memory surrounding `data`.
            mstore(dataEnd, mAfter1)
            mstore(data, dataLength)
            mstore(sub(data, 0x20), mBefore1)
            mstore(sub(data, 0x40), mBefore2)
        }
    }

    /**
     * @dev Returns the address of the deterministic clone of
     * `implementation` using immutable arguments encoded in `data`, with `salt`, by `deployer`.
     * @param implementation The address of the implementation.
     * @param data The immutable arguments of the implementation.
     * @param salt The salt used to compute the address.
     * @param deployer The address of the deployer.
     * @return predicted The predicted address.
     */
    function predictDeterministicAddress(address implementation, bytes memory data, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        bytes32 hash = initCodeHash(implementation, data);
        predicted = predictDeterministicAddress(hash, salt, deployer);
    }

    /**
     * @dev Returns the address when a contract with initialization code hash,
     * `hash`, is deployed with `salt`, by `deployer`.
     * @param hash The initialization code hash.
     * @param salt The salt used to compute the address.
     * @param deployer The address of the deployer.
     * @return predicted The predicted address.
     */
    function predictDeterministicAddress(bytes32 hash, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the boundaries of the data and cache the memory slots around it.
            let mBefore := mload(0x35)

            // Compute and store the bytecode hash.
            mstore8(0x00, 0xff) // Write the prefix.
            mstore(0x35, hash)
            mstore(0x01, shl(96, deployer))
            mstore(0x15, salt)
            predicted := keccak256(0x00, 0x55)

            // Restore the part of the free memory pointer that has been overwritten.
            mstore(0x35, mBefore)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILBHooks} from "../interfaces/ILBHooks.sol";

/**
 * @title Hooks library
 * @notice This library contains functions that should be used to interact with hooks
 */
library Hooks {
    error Hooks__CallFailed();

    bytes32 internal constant BEFORE_SWAP_FLAG = bytes32(uint256(1 << 160));
    bytes32 internal constant AFTER_SWAP_FLAG = bytes32(uint256(1 << 161));
    bytes32 internal constant BEFORE_FLASH_LOAN_FLAG = bytes32(uint256(1 << 162));
    bytes32 internal constant AFTER_FLASH_LOAN_FLAG = bytes32(uint256(1 << 163));
    bytes32 internal constant BEFORE_MINT_FLAG = bytes32(uint256(1 << 164));
    bytes32 internal constant AFTER_MINT_FLAG = bytes32(uint256(1 << 165));
    bytes32 internal constant BEFORE_BURN_FLAG = bytes32(uint256(1 << 166));
    bytes32 internal constant AFTER_BURN_FLAG = bytes32(uint256(1 << 167));
    bytes32 internal constant BEFORE_TRANSFER_FLAG = bytes32(uint256(1 << 168));
    bytes32 internal constant AFTER_TRANSFER_FLAG = bytes32(uint256(1 << 169));

    struct Parameters {
        address hooks;
        bool beforeSwap;
        bool afterSwap;
        bool beforeFlashLoan;
        bool afterFlashLoan;
        bool beforeMint;
        bool afterMint;
        bool beforeBurn;
        bool afterBurn;
        bool beforeBatchTransferFrom;
        bool afterBatchTransferFrom;
    }

    /**
     * @dev Helper function to encode the hooks parameters to a single bytes32 value
     * @param parameters The hooks parameters
     * @return hooksParameters The encoded hooks parameters
     */
    function encode(Parameters memory parameters) internal pure returns (bytes32 hooksParameters) {
        hooksParameters = bytes32(uint256(uint160(address(parameters.hooks))));

        if (parameters.beforeSwap) hooksParameters |= BEFORE_SWAP_FLAG;
        if (parameters.afterSwap) hooksParameters |= AFTER_SWAP_FLAG;
        if (parameters.beforeFlashLoan) hooksParameters |= BEFORE_FLASH_LOAN_FLAG;
        if (parameters.afterFlashLoan) hooksParameters |= AFTER_FLASH_LOAN_FLAG;
        if (parameters.beforeMint) hooksParameters |= BEFORE_MINT_FLAG;
        if (parameters.afterMint) hooksParameters |= AFTER_MINT_FLAG;
        if (parameters.beforeBurn) hooksParameters |= BEFORE_BURN_FLAG;
        if (parameters.afterBurn) hooksParameters |= AFTER_BURN_FLAG;
        if (parameters.beforeBatchTransferFrom) hooksParameters |= BEFORE_TRANSFER_FLAG;
        if (parameters.afterBatchTransferFrom) hooksParameters |= AFTER_TRANSFER_FLAG;
    }

    /**
     * @dev Helper function to decode the hooks parameters from a single bytes32 value
     * @param hooksParameters The encoded hooks parameters
     * @return parameters The hooks parameters
     */
    function decode(bytes32 hooksParameters) internal pure returns (Parameters memory parameters) {
        parameters.hooks = getHooks(hooksParameters);

        parameters.beforeSwap = (hooksParameters & BEFORE_SWAP_FLAG) != 0;
        parameters.afterSwap = (hooksParameters & AFTER_SWAP_FLAG) != 0;
        parameters.beforeFlashLoan = (hooksParameters & BEFORE_FLASH_LOAN_FLAG) != 0;
        parameters.afterFlashLoan = (hooksParameters & AFTER_FLASH_LOAN_FLAG) != 0;
        parameters.beforeMint = (hooksParameters & BEFORE_MINT_FLAG) != 0;
        parameters.afterMint = (hooksParameters & AFTER_MINT_FLAG) != 0;
        parameters.beforeBurn = (hooksParameters & BEFORE_BURN_FLAG) != 0;
        parameters.afterBurn = (hooksParameters & AFTER_BURN_FLAG) != 0;
        parameters.beforeBatchTransferFrom = (hooksParameters & BEFORE_TRANSFER_FLAG) != 0;
        parameters.afterBatchTransferFrom = (hooksParameters & AFTER_TRANSFER_FLAG) != 0;
    }

    /**
     * @dev Helper function to get the hooks address from the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @return hooks The hooks address
     */
    function getHooks(bytes32 hooksParameters) internal pure returns (address hooks) {
        hooks = address(uint160(uint256(hooksParameters)));
    }

    /**
     * @dev Helper function to set the hooks address in the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @param newHooks The new hooks address
     * @return hooksParameters The updated hooks parameters
     */
    function setHooks(bytes32 hooksParameters, address newHooks) internal pure returns (bytes32) {
        return bytes32(bytes12(hooksParameters)) | bytes32(uint256(uint160(newHooks)));
    }

    /**
     * @dev Helper function to get the flags from the encoded hooks parameters
     * @param hooksParameters The encoded hooks parameters
     * @return flags The flags
     */
    function getFlags(bytes32 hooksParameters) internal pure returns (bytes12 flags) {
        flags = bytes12(hooksParameters);
    }

    /**
     * @dev Helper function call the onHooksSet function on the hooks contract, only if the
     * hooksParameters is not 0
     * @param hooksParameters The encoded hooks parameters
     * @param onHooksSetData The data to pass to the onHooksSet function
     */
    function onHooksSet(bytes32 hooksParameters, bytes calldata onHooksSetData) internal {
        if (hooksParameters != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.onHooksSet.selector, hooksParameters, onHooksSetData)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeSwap function on the hooks contract, only if the
     * BEFORE_SWAP_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param swapForY Whether the swap is for Y
     * @param amountsIn The amounts in
     */
    function beforeSwap(bytes32 hooksParameters, address sender, address to, bool swapForY, bytes32 amountsIn)
        internal
    {
        if ((hooksParameters & BEFORE_SWAP_FLAG) != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.beforeSwap.selector, sender, to, swapForY, amountsIn)
            );
        }
    }

    /**
     * @dev Helper function to call the afterSwap function on the hooks contract, only if the
     * AFTER_SWAP_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param swapForY Whether the swap is for Y
     * @param amountsOut The amounts out
     */
    function afterSwap(bytes32 hooksParameters, address sender, address to, bool swapForY, bytes32 amountsOut)
        internal
    {
        if ((hooksParameters & AFTER_SWAP_FLAG) != 0) {
            _safeCall(
                hooksParameters, abi.encodeWithSelector(ILBHooks.afterSwap.selector, sender, to, swapForY, amountsOut)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeFlashLoan function on the hooks contract, only if the
     * BEFORE_FLASH_LOAN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param amounts The amounts
     */
    function beforeFlashLoan(bytes32 hooksParameters, address sender, address to, bytes32 amounts) internal {
        if ((hooksParameters & BEFORE_FLASH_LOAN_FLAG) != 0) {
            _safeCall(hooksParameters, abi.encodeWithSelector(ILBHooks.beforeFlashLoan.selector, sender, to, amounts));
        }
    }

    /**
     * @dev Helper function to call the afterFlashLoan function on the hooks contract, only if the
     * AFTER_FLASH_LOAN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param fees The fees
     * @param feesReceived The fees received
     */
    function afterFlashLoan(bytes32 hooksParameters, address sender, address to, bytes32 fees, bytes32 feesReceived)
        internal
    {
        if ((hooksParameters & AFTER_FLASH_LOAN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterFlashLoan.selector, sender, to, fees, feesReceived)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeMint function on the hooks contract, only if the
     * BEFORE_MINT_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param liquidityConfigs The liquidity configs
     * @param amountsReceived The amounts received
     */
    function beforeMint(
        bytes32 hooksParameters,
        address sender,
        address to,
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsReceived
    ) internal {
        if ((hooksParameters & BEFORE_MINT_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeMint.selector, sender, to, liquidityConfigs, amountsReceived)
            );
        }
    }

    /**
     * @dev Helper function to call the afterMint function on the hooks contract, only if the
     * AFTER_MINT_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param to The recipient
     * @param liquidityConfigs The liquidity configs
     * @param amountsIn The amounts in
     */
    function afterMint(
        bytes32 hooksParameters,
        address sender,
        address to,
        bytes32[] calldata liquidityConfigs,
        bytes32 amountsIn
    ) internal {
        if ((hooksParameters & AFTER_MINT_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterMint.selector, sender, to, liquidityConfigs, amountsIn)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeBurn function on the hooks contract, only if the
     * BEFORE_BURN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The ids
     * @param amountsToBurn The amounts to burn
     */
    function beforeBurn(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) internal {
        if ((hooksParameters & BEFORE_BURN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeBurn.selector, sender, from, to, ids, amountsToBurn)
            );
        }
    }

    /**
     * @dev Helper function to call the afterBurn function on the hooks contract, only if the
     * AFTER_BURN_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The ids
     * @param amountsToBurn The amounts to burn
     */
    function afterBurn(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) internal {
        if ((hooksParameters & AFTER_BURN_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterBurn.selector, sender, from, to, ids, amountsToBurn)
            );
        }
    }

    /**
     * @dev Helper function to call the beforeTransferFrom function on the hooks contract, only if the
     * BEFORE_TRANSFER_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The list of ids
     * @param amounts The list of amounts
     */
    function beforeBatchTransferFrom(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        if ((hooksParameters & BEFORE_TRANSFER_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.beforeBatchTransferFrom.selector, sender, from, to, ids, amounts)
            );
        }
    }

    /**
     * @dev Helper function to call the afterTransferFrom function on the hooks contract, only if the
     * AFTER_TRANSFER_FLAG is set in the hooksParameters
     * @param hooksParameters The encoded hooks parameters
     * @param sender The sender
     * @param from The sender
     * @param to The recipient
     * @param ids The list of ids
     * @param amounts The list of amounts
     */
    function afterBatchTransferFrom(
        bytes32 hooksParameters,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) internal {
        if ((hooksParameters & AFTER_TRANSFER_FLAG) != 0) {
            _safeCall(
                hooksParameters,
                abi.encodeWithSelector(ILBHooks.afterBatchTransferFrom.selector, sender, from, to, ids, amounts)
            );
        }
    }

    /**
     * @dev Helper function to call the hooks contract and verify the call was successful
     * by matching the expected selector with the returned data
     * @param hooksParameters The encoded hooks parameters
     * @param data The data to pass to the hooks contract
     */
    function _safeCall(bytes32 hooksParameters, bytes memory data) private {
        bool success;

        address hooks = getHooks(hooksParameters);

        assembly {
            let expectedSelector := shr(224, mload(add(data, 0x20)))

            success := call(gas(), hooks, 0, add(data, 0x20), mload(data), 0, 0x20)

            if and(iszero(success), iszero(iszero(returndatasize()))) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            success := and(success, and(gt(returndatasize(), 0x1f), eq(shr(224, mload(0)), expectedSelector)))
        }

        if (!success) revert Hooks__CallFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {ILBHooks} from "./ILBHooks.sol";
import {ILBPair} from "./ILBPair.sol";

/**
 * @title Liquidity Book Factory Interface
 * @author Trader Joe
 * @notice Required interface of LBFactory contract
 */
interface ILBFactory {
    error LBFactory__IdenticalAddresses(IERC20 token);
    error LBFactory__QuoteAssetNotWhitelisted(IERC20 quoteAsset);
    error LBFactory__QuoteAssetAlreadyWhitelisted(IERC20 quoteAsset);
    error LBFactory__AddressZero();
    error LBFactory__LBPairAlreadyExists(IERC20 tokenX, IERC20 tokenY, uint256 _binStep);
    error LBFactory__LBPairDoesNotExist(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__LBPairNotCreated(IERC20 tokenX, IERC20 tokenY, uint256 binStep);
    error LBFactory__FlashLoanFeeAboveMax(uint256 fees, uint256 maxFees);
    error LBFactory__BinStepTooLow(uint256 binStep);
    error LBFactory__PresetIsLockedForUsers(address user, uint256 binStep);
    error LBFactory__LBPairIgnoredIsAlreadyInTheSameState();
    error LBFactory__BinStepHasNoPreset(uint256 binStep);
    error LBFactory__PresetOpenStateIsAlreadyInTheSameState();
    error LBFactory__SameFeeRecipient(address feeRecipient);
    error LBFactory__SameFlashLoanFee(uint256 flashLoanFee);
    error LBFactory__LBPairSafetyCheckFailed(address LBPairImplementation);
    error LBFactory__SameImplementation(address LBPairImplementation);
    error LBFactory__ImplementationNotSet();
    error LBFactory__SameHooksImplementation(address hooksImplementation);
    error LBFactory__SameHooksParameters(bytes32 hooksParameters);
    error LBFactory__InvalidHooksParameters();
    error LBFactory__CannotGrantDefaultAdminRole();

    /**
     * @dev Structure to store the LBPair information, such as:
     * binStep: The bin step of the LBPair
     * LBPair: The address of the LBPair
     * createdByOwner: Whether the pair was created by the owner of the factory
     * ignoredForRouting: Whether the pair is ignored for routing or not. An ignored pair will not be explored during routes finding
     */
    struct LBPairInformation {
        uint16 binStep;
        ILBPair LBPair;
        bool createdByOwner;
        bool ignoredForRouting;
    }

    event LBPairCreated(
        IERC20 indexed tokenX, IERC20 indexed tokenY, uint256 indexed binStep, ILBPair LBPair, uint256 pid
    );

    event FeeRecipientSet(address oldRecipient, address newRecipient);

    event FlashLoanFeeSet(uint256 oldFlashLoanFee, uint256 newFlashLoanFee);

    event LBPairImplementationSet(address oldLBPairImplementation, address LBPairImplementation);

    event LBPairIgnoredStateChanged(ILBPair indexed LBPair, bool ignored);

    event PresetSet(
        uint256 indexed binStep,
        uint256 baseFactor,
        uint256 filterPeriod,
        uint256 decayPeriod,
        uint256 reductionFactor,
        uint256 variableFeeControl,
        uint256 protocolShare,
        uint256 maxVolatilityAccumulator
    );

    event PresetOpenStateChanged(uint256 indexed binStep, bool indexed isOpen);

    event PresetRemoved(uint256 indexed binStep);

    event QuoteAssetAdded(IERC20 indexed quoteAsset);

    event QuoteAssetRemoved(IERC20 indexed quoteAsset);

    function getMinBinStep() external pure returns (uint256);

    function getFeeRecipient() external view returns (address);

    function getMaxFlashLoanFee() external pure returns (uint256);

    function getFlashLoanFee() external view returns (uint256);

    function getLBPairImplementation() external view returns (address);

    function getNumberOfLBPairs() external view returns (uint256);

    function getLBPairAtIndex(uint256 id) external returns (ILBPair);

    function getNumberOfQuoteAssets() external view returns (uint256);

    function getQuoteAssetAtIndex(uint256 index) external view returns (IERC20);

    function isQuoteAsset(IERC20 token) external view returns (bool);

    function getLBPairInformation(IERC20 tokenX, IERC20 tokenY, uint256 binStep)
        external
        view
        returns (LBPairInformation memory);

    function getPreset(uint256 binStep)
        external
        view
        returns (
            uint256 baseFactor,
            uint256 filterPeriod,
            uint256 decayPeriod,
            uint256 reductionFactor,
            uint256 variableFeeControl,
            uint256 protocolShare,
            uint256 maxAccumulator,
            bool isOpen
        );

    function getAllBinSteps() external view returns (uint256[] memory presetsBinStep);

    function getOpenBinSteps() external view returns (uint256[] memory openBinStep);

    function getAllLBPairs(IERC20 tokenX, IERC20 tokenY)
        external
        view
        returns (LBPairInformation[] memory LBPairsBinStep);

    function setLBPairImplementation(address lbPairImplementation) external;

    function createLBPair(IERC20 tokenX, IERC20 tokenY, uint24 activeId, uint16 binStep)
        external
        returns (ILBPair pair);

    function setLBPairIgnored(IERC20 tokenX, IERC20 tokenY, uint16 binStep, bool ignored) external;

    function setPreset(
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        bool isOpen
    ) external;

    function setPresetOpenState(uint16 binStep, bool isOpen) external;

    function removePreset(uint16 binStep) external;

    function setFeesParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setLBHooksParametersOnPair(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        bytes32 hooksParameters,
        bytes memory onHooksSetData
    ) external;

    function removeLBHooksOnPair(IERC20 tokenX, IERC20 tokenY, uint16 binStep) external;

    function setFeeRecipient(address feeRecipient) external;

    function setFlashLoanFee(uint256 flashLoanFee) external;

    function addQuoteAsset(IERC20 quoteAsset) external;

    function removeQuoteAsset(IERC20 quoteAsset) external;

    function forceDecay(ILBPair lbPair) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {Hooks} from "../libraries/Hooks.sol";
import {ILBFactory} from "./ILBFactory.sol";
import {ILBFlashLoanCallback} from "./ILBFlashLoanCallback.sol";
import {ILBToken} from "./ILBToken.sol";

interface ILBPair is ILBToken {
    error LBPair__ZeroBorrowAmount();
    error LBPair__AddressZero();
    error LBPair__EmptyMarketConfigs();
    error LBPair__FlashLoanCallbackFailed();
    error LBPair__FlashLoanInsufficientAmount();
    error LBPair__InsufficientAmountIn();
    error LBPair__InsufficientAmountOut();
    error LBPair__InvalidInput();
    error LBPair__InvalidStaticFeeParameters();
    error LBPair__OnlyFactory();
    error LBPair__OnlyProtocolFeeRecipient();
    error LBPair__OutOfLiquidity();
    error LBPair__TokenNotSupported();
    error LBPair__ZeroAmount(uint24 id);
    error LBPair__ZeroAmountsOut(uint24 id);
    error LBPair__ZeroShares(uint24 id);
    error LBPair__MaxTotalFeeExceeded();
    error LBPair__InvalidHooks();

    struct MintArrays {
        uint256[] ids;
        bytes32[] amounts;
        uint256[] liquidityMinted;
    }

    event DepositedToBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event WithdrawnFromBins(address indexed sender, address indexed to, uint256[] ids, bytes32[] amounts);

    event CompositionFees(address indexed sender, uint24 id, bytes32 totalFees, bytes32 protocolFees);

    event CollectedProtocolFees(address indexed feeRecipient, bytes32 protocolFees);

    event Swap(
        address indexed sender,
        address indexed to,
        uint24 id,
        bytes32 amountsIn,
        bytes32 amountsOut,
        uint24 volatilityAccumulator,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event StaticFeeParametersSet(
        address indexed sender,
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    );

    event HooksParametersSet(address indexed sender, bytes32 hooksParameters);

    event FlashLoan(
        address indexed sender,
        ILBFlashLoanCallback indexed receiver,
        uint24 activeId,
        bytes32 amounts,
        bytes32 totalFees,
        bytes32 protocolFees
    );

    event OracleLengthIncreased(address indexed sender, uint16 oracleLength);

    event ForcedDecay(address indexed sender, uint24 idReference, uint24 volatilityReference);

    function initialize(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator,
        uint24 activeId
    ) external;

    function implementation() external view returns (address);

    function getFactory() external view returns (ILBFactory factory);

    function getTokenX() external view returns (IERC20 tokenX);

    function getTokenY() external view returns (IERC20 tokenY);

    function getBinStep() external view returns (uint16 binStep);

    function getReserves() external view returns (uint128 reserveX, uint128 reserveY);

    function getActiveId() external view returns (uint24 activeId);

    function getBin(uint24 id) external view returns (uint128 binReserveX, uint128 binReserveY);

    function getNextNonEmptyBin(bool swapForY, uint24 id) external view returns (uint24 nextId);

    function getProtocolFees() external view returns (uint128 protocolFeeX, uint128 protocolFeeY);

    function getStaticFeeParameters()
        external
        view
        returns (
            uint16 baseFactor,
            uint16 filterPeriod,
            uint16 decayPeriod,
            uint16 reductionFactor,
            uint24 variableFeeControl,
            uint16 protocolShare,
            uint24 maxVolatilityAccumulator
        );

    function getLBHooksParameters() external view returns (bytes32 hooksParameters);

    function getVariableFeeParameters()
        external
        view
        returns (uint24 volatilityAccumulator, uint24 volatilityReference, uint24 idReference, uint40 timeOfLastUpdate);

    function getOracleParameters()
        external
        view
        returns (uint8 sampleLifetime, uint16 size, uint16 activeSize, uint40 lastUpdated, uint40 firstTimestamp);

    function getOracleSampleAt(uint40 lookupTimestamp)
        external
        view
        returns (uint64 cumulativeId, uint64 cumulativeVolatility, uint64 cumulativeBinCrossed);

    function getPriceFromId(uint24 id) external view returns (uint256 price);

    function getIdFromPrice(uint256 price) external view returns (uint24 id);

    function getSwapIn(uint128 amountOut, bool swapForY)
        external
        view
        returns (uint128 amountIn, uint128 amountOutLeft, uint128 fee);

    function getSwapOut(uint128 amountIn, bool swapForY)
        external
        view
        returns (uint128 amountInLeft, uint128 amountOut, uint128 fee);

    function swap(bool swapForY, address to) external returns (bytes32 amountsOut);

    function flashLoan(ILBFlashLoanCallback receiver, bytes32 amounts, bytes calldata data) external;

    function mint(address to, bytes32[] calldata liquidityConfigs, address refundTo)
        external
        returns (bytes32 amountsReceived, bytes32 amountsLeft, uint256[] memory liquidityMinted);

    function burn(address from, address to, uint256[] calldata ids, uint256[] calldata amountsToBurn)
        external
        returns (bytes32[] memory amounts);

    function collectProtocolFees() external returns (bytes32 collectedProtocolFees);

    function increaseOracleLength(uint16 newLength) external;

    function setStaticFeeParameters(
        uint16 baseFactor,
        uint16 filterPeriod,
        uint16 decayPeriod,
        uint16 reductionFactor,
        uint24 variableFeeControl,
        uint16 protocolShare,
        uint24 maxVolatilityAccumulator
    ) external;

    function setHooksParameters(bytes32 hooksParameters, bytes calldata onHooksSetData) external;

    function forceDecay() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IMasterChefRewarder} from "./IMasterChefRewarder.sol";
import {IMoe} from "./IMoe.sol";
import {IVeMoe} from "./IVeMoe.sol";
import {Rewarder} from "../libraries/Rewarder.sol";
import {Amounts} from "../libraries/Amounts.sol";
import {IRewarderFactory} from "./IRewarderFactory.sol";

interface IMasterChef {
    error MasterChef__InvalidShares();
    error MasterChef__InvalidMoePerSecond();
    error MasterChef__ZeroAddress();
    error MasterChef__NotMasterchefRewarder();
    error MasterChef__CannotRenounceOwnership();
    error MasterChef__MintFailed();

    struct Farm {
        Amounts.Parameter amounts;
        Rewarder.Parameter rewarder;
        IERC20 token;
        IMasterChefRewarder extraRewarder;
    }

    event PositionModified(uint256 indexed pid, address indexed account, int256 deltaAmount, uint256 moeReward);

    event MoePerSecondSet(uint256 moePerSecond);

    event FarmAdded(uint256 indexed pid, IERC20 indexed token);

    event ExtraRewarderSet(uint256 indexed pid, IMasterChefRewarder extraRewarder);

    event TreasurySet(address indexed treasury);

    function add(IERC20 token, IMasterChefRewarder extraRewarder) external;

    function claim(uint256[] memory pids) external;

    function deposit(uint256 pid, uint256 amount) external;

    function emergencyWithdraw(uint256 pid) external;

    function getDeposit(uint256 pid, address account) external view returns (uint256);

    function getLastUpdateTimestamp(uint256 pid) external view returns (uint256);

    function getPendingRewards(address account, uint256[] memory pids)
        external
        view
        returns (uint256[] memory moeRewards, IERC20[] memory extraTokens, uint256[] memory extraRewards);

    function getExtraRewarder(uint256 pid) external view returns (IMasterChefRewarder);

    function getMoe() external view returns (IMoe);

    function getMoePerSecond() external view returns (uint256);

    function getMoePerSecondForPid(uint256 pid) external view returns (uint256);

    function getNumberOfFarms() external view returns (uint256);

    function getToken(uint256 pid) external view returns (IERC20);

    function getTotalDeposit(uint256 pid) external view returns (uint256);

    function getTreasury() external view returns (address);

    function getTreasuryShare() external view returns (uint256);

    function getRewarderFactory() external view returns (IRewarderFactory);

    function getLBHooksManager() external view returns (address);

    function getVeMoe() external view returns (IVeMoe);

    function setExtraRewarder(uint256 pid, IMasterChefRewarder extraRewarder) external;

    function setMoePerSecond(uint96 moePerSecond) external;

    function setTreasury(address treasury) external;

    function updateAll(uint256[] calldata pids) external;

    function withdraw(uint256 pid, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILBHooksBaseRewarder} from "./ILBHooksBaseRewarder.sol";

/**
 * @title LB Hooks Parent Rewarder Interface
 * @dev Interface for the LB Hooks Parent Rewarder
 */
interface ILBHooksBaseParentRewarder is ILBHooksBaseRewarder {
    error LBHooksRewarder__InvalidLBHooksExtraRewarder();

    event LBHooksExtraRewarderSet(address lbHooksExtraRewarder);

    function getExtraHooksParameters() external view returns (bytes32 extraHooksParameters);

    function setLBHooksExtraRewarder(address lbHooksExtraRewarder, bytes calldata extraRewarderData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILBHooksBaseSimpleRewarder} from "./ILBHooksBaseSimpleRewarder.sol";
import {ILBHooksBaseParentRewarder} from "./ILBHooksBaseParentRewarder.sol";

/**
 * @title LB Hooks Extra Rewarder Interface
 * @dev Interface for the LB Hooks Extra Rewarder
 */
interface ILBHooksExtraRewarder is ILBHooksBaseSimpleRewarder {
    error LBHooksExtraRewarder__UnauthorizedCaller();
    error LBHooksExtraRewarder__ParentRewarderNotLinked();

    function getParentRewarder() external view returns (ILBHooksBaseParentRewarder);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILBHooks} from "@lb-protocol/src/interfaces/ILBHooks.sol";

/**
 * @title LB Hooks Manager Interface
 * @dev Interface for the LB Hooks Manager
 */
interface ILBHooksManager {
    error LBHooksManager__InvalidLBHooksType();
    error LBHooksManager__LBHooksParametersNotSet();
    error LBHooksManager__LBPairNotFound();
    error LBHooksManager__LBHooksNotSetOnPair();
    error LBHooksManager__UnorderedTokens();

    enum LBHooksType {
        Invalid,
        MCRewarder,
        ExtraRewarder,
        SimpleRewarder
    }

    event HooksParametersSet(LBHooksType lbHooksType, bytes32 hooksParameters);

    event HooksCreated(LBHooksType lbHooksType, uint256 id, ILBHooks hooks);

    function getLBHooksParameters(LBHooksType lbHooksType) external view returns (bytes32 hooksParameters);

    function getHooksAt(LBHooksType lbHooksType, uint256 index) external view returns (ILBHooks hooks);

    function getHooksLength(LBHooksType lbHooksType) external view returns (uint256 length);

    function getLBHooksType(ILBHooks hooks) external view returns (LBHooksType lbHooksType);

    function setLBHooksParameters(LBHooksType lbHooksType, bytes32 hooksParameters) external;

    function createLBHooksMCRewarder(IERC20 tokenX, IERC20 tokenY, uint16 binStep, address initialOwner)
        external
        returns (address);

    function createLBHooksSimpleRewarder(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        IERC20 rewardToken,
        address initialOwner
    ) external returns (address);

    function createLBHooksExtraRewarder(
        IERC20 tokenX,
        IERC20 tokenY,
        uint16 binStep,
        IERC20 rewardToken,
        address initialOwner
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILBPair} from "./ILBPair.sol";

import {Hooks} from "../libraries/Hooks.sol";

interface ILBHooks {
    function getLBPair() external view returns (ILBPair);

    function isLinked() external view returns (bool);

    function onHooksSet(bytes32 hooksParameters, bytes calldata onHooksSetData) external returns (bytes4);

    function beforeSwap(address sender, address to, bool swapForY, bytes32 amountsIn) external returns (bytes4);

    function afterSwap(address sender, address to, bool swapForY, bytes32 amountsOut) external returns (bytes4);

    function beforeFlashLoan(address sender, address to, bytes32 amounts) external returns (bytes4);

    function afterFlashLoan(address sender, address to, bytes32 fees, bytes32 feesReceived) external returns (bytes4);

    function beforeMint(address sender, address to, bytes32[] calldata liquidityConfigs, bytes32 amountsReceived)
        external
        returns (bytes4);

    function afterMint(address sender, address to, bytes32[] calldata liquidityConfigs, bytes32 amountsIn)
        external
        returns (bytes4);

    function beforeBurn(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes4);

    function afterBurn(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amountsToBurn
    ) external returns (bytes4);

    function beforeBatchTransferFrom(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (bytes4);

    function afterBatchTransferFrom(
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Liquidity Book Flashloan Callback Interface
/// @author Trader Joe
/// @notice Required interface to interact with LB flash loans
interface ILBFlashLoanCallback {
    function LBFlashLoanCallback(
        address sender,
        IERC20 tokenX,
        IERC20 tokenY,
        bytes32 amounts,
        bytes32 totalFees,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @title Liquidity Book Token Interface
 * @author Trader Joe
 * @notice Interface to interact with the LBToken.
 */
interface ILBToken {
    error LBToken__AddressThisOrZero();
    error LBToken__InvalidLength();
    error LBToken__SelfApproval(address owner);
    error LBToken__SpenderNotApproved(address from, address spender);
    error LBToken__TransferExceedsBalance(address from, uint256 id, uint256 amount);
    error LBToken__BurnExceedsBalance(address from, uint256 id, uint256 amount);

    event TransferBatch(
        address indexed sender, address indexed from, address indexed to, uint256[] ids, uint256[] amounts
    );

    event ApprovalForAll(address indexed account, address indexed sender, bool approved);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply(uint256 id) external view returns (uint256);

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    function isApprovedForAll(address owner, address spender) external view returns (bool);

    function approveForAll(address spender, bool approved) external;

    function batchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseRewarder} from "./IBaseRewarder.sol";

interface IMasterChefRewarder is IBaseRewarder {
    error MasterChefRewarder__AlreadyLinked();
    error MasterChefRewarder__NotLinked();
    error MasterChefRewarder__UseUnlink();

    enum Status {
        Unlinked,
        Linked,
        Stopped
    }

    function link(uint256 pid) external;

    function unlink(uint256 pid) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMoe is IERC20 {
    error Moe__NotMinter(address account);
    error Moe__InvalidInitialSupply();

    function getMinter() external view returns (address);

    function getMaxSupply() external view returns (uint256);

    function mint(address account, uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVeMoeRewarder} from "./IVeMoeRewarder.sol";
import {IMoeStaking} from "./IMoeStaking.sol";
import {IMasterChef} from "./IMasterChef.sol";
import {Amounts} from "../libraries/Amounts.sol";
import {Rewarder} from "../libraries/Rewarder.sol";
import {IRewarderFactory} from "./IRewarderFactory.sol";

interface IVeMoe {
    error VeMoe__InvalidLength();
    error VeMoe__InsufficientVeMoe(uint256 totalVeMoe, uint256 requiredVeMoe);
    error VeMoe__InvalidCaller();
    error VeMoe__InvalidBribeAddress();
    error VeMoe__InvalidPid(uint256 pid);
    error VeMoe__InvalidWeight();
    error VeMoe__InvalidAlpha();
    error VeMoe__CannotUnstakeWithVotes();
    error VeMoe__NoBribeForPid(uint256 pid);
    error VeMoe__TooManyPoolIds();
    error VeMoe__DuplicatePoolId(uint256 pid);
    error VeMoe__CannotRenounceOwnership();

    struct User {
        uint256 veMoe;
        Amounts.Parameter votes;
        mapping(uint256 => IVeMoeRewarder) bribes;
    }

    struct Reward {
        Rewarder.Parameter rewarder;
        IERC20 token;
        uint256 reserve;
    }

    struct BribeReward {
        IVeMoeRewarder bribe;
        uint256 rewardAmount;
    }

    event BribesSet(address indexed account, uint256[] pids, IVeMoeRewarder[] bribes);

    event Claim(address indexed account, int256 deltaVeMoe);

    event TopPoolIdsSet(uint256[] topPoolIds);

    event Vote(address account, uint256[] pids, int256[] deltaVeAmounts);

    event VeMoePerSecondPerMoeSet(uint256 veMoePerSecondPerMoe);

    event AlphaSet(uint256 alpha);

    function balanceOf(address account) external view returns (uint256 veMoe);

    function claim(uint256[] memory pids) external;

    function emergencyUnsetBribes(uint256[] memory pids) external;

    function getBribesOf(address account, uint256 pid) external view returns (IVeMoeRewarder);

    function getBribesTotalVotes(IVeMoeRewarder bribe, uint256 pid) external view returns (uint256);

    function getMasterChef() external view returns (IMasterChef);

    function getMaxVeMoePerMoe() external view returns (uint256);

    function getMoeStaking() external view returns (IMoeStaking);

    function getPendingRewards(address account, uint256[] calldata pids)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory pendingRewards);

    function getTopPidsTotalVotes() external view returns (uint256);

    function getTopPoolIds() external view returns (uint256[] memory);

    function getTotalVotes() external view returns (uint256);

    function getTotalWeight() external view returns (uint256);

    function getTotalVotesOf(address account) external view returns (uint256);

    function getVeMoePerSecondPerMoe() external view returns (uint256);

    function getVotes(uint256 pid) external view returns (uint256);

    function getWeight(uint256 pid) external view returns (uint256);

    function getVotesOf(address account, uint256 pid) external view returns (uint256);

    function getAlpha() external view returns (uint256);

    function getRewarderFactory() external view returns (IRewarderFactory);

    function isInTopPoolIds(uint256 pid) external view returns (bool);

    function onModify(address account, uint256 oldBalance, uint256 newBalance, uint256 oldTotalSupply, uint256)
        external;

    function setBribes(uint256[] memory pids, IVeMoeRewarder[] memory bribes) external;

    function setTopPoolIds(uint256[] memory pids) external;

    function setAlpha(uint256 alpha) external;

    function setVeMoePerSecondPerMoe(uint256 veMoePerSecondPerMoe) external;

    function vote(uint256[] memory pids, int256[] memory deltaAmounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Amounts} from "./Amounts.sol";
import {Constants} from "./Constants.sol";

/**
 * @title Rewarder Library
 * @dev A library that defines various functions for calculating rewards.
 * It takes care about the reward debt and the accumulated debt per share.
 */
library Rewarder {
    using Amounts for Amounts.Parameter;

    struct Parameter {
        uint256 lastUpdateTimestamp;
        uint256 accDebtPerShare;
        mapping(address => uint256) debt;
    }

    /**
     * @dev Returns the debt associated with an amount.
     * @param accDebtPerShare The accumulated debt per share.
     * @param deposit The amount.
     * @return The debt associated with the amount.
     */
    function getDebt(uint256 accDebtPerShare, uint256 deposit) internal pure returns (uint256) {
        return (deposit * accDebtPerShare) >> Constants.ACC_PRECISION_BITS;
    }

    /**
     * @dev Returns the debt per share associated with a total deposit and total rewards.
     * @param totalDeposit The total deposit.
     * @param totalRewards The total rewards.
     * @return The debt per share associated with the total deposit and total rewards.
     */
    function getDebtPerShare(uint256 totalDeposit, uint256 totalRewards) internal pure returns (uint256) {
        return totalDeposit == 0 ? 0 : (totalRewards << Constants.ACC_PRECISION_BITS) / totalDeposit;
    }

    /**
     * @dev Returns the total rewards to emit.
     * If the end timestamp is in the past, the rewards are calculated up to the end timestamp.
     * If the last update timestamp is in the future, it will return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param rewardPerSecond The reward per second.
     * @param endTimestamp The end timestamp.
     * @param totalSupply The total supply.
     * @return The total rewards.
     */
    function getTotalRewards(
        Parameter storage rewarder,
        uint256 rewardPerSecond,
        uint256 endTimestamp,
        uint256 totalSupply
    ) internal view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 lastUpdateTimestamp = rewarder.lastUpdateTimestamp;
        uint256 timestamp = block.timestamp > endTimestamp ? endTimestamp : block.timestamp;

        return timestamp > lastUpdateTimestamp ? (timestamp - lastUpdateTimestamp) * rewardPerSecond : 0;
    }

    /**
     * @dev Returns the total rewards to emit.
     * @param rewarder The storage pointer to the rewarder.
     * @param rewardPerSecond The reward per second.
     * @param totalSupply The total supply.
     * @return The total rewards.
     */
    function getTotalRewards(Parameter storage rewarder, uint256 rewardPerSecond, uint256 totalSupply)
        internal
        view
        returns (uint256)
    {
        return getTotalRewards(rewarder, rewardPerSecond, block.timestamp, totalSupply);
    }

    /**
     * @dev Returns the pending reward of an account.
     * @param rewarder The storage pointer to the rewarder.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the account.
     * @param totalRewards The total rewards.
     * @return The pending reward of the account.
     */
    function getPendingReward(
        Parameter storage rewarder,
        Amounts.Parameter storage amounts,
        address account,
        uint256 totalRewards
    ) internal view returns (uint256) {
        return getPendingReward(rewarder, account, amounts.getAmountOf(account), amounts.getTotalAmount(), totalRewards);
    }

    /**
     * @dev Returns the pending reward of an account.
     * If the balance of the account is 0, it will always return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param account The address of the account.
     * @param balance The balance of the account.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return The pending reward of the account.
     */
    function getPendingReward(
        Parameter storage rewarder,
        address account,
        uint256 balance,
        uint256 totalSupply,
        uint256 totalRewards
    ) internal view returns (uint256) {
        uint256 accDebtPerShare = rewarder.accDebtPerShare + getDebtPerShare(totalSupply, totalRewards);

        return balance == 0 ? 0 : getDebt(accDebtPerShare, balance) - rewarder.debt[account];
    }

    /**
     * @dev Updates the rewarder.
     * If the balance of the account is 0, it will always return 0.
     * @param rewarder The storage pointer to the rewarder.
     * @param account The address of the account.
     * @param oldBalance The old balance of the account.
     * @param newBalance The new balance of the account.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return rewards The rewards of the account.
     */
    function update(
        Parameter storage rewarder,
        address account,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 totalSupply,
        uint256 totalRewards
    ) internal returns (uint256 rewards) {
        uint256 accDebtPerShare = updateAccDebtPerShare(rewarder, totalSupply, totalRewards);

        rewards = oldBalance == 0 ? 0 : getDebt(accDebtPerShare, oldBalance) - rewarder.debt[account];

        rewarder.debt[account] = getDebt(accDebtPerShare, newBalance);
    }

    /**
     * @dev Updates the accumulated debt per share.
     * If the last update timestamp is in the future, it will not update the last update timestamp.
     * @param rewarder The storage pointer to the rewarder.
     * @param totalSupply The total supply.
     * @param totalRewards The total rewards.
     * @return The accumulated debt per share.
     */
    function updateAccDebtPerShare(Parameter storage rewarder, uint256 totalSupply, uint256 totalRewards)
        internal
        returns (uint256)
    {
        uint256 debtPerShare = getDebtPerShare(totalSupply, totalRewards);

        if (block.timestamp > rewarder.lastUpdateTimestamp) rewarder.lastUpdateTimestamp = block.timestamp;

        return debtPerShare == 0 ? rewarder.accDebtPerShare : rewarder.accDebtPerShare += debtPerShare;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Math} from "./Math.sol";

/**
 * @title Amounts Library
 * @dev A library that defines various functions for manipulating amounts of a key and a total.
 * The key can be bytes32, address, or uint256.
 */
library Amounts {
    using Math for uint256;

    struct Parameter {
        uint256 totalAmount;
        mapping(bytes32 => uint256) amounts;
    }

    /**
     * @dev Returns the amount of a key.
     * @param amounts The storage pointer to the amounts.
     * @param key The key of the amount.
     * @return The amount of the key.
     */
    function getAmountOf(Parameter storage amounts, bytes32 key) internal view returns (uint256) {
        return amounts.amounts[key];
    }

    /**
     * @dev Returns the amount of an address.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the amount.
     * @return The amount of the address.
     */
    function getAmountOf(Parameter storage amounts, address account) internal view returns (uint256) {
        return getAmountOf(amounts, bytes32(uint256(uint160(account))));
    }

    /**
     * @dev Returns the amount of an id.
     * @param amounts The storage pointer to the amounts.
     * @param id The id of the amount.
     * @return The amount of the id.
     */
    function getAmountOf(Parameter storage amounts, uint256 id) internal view returns (uint256) {
        return getAmountOf(amounts, bytes32(id));
    }

    /**
     * @dev Returns the total amount.
     * @param amounts The storage pointer to the amounts.
     * @return The total amount.
     */
    function getTotalAmount(Parameter storage amounts) internal view returns (uint256) {
        return amounts.totalAmount;
    }

    /**
     * @dev Updates the amount of a key. The delta is added to the key amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param key The key of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, bytes32 key, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        oldAmount = amounts.amounts[key];
        oldTotalAmount = amounts.totalAmount;

        if (deltaAmount == 0) {
            newAmount = oldAmount;
            newTotalAmount = oldTotalAmount;
        } else {
            newAmount = oldAmount.addDelta(deltaAmount);
            newTotalAmount = oldTotalAmount.addDelta(deltaAmount);

            amounts.amounts[key] = newAmount;
            amounts.totalAmount = newTotalAmount;
        }
    }

    /**
     * @dev Updates the amount of an address. The delta is added to the address amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param account The address of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, address account, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        return update(amounts, bytes32(uint256(uint160(account))), deltaAmount);
    }

    /**
     * @dev Updates the amount of an id. The delta is added to the id amount and the total amount.
     * @param amounts The storage pointer to the amounts.
     * @param id The id of the amount.
     * @param deltaAmount The delta amount to update.
     * @return oldAmount The old amount of the key.
     * @return newAmount The new amount of the key.
     * @return oldTotalAmount The old total amount.
     * @return newTotalAmount The new total amount.
     */
    function update(Parameter storage amounts, uint256 id, int256 deltaAmount)
        internal
        returns (uint256 oldAmount, uint256 newAmount, uint256 oldTotalAmount, uint256 newTotalAmount)
    {
        return update(amounts, bytes32(id), deltaAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBaseRewarder} from "../interfaces/IBaseRewarder.sol";

interface IRewarderFactory {
    error RewarderFactory__ZeroAddress();
    error RewarderFactory__InvalidRewarderType();
    error RewarderFactory__InvalidPid();

    enum RewarderType {
        InvalidRewarder,
        MasterChefRewarder,
        VeMoeRewarder,
        JoeStakingRewarder
    }

    event RewarderCreated(
        RewarderType indexed rewarderType, IERC20 indexed token, uint256 indexed pid, IBaseRewarder rewarder
    );

    event RewarderImplementationSet(RewarderType indexed rewarderType, IBaseRewarder indexed implementation);

    function getRewarderImplementation(RewarderType rewarderType) external view returns (IBaseRewarder);

    function getRewarderCount(RewarderType rewarderType) external view returns (uint256);

    function getRewarderAt(RewarderType rewarderType, uint256 index) external view returns (IBaseRewarder);

    function getRewarderType(IBaseRewarder rewarder) external view returns (RewarderType);

    function setRewarderImplementation(RewarderType rewarderType, IBaseRewarder implementation) external;

    function createRewarder(RewarderType rewarderType, IERC20 token, uint256 pid) external returns (IBaseRewarder);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILBHooks} from "@lb-protocol/src/interfaces/ILBHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title LB Hooks Base Rewarder Interface
 * @dev Interface for the LB Hooks Base Rewarder
 */
interface ILBHooksBaseRewarder is ILBHooks {
    error LBHooksBaseRewarder__InvalidDeltaBins();
    error LBHooksBaseRewarder__Overflow();
    error LBHooksBaseRewarder__NativeTransferFailed();
    error LBHooksBaseRewarder__UnlinkedHooks();
    error LBHooksBaseRewarder__InvalidHooksParameters();
    error LBHooksBaseRewarder__ZeroBalance();
    error LBHooksBaseRewarder__LockedRewardToken();
    error LBHooksBaseRewarder__NotNativeRewarder();
    error LBHooksBaseRewarder__NotImplemented();
    error LBHooksBaseRewarder__UnauthorizedCaller();
    error LBHooksBaseRewarder__ExceedsMaxNumberOfBins();

    event DeltaBinsSet(int24 deltaBinA, int24 deltaBinB);
    event Claim(address indexed user, uint256 amount);

    struct Bin {
        uint256 accRewardsPerShareX64;
        mapping(address => uint256) userAccRewardsPerShareX64;
    }

    function getRewardToken() external view returns (IERC20);

    function getLBHooksManager() external view returns (address);

    function isStopped() external view returns (bool);

    function getRewardedRange() external view returns (uint256 binStart, uint256 binEnd);

    function getPendingRewards(address user, uint256[] calldata ids) external view returns (uint256 pendingRewards);

    function claim(address user, uint256[] calldata ids) external;

    function setDeltaBins(int24 deltaBinA, int24 deltaBinB) external;

    function sweep(IERC20 token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ILBHooksBaseRewarder} from "./ILBHooksBaseRewarder.sol";

/**
 * @title LB Hooks Simple Rewarder Interface
 * @dev Interface for the LB Hooks Simple Rewarder
 */
interface ILBHooksBaseSimpleRewarder is ILBHooksBaseRewarder {
    error LBHooksBaseSimpleRewarder__InvalidStartTimestamp();
    error LBHooksBaseSimpleRewarder__InvalidDuration();
    error LBHooksBaseSimpleRewarder__ZeroReward();
    error LBHooksBaseSimpleRewarder__Stopped();

    event RewardParameterUpdated(uint256 rewardPerSecond, uint256 startTimestamp, uint256 endTimestamp);

    function getRewarderParameter()
        external
        view
        returns (uint256 rewardPerSecond, uint256 lastUpdateTimestamp, uint256 endTimestamp);

    function getRemainingRewards() external view returns (uint256 remainingRewards);

    function setRewarderParameters(uint256 maxRewardPerSecond, uint256 startTimestamp, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);

    function setRewardPerSecond(uint256 maxRewardPerSecond, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBaseRewarder {
    error BaseRewarder__NativeTransferFailed();
    error BaseRewarder__InvalidCaller();
    error BaseRewarder__Stopped();
    error BaseRewarder__AlreadyStopped();
    error BaseRewarder__NotNativeRewarder();
    error BaseRewarder__ZeroAmount();
    error BaseRewarder__ZeroReward();
    error BaseRewarder__InvalidDuration();
    error BaseRewarder__InvalidPid(uint256 pid);
    error BaseRewarder__InvalidStartTimestamp(uint256 startTimestamp);
    error BaseRewarder__CannotRenounceOwnership();

    event Claim(address indexed account, IERC20 indexed token, uint256 reward);

    event RewardParameterUpdated(uint256 rewardPerSecond, uint256 startTimestamp, uint256 endTimestamp);

    event Stopped();

    event Swept(IERC20 indexed token, address indexed account, uint256 amount);

    function getToken() external view returns (IERC20);

    function getCaller() external view returns (address);

    function getPid() external view returns (uint256);

    function getRewarderParameter()
        external
        view
        returns (IERC20 token, uint256 rewardPerSecond, uint256 lastUpdateTimestamp, uint256 endTimestamp);

    function getRemainingReward() external view returns (uint256);

    function getPendingReward(address account, uint256 balance, uint256 totalSupply)
        external
        view
        returns (IERC20 token, uint256 pendingReward);

    function isStopped() external view returns (bool);

    function initialize(address initialOwner) external;

    function setRewardPerSecond(uint256 maxRewardPerSecond, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);

    function setRewarderParameters(uint256 maxRewardPerSecond, uint256 startTimestamp, uint256 expectedDuration)
        external
        returns (uint256 rewardPerSecond);

    function stop() external;

    function sweep(IERC20 token, address account) external;

    function onModify(address account, uint256 pid, uint256 oldBalance, uint256 newBalance, uint256 totalSupply)
        external
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBaseRewarder} from "./IBaseRewarder.sol";

interface IVeMoeRewarder is IBaseRewarder {
    function claim(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMoe} from "./IMoe.sol";
import {IVeMoe} from "./IVeMoe.sol";
import {IStableMoe} from "./IStableMoe.sol";

interface IMoeStaking {
    event PositionModified(address indexed account, int256 deltaAmount);

    function getMoe() external view returns (IMoe);

    function getVeMoe() external view returns (IVeMoe);

    function getSMoe() external view returns (IStableMoe);

    function getDeposit(address account) external view returns (uint256);

    function getTotalDeposit() external view returns (uint256);

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function claim() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Constants Library
 * @dev A library that defines various constants used throughout the codebase.
 */
library Constants {
    uint256 internal constant ACC_PRECISION_BITS = 64;
    uint256 internal constant PRECISION = 1e18;

    uint256 internal constant MAX_NUMBER_OF_FARMS = 32;
    uint256 internal constant MAX_NUMBER_OF_REWARDS = 32;

    uint256 internal constant MAX_MOE_PER_SECOND = 10e18;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Math
 * @dev Library for mathematical operations with overflow and underflow checks.
 */
library Math {
    error Math__UnderOverflow();

    uint256 internal constant MAX_INT256 = 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /**
     * @dev Adds a signed integer to an unsigned integer with overflow check.
     * The result must be greater than or equal to 0 and less than or equal to MAX_INT256.
     * @param x Unsigned integer to add to.
     * @param delta Signed integer to add.
     * @return y The result of the addition.
     */
    function addDelta(uint256 x, int256 delta) internal pure returns (uint256 y) {
        uint256 success;

        assembly {
            y := add(x, delta)

            success := iszero(or(gt(x, MAX_INT256), gt(y, MAX_INT256)))
        }

        if (success == 0) revert Math__UnderOverflow();
    }

    /**
     * @dev Safely converts an unsigned integer to a signed integer.
     * @param x Unsigned integer to convert.
     * @return y Signed integer result.
     */
    function toInt256(uint256 x) internal pure returns (int256 y) {
        if (x > MAX_INT256) revert Math__UnderOverflow();

        return int256(x);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Rewarder} from "../libraries/Rewarder.sol";
import {IMoeStaking} from "../interfaces/IMoeStaking.sol";

interface IStableMoe {
    error StableMoe__UnauthorizedCaller();
    error StableMoe__RewardAlreadyAdded(IERC20 reward);
    error StableMoe__RewardAlreadyRemoved(IERC20 reward);
    error StableMoe__ActiveReward(IERC20 reward);
    error StableMoe__NativeTransferFailed();
    error StableMoe__TooManyActiveRewards();
    error StableMoe__CannotRenounceOwnership();

    struct Reward {
        Rewarder.Parameter rewarder;
        uint256 reserve;
    }

    event Claim(address indexed account, IERC20 indexed token, uint256 amount);

    event AddReward(IERC20 indexed reward);

    event RemoveReward(IERC20 indexed reward);

    event Sweep(IERC20 indexed token, address indexed account);

    function getMoeStaking() external view returns (IMoeStaking);

    function getNumberOfRewards() external view returns (uint256);

    function getRewardToken(uint256 id) external view returns (address);

    function getRewardTokens() external view returns (address[] memory);

    function getPendingRewards(address account)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory rewards);

    function claim() external;

    function onModify(
        address account,
        uint256 oldBalance,
        uint256 newBalance,
        uint256 oldTotalSupply,
        uint256 newTotalSupply
    ) external;

    function addReward(IERC20 reward) external;

    function removeReward(IERC20 reward) external;

    function sweep(IERC20 token, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC1363} from "../../../interfaces/IERC1363.sol";
import {Address} from "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC-20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev An operation with an ERC-20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Performs an {ERC1363} transferAndCall, with a fallback to the simple {ERC20} transfer if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            safeTransfer(token, to, value);
        } else if (!token.transferAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} transferFromAndCall, with a fallback to the simple {ERC20} transferFrom if the target
     * has no code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * Reverts if the returned value is other than `true`.
     */
    function transferFromAndCallRelaxed(
        IERC1363 token,
        address from,
        address to,
        uint256 value,
        bytes memory data
    ) internal {
        if (to.code.length == 0) {
            safeTransferFrom(token, from, to, value);
        } else if (!token.transferFromAndCall(from, to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Performs an {ERC1363} approveAndCall, with a fallback to the simple {ERC20} approve if the target has no
     * code. This can be used to implement an {ERC721}-like safe transfer that rely on {ERC1363} checks when
     * targeting contracts.
     *
     * NOTE: When the recipient address (`to`) has no code (i.e. is an EOA), this function behaves as {forceApprove}.
     * Opposedly, when the recipient address (`to`) has code, this function only attempts to call {ERC1363-approveAndCall}
     * once without retrying, and relies on the returned value to be true.
     *
     * Reverts if the returned value is other than `true`.
     */
    function approveAndCallRelaxed(IERC1363 token, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            forceApprove(token, to, value);
        } else if (!token.approveAndCall(to, value, data)) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC1363.sol)

pragma solidity ^0.8.20;

import {IERC20} from "./IERC20.sol";
import {IERC165} from "./IERC165.sol";

/**
 * @title IERC1363
 * @dev Interface of the ERC-1363 standard as defined in the https://eips.ethereum.org/EIPS/eip-1363[ERC-1363].
 *
 * Defines an extension interface for ERC-20 tokens that supports executing code on a recipient contract
 * after `transfer` or `transferFrom`, or code on a spender contract after `approve`, in a single transaction.
 */
interface IERC1363 is IERC20, IERC165 {
    /*
     * Note: the ERC-165 identifier for this interface is 0xb0202a11.
     * 0xb0202a11 ===
     *   bytes4(keccak256('transferAndCall(address,uint256)')) ^
     *   bytes4(keccak256('transferAndCall(address,uint256,bytes)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256)')) ^
     *   bytes4(keccak256('transferFromAndCall(address,address,uint256,bytes)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256)')) ^
     *   bytes4(keccak256('approveAndCall(address,uint256,bytes)'))
     */

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the allowance mechanism
     * and then calls {IERC1363Receiver-onTransferReceived} on `to`.
     * @param from The address which you want to send tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @param data Additional data with no specified format, sent in call to `to`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function transferFromAndCall(address from, address to, uint256 value, bytes calldata data) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value) external returns (bool);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens and then calls {IERC1363Spender-onApprovalReceived} on `spender`.
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @param data Additional data with no specified format, sent in call to `spender`.
     * @return A boolean value indicating whether the operation succeeded unless throwing.
     */
    function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

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
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC-165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[ERC].
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
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[ERC section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}