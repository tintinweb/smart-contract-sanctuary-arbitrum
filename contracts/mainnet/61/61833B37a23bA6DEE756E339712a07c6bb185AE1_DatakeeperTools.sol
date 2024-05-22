// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;
/*
    Created by DeNet
*/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./protocol_interface.sol";


struct Datakeeper {
    uint256 id;
    address owner;
    uint8[4] ipAddress;
    uint16 port;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 updatesCount;
    uint256 rank;
}

struct DenetState {
    Block[128]   lastBlocks;
    uint256 minStorageSize;
    uint256 withdrawRatio;
    uint256 difficulty;
    uint256 systemReward;
}

struct Block {
    uint256 height;
    bytes32 hash;
}

contract DatakeeperTools {
    function networkState(address _posAddress) public view returns (DenetState memory) {
        IPoS pos = IPoS(_posAddress);
        IPayments payments = IPayments(pos.paymentsAddress());

        Block[128] memory blocks;
        for (uint256 i = 0; i < 128; i++) {
            blocks[i] = Block({
                height: block.number - i,
                hash: blockhash(block.number - i)
            });
        }        
        return DenetState({
            lastBlocks: blocks,
            minStorageSize: pos.min_storage_require(),
            withdrawRatio: payments.getWidthdrawtReturns(1e18),
            difficulty: pos.getDifficulty(),
            systemReward: calculateSystemReward(payments)
        });
    }

    function calculateSystemReward(IPayments payments) internal view returns (uint256) {
        uint16 period = payments.currentMinTimeToInflation();
        uint256 lastProof = payments.lastProofTime();
        if (block.timestamp - lastProof < period) {
            return 0;
        }
        return payments.getSystemReward();
    }
    
    struct UserRewardInfo {
        uint256 balance;
        uint256 lastProofAt;
    }

    function getRewardInfo(address[] calldata addresses, address _posAddress) public view returns (UserRewardInfo[] memory) {
        IPoS pos = IPoS(_posAddress);
        IUserStorage ustorage = IUserStorage(pos.userStorageAddress());
        IERC20 storageToken  = IERC20(pos.paymentsAddress());
        
        uint256 len = addresses.length;
        UserRewardInfo[] memory result = new UserRewardInfo[](len);

        for (uint256 i = 0; i < len; i++) {
            result[i] = UserRewardInfo({
                balance: storageToken.balanceOf(addresses[i]),
                lastProofAt: block.timestamp - ustorage.getPeriodFromLastProof(addresses[i])
            });
        }
        return result;
    }

    function getDatakeepersRow(address nodenftAddress,uint256 _startId, uint256 _endId) public view returns (Datakeeper[] memory) {
        require(_startId <= _endId, "Invalid range");

        uint256 length =  _endId - _startId + 1;
        Datakeeper[] memory datakeepers = new Datakeeper[](length);

        INodeNFT nfts = INodeNFT(nodenftAddress);

        for (uint256 i = 0; i < length; i++) {
            uint256 id = _startId + i;
            DeNetNode memory info = nfts.nodeInfo(id);
            datakeepers[i] = Datakeeper(
                id,
                nfts.ownerOf(id),
                info.ipAddress,
                info.port,
                info.createdAt,
                info.updatedAt,
                info.updatesCount,
                info.rank
            );            
        }

        return datakeepers;
    }
    function availableIds(address nodenftAddress) public view returns (uint256, uint256[] memory) {
        INodeNFT nodenft = INodeNFT(nodenftAddress);
        uint256 totalSupply = nodenft.totalSupply();
        uint256 maxInactive = nodenft.maxAlivePeriod();
        uint count = 0;
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (nodenft.getLastUpdateByAddress(nodenft.ownerOf(i)) < block.timestamp - maxInactive ||
                !nodenft.isAddressHaveGastokenToBeNode(nodenft.ownerOf(i), i)) {
                count++; 
            }
        }

        uint256[] memory ids = new uint256[](count);
        uint256 index = 0;
        for (uint256 j = 1; j <= totalSupply; j++) {
            if (nodenft.getLastUpdateByAddress(nodenft.ownerOf(j)) < block.timestamp - maxInactive ||
                !nodenft.isAddressHaveGastokenToBeNode(nodenft.ownerOf(j), j)) {
                ids[index] = j;
                index++;
            }
        }

        return (totalSupply + 1, ids);
    }    
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;
/*
    Created by DeNet
*/

