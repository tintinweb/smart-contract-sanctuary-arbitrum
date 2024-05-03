/**
 *Submitted for verification at Arbiscan.io on 2024-05-03
*/

// Sources flattened with hardhat v2.22.3 https://hardhat.org

// SPDX-License-Identifier: MIT AND UNLICENSED

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

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
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}


// File interfaces/wallet/ICadmosPayContract.sol

// Original license: SPDX_License_Identifier: UNLICENSED

pragma solidity 0.8.19;

//
//    ,ad8888ba,         db         88888888ba,    88b           d88    ,ad8888ba,     ad88888ba
//   d8"'    `"8b       d88b        88      `"8b   888b         d888   d8"'    `"8b   d8"     "8b
//  d8'                d8'`8b       88        `8b  88`8b       d8'88  d8'        `8b  Y8,
//  88                d8'  `8b      88         88  88 `8b     d8' 88  88          88  `Y8aaaaa,
//  88               d8YaaaaY8b     88         88  88  `8b   d8'  88  88          88    `"""""8b,
//  Y8,             d8""""""""8b    88         8P  88   `8b d8'   88  Y8,        ,8P          `8b
//   Y8a.    .a8P  d8'        `8b   88      .a8P   88    `888'    88   Y8a.    .a8P   Y8a     a8P
//    `"Y8888Y"'  d8'          `8b  88888888Y"'    88     `8'     88    `"Y8888Y"'     "Y88888P"
//
// ===============================================================================================
// ====================================  ICadmosPayContract  =======================================
// ===============================================================================================
// CADMOS: https://github.com/Cadmos-finance

// Primary Author(s)
// N.B.: https://github.com/nboueri



interface ICadmosPayContract{

    function contractNameHash() external view returns (bytes32);
    function getNewImplementationContract() external view returns (address);

}


// File contracts/wallet/CadmosPayContract.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.19;
abstract contract CadmosPayContract is ICadmosPayContract{

    bytes32 immutable public override(ICadmosPayContract) contractNameHash;

    address private newImplementationContract; // new Implementation Contract


    constructor(string memory contractName){
        contractNameHash = keccak256(bytes(contractName));
    }

    function getNewImplementationContract() external view override(ICadmosPayContract) returns (address){
        return newImplementationContract;
    }

    function _authorizeImplementationContractUpgrade(address newImplementationContract_) internal view virtual;

    function setNewImplementationContract(address newImplementationContract_) external{
        _authorizeImplementationContractUpgrade(newImplementationContract_);
        require(ICadmosPayContract(newImplementationContract_).contractNameHash()==contractNameHash,"Bad Contract");
        newImplementationContract = newImplementationContract_;
        emit NewImplementationContract(newImplementationContract_);
    }

    event NewImplementationContract(address indexed newImplementationContract_);

}


// File interfaces/wallet/IRecoveryAgent.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRecoveryAgent {

    function addRecoverySignatory(address wallet, address newRecoverySignatory) external;

}


// File interfaces/wallet/IUserWallet.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.19;

//
//    ,ad8888ba,         db         88888888ba,    88b           d88    ,ad8888ba,     ad88888ba
//   d8"'    `"8b       d88b        88      `"8b   888b         d888   d8"'    `"8b   d8"     "8b
//  d8'                d8'`8b       88        `8b  88`8b       d8'88  d8'        `8b  Y8,
//  88                d8'  `8b      88         88  88 `8b     d8' 88  88          88  `Y8aaaaa,
//  88               d8YaaaaY8b     88         88  88  `8b   d8'  88  88          88    `"""""8b,
//  Y8,             d8""""""""8b    88         8P  88   `8b d8'   88  Y8,        ,8P          `8b
//   Y8a.    .a8P  d8'        `8b   88      .a8P   88    `888'    88   Y8a.    .a8P   Y8a     a8P
//    `"Y8888Y"'  d8'          `8b  88888888Y"'    88     `8'     88    `"Y8888Y"'     "Y88888P"
//
// ===============================================================================================
// ========================================  IUserWallet  ========================================
// ===============================================================================================
// CADMOS: https://github.com/Cadmos-finance


/// @title Interface of CadmosPay userDeposit
interface IUserWallet{


    struct Request {
        address target;
        uint256 value;
        uint256 deadline;
        uint256 nonce;
        bytes data;
    }

    struct RecoverySignatory {
        address newSignatory;
        uint256 timestampAdded;
    }


    /* ========== VIEW FUNCTIONS ========== */

    function ProtocolRegistry() external view returns (address); // Returns Address of Protocol registry

    function REQUEST_TYPE() external view returns (string memory); //EIP712


