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
pragma solidity =0.8.9;

interface IKycManager {
    enum KycType {
        NON_KYC,
        US_KYC,
        GENERAL_KYC
    }

    struct User {
        KycType kycType;
        bool isBanned;
    }

    function onlyNotBanned(address investor) external view;

    function onlyKyc(address investor) external view;

    function isBanned(address investor) external view returns (bool);

    function isKyc(address investor) external view returns (bool);

    function isUSKyc(address investor) external view returns (bool);

    function isNonUSKyc(address investor) external view returns (bool);

    function isStrict() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IKycManager.sol";

contract KycManager is IKycManager, Ownable {
    event GrantKyc(address _investor, KycType _kycType);
    event RevokeKyc(address _investor, KycType _kycType);
    event Banned(address _investor, bool _status);
    event SetStrict(bool _status);

    mapping(address => User) userList;
    bool strictOn;

    modifier onlyNonZeroAddress(address _investor) {
        require(_investor != address(0), "invalid address");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                          GRANT KYC
    //////////////////////////////////////////////////////////////*/
    function grantKycInBulk(
        address[] calldata _investors,
        KycType[] calldata _kycTypes
    ) external onlyOwner {
        require(_investors.length == _kycTypes.length, "invalid input");
        for (uint256 i = 0; i < _investors.length; i++) {
            _grantKyc(_investors[i], _kycTypes[i]);
        }
    }

    function _grantKyc(
        address _investor,
        KycType _kycType
    ) internal onlyNonZeroAddress(_investor) {
        require(
            KycType.US_KYC == _kycType || KycType.GENERAL_KYC == _kycType,
            "invalid kyc type"
        );

        User storage user = userList[_investor];
        user.kycType = _kycType;
        emit GrantKyc(_investor, _kycType);
    }

    /*//////////////////////////////////////////////////////////////
                          REVOKE KYC
    //////////////////////////////////////////////////////////////*/
    function revokeKycInBulk(address[] calldata _investors) external onlyOwner {
        for (uint256 i = 0; i < _investors.length; i++) {
            _revokeKyc(_investors[i]);
        }
    }

    function _revokeKyc(
        address _investor
    ) internal onlyNonZeroAddress(_investor) {
        User storage user = userList[_investor];
        emit RevokeKyc(_investor, user.kycType);
        user.kycType = KycType.NON_KYC;
    }

    /*//////////////////////////////////////////////////////////////
                          BAN KYC
    //////////////////////////////////////////////////////////////*/
    function bannedInBulk(address[] calldata _investors) external onlyOwner {
        for (uint256 i = 0; i < _investors.length; i++) {
            _bannedInternal(_investors[i], true);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          UNBAN KYC
    //////////////////////////////////////////////////////////////*/
    function unBannedInBulk(address[] calldata _investors) external onlyOwner {
        for (uint256 i = 0; i < _investors.length; i++) {
            _bannedInternal(_investors[i], false);
        }
    }

    function _bannedInternal(
        address _investor,
        bool _status
    ) internal onlyNonZeroAddress(_investor) {
        User storage user = userList[_investor];
        user.isBanned = _status;
        emit Banned(_investor, _status);
    }

    function setStrict(bool _status) external onlyOwner {
        strictOn = _status;
        emit SetStrict(_status);
    }

    /*//////////////////////////////////////////////////////////////
                            USED BY INTERFACE
    //////////////////////////////////////////////////////////////*/
    function getUserInfo(
        address _investor
    ) external view returns (User memory user) {
        user = userList[_investor];
    }

    function onlyNotBanned(address _investor) external view {
        require(!userList[_investor].isBanned, "user is banned");
    }

    function onlyKyc(address _investor) external view {
        require(
            KycType.NON_KYC != userList[_investor].kycType,
            "not a kyc user"
        );
    }

    function isBanned(address _investor) external view returns (bool) {
        return userList[_investor].isBanned;
    }

    function isKyc(address _investor) external view returns (bool) {
        return KycType.NON_KYC != userList[_investor].kycType;
    }

    function isUSKyc(address _investor) external view returns (bool) {
        return KycType.US_KYC == userList[_investor].kycType;
    }

    function isNonUSKyc(address _investor) external view returns (bool) {
        return KycType.GENERAL_KYC == userList[_investor].kycType;
    }

    function isStrict() external view returns (bool) {
        return strictOn;
    }
}