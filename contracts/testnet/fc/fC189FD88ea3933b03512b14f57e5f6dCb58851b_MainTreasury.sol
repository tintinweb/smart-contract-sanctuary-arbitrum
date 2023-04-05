// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./ITreasury.sol";

interface IMainTreasury is ITreasury {
    event DepositETH(address indexed sender, uint256 amount);
    event DepositToken(address indexed token, address indexed sender, uint256 amount);

    function depositETH() external payable;
    function depositToken(address token, uint256 amount) external;
    function forceWithdrawETH(address recipient, uint256 amount) external;
    function forceWithdrawToken(address token, address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface ITreasury {
    event OperatorChanged(address indexed oldOperator, address indexed newOperator);
    event EtherWithdraw(address recipient, uint256 amount);
    event TokenWithdrawn(address token, address recipient, uint256 amount);

    function operator() external view returns (address);

    function changeOperator(address newOperator) external;

    function withdrawETH(address recipient, uint256 amount) external;

    function batchWithdrawETH(address[] memory recipients, uint256[] memory amounts) external;

    function withdrawToken(address token, address recipient, uint256 amount) external;

    function withdrawTokenToRecipients(address token, address[] memory recipients, uint256[] memory amounts) external;

    function batchWithdrawTokensToRecipients(address[] memory tokens, address[] memory recipients, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./interfaces/IMainTreasury.sol";
import "./Treasury.sol";
import "./libraries/TransferHelper.sol";

contract MainTreasury is IMainTreasury, Treasury {

    receive() external payable {}

    constructor(address operator_) Treasury(operator_) {}

    function depositETH() external payable override {
        require(msg.value > 0, "deposit amount is zero");
        emit DepositETH(msg.sender, msg.value);
    }

    function depositToken(
        address token,
        uint256 amount
    ) external override {
        require(token != address(0), "token is zero address");
        require(amount > 0, "deposit amount is zero");
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amount);
        emit DepositToken(token, msg.sender, amount);
    }

    function forceWithdrawETH(
        address recipient,
        uint256 amount
    ) external override {}

    function forceWithdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) external override {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./interfaces/IERC20.sol";
import "./interfaces/ITreasury.sol";
import "./libraries/TransferHelper.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Treasury is ITreasury, Ownable {
    address public operator;

    modifier onlyOperator() {
        require(msg.sender == operator, "only operator");
        _;
    }

    constructor(address operator_) {
        operator = operator_;
    }

    function changeOperator(address newOperator) external override onlyOwner {
        emit OperatorChanged(operator, newOperator);
        operator = newOperator;
    }

    function withdrawETH(address recipient, uint256 amount) external override onlyOperator {
        require(recipient != address(0), "zero address");
        require(amount > 0, "zero amount");
        require(address(this).balance >= amount);
        TransferHelper.safeTransferETH(recipient, amount);
        emit EtherWithdraw(recipient, amount);
    }

    function batchWithdrawETH(
        address[] memory recipients,
        uint256[] memory amounts
    ) external override onlyOperator {
        require(recipients.length == amounts.length, "length not same");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "zero address");
            require(amounts[i] > 0, "zero amount");
            require(address(this).balance >= amounts[i]);
            TransferHelper.safeTransferETH(recipients[i], amounts[i]);
            emit EtherWithdraw(recipients[i], amounts[i]);
        }
    }

    function withdrawToken(
        address token,
        address recipient,
        uint256 amount
    ) external override onlyOperator {
        require(token != address(0), "token is zero address");
        require(recipient != address(0), "recipient is zero address");
        require(amount > 0, "zero amount");
        require(IERC20(token).balanceOf(address(this)) >= amount, "balance not enough");
        TransferHelper.safeTransfer(token, recipient, amount);
        emit TokenWithdrawn(token, recipient, amount);
    }

    function withdrawTokenToRecipients(
        address token,
        address[] memory recipients,
        uint256[] memory amounts
    ) external override onlyOperator {
        require(token != address(0), "token is zero address");
        require(recipients.length == amounts.length, "length not same");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "recipient is zero address");
            require(amounts[i] > 0, "zero amount");
            require(IERC20(token).balanceOf(address(this)) >= amounts[i], "balance not enough");
            TransferHelper.safeTransfer(token, recipients[i], amounts[i]);
            emit TokenWithdrawn(token, recipients[i], amounts[i]);
        }
    }

    function batchWithdrawTokensToRecipients(
        address[] memory tokens,
        address[] memory recipients,
        uint256[] memory amounts
    ) external override onlyOperator {
        require(tokens.length == recipients.length && recipients.length == amounts.length, "length not same");
        for (uint256 i = 0; i < recipients.length; i++) {
            require(tokens[i] != address(0), "token is zero address");
            require(recipients[i] != address(0), "recipient is zero address");
            require(amounts[i] > 0, "zero amount");
            require(IERC20(tokens[i]).balanceOf(address(this)) >= amounts[i], "balance not enough");
            TransferHelper.safeTransfer(tokens[i], recipients[i], amounts[i]);
            emit TokenWithdrawn(tokens[i], recipients[i], amounts[i]);
        }
    }
}