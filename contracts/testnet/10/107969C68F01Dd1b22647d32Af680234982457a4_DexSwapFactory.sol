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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

abstract contract Constants {
    uint256 public constant DIVIDER = 10000;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./interfaces/IDexSwapERC20.sol";

contract DexSwapERC20 is IDexSwapERC20 {
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    string public constant name = "DexSwap LPs";
    string public constant symbol = "DexSwap-LP";
    uint8 public constant decimals = 18;

    bytes32 public override DOMAIN_SEPARATOR;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "DexSwapERC20: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "DexSwapERC20: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IDexSwapFactory.sol";
import "./DexSwapPair.sol";

contract DexSwapFactory is IDexSwapFactory, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _feeWhitelist;
    EnumerableSet.AddressSet private _peripheryWhitelist;
    EnumerableSet.AddressSet private _contractsWhitelist;

    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(DexSwapPair).creationCode));

    uint256 public fee;
    address public feeTo;
    address public feeToSetter;
    uint256 public protocolShare;

    address[] public allPairs;

    mapping(address => mapping(address => address)) public getPair;

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function contractsWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 contractsWhitelistLength = _contractsWhitelist.length();
        if (offset >= contractsWhitelistLength) return new address[](0);
        uint256 to = offset + limit;
        if (contractsWhitelistLength < to) to = contractsWhitelistLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _contractsWhitelist.at(offset + i);
    }

    function contractsWhitelist(uint256 index) external view returns (address) {
        return _contractsWhitelist.at(index);
    }

    function contractsWhitelistContains(address contract_) external view returns (bool) {
        return _contractsWhitelist.contains(contract_);
    }

    function contractsWhitelistCount() external view returns (uint256) {
        return _contractsWhitelist.length();
    }

    function feeWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 feeWhitelistLength = _feeWhitelist.length();
        if (offset >= feeWhitelistLength) return new address[](0);
        uint256 to = offset + limit;
        if (feeWhitelistLength < to) to = feeWhitelistLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _feeWhitelist.at(offset + i);
    }

    function feeWhitelist(uint256 index) external view returns (address) {
        return _feeWhitelist.at(index);
    }

    function feeWhitelistContains(address account) external view returns (bool) {
        return _feeWhitelist.contains(account);
    }

    function feeWhitelistCount() external view returns (uint256) {
        return _feeWhitelist.length();
    }

    function peripheryWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 peripheryWhitelistLength = _peripheryWhitelist.length();
        if (offset >= peripheryWhitelistLength) return new address[](0);
        uint256 to = offset + limit;
        if (peripheryWhitelistLength < to) to = peripheryWhitelistLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _peripheryWhitelist.at(offset + i);
    }

    function peripheryWhitelist(uint256 index) external view returns (address) {
        return _peripheryWhitelist.at(index);
    }

    function peripheryWhitelistContains(address account) external view returns (bool) {
        return _peripheryWhitelist.contains(account);
    }

    function peripheryWhitelistCount() external view returns (uint256) {
        return _peripheryWhitelist.length();
    }

    constructor(address _feeToSetter) {
        feeToSetter = _feeToSetter;
    }

    function createPair(address tokenA, address tokenB) external onlyOwner returns (address pair) {
        require(tokenA != tokenB, "DexSwapFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "DexSwapFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "DexSwapFactory: PAIR_EXISTS");
        bytes memory bytecode = type(DexSwapPair).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IDexSwapPair pair_ = IDexSwapPair(pair);
        pair_.initialize(token0, token1);
        pair_.updateFee(fee);
        pair_.updateProtocolShare(protocolShare);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function addContractsWhitelist(address[] memory contracts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < contracts.length; i++) {
            require(contracts[i] != address(0), "DexSwapFactory: Contract is zero address");
            _contractsWhitelist.add(contracts[i]);
        }
        emit ContractsWhitelistAdded(contracts);
        return true;
    }

    function addFeeWhitelist(address[] memory accounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "DexSwapFactory: Account is zero address");
            _feeWhitelist.add(accounts[i]);
        }
        emit FeeWhitelistAdded(accounts);
        return true;
    }

    function addPeripheryWhitelist(address[] memory periphery) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < periphery.length; i++) {
            require(periphery[i] != address(0), "DexSwapFactory: Periphery is zero address");
            _peripheryWhitelist.add(periphery[i]);
        }
        emit PeripheryWhitelistAdded(periphery);
        return true;
    }

    function removeContractsWhitelist(address[] memory contracts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < contracts.length; i++) {
            _contractsWhitelist.remove(contracts[i]);
        }
        emit ContractsWhitelistRemoved(contracts);
        return true;
    }

    function removeFeeWhitelist(address[] memory accounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < accounts.length; i++) {
            _feeWhitelist.remove(accounts[i]);
        }
        emit FeeWhitelistRemoved(accounts);
        return true;
    }

    function removePeripheryWhitelist(address[] memory periphery) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < periphery.length; i++) {
            _peripheryWhitelist.remove(periphery[i]);
        }
        emit PeripheryWhitelistRemoved(periphery);
        return true;
    }

    function skim(address token0, address token1, address to) external onlyOwner returns (bool) {
        require(to != address(0), "DexSwapFactory: Recipient is zero address");
        IDexSwapPair(getPair[token0][token1]).skim(to);
        emit Skimmed(token0, token1, to);
        return true;
    }

    function updateFee(uint256 fee_) external onlyOwner returns (bool) {
        fee = fee_;
        emit FeeUpdated(fee_);
        return true;
    }

    function updateProtocolShare(uint256 share) external onlyOwner returns (bool) {
        protocolShare = share;
        emit ProtocolShareUpdated(share);
        return true;
    }

    function updateFeePair(address token0, address token1, uint256 fee_) external onlyOwner returns (bool) {
        IDexSwapPair(getPair[token0][token1]).updateFee(fee_);
        emit FeePairUpdated(token0, token1, fee_);
        return true;
    }

    function updateProtocolSharePair(address token0, address token1, uint256 share) external onlyOwner returns (bool) {
        IDexSwapPair(getPair[token0][token1]).updateFee(share);
        emit ProtocolSharePairUpdated(token0, token1, share);
        return true;
    }

    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, "DexSwapFactory: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, "DexSwapFactory: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./DexSwapERC20.sol";
