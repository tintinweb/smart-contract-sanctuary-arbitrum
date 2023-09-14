// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {ERC2771Context} from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import {Auth} from "contracts/utils/Auth.sol";
import {IAccount} from "contracts/interfaces/IAccount.sol";
import {IFactory} from "contracts/interfaces/IFactory.sol";
import {IEvents} from "contracts/interfaces/IEvents.sol";

/// @title Excarbon Smart Account Implementation
contract Account is IAccount, Auth, ERC2771Context {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    bytes32 public constant VERSION = "0.1.0";

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the Smart Account Factory
    IFactory internal immutable FACTORY;

    /// @notice address of the contract used by all accounts for emitting events
    /// @dev can be immutable due to the fact the events contract is
    /// upgraded alongside the account implementation
    IEvents internal immutable EVENTS;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice value used for reentrancy protection
    /// @dev nonReentrant checks that locked is NOT EQUAL to 2
    uint256 internal locked;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier nonReentrant() {
        /// @dev locked is intially set to 0 due to the proxy nature of SM accounts
        /// however after the inital call to nonReentrant(), locked will be set to 1
        if (locked == 2) revert Reentrancy();
        locked = 2;

        _;

        locked = 1;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev set owner of implementation to zero address
    /// @param _params: constructor parameters (see IAccount.sol)
    constructor(
        AccountConstructorParams memory _params
    ) Auth(address(0)) ERC2771Context(_params.trustedForwarder) {
        FACTORY = IFactory(_params.factory);
        EVENTS = IEvents(_params.events);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function setInitialOwnership(address _owner) external override {
        if (msg.sender != address(FACTORY)) revert Unauthorized();
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @notice transfer ownership of account to new address
    /// @dev update factory's record of account ownership
    /// @param _newOwner: new account owner
    function transferOwnership(address _newOwner) public override {
        // will revert if msg.sender is *NOT* owner
        super.transferOwnership(_newOwner);

        // update the factory's record of owners and account addresses
        FACTORY.updateAccountOwnership({
            _newOwner: _newOwner,
            _oldOwner: msg.sender // verified to be old owner
        });
    }

    /*//////////////////////////////////////////////////////////////
                               EXECUTION
    //////////////////////////////////////////////////////////////*/

    // /// @inheritdoc IAccount
    // function execute(
    //     Command[] calldata _commands,
    //     bytes[] calldata _inputs
    // ) external payable override nonReentrant {
    //     uint256 numCommands = _commands.length;
    //     if (_inputs.length != numCommands) {
    //         revert LengthMismatch();
    //     }

    //     // loop through all given commands and execute them
    //     for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
    //         _dispatch(
    //             msg.sender,
    //             _commands[commandIndex],
    //             _inputs[commandIndex]
    //         );
    //         unchecked {
    //             ++commandIndex;
    //         }
    //     }
    // }

    /// @inheritdoc IAccount
    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external {
        address msgSender = _msgSender();
        uint256 numCommands = _commands.length;
        if (_inputs.length != numCommands) {
            revert LengthMismatch();
        }
        // loop through all given commands and execute them
        for (uint256 commandIndex = 0; commandIndex < numCommands; ) {
            _dispatch(
                msgSender,
                _commands[commandIndex],
                _inputs[commandIndex]
            );
            unchecked {
                ++commandIndex;
            }
        }
    }

    /// @notice Decodes and executes the given command with the given inputs
    /// @param _command: The command type to execute
    /// @param _inputs: The inputs to execute the command with
    function _dispatch(
        address msgSender,
        Command _command,
        bytes calldata _inputs
    ) internal {
        uint256 commandIndex = uint256(_command);

        if (commandIndex < 2) {
            /// @dev only owner can execute the following commands
            if (!isOwner(msgSender)) revert Unauthorized();

            if (_command == Command.ACCOUNT_WITHDRAW_ETH) {
                uint256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _withdrawEth({_amount: amount, _msgSender: msgSender});
            }
        } else {
            /// @dev only owner and delegate(s) can execute the following commands
            if (!isAuth(msgSender)) revert Unauthorized();
            // TODO: Command here

            if (_command == Command.TRANSFER_NFT) {
                address _token;
                address _receiver;
                uint256 _tokenId;
                uint256 _quantity;
                uint256 _price;
                assembly {
                    _token := calldataload(_inputs.offset)
                    _receiver := calldataload(add(_inputs.offset, 0x20))
                    _tokenId := calldataload(add(_inputs.offset, 0x40))
                    _quantity := calldataload(add(_inputs.offset, 0x60))
                    _price := calldataload(add(_inputs.offset, 0x80))
                }
                _transferNFT(_token, _receiver, _tokenId, _quantity, _price);
            }
            if (commandIndex == 0 || commandIndex > 2) {
                revert InvalidCommandType(commandIndex);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNT DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice allows ETH to be deposited directly into a margin account
    /// @notice ETH can be withdrawn
    receive() external payable {}

    /// @notice allow users to withdraw ETH deposited for keeper fees
    /// @param _amount: amount to withdraw
    function _withdrawEth(uint256 _amount, address _msgSender) internal {
        if (_amount > 0) {
            (bool success, ) = payable(_msgSender).call{value: _amount}("");
            if (!success) revert EthWithdrawalFailed();

            EVENTS.emitEthWithdraw({user: _msgSender, amount: _amount});
        }
    }

    function _transferNFT(
        address _token,
        address _receiver,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _price
    ) internal {
        EVENTS.emitTransferNFT({
            token: _token,
            receiver: _receiver,
            tokenId: _tokenId,
            quantity: _quantity,
            price: _price
        });
    }

    /*//////////////////////////////////////////////////////////////
                             MATH UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x: signed number
    /// @return z uint256 absolute value of x
    function _abs(int256 x) internal pure returns (uint256 z) {
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x: signed number
    /// @param y: signed number
    /// @return true if same sign, false otherwise
    function _isSameSign(int256 x, int256 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.1;

/**
 * @dev Context variant with ERC2771 support.
 */
// based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/metatx/ERC2771Context.sol
abstract contract ERC2771Context {
    address private immutable _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder)
        public
        view
        virtual
        returns (bool)
    {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @notice Authorization mixin for Smart Margin Accounts
/// @author JaredBorders ([email protected])
/// @dev This contract is intended to be inherited by the Account contract
abstract contract Auth {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice owner of the account
    address public owner;

    /// @notice mapping of delegate address
    mapping(address delegate => bool) public delegates;

    /// @dev reserved storage space for future contract upgrades
    /// @custom:caution reduce storage size when adding new storage variables
    uint256[19] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when an unauthorized caller attempts
    /// to access a caller restricted function
    error Unauthorized();

    /// @notice thrown when the delegate address is invalid
    /// @param delegateAddress: address of the delegate attempting to be added
    error InvalidDelegateAddress(address delegateAddress);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted after ownership transfer
    /// @param caller: previous owner
    /// @param newOwner: new owner
    event OwnershipTransferred(
        address indexed caller,
        address indexed newOwner
    );

    /// @notice emitted after a delegate is added
    /// @param caller: owner of the account
    /// @param delegate: address of the delegate being added
    event DelegatedAccountAdded(
        address indexed caller,
        address indexed delegate
    );

    /// @notice emitted after a delegate is removed
    /// @param caller: owner of the account
    /// @param delegate: address of the delegate being removed
    event DelegatedAccountRemoved(
        address indexed caller,
        address indexed delegate
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev sets owner to _owner and not msg.sender
    /// @param _owner The address of the owner
    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @return true if the caller is the owner
    function isOwner(address msgSender) public view virtual returns (bool) {
        return (msgSender == owner);
    }

    /// @return true if the caller is the owner or a delegate
    function isAuth(address msgSender) public view virtual returns (bool) {
        return (msgSender == owner || delegates[msgSender]);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer ownership of the account
    /// @dev only owner can transfer ownership (not delegates)
    /// @param _newOwner The address of the new owner
    function transferOwnership(address _newOwner) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    /// @notice Add a delegate to the account
    /// @dev only owner can add a delegate (not delegates)
    /// @param _delegate The address of the delegate
    function addDelegate(address _delegate) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        if (_delegate == address(0) || delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delegates[_delegate] = true;

        emit DelegatedAccountAdded({caller: msg.sender, delegate: _delegate});
    }

    /// @notice Remove a delegate from the account
    /// @dev only owner can remove a delegate (not delegates)
    /// @param _delegate The address of the delegate
    function removeDelegate(address _delegate) public virtual {
        if (!isOwner(msg.sender)) revert Unauthorized();

        if (_delegate == address(0) || !delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delete delegates[_delegate];

        emit DelegatedAccountRemoved({caller: msg.sender, delegate: _delegate});
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Excarbon Smart Account v0.1.0 Implementation Interface
interface IAccount {
    /*///////////////////////////////////////////////////////////////
                                Types
    ///////////////////////////////////////////////////////////////*/

    /// @notice Command Flags used to decode commands to execute
    /// @dev under the hood ACCOUNT_WITHDRAW_ETH = 1, TRANSFER_NFT = 2
    enum Command {
        NONE, // 0
        ACCOUNT_WITHDRAW_ETH,
        TRANSFER_NFT
    }

    /// @param factory: address of the Smart Account Factory
    /// @param events: address of the Smart Account Events
    struct AccountConstructorParams {
        address factory;
        address events;
        address trustedForwarder;
    }

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when commands length does not equal inputs length
    error LengthMismatch();

    /// @notice thrown when Command given is not valid
    error InvalidCommandType(uint256 commandType);

    /// @notice thrown when conditional order type given is not valid due to zero sizeDelta
    error ZeroSizeDelta();

    /// @notice exceeds useable margin
    /// @param available: amount of useable margin asset
    /// @param required: amount of margin asset required
    error InsufficientFreeMargin(uint256 available, uint256 required);

    /// @notice call to transfer ETH on withdrawal fails
    error EthWithdrawalFailed();

    /// @notice thrown when a call attempts to reenter the protected function
    error Reentrancy();

    /// @notice thrown when a conditional order is attempted to be executed but SM account cannot pay fee
    /// @param executorFee: fee required to execute conditional order
    error CannotPayExecutorFee(uint256 executorFee, address executor);

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the version of the Account
    function VERSION() external view returns (bytes32);

    /*//////////////////////////////////////////////////////////////
                                MUTATIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the initial owner of the account
    /// @dev only called once by the factory on account creation
    /// @param _owner: address of the owner
    function setInitialOwnership(address _owner) external;

    /// @notice executes commands along with provided inputs
    /// @param _commands: array of commands, each represented as an enum
    /// @param _inputs: array of byte strings containing abi encoded inputs for each command
    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

/// @title Excarbon Factory Interface
interface IFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when new account is created
    /// @param creator: account creator (address that called newAccount())
    /// @param account: address of account that was created (will be address of proxy)
    /// @param version: version of account created
    event NewAccount(
        address indexed creator,
        address indexed account,
        bytes32 version
    );

    /// @notice emitted when implementation is upgraded
    /// @param implementation: address of new implementation
    event AccountImplementationUpgraded(address implementation);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when factory cannot set account owner to the msg.sender
    /// @param data: data returned from failed low-level call
    error FailedToSetAcountOwner(bytes data);

    /// @notice thrown when Account creation fails due to no version being set
    /// @param data: data returned from failed low-level call
    error AccountFailedToFetchVersion(bytes data);

    /// @notice thrown when factory is not upgradable
    error CannotUpgrade();

    /// @notice thrown when account is unrecognized by factory
    error AccountDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @return canUpgrade: bool to determine if system can be upgraded
    function canUpgrade() external view returns (bool);

    /// @return logic: account logic address
    function implementation() external view returns (address);

    /// @param _account: address of account
    /// @return whether or not account exists
    function accounts(address _account) external view returns (bool);

    /// @param _account: address of account
    /// @return owner of account
    function getAccountOwner(address _account) external view returns (address);

    /// @param _owner: address of owner
    /// @return array of accounts owned by _owner
    function getAccountsOwnedBy(
        address _owner
    ) external view returns (address[] memory);

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice update owner to account(s) mapping
    /// @dev does *NOT* check new owner != old owner
    /// @param _newOwner: new owner of account
    /// @param _oldOwner: old owner of account
    function updateAccountOwnership(
        address _newOwner,
        address _oldOwner
    ) external;

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice create unique account proxy for function caller
    /// @return accountAddress address of account created
    function newAccount() external returns (address payable accountAddress);

    /*//////////////////////////////////////////////////////////////
                             UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice upgrade implementation of account which all account proxies currently point to
    /// @dev this *will* impact all existing accounts
    /// @dev future accounts will also point to this new implementation (until
    /// upgradeAccountImplementation() is called again with a newer implementation)
    /// @dev *DANGER* this function does not check the new implementation for validity,
    /// thus, a bad upgrade could result in severe consequences.
    /// @param _implementation: address of new implementation
    function upgradeAccountImplementation(address _implementation) external;

    /// @notice remove upgradability from factory
    /// @dev cannot be undone
    function removeUpgradability() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {IAccount} from "./IAccount.sol";

/// @title Interface for contract that emits all events emitted by the Smart Accounts
interface IEvents {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a non-account contract attempts to call a restricted function
    error OnlyAccounts();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the address of the factory contract
    function factory() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted after a successful transfer NFT
    /// @param token: the address of NFT Collection
    /// @param receiver: the address that received NFT
    /// @param tokenId: the Id of NFT
    /// @param quantity: the amount of NFT has been transferred
    /// @param price: the buy / sell price
    function emitTransferNFT(
        address token,
        address receiver,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    ) external;

    event TransferNFT(
        address indexed token,
        address indexed account,
        address indexed receiver,
        uint256 tokenId,
        uint256 quantity,
        uint256 price
    );

    /// @notice emitted after a successful ETH withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of ETH to withdraw from account
    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(
        address indexed user,
        address indexed account,
        uint256 amount
    );
}