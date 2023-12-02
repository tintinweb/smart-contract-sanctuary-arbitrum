// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../MicroUtility.sol";

pragma solidity ^0.8.4;

interface InitializableInterface {
    /**
     * @notice Used internally to initialize the contract instead of through a constructor
     * @dev This function is called by the deployer/factory when creating a contract
     * @param initPayload abi encoded payload to use for contract initilaization
     */
    function init(bytes memory initPayload) external returns (bool);
}

/**
 * @dev In the beginning there was a smart contract...
 */
contract MicroDrop is ReentrancyGuard, MicroUtility {
    event NewCollectionDeployed(
        address indexed sender,
        address indexed contractAddress
    );

    bool private initialized;

    uint256 public numberOfContracts;

    mapping(uint256 => address) public dropInfos;

    constructor() {}

    function init(bytes memory initPayload) external returns (bool) {
        require(!initialized, "Already initialized");
        (address _owner, address _manager) = abi.decode(
            initPayload,
            (address, address)
        );
        _setManager(_manager);
        transferOwnership(_owner);
        initialized = true;
        return true;
    }

    function deployWithPayload(
        bytes12 saltHash,
        bytes memory sourceCode,
        bytes memory initCode
    ) external nonReentrant payable {
        bytes32 salt = bytes32(
            keccak256(abi.encodePacked(msg.sender, saltHash))
        );

        address contractAddress = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            address(this),
                            salt,
                            keccak256(sourceCode)
                        )
                    )
                )
            )
        );

        require(!_isContract(contractAddress), "Micro: already deployed");

        assembly {
            contractAddress := create2(
                0,
                add(sourceCode, 0x20),
                mload(sourceCode),
                salt
            )
        }

        require(_isContract(contractAddress), "Micro: deployment failed");
        
        require(
            InitializableInterface(contractAddress).init(initCode),
            "Micro: initialization failed"
        );

        _payoutMicroFee(uint256(1));

        dropInfos[numberOfContracts] = contractAddress;

        numberOfContracts += 1;

        emit NewCollectionDeployed(msg.sender, contractAddress);
    }

    function _isContract(address contractAddress) internal view returns (bool) {
        bytes32 codehash;
        assembly {
            codehash := extcodehash(contractAddress)
        }
        return (codehash != 0x0 &&
            codehash !=
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IMicroManager {
    function microBridge(address _address) external view returns (bool);

    function treasuryAddress() external view returns (address);

    function microProtocolFee() external view returns (uint256);

    function oracleAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IPriceOracle {
    function convertUsdToWei(uint256 usdAmount) external view returns (uint256 weiAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import {IPriceOracle} from "./interfaces/IPriceOracle.sol";
import {IMicroManager} from "./interfaces/IMicroManager.sol";

contract MicroUtility is Ownable {
    IMicroManager public microManager;

    event FeePayout(
        uint256 MicroMintFeeWei,
        address MicroFeeRecipient,
        bool success
    );

    constructor(){}

    /**
     * PUBLIC FUNCTIONS
     * state changing
     */
    function getMicroFeeUsd(uint256 quantity)
        public
        view
        returns (uint256 fee)
    {
        fee = microManager.microProtocolFee() * quantity;
    }

    function getMicroFeeWei(uint256 quantity) public view returns (uint256) {
        return _usdToWei(microManager.microProtocolFee() * quantity);
    }

    function _payoutMicroFee(uint256 quantity) internal {
        // Transfer protocol mint fee to recipient address
        uint256 microProtocolFee = getMicroFeeWei(quantity);
        address payable treasury = payable(microManager.treasuryAddress());
        (bool success, ) = treasury.call{
            value: microProtocolFee
        }("");
        if (!success) {
            revert("Fee Payment Failed");
        }
        emit FeePayout(microProtocolFee, treasury, success);
    }

    function _usdToWei(uint256 amount)
        internal
        view
        returns (uint256 weiAmount)
    {
        if (amount == 0) {
            return 0;
        }
        weiAmount = IPriceOracle(microManager.oracleAddress()).convertUsdToWei(amount);
    }

    function _setManager(address _manager) internal {
        microManager = IMicroManager(_manager);
    }
}