// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: GLP-v3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";


contract AddressesProvider is Ownable{
    mapping(address => address) public hopBridge; //token => L2_AmmWrapper

    event HOPBRIDGE_SET(address indexed _token, address _bridge);

    //_bridgeMapping: [token1,bridge1,token2,bridge2,...]
    // arbitrum e.g.
    // hopBridge[0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 0xe22D2beDb3Eca35E6397e0C6D62857094aA26F52; //USDC
    // hopBridge[0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 0xCB0a4177E0A60247C0ad18Be87f8eDfF6DD30283; //USDT
    // hopBridge[0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1] = 0xe7F40BF16AB09f4a6906Ac2CAA4094aD2dA48Cc2; //DAI
    // hopBridge[0x82aF49447D8a07e3bd95BD0d56f35241523fBab1] = 0x33ceb27b39d2Bb7D2e61F7564d3Df29344020417; //WETH
    // hopBridge[0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f] = 0xC08055b634D43F2176d721E26A3428D3b7E7DdB5; //WBTC
    constructor(address[] memory _bridgeMapping){
        uint _counter = _bridgeMapping.length / 2;
        for(uint i = 0; i < _counter; i++){
            hopBridge[_bridgeMapping[i * 2]] = _bridgeMapping[i * 2 + 1];
        }
    }

    function setHopBridge(address _token, address _bridge) external onlyOwner{
        hopBridge[_token] = _bridge;
        emit HOPBRIDGE_SET(_token, _bridge);
    }
}