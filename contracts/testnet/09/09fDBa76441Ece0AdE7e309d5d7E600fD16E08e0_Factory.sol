// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IAccountProxy} from "./interfaces/IAccountProxy.sol";

/// @title Kwenta Account Proxy
/// @author OpenZeppelin, JaredBorders ([email protected])
/// @dev This contract implements a proxy that gets the
/// implementation address for each call from the {Beacon}
/// (which in this system is the contract: {Factory.sol}).
/// The beacon address is stored in the storage slot
/// `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
/// conflict with the storage layout of the implementation behind this proxy.
contract AccountProxy is IAccountProxy {
    /*//////////////////////////////////////////////////////////////
                           STORAGE MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    bytes32 internal constant _BEACON_STORAGE_SLOT =
        bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1);

    /// @dev struct to store beacon address
    struct AddressSlot {
        address value;
    }

    /// @dev returns the storage slot where the beacon address is stored
    function _getAddressSlot(bytes32 slot)
        internal
        pure
        returns (AddressSlot storage r)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r.slot := slot
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice constructor for proxy
    /// @param _beaconAddress: address of beacon (i.e. factory address)
    /// @dev {Factory.sol} will store the implementation address,
    /// thus acting as the beacon
    constructor(address _beaconAddress) {
        _getAddressSlot(_BEACON_STORAGE_SLOT).value = _beaconAddress;
    }

    /*//////////////////////////////////////////////////////////////
                              BEACON LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @return beacon address (i.e. the factory address)
    function _beacon() internal view returns (address beacon) {
        beacon = _getAddressSlot(_BEACON_STORAGE_SLOT).value;
        if (beacon == address(0)) revert BeaconNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                          IMPLEMENTATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @return implementation address (i.e. the account logic address)
    function _implementation() internal returns (address implementation) {
        (bool success, bytes memory data) =
            _beacon().call(abi.encodeWithSignature("implementation()"));
        if (!success) revert BeaconCallFailed();
        implementation = abi.decode(data, (address));
        if (implementation == address(0)) revert ImplementationNotSet();
    }

    /*//////////////////////////////////////////////////////////////
                            FORWARDING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`.
    /// Will run if no other function in the contract matches the call data.
    fallback() external payable {
        _fallback();
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`.
    /// Will run if call data is empty.
    receive() external payable {
        _fallback();
    }

    /// @notice Delegates the current call to the address returned by `_implementation()`.
    /// @dev This function does not return to its internal call site,
    /// it will return directly to the external caller.
    function _fallback() internal {
        _delegate(_implementation());
    }

    /// @notice delegates the current call to `implementation`.
    /// @dev This function does not return to its internal call site,
    /// it will return directly to the external caller.
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result :=
                delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())
            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {AccountProxy} from "./AccountProxy.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {Owned} from "./utils/Owned.sol";      

/// @title Kwenta Account Factory
/// @author JaredBorders ([email protected])
/// @notice factory for creating smart margin accounts
/// @dev the factory acts as a beacon for the proxy {AccountProxy.sol} contract(s)
contract Factory is IFactory, Owned {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    bool public canUpgrade = true;

    /// @inheritdoc IFactory
    address public implementation;

    /// @inheritdoc IFactory
    mapping(address accounts => bool exist) public accounts;

    /// @notice mapping of owner to accounts owned by owner
    mapping(address owner => address[] accounts) internal ownerAccounts;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice constructor for factory that sets owner
    /// @param _owner: owner of factory
    constructor(address _owner) Owned(_owner) {}

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function getAccountOwner(address _account)
        public
        view
        override
        returns (address)
    {
        // ensure account is registered
        if (!accounts[_account]) revert AccountDoesNotExist();

        // fetch owner from account
        (bool success, bytes memory data) =
            _account.staticcall(abi.encodeWithSignature("owner()"));
        assert(success); // should never fail (account is a contract)

        return abi.decode(data, (address));
    }

    /// @inheritdoc IFactory
    function getAccountsOwnedBy(address _owner)
        external
        view
        override
        returns (address[] memory)
    {
        return ownerAccounts[_owner];
    }

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function updateAccountOwnership(address _newOwner, address _oldOwner)
        external
        override
    {
        // ensure account is registered by factory
        if (!accounts[msg.sender]) revert AccountDoesNotExist();

        // store length of ownerAccounts array in memory
        uint256 length = ownerAccounts[_oldOwner].length;

        for (uint256 i = 0; i < length;) {
            if (ownerAccounts[_oldOwner][i] == msg.sender) {
                // remove account from ownerAccounts mapping for old owner
                ownerAccounts[_oldOwner][i] =
                    ownerAccounts[_oldOwner][length - 1];
                ownerAccounts[_oldOwner].pop();

                // add account to ownerAccounts mapping for new owner
                ownerAccounts[_newOwner].push(msg.sender);

                return;
            }

            unchecked {
                ++i;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function newAccount()
        external
        override
        returns (address payable accountAddress)
    {
        // create account and set beacon to this address (i.e. factory address)
        accountAddress = payable(address(new AccountProxy(address(this))));

        // add account to accounts mapping
        accounts[accountAddress] = true;

        // add account to ownerAccounts mapping
        ownerAccounts[msg.sender].push(accountAddress);

        // set owner of account to caller
        (bool success, bytes memory data) = accountAddress.call(
            abi.encodeWithSignature("setInitialOwnership(address)", msg.sender)
        );
        if (!success) revert FailedToSetAcountOwner(data);

        // determine version for the following event
        (success, data) =
            accountAddress.call(abi.encodeWithSignature("VERSION()"));
        if (!success) revert AccountFailedToFetchVersion(data);

        emit NewAccount({
            creator: msg.sender,
            account: accountAddress,
            version: abi.decode(data, (bytes32))
        });
    }

    /*//////////////////////////////////////////////////////////////
                             UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IFactory
    function upgradeAccountImplementation(address _implementation)
        external
        override
        onlyOwner
    {
        if (!canUpgrade) revert CannotUpgrade();
        implementation = _implementation;
        emit AccountImplementationUpgraded({implementation: _implementation});
    }

    /// @inheritdoc IFactory
    function removeUpgradability() external override onlyOwner {
        canUpgrade = false;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/// @title Kwenta Account Proxy Interface
/// @author JaredBorders ([email protected])
interface IAccountProxy {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev thrown if beacon is not set to a valid address
    error BeaconNotSet();

    /// @dev thrown if implementation is not set to a valid address
    error ImplementationNotSet();

    /// @dev thrown if beacon call fails
    error BeaconCallFailed();
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/// @title Kwenta Factory Interface
/// @author JaredBorders ([email protected])
interface IFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when new account is created
    /// @param creator: account creator (address that called newAccount())
    /// @param account: address of account that was created (will be address of proxy)
    /// @param version: version of account created
    event NewAccount(
        address indexed creator, address indexed account, bytes32 version
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
    function getAccountOwner(address _account)
        external
        view
        returns (address);

    /// @param _owner: address of owner
    /// @return array of accounts owned by _owner
    function getAccountsOwnedBy(address _owner)
        external
        view
        returns (address[] memory);

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice update owner to account(s) mapping
    /// @dev does *NOT* check new owner != old owner
    /// @param _newOwner: new owner of account
    /// @param _oldOwner: old owner of account
    function updateAccountOwnership(address _newOwner, address _oldOwner)
        external;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// https://docs.synthetix.io/contracts/source/contracts/owned
contract Owned {
    address public owner;
    address public nominatedOwner;

    constructor(address _owner) {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}