/**
 *Submitted for verification at Arbiscan.io on 2024-06-21
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;




interface ICategoryFees {
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external;
    
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external view returns (uint256);
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external view returns (uint256 feePercent, uint256 feeAmount);
}




abstract contract BaseReentrancyGuard {
    uint256 internal constant _REENTRANCY_NOT_ENTERED = 1;
    uint256 internal constant _REENTRANCY_ENTERED = 2;

    uint256 internal _reentrancyStatus;

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_reentrancyStatus != _REENTRANCY_ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _reentrancyStatus = _REENTRANCY_ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _reentrancyStatus = _REENTRANCY_NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _reentrancyStatus == _REENTRANCY_ENTERED;
    }
}




abstract contract BaseOwnable {
    address internal _owner;

    /**
     * @notice Triggers when contract ownership changes.
     * @param previousOwner The previous owner of the contract.
     * @param newOwner The new owner of the contract.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


/**
 * @title This contract is responsible for managing context-based fees in a generic manner.
 */
contract CategoryFees is ICategoryFees, BaseReentrancyGuard, BaseOwnable {
    /// @notice The divisor for fees. Represents a percentage with 6 decimals places (2 + 6 decimals = 1e8)
    uint256 public constant FEES_DIVISOR = 1e8;

    // This is the mapping for fees, expressed as: Category > Specific Address > Fee
    mapping (bytes32 => mapping (address => uint256)) internal _categoryFees;

    /**
     * @notice Constructor.
     * @param ownerAddr The address of the owner
     */
    constructor (address ownerAddr) {
        _owner = ownerAddr;
    }

    /**
     * @notice Transfers ownership of the contract to a new account.
     */
    function transferOwnership(address newOwner) external nonReentrant onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @notice Sets the applicable to a given category. Optionally, you can specify a specific address for selective fees.
     * @param feePercent The fee, expressed as a percentage with 6 decimals places. It can be zero.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string. Required.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     */
    function setContextFeeRate(uint256 feePercent, bytes32 categoryId, address specificAddr) external override nonReentrant onlyOwner {
        require(categoryId != bytes32(0), "Category required");
        require(feePercent <= 99_000000, "Fee too high");

        _categoryFees[categoryId][specificAddr] = feePercent;
    }

    /**
     * @notice Gets the fee applicable to the context specified.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     * @return Returns the rate for the category and address specified.
     */
    function getContextFeeRate(bytes32 categoryId, address specificAddr) external override view returns (uint256) {
        return _categoryFees[categoryId][specificAddr];
    }

    /**
     * @notice Gets the applicable fee amount for the context specified.
     * @param amount The payment amount.
     * @param categoryId The ID of the category. It could be a hash, or a number, or a limited string.
     * @param specificAddr The specific address within the category specified, if any. It can be the zero-address, meaning the fee applies to the whole category.
     * @return feePercent Returns the rate for the category and address specified.
     * @return feeAmount Returns the respective fee amount, for the category and address specified.
     */
    function getContextFeeAmount(uint256 amount, bytes32 categoryId, address specificAddr) external override view returns (uint256 feePercent, uint256 feeAmount) {
        feePercent = _categoryFees[categoryId][specificAddr];
        if ((specificAddr != address(0)) && (feePercent == 0)) feePercent = _categoryFees[categoryId][address(0)];
        
        feeAmount = (feePercent == 0) ? 0 : (feePercent * amount) / FEES_DIVISOR;
    }

    function owner() external view returns (address) {
        return _owner;
    }
}