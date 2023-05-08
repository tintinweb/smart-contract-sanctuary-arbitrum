/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// Sources flattened with hardhat v2.13.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IERC20.sol

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}


// File contracts/interfaces/IFeeCollector.sol

pragma solidity 0.8.13;

interface IFeeCollector {
    function transferERC20(address token, address to, uint256 amount) external;
    function transferETH(address payable _to) external payable;
}


// File contracts/interfaces/IVotingEscrow.sol

pragma solidity 0.8.13;

interface IVotingEscrow {

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint256 ts;
        uint256 blk; // block
    }

    function token() external view returns (address);
    function team() external returns (address);
    function epoch() external view returns (uint);
    function point_history(uint loc) external view returns (Point memory);
    function user_point_history(uint tokenId, uint loc) external view returns (Point memory);
    function user_point_epoch(uint tokenId) external view returns (uint);

    function ownerOf(uint) external view returns (address);
    function isApprovedOrOwner(address, uint) external view returns (bool);
    function transferFrom(address, address, uint) external;

    function voting(uint tokenId) external;
    function abstain(uint tokenId) external;
    function attach(uint tokenId) external;
    function detach(uint tokenId) external;

    function checkpoint() external;
    function deposit_for(uint tokenId, uint value) external;
    function create_lock_for(uint, uint, address) external returns (uint);

    function balanceOfNFT(uint) external view returns (uint);
    function balanceOfNFTAt(uint, uint) external view returns (uint);
    function totalSupply() external view returns (uint);
    function totalSupplyAtT(uint t) external view returns (uint);
}


// File contracts/RewardsDistributor.sol

pragma solidity 0.8.13;




contract RewardsDistributor is Ownable {
    uint constant WEEK = 7 * 86400;
    
    // connected contracts
    address public feeCollector;
    address public ve;
    address public forge;
    address public usdc;

    // team share
    address public team;
    uint public teamShare; // out of 10000

    // storing each epoch data
    uint[] public epoch;
    mapping(uint => uint) public epochVeSupply;
    mapping(uint => uint) public epochForgeReward;
    mapping(uint => uint) public epochUsdcReward;

    // storing user last claim
    mapping(uint => uint) lastClaim;

    constructor(address _votingEscrow, address _feeCollector, address _usdc, address _team, uint _teamShare) {
        team = _team;
        teamShare = _teamShare;
        usdc = _usdc;
        feeCollector = _feeCollector;
        ve = _votingEscrow;
        forge = IVotingEscrow(ve).token();
        require(IERC20(forge).approve(ve, type(uint).max));
    }

    function setTeam(address _team) onlyOwner public {
        team = _team;
    }

    function setTeamShare(uint _teamShare) onlyOwner public {
        teamShare = _teamShare;
    }

    function epochId() external view returns (uint) {
        return epoch.length;
    }

    function nextEpoch() external {
        uint epochTs = block.timestamp;
        uint veSupply = IVotingEscrow(ve).totalSupply();
        require(veSupply > 0, "Need at least 1 user to distribute fees");
        if (epoch.length > 0) {
            require(block.timestamp >= epoch[epoch.length-1] + WEEK, "Cannot go to next epoch yet");
        }
        
        uint id = epoch.length;
        epoch.push(epochTs);

        // save total ve supply
        epochVeSupply[id] = veSupply;

        // colleting forge fees from fee collector
        epochForgeReward[id] = IERC20(forge).balanceOf(feeCollector);
        uint forgeForTeam = epochForgeReward[id] * teamShare / 10000;
        epochForgeReward[id] -= forgeForTeam;
        IFeeCollector(feeCollector).transferERC20(forge, team, forgeForTeam);
        IFeeCollector(feeCollector).transferERC20(forge, address(this), epochForgeReward[id]);
        
        // collecting oven fees (USDC) from fee collector
        epochUsdcReward[id] = IERC20(usdc).balanceOf(feeCollector);
        uint usdcForTeam = epochUsdcReward[id] * teamShare / 10000;
        epochUsdcReward[id] -= usdcForTeam;
        IFeeCollector(feeCollector).transferERC20(usdc, team, usdcForTeam);
        IFeeCollector(feeCollector).transferERC20(usdc, address(this), epochUsdcReward[id]);
    }

    function claimable(uint tokenId) public view returns (uint rewardForge, uint rewardUsdc) {
        rewardForge = 0;
        rewardUsdc = 0;
        uint i = lastClaim[tokenId];
        IVotingEscrow.Point memory pt = IVotingEscrow(ve).user_point_history(tokenId, 1);
        while (i < epoch.length) {
            if (pt.ts < epoch[i]) {
                rewardForge += (epochForgeReward[i] * IVotingEscrow(ve).balanceOfNFTAt(tokenId, epoch[i]) / epochVeSupply[i]);
                rewardUsdc += (epochUsdcReward[i] * IVotingEscrow(ve).balanceOfNFTAt(tokenId, epoch[i]) / epochVeSupply[i]);
            }
            i++;
        }
        return (rewardForge, rewardUsdc);
    }

    function claim(uint tokenId) public {
        require(IVotingEscrow(ve).ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        (uint rewardForge, uint rewardUsdc) = claimable(tokenId);
        require(rewardForge > 0 || rewardUsdc > 0, "Nothing to claim");
        IVotingEscrow(ve).deposit_for(tokenId, rewardForge);
        IERC20(usdc).transfer(IVotingEscrow(ve).ownerOf(tokenId), rewardUsdc);
        lastClaim[tokenId] = epoch.length;
    }
}