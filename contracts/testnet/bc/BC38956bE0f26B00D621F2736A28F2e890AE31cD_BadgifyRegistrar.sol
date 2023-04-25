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

/**
 * ░█▀▄░█▀█░█▀▄░█▀▀░▀█▀░█▀▀░█░█
 * ░█▀▄░█▀█░█░█░█░█░░█░░█▀▀░░█░
 * ░▀▀░░▀░▀░▀▀░░▀▀▀░▀▀▀░▀░░░░▀░
 *
 * @title Badgify: Digital Badging Platform
 * @author raldblox.eth (github.com/raldblox)
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IBadgifyRegistrar.sol";

/**
 * @title Badgify Registrar
 * @dev Store & retrieve addresses and statuses
 */
contract BadgifyRegistrar is IBadgifyRegistrar {
    using SafeMath for uint256;

    address private admin;
    bool private restrictBlacklisted;
    uint256 private epoch = 1;
    uint256 private userCount;
    uint256 public bluelister;
    uint256 private txFee;
    bool internal locked;

    mapping(address => uint256) private joinedEpoch;
    mapping(address => string) private namespaces;
    mapping(string => address) private nameaddresses;
    mapping(uint256 => mapping(address => bool)) private _joinlists;
    mapping(address => address) private _joinlistedBy;
    mapping(address => uint256) private listed;
    mapping(address => bool) private _blacklists; // @note banned addresses
    mapping(address => bool) private _bluelists; // @note incentivized addresses (orgs, communities, affiliates)
    mapping(address => uint256) private rfees;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

    /**
     * @dev Emitted when the `joinlistAddress` is set by
     * a call to {joinlist}. `isJoinlisted` is the joinlist status.
     */
    event Joinlisted(
        address indexed joinlistedBy,
        address indexed joinlistAddress,
        bool isJoinlisted,
        uint256 epoch
    );

    modifier onlyAdmin() {
        require(admin == msg.sender, "BADGIFY: Caller is not the admin");
        _;
    }

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        admin = msg.sender;
        _bluelists[msg.sender] = true;
        rfees[msg.sender] = 100;
    }

    function version() external pure override returns (string memory) {
        return "Badgify Registrar v1.0";
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newAdmin`).
     * Can only be called by the current admin.
     */
    function setAdmin(address newAdmin) external onlyAdmin {
        require(
            newAdmin != address(0),
            "BADGIFY: New admin address cannot be zero"
        );
        address oldAdmin = admin;
        admin = newAdmin;
        rfees[newAdmin] = 100;
        emit AdminChanged(oldAdmin, newAdmin);
    }

    /**
     * @dev New epoch for registrar
     */
    function newEpoch(uint256 _epoch) external onlyAdmin {
        epoch = _epoch;
    }

    /**
     * @dev Adjust processing fee
     */
    function newTxFee(uint256 _value) external onlyAdmin {
        txFee = _value.mul(10 ** 18);
    }

    /****** LISTING FUNCTIONS ******/

    /**
     * @dev Blacklist addresses
     * @param addr to blacklist address
     * @param isBlacklisted joinlist status
     */
    function blacklist(address addr, bool isBlacklisted) external onlyAdmin {
        _blacklists[addr] = isBlacklisted;
    }

    /**
     * @dev Joinlist addresses per Epoch
     * @param joinlistAddress to joinlist address
     * @param isJoinlisted joinlist status
     */
    function joinlist(
        address joinlistAddress,
        bool isJoinlisted
    ) external noReentrant {
        require(
            joinlistAddress != address(0),
            "BADGIFY: Zero addresses cannot be joinlisted"
        );
        require(
            !isContract(joinlistAddress),
            "BADGIFY: Bluelist address is a smart contract"
        );
        require(!blacklisted(msg.sender), "BADGIFY: Sender is blacklisted");
        require(
            !blacklisted(joinlistAddress),
            "BADGIFY: Joinlist address is blacklisted"
        );
        require(
            !joinlisted(epoch, joinlistAddress),
            "BADGIFY: Already joinlisted"
        );
        _joinlists[epoch][joinlistAddress] = isJoinlisted;
        _joinlistedBy[joinlistAddress] = msg.sender;
        uint256 cListed = listed[msg.sender];
        listed[msg.sender] = cListed++;
        joinedEpoch[joinlistAddress] = epoch;
        userCount++;
        emit Joinlisted(msg.sender, joinlistAddress, isJoinlisted, epoch);
    }

    /**
     * @dev Joinlist addresses per Epoch
     * @param bluelistAddress to joinlist address
     */
    function incentivizedJoinlist(
        address payable bluelistAddress
    ) external payable noReentrant {
        require(
            bluelistAddress != address(0),
            "BADGIFY: Zero addresses cannot be joinlisted"
        );
        require(!blacklisted(msg.sender), "BADGIFY: Sender is blacklisted");
        require(
            !blacklisted(bluelistAddress),
            "BADGIFY: Joinlist address is blacklisted"
        );
        require(!joinlisted(epoch, msg.sender), "BADGIFY: Already joinlisted");
        require(
            _bluelists[bluelistAddress],
            "BADGIFY: Bluelist address is not bluelisted"
        );
        require(msg.value >= txFee, "BADGIFY: Not Enough Processing Fee");
        uint256 rFees = msg.value.mul(100).div(rfees[bluelistAddress]); // @note send rewards to bluelisted
        (bool isProcessed, ) = bluelistAddress.call{value: rFees}("");
        require(isProcessed, "BADGIFY: Joinlisting Failed");
        _joinlists[epoch][msg.sender] = isProcessed;
        _joinlistedBy[msg.sender] = bluelistAddress;
        uint256 cListed = listed[bluelistAddress];
        listed[bluelistAddress] = cListed++;
        emit Joinlisted(bluelistAddress, msg.sender, isProcessed, epoch);
    }

    /**
     * @dev Bluelisting addresses
     * @param bluelistAddress is incentivized address
     * @param isBluelisted joinlist status
     */
    function bluelist(
        address bluelistAddress,
        bool isBluelisted,
        string memory _namespace,
        uint256 rfee
    ) external onlyAdmin {
        require(
            bluelistAddress != address(0),
            "BADGIFY: Zero addresses cannot be joinlisted"
        );
        require(!blacklisted(msg.sender), "BADGIFY: Sender is blacklisted");
        require(
            !blacklisted(bluelistAddress),
            "BADGIFY: Joinlist address is blacklisted"
        );
        require(
            nameaddresses[_namespace] == address(0),
            "BADGIFY: Namespace is taken"
        );
        require(rfee >= 50, "BADGIFY: rfee exceeds 50%");
        _bluelists[bluelistAddress] = isBluelisted;
        rfees[bluelistAddress] = rfee;
        assignNamespace(_namespace, bluelistAddress);
        bluelister++;
    }

    /****** NAMESPACE FUNCTIONS ******/

    /**
     * @dev Assign namespace on address
     * @param _namespace of `_addr`
     */
    function setNamespace(
        string memory _namespace,
        address _addr
    ) external virtual override {
        require(
            _addr != address(0),
            "BADGIFY: Zero addresses cannot be joinlisted"
        );
        require(!blacklisted(msg.sender), "BADGIFY: Sender is blacklisted");
        require(
            nameaddresses[_namespace] == address(0),
            "BADGIFY: Namespace is taken"
        );
        assignNamespace(_namespace, _addr);
    }

    /**
     * @dev Assign namespace to address
     */
    function assignNamespace(
        string memory _namespace,
        address _addr
    ) internal virtual {
        nameaddresses[_namespace] = _addr;
        namespaces[_addr] = _namespace;
    }

    /****** VIEWING DECK ******/

    /**
     * @dev Return blacklist status of address
     * @return status of 'addr'
     */

    function blacklisted(
        address addr
    ) public view virtual override returns (bool) {
        return _blacklists[addr];
    }

    /**
     * @dev Return joinlist status of epoch
     * @return status of 'addr'
     */

    function joinlisted(
        uint256 _epoch,
        address addr
    ) public view virtual override returns (bool) {
        return _joinlists[_epoch][addr];
    }

    /**
     * @dev Return joinlist status of epoch
     * @return status of 'addr'
     */

    function bluelisted(
        address addr
    ) public view virtual override returns (bool) {
        return _bluelists[addr];
    }

    /**
     * @dev Return namespace of address
     * @return name of 'addr'
     */

    function viewNamespace(
        address addr
    ) public view virtual override returns (string memory) {
        return namespaces[addr];
    }

    /**
     * @dev Return address of namespace
     * @return address of '_namespace'
     */

    function viewNameaddr(
        string memory _namespace
    ) public view virtual override returns (address) {
        return nameaddresses[_namespace];
    }

    /****** HELPERS ******/

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function recover() external onlyAdmin {
        uint256 amount = address(this).balance;
        (bool recovered, ) = admin.call{value: amount}("");
        require(recovered, "Failed to recover.");
    }
}

/**
 * ░█▀▄░█▀█░█▀▄░█▀▀░▀█▀░█▀▀░█░█
 * ░█▀▄░█▀█░█░█░█░█░░█░░█▀▀░░█░
 * ░▀▀░░▀░▀░▀▀░░▀▀▀░▀▀▀░▀░░░░▀░
 *
 * @title Badgify: Digital Badging Platform
 * @author raldblox.eth (github.com/raldblox)
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.2 <0.9.0;

/**
 * @dev Interface of the BadgifyRegistrar.
 */
interface IBadgifyRegistrar {
    function version() external pure returns (string memory);

    function blacklisted(address) external view returns (bool);

    function joinlisted(uint256, address) external view returns (bool);

    function bluelisted(address) external view returns (bool);

    function setNamespace(string memory, address) external;

    function viewNamespace(address) external view returns (string memory);

    function viewNameaddr(string memory) external view returns (address);
}