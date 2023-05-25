/**
 *Submitted for verification at Arbiscan on 2023-05-25
*/

// SPDX-License-Identifier: MIT
// File: xlsd/interfaces/IReferralProgram.sol



pragma solidity ^0.8.0;

struct ReferralRewardsInfo {
    uint256 timestamp;
    uint256 rewardsAmount;
    uint256 rebatesBonusAmount;
    address fromAddress;
    address poolAddress;
}

interface IReferralProgram {
    function registerCode(bytes32 _code) external;
    function setTraderReferralCode(address _account, bytes32 _code) external;
    function setTraderReferralCodeByUser(bytes32 _code) external;
    function getTraderReferralInfo(address _account) external view returns (bytes32, address, uint256, uint256, uint256);
    function getAffiliatesReferralInfo(address _account) external view returns (bytes32, uint256, uint256, uint256, uint256);
    function getBasePoints() external view returns (uint256);
}
// File: xlsd/access/Governable.sol



pragma solidity ^0.8.0;

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
// File: xlsd/libraries/math/SafeMath.sol



pragma solidity ^0.8.0;

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
// File: xlsd/ReferralProgram.sol



pragma solidity ^0.8.0;




contract ReferralProgram is Governable, IReferralProgram {
    using SafeMath for uint256;

    struct Tier {
        uint256 rebates; // 3000 for 30%
        uint256 bonus; // 5000 for 50%, 7000 for 70%
    }

    uint256 public constant BASIS_POINTS = 10000;
    mapping (address => uint256) public referrerTiers; // link between user <> tier
    mapping (address => uint256) public referrerCounter;
    mapping (uint256 => Tier) public tiers;

    mapping (address => bool) public isHandler;

    mapping (bytes32 => address) public codeOwners;
    mapping (address => bytes32) public affiliatesCodes;
    mapping (address => bytes32) public traderReferralCodes;

    event SetHandler(address handler, bool isActive);
    event SetTraderReferralCode(address account, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare);
    event SetReferrerTier(address referrer, uint256 tierId);
    event RegisterCode(address account, bytes32 code);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event GovSetCodeOwner(bytes32 code, address newAccount);

    modifier onlyHandler() {
        require(isHandler[msg.sender], "ReferralProgram: forbidden");
        _;
    }

    function setHandler(address _handler, bool _isActive) external onlyGov {
        isHandler[_handler] = _isActive;
        emit SetHandler(_handler, _isActive);
    }

    function setTier(uint256 _tierId, uint256 _rebate, uint256 _bonus) external onlyGov {
        require(_rebate <= BASIS_POINTS, "ReferralProgram: invalid rebate");
        require(_bonus <= BASIS_POINTS, "ReferralProgram: invalid bonus");

        Tier memory tier = tiers[_tierId];
        tier.rebates = _rebate;
        tier.bonus = _bonus;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _rebate, _bonus);
    }

    function setReferrerTier(address _referrer, uint256 _tierId) external onlyGov {
        referrerTiers[_referrer] = _tierId;
        emit SetReferrerTier(_referrer, _tierId);
    }

    function setTraderReferralCode(address _account, bytes32 _code) external override onlyHandler {
        _setTraderReferralCode(_account, _code);
    }

    function setTraderReferralCodeByUser(bytes32 _code) external override{
        _setTraderReferralCode(msg.sender, _code);
    }

    function _setTraderReferralCode(address _account, bytes32 _code) private {
        require(_code != bytes32(0), "ReferralProgram: invalid _code");
        require(codeOwners[_code] != address(0), "ReferralProgram: _code not exists");
        require(traderReferralCodes[_account] == bytes32(0), "ReferralProgram: ref already exists");
        address referrer = codeOwners[_code];
        uint refCount = referrerCounter[referrer];
        referrerCounter[referrer] = refCount + 1;
        traderReferralCodes[_account] = _code;
        emit SetTraderReferralCode(_account, _code);
    }

    function registerCode(bytes32 _code) external override{
        require(_code != bytes32(0), "ReferralProgram: invalid _code");
        require(codeOwners[_code] == address(0), "ReferralProgram: code already exists");

        codeOwners[_code] = msg.sender;
        affiliatesCodes[msg.sender] = _code;
        bytes32 code = traderReferralCodes[msg.sender];
        if (code != bytes32(0)) {
            address referrer = codeOwners[code];
            uint refererTier = referrerTiers[referrer];
            if (refererTier > 0 && refererTier < 3){
                referrerTiers[msg.sender] = refererTier + 1;
            }
        }
        emit RegisterCode(msg.sender, _code);
    }

    function getTraderReferralInfo(address _account) external override view returns (bytes32, address, uint256, uint256, uint256) {
        bytes32 code = traderReferralCodes[_account];
        address referrer;
        uint256 tierId;
        uint256 rebates;
        uint256 bonus;
        if (code != bytes32(0)) {
            referrer = codeOwners[code];
            tierId = referrerTiers[referrer];
            Tier memory tier = tiers[tierId];
            bonus = tier.bonus;
            rebates = tier.rebates;
        }
        return (code, referrer, tierId, rebates, bonus);
    }

    function getAffiliatesReferralInfo(address _account) external override view returns (bytes32, uint256, uint256, uint256, uint256) {
        bytes32 code = affiliatesCodes[_account];
        uint256 tierId = referrerTiers[_account];
        Tier memory tier = tiers[tierId];
        uint256 referredCount = referrerCounter[_account];
        return (code, referredCount, tierId, tier.rebates, tier.bonus);
    }

    function getBasePoints() external override pure returns (uint256) {
        return BASIS_POINTS;
    }

}