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
pragma solidity ^0.8.15;

import {Asset, AssetType} from "./EarnAssetTypes.sol";

contract EarnAssetController {
    //asset id => Asset
    mapping(bytes32 => Asset) internal _assets;

    function _getOrCreateAsset(
        bytes32 _assetId,
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) internal returns (Asset memory) {
        Asset memory sa = _assets[_assetId];
        if (sa.assetType == AssetType.UNDEFINED) {
            bytes32 newAssetId = _calculateAssetId(
                _assetAddress,
                _erc1155TokenId,
                _assetType
            );
            if (_assetId != 0) {
                require(newAssetId == _assetId, "EAC: assetId mismatch");
            }
            sa = Asset({
                assetAddress: _assetAddress,
                erc1155TokenId: _erc1155TokenId,
                assetType: _assetType
            });
            _assets[newAssetId] = sa;
        }
        return sa;
    }

    function _calculateAssetId(
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) internal pure returns (bytes32) {
        require(
            _assetType != AssetType.UNDEFINED,
            "EAC: assetType cannot be UNDEFINED"
        );
        return
            keccak256(
                abi.encodePacked(_assetAddress, _erc1155TokenId, _assetType)
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum AssetType {
    UNDEFINED,
    ERC20,
    ERC721,
    ERC1155,
    NATIVE
}

struct Asset {
    address assetAddress;
    uint256 erc1155TokenId;
    AssetType assetType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IEarnStakingManager.sol";
import "./EarnAssetController.sol";

contract EarnStakingManager is
    Ownable,
    IEarnStakingManager,
    EarnAssetController
{
    // ************ MODIFIERS ************ //

    modifier noAddressZero(address adr) {
        require(adr != address(0), "ESM: Wrong Address");
        _;
    }

    // ************ EVENTS ************ //

    event NewTreasury(address indexed newTreasury);

    event NewSigner(address indexed newSigner);

    event Payed(
        uint256 indexed paymentType,
        address payer,
        address paymentToken,
        uint256 amount,
        uint256 nonce
    );

    event StakePositionUpdate(
        address indexed staker,
        bytes32 indexed assetId,
        uint256 transactionNonce,
        uint256 newUserStakedAmount,
        uint256 newTotalStakedAmount,
        uint256 txIndex,
        uint256 timestamp,
        uint256 newUnstakeTimestamp,
        uint256[] erc721TokenIds,
        bool liquidated
    );

    event RewardExecuted(
        address indexed from,
        uint256 indexed nonce,
        address rewardToken,
        uint256 rewardAmount,
        uint256 erc721TokenId,
        uint256[] erc721TokenIds,
        bool isWithdrawTx
    );

    event NonceProcessed(address indexed addr, uint256 amount, uint256 nonce);

    // ************ VARIABLES ************ //
    mapping(address => bool) internal _paymentContractStatus;
    mapping(address => bool) internal _rewardsContractStatus;
    mapping(address => bool) internal _whitelist;
    address internal _rewardHolderContract;
    address internal _stakingPoolContract;
    address internal _treasury;
    address internal _signer;
    address internal _weth;

    // ************ CONSTRUCTOR ************ //

    constructor(address treasury_, address signer_, address weth_) {
        _treasury = treasury_;
        _signer = signer_;
        _weth = weth_;
    }

    // ************ VIEW FUNCTIONS ************ //

    function stakingPoolContract() external view returns (address) {
        return _stakingPoolContract;
    }

    function whitelisted(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function rewardsHolderContract() external view returns (address) {
        return _rewardHolderContract;
    }

    function paymentContractStatus(
        address paymentContract
    ) external view returns (bool) {
        return _paymentContractStatus[paymentContract];
    }

    function rewardsContractStatus(
        address rewardsContract
    ) external view returns (bool) {
        return _rewardsContractStatus[rewardsContract];
    }

    function treasury() external view returns (address) {
        return _treasury;
    }

    function signer() external view returns (address) {
        return _signer;
    }

    function WETH() external view returns (address) {
        return _weth;
    }

    function admin() external view returns (address) {
        return owner();
    }

    // ************ ASSETS FUNCTIONS ************ //
    function getOrCreateAsset(
        bytes32 _assetId,
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) external returns (Asset memory) {
        return
            _getOrCreateAsset(
                _assetId,
                _assetAddress,
                _erc1155TokenId,
                _assetType
            );
    }

    function getAssetId(
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) external pure returns (bytes32) {
        return _calculateAssetId(_assetAddress, _erc1155TokenId, _assetType);
    }

    function getAssetById(
        bytes32 _assetId
    ) external view returns (Asset memory) {
        return _assets[_assetId];
    }

    function assets(
        bytes32 _assetId
    ) external view returns (Asset memory asset) {
        return _assets[_assetId];
    }

    // ************ STAKING FUNCTIONS ************ //

    function stakePositionUpdate(
        address staker,
        bytes32 assetId,
        uint256 transactionNonce,
        uint256 newUserStakedAmount,
        uint256 newTotalStakedAmount,
        uint256 transactionIndex,
        uint256 timestamp,
        uint256 unstakeTimestamp,
        uint256[] memory erc721TokenIds,
        bool liquidated
    ) external {
        require(msg.sender == _stakingPoolContract);
        emit StakePositionUpdate(
            staker,
            assetId,
            transactionNonce,
            newUserStakedAmount,
            newTotalStakedAmount,
            transactionIndex,
            timestamp,
            unstakeTimestamp,
            erc721TokenIds,
            liquidated
        );
    }

    // ************ PAYMENT FUNCTIONS ************ //

    function pay(
        address payer,
        uint256 paymentType,
        address paymentToken,
        uint256 amount,
        uint256 nonce
    ) external {
        require(
            _paymentContractStatus[msg.sender],
            "ESM: Only Payment Contracts"
        );
        emit Payed(paymentType, payer, paymentToken, amount, nonce);
    }

    // ************ REWARD FUNCTIONS ************ //
    function execReward(
        address from,
        uint256 nonce,
        address rewardToken,
        uint256 rewardAmount,
        uint256 erc1155TokenId,
        uint256[] memory erc721TokenIds,
        bool isWithdrawTx
    ) external {
        require(
            msg.sender == _rewardHolderContract ||
                _rewardsContractStatus[msg.sender],
            "ESM: Only Reward Contracts"
        );
        emit RewardExecuted(
            from,
            nonce,
            rewardToken,
            rewardAmount,
            erc1155TokenId,
            erc721TokenIds,
            isWithdrawTx
        );
    }

    // ************ ADMIN FUNCTIONS ************ //
    function setStakingPool(
        address stakingPool
    ) external noAddressZero(stakingPool) onlyOwner {
        require(
            _stakingPoolContract == address(0),
            "ESM: Staking Pool Already Set"
        );
        _stakingPoolContract = stakingPool;
    }

    function setTreasury(
        address newTreasury
    ) external noAddressZero(newTreasury) onlyOwner {
        _treasury = newTreasury;
        emit NewTreasury(newTreasury);
    }

    function setSigner(
        address newSigner
    ) external noAddressZero(newSigner) onlyOwner {
        _signer = newSigner;
        emit NewSigner(newSigner);
    }

    function setPaymentContractStatus(
        address paymentContract,
        bool status
    ) external onlyOwner {
        _paymentContractStatus[paymentContract] = status;
    }

    function setRewardHolderContract(
        address rewardHolderContractAddress
    ) external noAddressZero(rewardHolderContractAddress) onlyOwner {
        _rewardHolderContract = rewardHolderContractAddress;
    }

    function setRewardContractStatus(
        address rewardContract,
        bool status
    ) external onlyOwner {
        _rewardsContractStatus[rewardContract] = status;
    }

    function setWhitelist(address addr, bool status) external onlyOwner {
        _whitelist[addr] = status;
    }

    // ************ OTHER FUNCTIONS ************ //
    function emitNonce(address addr, uint256 amount, uint256 nonce) external {
        require(_whitelist[msg.sender], "ESM: Not Whitelisted");
        emit NonceProcessed(addr, amount, nonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Asset, AssetType} from "./EarnAssetTypes.sol";

interface IEarnStakingManager {
    function treasury() external view returns (address);

    function signer() external view returns (address);

    function rewardsHolderContract() external view returns (address);

    function stakePositionUpdate(
        address staker,
        bytes32 assetId,
        uint256 transactionNonce,
        uint256 newUserStakedAmount,
        uint256 newTotalStakedAmount,
        uint256 transactionIndex,
        uint256 timestamp,
        uint256 unstakeTimestamp,
        uint256[] memory erc721TokenIds,
        bool liquidated
    ) external;

    function pay(
        address payer,
        uint256 paymentType,
        address paymentToken,
        uint256 amount,
        uint256 nonce
    ) external;

    function execReward(
        address from,
        uint256 nonce,
        address rewardToken,
        uint256 rewardAmount,
        uint256 erc1155TokenId,
        uint256[] memory erc721TokenIds,
        bool isWithdrawTx
    ) external;

    function WETH() external view returns (address);

    function getOrCreateAsset(
        bytes32 _assetId,
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) external returns (Asset memory);

    function getAssetById(bytes32 _assetId)
        external
        view
    returns (Asset memory);

    function getAssetId(
        address _assetAddress,
        uint256 _erc1155TokenId,
        AssetType _assetType
    ) external pure returns (bytes32);

    function assets(bytes32 _assetId)
        external
        view
    returns (Asset memory asset);

    function admin() external view returns (address);

    function emitNonce(address addr, uint256 amount, uint256 nonce) external;
}