import "./abstracts/Constants.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/IDexSwapPair.sol";
import "./interfaces/IDexSwapFactory.sol";
import "./interfaces/IDexSwapCallee.sol";

import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

contract DexSwapPair is IDexSwapPair, DexSwapERC20, Constants {
    using UQ112x112 for uint224;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint256 public constant MINIMUM_LIQUIDITY = 10 ** 3;
    uint256 public constant MAX_FEE = 100;
    uint256 public constant MAX_PROTOCOL_SHARE = 100;

    uint256 public fee;
    uint256 public protocolShare;
    address public factory;
    address public token0;
    address public token1;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    uint256 public kLast;

    uint256 internal decimals0;
    uint256 internal decimals1;

    uint256 private blockTimestampLast;
    uint112 private reserve0;
    uint112 private reserve1;
    uint256 private unlocked = 1;

    function getAmountIn(uint256 amountOut, address tokenIn, address caller) public view returns (uint256 amountIn) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();
        require(amountOut > 0, "DexSwapPair: INSUFFICIENT_INPUT_AMOUNT");
        require(_reserve0 > 0 && _reserve1 > 0, "DexSwapPair: INSUFFICIENT_LIQUIDITY");
        if (tokenIn == token1) (_reserve0, _reserve1) = (_reserve1, _reserve0);
        uint256 fee_ = IDexSwapFactory(factory).feeWhitelistContains(caller) ? 0 : fee;
        uint256 numerator = _reserve0 * amountOut * DIVIDER;
        uint256 denominator = (_reserve1 - amountOut) * (DIVIDER - fee_);
        amountIn = (numerator / denominator) + 1;
    }

    function getAmountOut(uint256 amountIn, address tokenIn, address caller) public view returns (uint256 amountOut) {
        (uint256 _reserve0, uint256 _reserve1, ) = getReserves();
        require(amountIn > 0, "DexSwapPair: INSUFFICIENT_INPUT_AMOUNT");
        require(_reserve0 > 0 && _reserve1 > 0, "DexSwapPair: INSUFFICIENT_LIQUIDITY");
        uint256 fee_ = IDexSwapFactory(factory).feeWhitelistContains(caller) ? 0 : fee;
        if (tokenIn == token1) (_reserve0, _reserve1) = (_reserve1, _reserve0);
        uint amountInWithFee = amountIn * (DIVIDER - fee_);
        uint numerator = amountInWithFee * _reserve1;
        uint denominator = (_reserve0 * DIVIDER) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint256 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    constructor() {
        factory = msg.sender;
    }

    function burn(address to) external lock returns (uint256 amount0, uint256 amount1) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        address _token0 = token0;
        address _token1 = token1;
        uint256 balance0 = IERC20(_token0).balanceOf(address(this));
        uint256 balance1 = IERC20(_token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        amount0 = (liquidity * balance0) / _totalSupply;
        amount1 = (liquidity * balance1) / _totalSupply;
        require(amount0 > 0 && amount1 > 0, "DexSwapPair: INSUFFICIENT_LIQUIDITY_BURNED");
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        emit Burn(msg.sender, amount0, amount1, to);
    }

    function initialize(address _token0, address _token1) external onlyFactory {
        token0 = _token0;
        token1 = _token1;
        decimals0 = 10 ** IERC20(_token0).decimals();
        decimals1 = 10 ** IERC20(_token1).decimals();
    }

    function mint(address to) external lock returns (uint256 liquidity) {
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - _reserve0;
        uint256 amount1 = balance1 - _reserve1;
        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint256 _totalSupply = totalSupply;
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / _reserve0, (amount1 * _totalSupply) / _reserve1);
        }
        require(liquidity > 0, "DexSwapPair: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);
        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint256(reserve0) * reserve1;
        emit Mint(msg.sender, amount0, amount1);
    }

    function skim(address to) external onlyFactory lock {
        address _token0 = token0;
        address _token1 = token1;
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)) - reserve0);
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)) - reserve1);
    }

    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external {
        _swap(amount0Out, amount1Out, to, address(0), data);
    }

    function swapFromPeriphery(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        address caller,
        bytes calldata data
    ) external {
        require(
            IDexSwapFactory(factory).peripheryWhitelistContains(msg.sender),
            "DexSwapPair: Caller is not periphery"
        );
        _swap(amount0Out, amount1Out, to, caller, data);
    }

    function updateFee(uint256 fee_) external onlyFactory returns (bool) {
        require(fee_ <= MAX_FEE, "DexSwapFactory: Fee gt MAX_FEE");
        fee = fee_;
        emit FeeUpdated(fee_);
        return true;
    }

    function updateProtocolShare(uint256 share) external onlyFactory returns (bool) {
        require(share <= MAX_PROTOCOL_SHARE, "DexSwapFactory: Share gt MAX_PROTOCOL_SHARE");
        protocolShare = share;
        emit ProtocolShareUpdated(share);
        return true;
    }

    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IDexSwapFactory(factory).feeTo();
        feeOn = feeTo != address(0) && protocolShare > 0;
        uint256 _kLast = kLast;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(_reserve0) * _reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = (totalSupply * (rootK - rootKLast)) * protocolShare;
                    uint256 denominator = (rootK * (MAX_PROTOCOL_SHARE - protocolShare)) + (rootKLast * protocolShare);
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "DexSwapPair: TRANSFER_FAILED");
    }

    function _swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        address caller,
        bytes calldata data
    ) private lock {
        IDexSwapFactory factory_ = IDexSwapFactory(factory);
        require(
            factory_.contractsWhitelistContains(address(0)) ||
                msg.sender == tx.origin ||
                factory_.contractsWhitelistContains(msg.sender),
            "DexSwapPair: Caller is invalid"
        );
        require(amount0Out > 0 || amount1Out > 0, "DexSwapPair: INSUFFICIENT_OUTPUT_AMOUNT");
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();
        require(amount0Out < _reserve0 && amount1Out < _reserve1, "DexSwapPair: INSUFFICIENT_LIQUIDITY");
        uint256 balance0;
        uint256 balance1;
        {
            address _token0 = token0;
            address _token1 = token1;
            require(to != _token0 && to != _token1, "DexSwapPair: INVALID_TO");
            if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out);
            if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out);
            if (data.length > 0) IDexSwapCallee(to).dexSwapCall(msg.sender, amount0Out, amount1Out, data);
            balance0 = IERC20(_token0).balanceOf(address(this));
            balance1 = IERC20(_token1).balanceOf(address(this));
        }
        uint256 amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, "DexSwapPair: INSUFFICIENT_INPUT_AMOUNT");
        {
            uint256 fee_ = (caller != address(0) && factory_.feeWhitelistContains(caller)) ? 0 : fee;
            uint256 balance0Adjusted = (balance0 * DIVIDER) - (amount0In * fee_);
            uint256 balance1Adjusted = (balance1 * DIVIDER) - (amount1In * fee_);
            require(
                balance0Adjusted * balance1Adjusted >= (uint256(_reserve0) * _reserve1) * DIVIDER ** 2,
                "DexSwapPair: K"
            );
        }
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    function _update(uint256 balance0, uint256 balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, "DexSwapPair: OVERFLOW");
        uint256 blockTimestamp = block.timestamp % 2 ** 32;
        uint256 timeElapsed = blockTimestamp - blockTimestampLast;
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    modifier lock() {
        require(unlocked == 1, "DexSwapPair: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "DexSwapPair: Caller is not factory");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IDexSwapCallee {
    function dexSwapCall(address sender, uint256 amount0, uint256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IDexSwapERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function nonces(address owner) external view returns (uint256);

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IDexSwapFactory {
    event ContractsWhitelistAdded(address[] contracts);
    event ContractsWhitelistRemoved(address[] contracts);
    event FeeUpdated(uint256 fee);
    event ProtocolShareUpdated(uint256 share);
    event FeePairUpdated(address indexed token0, address indexed token1, uint256 fee);
    event ProtocolSharePairUpdated(address indexed token0, address indexed token1, uint256 share);
    event FeeWhitelistAdded(address[] accounts);
    event FeeWhitelistRemoved(address[] accounts);
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event PeripheryWhitelistAdded(address[] periphery);
    event PeripheryWhitelistRemoved(address[] periphery);
    event Skimmed(address indexed token0, address indexed token1, address to);

    function INIT_CODE_PAIR_HASH() external view returns (bytes32);

    function contractsWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    function contractsWhitelist(uint256 index) external view returns (address);

    function contractsWhitelistContains(address contract_) external view returns (bool);

    function contractsWhitelistCount() external view returns (uint256);

    function protocolShare() external view returns (uint256);

    function fee() external view returns (uint256);

    function feeWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    function feeWhitelist(uint256 index) external view returns (address);

    function feeWhitelistContains(address account) external view returns (bool);

    function feeWhitelistCount() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function peripheryWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output);

    function peripheryWhitelist(uint256 index) external view returns (address);

    function peripheryWhitelistContains(address account) external view returns (bool);

    function peripheryWhitelistCount() external view returns (uint256);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function addContractsWhitelist(address[] memory contracts) external returns (bool);

    function addFeeWhitelist(address[] memory accounts) external returns (bool);

    function addPeripheryWhitelist(address[] memory periphery) external returns (bool);

    function removeContractsWhitelist(address[] memory contracts) external returns (bool);

    function removeFeeWhitelist(address[] memory accounts) external returns (bool);

    function removePeripheryWhitelist(address[] memory periphery) external returns (bool);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function updateFee(uint256 fee_) external returns (bool);

    function updateProtocolShare(uint256 share) external returns (bool);

    function updateFeePair(address token0, address token1, uint256 fee_) external returns (bool);

    function updateProtocolSharePair(address token0, address token1, uint256 share) external returns (bool);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function skim(address token0, address token1, address to) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

import "./IDexSwapERC20.sol";

interface IDexSwapPair is IDexSwapERC20 {
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event FeeUpdated(uint256 fee);
    event ProtocolShareUpdated(uint256 share);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external view returns (uint256);

    function MAX_FEE() external view returns (uint256);

    function MAX_PROTOCOL_SHARE() external view returns (uint256);

    function factory() external view returns (address);

    function fee() external view returns (uint256);

    function protocolShare() external view returns (uint256);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getAmountOut(uint256 amountIn, address tokenIn, address caller) external view returns (uint256 amountOut);

    function getAmountIn(uint256 amountOut, address tokenIn, address caller) external view returns (uint256 amountIn);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint256 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function swapFromPeriphery(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        address caller,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;

    function updateFee(uint256 fee_) external returns (bool);

    function updateProtocolShare(uint256 share) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2 ** 112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}