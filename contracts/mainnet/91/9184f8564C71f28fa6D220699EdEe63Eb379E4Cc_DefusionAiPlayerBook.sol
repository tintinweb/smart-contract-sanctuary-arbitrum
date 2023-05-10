pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../library/NameFilter.sol";
import "../interface/IPlayerBook.sol";

contract DefusionAiPlayerBook is IPlayerBook, Ownable {
    using NameFilter for string;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // --- Data ---
    bool private initialized; // Flag of initialize data

    // register pools
    mapping(address => bool) public _pools;

    // (addr => pID) returns player id by address
    mapping(address => uint256) public _pIDxAddr;
    // (name => pID) returns player id by name
    mapping(bytes32 => uint256) public _pIDxName;
    // (pID => data) player data
    mapping(uint256 => Player) public _plyr;
    // (pID => name => bool) list of names a player owns.  (used so you can change your display name amoungst any name you own)
    mapping(uint256 => mapping(bytes32 => bool)) public _plyrNames;

    // the  of refrerrals
    uint256 public _totalReferReward;
    // the fee of register
    uint256 public _totalRegisterFee;
    // total number of players
    uint256 public _pID;
    // total register name count
    uint256 public _totalRegisterCount = 0;

    // the direct refer's reward rate
    uint256 public _refer1RewardRate = 700; //7%
    // the second direct refer's reward rate
    uint256 public _refer2RewardRate = 300; //3%

    uint256 public _feeRate; // 0.07%
    // base rate
    uint256 public _baseRate = 10000;

    bytes32 public _defaulRefer =
        0x61696465676f0000000000000000000000000000000000000000000000000000;

    uint256 public _freeAmount;

    address public _teamWallet = address(0);

    IERC20 public _aigc;

    struct Player {
        address addr;
        bytes32 name;
        uint8 nameCount;
        uint256 laff;
        uint256 amount;
        uint256 rreward;
        uint256 allReward;
        uint256 lv1Count;
        uint256 lv2Count;
    }

    event eveClaim(uint256 pID, address addr, uint256 reward);
    event eveBindRefer(
        uint256 pID,
        address addr,
        bytes32 name,
        uint256 affID,
        address affAddr,
        bytes32 affName
    );
    event eveDefaultPlayer(uint256 pID, address addr, bytes32 name);
    event eveNewName(
        uint256 pID,
        address addr,
        bytes32 name,
        uint256 affID,
        address affAddr,
        bytes32 affName
    );
    event eveSettle(
        uint256 pID,
        uint256 affID,
        uint256 aff_affID,
        uint256 affReward,
        uint256 aff_affReward,
        uint256 amount
    );
    event eveAddPool(address addr);
    event eveRemovePool(address addr);
    event eveSetRewardRate(
        uint256 refer1Rate,
        uint256 refer2Rate,
        uint256 feeRate
    );
    event GovernanceTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event TransferReferrer(uint256 pID, address newReferrer);
    event eveWithdrawFee(uint256 registerFee);

    // --- Init ---
    function initialize(address owner, address teamWallet) public {
        require(!initialized, "initialize: Already initialized!");
        _transferOwnership(owner);
        _pID = 0;
        _totalReferReward = 0;
        _totalRegisterCount = 0;
        _refer1RewardRate = 700; //7%
        _refer2RewardRate = 300; //3%
        _feeRate = 7;
        _baseRate = 10000;
        _freeAmount = 101;
        _defaulRefer = 0x6465667573696f6e616900000000000000000000000000000000000000000000;
        _teamWallet = teamWallet;
        addDefaultPlayer(_teamWallet, _defaulRefer);
        initialized = true;
    }

    /**
     * check address
     */
    modifier validAddress(address addr) {
        require(addr != address(0x0));
        _;
    }

    /**
     * check pool
     */
    modifier isRegisteredPool() {
        require(_pools[msg.sender], "invalid pool address!");
        _;
    }

    /**
     * registe a pool
     */
    function addPool(address poolAddr) public onlyOwner {
        require(!_pools[poolAddr], "derp, that pool already been registered");

        _pools[poolAddr] = true;

        emit eveAddPool(poolAddr);
    }

    /**
     * remove a pool
     */
    function removePool(address poolAddr) public onlyOwner {
        require(_pools[poolAddr], "derp, that pool must be registered");

        _pools[poolAddr] = false;

        emit eveRemovePool(poolAddr);
    }

    /**
     * resolve the refer's reward from a player
     */
    function settleReward(
        address from,
        uint256 amount
    ) external override isRegisteredPool validAddress(from) returns (uint256) {
        // set up our tx event data and determine if player is new or not
        // _determinePID(from);
        // uint256 pID = _pIDxAddr[from];
        uint256 pID = _determinePID(from);
        uint256 affID = _plyr[pID].laff;

        if (affID <= 0) {
            affID = _pIDxName[_defaulRefer];
            _plyr[pID].laff = affID;
        }

        uint256 fee = 0;

        // father
        uint256 affReward = (amount.mul(_refer1RewardRate)).div(_baseRate);
        _plyr[affID].rreward = _plyr[affID].rreward.add(affReward);
        _totalReferReward = _totalReferReward.add(affReward);
        fee = fee.add(affReward);

        // grandfather
        uint256 aff_affID = _plyr[affID].laff;
        uint256 aff_affReward = amount.mul(_refer2RewardRate).div(_baseRate);
        if (aff_affID <= 0) {
            aff_affID = _pIDxName[_defaulRefer];
        }
        _plyr[aff_affID].rreward = _plyr[aff_affID].rreward.add(aff_affReward);
        _totalReferReward = _totalReferReward.add(aff_affReward);

        _plyr[pID].amount = _plyr[pID].amount.add(amount);

        fee = fee.add(aff_affReward);

        emit eveSettle(pID, affID, aff_affID, affReward, aff_affReward, amount);

        return fee;
    }

    /**
     * claim all of the refer reward.
     */
    function claim() public {
        address addr = msg.sender;
        uint256 pid = _pIDxAddr[addr];
        uint256 reward = _plyr[pid].rreward;

        require(reward > 0, "only have reward");

        //reset
        _plyr[pid].allReward = _plyr[pid].allReward.add(reward);
        _plyr[pid].rreward = 0;

        //get reward
        _aigc.safeTransfer(addr, reward);

        // fire event
        emit eveClaim(_pIDxAddr[addr], addr, reward);
    }

    /**
     * check name string
     */
    function checkIfNameValid(
        string memory nameStr
    ) public view returns (bool) {
        bytes32 name = nameStr.nameFilter();
        if (_pIDxName[name] == 0) return (true);
        else return (false);
    }

    /**
     * @dev add a default player
     */
    function addDefaultPlayer(address addr, bytes32 name) private {
        _pID++;

        _plyr[_pID].addr = addr;
        _plyr[_pID].name = name;
        _plyr[_pID].nameCount = 1;
        _pIDxAddr[addr] = _pID;
        _pIDxName[name] = _pID;
        _plyrNames[_pID][name] = true;

        //fire event
        emit eveDefaultPlayer(_pID, addr, name);
    }

    /**
     * @dev set refer reward rate
     */
    function setReferRewardRate(
        uint256 refer1Rate,
        uint256 refer2Rate,
        uint256 feeRate
    ) public onlyOwner {
        _refer1RewardRate = refer1Rate;
        _refer2RewardRate = refer2Rate;
        _feeRate = feeRate;
        emit eveSetRewardRate(refer1Rate, refer2Rate, feeRate);
    }

    /**
     * @dev set aigc contract address
     */
    function setAigcContract(address aigc) public onlyOwner {
        _aigc = IERC20(aigc);
    }

    /**
     * @dev set teamWallet address
     */
    function setTeamWallet(address payable teamWallet) public onlyOwner {
        _teamWallet = teamWallet;
    }

    /**
     * @dev registers a name.  UI will always display the last name you registered.
     * but you will still own all previously registered names to use as affiliate
     * links.
     * - must pay a registration fee.
     * - name must be unique
     * - names will be converted to lowercase
     * - cannot be only numbers
     * - cannot start with 0x
     * - name must be at least 1 char
     * - max length of 32 characters long
     * - allowed characters: a-z, 0-9
     * -functionhash- 0x921dec21 (using ID for affiliate)
     * -functionhash- 0x3ddd4698 (using address for affiliate)
     * -functionhash- 0x685ffd83 (using name for affiliate)
     * @param nameString players desired name
     * @param affCode affiliate name of who refered you
     * (this might cost a lot of gas)
     */

    function registerNameXName(
        string memory nameString,
        string memory affCode
    ) external {
        uint256 registrationFee = this.getRegistrationFee();
        if (registrationFee > 0) {
            _aigc.safeTransferFrom(
                msg.sender,
                address(this),
                this.getRegistrationFee()
            );
            _totalRegisterFee += registrationFee;
        }

        // filter name + condition checks
        bytes32 name = NameFilter.nameFilter(nameString);
        // if names already has been used
        require(_pIDxName[name] == 0, "sorry that names already taken");

        // set up address
        address addr = msg.sender;
        // set up our tx event data and determine if player is new or not

        // _determinePID(addr);
        // // fetch player id
        // uint256 pID = _pIDxAddr[addr];
        uint256 pID = _determinePID(addr);
        // if names already has been used
        require(
            _plyrNames[pID][name] == false,
            "sorry that names already taken"
        );

        // add name to player profile, registry, and name book
        _plyrNames[pID][name] = true;
        _pIDxName[name] = pID;
        _plyr[pID].name = name;
        _plyr[pID].nameCount++;

        _totalRegisterCount++;

        //try bind a refer
        if (_plyr[pID].laff == 0) {
            bytes memory tempCode = bytes(affCode);
            bytes32 affName = 0x0;
            if (tempCode.length >= 0) {
                assembly {
                    affName := mload(add(tempCode, 32))
                }
            }

            _bindRefer(addr, affName);
        }
        uint256 affID = _plyr[pID].laff;

        // fire event
        emit eveNewName(
            pID,
            addr,
            name,
            affID,
            _plyr[affID].addr,
            _plyr[affID].name
        );
    }

    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */
    function bindRefer(
        address from,
        string calldata affCode
    ) external override isRegisteredPool returns (bool) {
        bytes memory tempCode = bytes(affCode);
        bytes32 affName = 0x0;
        if (tempCode.length >= 0) {
            assembly {
                affName := mload(add(tempCode, 32))
            }
        }

        return _bindRefer(from, affName);
    }

    /**
     * @dev bind a refer,if affcode invalid, use default refer
     */
    function _bindRefer(
        address from,
        bytes32 name
    ) private validAddress(msg.sender) validAddress(from) returns (bool) {
        // set up our tx event data and determine if player is new or not
        // _determinePID(from);

        // // fetch player id
        // uint256 pID = _pIDxAddr[from];
        uint256 pID = _determinePID(from);
        if (_plyr[pID].laff != 0) {
            return false;
        }

        if (_pIDxName[name] == 0) {
            //unregister name
            name = _defaulRefer;
        }

        uint256 affID = _pIDxName[name];
        if (affID == pID) {
            affID = _pIDxName[_defaulRefer];
        }

        _plyr[pID].laff = affID;

        //lvcount
        _plyr[affID].lv1Count++;
        uint256 aff_affID = _plyr[affID].laff;
        if (aff_affID != 0) {
            _plyr[aff_affID].lv2Count++;
        }

        // fire event
        emit eveBindRefer(
            pID,
            from,
            name,
            affID,
            _plyr[affID].addr,
            _plyr[affID].name
        );

        return true;
    }

    function _determinePID(address addr) private returns (uint256) {
        if (_pIDxAddr[addr] == 0) {
            _pID++;
            _pIDxAddr[addr] = _pID;
            _plyr[_pID].addr = addr;
            return _pID;
        } else {
            return _pIDxAddr[addr];
        }
    }

    function hasRefer(
        address from
    ) external override isRegisteredPool returns (bool) {
        uint256 pID = _determinePID(from);
        return (_plyr[pID].laff > 0);
    }

    function getPlayerInfo(
        address from
    )
        external
        view
        returns (bytes32, uint256, uint256, uint256, uint256, uint256, uint256)
    {
        uint256 pID = _pIDxAddr[from];
        if (_pID == 0) {
            return (0, 0, 0, 0, 0, 0, 0);
        }
        return (
            _plyr[pID].name,
            _plyr[pID].laff,
            _plyr[_plyr[pID].laff].laff,
            _plyr[pID].rreward,
            _plyr[pID].allReward,
            _plyr[pID].lv1Count,
            _plyr[pID].lv2Count
        );
    }

    function getRegistrationFee() external view returns (uint256) {
        if (_pID <= _freeAmount) {
            return 0;
        } else {
            return _aigc.totalSupply().mul(_feeRate).div(_baseRate);
        }
    }

    function withdrawRegisterFee() external onlyOwner {
        _aigc.safeTransfer(_teamWallet, _totalRegisterFee);
        emit eveWithdrawFee(_totalRegisterFee);
    }

    function transferReferrer(address newReferrer) external {
        uint256 pID = _pIDxAddr[msg.sender];
        require(pID != 0, "not register");
        require(_plyr[pID].name != bytes32(0), "No registered name!");
        _plyr[pID].addr = newReferrer;
        uint256 newPID = _pIDxAddr[newReferrer];
        require(newPID == 0, "newReferrer is bound!!");
        _pIDxAddr[newReferrer] = pID;
        _pIDxAddr[msg.sender] = 0;
        emit TransferReferrer(pID, newReferrer);
    }
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface IPlayerBook {
    function settleReward(
        address from,
        uint256 amount
    ) external returns (uint256);

    function bindRefer(
        address from,
        string calldata affCode
    ) external returns (bool);

    function hasRefer(address from) external returns (bool);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string memory _input) internal pure returns (bytes32) {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

        //sorry limited to 32 characters
        require(
            _length <= 32 && _length > 0,
            "string must be between 1 and 32 characters"
        );
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30) {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

        // create a bool to track if we have a non number character
        bool _hasNonNumber;

        // convert & check
        for (uint256 i = 0; i < _length; i++) {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b) {
                // convert to lower case a-z
                _temp[i] = bytes1(uint8(_temp[i]) + 32);

                // we have a non number
                if (_hasNonNumber == false) _hasNonNumber = true;
            } else {
                require(
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                        // or 0-9
                        (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );

                // see if we have a character other than a number
                if (
                    _hasNonNumber == false &&
                    (_temp[i] < 0x30 || _temp[i] > 0x39)
                ) _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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