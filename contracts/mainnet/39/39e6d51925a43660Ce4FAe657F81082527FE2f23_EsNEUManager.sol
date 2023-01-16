/**
 *Submitted for verification at Arbiscan on 2023-01-16
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/interfaces/IMintable.sol


pragma solidity 0.8.11;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}


// File contracts/libraries/Governable.sol


pragma solidity 0.8.11;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}


// File contracts/interfaces/IVester.sol


pragma solidity 0.8.11;

interface IVester {
    function rewardTracker() external view returns (address);

    function claimForAccount(address _account, address _receiver) external returns (uint256);

    function claimable(address _account) external view returns (uint256);

    function cumulativeClaimAmounts(address _account) external view returns (uint256);

    function claimedAmounts(address _account) external view returns (uint256);

    function pairAmounts(address _account) external view returns (uint256);

    function getVestedAmount(address _account) external view returns (uint256);

    function transferredAverageStakedAmounts(address _account) external view returns (uint256);

    function transferredCumulativeRewards(address _account) external view returns (uint256);

    function cumulativeRewardDeductions(address _account) external view returns (uint256);

    function bonusRewards(address _account) external view returns (uint256);

    function transferStakeValues(address _sender, address _receiver) external;

    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;

    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;

    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;

    function setBonusRewards(address _account, uint256 _amount) external;

    function getMaxVestableAmount(address _account) external view returns (uint256);

    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}


// File contracts/token/EsNEUManager.sol

pragma solidity 0.8.11;




contract EsNEUManager is Governable {
    address public esNeu;

    address public vester;

    mapping(address => uint256) private _balances;

    event Transfer(address sender, address recipient, uint256 amount);
    
    constructor(
        address _esNeu,
        address _vester
    ){
        esNeu = _esNeu;
        vester = _vester;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function depositForAccount(address account, uint256 amount) public onlyGov {
        _balances[account] += amount;

        IMintable(esNeu).mint(address(this), amount);
    } 

    function burnForAccount(address account, uint256 amount) public onlyGov {
        _balances[account] -= amount;

        IMintable(esNeu).burn(address(this), amount);
    }

    function transfer(address _recipient, uint256 _amount) public returns (bool){
        require(_amount <= _balances[msg.sender], "EsNEUManager, not enough balance");
        require(_amount > 0, "EsNEUManager: invalid _amount");

        _transfer(msg.sender, _recipient, _amount);

        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        _balances[_sender] -= _amount;

        uint256 userBonusRewards = IVester(vester).bonusRewards(_recipient);

        IVester(vester).setBonusRewards(_recipient, userBonusRewards + _amount);

        IERC20(esNeu).transfer(_recipient, _amount);

        emit Transfer(_sender, _recipient, _amount);
    }
}