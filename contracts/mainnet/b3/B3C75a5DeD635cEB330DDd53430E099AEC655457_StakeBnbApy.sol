// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IStakeApy {
    function setApy(uint256 _poolId, uint256 _poolIdEarnPerDay) external;

    function setApyExactly(uint256 _poolId, uint256[] calldata _startTime, uint256[] calldata _endTime, uint256[] calldata _tokenEarn) external;

    function getStartTime(uint256 _poolId) external view returns (uint256[] memory);

    function getEndTime(uint256 _poolId) external view returns (uint256[] memory);

    function getPoolApy(uint256 _poolId) external view returns (uint256[] memory);

    function getMaxIndex(uint256 _poolId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakeApy.sol";

contract StakeBnbApy is IStakeApy, Ownable {
    // mapping to store reward NFT Tier ean per day
    mapping(uint256 => uint256[]) public startTime;

    mapping(uint256 => uint256[]) public endTime;

    mapping(uint256 => uint256[]) public poolApy;

    constructor() {
        initApy();
    }

    /**
     * @dev init stake apr for each NFT ID
     */
    function initApy() internal {
        startTime[0] = [0];
        endTime[0] = [0];
        poolApy[0] = [390];
        startTime[1] = [0];
        endTime[1] = [0];
        poolApy[1] = [1180];
        startTime[2] = [0];
        endTime[2] = [0];
        poolApy[2] = [1380];
        startTime[3] = [0];
        endTime[3] = [0];
        poolApy[3] = [1770];
    }

    function getStartTime(uint256 _poolId) external view override returns (uint256[] memory) {
        return startTime[_poolId];
    }

    function getEndTime(uint256 _poolId) external view override returns (uint256[] memory) {
        return endTime[_poolId];
    }

    function getPoolApy(uint256 _poolId) external view override returns (uint256[] memory) {
        return poolApy[_poolId];
    }

    function getMaxIndex(uint256 _poolId) external view override returns (uint256) {
        return poolApy[_poolId].length;
    }

    function setApy(uint256 _poolId, uint256 _apy) external override onlyOwner {
        startTime[_poolId].push(block.timestamp);
        endTime[_poolId].pop();
        endTime[_poolId].push(block.timestamp);
        endTime[_poolId].push(0);
        poolApy[_poolId].push(_apy);
    }

    function setApyExactly(uint256 _poolId, uint256[] calldata _startTime, uint256[] calldata _endTime, uint256[] calldata _apy) external override onlyOwner {
        startTime[_poolId] = _startTime;
        endTime[_poolId] = _endTime;
        poolApy[_poolId] = _apy;
    }
}