/**
 *Submitted for verification at Arbiscan on 2023-04-04
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File contracts/launchpad/interfaces/IZyberVault.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IZyberVault {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 lastInteraction; // Last time when user deposited or claimed rewards, renewing the lock
    }

    function userInfo(
        uint256 _pid,
        address user
    ) external view returns (UserInfo memory);

    function poolLength() external view returns (uint256);

    function userLockedUntil(
        uint256 _pid,
        address _user
    ) external view returns (uint256);
}


// File contracts/launchpad/VaultUtils.sol

pragma solidity =0.8.18;
pragma abicoder v2;
contract VaultUtils {
    IZyberVault public immutable VAULT;
    uint256 internal constant NINETY_MIN_AMOUNT = 1200 ether;
    uint256 internal constant THIRTY_MIN_AMOUNT = 300 ether;
    uint256 internal constant SEVEN_MIN_AMOUNT = 300 ether;

    uint256 internal constant poolSevenLockUp = 7 days;
    uint256 internal constant poolThirtyLockUp = 30 days;
    uint256 internal constant poolNinetyLockUp = 90 days;

    uint256 internal constant MIN_AMOUNT = 0 ether;

    function getVaultUserInfo(
        address _user
    ) external view returns (uint256 stakedAmount) {
        IZyberVault.UserInfo memory sevenLock = VAULT.userInfo(1, _user);
        IZyberVault.UserInfo memory thirtyLock = VAULT.userInfo(2, _user);
        IZyberVault.UserInfo memory ninetyLock = VAULT.userInfo(3, _user);

        if (
            ninetyLock.amount >= NINETY_MIN_AMOUNT &&
            ninetyLock.lastInteraction + poolNinetyLockUp > block.timestamp
        ) {
            return 192;
        } else if (
            thirtyLock.amount >= SEVEN_MIN_AMOUNT &&
            thirtyLock.lastInteraction + poolThirtyLockUp > block.timestamp
        ) {
            return 16;
        } else if (
            sevenLock.amount >= SEVEN_MIN_AMOUNT &&
            sevenLock.lastInteraction + poolSevenLockUp > block.timestamp
        ) {
            return 4;
        } else return 0;
    }

    function isUserInVaults(address _user) external view returns (bool) {
        IZyberVault.UserInfo memory sevenLock = VAULT.userInfo(1, _user);
        IZyberVault.UserInfo memory thirtyLock = VAULT.userInfo(2, _user);
        IZyberVault.UserInfo memory ninetyLock = VAULT.userInfo(3, _user);

        if (
            sevenLock.amount >= MIN_AMOUNT ||
            thirtyLock.amount >= MIN_AMOUNT ||
            ninetyLock.amount >= MIN_AMOUNT
        ) {
            return true;
        } else return false;
    }

    constructor(IZyberVault _vault) {
        VAULT = _vault;
    }
}