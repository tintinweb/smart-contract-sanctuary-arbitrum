//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Ownable2Step } from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import { Group, GroupUpdate, Contract, ContractUpdate, Stake, Lock } from "../Structs.sol";
import { IERC20 } from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import { IPepeFeeDistributorV2 } from "../interfaces/IPepeFeeDistributorV2.sol";
import { IPepeStaking2 } from "../interfaces/IPepeStaking2.sol";
import { IPepeLockUp2 } from "../interfaces/IPepeLockUp2.sol";
import { SafeERC20 } from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

import { Math } from "openzeppelin-contracts/contracts/utils/math/Math.sol";

contract PepeFeeDistributorV2 is IPepeFeeDistributorV2, Ownable2Step {
    using SafeERC20 for IERC20;
    using Math for uint256;
    using Math for int256;

    uint16 public constant BPS_DIVISOR = 10_000; ///@dev basis points divisor. Also acts as the total staked for all groups and all contracts per group.
    IERC20 public immutable usdcToken;

    address public pepeStaking; ///@dev pepeStaking contract address.
    address public pepeLockUp; ///@dev pepeLockUp contract address.
    address public pepePlsAccumulator; ///@dev pepePlsAccumulator contract address.

    uint256 public accumulatedUsdcPerGroup; ///@dev usdc accumulated per total group stake (10_000).
    uint256 public lastBalance; ///@dev last balance of the contract.
    uint48 public lastAllocatedGroupsTimestamp; ///@dev last time the rewards per groups were updated.
    uint48 public lastAllocatedContractsTimestamp; ///@dev last time the rewards per contracts were updated.
    uint8 public groupCount; ///@dev total number of groups, also acts as Id.
    mapping(uint8 groupId => Group) public groups; ///@dev groups.
    mapping(uint8 groupId => Contract[]) public contracts; ///@dev contracts per group.
    mapping(uint8 groupId => mapping(address contractAddress => uint256 index)) public contractIndex; ///@dev index of the contract in the contracts array.

    event ContractAdded(uint8 indexed groupId, string name, address indexed contractAddress, uint16 feeShare);
    event ContractRemoved(uint8 indexed groupId, string name, address indexed contractAddress, uint16 feeShare);
    event GroupAdded(uint8 indexed groupId, string indexed groupName, uint256 indexed newShare);
    event GroupRemoved(uint8 indexed groupId, string indexed groupName, uint16 indexed previousShare);
    event GroupSharesUpdated(GroupUpdate[] indexed groupUpdates);
    event ContractSharesUpdated(uint8 indexed groupId, ContractUpdate[] indexed contractUpdates);
    event UpdatedGroupsAllocation(uint256 indexed accumulatedUsdcPerGroup);
    event UpdatedContracts(address indexed staking, address indexed lockUp, address indexed plsAccumulator);
    event UpdatedContractsAllocation(
        uint8 indexed groupId,
        string groupName,
        uint256 usdcDistributable,
        uint256 accumulatedUsdcPerContract,
        uint48 timestamp
    );
    event UsdcAllocatedToGroup(uint8 indexed groupId, uint256 indexed amountAllocated);
    event UsdcTransferredToContract(
        uint8 indexed groupId,
        address indexed contractAddress,
        uint256 indexed amountAllocated
    );

    constructor(address _usdcToken, address staking_, address lockUp_, address plsAccumulator_) {
        usdcToken = IERC20(_usdcToken);

        pepeStaking = staking_;
        pepeLockUp = lockUp_;
        pepePlsAccumulator = plsAccumulator_;

        //initialize groups
        Contract memory stakingContracts = Contract({
            totalUsdcReceived: 0,
            contractShareDebt: 0,
            contractAddress: staking_,
            feeShare: BPS_DIVISOR,
            groupId: 1
        });

        Contract memory lockUpContracts = Contract({
            totalUsdcReceived: 0,
            contractShareDebt: 0,
            contractAddress: lockUp_,
            feeShare: BPS_DIVISOR,
            groupId: 2
        });

        Contract memory plsAccumulatorContracts = Contract({
            totalUsdcReceived: 0,
            contractShareDebt: 0,
            contractAddress: plsAccumulator_,
            feeShare: BPS_DIVISOR,
            groupId: 3
        });

        contracts[1].push(stakingContracts);
        contracts[2].push(lockUpContracts);
        contracts[3].push(plsAccumulatorContracts);
        contractIndex[1][staking_] = 0;
        contractIndex[2][lockUp_] = 0;
        contractIndex[3][plsAccumulator_] = 0;

        groups[1] = Group({
            totalUsdcDistributed: 0,
            accumulatedUsdcPerContract: 0,
            pendingGroupUsdc: 0,
            lastGroupBalance: 0,
            shareDebt: 0,
            name: "STAKING",
            feeShare: 1_000,
            groupId: 1
        });

        groups[2] = Group({
            totalUsdcDistributed: 0,
            accumulatedUsdcPerContract: 0,
            pendingGroupUsdc: 0,
            lastGroupBalance: 0,
            shareDebt: 0,
            name: "LOCKUP",
            feeShare: 3_000,
            groupId: 2
        });

        groups[3] = Group({
            totalUsdcDistributed: 0,
            accumulatedUsdcPerContract: 0,
            pendingGroupUsdc: 0,
            lastGroupBalance: 0,
            shareDebt: 0,
            name: "PLSACCUMULATOR",
            feeShare: 6_000,
            groupId: 3
        });

        groupCount = 3;
    }

    ///@dev updates accumulated usdc group. I.e usdc per 10_000 (total stake of groups).
    function updateGroupAllocations() public override {
        if (uint48(block.timestamp) > lastAllocatedGroupsTimestamp) {
            uint256 contractBalance = usdcToken.balanceOf(address(this));
            uint256 diff = contractBalance - lastBalance;
            if (diff != 0) {
                accumulatedUsdcPerGroup += diff / BPS_DIVISOR;
                lastBalance = contractBalance;
                emit UpdatedGroupsAllocation(accumulatedUsdcPerGroup);
            }
            lastAllocatedGroupsTimestamp = uint48(block.timestamp);
        }
    }

    ///@dev updates accumulated usdc per contract per group. I.e usdc per 10_000 (total stake of contracts per group).
    function updateContractAllocations() public override {
        allocateUsdcToAllGroups();

        if (uint48(block.timestamp) > lastAllocatedContractsTimestamp) {
            uint8 i = 1;
            for (; i <= groupCount; ) {
                Group memory group = groups[i];
                Contract[] memory contractDetails = contracts[i];

                if (group.pendingGroupUsdc != 0 && contractDetails.length != 0) {
                    uint256 diff = group.pendingGroupUsdc - group.lastGroupBalance;

                    if (diff != 0) {
                        groups[i].accumulatedUsdcPerContract += diff / BPS_DIVISOR;
                        groups[i].lastGroupBalance = group.pendingGroupUsdc;

                        emit UpdatedContractsAllocation(
                            i,
                            group.name,
                            group.pendingGroupUsdc,
                            diff / BPS_DIVISOR,
                            uint48(block.timestamp)
                        );
                    }
                }

                unchecked {
                    ++i;
                }
            }

            lastAllocatedContractsTimestamp = uint48(block.timestamp);
        }
    }

    function allocateStake() public override returns (uint256) {
        require(msg.sender == pepeStaking, "Only pepeStaking");

        return transferUsdcToContract(1, pepeStaking);
    }

    function allocateLock() public override returns (uint256) {
        require(msg.sender == pepeLockUp, "Only lockup");

        return transferUsdcToContract(2, pepeLockUp);
    }

    function allocatePlsAccumulation() public override returns (uint256) {
        require(msg.sender == pepePlsAccumulator, "Only pepePlsAccumulator");

        return transferUsdcToContract(3, pepePlsAccumulator);
    }

    ///@dev updates pending usdc of a group (amount sharable by contracts in that group).
    ///@param groupId id of the group to update.
    function allocateUsdcToGroup(uint8 groupId) public override {
        updateGroupAllocations();
        Group memory groupDetails = groups[groupId];
        int256 accumulatedGroupUsdc = int256(groupDetails.feeShare * accumulatedUsdcPerGroup);
        uint256 pendingGroupUsdc = uint256(accumulatedGroupUsdc - groupDetails.shareDebt);

        if (pendingGroupUsdc != 0) {
            groups[groupId].shareDebt = accumulatedGroupUsdc;

            groups[groupId].pendingGroupUsdc += pendingGroupUsdc;

            emit UsdcAllocatedToGroup(groupId, pendingGroupUsdc);
        }
    }

    ///@dev transfers usdc to a contract in a group.
    ///@param groupId id of the group to update.
    ///@param contractAddress address of the contract to transfer usdc to.
    function transferUsdcToContract(uint8 groupId, address contractAddress) public override returns (uint256) {
        updateContractAllocations();

        if (contracts[groupId].length == 0) return 0;

        Group memory groupDetails = groups[groupId];
        uint256 contractIndex_ = contractIndex[groupId][contractAddress];
        Contract memory contractDetails = contracts[groupId][contractIndex_];

        if (contractDetails.contractAddress != contractAddress) return 0;

        int256 accumulatedContractUsdc = int256(contractDetails.feeShare * groupDetails.accumulatedUsdcPerContract);
        uint256 pendingContractUsdc = uint256(accumulatedContractUsdc - contractDetails.contractShareDebt);

        if (pendingContractUsdc != 0) {
            contracts[groupId][contractIndex_].contractShareDebt = accumulatedContractUsdc;
            contracts[groupId][contractIndex_].totalUsdcReceived += pendingContractUsdc;

            groups[groupId].totalUsdcDistributed += pendingContractUsdc;
            groups[groupId].pendingGroupUsdc -= pendingContractUsdc;
            groups[groupId].lastGroupBalance -= pendingContractUsdc;

            lastBalance -= pendingContractUsdc;

            require(usdcToken.transfer(contractAddress, pendingContractUsdc), "transfer failed");
            emit UsdcTransferredToContract(groupId, contractAddress, pendingContractUsdc);
        }
        return pendingContractUsdc;
    }

    ///@dev updates pending usdc for all groupa.
    function allocateUsdcToAllGroups() public override {
        uint8 i = 1;
        for (; i <= groupCount; ) {
            allocateUsdcToGroup(i);
            unchecked {
                ++i;
            }
        }
    }

    ///@dev transfers usdc to all contracts in all groups.
    function transferUsdcToAllContracts() public override {
        uint8 i = 1; ///@notice updated

        for (; i <= groupCount; ) {
            transferUsdcToContractsByGroupId(i);

            unchecked {
                ++i;
            }
        }
    }

    ///@dev transfers usdc to all contracts in a group.
    ///@param groupId id in question.
    function transferUsdcToContractsByGroupId(uint8 groupId) public override {
        require(contracts[groupId].length != 0, "TRANSFER: no contracts");

        allocateUsdcToGroup(groupId);
        uint256 i;
        Contract[] memory contractDetails = contracts[groupId];
        uint256 contractCount = contractDetails.length;

        for (; i < contractCount; ) {
            transferUsdcToContract(groupId, contractDetails[i].contractAddress);

            unchecked {
                ++i;
            }
        }
    }

    ///@param update array of GroupUpdate struct to update the share of the existing groups.
    ///@param name name of the new group.
    ///@param groupShare share of the new group.
    ///@param contractAddress address of the contract to be added to the new group.
    ///@param contractShare share of the contract to be added to the new group.
    function addGroup(
        GroupUpdate[] calldata update,
        string calldata name,
        uint16 groupShare,
        address contractAddress,
        uint16 contractShare
    ) external override onlyOwner {
        require(groupShare != 0 && groupShare <= BPS_DIVISOR, "invalid groupShare");
        require(bytes(name).length != 0, "invalid name");

        uint8 updateLength = uint8(update.length);
        require(updateLength == groupCount, "invalid update length");

        updateGroupAllocations();

        uint16 newTotalShare;
        uint8 i;
        for (; i < updateLength; ) {
            GroupUpdate memory currentUpdate = update[i];
            newTotalShare += uint16(update[i].newShare);

            require(currentUpdate.groupId != 0 && currentUpdate.groupId <= groupCount, "invalid groupId");
            require(currentUpdate.newShare != 0, "invalid groupShare");

            uint16 existingShare = groups[currentUpdate.groupId].feeShare;
            if (existingShare != currentUpdate.newShare) {
                groups[currentUpdate.groupId].feeShare = currentUpdate.newShare;
                groups[currentUpdate.groupId].shareDebt += int256(currentUpdate.newShare * accumulatedUsdcPerGroup);
            }
            unchecked {
                ++i;
            }
        }
        require(newTotalShare + groupShare == BPS_DIVISOR, "invalid groupShare");

        uint8 newGroupId = ++groupCount;
        groups[newGroupId] = Group({
            totalUsdcDistributed: 0,
            accumulatedUsdcPerContract: 0,
            pendingGroupUsdc: 0,
            lastGroupBalance: 0,
            shareDebt: int256(groupShare * accumulatedUsdcPerGroup),
            name: name,
            feeShare: groupShare,
            groupId: newGroupId
        });

        emit GroupAdded(newGroupId, name, groupShare);

        ContractUpdate[] memory existingContractsUpdate = new ContractUpdate[](0);
        addContract(existingContractsUpdate, newGroupId, contractAddress, contractShare);
    }

    ///@param existingContractsUpdate array of ContractUpdate struct to update the share of the existing contracts.
    ///@param groupId id of the group to which the contract is to be added.
    ///@param contractAddress address of the contract to be added to the group.
    ///@param share share of the contract to be added to the group.
    function addContract(
        ContractUpdate[] memory existingContractsUpdate,
        uint8 groupId,
        address contractAddress,
        uint16 share
    ) public override onlyOwner {
        require(groupId != 0 || groupId <= groupCount, "invalid groupId");
        require(share != 0 && share <= BPS_DIVISOR, "invalid share");
        require(contractAddress != address(0), "invalid address");

        Contract[] memory currentContracts = contracts[groupId];

        require(existingContractsUpdate.length == currentContracts.length, "invalid contracts length");

        if (currentContracts.length == 0) {
            require(share == BPS_DIVISOR, "invalid share");
        }

        if (currentContracts.length != 0) transferUsdcToContractsByGroupId(groupId);

        uint256 lengthUpdate = existingContractsUpdate.length;
        uint16 newTotalShare;

        uint256 i;
        for (; i < lengthUpdate; ) {
            ContractUpdate memory currentUpdate = existingContractsUpdate[i];

            require(currentUpdate.contractAddress != address(0), "!invalid");
            require(currentUpdate.newShare != 0, "invalid share");
            require(currentContracts[i].contractAddress != contractAddress, "contract already added");

            newTotalShare += existingContractsUpdate[i].newShare;

            uint256 contractIndex_ = contractIndex[groupId][currentUpdate.contractAddress];
            if (contractIndex_ == 0) {
                require(
                    currentContracts[contractIndex_].contractAddress == currentUpdate.contractAddress,
                    "contract not found"
                );
            }

            uint16 existingShare = currentContracts[contractIndex_].feeShare;

            if (existingShare != currentUpdate.newShare) {
                contracts[groupId][contractIndex_].feeShare = currentUpdate.newShare;
                contracts[groupId][contractIndex_].contractShareDebt = int256(
                    currentUpdate.newShare * groups[groupId].accumulatedUsdcPerContract
                );
            }

            unchecked {
                ++i;
            }
        }
        require(newTotalShare + share == BPS_DIVISOR, "invalid share");

        contractIndex[groupId][contractAddress] = currentContracts.length;

        contracts[groupId].push(
            Contract({
                totalUsdcReceived: 0,
                contractShareDebt: int256(share * groups[groupId].accumulatedUsdcPerContract),
                contractAddress: contractAddress,
                feeShare: share,
                groupId: groupId
            })
        );
        emit ContractAdded(groupId, groups[groupId].name, contractAddress, share);
    }

    ///@param groupId id of the group to which the contract is to be removed.
    ///@param existingGroups array of GroupUpdate struct to update the share of the existing groups minus the group to be removed.
    function removeGroup(uint8 groupId, GroupUpdate[] memory existingGroups) public override onlyOwner {
        require(groupId != 0 && groupId <= groupCount, "invalid groupId");
        require(existingGroups.length == groupCount - 1, "invalid update length");

        Group memory group = groups[groupId];

        transferUsdcToContractsByGroupId(groupId);

        uint16 newTotalShare;
        uint256 lengthGroup = existingGroups.length;

        uint256 i;

        for (; i < lengthGroup; ) {
            require(existingGroups[i].groupId != 0 && existingGroups[i].groupId <= groupCount, "invalid groupId");
            require(existingGroups[i].newShare != 0, "invalid groupShare");

            newTotalShare += existingGroups[i].newShare;

            if (existingGroups[i].groupId != groupId) {
                groups[existingGroups[i].groupId].feeShare = existingGroups[i].newShare;
                groups[existingGroups[i].groupId].shareDebt = int256(
                    existingGroups[i].newShare * accumulatedUsdcPerGroup
                );
            }

            unchecked {
                ++i;
            }
        }
        require(newTotalShare == BPS_DIVISOR, "invalid groupShare");

        Contract[] memory groupContracts = contracts[groupId];
        uint256 lengthContracts = groupContracts.length;
        uint256 k;

        for (; k < lengthContracts; ) {
            delete contractIndex[groupId][groupContracts[k].contractAddress];
            unchecked {
                ++k;
            }
        }

        delete groups[groupId];
        delete contracts[groupId];
        --groupCount;

        emit GroupRemoved(groupId, group.name, group.feeShare);
    }

    ///@param groupId id of the group to which the contract is to be removed.
    ///@param contractAddress address of the contract to be removed from the group.
    ///@param existingContracts array of ContractUpdate struct to update the share of the existing contracts minus the contract to be removed.
    function removeContract(
        uint8 groupId,
        address contractAddress,
        ContractUpdate[] memory existingContracts
    ) public override onlyOwner {
        Contract[] memory groupContracts = contracts[groupId];

        require(groupContracts.length != 0, "no contracts");
        require(contractAddress != address(0), "!invalid");
        require(existingContracts.length == groupContracts.length - 1, "invalid update length");

        transferUsdcToContractsByGroupId(groupId);

        uint16 newTotalShare;
        uint256 contractsCount = groupContracts.length;
        uint256 i;
        uint256 updateLength = existingContracts.length;
        for (; i < updateLength; ) {
            require(existingContracts[i].contractAddress != address(0), "!invalid");
            require(existingContracts[i].newShare != 0, "invalid share");
            newTotalShare += existingContracts[i].newShare;

            uint256 contractIndex_ = contractIndex[groupId][existingContracts[i].contractAddress];

            if (contractIndex_ == 0) {
                require(
                    groupContracts[contractIndex_].contractAddress == existingContracts[i].contractAddress,
                    "contract not found"
                );
            }

            contracts[groupId][contractIndex_].feeShare = existingContracts[i].newShare;
            contracts[groupId][contractIndex_].contractShareDebt = int256(
                existingContracts[i].newShare * groups[groupId].accumulatedUsdcPerContract
            );

            unchecked {
                ++i;
            }
        }

        require(newTotalShare == BPS_DIVISOR, "invalid share");

        uint256 indexOfContractToRemove = contractIndex[groupId][contractAddress];
        Contract memory contract_ = groupContracts[indexOfContractToRemove];
        Contract memory lastContract = groupContracts[contractsCount - 1];

        contracts[groupId][indexOfContractToRemove] = lastContract;

        if (indexOfContractToRemove != contractsCount - 1) {
            contractIndex[groupId][lastContract.contractAddress] = indexOfContractToRemove;
        }

        contracts[groupId].pop();

        emit ContractRemoved(groupId, groups[groupId].name, contractAddress, contract_.feeShare);
    }

    ///@param updateGroups array of GroupUpdate struct to update the share of the existing groups.
    function updateGroupShares(GroupUpdate[] memory updateGroups) public override onlyOwner {
        ///allocate the usdc to the groups based on the share before.
        require(updateGroups.length == groupCount, "invalid update length");

        allocateUsdcToAllGroups();

        uint16 newTotalShare;
        uint256 lengthGroup = updateGroups.length;

        uint256 i;

        for (; i < lengthGroup; ) {
            require(updateGroups[i].groupId != 0 && updateGroups[i].groupId <= groupCount, "invalid groupId");
            require(updateGroups[i].newShare != 0, "invalid groupShare");

            newTotalShare += updateGroups[i].newShare;

            uint16 existingShare = groups[updateGroups[i].groupId].feeShare;

            if (existingShare != updateGroups[i].newShare) {
                groups[updateGroups[i].groupId].feeShare = updateGroups[i].newShare;
                groups[updateGroups[i].groupId].shareDebt = int256(updateGroups[i].newShare * accumulatedUsdcPerGroup);
            }

            unchecked {
                ++i;
            }
        }
        require(newTotalShare == BPS_DIVISOR, "invalid groupShare");

        emit GroupSharesUpdated(updateGroups);
    }

    ///@param groupId id of the group to which the contract is to be updated.
    ///@param existingContracts array of ContractUpdate struct to update the share of the existing contracts.
    function updateContractShares(uint8 groupId, ContractUpdate[] memory existingContracts) public override onlyOwner {
        Contract[] memory groupContracts = contracts[groupId];

        require(groupContracts.length != 0, "no contracts");
        require(existingContracts.length == groupContracts.length, "invalid update length");

        uint16 newTotalShare;
        uint256 contractsLength = groupContracts.length;
        uint256 j;

        for (; j < contractsLength; ) {
            transferUsdcToContract(groupId, groupContracts[j].contractAddress);

            unchecked {
                ++j;
            }
        }

        uint256 i;
        for (; i < contractsLength; ) {
            require(existingContracts[i].contractAddress != address(0), "!invalid");
            require(existingContracts[i].newShare != 0, "invalid share");

            newTotalShare += existingContracts[i].newShare;

            uint256 contractIndex_ = contractIndex[groupId][existingContracts[i].contractAddress];

            if (contractIndex_ == 0) {
                require(
                    groupContracts[contractIndex_].contractAddress == existingContracts[i].contractAddress,
                    "contract not found"
                );
            }

            uint16 existingShare = contracts[groupId][contractIndex_].feeShare;

            if (existingShare != existingContracts[i].newShare) {
                contracts[groupId][contractIndex_].feeShare = existingContracts[i].newShare;
                contracts[groupId][contractIndex_].contractShareDebt = int256(
                    existingContracts[i].newShare * groups[groupId].accumulatedUsdcPerContract
                );
            }

            unchecked {
                ++i;
            }
        }
        require(newTotalShare == BPS_DIVISOR, "invalid share");

        emit ContractSharesUpdated(groupId, existingContracts);
    }

    function contractPendingUsdcRewards(address contractAddress, uint8 groupId) public view override returns (uint256) {
        Group memory groupDetails = groups[groupId];
        Contract[] memory contracts_ = contracts[groupId];
        uint256 contractIndex_ = contractIndex[groupId][contractAddress];
        Contract memory wantedContract = contracts_[contractIndex_];

        uint256 accumulatedUsdcPerGroup_ = accumulatedUsdcPerGroup;
        uint256 lastFDV2Balance = lastBalance;
        uint48 lastUpdatedFDV2GroupsTimestamp = lastAllocatedGroupsTimestamp;
        uint48 lastUpdatedFDV2ContractsTimestamp = lastAllocatedContractsTimestamp;

        ///@dev new usdc gotten by the fee distributor.
        if (uint48(block.timestamp) > lastUpdatedFDV2GroupsTimestamp) {
            uint256 diff = usdcToken.balanceOf(address(this)) - lastFDV2Balance;
            if (diff != 0) {
                accumulatedUsdcPerGroup_ += diff / 1e4;
            }
        }

        ///@dev new usdc gotten by each group in the fee distributor.
        if (uint48(block.timestamp) > lastUpdatedFDV2ContractsTimestamp) {
            int256 accumulatedUsdcForThisGroup = int256(accumulatedUsdcPerGroup_ * groupDetails.feeShare);
            uint256 pendingUsdcForThisGroup = uint256(accumulatedUsdcForThisGroup - groupDetails.shareDebt);
            if (pendingUsdcForThisGroup != 0) {
                groupDetails.pendingGroupUsdc += pendingUsdcForThisGroup;
            }

            uint256 diff = groupDetails.pendingGroupUsdc - groupDetails.lastGroupBalance;
            if (diff != 0) {
                groupDetails.accumulatedUsdcPerContract += diff / 1e4;
            }
        }

        int256 accumulatedUsdcForWantedContract = int256(
            wantedContract.feeShare * groupDetails.accumulatedUsdcPerContract
        );

        uint256 pendingUsdcForThisContract = uint256(
            accumulatedUsdcForWantedContract - wantedContract.contractShareDebt
        );

        return pendingUsdcForThisContract;
    }

    function pepeStakingPendingRewards(address user) public view override returns (uint256 pendingUsdc) {
        Stake memory userPepeStakeInfo = IPepeStaking2(pepeStaking).userStake(user);
        if (userPepeStakeInfo.amount == 0) return 0;

        uint256 stakingContractAccumulatedUsdcPerPeg = IPepeStaking2(pepeStaking).accumulatedUsdcPerPeg();

        uint256 totalStakedInStakingContract = IPepeStaking2(pepeStaking).totalStaked();

        ///@dev amount of usdc the staking contract is to get from the fee distributor (this contract).
        uint256 stakingContractPendingRewards = contractPendingUsdcRewards(pepeStaking, 1);

        if (stakingContractPendingRewards != 0) {
            stakingContractAccumulatedUsdcPerPeg += stakingContractPendingRewards.mulDiv(
                1e18,
                totalStakedInStakingContract
            );
        }

        int256 accumulatedUsdc = int256(userPepeStakeInfo.amount.mulDiv(stakingContractAccumulatedUsdcPerPeg, 1e18));
        pendingUsdc = uint256(accumulatedUsdc - userPepeStakeInfo.rewardDebt);
    }

    function pepeLockUpPendingRewards(address user) public view override returns (uint256 pendingUsdc) {
        Lock memory userLockInfo = IPepeLockUp2(pepeLockUp).getLockDetails(user);
        if (userLockInfo.totalLpShare == 0) return 0;

        uint256 lockContractAccumulatedUsdcPerPeg = IPepeLockUp2(pepeLockUp).accumulatedUsdcPerLpShare();

        uint256 totalLockedInLockContract = IPepeLockUp2(pepeLockUp).totalLpShares();
        ///@dev amount of usdc the lock contract is to get from the fee distributor (this contract).
        uint256 lockContractPendingRewards = contractPendingUsdcRewards(pepeLockUp, 2);

        if (lockContractPendingRewards != 0) {
            lockContractAccumulatedUsdcPerPeg += lockContractPendingRewards.mulDiv(1e18, totalLockedInLockContract);
        }

        int256 accumulatedUsdc = int256(userLockInfo.totalLpShare.mulDiv(lockContractAccumulatedUsdcPerPeg, 1e18));
        pendingUsdc = uint256(accumulatedUsdc - userLockInfo.rewardDebt);
    }

    ///@notice retrieve multiple tokens from the contract.
    function retrieveTokens(address[] calldata _tokens, address to) external override onlyOwner {
        uint256 arrayLength = _tokens.length;
        uint256 i;
        for (; i < arrayLength; ) {
            retrieve(_tokens[i], to);
            unchecked {
                ++i;
            }
        }
    }

    ///borrowed
    ///@param _stakingContract the address of the new pepeStaking contract. Pass in address(0) to keep the current pepeStaking contract.
    ///@param _lockContract the address of the new lock contract. Pass in address(0) to keep the current lock contract.
    ///@param _plsAccumulationContract the address of the new plsAccumulation contract. Pass in address(0) to keep the current plsAccumulation contract.
    function updateContractAddresses(
        address _stakingContract,
        address _lockContract,
        address _plsAccumulationContract
    ) external override onlyOwner {
        if (_stakingContract != address(0)) {
            pepeStaking = _stakingContract;
        }
        if (_lockContract != address(0)) {
            pepeLockUp = _lockContract;
        }
        if (_plsAccumulationContract != address(0)) {
            pepePlsAccumulator = _plsAccumulationContract;
        }

        emit UpdatedContracts(pepeStaking, pepeLockUp, pepePlsAccumulator);
    }

    ///@dev FD-V2 will receive other tokens as fee, this function is to retrieve those tokens.
    function retrieve(address _token, address to) public override onlyOwner {
        require(_token != address(usdcToken), "cannot retrieve usdc");
        IERC20 token = IERC20(_token);
        if (address(this).balance != 0) {
            (bool success, ) = payable(to).call{ value: address(this).balance }("");
            require(success, "ETH retrival failed");
        }

        token.safeTransfer(to, token.balanceOf(address(this)));
    }

    function getContractIndex(uint8 groupdId, address _contract) external view override returns (uint256) {
        return contractIndex[groupdId][_contract];
    }

    function getGroup(uint8 groupId) external view override returns (Group memory) {
        return groups[groupId];
    }

    function getContracts(uint8 groupId) public view override returns (Contract[] memory) {
        return contracts[groupId];
    }

    function getGroupShareDebt(uint8 groupId) public view override returns (int256) {
        return groups[groupId].shareDebt;
    }

    function getLastBalance() external view override returns (uint256) {
        return lastBalance;
    }

    function getAccumulatedUsdcPerGroup() external view override returns (uint256) {
        return accumulatedUsdcPerGroup;
    }

    function getLastUpdatedGroupsTimestamp() external view override returns (uint48) {
        return lastAllocatedGroupsTimestamp;
    }

    function getLastUpdatedContractsTimestamp() external view override returns (uint48) {
        return lastAllocatedContractsTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

struct User {
    uint256 totalPegPerMember;
    uint256 pegClaimed;
    bool exist;
}

struct Stake {
    uint256 amount; ///@dev amount of peg staked.
    int256 rewardDebt; ///@dev outstanding rewards that will not be included in the next rewards calculation.
}

struct StakeClass {
    uint256 id;
    uint256 minDuration;
    uint256 maxDuration;
    bool isActive;
}

struct Lock {
    uint256 pegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 lastLockedAt; // last time user increased their lock allocation
    uint48 unlockTimestamp; // unlockable
}

struct EsPegLock {
    uint256 esPegLocked;
    uint256 wethLocked;
    uint256 totalLpShare;
    int256 rewardDebt;
    uint48 lockedAt; // locked
    uint48 unlockTimestamp; // unlockable
}

struct FeeDistributorInfo {
    uint256 accumulatedUsdcPerContract; ///@dev usdc allocated to the three contracts in the fee distributor.
    uint256 lastBalance; ///@dev last balance of usdc in the fee distributor.
    uint256 currentBalance; ///@dev current balance of usdc in the fee distributor.
    int256 stakingContractDebt; ///@dev outstanding rewards of this contract (staking) that will not be included in the next rewards calculation.
    int256 lockContractDebt; ///@dev outstanding rewards of this contract (lock) that will not be included in the next rewards calculation.
    int256 plsAccumationContractDebt; ///@dev outstanding rewards of this contract (pls accumulator) that will not be included in the next rewards calculation.
    uint48 lastUpdateTimestamp; ///@dev last time the fee distributor rewards were updated.
}

struct StakeDetails {
    int256 rewardDebt;
    uint112 plsStaked;
    uint32 epoch;
    address user;
}

struct StakedDetails {
    uint112 amount;
    uint32 lastCheckpoint;
}

struct EsPegStake {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct EsPegVest {
    address user; //user who staked
    uint256 amount; //amount of esPeg staked
    uint256 amountClaimable; //amount of peg claimable
    uint256 amountClaimed; //amount of peg claimed
    uint256 pegPerSecond; //reward rate
    uint48 startTime; //time when the stake started
    uint48 fullVestingTime; //time when the stake is fully vested
    uint48 lastClaimTime; //time when the user last claimed
}

struct Referrers {
    uint256 epochId;
    address[] referrers;
    uint256[] allocations;
}

struct Group {
    uint256 totalUsdcDistributed;
    uint256 accumulatedUsdcPerContract;
    uint256 pendingGroupUsdc;
    uint256 lastGroupBalance;
    int256 shareDebt;
    string name;
    uint16 feeShare;
    uint8 groupId; //1: staking , 2:locking , 3:plsAccumulator
}

struct Contract {
    uint256 totalUsdcReceived;
    int256 contractShareDebt;
    address contractAddress;
    uint16 feeShare;
    uint8 groupId; ///@dev group contract belongs to
}

struct GroupUpdate {
    uint8 groupId;
    uint16 newShare;
}

struct ContractUpdate {
    address contractAddress;
    uint16 newShare;
}

///@notice PepeBet structs
struct BetDetails {
    uint256 amount;
    uint256 wagerAmount;
    uint256 openingPrice;
    uint256 closingPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 betId;
    address initiator;
    address betToken;
    address asset;
    bool isLong;
    bool active;
}

struct WagerTokenDetails {
    address token;
    uint256 minBetAmount;
    uint256 maxBetAmount;
}

///@notice PepeLockExtention structs
struct LockExtension {
    address user;
    uint256 amount;
    uint48 lockDuration;
}

///@notice PepeDegen struct
struct DegenEpoch {
    uint32 epochId;
    address[] users;
    uint256[] amounts;
}

///@notice pepeBetPool structs
struct UserBalanceUpdate {
    address user;
    address token;
    uint256 newBalance;
}

struct ProtocolBalanceUpdate {
    address token;
    uint256 newPoolBalance;
    uint256 accumulatedFees;
}

struct BalanceUpdate {
    UserBalanceUpdate[] userBalanceUpdate;
    ProtocolBalanceUpdate[] protocolBalanceUpdate;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import { Group, GroupUpdate, Contract, ContractUpdate } from "../Structs.sol";

interface IPepeFeeDistributorV2 {
    function allocateStake() external returns (uint256);

    function allocateLock() external returns (uint256);

    function allocatePlsAccumulation() external returns (uint256);

    function updateGroupAllocations() external;

    function updateContractAllocations() external;

    function allocateUsdcToGroup(uint8 groupId) external;

    function transferUsdcToContract(uint8 groupId, address contractAddress) external returns (uint256);

    function allocateUsdcToAllGroups() external;

    function transferUsdcToAllContracts() external;

    function transferUsdcToContractsByGroupId(uint8 groupId) external;

    function pepeStakingPendingRewards(address user) external view returns (uint256);

    function pepeLockUpPendingRewards(address user) external view returns (uint256);

    function addGroup(
        GroupUpdate[] calldata update,
        string calldata name,
        uint16 groupShare,
        address contractAddress,
        uint16 contractShare
    ) external;

    function addContract(
        ContractUpdate[] memory existingContractsUpdate,
        uint8 groupId,
        address contractAddress,
        uint16 share
    ) external;

    function updateContractAddresses(
        address _stakingContract,
        address _lockContract,
        address _plsAccumulationContract
    ) external;

    function removeGroup(uint8 groupId, GroupUpdate[] memory existingGroups) external;

    function removeContract(uint8 groupId, address contractAddress, ContractUpdate[] memory existingContracts) external;

    function updateGroupShares(GroupUpdate[] memory existingGroups) external;

    function updateContractShares(uint8 groupId, ContractUpdate[] memory existingContracts) external;

    function contractPendingUsdcRewards(address contractAddress, uint8 groupId) external view returns (uint256);

    function retrieveTokens(address[] calldata _tokens, address to) external;

    function retrieve(address _token, address to) external;

    function getLastBalance() external view returns (uint256);

    function getAccumulatedUsdcPerGroup() external view returns (uint256);

    function getLastUpdatedContractsTimestamp() external view returns (uint48);

    function getLastUpdatedGroupsTimestamp() external view returns (uint48);

    function getContractIndex(uint8 groupdId, address _contract) external view returns (uint256);

    function getGroup(uint8 groupId) external view returns (Group memory);

    function getContracts(uint8 groupId) external view returns (Contract[] memory);

    function getGroupShareDebt(uint8 groupId) external view returns (int256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IPepeStaking } from "./IPepeStaking.sol";
import { Stake } from "../Structs.sol";

interface IPepeStaking2 is IPepeStaking {
    function accumulatedUsdcPerPeg() external view returns (uint256);

    function userStake(address user) external view returns (Stake memory);

    function totalStaked() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { IPepeLockUp } from "./IPepeLockUp.sol";

interface IPepeLockUp2 is IPepeLockUp {
    function accumulatedUsdcPerLpShare() external view returns (uint256);

    function totalLpShares() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IPepeStaking {
    function stake(uint256 amount) external;

    function unStake(uint256 amount) external;

    function exit() external;

    function updateRewards() external;

    function claimRewards() external;

    function pendingRewards(address user) external view returns (uint256);

    function getUserStake(address user) external view returns (uint256);

    function setFeeDistributor(address feeDistributor) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import { Lock } from "../Structs.sol";

interface IPepeLockUp {
    function initializePool(uint256 wethAmount, uint256 pegAmount, address poolAdmin) external;

    function updateRewards() external;

    function lock(uint256 wethAmount, uint256 pegAmount, uint256 minBlpOut) external;

    function unLock() external;

    function claimUsdcRewards() external;

    function pendingUsdcRewards(address _user) external view returns (uint256);

    function getLockDetails(address _user) external view returns (Lock memory);

    function lockDuration() external view returns (uint48);

    function setLockDuration(uint48 _lockDuration) external;

    function setFeeDistributor(address _feeDistributor) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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