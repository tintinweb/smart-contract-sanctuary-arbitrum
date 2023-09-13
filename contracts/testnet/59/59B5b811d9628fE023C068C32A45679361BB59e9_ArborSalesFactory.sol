/**
 *Submitted for verification at Arbiscan.io on 2023-09-12
*/

// Sources flattened with hardhat v2.17.0 https://hardhat.org

// File contracts/Errors.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

error ArrayLengthMismatch();
error InvalidAddress();
error InvalidValueProvided();
error InvalidSignerOne();
error InvalidSignerTwo();
error InvalidSignature();
error MessageAlreadyUsed();
error SignatureExpired();
error UnauthorizedCaller();


// File contracts/ArborSalesFactory.sol

pragma solidity 0.8.20;

contract ArborSalesFactory {
    // Factory admin
    address private _admin;
    // Contains sales deployed by this factory
    mapping(address => bool) private _deployedThroughFactory;
    // Array of all sale deployments
    address[] private _deployments;
    // ArborSale contract implementation
    address private _implementation;

    // Events
    event Deployed(address clone);
    event ImplementationSet(address implementation);
    event AdminSet(address admin);

    // Errors
    error ImplementationNotSet();
    error ImplementationAlreadySet();
    error CloneCreationFailed();
    error InvalidIndexes();

    modifier onlyAdmin() {
        if (msg.sender != _admin) revert UnauthorizedCaller();
        _;
    }

    constructor(address admin_) {
        _setAdmin(admin_);
    }

    /**
     * @dev Function to set admin
     */
    function setAdmin(address admin_) external onlyAdmin {
        _setAdmin(admin_);
    }

    /**
     * @dev Function containing logic for new admin setting
     */
    function _setAdmin(address admin_) private {
        // Check admin address
        if (admin_ == address(0) || admin_ == _admin) {
            revert InvalidAddress();
        }
        // Set admin
        _admin = admin_;
        // Emit event
        emit AdminSet(admin_);
    }

    /**
     * @dev Function to set new ArborSale implementation
     * @param implementation_ is ArborSale contract implementation
     */
    function setImplementation(address implementation_) external onlyAdmin {
        // Require that implementation is different from current one
        if (_implementation == implementation_) {
            revert ImplementationAlreadySet();
        }
        // Set new implementation
        _implementation = implementation_;
        // Emit relevant event
        emit ImplementationSet(implementation_);
    }

    /**
     * @dev Function to make a new deployment and initialize clone instance
     */
    function deploy(bytes calldata data) external payable onlyAdmin {
        // Require that implementation is set
        if (_implementation == address(0)) {
            revert ImplementationNotSet();
        }

        // Newly deployed clone address will be stored inside of this variable
        address clone;
        // Localize implementation address in order to use it inside the assembly block
        address imp = _implementation;

        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, imp)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, imp), 0x5af43d82803e903d91602b57fd5bf3))
            clone := create(0, 0x09, 0x37)
        }
        // Require that clone is created
        if (clone == address(0)) {
            revert CloneCreationFailed();
        }

        // Mark sale as created through official factory
        _deployedThroughFactory[clone] = true;
        // Add sale to allSales
        _deployments.push(clone);

        // Initialize
        if (data.length > 0) {
            (bool success, ) = clone.call{value: msg.value}(data);
            if (!success) revert();
        }

        // Emit relevant event
        emit Deployed(clone);
    }

    /**
     * @dev Function to retrieve the admin address
     */
    function admin() external view returns (address) {
        return _admin;
    }

    /**
     * @dev Function to provide information if contract on the given address has been deployed through this factory
     * @param addr Contract address to be checked
     */
    function isDeployedThroughFactory(address addr) external view returns (bool) {
        return _deployedThroughFactory[addr];
    }

    /**
     * @dev Function to retrieve total number of deployments made by this factory
     */
    function noOfDeployments() public view returns (uint256) {
        return _deployments.length;
    }

    /**
     * @dev Function to retrieve the address of the latest deployment made by this factory
     * @return Latest deployment address
     */
    function getLatestDeployment() external view returns (address) {
        uint256 _noOfDeployments = noOfDeployments();
        if (_noOfDeployments > 0) return _deployments[_noOfDeployments - 1];
        // Return zero address if no deployments were made
        return address(0);
    }

    /**
     * @dev Function to retrieve all deployments between indexes
     * @param startIndex First index
     * @param endIndex Last index
     * @return deployments_ All deployments between provided indexes
     */
    function getAllDeployments(
        uint256 startIndex,
        uint256 endIndex
    ) external view returns (address[] memory deployments_) {
        // Require valid index input
        if (endIndex < startIndex || endIndex >= _deployments.length) {
            revert InvalidIndexes();
        }
        // Initialize new array
        deployments_ = new address[](endIndex - startIndex + 1);
        uint index = 0;
        // Fill the array with sale addresses
        for (uint i = startIndex; i <= endIndex; i++) {
            deployments_[index] = _deployments[i];
            index++;
        }
    }

    /**
     * @dev Function to retrieve the implementation address
     */
    function implementation() external view returns (address) {
        return _implementation;
    }
}