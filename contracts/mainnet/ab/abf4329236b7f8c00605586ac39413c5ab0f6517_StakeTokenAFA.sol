/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

contract StakeTokenAFA is Context, Ownable {
    //event Deposit(uint256 numberOfDays, uint256 amount, address sender);

    //event Withdraw(address sender, uint256 amountIn, uint256 amountOut);

    address private tokenAddress = 0x2d93b005157a45369Cd7659bA3715806366899e8; //0x0d686E627aD4C6Ae8Ae41D4aAa0d35bA429Ed1ab;

    address private interestPaymentAddress =
        0xa01AF6B266bD68eDfd49AD0bFF7b665f6c53373d; //0x512C25204B317F433CA566670AAb97bc80b30D4c;

    //IBEP20 private bep;

    uint256 private denominator = 1_000_000;

    uint256 private baseRatePerDay = 10_000; //(/1_000_000) = 0.01% per day => ~ 3.65% per year

    uint256 private withdrawBeforeHours = 168; // only accept withdraw after 'withdrawBeforeHours' hours

    uint256 private withdrawBeforeHourFee = 150_000; //(/1_000_000) = 1% => early withdrawal fee

    struct Account {
        uint256 amount;
        uint256 startDate;
        uint256 ratePerDay;
        uint256 endDate;
    }

    struct InterestRate {
        uint256 numberOfDays;
        uint256 ratePerDay;
        uint256 totalStaker;
        uint256 totalToken;
    }

    mapping(address => Account) private vaults;

    mapping(uint256 => InterestRate) private interestRates;

    uint256[] private interestRateDays;

    // bool emergency = false;

    uint256 private totalTokenStake;
    uint256 private totalStaker;

    constructor() {
        require(IBEP20(tokenAddress).totalSupply() > 0);

        //set interest
        // 14 days / 0.03% per day
        interestRates[14].ratePerDay = 10_000; //0.03% per day ~ 10.95% per year
        interestRates[14].numberOfDays = 14;
        interestRateDays.push(14);

        // 30 days / 0.04% per day
        interestRates[30].ratePerDay = 20_000; //0.04% per day ~ 14.6% per year
        interestRates[30].numberOfDays = 30;
        interestRateDays.push(30);
    }

    struct HelperState {
        address tokenAddress;
        uint256 totalTokenStake;
        uint256 withdrawBeforeHours;
        uint256 denominator;
        uint256 baseRatePerDay;
        uint256 withdrawBeforeHourFee;
        address interestPaymentAddress;
        uint256 totalStaker;
    }

    function _state() external view returns (HelperState memory) {
        return
            HelperState({
                tokenAddress: tokenAddress,
                totalTokenStake: totalTokenStake,
                withdrawBeforeHours: withdrawBeforeHours,
                denominator: denominator,
                baseRatePerDay: baseRatePerDay,
                withdrawBeforeHourFee: withdrawBeforeHourFee,
                interestPaymentAddress: interestPaymentAddress,
                totalStaker: totalStaker
            });
    }

    function addInterestRate(uint256 _numberOfDays, uint256 _ratePerDay)
        external
        onlyOwner
    {
        require(_numberOfDays > 0, "_");
        require(_ratePerDay > 0, "_");
        interestRates[_numberOfDays].ratePerDay = _ratePerDay;
        interestRates[_numberOfDays].numberOfDays = _numberOfDays;
        if (!_exist(interestRateDays, _numberOfDays)) {
            interestRateDays.push(_numberOfDays);
        }
    }

    function getInterestRates()
        external
        view
        returns (InterestRate[] memory _interestRates)
    {
        return _getInterestRates();
    }

    function _getInterestRates()
        internal
        view
        returns (InterestRate[] memory _interestRates)
    {
        InterestRate[] memory result = new InterestRate[](
            interestRateDays.length
        );

        for (uint256 i = 0; i < interestRateDays.length; ) {
            result[i] = interestRates[interestRateDays[i]];
            unchecked {
                i++;
            }
        }

        return result;
    }

    function getAccount(address _account)
        external
        view
        returns (
            Account memory account,
            uint256 endPeriodProfit,
            uint256 profit
        )
    {
        return (
            vaults[_account],
            _endPeriodProfit(_account),
            _profit(_account, true)
        );
    }

    function setWithdrawBeforeHours(uint256 _withdrawBeforeHours)
        external
        onlyOwner
    {
        require(_withdrawBeforeHours >= 0, "_");
        withdrawBeforeHours = _withdrawBeforeHours;
    }

    function setWithdrawBeforeHourFee(uint256 _withdrawBeforeHourFee)
        external
        onlyOwner
    {
        require(_withdrawBeforeHourFee >= 0, "_");
        withdrawBeforeHourFee = _withdrawBeforeHourFee;
    }

    function deposit(uint256 _numberOfDays, uint256 _amount) external {
        require(_amount > 0, "user insufficient balance");
        require(
            IBEP20(tokenAddress).allowance(msg.sender, address(this)) >=
                _amount,
            "token not allowance"
        );
        TransferHelper.safeTransferFrom(
            tokenAddress,
            msg.sender,
            address(this),
            _amount
        );
        uint256 oldAmount = _profit(msg.sender, false);
        if (oldAmount <= 0) {
            totalStaker++;
        } else {
            uint256 _days = _calcDays(
                vaults[msg.sender].endDate,
                vaults[msg.sender].startDate
            );
            if (interestRates[_days].ratePerDay > 0) {
                interestRates[_days].totalStaker = interestRates[_days]
                    .totalStaker > 1
                    ? interestRates[_days].totalStaker - 1
                    : 0;
                interestRates[_days].totalToken = interestRates[_days]
                    .totalToken > oldAmount
                    ? interestRates[_days].totalToken - oldAmount
                    : 0;
            }
        }
        vaults[msg.sender].amount = oldAmount + _amount;
        vaults[msg.sender].startDate = block.timestamp;
        if (_numberOfDays > 0 && interestRates[_numberOfDays].ratePerDay > 0) {
            vaults[msg.sender].ratePerDay = interestRates[_numberOfDays]
                .ratePerDay > 0
                ? interestRates[_numberOfDays].ratePerDay
                : baseRatePerDay;
            vaults[msg.sender].endDate =
                block.timestamp +
                _numberOfDays *
                24 *
                3600;

            interestRates[_numberOfDays].totalStaker++;
            interestRates[_numberOfDays].totalToken += (oldAmount + _amount);
        } else {
            vaults[msg.sender].ratePerDay = baseRatePerDay;
            vaults[msg.sender].endDate = 0;
        }
        totalTokenStake += _amount;
        //emit Deposit(_numberOfDays, _amount, msg.sender);
    }

    function withdraw() external {
        uint256 amount = _profit(msg.sender, true);
        require(amount > 0, "user insufficient balance");
        if (vaults[msg.sender].amount < amount) {
            require(
                IBEP20(tokenAddress).balanceOf(interestPaymentAddress) >=
                    amount - vaults[msg.sender].amount,
                "interestPaymentAddress insufficient balance"
            );
            require(
                IBEP20(tokenAddress).allowance(
                    interestPaymentAddress,
                    address(this)
                ) >= amount - vaults[msg.sender].amount,
                "interestPaymentAddress not allowance"
            );
        }
        if (vaults[msg.sender].amount > amount) {
            TransferHelper.safeTransfer(tokenAddress, msg.sender, amount);
            TransferHelper.safeTransfer(
                tokenAddress,
                interestPaymentAddress,
                vaults[msg.sender].amount - amount
            );
        } else {
            TransferHelper.safeTransfer(
                tokenAddress,
                msg.sender,
                vaults[msg.sender].amount
            );
            if (amount - vaults[msg.sender].amount > 0) {
                TransferHelper.safeTransferFrom(
                    tokenAddress,
                    interestPaymentAddress,
                    msg.sender,
                    amount - vaults[msg.sender].amount
                );
            }
        }

        totalTokenStake = totalTokenStake > vaults[msg.sender].amount
            ? totalTokenStake - vaults[msg.sender].amount
            : 0;
        totalStaker = totalStaker > 0 ? totalStaker - 1 : 0;
        uint256 _days = _calcDays(
            vaults[msg.sender].endDate,
            vaults[msg.sender].startDate
        );
        if (interestRates[_days].ratePerDay > 0) {
            interestRates[_days].totalStaker = interestRates[_days]
                .totalStaker > 1
                ? interestRates[_days].totalStaker - 1
                : 0;
            interestRates[_days].totalToken = interestRates[_days].totalToken >
                vaults[msg.sender].amount
                ? interestRates[_days].totalToken - vaults[msg.sender].amount
                : 0;
        }
        vaults[msg.sender].amount = 0;
        //vaults[msg.sender].startDate = 0;
        //vaults[msg.sender].ratePerDay = 0;
        //vaults[msg.sender].endDate = 0;
    }

    function getProfit(address _account)
        external
        view
        returns (uint256 _amount)
    {
        return _profit(_account, true);
    }

    function _profit(address _account, bool _earlyWithdrawFee)
        internal
        view
        returns (uint256 _amount)
    {
        if (vaults[_account].amount <= 0) {
            return 0;
        }
        // if (emergency) {
        //     return vaults[_account].amount;
        // }
        if (
            vaults[_account].startDate + withdrawBeforeHours * 3600 >
            block.timestamp &&
            _earlyWithdrawFee
        ) {
            return
                vaults[_account].amount -
                (withdrawBeforeHourFee * vaults[_account].amount) /
                denominator;
        }
        if (
            /*
                only comment for testing purpose
            */
            vaults[_account].endDate > block.timestamp ||
            vaults[_account].endDate == 0 ||
            vaults[_account].endDate < vaults[_account].startDate
        ) {
            // withdraw before endDate
            return
                vaults[_account].amount +
                _calcProfit(
                    vaults[_account].amount,
                    baseRatePerDay,
                    _calcDays(block.timestamp, vaults[_account].startDate),
                    denominator
                );
        } else {
            return
                vaults[_account].amount +
                _calcProfit(
                    vaults[_account].amount,
                    vaults[_account].ratePerDay,
                    _calcDays(
                        vaults[_account].endDate,
                        vaults[_account].startDate
                    ),
                    denominator
                ) +
                (
                    block.timestamp > vaults[_account].endDate
                        ? _calcProfit(
                            vaults[_account].amount,
                            baseRatePerDay,
                            _calcDays(
                                block.timestamp,
                                vaults[_account].endDate
                            ),
                            denominator
                        )
                        : 0
                );
        }
    }

    function getEndPeriodProfit(address _account)
        external
        view
        returns (uint256 _amount)
    {
        return _endPeriodProfit(_account);
    }

    function _endPeriodProfit(address _account)
        internal
        view
        returns (uint256 _amount)
    {
        if (vaults[_account].amount <= 0) {
            return 0;
        }
        // if (emergency) {
        //     return vaults[_account].amount;
        // }
        if (
            vaults[_account].endDate == 0 ||
            vaults[_account].endDate < vaults[_account].startDate
        ) {
            return
                vaults[_account].amount +
                _calcProfit(
                    vaults[_account].amount,
                    vaults[_account].ratePerDay,
                    _calcDays(block.timestamp, vaults[_account].startDate),
                    denominator
                );
        } else {
            return
                vaults[_account].amount +
                _calcProfit(
                    vaults[_account].amount,
                    vaults[_account].ratePerDay,
                    _calcDays(
                        vaults[_account].endDate,
                        vaults[_account].startDate
                    ),
                    denominator
                ) +
                (
                    block.timestamp > vaults[_account].endDate
                        ? _calcProfit(
                            vaults[_account].amount,
                            baseRatePerDay,
                            _calcDays(
                                block.timestamp,
                                vaults[_account].endDate
                            ),
                            denominator
                        )
                        : 0
                );
        }
    }

    function _calcDays(uint256 _end, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        if (_end <= _start) {
            return 0;
        }
        return (_end - _start) / (24 * 3600);
    }

    function _calcProfit(
        uint256 _amount,
        uint256 _rate,
        uint256 _days,
        uint256 _denominator
    ) internal pure returns (uint256) {
        return (_amount * _rate * _days) / _denominator;
    }

    function _exist(uint256[] memory _interestRateDays, uint256 _nod)
        internal
        pure
        returns (bool)
    {
        uint256 length = _interestRateDays.length;
        for (uint256 i = 0; i < length; ) {
            if (_nod == _interestRateDays[i]) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function setInterestPaymentAddress(address _interestPaymentAddress)
        external
        onlyOwner
    {
        interestPaymentAddress = _interestPaymentAddress;
    }

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        require(totalTokenStake < 0);
        tokenAddress = _tokenAddress;
    }

    function setEndDate(address _account, uint256 _endDate) external onlyOwner {
        vaults[_account].endDate = _endDate;
    }

    function setStartDate(address _account, uint256 _startDate)
        external
        onlyOwner
    {
        vaults[_account].startDate = _startDate;
    }
}