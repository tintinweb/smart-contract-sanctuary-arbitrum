// SPDX-License-Identifier: AGPL V3.0
pragma solidity 0.8.4;

import "ERC20Upgradeable.sol";
import "IERC20.sol";
import "SafeERC20.sol";

import "PausableUpgradeable.sol";
import "ReentrancyGuardUpgradeable.sol";

import "OwnableUpgradeable.sol";
import "Math.sol";

import "IStrategy.sol";

/**
 * @title  BasisVault
 * @author akropolis.io
 * @notice A vault used as the management system for a basis trading protocol
 */
contract BasisVault is
    ERC20Upgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeERC20 for IERC20;
    using Math for uint256;

    // token used as the vault's underlying currency
    IERC20 public want;
    // total amount of want that can be deposited in the vault
    uint256 public depositLimit;
    // total amount of want lent out to strategies to perform yielding activities
    uint256 public totalLent;
    // last time the vault was updated
    uint256 public lastUpdate;
    // MAX_BPS
    uint256 public constant MAX_BPS = 10_000;
    // Seconds in a year, taken from yearn
    uint256 public constant SECS_PER_YEAR = 31_556_952;
    // strat address
    address public strategy;
    // management fee
    uint256 public managementFee;
    // performance fee
    uint256 public performanceFee;
    // fee recipient
    address public protocolFeeRecipient;
    // what is the addresses current deposit
    mapping(address => uint256) public userDeposit;
    // individual cap per depositor
    uint256 public individualDepositLimit;

    bool public limitActivate = true; // rename to limitActive

    // modifier to check that the caller is the strategy
    modifier onlyStrategy() {
        require(msg.sender == strategy, "!strategy");
        _;
    }

    function initialize(
        address _want,
        uint256 _depositLimit,
        uint256 _individualDepositLimit
    ) public initializer {
        __ERC20_init("akBVUSDC-ETH", "akBasisVault-USDC-ETH");
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        require(_want != address(0), "!_want");
        want = IERC20(_want);
        depositLimit = _depositLimit;
        individualDepositLimit = _individualDepositLimit;
        protocolFeeRecipient = msg.sender;
    }

    /**********
     * EVENTS *
     **********/

    event StrategyUpdated(address indexed strategy); // maybe need to rename because we also have StrategyUpdate event
    event DepositLimitUpdated(uint256 depositLimit);
    event MaxLossUpdated(uint256 maxLoss); // unused
    event Deposit(address indexed user, uint256 deposit, uint256 shares);
    event Withdraw(address indexed user, uint256 withdrawal, uint256 shares);
    event StrategyUpdate(uint256 profitOrLoss, bool isLoss, uint256 toDeposit);
    event VaultLimited(bool _state); // unused
    event ProtocolFeesUpdated(
        uint256 oldManagementFee,
        uint256 newManagementFee,
        uint256 oldPerformanceFee,
        uint256 newPerformanceFee
    );
    event ProtocolFeeRecipientUpdated(
        address oldRecipient,
        address newRecipient
    );
    event ProtocolFeesIssued(uint256 wantAmount, uint256 sharesIssued);
    event IndividualCapChanged(uint256 oldState, uint256 newState); // rename to IndividualCapUpdated

    /***********
     * SETTERS *
     ***********/

    /**
     * @notice  set the size of the individual cap
     * @param   _individualDepositLimit uint256 for setting the individual cap
     * @dev     only callable by owner
     */
    function setIndividualCap(uint256 _individualDepositLimit)
        external
        onlyOwner
    {
        emit IndividualCapChanged(
            individualDepositLimit,
            _individualDepositLimit
        );
        individualDepositLimit = _individualDepositLimit;
    }

    /**
     * @notice  set the maximum amount that can be deposited in the vault
     * @param   _depositLimit amount of want allowed to be deposited
     * @dev     only callable by owner
     */
    function setDepositLimit(uint256 _depositLimit) external onlyOwner {
        depositLimit = _depositLimit;
        emit DepositLimitUpdated(_depositLimit);
    }

    /**
     * @notice  set the strategy associated with the vault
     * @param   _strategy address of the strategy
     * @dev     only callable by owner
     */
    function setStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "!_strategy");
        strategy = _strategy;
        emit StrategyUpdated(_strategy);
    }

    /**
     * @notice function to set the protocol management and performance fees
     * @param  _performanceFee the fee applied for the strategies performance
     * @param  _managementFee the fee applied for the strategies management
     * @dev    only callable by the owner
     */
    function setProtocolFees(uint256 _performanceFee, uint256 _managementFee)
        external
        onlyOwner
    {
        require(_performanceFee < MAX_BPS, "!_performanceFee");
        require(_managementFee < MAX_BPS, "!_managementFee");
        emit ProtocolFeesUpdated(
            managementFee,
            _managementFee,
            performanceFee,
            _performanceFee
        );
        performanceFee = _performanceFee;
        managementFee = _managementFee;
    }

    /**
     * @notice function to set the protocol fee recipient
     * @param  _newRecipient the recipient of protocol fees
     * @dev    only callable by the owner
     */
    function setProtocolFeeRecipient(address _newRecipient) external onlyOwner {
        emit ProtocolFeeRecipientUpdated(protocolFeeRecipient, _newRecipient);
        protocolFeeRecipient = _newRecipient;
    }

    /**
     * @notice pause the vault
     * @dev    only callable by the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the vault
     * @dev    only callable by the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function setLimitState() external onlyOwner {
        limitActivate = !limitActivate;
        // add event
    }

    /**********************
     * EXTERNAL FUNCTIONS *
     **********************/

    /**
     * @notice  deposit function - where users can join the vault and
     *          receive shares in the vault proportional to their ownership
     *          of the funds.
     * @param  _amount    amount of want to be deposited
     * @param  _recipient recipient of the shares as the recipient may not
     *                    be the sender
     * @return shares the amount of shares being minted to the recipient
     *                for their deposit
     */
    // add overload with recipient==msg.sender
    function deposit(uint256 _amount, address _recipient)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 shares)
    {
        require(_amount > 0, "!_amount");
        require(_recipient != address(0), "!_recipient");
        if (limitActivate == true) {
            require(totalAssets() + _amount <= depositLimit, "!depositLimit");
            require(
                userDeposit[msg.sender] + _amount <= individualDepositLimit,
                "user cap reached"
            );
        }

        // update their deposit amount
        userDeposit[msg.sender] += _amount; // maybe need to update limit in withdraw function

        shares = _issueShares(_amount, _recipient);
        // transfer want to the vault
        want.safeTransferFrom(msg.sender, address(this), _amount);

        emit Deposit(_recipient, _amount, shares);
    }

    /**
     * @notice  withdraw function - where users can exit their positions in a vault
     *          users provide an amount of shares that will be returned to a recipient.
     * @param  _shares    amount of shares to be redeemed
     * @param  _recipient recipient of the amount as the recipient may not
     *                    be the sender
     * @return amount the amount being withdrawn for the shares redeemed
     */
    // add overload with recipient==msg.sender
    function withdraw(
        uint256 _shares,
        uint256 _maxLoss,
        address _recipient
    ) external nonReentrant whenNotPaused returns (uint256 amount) {
        require(_shares > 0, "!_shares");
        require(_shares <= balanceOf(msg.sender), "insufficient balance");
        amount = _calcShareValue(_shares);
        uint256 vaultBalance = want.balanceOf(address(this));
        uint256 loss; // move inside `if (amount > vaultBalance) {}`

        // if the vault doesnt have free funds then funds should be taken from the strategy
        if (amount > vaultBalance) {
            uint256 needed = amount - vaultBalance;
            needed = Math.min(needed, totalLent); // ?
            uint256 withdrawn;
            (loss, withdrawn) = IStrategy(strategy).withdraw(needed);
            vaultBalance = want.balanceOf(address(this));
            if (loss > 0) {
                require(loss <= _maxLoss, "loss more than expected");
                amount = vaultBalance; // ? maybe Math.min(amount, vaultBalance)
                totalLent -= loss;
                // remove unused code
                // all assets have been withdrawn so now the vault must deal with the loss in the share calculation
                // _shares = _sharesForAmount(amount);
            }
            // reduce the totallent by the amount withdrawn, if the amount withdrawn is greater than the totallent
            // then make it 0
            if (totalLent >= withdrawn) {
                totalLent -= withdrawn;
            } else {
                totalLent = 0;
            }
        }

        _burn(msg.sender, _shares);
        if (amount > vaultBalance) {
            amount = vaultBalance;
        }
        emit Withdraw(_recipient, amount, _shares);
        want.safeTransfer(_recipient, amount);
    }

    /**
     * @notice function to update the state of the strategy in the vault and pull any funds to be redeposited
     * @param  _amount change in the vault amount sent by the strategy
     * @param  _loss   whether the change is negative or not
     *                 be the sender
     * @return toDeposit the amount to be deposited in to the strategy on this update
     */
    function update(uint256 _amount, bool _loss)
        external
        onlyStrategy
        returns (uint256 toDeposit)
    {
        // if a loss was recorded then decrease the totalLent by the amount, otherwise increase the totalLent
        if (_loss) {
            totalLent -= _amount;
        } else {
            _determineProtocolFees(_amount);
            totalLent += _amount;
        }
        // increase the totalLent by the amount of deposits that havent yet been sent to the vault
        toDeposit = want.balanceOf(address(this));
        totalLent += toDeposit;
        lastUpdate = block.timestamp;
        emit StrategyUpdate(_amount, _loss, toDeposit);
        if (toDeposit > 0) {
            want.safeTransfer(msg.sender, toDeposit);
        }
    }

    /**********************
     * INTERNAL FUNCTIONS *
     **********************/

    /**
     * @dev     function for handling share issuance during a deposit
     * @param  _amount    amount of want to be deposited
     * @param  _recipient recipient of the shares as the recipient may not
     *                    be the sender
     * @return shares the amount of shares being minted to the recipient
     *                for their deposit
     */
    function _issueShares(uint256 _amount, address _recipient)
        internal
        returns (uint256 shares)
    {
        // use internal function _calcSharesIssuable(_amount)
        if (totalSupply() > 0) {
            // if there is supply then mint according to the proportion of the pool
            require(totalAssets() > 0, "totalAssets == 0"); // duplicated condition
            shares = (_amount * totalSupply()) / totalAssets();
        } else {
            // if there is no supply mint 1 for 1
            shares = _amount;
        }
        _mint(_recipient, shares);
    }

    /**
     * @dev     function for handling share issuance viewing during a deposit
     * @param  _amount    amount of want to be deposited
     * @return shares the amount of shares being minted to the recipient
     *                for their deposit
     */
    function _calcSharesIssuable(uint256 _amount)
        internal
        view
        returns (uint256 shares)
    {
        if (totalSupply() > 0) {
            // if there is supply then mint according to the proportion of the pool
            require(totalAssets() > 0, "totalAssets == 0"); // duplicated condition
            shares = (_amount * totalSupply()) / totalAssets();
        } else {
            // if there is no supply mint 1 for 1
            shares = _amount;
        }
    }

    /**
     * @dev     function for determining the value of a share of the vault
     * @param  _shares    amount of shares to convert
     * @return the value of the inputted amount of shares in want
     */
    function _calcShareValue(uint256 _shares) internal view returns (uint256) {
        if (totalSupply() == 0) {
            return _shares;
        }
        return (_shares * totalAssets()) / totalSupply();
    }

    /**
     * @dev    function for determining the amount of shares for a specific amount
     * @param  _amount amount of want to convert to shares
     * @return the value of the inputted amount of shares in want
     */
    function _sharesForAmount(uint256 _amount) internal view returns (uint256) {
        if (totalAssets() > 0) {
            return ((_amount * totalSupply()) / totalAssets());
        } else {
            return 0;
        }
    }

    /**
     * @dev    function for determining the performance and management fee of the vault
     * @param  gain the profits to determine the fees from
     * @return feeAmount the fees taken from the gain
     */
    function _determineProtocolFees(uint256 gain)
        internal
        returns (uint256 feeAmount)
    {
        if (gain == 0) {
            return 0;
        }
        uint256 reward;
        uint256 duration = block.timestamp - lastUpdate;
        require(duration > 0, "!duration"); // maybe don't need
        uint256 performance = (gain * performanceFee) / MAX_BPS;
        uint256 management = ((totalLent * duration * managementFee) /
            MAX_BPS) / SECS_PER_YEAR;
        feeAmount = performance + management;
        if (feeAmount > gain) {
            feeAmount = gain;
        }
        if (feeAmount > 0) {
            reward = _issueShares(feeAmount, protocolFeeRecipient);
        }
        emit ProtocolFeesIssued(feeAmount, reward);
    }

    /***********
     * GETTERS *
     ***********/

    // useless function
    function expectedLoss(uint256 _shares) public view returns (uint256 loss) {
        uint256 strategyBalance = want.balanceOf(strategy);
        uint256 vaultBalance = want.balanceOf(address(this));
        uint256 amount = _calcShareValue(_shares);
        if (amount > vaultBalance) {
            uint256 needed = amount - vaultBalance;
            if (needed > strategyBalance) {
                loss = needed - strategyBalance;
            } else {
                loss = 0;
            }
        }
    }

    /**
     * @notice get the total assets held in the vault including funds lent to the strategy
     * @return total assets in want available in the vault
     */
    function totalAssets() public view returns (uint256) {
        return want.balanceOf(address(this)) + totalLent;
    }

    /**
     * @notice get the price per vault share
     * @return the price per share in want
     */
    function pricePerShare() public view returns (uint256) {
        uint8 decimal = decimals();
        return _calcShareValue(10**decimal);
    }

    /**
     * @notice  view deposit function - where users can join the vault and
     *          receive shares in the vault proportional to their ownership
     *          of the funds.
     * @param  _amount    amount of want to be deposited
     * @return shares the amount of shares being minted to the recipient
     *                for their deposit
     */
    function calcSharesIssuable(uint256 _amount)
        external
        view
        returns (uint256 shares)
    {
        require(_amount > 0, "!_amount");
        require(totalAssets() + _amount <= depositLimit, "!depositLimit"); // maybe don't needed

        shares = _calcSharesIssuable(_amount);
    }

    /**
     * @notice  view withdraw function - where users can exit their positions in a vault
     *          users provide an amount of shares that will be returned to a recipient.
     * @param  _shares    amount of shares to be redeemed
     * @return amount the amount being withdrawn for the shares redeemed
     */
    function calcWithdrawIssuable(uint256 _shares)
        external
        view
        returns (uint256 amount)
    {
        amount = _calcShareValue(_shares);
    }

    function decimals() public view override returns (uint8) {
        return ERC20Upgradeable(address(want)).decimals();
    }
}