struct DeNetNode {
    uint8[4] ipAddress;
    uint16 port;
    uint256 createdAt;
    uint256 updatedAt;
    uint256 updatesCount;
    uint256 rank;
}

interface INodeNFT {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function nodeInfo(uint256 tokenId) external view returns (DeNetNode memory);
    function getNodeIDByAddress(address _node) external view returns (uint256);
    function getLastUpdateByAddress(address _user) external view returns(uint256);
    function maxAlivePeriod() external view returns (uint256);
    function isAddressHaveGastokenToBeNode(address nodeAddress, uint nodeId) external view returns (bool);
}

interface IPayments {
    function DECIMALS_18() external view returns (uint256);
    function DEFAULT_FEE_COLLECTOR() external view returns (address);
    function DIV_FEE() external view returns (uint16);
    function DeNetDAOWallet() external view returns (address);
    function MAX_BLOCKS_AFTER_PROOF() external view returns (uint256);
    function NETWORK_ID() external view returns (uint256);
    function PAIR_TOKEN_START_ADDRESS() external view returns (address);
    function START_DEPOSIT_LIMIT() external view returns (uint256);
    function START_MINT_PERCENT() external view returns (uint16);
    function START_PAYIN_FEE() external view returns (uint16);
    function START_PAYOUT_FEE() external view returns (uint16);
    function START_UNBURN_PERCENT() external view returns (uint16);
    function STORAGE_100GB_IN_MB() external view returns (uint256);
    function STORAGE_10GB_IN_MB() external view returns (uint256);
    function STORAGE_1TB_IN_MB() external view returns (uint256);
    function TIME_1D() external view returns (uint256);
    function TIME_1Y() external view returns (uint256);
    function TIME_30D() external view returns (uint256);
    function TIME_7D() external view returns (uint256);
    function _balances(address) external view returns (uint256);
    function _name() external view returns (string memory);
    function _symbol() external view returns (string memory);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function calcPayoutFee(uint256) external view returns (uint256);
    function changeFeeLimit(uint256) external;
    function changeInflationRate(uint16) external;
    function changeMinTimeToInflation(uint16) external;
    function changeMintPercent(uint16) external;
    function changePayinFee(uint16) external;
    function changePayoutFee(uint16) external;
    function changePoS(address) external;
    function changeRecipientFee(address) external;
    function changeUnburnPercent(uint16) external;
    function closeDeposit() external;
    function contractStorageAddress() external view returns (address);
    function currentDivFee() external pure returns (uint16);
    function currentFeeLimit() external view returns (uint256);
    function currentInflationRate() external view returns (uint16);
    function currentMinTimeToInflation() external view returns (uint16);
    function currentMintPercent() external view returns (uint16);
    function currentPayinFee() external view returns (uint16);
    function currentPayoutFee() external view returns (uint16);
    function currentUnburnPercent() external view returns (uint16);
    function daoContractAddress() external view returns (address);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address, uint256) external returns (bool);
    function depositToLocal(address, uint256) external;
    function fee_collected() external view returns (uint256);
    function fee_limit() external view returns (uint256);
    function feelessBalance(address) external view returns (uint256);
    function gasTokenAddress() external view returns (address);
    function gasTokenMined() external view returns (address);
    function getBalance(address) external view returns (uint256);
    function getSystemReward() external view returns (uint256);
    function getWidthdrawtReturns(uint256) external view returns (uint256);
    function increaseAllowance(address, uint256) external returns (bool);
    function inflationRate() external view returns (uint16);
    function lastProofTime() external view returns (uint256);
    function localTransferFrom(address, address, uint256) external;
    function makeThistokenOld(string memory, string memory) external;
    function minTimeToInflation() external view returns (uint16);
    function minedTokenAddress() external view returns (address);
    function mint_percent() external view returns (uint16);
    function name() external view returns (string memory);
    function owner() external view returns (address);
    function pairTokenAddress() external view returns (address);
    function pairTokenBalance() external view returns (uint256);
    function payin_fee() external view returns (uint16);
    function payout_fee() external view returns (uint16);
    function proofOfStorageAddress() external view returns (address);
    function recipient_fee() external view returns (address);
    function renounceOwnership() external;
    function storagePairTokenAddress() external view returns (address);
    function symbol() external view returns (string memory);
    function sync() external;
    function toFeelessPayout(uint256) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function transferOwnership(address) external;
    function unburn_percent() external view returns (uint16);
}

