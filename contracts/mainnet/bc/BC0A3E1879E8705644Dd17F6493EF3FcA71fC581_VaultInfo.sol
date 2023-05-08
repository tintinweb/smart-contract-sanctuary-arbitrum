// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IClaim {
    function claim(address _recipient) external returns (uint256 claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { IClaim } from "../../interfaces/IClaim.sol";
import { ICommonReward } from "./ICommonReward.sol";

interface IBaseReward is ICommonReward, IClaim {
    function stakeFor(address _recipient, uint256 _amountIn) external;

    function withdraw(uint256 _amountOut) external returns (uint256);

    function withdrawFor(address _recipient, uint256 _amountOut) external returns (uint256);

    function pendingRewards(address _recipient) external view returns (uint256);

    function balanceOf(address _recipient) external view returns (uint256);

    event StakeFor(address indexed _recipient, uint256 _amountIn, uint256 _totalSupply, uint256 _totalUnderlying);
    event Withdraw(address indexed _recipient, uint256 _amountOut, uint256 _totalSupply, uint256 _totalUnderlying);
    event Claim(address indexed _recipient, uint256 _claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICommonReward {
    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function distribute(uint256 _rewards) external;

    event Distribute(uint256 _rewards, uint256 _accRewardPerShare);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { IAbstractVault as IOriginAbstractVault } from "./vaults/interfaces/IAbstractVault.sol";
import { IBaseReward as IOriginBaseReward } from "./rewards/interfaces/IBaseReward.sol";

interface IAbstractVault is IOriginAbstractVault {
    function creditManagers(uint256 _index) external view returns (address);

    function creditManagersCount() external view returns (uint256);
}

interface IBaseReward is IOriginBaseReward {
    function totalSupply() external view returns (uint256);
}

contract VaultInfo {
    bool private _initializing;

    modifier initializer() {
        require(!_initializing, "VaultInfo: Contract is already initialized");
        _;
    }

    // @notice used to initialize the contract
    function initialize() external initializer {
        _initializing = true;
    }

    function workingBalance(address[] calldata _vaults) public view returns (address[] memory, uint256[] memory) {
        address[] memory underlyingTokens = new address[](_vaults.length);
        uint256[] memory total = new uint256[](_vaults.length);

        for (uint256 i = 0; i < _vaults.length; i++) {
            address supplyRewardPool = IAbstractVault(_vaults[i]).supplyRewardPool();

            underlyingTokens[i] = IAbstractVault(_vaults[i]).underlyingToken();
            total[i] = IBaseReward(supplyRewardPool).totalSupply();
        }

        return (underlyingTokens, total);
    }

    function borrowedBalance(address[] calldata _vaults) public view returns (address[] memory, uint256[] memory) {
        address[] memory underlyingTokens = new address[](_vaults.length);
        uint256[] memory total = new uint256[](_vaults.length);

        for (uint256 i = 0; i < _vaults.length; i++) {
            address borrowedRewardPool = IAbstractVault(_vaults[i]).borrowedRewardPool();

            underlyingTokens[i] = IAbstractVault(_vaults[i]).underlyingToken();
            total[i] = IBaseReward(borrowedRewardPool).totalSupply();
        }

        return (underlyingTokens, total);
    }

    function lockedBalance(address[] calldata _vaults) public view returns (address[] memory, uint256[] memory) {
        address[] memory underlyingTokens = new address[](_vaults.length);
        uint256[] memory total = new uint256[](_vaults.length);

        for (uint256 i = 0; i < _vaults.length; i++) {
            address borrowedRewardPool = IAbstractVault(_vaults[i]).borrowedRewardPool();

            underlyingTokens[i] = IAbstractVault(_vaults[i]).underlyingToken();

            for (uint256 j = 0; j < IAbstractVault(_vaults[i]).creditManagersCount(); j++) {
                address creditManager = IAbstractVault(_vaults[i]).creditManagers(j);
                address shareLocker = IAbstractVault(_vaults[i]).creditManagersShareLocker(creditManager);

                total[i] += IBaseReward(borrowedRewardPool).balanceOf(shareLocker);
            }
        }

        return (underlyingTokens, total);
    }

    function debtBalance(address[] calldata _vaults) public view returns (address[] memory, uint256[] memory) {
        address[] memory underlyingTokens = new address[](_vaults.length);
        uint256[] memory total = new uint256[](_vaults.length);

        for (uint256 i = 0; i < _vaults.length; i++) {
            address borrowedRewardPool = IAbstractVault(_vaults[i]).borrowedRewardPool();

            underlyingTokens[i] = IAbstractVault(_vaults[i]).underlyingToken();
            total[i] = IBaseReward(borrowedRewardPool).totalSupply();

            for (uint256 j = 0; j < IAbstractVault(_vaults[i]).creditManagersCount(); j++) {
                address creditManager = IAbstractVault(_vaults[i]).creditManagers(j);
                address shareLocker = IAbstractVault(_vaults[i]).creditManagersShareLocker(creditManager);

                total[i] -= IBaseReward(borrowedRewardPool).balanceOf(shareLocker);
            }
        }

        return (underlyingTokens, total);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAbstractVault {
    function borrow(uint256 _borrowedAmount) external returns (uint256);

    function repay(
        uint256 _borrowedAmount,
        uint256 _repayAmountDuringLiquidation,
        bool _liquidating
    ) external;

    function supplyRewardPool() external view returns (address);

    function borrowedRewardPool() external view returns (address);

    function underlyingToken() external view returns (address);

    function creditManagersShareLocker(address _creditManager) external view returns (address);

    function creditManagersCanBorrow(address _creditManager) external view returns (bool);

    function creditManagersCanRepay(address _creditManager) external view returns (bool);

    event AddLiquidity(address indexed _recipient, uint256 _amountIn, uint256 _timestamp);
    event RemoveLiquidity(address indexed _recipient, uint256 _amountOut, uint256 _timestamp);
    event Borrow(address indexed _creditManager, uint256 _borrowedAmount);
    event Repay(address indexed _creditManager, uint256 _borrowedAmount, uint256 _repayAmountDuringLiquidatio, bool _liquidating);
    event SetSupplyRewardPool(address _rewardPool);
    event SetBorrowedRewardPool(address _rewardPool);
    event SetRewardTracker(address _tracker);
    event AddCreditManager(address _creditManager, address _shareLocker);
    event ToggleCreditManagerToBorrow(address _creditManager, bool _oldState);
    event ToggleCreditManagersCanRepay(address _creditManager, bool _oldState);
}