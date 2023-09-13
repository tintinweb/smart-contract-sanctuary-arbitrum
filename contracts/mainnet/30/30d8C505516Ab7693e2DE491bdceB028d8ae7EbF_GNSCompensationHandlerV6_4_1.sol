// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface GNSStakingInterfaceV6_4_1 {
    // Structs
    struct Staker {
        uint128 stakedGns; // 1e18
        uint128 debtDai; // 1e18
    }

    struct UnlockSchedule {
        uint128 totalGns; // 1e18
        uint128 claimedGns; // 1e18
        uint128 debtDai; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
        uint16 __placeholder;
    }

    struct UnlockScheduleInput {
        uint128 totalGns; // 1e18
        uint48 start; // block.timestamp (seconds)
        uint48 duration; // in seconds
        bool revocable;
        UnlockType unlockType;
    }

    enum UnlockType {
        LINEAR,
        CLIFF
    }

    function owner() external view returns (address);

    function distributeRewardDai(uint _amountDai) external;

    function createUnlockSchedule(UnlockScheduleInput calldata _schedule, address _staker) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function hasRole(bytes32, address) external view returns (bool);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../interfaces/TokenInterfaceV5.sol";
import "../interfaces/NftInterfaceV5.sol";
import "../interfaces/GNSStakingInterfaceV6_4_1.sol";

contract GNSCompensationHandlerV6_4_1 {
    // NFT unlock constants
    uint private constant NFT_1_VALUE = 800e18;
    uint private constant NFT_2_VALUE = 1_200e18;
    uint private constant NFT_3_VALUE = 1_800e18;
    uint private constant NFT_4_VALUE = 3_700e18;
    uint private constant NFT_5_VALUE = 12_000e18;

    uint private constant NFT_PENALTY_P = 25; // Conversion penalty if user skip unlock schedule (25%)
    uint48 private constant NFT_UNLOCK_DURATION = 180 days; // 6 months in seconds
    GNSStakingInterfaceV6_4_1.UnlockType private constant NFT_UNLOCK_TYPE = GNSStakingInterfaceV6_4_1.UnlockType.LINEAR;

    // Dev unlock constants
    address private constant DEV_ADDRESS = 0x211999E5eE74Af3E8dAcBCd5c4e608CD7D8086FA;
    uint private constant DEV_UNLOCK_CHAIN = 42161;
    uint128 private constant DEV_UNLOCK_AMOUNT = 1_000_000e18;
    uint48 private constant DEV_UNLOCK_DURATION = 365 days;
    GNSStakingInterfaceV6_4_1.UnlockType private constant DEV_UNLOCK_TYPE = GNSStakingInterfaceV6_4_1.UnlockType.CLIFF;

    // Addresses
    TokenInterfaceV5 public immutable gns;
    GNSStakingInterfaceV6_4_1 public immutable staking;
    NftInterfaceV5[5] public nfts;

    // State
    bool public devFundUnlockScheduled;

    // Data structures
    struct ClaimInput {
        uint nftType;
        uint[] ids;
    }

    // Events
    event NftsConverted(address indexed user, ClaimInput[] input, uint claimAmount, uint penaltyAmount, bool locked);
    event DevFundUnlockScheduled();

    constructor(TokenInterfaceV5 _gns, GNSStakingInterfaceV6_4_1 _staking, NftInterfaceV5[5] memory _nfts) {
        require(
            address(_gns) != address(0) &&
                address(_staking) != address(0) &&
                address(_nfts[0]) != address(0) &&
                address(_nfts[1]) != address(0) &&
                address(_nfts[2]) != address(0) &&
                address(_nfts[3]) != address(0) &&
                address(_nfts[4]) != address(0),
            "WRONG_VALUES"
        );

        gns = _gns;
        staking = _staking;
        nfts = _nfts;

        // Approve staking contract allowance so it can transferFrom when creating new unlocks
        gns.approve(address(staking), type(uint256).max);
    }

    function retireNfts(ClaimInput[] calldata _inputArr, bool _lock) external {
        // ClaimInput[] should be grouped by nftType and therefore of length 5 or less
        require(_inputArr.length < 6, "INCORRECT_GROUPING");

        uint[5] memory nftValues = [NFT_1_VALUE, NFT_2_VALUE, NFT_3_VALUE, NFT_4_VALUE, NFT_5_VALUE];
        uint toClaim;
        uint penaltyAmount;

        for (uint i; i < _inputArr.length; ) {
            ClaimInput memory input = _inputArr[i];

            uint nftType = input.nftType - 1;
            NftInterfaceV5 nft = nfts[nftType];

            for (uint j; j < input.ids.length; ) {
                nft.transferFrom(msg.sender, address(this), input.ids[j]);

                unchecked {
                    ++j;
                }
            }

            toClaim += nftValues[nftType] * input.ids.length;

            unchecked {
                ++i;
            }
        }

        require(toClaim > 0, "NOTHING_TO_CLAIM");

        if (_lock) {
            gns.mint(address(this), toClaim);

            staking.createUnlockSchedule(
                GNSStakingInterfaceV6_4_1.UnlockScheduleInput({
                    totalGns: uint128(toClaim),
                    start: 0,
                    duration: NFT_UNLOCK_DURATION,
                    revocable: false,
                    unlockType: NFT_UNLOCK_TYPE
                }),
                msg.sender
            );
        } else {
            penaltyAmount = (toClaim * NFT_PENALTY_P) / 100;
            toClaim -= penaltyAmount;

            gns.mint(msg.sender, toClaim);
            gns.mint(staking.owner(), penaltyAmount);
        }

        emit NftsConverted(msg.sender, _inputArr, toClaim, penaltyAmount, _lock);
    }

    function scheduleDevFundUnlock() external {
        require(msg.sender == staking.owner(), "ONLY_GOV");
        require(block.chainid == DEV_UNLOCK_CHAIN, "NOT_ARBITRUM");
        require(!devFundUnlockScheduled, "ALREADY_SCHEDULED");

        devFundUnlockScheduled = true;

        gns.mint(address(this), DEV_UNLOCK_AMOUNT);

        staking.createUnlockSchedule(
            GNSStakingInterfaceV6_4_1.UnlockScheduleInput({
                totalGns: DEV_UNLOCK_AMOUNT,
                start: 0,
                duration: DEV_UNLOCK_DURATION,
                revocable: false,
                unlockType: DEV_UNLOCK_TYPE
            }),
            DEV_ADDRESS
        );

        emit DevFundUnlockScheduled();
    }
}