interface IUserStorage {
    function getUserRootHash(address _user_address) external view returns (bytes32, uint256);
    function getPeriodFromLastProof(address userAddress) external view returns(uint256);
}

interface IPoS {
    event MinStorageSizeUpdate(uint256 _newMinStorageSize);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TargetProofTimeUpdate(uint256 _newTargetProofTime);
    event UpdateDifficulty(uint256 newDifficulty);
    event WrongError(bytes32 wrongHash);

    function DECIMALS_18() external view returns (uint256);
    function DEFAULT_FEE_COLLECTOR() external view returns (address);
    function DIV_FEE() external view returns (uint16);
    function MAX_BLOCKS_AFTER_PROOF() external view returns (uint256);
    function NETWORK_ID() external view returns (uint256);
    function PAIR_TOKEN_START_ADDRESS() external view returns (address);
    function START_DEPOSIT_LIMIT() external view returns (uint256);
    function START_MINT_PERCENT() external view returns (uint16);
    function START_PAYIN_FEE() external view returns (uint16);
    function START_PAYOUT_FEE() external view returns (uint16);
    function START_UNBURN_PERCENT() external view returns (uint16);
    function STORAGE_100GB_IN_MB() external view returns (uint256);
    function STORAGE_10GB_IN_MB() external view returns (uint256);
    function STORAGE_1TB_IN_MB() external view returns (uint256);
    function TIME_1D() external view returns (uint256);
    function TIME_1Y() external view returns (uint256);
    function TIME_30D() external view returns (uint256);
    function TIME_7D() external view returns (uint256);
    function closeDeposit() external;
    function contractStorageAddress() external view returns (address);
    function daoContractAddress() external view returns (address);
    function getBlockHash(uint32 _n) external view returns (bytes32);
    function getBlockNumber() external view returns (uint32);
    function getDifficulty() external view returns (uint256);
    function getProof(bytes calldata _file, address _sender, uint256 _blockNumber) external view returns (bytes memory, bytes32);
    function getUpgradingDifficulty() external view returns (uint256);
    function getUserRewardInfo(address _user, uint256 _user_storage_size) external view returns (uint256, uint256);
    function getUserRootHash(address _user) external view returns (bytes32, uint256);
    function initTrafficPayment(address _user_address, uint256 _amount) external;
    function isMatchDifficulty(uint256 baseDiff, uint256 _proof, uint256 _targetDifficulty) external pure returns (bool);
    function isValidMerkleTreeProof(bytes32 rootHash, bytes32[] calldata proof) external pure returns (bool);
    function makeDeposit(uint256 _amount) external;
    function min_storage_require() external view returns (uint256);
    function node_nft_address() external view returns (address);
    function owner() external view returns (address);
    function paymentsAddress() external view returns (address);
    function renounceOwnership() external;
    function sendProof(address _user_address, uint32 _block_number, bytes32 _user_root_hash, uint64 _user_storage_size, uint64 _user_root_hash_nonce, bytes calldata _user_signature, bytes calldata _file, bytes32[] calldata merkleProof) external;
    function sendProofFrom(address _node_address, address _user_address, uint32 _block_number, bytes32 _user_root_hash, uint64 _user_storage_size, uint64 _user_root_hash_nonce, bytes calldata _user_signature, bytes calldata _file, bytes32[] calldata merkleProof) external;
    function setMinStorage(uint256 _size) external;
    function setTargetProofTime(uint256 _newTargetProofTime) external;
    function sync() external;
    function targetProofTime() external view returns (uint256);
    function trafficManagerContractAddress() external view returns (address);
    function transferOwnership(address newOwner) external;
    function updateBaseDifficulty(uint256 _new_difficulty) external;
    function userStorageAddress() external view returns (address);
    function verifyFileProof(address _sender, bytes calldata _file, uint32 _block_number, uint256 _time_passed) external view returns (bool);
}