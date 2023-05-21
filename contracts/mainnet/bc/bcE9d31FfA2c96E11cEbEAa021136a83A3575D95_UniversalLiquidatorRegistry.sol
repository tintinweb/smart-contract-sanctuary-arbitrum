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
pragma solidity 0.8.17;

import "../../libraries/DataTypes.sol";

abstract contract ULRegistryStorage {
    mapping(address => mapping(address => DataTypes.PathInfo)) public paths;
    mapping(bytes32 => address) public dexesInfo;

    bytes32[] internal _allDexes;
    address[] internal _intermediateTokens;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// imported contracts and libraries
import "@openzeppelin/contracts/access/Ownable.sol";

// interfaces
import "../interface/IUniversalLiquidatorRegistry.sol";

// libraries
import "../libraries/DataTypes.sol";
import "../libraries/Errors.sol";

// constants and types
import {ULRegistryStorage} from "./storage/ULRegistry.sol";

contract UniversalLiquidatorRegistry is
    Ownable,
    IUniversalLiquidatorRegistry,
    ULRegistryStorage
{
    function getPath(
        address _sellToken,
        address _buyToken
    ) public view override returns (DataTypes.SwapInfo[] memory) {
        if (paths[_sellToken][_buyToken].dex != bytes32(0)) {
            DataTypes.SwapInfo[] memory retPaths = new DataTypes.SwapInfo[](1);
            retPaths[0] = DataTypes.SwapInfo(
                dexesInfo[paths[_sellToken][_buyToken].dex],
                paths[_sellToken][_buyToken].paths
            );
            return retPaths;
        }

        for (uint256 idx; idx < _intermediateTokens.length; ) {
            if (
                paths[_sellToken][_intermediateTokens[idx]].dex != bytes32(0) &&
                paths[_intermediateTokens[idx]][_buyToken].dex != bytes32(0)
            ) {
                // found the intermediateToken and intermediateDex
                DataTypes.SwapInfo[] memory retPaths = new DataTypes.SwapInfo[](
                    2
                );
                retPaths[0] = DataTypes.SwapInfo(
                    dexesInfo[paths[_sellToken][_intermediateTokens[idx]].dex],
                    paths[_sellToken][_intermediateTokens[idx]].paths
                );
                retPaths[1] = DataTypes.SwapInfo(
                    dexesInfo[paths[_intermediateTokens[idx]][_buyToken].dex],
                    paths[_intermediateTokens[idx]][_buyToken].paths
                );
                return retPaths;
            }
            unchecked {
                ++idx;
            }
        }
        revert Errors.PathsNotExist();
    }

    function setPath(
        bytes32 _dex,
        address[] memory _paths
    ) external override onlyOwner {
        // dex should exist
        if (!_dexExists(_dex)) revert Errors.DexDoesNotExist();
        // path could also be an empty array
        if (_paths.length < 2) revert Errors.InvalidLength();

        // path can also be empty
        paths[_paths[0]][_paths[_paths.length - 1]] = DataTypes.PathInfo(
            _dex,
            _paths
        );
    }

    function setIntermediateToken(
        address[] memory _token
    ) public override onlyOwner {
        _intermediateTokens = _token;
    }

    function addDex(bytes32 _name, address _dex) public override onlyOwner {
        if (_dexExists(_name)) revert Errors.DexExists();
        dexesInfo[_name] = _dex;
        _allDexes.push(_name);
    }

    function changeDexAddress(
        bytes32 _name,
        address _dex
    ) public override onlyOwner {
        if (!_dexExists(_name)) revert Errors.DexDoesNotExist();
        dexesInfo[_name] = _dex;
    }

    function getAllDexes() public view override returns (bytes32[] memory) {
        uint256 totalDexes = 0;

        for (uint256 idx = 0; idx < _allDexes.length; ) {
            if (dexesInfo[_allDexes[idx]] != address(0)) {
                totalDexes++;
            }
            unchecked {
                ++idx;
            }
        }

        bytes32[] memory retDexes = new bytes32[](totalDexes);
        uint256 retIdx = 0;

        for (uint256 idx; idx < _allDexes.length; ) {
            if (dexesInfo[_allDexes[idx]] != address(0)) {
                retDexes[retIdx] = _allDexes[idx];
                retIdx++;
            }
            unchecked {
                ++idx;
            }
        }

        return retDexes;
    }

    function getAllIntermediateTokens()
        public
        view
        override
        returns (address[] memory)
    {
        return _intermediateTokens;
    }

    function _dexExists(bytes32 _name) internal view returns (bool) {
        return dexesInfo[_name] != address(0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// libraries
import "../libraries/DataTypes.sol";

interface IUniversalLiquidatorRegistry {
    function getPath(
        address _sellToken,
        address _buyToken
    ) external view returns (DataTypes.SwapInfo[] memory);

    function setPath(bytes32 _dex, address[] memory _paths) external;

    function setIntermediateToken(address[] memory _token) external;

    function addDex(bytes32 _name, address _address) external;

    function changeDexAddress(bytes32 _name, address _address) external;

    function getAllDexes() external view returns (bytes32[] memory);

    function getAllIntermediateTokens()
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library DataTypes {
    struct PathInfo {
        bytes32 dex;
        address[] paths;
    }

    struct SwapInfo {
        address dex;
        address[] paths;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library Errors {
    // UniversalLiquidatorRegistry errors
    error InvalidLength();
    error DexExists();
    error DexDoesNotExist();
    error PathsNotExist();
    // UniversalLiquidator errors
    error InvalidAddress();
}