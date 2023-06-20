/**
 *Submitted for verification at Arbiscan on 2023-06-20
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
abstract contract CustomOwnable {
    // The current owner of this resource.
    address internal _owner;

    /**
     * @notice This event is triggered when the current owner transfers ownership of the contract.
     * @param previousOwner The previous owner
     * @param newOwner The new owner
     */
    event OnOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only owner");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership(address addr) external virtual onlyOwner {
        _transferOwnership(addr);
    }

    /**
     * @notice Gets the owner of this contract.
     * @return Returns the address of the owner.
     */
    function owner() external virtual view returns (address) {
        return _owner;
    }

    function _transferOwnership(address addr) internal virtual {
        require(addr != address(0) && addr != _owner, "Invalid owner address");

        address oldValue = _owner;
        _owner = addr;
        emit OnOwnershipTransferred(oldValue, _owner);
    }
}

/**
 * @title Defines the interface of a basic pricing oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
interface IBasicPriceOracle {
    function updateTokenPrice (address tokenAddr, uint256 valueInUSD) external;
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external;
    function getTokenPrice (address tokenAddr) external view returns (uint256);
}

/**
 * @title Implements a basic price oracle.
 * @dev All prices are expressed in USD, with 6 decimal positions.
 */
contract PriceOracle is IBasicPriceOracle, CustomOwnable {
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
     * @notice Updates the price of the token specified.
     * @dev Throws if the sender is not the owner of this contract.
     * @param tokenAddr The address of the token
     * @param newTokenPrice The new price of the token, expressed in USD with 6 decimal positions
     */
    function updateTokenPrice (address tokenAddr, uint256 newTokenPrice) external override onlyOwner {
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
    function bulkUpdate (address[] memory tokens, uint256[] memory prices) external override onlyOwner {
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
}