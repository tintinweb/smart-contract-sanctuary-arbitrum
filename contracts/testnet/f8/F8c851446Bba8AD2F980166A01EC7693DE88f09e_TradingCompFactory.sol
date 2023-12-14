/**
 *Submitted for verification at Arbiscan.io on 2023-12-10
*/

// SPDX-License-Identifier: MIT AND UNLICENSED

// File @openzeppelin/contracts/utils/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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


// File @openzeppelin/contracts/access/[email protected]

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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


// File contracts/TradingComp.sol

// Original license: SPDX_License_Identifier: UNLICENSED

pragma solidity ^0.8.12;

contract TradingComp is Ownable {
    enum CompStatus {
        Registration,
        Open,
        Close
    }
    uint256 public startTime;
    uint256 public endTime;
    uint256 public regTime;

    mapping(address => UserInfo) public userInfo;
    address[] public pairAddresses;

    struct UserInfo {
        bool hasRegistered;
        bool hasClaimed;
        uint256 userRegTime;
    }

    event Register(address _address, uint256 _regTime);
    event NewPairSet(address _pair);
    event RemovePair(address _pair);
    event NewStartTime(uint256 _startTime, uint256 _prevTime);
    event NewEndTime(uint256 _endTime, uint256 _prevTime);
    event NewRegTime(uint256 _regTime, uint256 _prevTime);

    constructor(        
        uint256 _regTime,
        uint256 _startTime,
        uint256 _endTime,
        address _compOwner,
        address[] memory _pairs
    ) Ownable(msg.sender) {
        setRegTime(_regTime);
        setStartTime(_startTime);
        setEndTime(_endTime);
        setPairAddresses(_pairs);
        transferOwnership(_compOwner);
    }

    function registerForComp() external {
        require(!userInfo[msg.sender].hasRegistered, "User Already Registered");

        require(
            block.timestamp >= regTime && block.timestamp <= startTime,
            "Registration Closed For Competetion"
        );

        UserInfo storage newUserInfo = userInfo[msg.sender];
        newUserInfo.hasRegistered = true;
        newUserInfo.userRegTime = block.timestamp;

        emit Register(msg.sender, block.timestamp);
    }

    function getCompStatus() external view returns (CompStatus status) {
        if (block.timestamp >= regTime && block.timestamp <= startTime) {
            return CompStatus.Registration;
        } else if (block.timestamp >= startTime && block.timestamp <= endTime) {
            return CompStatus.Open;
        } else if (block.timestamp >= endTime) {
            return CompStatus.Close;
        }
    }

    function setPairAddresses(address[] memory _pairs) public onlyOwner {
        for (uint i = 0; i < _pairs.length; i++) {
            require(_pairs[i] != address(0), "Invalid Pair Address");
            bool isAlreadyAdded = false;
            for (uint j = 0; j < pairAddresses.length; j++) {
                if (pairAddresses[j] == _pairs[i]) {
                    isAlreadyAdded = true;
                    break;
                }
            }

            if (!isAlreadyAdded) {
                pairAddresses.push(_pairs[i]);
                emit NewPairSet(_pairs[i]); 
            }
        }
    }

    function removePairAddress(address _pair) public onlyOwner {
        require(_pair != address(0), "Invalid Pair Address");

        int256 indexToRemove = -1;
        for (uint i = 0; i < pairAddresses.length; i++) {
            if (pairAddresses[i] == _pair) {
                indexToRemove = int256(i);
                break;
            }
        }

        require(indexToRemove >= 0, "Pair Address Not Found");
        for (
            uint i = uint256(indexToRemove);
            i < pairAddresses.length - 1;
            i++
        ) {
            pairAddresses[i] = pairAddresses[i + 1];
        }

        pairAddresses.pop();
        emit RemovePair(_pair); 
    }

    function setStartTime(uint256 _startTime) public onlyOwner {
        require(
            _startTime > regTime,
            "Start time should be greater than registration time"
        );
        emit NewStartTime(_startTime, startTime);
        startTime = _startTime;
    }

    function setEndTime(uint256 _endTime) public onlyOwner {
        require(
            _endTime > startTime && block.timestamp <_endTime,
            "End time should be greater than startTime"
        );
        emit NewEndTime(_endTime, endTime);
        endTime = _endTime;
    }

    function setRegTime(uint256 _regTime) public onlyOwner {
        require(
            _regTime > block.timestamp,
            "Reg time should be greater than current block timestamp"
        );
        emit NewRegTime(_regTime, regTime);
        regTime = _regTime;
    }
}


// File contracts/CompFactory.sol

// Original license: SPDX_License_Identifier: UNLICENSED

pragma solidity ^0.8.12;


contract TradingCompFactory is Ownable {
    // This mapping relates a human-readable name for each trading comp contract to its address
    mapping(string => address) public tradingComps;
    event TradingCompDeployed(string compName, address indexed compAddress);
     constructor() Ownable(msg.sender){}
    function deployTradingComp(uint256 regTime,uint256 startTime,uint256 endTime, string calldata compName, address compOwner, address[] calldata pairs) public returns (address) {
        require(bytes(compName).length > 0, "Competetion name cannot be empty");
        require(tradingComps[compName] == address(0), "Competetion with this name already exists");

        // Creating a new instance of the TradingComp contract
        TradingComp newComp = new TradingComp(regTime,startTime,endTime,compOwner, pairs);
        address newCompAddress = address(newComp);

        // Store the newly created TradingComp contract address in the mapping searcheable by the provided compName
        tradingComps[compName] = newCompAddress;

        emit TradingCompDeployed(compName, newCompAddress);
        return newCompAddress;
    }

    function findTradingCompByName(string calldata compName) public view returns (address) {
        require(tradingComps[compName] != address(0), "Competetion address not found");
        return tradingComps[compName];
    }

}