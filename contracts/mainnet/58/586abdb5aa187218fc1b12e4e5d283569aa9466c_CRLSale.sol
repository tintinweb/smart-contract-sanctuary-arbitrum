/**
 *Submitted for verification at Arbiscan.io on 2023-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
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
   * - The divisor cannot be zero.
   */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

contract CRLSale {

    using SafeMath for uint256;

    address public crlContractAddress;
    address public crcContractAddress;

    address public admin;
    address public adminReceive;

    uint256 public crlPrice =  5 * 10 ** 10;

    uint256 public crcAmountRequired;
    uint256 public crlAmountRequired;

    uint256 public minEthAmount = 5 * 10 ** 16;

    uint256 public maxCrlSupply = 25000000000 * 10**18; // 250

    event Purchase(address indexed buyer, uint256 crlAmount);
    event AddressUpdate(address indexed admin, string contractName, address newAddress);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    constructor(address _crlAddress, address _crcAddress) {
        admin = msg.sender;
        adminReceive = msg.sender;
        crlContractAddress = _crlAddress;
        crcContractAddress = _crcAddress;
        crcAmountRequired = 10 * 10**18;
        crlAmountRequired = 10000000 * 10** 18;
    }

    function setAdmin(address _newAdmin) external onlyAdmin {
        adminReceive = _newAdmin;
        emit AddressUpdate(msg.sender, "Admin", _newAdmin);
    }

    function setAmount(uint256 amount1,uint256 amount2) external onlyAdmin {
        crcAmountRequired = amount1 * 10 ** 18;
        crlAmountRequired = amount2 * 10 ** 18;
    }

    function updateCrlAddress(address _newCrlAddress) external onlyAdmin {
        crlContractAddress = _newCrlAddress;
        emit AddressUpdate(msg.sender, "CRL", _newCrlAddress);
    }

    function updateCrcAddress(address _newCrcAddress) external onlyAdmin {
        crcContractAddress = _newCrcAddress;
        emit AddressUpdate(msg.sender, "CRC", _newCrcAddress);
    }

    function withdrawETH() external onlyAdmin {
        uint balance = address(this).balance;
        payable(admin).transfer(balance);
    }

    function withdrawCRL() external onlyAdmin {
        uint crlBalance = IERC20(crlContractAddress).balanceOf(address(this));
        require(IERC20(crlContractAddress).transfer(admin, crlBalance), "CRC transfer failed");
    }

    function buyCRL() external payable {
        require(msg.value >= minEthAmount, "Insufficient ETH amount");

        uint crcBalance = IERC20(crcContractAddress).balanceOf(msg.sender);
        require(crcBalance >= crcAmountRequired, "Insufficient CRC balance");

        uint crlBalance = IERC20(crlContractAddress).balanceOf(address(this));
        require(crlBalance >= crlAmountRequired, "Insufficient CRL balance in contract");

        require(IERC20(crcContractAddress).transferFrom(msg.sender, adminReceive, crcAmountRequired), "CRC transfer failed");

        uint crlAmountToBuy = msg.value.div(crlPrice);
        require(crlAmountToBuy* 10 **18 <= maxCrlSupply, "CRL purchase exceeds supply cap");

        require(IERC20(crlContractAddress).transfer(msg.sender, crlAmountToBuy * 10 **18), "CRL transfer failed");

        payable(adminReceive).transfer(msg.value);

        emit Purchase(msg.sender, crlAmountToBuy);
    }
}