// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../utils/Ownable.sol";

import "../interfaces/IMayfairCommunityStore.sol";

contract MayfairCommunityStore is IMayfairCommunityStore, Ownable {
    mapping(address => bool) private _writers;

    mapping(address => bool) public override isTokenWhitelisted;
    mapping(address => PoolInfo) private _poolInfo;
    mapping(address => mapping(address => bool)) private _privateInvestors;

    function setInvestor(
        address poolAddress,
        address investor,
        bool isApproved
    ) external override {
        require(_writers[msg.sender], "ERR_NOT_ALLOWED_WRITER");
        _privateInvestors[poolAddress][investor] = isApproved;
    }

    function setWriter(
        address writer,
        bool allowance
    ) external override onlyOwner {
        require(writer != address(0), "ERR_WRITER_ADDRESS_ZERO");
        _writers[writer] = allowance;
    }

    function whitelistToken(
        address token,
        bool whitelist
    ) external override onlyOwner {
        require(token != address(0), "ERR_TOKEN_ADDRESS_ZERO");
        isTokenWhitelisted[token] = whitelist;
    }

    function setManager(
        address poolAddress,
        address poolCreator,
        uint256 feesToManager,
        uint256 feesToReferral,
        bool isPrivate
    ) external override {
        require(poolAddress != address(0), "ERR_POOL_ADDRESS_ZERO");
        require(poolCreator != address(0), "ERR_MANAGER_ADDRESS_ZERO");
        require(_writers[msg.sender], "ERR_NOT_ALLOWED_WRITER");
        _poolInfo[poolAddress].manager = poolCreator;
        _poolInfo[poolAddress].feesToManager = feesToManager;
        _poolInfo[poolAddress].feesToReferral = feesToReferral;
        _poolInfo[poolAddress].isPrivate = isPrivate;
    }

    function setPrivatePool(
        address poolAddress,
        bool isPrivate
    ) external override {
        require(_writers[msg.sender], "ERR_NOT_ALLOWED_WRITER");
        _poolInfo[poolAddress].isPrivate = isPrivate;
    }

    function getPoolInfo(
        address poolAddress
    ) external view override returns (PoolInfo memory) {
        return _poolInfo[poolAddress];
    }

    function getPrivateInvestor(
        address poolAddress,
        address investor
    ) external view override returns (bool) {
        return _privateInvestors[poolAddress][investor];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IMayfairCommunityStore {
    struct PoolInfo {
        address manager;
        uint256 feesToManager;
        uint256 feesToReferral;
        bool isPrivate;
    }

    function setInvestor(
        address poolAddress,
        address investor,
        bool isAproved
    ) external;

    function isTokenWhitelisted(address token) external returns (bool);

    function getPoolInfo(
        address poolAddress
    ) external returns (PoolInfo calldata);

    function getPrivateInvestor(
        address poolAddress,
        address investor
    ) external returns (bool);

    function setWriter(address writer, bool allowance) external;

    function setPrivatePool(address poolAddress, bool isPrivate) external;

    function whitelistToken(address token, bool whitelist) external;

    function setManager(
        address poolAddress,
        address poolCreator,
        uint256 feesToManager,
        uint256 feesToReferral,
        bool isPrivate
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Ownable.sol interface
 *
 * @dev Other interfaces might inherit this one so it may be unnecessary to use it
 */
interface IOwnable {
    function getController() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IOwnable.sol";

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
abstract contract Ownable is IOwnable {
    // owner of the contract
    address private _owner;

    /**
     * @notice Emitted when the owner is changed
     *
     * @param previousOwner - The previous owner of the contract
     * @param newOwner - The new owner of the contract
     */
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "ERR_NOT_CONTROLLER");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     *         Can only be called by the current owner
     *
     * @dev external for gas optimization
     *
     * @param newOwner - Address of new owner
     */
    function setController(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ERR_ZERO_ADDRESS");

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }

    /**
     * @notice Returns the address of the current owner
     *
     * @dev external for gas optimization
     *
     * @return address - of the owner (AKA controller)
     */
    function getController() external view override returns (address) {
        return _owner;
    }
}