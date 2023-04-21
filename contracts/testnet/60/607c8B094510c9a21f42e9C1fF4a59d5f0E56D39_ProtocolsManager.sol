// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: agpl-3.0


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS    = address(0);

}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.15;


interface IProtocolsManager {

    function  query(string memory protocolName) external view returns (address contractAddress, bool allowTrading);
    function  isCurrencySupported(string memory protocolName, address token) external view returns(bool);
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IProtocolsManager.sol";
import "./Constant.sol";


contract ProtocolsManager is IProtocolsManager, Ownable {

    struct Protocol {
        address contractAddress;
        bool allowed;

        mapping(uint=>Currency) currencyMap; // index is 1-based. 0 is invalid currency.
        mapping(address=>uint) currencyIndexMap;
        uint currencyCount;
    }

    struct Currency {
        address tokenAddress;
        bool enabled;
    }

    mapping (string => Protocol) public protocolsMap;

    event AddProtocol(string protocolName, address contractAddress, bool allowed);
    event PauseTrading(string protocolName, bool pause);
    event AddCurrency(string protocolName, address currency);
    event EnableCurrency(string protocolName, address currency, bool enable);
   

    function add(string memory protocolName, address contractAddress, bool allowTrading) external onlyOwner {
        require(bytes(protocolName).length > 0 && contractAddress != Constant.ZERO_ADDRESS, "Invalid params");
        Protocol storage p = protocolsMap[protocolName];
        require(p.contractAddress == Constant.ZERO_ADDRESS, "Already added");
        p.contractAddress = contractAddress;
        p.allowed = allowTrading;
        emit AddProtocol(protocolName, contractAddress, allowTrading);
    }

    function pause(string memory protocolName, bool setPause) external onlyOwner {
        Protocol storage p =  _get(protocolName, true);
        require(p.allowed == setPause, "Invalid state");
        p.allowed = !setPause;
        emit PauseTrading(protocolName, setPause);
    }

    function addCurrency(string memory protocolName, address[] memory tokens) external onlyOwner{
        Protocol storage p =  _get(protocolName, true);
        address token;
        uint len = tokens.length;
        for (uint n=0; n<len; n++) {
            token = tokens[n];
            require(token != Constant.ZERO_ADDRESS, "Invalid token");
            require(p.currencyIndexMap[token] == 0, "Currency existed"); // Make sure not exist
            p.currencyMap[++p.currencyCount] = Currency(token, true);
            p.currencyIndexMap[token] = p.currencyCount;
            emit AddCurrency(protocolName, token);
        }     
    }

    function enableCurrency(string memory protocolName, address token, bool enable)external {
        Currency storage c = _getCurrency(protocolName, token);
        require(c.tokenAddress != Constant.ZERO_ADDRESS, "Invalid currency");
        require(c.enabled != enable, "Invalid state");
        c.enabled = enable;
        emit EnableCurrency(protocolName, token, enable);
    }

    function query(string memory protocolName) external  override view returns (address contractAddress, bool allowTrading) {
        Protocol storage p =  _get(protocolName, false);
        contractAddress = p.contractAddress;
        allowTrading = p.allowed;
    }

    function isCurrencySupported(string memory protocolName, address token) external override view returns (bool) {
        Currency storage c = _getCurrency(protocolName, token);
        return c.enabled;
    }

    function _get(string memory protocolName, bool ensureValid) private view returns (Protocol storage p) {
        p = protocolsMap[protocolName];
        if (ensureValid) {
            require(p.contractAddress != Constant.ZERO_ADDRESS, "Invalid address");
        }
    }

    function _getCurrency(string memory protocolName, address token) private view returns (Currency storage) {
        Protocol storage p = protocolsMap[protocolName];
        uint index = p.currencyIndexMap[token];
        return p.currencyMap[index];
    }
}