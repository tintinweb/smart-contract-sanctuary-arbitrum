// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "../utils/Errors.sol";
import {Ownable} from "../utils/Ownable.sol";
import {IRegistry} from "../interface/core/IRegistry.sol";

/**
    @title Registry Contract
    @notice This contract stores:
        1. Address of all accounts as well their owners
        2. Active LToken addresses and Token->LToken mapping
        3. Address of all deployed protocol contracts
*/
contract Registry is Ownable, IRegistry {

    /* -------------------------------------------------------------------------- */
    /*                              STATE VARIABLES                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Utility variable to indicate if contract is initialized
    bool private initialized;

    /// @notice List of contracts
    /// @dev Contract Name should be separated by _ and in all caps Ex. (REGISTRY, RATE_MODEL)
    string[] public keys;

    /// @notice List of accounts
    address[] public accounts;

    /// @notice List of active lTokens
    address[] public lTokens;

    /// @notice Account address to owner mapping (account => owner)
    mapping(address => address) public ownerFor;

    /// @notice Token to LToken mapping (token => LToken)
    mapping(address => address) public LTokenFor;

    /// @notice Contract name to contract address mapping (contractName => contract)
    mapping(string => address) public addressFor;

    /* -------------------------------------------------------------------------- */
    /*                              CUSTOM MODIFIERS                              */
    /* -------------------------------------------------------------------------- */

    modifier accountManagerOnly() {
        if (msg.sender != addressFor['ACCOUNT_MANAGER'])
            revert Errors.AccountManagerOnly();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                             EXTERNAL FUNCTIONS                             */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Contract Initialization function
        @dev Can only be invoked once
    */
    function init() external {
        if (initialized) revert Errors.ContractAlreadyInitialized();
        initialized = true;
        initOwnable(msg.sender);
    }

    /**
        @notice Sets contract address for a given contract id
        @dev If address is 0x0 it removes the address from keys.
        If addressFor[id] returns 0x0 then the contract id is added to keys
        @param id Contract name, format (REGISTRY, RATE_MODEL)
        @param _address Address of the contract
    */
    function setAddress(string calldata id, address _address)
        external
        adminOnly
    {
        if (addressFor[id] == address(0)) {
            if (_address == address(0)) revert Errors.ZeroAddress();
            keys.push(id);
        }
        else if (_address == address(0)) removeKey(id);

        addressFor[id] = _address;
    }

    /**
        @notice Sets LToken address for a specified token
        @dev If underlying token is 0x0 LToken is removed from lTokens
        if the mapping doesn't exist LToken is pushed to lTokens
        if the mapping exist LToken is updated in lTokens
        @param underlying Address of token
        @param lToken Address of LToken
    */
    function setLToken(address underlying, address lToken) external adminOnly {
        if (LTokenFor[underlying] == address(0)) {
            if (lToken == address(0)) revert Errors.ZeroAddress();
            lTokens.push(lToken);
        }
        else if (lToken == address(0)) removeLToken(LTokenFor[underlying]);
        else updateLToken(LTokenFor[underlying], lToken);

        LTokenFor[underlying] = lToken;
    }

    /**
        @notice Adds account and sets owner of the account
        @dev Adds account to accounts and stores owner for the account.
        Event AccountCreated(account, owner) is emitted
        @param account Address of account
        @param owner Address of owner of the account
    */
    function addAccount(address account, address owner)
        external
        accountManagerOnly
    {
        ownerFor[account] = owner;
        accounts.push(account);
        emit AccountCreated(account, owner);
    }

    /**
        @notice Updates owner of account
        @param account Address of account
        @param owner Address of owner of account
    */
    function updateAccount(address account, address owner)
        external
        accountManagerOnly
    {
        ownerFor[account] = owner;
    }

    /**
        @notice Closes account
        @dev Sets address of owner for the account to 0x0
        @param account Address of account to close
    */
    function closeAccount(address account) external accountManagerOnly {
        ownerFor[account] = address(0);
    }

    /* -------------------------------------------------------------------------- */
    /*                               VIEW FUNCTIONS                               */
    /* -------------------------------------------------------------------------- */

    /**
        @notice Returns all contract names in registry
        @return keys List of contract names
    */
    function getAllKeys() external view returns(string[] memory) {
        return keys;
    }

    /**
        @notice Returns all accounts in registry
        @return accounts List of accounts
    */
    function getAllAccounts() external view returns (address[] memory) {
        return accounts;
    }

    /**
        @notice Returns all active LTokens in registry
        @return lTokens List of lTokens
    */
    function getAllLTokens() external view returns(address[] memory) {
        return lTokens;
    }

    /**
        @notice Returns all accounts owned by a specific user
        @param user Address of user
        @return userAccounts List of accounts
    */
    function accountsOwnedBy(address user)
        external
        view
        returns (address[] memory userAccounts)
    {
        userAccounts = new address[](accounts.length);
        uint index;
        for (uint i; i < accounts.length; i++) {
            if (ownerFor[accounts[i]] == user) {
                userAccounts[index] = accounts[i];
                index++;
            }
        }
        assembly { mstore(userAccounts, index) }
    }

    /**
        @notice Returns address of a specified contract deployed by the protocol
        @dev Reverts if there is no contract deployed
        @param id Name of the contract, Eg: ACCOUNT_MANAGER
        @return value Address of deployed contract
    */
    function getAddress(string calldata id)
        external
        view
        returns (address value)
    {
        if ((value = addressFor[id]) == address(0))
            revert Errors.ZeroAddress();
    }

    /* -------------------------------------------------------------------------- */
    /*                              HELPER FUNCTIONS                              */
    /* -------------------------------------------------------------------------- */

    function updateLToken(address lToken, address newLToken) internal {
        uint len = lTokens.length;
        for(uint i; i < len; ++i) {
            if(lTokens[i] == lToken) {
                lTokens[i] = newLToken;
                break;
            }
        }
    }

    function removeLToken(address underlying) internal {
        uint len = lTokens.length;
        for(uint i; i < len; ++i) {
            if (underlying == lTokens[i]) {
                lTokens[i] = lTokens[len - 1];
                lTokens.pop();
                break;
            }
        }
    }

    function removeKey(string calldata id) internal {
        uint len = keys.length;
        bytes32 keyHash = keccak256(abi.encodePacked(id));
        for(uint i; i < len; ++i) {
            if (keyHash == keccak256(abi.encodePacked((keys[i])))) {
                keys[i] = keys[len - 1];
                keys.pop();
                break;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRegistry {
    event AccountCreated(address indexed account, address indexed owner);

    function init() external;

    function addressFor(string calldata id) external view returns (address);
    function ownerFor(address account) external view returns (address);

    function getAllLTokens() external view returns (address[] memory);
    function LTokenFor(address underlying) external view returns (address);

    function setAddress(string calldata id, address _address) external;
    function setLToken(address underlying, address lToken) external;

    function addAccount(address account, address owner) external;
    function updateAccount(address account, address owner) external;
    function closeAccount(address account) external;

    function getAllAccounts() external view returns(address[] memory);
    function accountsOwnedBy(address user)
        external view returns (address[] memory);
    function getAddress(string calldata) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Errors {
    error AdminOnly();
    error MaxSupply();
    error ZeroShares();
    error ZeroAssets();
    error ZeroAddress();
    error MinimumShares();
    error ContractPaused();
    error OutstandingDebt();
    error AccountOwnerOnly();
    error TokenNotContract();
    error AddressNotContract();
    error ContractNotPaused();
    error LTokenUnavailable();
    error LiquidationFailed();
    error EthTransferFailure();
    error AccountManagerOnly();
    error RiskThresholdBreached();
    error FunctionCallRestricted();
    error AccountNotLiquidatable();
    error CollateralTypeRestricted();
    error IncorrectConstructorArgs();
    error ContractAlreadyInitialized();
    error AccountDeactivationFailure();
    error AccountInteractionFailure(address, address, uint, bytes);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Errors} from "./Errors.sol";

abstract contract Ownable {

    address public admin;

    event OwnershipTransferred(
        address indexed previousAdmin,
        address indexed newAdmin
    );

    function initOwnable(address _admin) internal {
        if (_admin == address(0)) revert Errors.ZeroAddress();
        admin = _admin;
    }

    modifier adminOnly() {
        if (admin != msg.sender) revert Errors.AdminOnly();
        _;
    }

    function transferOwnership(address newAdmin) external virtual adminOnly {
        if (newAdmin == address(0)) revert Errors.ZeroAddress();
        emit OwnershipTransferred(admin, newAdmin);
        admin = newAdmin;
    }
}