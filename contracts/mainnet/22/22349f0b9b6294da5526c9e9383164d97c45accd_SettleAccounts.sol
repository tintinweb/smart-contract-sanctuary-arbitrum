// SPDX-License-Identifier: BSUL-1.1
pragma solidity =0.8.19;

interface NotionalProxy {
    function settleAccount(address account) external;

    function settleVaultAccount(address account, address vault) external;
}

struct VaultAccounts {
    address vaultAddress;
    address[] accounts;
}

contract SettleAccounts {
    event AccountSettlementFailed(address account);
    event VaultAccountSettlementFailed(address account, address vault);

    address public immutable NOTIONAL;

    constructor(address _notional) {
        NOTIONAL = _notional;
    }

    function settleAccounts(address[] calldata accounts) external {
        for (uint16 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            try NotionalProxy(NOTIONAL).settleAccount(account) {} catch {
                emit AccountSettlementFailed(account);
            }
        }
    }

    function settleVaultsAccounts(VaultAccounts[] calldata vaultAccountsArray) external {
        for (uint256 i = 0; i < vaultAccountsArray.length; i++) {
            VaultAccounts memory vaultAccounts = vaultAccountsArray[i];
            for (uint16 j = 0; j < vaultAccounts.accounts.length; j++) {
                address account = vaultAccounts.accounts[j];
                try
                    NotionalProxy(NOTIONAL).settleVaultAccount(account, vaultAccounts.vaultAddress)
                {} catch {
                    emit VaultAccountSettlementFailed(account, vaultAccounts.vaultAddress);
                }
            }
        }
    }
}