    // Transaction Nonce for the contract
    function nonce() external view returns (uint256);

    // Number of Authorized Signatories
    function signatoryCount() external view returns (uint256);

    function isAuthorizedSignatory(address signatory) external view returns (bool);

    // recovery time-lock
    function recoveryTimeLock()  external view returns (uint256);

    // True iff Contract has a Recovery Agent
    function hasRecoveryAgent()  external view returns (bool);

    // True iff Contract has a Guardian Contarct
    function hasGuardianContract()  external view returns (bool);

    // address of recovery Agent
    function recoveryAgent() external view returns (address);

    // address of guardian Contract
    function guardianContract() external view returns (address);

    /// @dev helper function for EIP712
    function hashRequest(Request memory request) external view returns (bytes32);


    /* ========== CONSTRUCTOR and INITIALIZER========== */


    ///@notice Contract initializer
    ///@param signatory first signatory of the userWallet
    ///@param hasRecoveryAgent_ True iff User Wallet has Recovery Agent
    ///@param hasGuardianContract_ True iff User Wallet has Guardian Contract
    function initialize(address signatory,bool hasRecoveryAgent_,bool hasGuardianContract_, address cToken, address usdt, address cTokenDepositor) external;


    /* ========== VIEWS ========== */

    ///@notice Checks if a given messageHash  has been signed by one signatory
    ///@dev see https://eips.ethereum.org/EIPS/eip-1271
    function isValidSignature(bytes32 _hash, bytes calldata signature) external view returns(bytes4 magicValue);

    /* ========== RESTRICTED FUNCTIONS ========== */

    ///@notice changes the recovery time-lock
    function setRecoveryTimeLock(uint256 newRecoveryTimeLock, address signatory,bytes calldata signature, uint256 deadline) external;

    ///@notice sets if Contract has a Recovery Agent
    function setHasRecoveryAgent(bool hasRecoveryAgent, address signatory,bytes calldata signature, uint256 deadline) external;

    ///@notice Sets if contract has a guardian contract
    function setHasGuardianContract(bool hasGuardianContract, address signatory,bytes calldata signature, uint256 deadline) external;

    ///@notice adds a new Pending Recovery Signatory
    function addRecoverySignatory(address newRecoverySignatory) external;

    ///@notice Adds the Pending Recovery Signatory to the Signatory List
    function applyRecoverySignatory() external;

    ///@notice adds a new Signatory
    function addSignatory(address newSignatory, address signatory,bytes calldata signature, uint256 deadline) external;

    ///@notice removes a Signatory - /!\ cannot self remove (enforces that there is at least one valid signatory)
    function removeSignatory(address signatoryToRemove, address signatory,bytes calldata signature, uint256 deadline) external;

    ///@notice Performs a solidity function call
    function call(address target, address signatory, bytes calldata data, bytes calldata signature, uint256 deadline) external returns (bytes memory);

    ///@notice Performs a solidity function call and transfers 'value' wei to 'target'
    function callWithValue(address target,address signatory,  bytes calldata data, bytes calldata signature, uint256 value, uint256 deadline) external returns (bytes memory);

    ///@notice Transfers ETH to an arbitrary address
    function transferETH(address target, address signatory, bytes calldata signature, uint256 value, uint256 deadline) external;

    /* ========== EVENTS ========== */
    event NewRecoveryTimeLock(uint256 indexed newRecoveryTimeLock);
    event SetHasRecoveryAgent(bool indexed hasRecoveryAgent);
    event SetHasGuardianContract(bool indexed hasGuardianContract);
    event AddedRecoverySignatory(address indexed  newRecoverySignatory);
    event addedSignatory(address indexed newSignatory);
    event removedSignatory(address indexed signatoryToRemove);

}


// File contracts/wallet/RecoveryAgent.sol

// Original license: SPDX_License_Identifier: UNLICENSED
pragma solidity 0.8.19;
contract RecoveryAgent is Ownable2Step, CadmosPayContract, IRecoveryAgent{



    /* ========== CONSTRUCTOR ========== */

    constructor() CadmosPayContract("RECOVERY_AGENT"){
    }


    /* ========== INTERNAL FUNCTIONS ========== */

    function _authorizeImplementationContractUpgrade(address newImplementationContract_) internal view override(CadmosPayContract){
        require(msg.sender == owner());
    }


     /* ========== RESTRICTED FUNCTIONS ========== */
    function addRecoverySignatory(address wallet, address newRecoverySignatory) external override(IRecoveryAgent) onlyOwner  {
        IUserWallet(wallet).addRecoverySignatory(newRecoverySignatory);
    }


}