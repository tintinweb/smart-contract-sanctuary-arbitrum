/**
 *Submitted for verification at Arbiscan.io on 2024-05-08
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.12;




/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
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
 * @title Implements a basic price oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
contract PriceOracle is IBasicPriceOracle, BaseReentrancyGuard, BaseOwnable {
    // The price of each token, expressed in USD
    mapping (address => uint256) internal _tokenPrice;

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
     * @notice Updates the price of the token specified.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokenAddr The address of the token
     * @param newTokenPrice The new price of the token, expressed in USD with 6 decimal positions
     */
    function updateTokenPrice (address tokenAddr, uint256 newTokenPrice) external override nonReentrant onlyOwner {
        require(tokenAddr != address(0), "Token address required");
        require(newTokenPrice > 0, "Token price required");
        
        _tokenPrice[tokenAddr] = newTokenPrice;
    }

    /**
     * @notice Updates the price of multiple tokens.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokens The address of each token
     * @param prices The new price of each token, expressed in USD with 6 decimal positions
     */
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external override nonReentrant onlyOwner {
        require(tokens.length > 0 && tokens.length <= 30, "Too many tokens");
        require(tokens.length == prices.length, "Invalid array length");

        for (uint256 i = 0; i < tokens.length; i++) {
            address tokenAddr = tokens[i];
            uint256 newTokenPrice = prices[i];
            require(tokenAddr != address(0), "Token address required");
            require(newTokenPrice > 0, "Token price required");        
            _tokenPrice[tokenAddr] = newTokenPrice;
        }
    }

    /**
     * @notice Gets the price of the token specified.
     * @param tokenAddr The address of the token
     * @return Returns the token price
     */
    function getTokenPrice (address tokenAddr) external view override returns (uint256) {
        return _tokenPrice[tokenAddr];
    }

    function owner() external view returns (address) {
        return _owner;
    }
}