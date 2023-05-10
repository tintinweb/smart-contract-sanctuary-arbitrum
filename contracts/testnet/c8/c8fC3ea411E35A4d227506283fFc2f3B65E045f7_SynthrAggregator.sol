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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IExchanger {
    function updateDestinationForExchange(
        address recipient,
        bytes32 destinationKey,
        uint destinationAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISynthrIssuer {
    function synthsByAddress(address synthAddress) external view returns (bytes32);

    function destIssue(
        address account,
        bytes32 synthKey,
        uint synthAmount
    ) external;

    function destBurn(
        address account,
        bytes32 synthKey,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWrappedSynthr {
    function getAvailableCollaterals() external view returns (bytes32[] memory);

    function withdrawCollateral(
        address from,
        address to,
        bytes32 collateralKey,
        uint collateralAmount
    ) external;

    function collateralTransfer(
        address _from,
        bytes32 _collateralKey,
        uint _collateralAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISynthrIssuer.sol";
import "./interfaces/IExchanger.sol";
import "./interfaces/IWrappedSynthr.sol";

contract SynthrAggregator is Ownable {
    address public _exchangeFeeAddress;
    address public synthrBridge;

    uint16 private _selfLZChainId;

    // collateral currency key => chainId => user address => amount
    mapping(bytes32 => mapping(uint16 => mapping(address => uint))) private _collateralByIssuerAggregation;
    // collateral currency key => user address => amount
    mapping(bytes32 => mapping(address => uint)) private _collateralByIssuer;
    mapping(bytes32 => mapping(uint16 => uint)) private _chainSynthTotalSupply;
    mapping(bytes32 => uint) private _synthTotalSupply;

    event ChangeAuthority(address indexed account, bool state);

    modifier onlyBridge() {
        require(msg.sender == synthrBridge, "Caller is not SynthrBridge");
        _;
    }

    function synthTotalSupply(bytes32 synthKey) external view returns (uint) {
        return _synthTotalSupply[synthKey];
    }

    function chainSynthTotalSupply(bytes32 synthKey, uint16 chainId) external view returns (uint) {
        if (chainId == 0) {
            return _chainSynthTotalSupply[synthKey][_selfLZChainId];
        }
        return _chainSynthTotalSupply[synthKey][chainId];
    }

    function collateralByIssuerAggregation(
        bytes32 currencyKey,
        uint16 chainId,
        address account
    ) external view returns (uint) {
        if (chainId == 0) {
            return _collateralByIssuerAggregation[currencyKey][_selfLZChainId][account];
        }
        return _collateralByIssuerAggregation[currencyKey][chainId][account];
    }

    function collateralByIssuer(bytes32 currencyKey, address account) external view returns (uint) {
        return _collateralByIssuer[currencyKey][account];
    }

    function initialize(
        address __exchangeFeeAddress,
        address __synthrBridge,
        uint16 __selfLZChainId
    ) external onlyOwner {
        _exchangeFeeAddress = __exchangeFeeAddress;
        synthrBridge = __synthrBridge;
        _selfLZChainId = __selfLZChainId;
    }

    function depositCollateral(
        address account,
        bytes32 collateralKey,
        uint amount,
        uint16 chainId
    ) external onlyBridge {
        _collateralByIssuerAggregation[collateralKey][chainId][account] += amount;
        _collateralByIssuer[collateralKey][account] += amount;
    }

    function mintSynth(
        bytes32 synthKey,
        uint synthAmount,
        uint16 chainId
    ) external onlyBridge {
        _chainSynthTotalSupply[synthKey][chainId] += synthAmount;
        _synthTotalSupply[synthKey] += synthAmount;
    }

    function withdrawCollateral(
        address account,
        uint amount,
        bytes32 collateralKey,
        uint16 chainId
    ) external onlyBridge {
        uint preAmount = _collateralByIssuerAggregation[collateralKey][chainId][account];
        _collateralByIssuerAggregation[collateralKey][chainId][account] = preAmount > amount ? preAmount - amount : 0;
        preAmount = _collateralByIssuer[collateralKey][account];
        _collateralByIssuer[collateralKey][account] = preAmount > amount ? preAmount - amount : 0;
    }

    function burnSynth(
        bytes32 synthKey,
        uint synthAmount,
        uint16 chainId
    ) external onlyBridge {
        uint preAmount = _chainSynthTotalSupply[synthKey][chainId];
        _chainSynthTotalSupply[synthKey][chainId] = preAmount > synthAmount ? preAmount - synthAmount : 0;
        preAmount = _synthTotalSupply[synthKey];
        _synthTotalSupply[synthKey] = preAmount > synthAmount ? preAmount - synthAmount : 0;
    }

    function exchangeSynth(
        bytes32 sourceKey,
        uint sourceAmount,
        bytes32 destKey,
        uint destAmount,
        uint fee,
        uint16 srcChainId,
        uint16 destChainId
    ) external onlyBridge {
        uint preAmount = _chainSynthTotalSupply[sourceKey][srcChainId];
        _chainSynthTotalSupply[sourceKey][srcChainId] = preAmount > sourceAmount ? preAmount - sourceAmount : 0;
        preAmount = _synthTotalSupply[sourceKey];
        _synthTotalSupply[sourceKey] = preAmount > sourceAmount ? preAmount - sourceAmount : 0;
        _chainSynthTotalSupply[destKey][destChainId] += destAmount;
        _synthTotalSupply[destKey] += destAmount;
        //
        _chainSynthTotalSupply[bytes32("sUSD")][_selfLZChainId] += fee;
    }

    function liquidate(
        address account,
        bytes32 collateralKey,
        uint collateralAmount,
        uint16 destChainId
    ) external onlyBridge {
        _collateralByIssuerAggregation[collateralKey][destChainId][account] -= collateralAmount;
    }

    function bridgeSynth(
        bytes32 synthKey,
        uint amount,
        uint16 srcChainId,
        uint16 dstChainId
    ) external onlyBridge {
        uint preAmount = _chainSynthTotalSupply[synthKey][srcChainId];
        _chainSynthTotalSupply[synthKey][srcChainId] = preAmount > amount ? preAmount - amount : 0;
        _chainSynthTotalSupply[synthKey][dstChainId] += amount;
    }
}