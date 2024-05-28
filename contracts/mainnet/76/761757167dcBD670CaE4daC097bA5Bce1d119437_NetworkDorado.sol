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

interface INetwork {
    function updateReferralData(address _user, address _refAddress) external;

    function getReferralAccountForAccount(address _user) external view returns (address);

    function isAddressCanUpdateReferralData(address _user) external view returns (bool);

    function getReferralAccountForAccountExternal(address _user) external view returns (address);

    function getTotalMember(address _wallet, uint16 _maxFloor) external view returns (uint256);

    function getF1ListForAccount(address _wallet) external view returns (address[] memory);

    function possibleChangeReferralData(address _wallet) external returns (bool);

    function lockedReferralDataForAccount(address _user) external;

    function setSystemWallet(address _newSystemWallet) external;

    function setAddressCanUpdateReferralData(address account, bool hasUpdate) external;

    function checkValidRefCodeAdvance(address _user, address _refAddress) external returns (bool);

    function getActiveMemberForAccount(address _wallet) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./INetwork.sol";

contract NetworkDorado is INetwork, Ownable {

    struct ChildListData {
        address[] childList;
        uint256 memberCounter;
    }
    uint16 private maxFloor = 100;

    address public systemWallet;

    mapping(address => uint256) private totalActiveMembers;

    mapping(address => bool) private addressCanUpdateReferralData;

    mapping(address => ChildListData) private userF1ListData;

    mapping(address => address) private userRef;

    mapping(address => bool) private lockedReferralData;

    constructor(address _systemWallet) {
        systemWallet = _systemWallet;
    }

    function setAddressCanUpdateReferralData(address account, bool hasUpdate) public override onlyOwner {
        addressCanUpdateReferralData[account] = hasUpdate;
    }

    function isAddressCanUpdateReferralData(address account) public view override returns (bool) {
        return addressCanUpdateReferralData[account];
    }

    function getActiveMemberForAccount(address _wallet) external view override returns (uint256) {
        return totalActiveMembers[_wallet];
    }
    
    /**
        * @dev the function to update system wallet. Only owner can do this action
     */
    function setSystemWallet(address _newSystemWallet) external override onlyOwner {
        require(
            _newSystemWallet != address(0) && _newSystemWallet != systemWallet,
            "MARKETPLACE: INVALID SYSTEM WALLET"
        );
        systemWallet = _newSystemWallet;
    }

    /**
        * @dev the function return refferal address for specified address
     */
    function getReferralAccountForAccount(address _user) public view override returns (address) {
        address refWallet = address(0);
        refWallet = userRef[_user];
        if (refWallet == address(0)) {
            refWallet = systemWallet;
        }
        return refWallet;
    }

    /**
     * @dev the function return refferal address for specified address (without system)
     */
    function getReferralAccountForAccountExternal(address _user) public view override returns (address) {
        return userRef[_user];
    }

    /**
       * @dev get childlist of an address
     */
    function getF1ListForAccount(address _wallet) public view override returns (address[] memory) {
        return userF1ListData[_wallet].childList;
    }

    function getF1Next(address[] memory allF1s) internal view returns (address[] memory) {
        uint256 totalFNext = 0;
        address[] memory allF1Result;
        for (uint i = 0; i < allF1s.length; i++) {
            address[] memory allF1Index = getF1ListForAccount(allF1s[i]);
            totalFNext = totalFNext + allF1Index.length;
        }
        if (totalFNext == 0) {
            allF1Result = new address[](0);
        } else {
            uint256 counter = 0;
            address[] memory allFNext = new address[](totalFNext);
            for (uint i = 0; i < allF1s.length; i++) {
                address[] memory allF1Index = getF1ListForAccount(allF1s[i]);
                for (uint j = 0; j < allF1Index.length; j++) {
                    allFNext[counter] = allF1Index[j];
                    counter++;
                }
            }
            allF1Result = allFNext;
        }
        return allF1Result;
    }

    function getTotalMember(address _wallet, uint16 _maxFloor) external view override returns (uint256) {
        uint16 index = 1;
        uint256 total = 0;
        address[] memory allF1s = getF1ListForAccount(_wallet);
        total = total + allF1s.length;
        while (allF1s.length != 0 && index <= _maxFloor) {
            address[] memory addressNext = getF1Next(allF1s);
            if (addressNext.length > 0) {
                total = addressNext.length + total;
                allF1s = addressNext;
                index++;
            } else {
                break;
            }
        }
        return total;
    }

    /**
     * @dev update referral data function
     * @param _user user wallet address
     * @param _refAddress referral address of ref account
     */
    function updateReferralData(address _user, address _refAddress) public override {
        address refAddress = _refAddress;
        address refOfRefUser = getReferralAccountForAccountExternal(refAddress);
        require(
            isAddressCanUpdateReferralData(msg.sender) || msg.sender == _user,
            "MARKETPLACE: CONFLICT REF CODE"
        );
        require(refOfRefUser != _user, "MARKETPLACE: CONFLICT REF CODE");
        require(_refAddress != _user, "MARKETPLACE: CANNOT REF TO YOURSELF");
        require(_refAddress != msg.sender, "MARKETPLACE: CANNOT REF TO YOURSELF");
        require(checkValidRefCodeAdvance(msg.sender, _refAddress), "MARKETPLACE: CHEAT REF DETECTED");
        if (possibleChangeReferralData(_user)) {
            userRef[_user] = refAddress;
            lockedReferralDataForAccount(_user);
            // Update Active Members
            uint256 currentMember = totalActiveMembers[refAddress];
            totalActiveMembers[refAddress] = currentMember + 1;
            userF1ListData[refAddress].childList.push(_user);
            userF1ListData[refAddress].memberCounter += 1;
        }
    }

    function checkValidRefCodeAdvance(address _user, address _refAddress) public view override returns (bool) {
        bool isValid = true;
        address currentRefUser = _refAddress;
        address[] memory refTree = new address[](101);
        refTree[0] = _user;
        uint i = 1;
        while (i < 101 && currentRefUser != systemWallet) {
            for (uint j = 0; j < refTree.length; j++) {
                if (currentRefUser == refTree[j]) {
                    isValid = false;
                    break;
                }
            }
            refTree[i] = currentRefUser;
            currentRefUser = getReferralAccountForAccount(currentRefUser);
            ++i;
        }
        return isValid;
    }

    function updateF1ListForRefAccount(address _wallet, address[] memory _f1Lists) external onlyOwner {
        userF1ListData[_wallet].childList = _f1Lists;
        userF1ListData[_wallet].memberCounter = _f1Lists.length;
        uint index;
        for (index = 0; index < _f1Lists.length; index++) {
            userRef[_f1Lists[index]] = _wallet;
            lockedReferralData[_f1Lists[index]] = true;
        }
    }

    /**
        * @dev check possible to change referral data for a user
     * @param _user user wallet address
     */
    function possibleChangeReferralData(address _user) public view override returns (bool) {
        return !lockedReferralData[_user];
    }

    /**
     * @dev only update the referral data 1 time. After set cannot change the data again.
     */
    function lockedReferralDataForAccount(address _user) public override {
        require(lockedReferralData[_user] == false, "MARKETPLACE: USER'S REFERRAL INFORMATION HAS ALREADY BEEN LOCKED");
        lockedReferralData[_user] = true;
    }

    function updateLockedReferralDataByAdmin(address[] calldata _wallets, bool[] calldata _lockedReferralDatas) external onlyOwner {
        require(_wallets.length == _lockedReferralDatas.length, "MARKETPLACE: _wallets and _lockedReferralDatas must be same size");
        for (uint32 index = 0; index < _wallets.length; index++) {
            lockedReferralData[_wallets[index]] = _lockedReferralDatas[index];
        }
    }


    /**
         * @dev Recover lost bnb and send it to the contract owner
     */
    function recoverLostBNB() public onlyOwner {
        address payable recipient = payable(msg.sender);
        recipient.transfer(address(this).balance);
    }

    receive() external payable {}
}