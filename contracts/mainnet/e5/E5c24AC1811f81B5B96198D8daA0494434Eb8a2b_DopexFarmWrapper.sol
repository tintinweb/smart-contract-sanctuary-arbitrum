// SPDX-License-Identifier: GPL-3.0
/*                            ******@@@@@@@@@**@*                               
                        ***@@@@@@@@@@@@@@@@@@@@@@**                             
                     *@@@@@@**@@@@@@@@@@@@@@@@@*@@@*                            
                  *@@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@*@**                          
                 *@@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@*                         
                **@@@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@**                       
                **@@@@@@@@@@@@@@@*@@@@@@@@@@@@@@@@@@@@@@@*                      
                **@@@@@@@@@@@@@@@@*************************                    
                **@@@@@@@@***********************************                   
                 *@@@***********************&@@@@@@@@@@@@@@@****,    ******@@@@*
           *********************@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@************* 
      ***@@@@@@@@@@@@@@@*****@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@****@@*********      
   **@@@@@**********************@@@@*****************#@@@@**********            
  *@@******************************************************                     
 *@************************************                                         
 @*******************************                                               
 *@*************************                                                    
   *********************  
   
    /$$$$$                                               /$$$$$$$   /$$$$$$   /$$$$$$ 
   |__  $$                                              | $$__  $$ /$$__  $$ /$$__  $$
      | $$  /$$$$$$  /$$$$$$$   /$$$$$$   /$$$$$$$      | $$  \ $$| $$  \ $$| $$  \ $$
      | $$ /$$__  $$| $$__  $$ /$$__  $$ /$$_____/      | $$  | $$| $$$$$$$$| $$  | $$
 /$$  | $$| $$  \ $$| $$  \ $$| $$$$$$$$|  $$$$$$       | $$  | $$| $$__  $$| $$  | $$
| $$  | $$| $$  | $$| $$  | $$| $$_____/ \____  $$      | $$  | $$| $$  | $$| $$  | $$
|  $$$$$$/|  $$$$$$/| $$  | $$|  $$$$$$$ /$$$$$$$/      | $$$$$$$/| $$  | $$|  $$$$$$/
 \______/  \______/ |__/  |__/ \_______/|_______/       |_______/ |__/  |__/ \______/                                      
*/
pragma solidity ^0.8.2;

/// Interfaces
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDPXSingleStaking} from "../../interfaces/IDPXSingleStaking.sol";

/// @title A Dopex single stake farm wrapper library
/// @author Jones DAO
/// @notice Adds a few utility functions to Dopex single stake farms
library DopexFarmWrapper {
    /**
     * @notice Stakes an amount of assets
     * @param _amount a parameter just like in doxygen (must be followed by parameter name)
     */
    function addSingleStakeAsset(IDPXSingleStaking self, uint256 _amount)
        external
        returns (bool)
    {
        self.stake(_amount);

        return true;
    }

    /**
     * @notice Stakes the complete balance if the caller is whitelisted
     * @param _caller The address to check whitelist and get the staking token balance
     */
    function depositAllIfWhitelisted(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        if (self.whitelistedContracts(_caller)) {
            uint256 amount = IERC20(self.stakingToken()).balanceOf(_caller);

            self.stake(amount);
        }

        return true;
    }

    /**
     * @notice Removes an amount from staking with an option to claim rewards
     * @param _amount the amount to withdraw from staking
     * @param _getRewards if true the function will claim rewards
     */
    function removeSingleStakeAsset(
        IDPXSingleStaking self,
        uint256 _amount,
        bool _getRewards
    ) public returns (bool) {
        if (_getRewards) {
            self.getReward(2);
        }

        if (_amount > 0) {
            self.withdraw(_amount);
        }

        return true;
    }

    /**
     * @notice Removes the complete position from staking
     * @param _caller The address to get the deposited balance
     */
    function removeAll(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        uint256 amount = self.balanceOf(_caller);

        removeSingleStakeAsset(self, amount, false);

        return true;
    }

    /**
     * @notice Claim all rewards
     */
    function claimRewards(IDPXSingleStaking self) external returns (bool) {
        return removeSingleStakeAsset(self, 0, true);
    }

    /**
     * @notice Removes all assets from the farm and claim all rewards
     */
    function exitSingleStakeAsset(IDPXSingleStaking self)
        external
        returns (bool)
    {
        self.exit();

        return true;
    }

    /**
     * @notice Removes all assets from the farm and claim rewards only if the caller has assets staked
     * @param _caller the address used to check if it has staked assets on the farm
     */
    function exitIfPossible(IDPXSingleStaking self, address _caller)
        external
        returns (bool)
    {
        if (self.balanceOf(_caller) > 0) {
            self.exit();
        }

        return true;
    }

    /**
     * @notice Obtain the amount of DPX earned on the farm
     * @param _caller the address used to check if it has rewards
     */
    function earnedDPX(IDPXSingleStaking self, address _caller)
        public
        view
        returns (uint256)
    {
        (uint256 reward, ) = self.earned(_caller);

        return reward;
    }

    /**
     * @notice Obtain the amount of rDPX earned on the farm
     * @param _caller the address used to check if it has rewards
     */
    function earnedRDPX(IDPXSingleStaking self, address _caller)
        external
        view
        returns (uint256)
    {
        (, uint256 reward) = self.earned(_caller);

        return reward;
    }

    /**
     * @notice Compound Single stake rewards
     */
    function compoundRewards(IDPXSingleStaking self) external returns (bool) {
        self.compound();
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

interface IDPXSingleStaking {
    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward(uint256 rewardsTokenID) external;

    function compound() external;

    function exit() external;

    function earned(address account)
        external
        view
        returns (uint256 DPXEarned, uint256 RDPXEarned);

    function stakingToken() external view returns (address);

    function rewardsTokenDPX() external view returns (address);

    function whitelistedContracts(address) external view returns (bool);
}