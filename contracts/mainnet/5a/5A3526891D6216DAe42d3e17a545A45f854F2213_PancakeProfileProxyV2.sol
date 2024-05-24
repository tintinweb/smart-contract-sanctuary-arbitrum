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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/** @title IIFODeployerV8.
 * @notice It is an interface for IFODeployerV8.sol
 */
interface IIFODeployerV8 {

    function previousIFOAddress() external view returns (address);

    function currIFOAddress() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/** @title IIFOV8Minimal.
 * @notice It is an interface for IFOV8.sol
 */
interface IIFOV8Minimal {
    function endTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserInfo {
    struct UserProfilePack {
        uint256 userId;
        uint256 numberPoints;
        address nftAddress;
        uint256 tokenId;
        bool isActive;
    }

    struct UserCreditPack {
        uint256 userCredit;
        uint256 lockStartTime;
        uint256 lockEndTime;
    }

    struct UserVeCakePack {
        int128 amount;
        uint256 end;
        address cakePoolProxy;
        uint128 cakeAmount;
        uint48 lockEndTime;
    }

    struct TotalVeCakePack {
        address userAddress;
        uint256 executionTimestamp;
        uint256 supply;
        bool syncVeCake;
        bool syncProfile;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin-4.5.0/contracts/access/Ownable.sol";
import "./interfaces/IUserInfo.sol";
import "./interfaces/IIFODeployerV8.sol";
import "./interfaces/IIFOV8Minimal.sol";

contract PancakeProfileProxyV2 is Ownable {
    address public IFODeployerV8Address;

    address public receiver;

    /// @dev mapping [user][userProfilePack]
    mapping(address => IUserInfo.UserProfilePack) public userProfiles;

    /// @dev mapping [user][ifoAddress][expireDate]
    mapping(address => mapping(address => uint256)) public dataExpireDates;

    event UserProfileUpdated(address indexed userAddress, uint256 userId, bool isActive);

    /**
    * @notice Checks if the msg.sender is the receiver address
     */
    modifier onlyReceiver() {
        require(msg.sender == receiver, "None receiver!");
        _;
    }

    constructor(address _deployer, address _receiver) {
        IFODeployerV8Address = _deployer;
        receiver = _receiver;
    }

    /// @dev Update receiver address in this contract, this is called by owner only
    /// @param _receiver the address of new receiver
    function updateReceiver(address _receiver) external onlyOwner {
        require(receiver != _receiver, "receiver not change");
        receiver = _receiver;
    }

    function updateDeployer(address _deployer) external onlyOwner {
        require(IFODeployerV8Address != _deployer, "IFODeployerV8Address not change");
        IFODeployerV8Address = _deployer;
    }

    function setUserProfile(
        address _userAddress,
        uint256 _userId,
        uint256 _numberPoints,
        address _nftAddress,
        uint256 _tokenId,
        bool _isActive) external onlyReceiver {

        require(_userAddress != address(0), "setUserProfile: Invalid address");

        IUserInfo.UserProfilePack storage pack = userProfiles[_userAddress];
        pack.userId = _userId;
        pack.numberPoints = _numberPoints;
        pack.nftAddress = _nftAddress;
        pack.tokenId = _tokenId;
        pack.isActive = _isActive;

        address currIFOAddress = IIFODeployerV8(IFODeployerV8Address).currIFOAddress();

        if (currIFOAddress != address(0)) {
            uint256 ifoEndTimestamp = IIFOV8Minimal(currIFOAddress).endTimestamp();

            if (block.timestamp < ifoEndTimestamp) {
                dataExpireDates[_userAddress][currIFOAddress] = ifoEndTimestamp;
            } else {
                dataExpireDates[_userAddress][currIFOAddress] = type(uint256).max;
            }
        }

        emit UserProfileUpdated(_userAddress, _userId, _isActive);
    }

    function getUserProfile(address _userAddress)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        address,
        uint256,
        bool
    ) {
        require(_userAddress != address(0), "getUserProfile: Invalid address");

        address currIFOAddress = IIFODeployerV8(IFODeployerV8Address).currIFOAddress();

        if (dataExpireDates[_userAddress][currIFOAddress] < block.timestamp) {
            return (0, 0, 0, address(0x0), 0, false);
        }
        return (
            userProfiles[_userAddress].userId,
            userProfiles[_userAddress].numberPoints,
            0,
            userProfiles[_userAddress].nftAddress,
            userProfiles[_userAddress].tokenId,
            userProfiles[_userAddress].isActive
        );
    }

    function getUserStatus(address _userAddress) external view returns (bool) {
        require(_userAddress != address(0), "getUserStatus: Invalid address");

        address currIFOAddress = IIFODeployerV8(IFODeployerV8Address).currIFOAddress();

        if (dataExpireDates[_userAddress][currIFOAddress] < block.timestamp) {
            return false;
        }
        return userProfiles[_userAddress].isActive;
    }

    function getTeamProfile(uint256)
    external
    pure
    returns (
        string memory,
        string memory,
        uint256,
        uint256,
        bool
    ) {
        return ("", "", 0, 0, false);
    }

    /**
     * @dev To increase the number of points for a user.
     * Callable only by point admins
     */
    function increaseUserPoints(
        address _userAddress,
        uint256 _numberPoints,
        uint256 _campaignId
    ) external {

    }
}