/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IXARB {
    function distributeReward(address _genesisPool) external;
    function setXarbOracle(address _xarbOracle) external;
    function setTaxOffice(address _taxOffice) external;
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;
}

interface IDROP {
    function distributeReward(address _farmingIncentiveFund) external;
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;
}

interface ITRBOND {
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;
}

interface IXarbGenesis {
    function add(
        uint256 _allocPoint,
        address _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeeBP,
        bool _isLPtoken
    ) external;
    function setTreasuryFund(address _treasuryFund) external;
    function setReferral(address _referral) external;
    function setOperator(address _operator) external;
}

interface IDropRewardPool {
    function add(
        uint256 _allocPoint,
        address _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _depositFeeBP,
        bool _isLPtoken
    ) external;
    function setTreasuryFund(address _treasuryFund) external;
    function setReferral(address _referral) external;
    function setOperator(address _operator) external;
}

interface IBoardroom {
    function initialize(
        address _xarb,
        address _drop,
        address _treasury
    ) external;
    function setOperator(address _operator) external;
}

interface ISeigniorageOracle {
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;
}

interface ITreasury {
    function initialize(
        address _xarb,
        address _trbond,
        address _drop,
        address _xarbOracle,
        address _boardroom,
        uint256 _startTime
    ) external;
    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external;
    function setOperator(address _operator) external;
}

interface IReferral {
    function setOperator(address _operator, bool _flag) external;
    function transferOwnership(address newOwner) external;
}

interface ITaxOffice {
    function transferOperator(address newOperator_) external;
    function transferOwnership(address newOwner) external;
}

contract Initializer is Ownable {

    address public WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    address public USDC = address(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
    address public projectOwner = address(0x43E8d37a835dE539c42a268FAe44521021994BB4);
    address public projectTreasuryFund = address(0x43E8d37a835dE539c42a268FAe44521021994BB4);
    address public projectDevFund = address(0x43E8d37a835dE539c42a268FAe44521021994BB4);

    uint256 public genesisStartTimestamp = 1679580000; // Thu Mar 23 2023 14:00:00 GMT+0000
    uint256 public farmStartTimestamp = 1680012000; // Tue Mar 28 2023 14:00:00 GMT+0000
    uint256 public epochPeriod = 21600;

    bool public initialized = false;
    
    constructor(){}

    function initialize(
        address xarb,
        address drop,
        address trbond,
        address xarbGenesis,
        address dropRewardPool,
        address boardroom,
        address seigniorageOracle,
        address treasury,
        address referral,
        address taxOffice,
        address xarb_eth_pair,
        address drop_eth_pair
    ) external onlyOwner {
        require(!initialized, "invalid");

        IXARB(xarb).distributeReward(xarbGenesis);
        IXARB(xarb).setXarbOracle(seigniorageOracle);
        IXARB(xarb).setTaxOffice(taxOffice);
        IXARB(xarb).transferOperator(treasury);
        IXARB(xarb).transferOwnership(projectOwner);

        IDROP(drop).distributeReward(dropRewardPool);
        IDROP(drop).transferOperator(treasury);
        IDROP(drop).transferOwnership(projectOwner);

        ITRBOND(trbond).transferOperator(treasury);
        ITRBOND(trbond).transferOwnership(projectOwner);

        IXarbGenesis(xarbGenesis).add(4000, xarb_eth_pair, false, 0, 0, true);
        IXarbGenesis(xarbGenesis).add(3000, WETH, false, 0, 200, false);
        IXarbGenesis(xarbGenesis).add(3000, USDC, false, 0, 200, false);
        IXarbGenesis(xarbGenesis).setTreasuryFund(projectTreasuryFund);
        IXarbGenesis(xarbGenesis).setReferral(referral);
        IXarbGenesis(xarbGenesis).setOperator(projectOwner);

        IDropRewardPool(dropRewardPool).add(3000, xarb_eth_pair, false, 0, 0, true);
        IDropRewardPool(dropRewardPool).add(3000, drop_eth_pair, false, 0, 0, true);
        IDropRewardPool(dropRewardPool).add(2000, WETH, false, 0, 300, false);
        IDropRewardPool(dropRewardPool).add(2000, USDC, false, 0, 300, false);
        IDropRewardPool(dropRewardPool).setTreasuryFund(projectTreasuryFund);
        IDropRewardPool(dropRewardPool).setReferral(referral);
        IDropRewardPool(dropRewardPool).setOperator(projectOwner);

        IBoardroom(boardroom).initialize(xarb, drop, treasury);
        IBoardroom(boardroom).setOperator(treasury);

        ISeigniorageOracle(seigniorageOracle).transferOperator(projectOwner);
        ISeigniorageOracle(seigniorageOracle).transferOwnership(projectOwner);
        
        ITreasury(treasury).initialize(xarb, trbond, drop, seigniorageOracle, boardroom, farmStartTimestamp);
        ITreasury(treasury).setExtraFunds(projectTreasuryFund, 1800, projectDevFund, 200);
        ITreasury(treasury).setOperator(projectOwner);

        IReferral(referral).setOperator(xarbGenesis, true);
        IReferral(referral).setOperator(dropRewardPool, true);
        IReferral(referral).transferOwnership(projectOwner);

        ITaxOffice(taxOffice).transferOperator(projectOwner);
        ITaxOffice(taxOffice).transferOwnership(projectOwner);

        initialized = true;
    }
}