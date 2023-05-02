/**
 *Submitted for verification at Arbiscan on 2023-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.value;
    }
}

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

interface AIKUN {
    function balanceOf(address account) external view returns (uint256);
    function owner() external view returns (address);
    function distributeIncrease(address account, uint256 amount) external;
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract AIRDROP is Context {
    using SafeMath for uint256;

    
    uint256 public airdropCounter;
    uint256 private _todayClaimSize = 2500;
    uint256 public currClaimSizeTotall = _todayClaimSize;
    bool private _isActive;
    address private constant _aikunTokenAddress = 0x67a8B09Da74ca3aB057b554119844d96eDFDF7Ae;
    address private constant _nftAddress = 0x5B0a1c6E7604C3beA7b10991C17C5f92b9D186DF;
    mapping(address => bool) private _blacklist;
    mapping(uint => bool) public _getTokenList;
    mapping(address => uint) public addressGetLength;
    uint256 public preResTime = block.timestamp;
    uint256 private _initClaimAmount = 0;

    constructor() {
        _isActive = true;
    }

    function safeTransfer(address token, address to, uint value) private {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function claimAirdrop(uint tokenId) external returns(uint256) {
        require(_isActive, "Airdrop is not active.");
        require(airdropCounter < 25000, "Airdrop has ended.");
        require(!_blacklist[_msgSender()], "Address is blacklisted.");
        require(!_getTokenList[tokenId], "Can only be claimed once.");
        require(AIKUN(_nftAddress).ownerOf(tokenId) == _msgSender(), "No AIKUN token owned.");

        if (block.timestamp.sub(preResTime) >= 86400) {
            preResTime = preResTime.add(86400);
            currClaimSizeTotall = _todayClaimSize;
        }

        require(currClaimSizeTotall > 0, "The number of air drops has reached the upper limit today");

        if (_initClaimAmount == 0) {
            _initClaimAmount = AIKUN(_aikunTokenAddress).balanceOf(address(this)).div(25000);
        }
        
        currClaimSizeTotall--;
        airdropCounter++;
        _getTokenList[tokenId] = true;
        addressGetLength[_msgSender()]++;

        safeTransfer(_aikunTokenAddress, _msgSender(), _initClaimAmount);
        AIKUN(_aikunTokenAddress).distributeIncrease(address(0), 0);

        return _initClaimAmount;
    }

    function getBlockTimestamp() view public returns(uint256) {
        return block.timestamp;
    }

    function addToBlacklist(address account) external {
        require(AIKUN(_aikunTokenAddress).owner() == _msgSender(), "Only the owner can add to blacklist.");
        _blacklist[account] = true;
    }

    function removeFromBlacklist(address account) external {
        require(AIKUN(_aikunTokenAddress).owner() == _msgSender(), "Only the owner can remove from blacklist.");
        _blacklist[account] = false;
    }

    function toggleAirdrop() external {
        require(AIKUN(_aikunTokenAddress).owner() == _msgSender(), "Only the owner can toggle airdrop.");
        _isActive = !_isActive;
    }
}