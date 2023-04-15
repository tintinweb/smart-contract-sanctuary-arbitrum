// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/core/IVaultAccessControlRegistry.sol";

pragma solidity ^0.8.4;

contract AccessControlBase is Context {
    IVaultAccessControlRegistry public immutable registry;
    address public immutable timelockAddressImmutable;

    constructor(
        address _vaultRegistry,
        address _timelock
    ) {
        registry = IVaultAccessControlRegistry(_vaultRegistry);
        timelockAddressImmutable = _timelock;
    }

    /*==================== Managed in VaultAccessControlRegistry *====================*/

    modifier onlyGovernance() {
        require(
            registry.isCallerGovernance(_msgSender()),
            "Forbidden: Only Governance"
        );
        _;
    }

    modifier onlyManager() {
        require(
            registry.isCallerManager(_msgSender()),
            "Forbidden: Only Manager"
        );
        _;
    }

    modifier onlyEmergency() {
        require(
            registry.isCallerEmergency(_msgSender()),
            "Forbidden: Only Emergency"
        );
        _;
    }

    modifier protocolNotPaused() {
        require(
            !registry.isProtocolPaused(),
            "Forbidden: Protocol Paused"
        );
        _;
    }

    /*==================== Managed in WINRTimelock *====================*/

    modifier onlyTimelockGovernance() {
        address timelockActive_;
        if(!registry.timelockActivated()) {
            // the flip is not switched yet, so this means that the governance address can still pass the onlyTimelockGoverance modifier
            timelockActive_ = registry.governanceAddress();
        } else {
            // the flip is switched, the immutable timelock is now locked in as the only adddress that can pass this modifier (and nothing can undo that)
            timelockActive_ = timelockAddressImmutable;
        }
        require(
            _msgSender() == timelockActive_,
            "Forbidden: Only TimelockGovernance"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/IAccessControl.sol";

pragma solidity >=0.6.0 <0.9.0;

interface IVaultAccessControlRegistry is IAccessControl {
    function timelockActivated() external view returns(bool);
    function governanceAddress() external view returns(address);
    function pauseProtocol() external;
    function unpauseProtocol() external;
    function isCallerGovernance(address _account) external view returns (bool);
    function isCallerManager(address _account) external view returns (bool);
    function isCallerEmergency(address _account) external view returns (bool);
    function isProtocolPaused() external view returns (bool);
    function changeGovernanceAddress(address _governanceAddress) external;

    /*==================== Events WINR  *====================*/

    event DeadmanSwitchFlipped();
    event GovernanceChange(
        address newGovernanceAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;

interface IMintable {

    event MinterSet(
        address minterAddress,
        bool isActive
    );

    function isMinter(address _account) external returns (bool);
    function setMinter(address _minter, bool _isActive) external;
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IBaseFDT.sol";
import "./math/SafeMath.sol";
import "./math/SignedSafeMath.sol";
import "./math/SafeMathUint.sol";
import "./math/SafeMathInt.sol";

/// @title BasicFDT implements base level FDT functionality for accounting for revenues.
abstract contract BasicFDT is IBaseFDT, ERC20 {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;
    
    uint256 internal constant pointsMultiplier = 2 ** 128;

    // storage for WLP token rewards
    uint256 internal pointsPerShare_WLP;
    mapping(address => int256)  internal pointsCorrection_WLP;
    mapping(address => uint256) internal withdrawnFunds_WLP;

    // storage for VWINR token rewards
    uint256 internal pointsPerShare_VWINR;
    mapping(address => int256)  internal pointsCorrection_VWINR;
    mapping(address => uint256) internal withdrawnFunds_VWINR;

    // events WLP token rewards
    event   PointsPerShareUpdated_WLP(uint256 pointsPerShare_WLP);
    event PointsCorrectionUpdated_WLP(address indexed account, int256 pointsCorrection_WLP);

    // events VWINR token rewards
    event PointsPerShareUpdated_VWINR(uint256 pointsPerShare_VWINR);
    event PointsCorrectionUpdated_VWINR(address indexed account, int256 pointsCorrection_VWINR);

    constructor(string memory name, string memory symbol) ERC20(name, symbol)  { }

    // ADDED FUNCTION BY GHOST

    /**
     * The WLP on this contract (so that is WLP that has to be disbtributed as rewards, doesn't belong the the WLP that can claim this same WLp). To prevent the dust accumulation of WLP on this contract, we should deduct the balance of WLP on this contract from totalSupply, otherwise the pointsPerShare_WLP will make pointsPerShare_WLP lower as it should be
     */
    function correctedTotalSupply() public view returns(uint256) {
        return (totalSupply() - balanceOf(address(this)));
    }

    /**
        @dev Distributes funds to token holders.
        @dev It reverts if the total supply of tokens is 0.
        @dev It emits a `FundsDistributed` event if the amount of received funds is greater than 0.
        @dev It emits a `PointsPerShareUpdated` event if the amount of received funds is greater than 0.
             About undistributed funds:
                In each distribution, there is a small amount of funds which do not get distributed,
                   which is `(value  pointsMultiplier) % totalSupply()`.
                With a well-chosen `pointsMultiplier`, the amount funds that are not getting distributed
                   in a distribution can be less than 1 (base unit).
                We can actually keep track of the undistributed funds in a distribution
                   and try to distribute it in the next distribution.
    */
    function _distributeFunds_WLP(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        /**
         * todo probably should deduct the balance of WLP on this contract from totalSupply, otherwise the pointsPerShare_WLP will make pointsPerShare_WLP lower as it should be
         */

        uint256 correctedTotalSupply_ = correctedTotalSupply();

        pointsPerShare_WLP = pointsPerShare_WLP.add(value.mul(pointsMultiplier) / correctedTotalSupply_);
        emit FundsDistributed_WLP(msg.sender, value);
        emit PointsPerShareUpdated_WLP(pointsPerShare_WLP);
    }

    function _distributeFunds_VWINR(uint256 value) internal {
        require(totalSupply() > 0, "FDT:ZERO_SUPPLY");

        if (value == 0) return;

        uint256 correctedTotalSupply_ = correctedTotalSupply();

        pointsPerShare_VWINR = pointsPerShare_VWINR.add(value.mul(pointsMultiplier) / correctedTotalSupply_);
        emit FundsDistributed_VWINR(msg.sender, value);
        emit PointsPerShareUpdated_VWINR(pointsPerShare_VWINR);
    }

    /**
        @dev    Prepares the withdrawal of funds.
        @dev    It emits a `FundsWithdrawn_WLP` event if the amount of withdrawn funds is greater than 0.
        @return withdrawableDividend_WLP The amount of dividend funds that can be withdrawn.
    */
    function _prepareWithdraw_WLP() internal returns (uint256 withdrawableDividend_WLP) {
        withdrawableDividend_WLP = withdrawableFundsOf_WLP(msg.sender);
        uint256 _withdrawnFunds_WLP = withdrawnFunds_WLP[msg.sender].add(withdrawableDividend_WLP);
        withdrawnFunds_WLP[msg.sender] = _withdrawnFunds_WLP;
        emit FundsWithdrawn_WLP(msg.sender, withdrawableDividend_WLP, _withdrawnFunds_WLP);
    }

    function _prepareWithdraw_VWINR() internal returns(uint256 withdrawableDividend_VWINR) {
        withdrawableDividend_VWINR = withdrawableFundsOf_VWINR(msg.sender);
        uint256 _withdrawnFunds_VWINR = withdrawnFunds_VWINR[msg.sender].add(withdrawableDividend_VWINR);
        withdrawnFunds_VWINR[msg.sender] = _withdrawnFunds_VWINR;
        emit FundsWithdrawn_VWINR(msg.sender, withdrawableDividend_VWINR, _withdrawnFunds_VWINR);
    }

    /**
        @dev    Returns the amount of funds that an account can withdraw.
        @param  _owner The address of a token holder.
        @return The amount funds that `_owner` can withdraw.
    */
    function withdrawableFundsOf_WLP(address _owner) public view returns (uint256) {
        return accumulativeFundsOf_WLP(_owner).sub(withdrawnFunds_WLP[_owner]);
    }

    function withdrawableFundsOf_VWINR(address _owner) public view returns (uint256) {
        return accumulativeFundsOf_VWINR(_owner).sub(withdrawnFunds_VWINR[_owner]);
    }

    /**
        @dev    Returns the amount of funds that an account has withdrawn.
        @param  _owner The address of a token holder.
        @return The amount of funds that `_owner` has withdrawn.
    */
    function withdrawnFundsOf_WLP(address _owner) external view returns (uint256) {
        return withdrawnFunds_WLP[_owner];
    }

    function withdrawnFundsOf_VWINR(address _owner) external view returns (uint256) {
        return withdrawnFunds_VWINR[_owner];
    }

    /**
        @dev    Returns the amount of funds that an account has earned in total.
        @dev    accumulativeFundsOf_WLP(_owner) = withdrawableFundsOf_WLP(_owner) + withdrawnFundsOf_WLP(_owner)
                                         = (pointsPerShare_WLP * balanceOf(_owner) + pointsCorrection_WLP[_owner]) / pointsMultiplier
        @param  _owner The address of a token holder.
        @return The amount of funds that `_owner` has earned in total.
    */
    function accumulativeFundsOf_WLP(address _owner) public view returns (uint256) {
        return
            pointsPerShare_WLP
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection_WLP[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    function accumulativeFundsOf_VWINR(address _owner) public view returns (uint256) {
        return
            pointsPerShare_VWINR
                .mul(balanceOf(_owner))
                .toInt256Safe()
                .add(pointsCorrection_VWINR[_owner])
                .toUint256Safe() / pointsMultiplier;
    }

    /**
        @dev   Transfers tokens from one account to another. Updates pointsCorrection_WLP to keep funds unchanged.
        @dev   It emits two `PointsCorrectionUpdated` events, one for the sender and one for the receiver.
        @param from  The address to transfer from.
        @param to    The address to transfer to.
        @param value The amount to be transferred.
    */
    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual override {
        super._transfer(from, to, value);

        // storage for WLP token rewards
        int256 _magCorrection_WLP       = pointsPerShare_WLP.mul(value).toInt256Safe();
        int256 pointsCorrectionFrom_WLP = pointsCorrection_WLP[from].add(_magCorrection_WLP);
        pointsCorrection_WLP[from]      = pointsCorrectionFrom_WLP;
        int256 pointsCorrectionTo_WLP   = pointsCorrection_WLP[to].sub(_magCorrection_WLP);
        pointsCorrection_WLP[to]        = pointsCorrectionTo_WLP;

        // storage for VWINR token rewards
        int256 _magCorrection_VWINR = pointsPerShare_VWINR.mul(value).toInt256Safe();
        int256 pointsCorrectionFrom_VWINR = pointsCorrection_VWINR[from].add(_magCorrection_VWINR);
        pointsCorrection_VWINR[from] = pointsCorrectionFrom_VWINR;
        int256 pointsCorrectionTo_VWINR = pointsCorrection_VWINR[to].sub(_magCorrection_VWINR);
        pointsCorrection_VWINR[to] = pointsCorrectionTo_VWINR;

        emit PointsCorrectionUpdated_WLP(from, pointsCorrectionFrom_WLP);
        emit PointsCorrectionUpdated_WLP(to,   pointsCorrectionTo_WLP);

        emit PointsCorrectionUpdated_VWINR(from, pointsCorrectionFrom_VWINR);
        emit PointsCorrectionUpdated_VWINR(to,  pointsCorrectionTo_VWINR);
    }

    /**
        @dev   Mints tokens to an account. Updates pointsCorrection_WLP to keep funds unchanged.
        @param account The account that will receive the created tokens.
        @param value   The amount that will be created.
    */
    function _mint(address account, uint256 value) internal virtual override {
        super._mint(account, value);

        int256 _pointsCorrection_WLP = pointsCorrection_WLP[account].sub(
            (pointsPerShare_WLP.mul(value)).toInt256Safe()
        );

        pointsCorrection_WLP[account] = _pointsCorrection_WLP;

        int256 _pointsCorrection_VWINR = pointsCorrection_VWINR[account].sub(
            (pointsPerShare_VWINR.mul(value)).toInt256Safe()
        );

        pointsCorrection_VWINR[account] = _pointsCorrection_VWINR;

        emit PointsCorrectionUpdated_WLP(account, _pointsCorrection_WLP);
        emit PointsCorrectionUpdated_VWINR(account, _pointsCorrection_VWINR);
    }

    /**
        @dev   Burns an amount of the token of a given account. Updates pointsCorrection_WLP to keep funds unchanged.
        @dev   It emits a `PointsCorrectionUpdated` event.
        @param account The account whose tokens will be burnt.
        @param value   The amount that will be burnt.
    */
    function _burn(address account, uint256 value) internal virtual override {
        super._burn(account, value);

        int256 _pointsCorrection_WLP = pointsCorrection_WLP[account].add(
            (pointsPerShare_WLP.mul(value)).toInt256Safe()
        );

        pointsCorrection_WLP[account] = _pointsCorrection_WLP;

        int256 _pointsCorrection_VWINR = pointsCorrection_VWINR[account].add(
            (pointsPerShare_VWINR.mul(value)).toInt256Safe()
        );

        pointsCorrection_VWINR[account] = _pointsCorrection_VWINR;

        emit PointsCorrectionUpdated_WLP(account, _pointsCorrection_WLP);
        emit PointsCorrectionUpdated_VWINR(account, _pointsCorrection_VWINR);
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds_WLP() public virtual override {}

    function withdrawFunds_VWINR() public virtual override {}

    function withdrawFunds() public virtual override {}

    /**
        @dev    Updates the current `fundsToken` balance and returns the difference of the new and previous `fundsToken` balance.
        @return A int256 representing the difference of the new and previous `fundsToken` balance.
    */
    function _updateFundsTokenBalance_WLP() internal virtual returns (int256) {}

    function _updateFundsTokenBalance_VWINR() internal virtual returns (int256) {}

    /**
        @dev Registers a payment of funds in tokens. May be called directly after a deposit is made.
        @dev Calls _updateFundsTokenBalance(), whereby the contract computes the delta of the new and previous
             `fundsToken` balance and increments the total received funds (cumulative), by delta, by calling _distributeFunds_WLP().
    */
    function updateFundsReceived() public virtual {
        int256 newFunds_WLP = _updateFundsTokenBalance_WLP();
        int256 newFunds_VWINR = _updateFundsTokenBalance_VWINR();

        if (newFunds_WLP > 0) {
            _distributeFunds_WLP(newFunds_WLP.toUint256Safe());
        }

        if (newFunds_VWINR > 0) {
            _distributeFunds_VWINR(newFunds_VWINR.toUint256Safe());
        }
    }

    function updateFundsReceived_WLP() public virtual {
        int256 newFunds_WLP = _updateFundsTokenBalance_WLP();

        if (newFunds_WLP > 0) {
            _distributeFunds_WLP(newFunds_WLP.toUint256Safe());
        }
    }

    function updateFundsReceived_VWINR() public virtual {
        int256 newFunds_VWINR = _updateFundsTokenBalance_VWINR();

        if (newFunds_VWINR > 0) {
            _distributeFunds_VWINR(newFunds_VWINR.toUint256Safe());
        }
    }

    function returnPointsCorrection_WLP(address _account) public view returns(int256) {
        return pointsCorrection_WLP[_account];
    } 

    function returnPointsCorrection_VWINR(address _account) public view returns(int256) {
        return pointsCorrection_VWINR[_account];
    }

    function returnWithdrawnFunds_WLP(address _account) public view returns(uint256) {
        return withdrawnFunds_WLP[_account];
    }

    function returnWithdrawnFunds_VWINR(address _account) public view returns(uint256) {
        return withdrawnFunds_VWINR[_account];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BasicFDT.sol";
import "../../interfaces/tokens/wlp/IMintable.sol";
import "../../core/AccessControlBase.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

contract MintableBaseToken is BasicFDT, AccessControlBase, ReentrancyGuard, IMintable {
    using SafeMath       for uint256;
    using SafeMathUint   for uint256;
    using SignedSafeMath for  int256;
    using SafeMathInt    for  int256;

    mapping (address => bool) public override isMinter;
    bool public inPrivateTransferMode;
    mapping (address => bool) public isHandler;
    
    IERC20 public immutable rewardToken_WLP; // 1 The `rewardToken_WLP` (dividends).
    IERC20 public immutable rewardToken_VWINR; // 2 The `rewardToken_VWINR` (dividends).
    
    uint256 public rewardTokenBalance_WLP;   // The amount of `rewardToken_WLP` (Liquidity Asset 1) currently present and accounted for in this contract.
    uint256 public rewardTokenBalance_VWINR;   // The amount of `rewardToken_VWINR` (Liquidity Asset2 ) currently present and accounted for in this contract.

    event SetInfo(
        string name,
        string symbol
    );

    event SetPrivateTransferMode(
        bool inPrivateTransferMode
    );

    event SetHandler(
        address handlerAddress,
        bool isActive
    );

    event WithdrawStuckToken(
        address tokenAddress,
        address receiver,
        uint256 amount
    );

    constructor(
        string memory _name, 
        string memory _symbol,
        address _vwinrAddress,
        address _vaultRegistry, 
        address _timelock) BasicFDT(
            _name,
            _symbol
        ) AccessControlBase(
            _vaultRegistry, 
            _timelock
        ) {
            rewardToken_WLP = IERC20(address(this));
            rewardToken_VWINR = IERC20(_vwinrAddress);
        }

    modifier onlyMinter() {
        require(
            isMinter[_msgSender()], 
            "MintableBaseToken: forbidden"
        );
        _;
    }

    /**
        @dev Withdraws all available funds for a token holder.
    */
    function withdrawFunds_WLP() public nonReentrant virtual override {
        uint256 withdrawableFunds_WLP = _prepareWithdraw_WLP();

        if (withdrawableFunds_WLP > uint256(0)) {
            rewardToken_WLP.transfer(_msgSender(), withdrawableFunds_WLP);

            _updateFundsTokenBalance_WLP();
        }
    }

    function withdrawFunds_VWINR() public nonReentrant virtual override {
        uint256 withdrawableFunds_VWINR = _prepareWithdraw_VWINR();

        if (withdrawableFunds_VWINR > uint256(0)) {
            rewardToken_VWINR.transfer(_msgSender(), withdrawableFunds_VWINR);

            _updateFundsTokenBalance_VWINR();
        }
    }

    function withdrawFunds() public nonReentrant virtual override {
        withdrawFunds_WLP();
        withdrawFunds_VWINR();
    }

    /**
        @dev    Updates the current `rewardToken_WLP` balance and returns the difference of the new and previous `rewardToken_WLP` balance.
        @return A int256 representing the difference of the new and previous `rewardToken_WLP` balance.
    */
    function _updateFundsTokenBalance_WLP() internal virtual override returns (int256) {
        uint256 _prevFundsTokenBalance_WLP = rewardTokenBalance_WLP;

        rewardTokenBalance_WLP = rewardToken_WLP.balanceOf(address(this));

        return int256(rewardTokenBalance_WLP).sub(int256(_prevFundsTokenBalance_WLP));
    }

    function _updateFundsTokenBalance_VWINR() internal virtual override returns (int256) {
        uint256 _prevFundsTokenBalance_VWINR = rewardTokenBalance_VWINR;

        rewardTokenBalance_VWINR = rewardToken_VWINR.balanceOf(address(this));

        return int256(rewardTokenBalance_VWINR).sub(int256(_prevFundsTokenBalance_VWINR));
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        if (inPrivateTransferMode) {
            require(isHandler[_msgSender()], "BaseToken: _msgSender() not whitelisted");
        }
        super._transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function transferFrom(address _from, address _recipient, uint256 _amount) public override returns (bool) {
        if (inPrivateTransferMode) {
            require(isHandler[_msgSender()], "BaseToken: _msgSender() not whitelisted");
        }
        if (isHandler[_msgSender()]) {
            super._transfer(_from, _recipient, _amount);
            return true;
        }
        address spender = _msgSender();
        super._spendAllowance(_from, spender, _amount);
        super._transfer(_from, _recipient, _amount);
        return true;
    }

    function setInPrivateTransferMode(bool _inPrivateTransferMode) external onlyGovernance {
        inPrivateTransferMode = _inPrivateTransferMode;
        emit SetPrivateTransferMode(_inPrivateTransferMode);
    }

    function setHandler(address _handler, bool _isActive) external onlyTimelockGovernance {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setInfo(string memory _name, string memory _symbol) external onlyGovernance {
        _name = _name;
        _symbol = _symbol;
        emit SetInfo(_name, _symbol);
    }

    /**
     * @notice function to service users who accidentally send their tokens to this contract
     * @dev since this function could technically steal users assets we added a timelock modifier
     * @param _token address of the token to be recoved
     * @param _account address the recovered tokens will be sent to
     * @param _amount amount of token to be recoverd
     */
    function withdrawToken(
        address _token, 
        address _account, 
        uint256 _amount) external onlyGovernance {
        IERC20(_token).transfer(_account, _amount);
        emit WithdrawStuckToken(
            _token,
            _account,
            _amount
        );
    }

    function setMinter(address _minter, bool _isActive) external override onlyTimelockGovernance {
        isMinter[_minter] = _isActive;
        emit MinterSet(
            _minter,
            _isActive
        );
    }

    function mint(address _account, uint256 _amount) external nonReentrant override onlyMinter {
        super._mint(_account, _amount);
    }

    function burn(address _account, uint256 _amount) external nonReentrant override onlyMinter {
        super._burn(_account, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./MintableBaseToken.sol";

contract WLP is MintableBaseToken {
    constructor(
        address _vaultRegistry, 
        address _timelock,
        address _vwinrAddress) MintableBaseToken(
            "WINR LP", 
            "WLP", 
            _vwinrAddress, 
            _vaultRegistry, 
            _timelock
        ) {}

    function id() external pure returns (string memory _name) {
        return "WLP";
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IBaseFDT {

    /**
        @dev    Returns the total amount of funds a given address is able to withdraw currently.
        @param  owner Address of FDT holder.
        @return A uint256 representing the available funds for a given account.
    */
    function withdrawableFundsOf_WLP(address owner) external view returns (uint256);

    function withdrawableFundsOf_VWINR(address owner) external view returns (uint256);

    /**
        @dev Withdraws all available funds for a FDT holder.
    */
    function withdrawFunds_WLP() external;

    function withdrawFunds_VWINR() external;

    function withdrawFunds() external;

    /**
        @dev   This event emits when new funds are distributed.
        @param by               The address of the sender that distributed funds.
        @param fundsDistributed_WLP The amount of funds received for distribution.
    */
    event FundsDistributed_WLP(address indexed by, uint256 fundsDistributed_WLP);

    event FundsDistributed_VWINR(address indexed by, uint256 fundsDistributed_VWINR);


    /**
        @dev   This event emits when distributed funds are withdrawn by a token holder.
        @param by             The address of the receiver of funds.
        @param fundsWithdrawn_WLP The amount of funds that were withdrawn.
        @param totalWithdrawn_WLP The total amount of funds that were withdrawn.
    */
    event FundsWithdrawn_WLP(address indexed by, uint256 fundsWithdrawn_WLP, uint256 totalWithdrawn_WLP);

    event FundsWithdrawn_VWINR(address indexed by, uint256 fundsWithdrawn_VWINR, uint256 totalWithdrawn_VWINR);

}

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;
pragma solidity ^0.8.4;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity 0.6.11;
pragma solidity ^0.8.4;

library SafeMathInt {
    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "SMI:NEG");
        return uint256(a);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity 0.6.11;
pragma solidity ^0.8.4;

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256 b) {
        b = int256(a);
        require(b >= 0, "SMU:OOB");
    }
}

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;
pragma solidity ^0.8.4;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}