// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IPanaAuthority.sol";

abstract contract PanaAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPanaAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IPanaAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IPanaAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IPanaAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IBondingCalculator {
    function valuation( address pair_, uint amount_, uint256 _baseValue ) external view returns ( uint _value );
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IPana is IERC20 {
  event DistributionConcluded(uint256 totalDistributed);

  function mint(address account_, uint256 amount_) external;

  function burn(uint256 amount) external;

  function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IPanaAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event DistributionVaultPushed(address indexed from, address indexed to, bool _effectiveImmediately); 

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);
    event DistributionVaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
    function distributionVault() external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ISupplyContoller {
        
    /* ========== EVENTS ========== */
    event SetSupplyControlParams(uint256 totalSupply, uint256 old_lossRatio, uint256 old_cf, uint256 old_cc, 
                            uint256 old_mslp, uint256 lossRatio, uint256 cf, uint256 cc, 
                                uint256 mslp);
    event Burnt(uint256 totalSupply, uint256 panaInPool, uint256 slp, uint256 panaResidue, uint256 tokenResidue);
    event Supplied(uint256 totalSupply, uint256 panaInPool, uint256 slp, 
                    uint256 panaSupplied, uint256 panaResidue, uint256 tokenResidue);
    
    function supplyControlEnabled() external view returns (bool);

    function paramsSet() external view returns (bool);

    function setSupplyControlParams(uint256 _lossRatio, uint256 _cf, uint256 _cc, uint256 _mslp) external;

    function enableSupplyControl() external;

    function disableSupplyControl() external;

    function getSupplyControlAmount() external view returns (uint256 _pana, uint256 _slp, bool _burn);

    function burn(uint256 _slp) external;

    function add(uint256 _pana) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _payout
    ) external returns (uint256);

    function depositForRedemption(uint _amount, address _token) external returns (uint256 send_);

    function tokenValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function baseSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IsPana is IERC20 {
    function rebase( uint256 panaProfit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );

    function index() external view returns ( uint );

    function toKARSHA(uint amount) external view returns (uint);

    function fromKARSHA(uint amount) external view returns (uint);
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.7.5;

import "../libraries/SafeMath.sol";
import "../libraries/SafeERC20.sol";

import "../interfaces/IERC20.sol";
import "../interfaces/IERC20Metadata.sol";
import "../interfaces/IPana.sol";
import "../interfaces/IsPana.sol";
import "../interfaces/IBondingCalculator.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/ISupplyContoller.sol";

import "../access/PanaAccessControlled.sol";

contract PanaTreasury is PanaAccessControlled, ITreasury {
    /* ========== DEPENDENCIES ========== */

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event Deposit(address indexed token, uint256 amount, uint256 payout);
    event DepositForRedemption(address indexed token, uint256 amount, uint256 send);
    event Managed(address indexed token, uint256 amount);
    event Minted(address indexed caller, address indexed recipient, uint256 amount);
    event PermissionQueued(STATUS indexed status, address queued);
    event Permissioned(address addr, STATUS indexed status, bool result);
    event MintedForNFTTreasury(uint256 amount, address treasury);

    /* ========== DATA STRUCTURES ========== */

    enum STATUS {
        RESERVEDEPOSITOR,
        RESERVETOKEN,
        RESERVEMANAGER,
        LIQUIDITYDEPOSITOR,
        LIQUIDITYTOKEN,
        LIQUIDITYMANAGER,
        REWARDMANAGER,
        SPANA,
        PANAREDEEMER,
        NFTTREASURY
    }

    struct Queue {
        STATUS managing;
        address toPermit;
        address supplyController;
        uint256 timelockEnd;
        bool nullify;
        bool executed;
    }

    /* ========== STATE VARIABLES ========== */

    IPana public immutable PANA;
    IsPana public sPANA;

    mapping(STATUS => address[]) public registry;
    mapping(STATUS => mapping(address => bool)) public permissions;
    mapping(address => address) public supplyController;

    Queue[] public permissionQueue;
    uint256 public immutable blocksNeededForQueue;

    bool public timelockEnabled;
    bool public initialized;

    uint256 public onChainGovernanceTimelock;

    // Percentage of PANA balance available for redemption.
    // Percentage specified to 4 precision digits. 100 = 1% = 0.01
    uint256 public redemptionLimit;

    string internal notAccepted = "Treasury: not accepted";
    string internal notApproved = "Treasury: not approved";
    string internal invalidToken = "Treasury: invalid token";
    string internal noValuation = "Treasury: asset is not a reserve token";

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _pana,
        uint256 _timelock,
        address _authority
    ) PanaAccessControlled(IPanaAuthority(_authority)) {
        require(_pana != address(0), "Zero address: PANA");
        PANA = IPana(_pana);

        timelockEnabled = false;
        initialized = false;
        blocksNeededForQueue = _timelock;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice allow approved address to deposit an asset for PANA
     * @param _amount uint256
     * @param _token address
     * @param _payout uint256
     * @return send_ uint256
     */
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _payout
    ) external override returns (uint256) {
        if (permissions[STATUS.RESERVETOKEN][_token]) {
            require(permissions[STATUS.RESERVEDEPOSITOR][msg.sender], notApproved);
        } else if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYDEPOSITOR][msg.sender], notApproved);
        } else {
            revert(invalidToken);
        }

        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        PANA.mint(msg.sender, _payout);

        emit Deposit(_token, _amount, _payout);

        if(permissions[STATUS.LIQUIDITYTOKEN][_token] 
            && supplyController[_token] != address(0)
            && ISupplyContoller(supplyController[_token]).supplyControlEnabled()
            && ISupplyContoller(supplyController[_token]).paramsSet()) {
                _updateSupplyRatio(_token);
        }

        return _payout;
    }

    /**
     * @notice allow approved address to deposit reserve token for available PANA. No new PANA is minted.
     * @param _amount uint256
     * @param _token address
     * @return send_ uint256
     */
    function depositForRedemption(uint _amount, address _token) external override returns (uint256 send_) {
        require(permissions[STATUS.RESERVETOKEN][_token], notAccepted);
        require(permissions[STATUS.PANAREDEEMER][msg.sender], notApproved);

        // redemption is always calculated as 1:100
        send_ = tokenValue(_token, _amount);
        require(send_ <= availableForRedemption(), "Not enough PANA reserves");
       
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(PANA).safeTransfer(msg.sender, send_);

        emit DepositForRedemption(_token, _amount, send_);
    }

    /**
     * @notice  executes loss ratio management
     * @dev     this function is for internal usage, it expects all required checks to be performed before a call
     * @param   _lpToken a target liquidity token
     */
    function _updateSupplyRatio(address _lpToken) internal {
        ISupplyContoller controller = ISupplyContoller(supplyController[_lpToken]);

        (uint256 pana, uint256 slp, bool burn) = controller.getSupplyControlAmount();
        if (pana > 0) {
            if (burn) {
                // send LP tokens to supplyController and burn liquidity
                uint256 toBurn = IERC20(_lpToken).balanceOf(address(this));
                if (toBurn > slp) {
                    toBurn = slp;
                }

                IERC20(_lpToken).safeTransfer(address(controller), toBurn);
                controller.burn(toBurn);
            } else {
                // send PANA to supplyController and add liquidity
                uint256 toAdd = IERC20(PANA).balanceOf(address(this));
                if (toAdd > pana) {
                    toAdd = pana;
                }

                IERC20(PANA).safeTransfer(address(controller), toAdd);
                controller.add(toAdd);
            }
        }
    }

    /**
     * @notice  externally called version of _updateSupplyRatio
     * @dev     performs additional configuration checks and reverts if any condition fails
     * @param   _lpToken a target liquidity token
     */
    function updateSupplyRatio(address _lpToken) external {
        require(permissions[STATUS.LIQUIDITYTOKEN][_lpToken], "Not an LP token");
        require(supplyController[_lpToken] != address(0), "Supply controller is not configured");
        require(ISupplyContoller(supplyController[_lpToken]).supplyControlEnabled(), "Supply controller is not enabled");
        require(ISupplyContoller(supplyController[_lpToken]).paramsSet(), "Supply controller is not initialized");

        _updateSupplyRatio(_lpToken);
    }
    
    /**
     * @notice allow approved Assurance/Parametrics Insurance NFT Treasury to mint Pana from Master Treasury.
     * @param _amount uint256 amount of Pana to mint
     */
    function mintForNFTTreasury(uint256 _amount) external {
        require(permissions[STATUS.NFTTREASURY][msg.sender], notApproved);
        PANA.mint(msg.sender, _amount);
        emit MintedForNFTTreasury(_amount, msg.sender);
    }

    /**
     * @notice allow approved address to withdraw assets
     * @param _token address
     * @param _amount uint256
     */
    function manage(address _token, uint256 _amount) external override {
        if (permissions[STATUS.LIQUIDITYTOKEN][_token]) {
            require(permissions[STATUS.LIQUIDITYMANAGER][msg.sender], notApproved);
        } else {
            require(permissions[STATUS.RESERVEMANAGER][msg.sender], notApproved);
        }

        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Managed(_token, _amount);
    }

    /**
     * @notice mint new PANA
     * @param _recipient address
     * @param _amount uint256
     */
    function mint(address _recipient, uint256 _amount) external override {
        require(permissions[STATUS.REWARDMANAGER][msg.sender], notApproved);
        PANA.mint(_recipient, _amount);
        emit Minted(msg.sender, _recipient, _amount);
    }

    /**
     * @notice sets new PANA redemption limit
     * @param _limit percentage (as a decimal with 4 precision digits) of PANA balance available for redemption
     */
    function setRedemptionLimit(uint256 _limit) external onlyGovernor {
        require(_limit <= 10000, "Limit cannot exceed 100 percent");
        redemptionLimit = _limit;
    }

    /**
     * @notice enable permission from queue
     * @param _status STATUS
     * @param _address address
     * @param _supplyController address
     */
    function enable(
        STATUS _status,
        address _address,
        address _supplyController
    ) external onlyGovernor {
        require(timelockEnabled == false, "Use queueTimelock");
        if (_status == STATUS.SPANA) {
            sPANA = IsPana(_address);
        } else {
            permissions[_status][_address] = true;

            if (_status == STATUS.LIQUIDITYTOKEN) {
                supplyController[_address] = _supplyController;
            }

            (bool registered, ) = indexInRegistry(_address, _status);
            if (!registered) {
                registry[_status].push(_address);
            }
        }
        emit Permissioned(_address, _status, true);
    }

    /**
     *  @notice disable permission from address
     *  @param _status STATUS
     *  @param _toDisable address
     */
    function disable(STATUS _status, address _toDisable) external {
        require(msg.sender == authority.governor() || msg.sender == authority.guardian(), "Only governor or guardian");
        permissions[_status][_toDisable] = false;
        emit Permissioned(_toDisable, _status, false);
    }

    /**
     * @notice check if registry contains address
     * @return (bool, uint256)
     */
    function indexInRegistry(address _address, STATUS _status) public view returns (bool, uint256) {
        address[] memory entries = registry[_status];
        for (uint256 i = 0; i < entries.length; i++) {
            if (_address == entries[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    /* ========== TIMELOCKED FUNCTIONS ========== */

    // functions are used prior to enabling on-chain governance

    /**
     * @notice queue address to receive permission
     * @param _status STATUS
     * @param _address address
     * @param _supplyController address
     */
    function queueTimelock(
        STATUS _status,
        address _address,
        address _supplyController
    ) external onlyGovernor {
        require(_address != address(0));
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        uint256 timelock = block.number.add(blocksNeededForQueue);
        if (_status == STATUS.RESERVEMANAGER || _status == STATUS.LIQUIDITYMANAGER) {
            timelock = block.number.add(blocksNeededForQueue.mul(2));
        }
        permissionQueue.push(
            Queue({managing: _status, toPermit: _address, supplyController: _supplyController, timelockEnd: timelock, nullify: false, executed: false})
        );
        emit PermissionQueued(_status, _address);
    }

    /**
     *  @notice enable queued permission
     *  @param _index uint256
     */
    function execute(uint256 _index) external {
        require(timelockEnabled == true, "Timelock is disabled, use enable");

        Queue memory info = permissionQueue[_index];

        require(!info.nullify, "Action has been nullified");
        require(!info.executed, "Action has already been executed");
        require(block.number >= info.timelockEnd, "Timelock not complete");

        if (info.managing == STATUS.SPANA) {
            // 9
            sPANA = IsPana(info.toPermit);
        } else {
            permissions[info.managing][info.toPermit] = true;

            if (info.managing == STATUS.LIQUIDITYTOKEN) {
                supplyController[info.toPermit] = info.supplyController;
            }
            (bool registered, ) = indexInRegistry(info.toPermit, info.managing);
            if (!registered) {
                registry[info.managing].push(info.toPermit);

                if (info.managing == STATUS.LIQUIDITYTOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.RESERVETOKEN);
                    if (reg) {
                        delete registry[STATUS.RESERVETOKEN][index];
                    }
                } else if (info.managing == STATUS.RESERVETOKEN) {
                    (bool reg, uint256 index) = indexInRegistry(info.toPermit, STATUS.LIQUIDITYTOKEN);
                    if (reg) {
                        delete registry[STATUS.LIQUIDITYTOKEN][index];
                    }
                }
            }
        }
        permissionQueue[_index].executed = true;
        emit Permissioned(info.toPermit, info.managing, true);
    }

    /**
     * @notice cancel timelocked action
     * @param _index uint256
     */
    function nullify(uint256 _index) external onlyGovernor {
        permissionQueue[_index].nullify = true;
    }

    /**
     * @notice disables timelocked functions
     */
    function disableTimelock() external onlyGovernor {
        require(timelockEnabled == true, "timelock already disabled");
        if (onChainGovernanceTimelock != 0 && onChainGovernanceTimelock <= block.number) {
            timelockEnabled = false;
        } else {
            onChainGovernanceTimelock = block.number.add(blocksNeededForQueue.mul(7)); // 7-day timelock
        }
    }

    /**
     * @notice enables timelocks after initilization
     */
    function initialize() external onlyGovernor {
        require(initialized == false, "Already initialized");
        timelockEnabled = true;
        initialized = true;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns PANA valuation of asset as 1:100
     * The protocol has no intrinsic valuation for external tokens
     * This function values any given asset at 100 PANA
     * Only to be used for valuation of RESERVE TOKENS
     * Not to be used to valuate LP tokens
     * @param _token address
     * @param _amount uint256
     * @return value_ uint256
     */
    function tokenValue(address _token, uint256 _amount) public view override returns (uint256 value_) {
        require(permissions[STATUS.RESERVETOKEN][_token], noValuation);

        value_ = _amount.mul(1e11).mul(10**IERC20Metadata(address(PANA)).decimals())
                            .div(10**9).div(10**IERC20Metadata(_token).decimals());
    }

    /**
     * @notice returns supply metric
     * @dev use this any time you need to query supply
     * @return uint256
     */
    function baseSupply() external view override returns (uint256) {
        return PANA.totalSupply();
    }

    /**
     * @notice returns current amount of PANA available for redemption
     * @return uint256
     */
    function availableForRedemption() public view returns (uint256) {
        return PANA.balanceOf(address(this)).mul(redemptionLimit).div(10**4);
    }
}