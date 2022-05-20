pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

contract XeenonLedger is Ownable {
    uint256 private creditsConversion = 1E16;
    mapping(address => uint256) public creditBalance;
    uint256 private totalRevenue;
    uint256 public transactionFeePercentage = 10;
    address public acceptedToken;

    event Deposit(address indexed from, uint256 credits);
    event Withdraw(address indexed from, uint256 credits);
    event PayViewFee(
        address indexed from,
        address indexed to,
        uint256 credits,
        uint256 transactionFeePercentage
    );

    constructor(address _acceptedToken) {
        acceptedToken = _acceptedToken;
    }

    /**
     *  @notice Depositing DAI to receive credits.
     *  @param _amount uint256
     */
    function deposit(uint256 _amount) external {
        IERC20(acceptedToken).transferFrom(msg.sender, address(this), _amount);
        uint256 addedCredits = _amount / creditsConversion;
        creditBalance[msg.sender] = creditBalance[msg.sender] + addedCredits;

        emit Deposit(msg.sender, addedCredits);
    }

    /**
     *  @notice Converting credits to DAI.
     *  @param _creditAmount uint256
     */
    function withdraw(uint256 _creditAmount) external {
        require(
            creditBalance[msg.sender] >= _creditAmount,
            "You don't have enough credits."
        );

        creditBalance[msg.sender] = creditBalance[msg.sender] - _creditAmount;
        uint256 withdrawAmount = _creditAmount * creditsConversion;
        IERC20(acceptedToken).transfer(msg.sender, withdrawAmount);

        emit Withdraw(msg.sender, _creditAmount);
    }

    /**
     * @notice Transfer money from viewer to streamer, a fee procetage is taken. Can only be called
     * by admin wallet
     * @param _from address - viewer
     * @param  _to address - streamer
     * @param  _creditAmount uint256 - amount to transfer
     */
    function payViewFee(
        address _from,
        address _to,
        uint256 _creditAmount
    ) external onlyOwner {
        require(
            creditBalance[_from] >= _creditAmount,
            "Viewer don't have enough credits."
        );
        (
            uint256 streamerPayment,
            uint256 fee
        ) = calcStreamerPaymentAfterTransactionFee(
                _creditAmount,
                transactionFeePercentage
            );

        creditBalance[_from] = creditBalance[_from] - _creditAmount;
        totalRevenue = totalRevenue + fee;
        creditBalance[_to] = creditBalance[_to] + streamerPayment;

        emit PayViewFee(_from, _to, _creditAmount, transactionFeePercentage);
    }

    /**
     * @notice Withdraws all the revenue. Can only be called by admin wallet.
     */
    function withdrawRevenue() external onlyOwner {
        uint256 withdrawAmount = totalRevenue * creditsConversion;
        totalRevenue = 0;
        IERC20(acceptedToken).transfer(owner(), withdrawAmount);
    }

    /**
     * @notice Sets the transaction fee percentage. Can only be called by admin wallet.
     * @param _transactionFeePercentage uint256
     */
    function setTransactionFeePercentage(uint256 _transactionFeePercentage)
        external
        onlyOwner
    {
        transactionFeePercentage = _transactionFeePercentage;
    }

    /**
     * @notice Calculates the earnings and fees
     * @param _amount uint256
     * @param _feePercentage uint256
     */
    function calcStreamerPaymentAfterTransactionFee(
        uint256 _amount,
        uint256 _feePercentage
    ) private pure returns (uint256, uint256) {
        uint256 fee = (_amount * _feePercentage) / 100;

        // handles subcent rounding
        uint256 remainder = _amount % _feePercentage;
        if (remainder > _feePercentage / 2) {
            fee = fee + 1;
        } else if (fee == 0) {
            fee = fee + 1;
        }

        return (_amount - fee, fee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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