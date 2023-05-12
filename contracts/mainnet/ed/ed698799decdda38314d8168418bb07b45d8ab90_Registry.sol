// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "mixins/Operatable.sol";

contract Registry is Operatable {
    error ErrKeyNotFound();
    error ErrReservedBucketName();

    struct Entry {
        bytes32 key;
        bytes content;
        string encoding;
    }

    bytes32 public constant ALL_BUCKETNAME = keccak256(abi.encodePacked("*"));

    mapping(bytes32 => Entry) public entries;
    mapping(bytes32 => bytes32[]) public bucketKeys;
    mapping(bytes32 => mapping(bytes32 => bool)) public bucketEntryExists;

    function encodeKeyName(string memory key) external pure returns (bytes32) {
        return keccak256(abi.encode(key));
    }

    function get(bytes32 key) external view returns (Entry memory entry) {
        entry = entries[key];

        if (entry.content.length == 0) {
            revert ErrKeyNotFound();
        }

        return entry;
    }

    function getMany(bytes32 bucketName) external view returns (Entry[] memory bucketEntries) {
        bytes32[] memory keys = bucketKeys[bucketName];
        bucketEntries = new Entry[](keys.length);
        for (uint256 i = 0; i < keys.length; ) {
            bucketEntries[i] = entries[keys[i]];

            unchecked {
                ++i;
            }
        }
    }

    function getBucketSize(bytes32 bucketName) external view returns (uint256) {
        return bucketKeys[bucketName].length;
    }

    /// encoding is a string with a valid list of solidity types
    /// for example: "(uint256,bytes,bool)"
    function set(
        bytes32 key,
        bytes32 bucketName,
        bytes memory content,
        string memory encoding
    ) external onlyOperators {
        _set(key, bucketName, content, encoding);
    }

    function clearBucket(bytes32 bucketName) external onlyOperators {
        _validateBucketName(bucketName);

        bytes32[] memory keys = bucketKeys[bucketName];
        for (uint256 i = 0; i < keys.length; ) {
            bucketEntryExists[bucketName][keys[i]] = false;
            unchecked {
                ++i;
            }
        }

        delete bucketKeys[bucketName];
    }

    function removeFromBucket(bytes32 key, bytes32 bucketName) external onlyOperators {
        _validateBucketName(bucketName);
        _removeFromBucket(key, bucketName);
    }

    function removeFromBucket(bytes32[] memory keys, bytes32 bucketName) external onlyOperators {
        _validateBucketName(bucketName);

        for (uint256 i = 0; i < keys.length; ) {
            _removeFromBucket(keys[i], bucketName);
            unchecked {
                ++i;
            }
        }
    }

    function addToBucket(bytes32[] memory keys, bytes32 bucketName) external onlyOperators {
        _validateBucketName(bucketName);

        for (uint256 i = 0; i < keys.length; ) {
            _addToBucket(keys[i], bucketName);
            unchecked {
                ++i;
            }
        }
    }

    function setMany(
        bytes32[] memory keys,
        bytes[] memory contents,
        string memory encoding,
        bytes32 bucketName
    ) external onlyOperators {
        for (uint256 i = 0; i < keys.length; ) {
            _set(keys[i], bucketName, contents[i], encoding);
            unchecked {
                ++i;
            }
        }
    }

    function setMany(
        bytes32[] memory keys,
        bytes[] memory contents,
        string[] memory encodings,
        bytes32[] memory bucketNames
    ) external onlyOperators {
        for (uint256 i = 0; i < keys.length; ) {
            _set(keys[i], bucketNames[i], contents[i], encodings[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _set(
        bytes32 key,
        bytes32 bucketName,
        bytes memory content,
        string memory encoding
    ) private {
        Entry storage entry = entries[key];
        entry.key = key;
        entry.content = content;
        entry.encoding = encoding;

        if (bucketName != bytes32(0)) {
            _validateBucketName(bucketName);
            _addToBucket(key, bucketName);
        }

        // add to default bucket
        _addToBucket(key, ALL_BUCKETNAME);
    }

    function _addToBucket(bytes32 key, bytes32 bucketName) private {
        if (!bucketEntryExists[bucketName][key]) {
            bucketEntryExists[bucketName][key] = true;
            bucketKeys[bucketName].push(key);
        }
    }

    function _removeFromBucket(bytes32 key, bytes32 bucketName) private {
        if (bucketEntryExists[bucketName][key]) {
            bucketEntryExists[bucketName][key] = false;

            bytes32[] storage keys = bucketKeys[bucketName];

            for (uint256 i = 0; i < keys.length; ) {
                if (key == keys[i]) {
                    keys[i] = keys[keys.length - 1];
                    keys.pop();
                    return;
                }
                unchecked {
                    ++i;
                }
            }
        }
    }

    function _validateBucketName(bytes32 bucketName) private pure {
        if (bucketName == ALL_BUCKETNAME) {
            revert ErrReservedBucketName();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/BoringOwnable.sol";

contract Operatable is BoringOwnable {
    event OperatorChanged(address indexed, bool);
    error NotAllowedOperator();

    mapping(address => bool) public operators;

    constructor() {
        operators[msg.sender] = true;
    }

    modifier onlyOperators() {
        if (!operators[msg.sender]) {
            revert NotAllowedOperator();
        }
        _;
    }

    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorChanged(operator, status);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}