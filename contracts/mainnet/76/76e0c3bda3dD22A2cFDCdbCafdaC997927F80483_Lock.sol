// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IBondNFT.sol";
import "./interfaces/IGovNFT.sol";

interface IGovNFTPreaudit is IGovNFT {
    function safeTransferMany(address _to, uint[] calldata _ids) external;
}

contract Lock is Ownable {

    uint256 public constant MIN_PERIOD = 7;
    uint256 public constant MAX_PERIOD = 365;

    IBondNFT public immutable bondNFT;
    IGovNFTPreaudit public immutable govNFT;

    mapping(address => bool) public allowedAssets;
    mapping(address => uint) public totalLocked;
    mapping(address => bool) private isApproved;

    constructor(
        address _bondNFTAddress,
        address _govNFT
    ) {
        require(_govNFT != address(0), "!gov");
        require(_bondNFTAddress != address(0), "!bond");

        bondNFT = IBondNFT(_bondNFTAddress);
        govNFT = IGovNFTPreaudit(_govNFT);
    }

    function claimAll() external {
        claimGovFees();
        uint256[] memory _ids = bondNFT.balanceIds(msg.sender);
        uint256 _l = _ids.length;
        for (uint256 i=0; i<_l; i++) {
            (uint256 _amount, address _tigAsset) = bondNFT.claim(_ids[i], msg.sender);
            if (_amount > 0) {
                IERC20(_tigAsset).transfer(msg.sender, _amount);
            }
        }
    }

    /**
     * @notice Claim pending rewards from a bond
     * @param _id Bond NFT id
     * @return address claimed tigAsset address
     */
    function claim(
        uint256 _id
    ) public returns (address) {
        claimGovFees();
        (uint256 _amount, address _tigAsset) = bondNFT.claim(_id, msg.sender);
        IERC20(_tigAsset).transfer(msg.sender, _amount);
        return _tigAsset;
    }

    /**
     * @notice Claim pending rewards left over from a bond transfer
     * @param _tigAsset token address being claimed
     */
    function claimDebt(
        address _tigAsset
    ) external {
        claimGovFees();
        uint256 amount = bondNFT.claimDebt(msg.sender, _tigAsset);
        IERC20(_tigAsset).transfer(msg.sender, amount);
    }

    /**
     * @notice Lock up tokens to create a bond
     * @param _asset tigAsset being locked
     * @param _amount tigAsset amount
     * @param _period number of days to be locked for
     */
    function lock(
        address _asset,
        uint256 _amount,
        uint256 _period
    ) public {
        require(_period <= MAX_PERIOD, "MAX PERIOD");
        require(_period >= MIN_PERIOD, "MIN PERIOD");
        require(allowedAssets[_asset], "!asset");

        claimGovFees();

        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        totalLocked[_asset] = totalLocked[_asset] + _amount;
        
        bondNFT.createLock( _asset, _amount, _period, msg.sender);
    }

    /**
     * @notice Reset the lock time and extend the period and/or token amount
     * @param _id Bond id being extended
     * @param _amount tigAsset amount being added
     * @param _period number of days being added
     */
    function extendLock(
        uint256 _id,
        uint256 _amount,
        uint256 _period
    ) public {
        address _asset = claim(_id);
        IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
        totalLocked[_asset] = totalLocked[_asset] + _amount;
        bondNFT.extendLock(_id, _asset, _amount, _period, msg.sender);
    }

    /**
     * @notice Release the bond once it's expired
     * @param _id Bond id being released
     */
    function release(
        uint256 _id
    ) public {
        claimGovFees();
        (uint256 amount, uint256 lockAmount, address asset, address _owner) = bondNFT.release(_id, msg.sender);
        totalLocked[asset] = totalLocked[asset] - lockAmount;
        IERC20(asset).transfer(_owner, amount);
    }

    /**
     * @notice Claim rewards from gov nfts and distribute them to bonds
     */
    function claimGovFees() public {
        address[] memory assets = bondNFT.getAssets();

        uint256 balanceBefore;
        uint256 balanceAfter;

        for (uint256 i=0; i < assets.length; i++) {
            balanceBefore = IERC20(assets[i]).balanceOf(address(this));
            govNFT.claim(assets[i]);
            balanceAfter = IERC20(assets[i]).balanceOf(address(this));
            if (!isApproved[assets[i]]) {
                IERC20(assets[i]).approve(address(bondNFT), type(uint256).max);
                isApproved[assets[i]] = true;
            }
            bondNFT.distribute(assets[i], balanceAfter - balanceBefore);
        }
    }

    /**
     * @notice Whitelist an asset
     * @param _tigAsset tigAsset token address
     * @param _isAllowed set tigAsset as allowed
     */
    function editAsset(
        address _tigAsset,
        bool _isAllowed
    ) external onlyOwner() {
        allowedAssets[_tigAsset] = _isAllowed;
    }

    /**
     * @notice Owner can retrieve Gov NFTs
     * @param _ids array of gov nft ids
     */
    function sendNFTs(
        uint[] memory _ids
    ) external onlyOwner() {
        govNFT.safeTransferMany(msg.sender, _ids);
    }

    /**
     * @notice Owner can rescue tokens that are stuck in this contract
     * @param _token token address
     */
    function rescue(
        address _token
    ) external onlyOwner() {
        uint256 _toRescue = IERC20(_token).balanceOf(address(this)) - totalLocked[_token];
        IERC20(_token).transfer(owner(), _toRescue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IGovNFT {
    function distribute(address _tigAsset, uint256 _amount) external;
    function transferMany(address _to, uint[] calldata _ids) external;
    function transferFromMany(address _from, address _to, uint[] calldata _ids) external;
    function claim(address _tigAsset) external;
    function pending(address user, address _tigAsset) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBondNFT {
    function createLock(
        address _asset,
        uint256 _amount,
        uint256 _period,
        address _owner
    ) external returns(uint256 id);

    function extendLock(
        uint256 _id,
        address _asset,
        uint256 _amount,
        uint256 _period,
        address _sender
    ) external;

    function claim(
        uint256 _id,
        address _owner
    ) external returns(uint256 amount, address tigAsset);

    function claimDebt(
        address _owner,
        address _tigAsset
    ) external returns(uint256 amount);

    function release(
        uint256 _id,
        address _releaser
    ) external returns(uint256 amount, uint256 lockAmount, address asset, address _owner);

    function distribute(
        address _tigAsset,
        uint256 _amount
    ) external;

    function ownerOf(uint256 _id) external view returns (uint256);
    
    function totalAssets() external view returns (uint256);
    function getAssets() external view returns (address[] memory);
    function balanceIds(address) external view returns (uint256[] memory);
}

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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