// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IAllowanceTarget.sol";
import "./interfaces/ISpender.sol";
import "./utils/BaseLibEIP712.sol";
import "./utils/SignatureValidator.sol";

/**
 * @dev Spender contract
 */
contract Spender is ISpender, BaseLibEIP712, SignatureValidator {
    using SafeMath for uint256;

    // Constants do not have storage slot.
    address private constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = address(0);
    uint256 private constant TIME_LOCK_DURATION = 1 days;
    /*
        keccak256(
            abi.encodePacked(
                "SpendWithPermit(",
                "address tokenAddr,",
                "address user,",
                "address recipient,",
                "uint256 amount,",
                "uint256 salt,",
                "uint64 expiry",
                ")"
            )
        );
    */
    uint256 private constant SPEND_WITH_PERMIT_TYPEHASH = 0xef4569e9739cba74d90490d1bd03bf9bb1ce2f4b9134ad0e79ba922a1f70c1a1;

    // Below are the variables which consume storage slots.
    bool public timelockActivated;
    uint64 public numPendingAuthorized;
    address public operator;

    address public allowanceTarget;
    address public pendingOperator;

    uint256 public contractDeployedTime;
    uint256 public timelockExpirationTime;

    mapping(address => bool) public consumeGasERC20Tokens;
    mapping(uint256 => address) public pendingAuthorized;

    mapping(address => bool) private authorized;
    mapping(bytes32 => bool) private spendingFulfilled;
    mapping(address => bool) private tokenBlacklist;

    // System events
    event TimeLockActivated(uint256 activatedTimeStamp);
    // Operator events
    event SetPendingOperator(address pendingOperator);
    event TransferOwnership(address newOperator);
    event SetAllowanceTarget(address allowanceTarget);
    event SetNewSpender(address newSpender);
    event SetConsumeGasERC20Token(address token);
    event TearDownAllowanceTarget(uint256 tearDownTimeStamp);
    event BlackListToken(address token, bool isBlacklisted);
    event AuthorizeSpender(address spender, bool isAuthorized);

    /************************************************************
     *          Access control and ownership management          *
     *************************************************************/
    modifier onlyOperator() {
        require(operator == msg.sender, "Spender: not the operator");
        _;
    }

    modifier onlyAuthorized() {
        require(authorized[msg.sender], "Spender: not authorized");
        _;
    }

    function setNewOperator(address _newOperator) external onlyOperator {
        require(_newOperator != address(0), "Spender: operator can not be zero address");
        pendingOperator = _newOperator;

        emit SetPendingOperator(_newOperator);
    }

    function acceptAsOperator() external {
        require(pendingOperator == msg.sender, "Spender: only nominated one can accept as new operator");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit TransferOwnership(operator);
    }

    /************************************************************
     *                    Timelock management                    *
     *************************************************************/
    /// @dev Everyone can activate timelock after the contract has been deployed for more than 1 day.
    function activateTimelock() external {
        bool canActivate = block.timestamp.sub(contractDeployedTime) > 1 days;
        require(canActivate && !timelockActivated, "Spender: can not activate timelock yet or has been activated");
        timelockActivated = true;

        emit TimeLockActivated(block.timestamp);
    }

    /************************************************************
     *              Constructor and init functions               *
     *************************************************************/
    constructor(address _operator, address[] memory _consumeGasERC20Tokens) {
        require(_operator != address(0), "Spender: _operator should not be 0");

        // Set operator
        operator = _operator;
        timelockActivated = false;
        contractDeployedTime = block.timestamp;

        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;
        }
    }

    function setAllowanceTarget(address _allowanceTarget) external onlyOperator {
        require(allowanceTarget == address(0), "Spender: can not reset allowance target");

        // Set allowanceTarget
        allowanceTarget = _allowanceTarget;

        emit SetAllowanceTarget(_allowanceTarget);
    }

    /************************************************************
     *          AllowanceTarget interaction functions            *
     *************************************************************/
    function setNewSpender(address _newSpender) external onlyOperator {
        IAllowanceTarget(allowanceTarget).setSpenderWithTimelock(_newSpender);

        emit SetNewSpender(_newSpender);
    }

    function teardownAllowanceTarget() external onlyOperator {
        IAllowanceTarget(allowanceTarget).teardown();

        emit TearDownAllowanceTarget(block.timestamp);
    }

    /************************************************************
     *           Whitelist and blacklist functions               *
     *************************************************************/
    function isBlacklisted(address _tokenAddr) external view returns (bool) {
        return tokenBlacklist[_tokenAddr];
    }

    function blacklist(address[] calldata _tokenAddrs, bool[] calldata _isBlacklisted) external onlyOperator {
        require(_tokenAddrs.length == _isBlacklisted.length, "Spender: length mismatch");
        for (uint256 i = 0; i < _tokenAddrs.length; i++) {
            tokenBlacklist[_tokenAddrs[i]] = _isBlacklisted[i];

            emit BlackListToken(_tokenAddrs[i], _isBlacklisted[i]);
        }
    }

    function isAuthorized(address _caller) external view returns (bool) {
        return authorized[_caller];
    }

    function authorize(address[] calldata _pendingAuthorized) external onlyOperator {
        require(_pendingAuthorized.length > 0, "Spender: authorize list is empty");
        require(numPendingAuthorized == 0 && timelockExpirationTime == 0, "Spender: an authorize current in progress");

        if (timelockActivated) {
            numPendingAuthorized = uint64(_pendingAuthorized.length);
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                pendingAuthorized[i] = _pendingAuthorized[i];
            }
            timelockExpirationTime = block.timestamp + TIME_LOCK_DURATION;
        } else {
            for (uint256 i = 0; i < _pendingAuthorized.length; i++) {
                require(_pendingAuthorized[i] != address(0), "Spender: can not authorize zero address");
                authorized[_pendingAuthorized[i]] = true;

                emit AuthorizeSpender(_pendingAuthorized[i], true);
            }
        }
    }

    function completeAuthorize() external {
        require(timelockExpirationTime != 0, "Spender: no pending authorize");
        require(block.timestamp >= timelockExpirationTime, "Spender: time lock not expired yet");

        for (uint256 i = 0; i < numPendingAuthorized; i++) {
            authorized[pendingAuthorized[i]] = true;
            emit AuthorizeSpender(pendingAuthorized[i], true);
            delete pendingAuthorized[i];
        }
        timelockExpirationTime = 0;
        numPendingAuthorized = 0;
    }

    function deauthorize(address[] calldata _deauthorized) external onlyOperator {
        for (uint256 i = 0; i < _deauthorized.length; i++) {
            authorized[_deauthorized[i]] = false;

            emit AuthorizeSpender(_deauthorized[i], false);
        }
    }

    function setConsumeGasERC20Tokens(address[] memory _consumeGasERC20Tokens) external onlyOperator {
        for (uint256 i = 0; i < _consumeGasERC20Tokens.length; i++) {
            consumeGasERC20Tokens[_consumeGasERC20Tokens[i]] = true;

            emit SetConsumeGasERC20Token(_consumeGasERC20Tokens[i]);
        }
    }

    /************************************************************
     *                   External functions                      *
     *************************************************************/
    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _amount Amount to spend.
    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external override onlyAuthorized {
        _transferTokenFromUserTo(_tokenAddr, _user, msg.sender, _amount);
    }

    /// @dev Spend tokens on user's behalf. Only an authority can call this.
    /// @param _user The user to spend token from.
    /// @param _tokenAddr The address of the token.
    /// @param _receiver The receiver of the token.
    /// @param _amount Amount to spend.
    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _receiver,
        uint256 _amount
    ) external override onlyAuthorized {
        _transferTokenFromUserTo(_tokenAddr, _user, _receiver, _amount);
    }

    /// @dev Spend tokens on user's behalf with user's permit signature. Only an authority can call this.
    /// @param _tokenAddr The address of the token.
    /// @param _user The user to spend token from.
    /// @param _recipient The recipient of the token.
    /// @param _amount Amount to spend.
    /// @param _salt Salt for the permit.
    /// @param _expiry Expiry for the permit.
    /// @param _spendWithPermitSig Spend with permit signature.
    function spendFromUserToWithPermit(
        address _tokenAddr,
        address _user,
        address _recipient,
        uint256 _amount,
        uint256 _salt,
        uint64 _expiry,
        bytes calldata _spendWithPermitSig
    ) external override onlyAuthorized {
        require(_expiry > block.timestamp, "Spender: Permit is expired");

        // Validate spend with permit signature
        bytes32 spendWithPermitHash = getEIP712Hash(keccak256(abi.encode(SPEND_WITH_PERMIT_TYPEHASH, _tokenAddr, _user, _recipient, _amount, _salt, _expiry)));
        require(isValidSignature(_user, spendWithPermitHash, bytes(""), _spendWithPermitSig), "Spender: Invalid permit signature");

        // Validate spending is not replayed
        require(!spendingFulfilled[spendWithPermitHash], "Spender: Spending is already fulfilled");
        spendingFulfilled[spendWithPermitHash] = true;

        _transferTokenFromUserTo(_tokenAddr, _user, _recipient, _amount);
    }

    function _transferTokenFromUserTo(
        address _tokenAddr,
        address _user,
        address _recipient,
        uint256 _amount
    ) internal {
        require(!tokenBlacklist[_tokenAddr], "Spender: token is blacklisted");

        if (_tokenAddr == ETH_ADDRESS || _tokenAddr == ZERO_ADDRESS) {
            return;
        }
        // Fix gas stipend for non standard ERC20 transfer in case token contract's SafeMath violation is triggered
        // and all gas are consumed.
        uint256 gasStipend = consumeGasERC20Tokens[_tokenAddr] ? 80000 : gasleft();
        uint256 balanceBefore = IERC20(_tokenAddr).balanceOf(_recipient);

        (bool callSucceed, bytes memory returndata) = address(allowanceTarget).call{ gas: gasStipend }(
            abi.encodeWithSelector(
                IAllowanceTarget.executeCall.selector,
                _tokenAddr,
                abi.encodeWithSelector(IERC20.transferFrom.selector, _user, _recipient, _amount)
            )
        );
        require(callSucceed, "Spender: ERC20 transferFrom failed");

        bytes memory decodedReturnData = abi.decode(returndata, (bytes));
        if (decodedReturnData.length > 0) {
            // Return data is optional
            // Tokens like ZRX returns false on failed transfer
            require(abi.decode(decodedReturnData, (bool)), "Spender: ERC20 transferFrom failed");
        }

        // Check balance
        uint256 balanceAfter = IERC20(_tokenAddr).balanceOf(_recipient);
        require(balanceAfter.sub(balanceBefore) == _amount, "Spender: ERC20 transferFrom amount mismatch");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

pragma solidity >=0.7.0;

interface IAllowanceTarget {
    function setSpenderWithTimelock(address _newSpender) external;

    function completeSetSpender() external;

    function executeCall(address payable _target, bytes calldata _callData) external returns (bytes memory resultData);

    function teardown() external;
}

pragma solidity >=0.7.0;

interface ISpender {
    function spendFromUser(
        address _user,
        address _tokenAddr,
        uint256 _amount
    ) external;

    function spendFromUserTo(
        address _user,
        address _tokenAddr,
        address _receiverAddr,
        uint256 _amount
    ) external;

    function spendFromUserToWithPermit(
        address _tokenAddr,
        address _user,
        address _recipient,
        uint256 _amount,
        uint256 _salt,
        uint64 _expiry,
        bytes calldata _spendWithPermitSig
    ) external;
}

pragma solidity 0.7.6;

abstract contract BaseLibEIP712 {
    /***********************************|
    |             Constants             |
    |__________________________________*/

    // EIP-191 Header
    string public constant EIP191_HEADER = "\x19\x01";

    // EIP712Domain
    string public constant EIP712_DOMAIN_NAME = "Tokenlon";
    string public constant EIP712_DOMAIN_VERSION = "v5";

    // EIP712Domain Separator
    bytes32 public immutable EIP712_DOMAIN_SEPARATOR =
        keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                getChainID(),
                address(this)
            )
        );

    /**
     * @dev Return `chainId`
     */
    function getChainID() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function getEIP712Hash(bytes32 structHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_SEPARATOR, structHash));
    }
}

pragma solidity 0.7.6;

import "@openzeppelin/contracts/cryptography/ECDSA.sol";
import "../interfaces/IERC1271Wallet.sol";
import "./LibBytes.sol";

interface IWallet {
    /// @dev Verifies that a signature is valid.
    /// @param hash Message hash that is signed.
    /// @param signature Proof of signing.
    /// @return isValid Validity of order signature.
    function isValidSignature(bytes32 hash, bytes calldata signature) external view returns (bool isValid);
}

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
abstract contract SignatureValidator {
    using LibBytes for bytes;

    /***********************************|
  |             Variables             |
  |__________________________________*/

    // bytes4(keccak256("isValidSignature(bytes,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE = 0x20c13b0b;

    // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
    bytes4 internal constant ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

    // keccak256("isValidWalletSignature(bytes32,address,bytes)")
    bytes4 internal constant ERC1271_FALLBACK_MAGICVALUE_BYTES32 = 0xb0671381;

    // Allowed signature types.
    enum SignatureType {
        Illegal, // 0x00, default value
        Invalid, // 0x01
        EIP712, // 0x02
        EthSign, // 0x03
        WalletBytes, // 0x04  standard 1271 wallet type
        WalletBytes32, // 0x05  standard 1271 wallet type
        Wallet, // 0x06  0x wallet type for signature compatibility
        NSignatureTypes // 0x07, number of signature types. Always leave at end.
    }

    /***********************************|
  |        Signature Functions        |
  |__________________________________*/

    /**
     * @dev Verifies that a hash has been signed by the given signer.
     * @param _signerAddress  Address that should have signed the given hash.
     * @param _hash           Hash of the EIP-712 encoded data
     * @param _data           Full EIP-712 data structure that was hashed and signed
     * @param _sig            Proof that the hash has been signed by signer.
     *      For non wallet signatures, _sig is expected to be an array tightly encoded as
     *      (bytes32 r, bytes32 s, uint8 v, uint256 nonce, SignatureType sigType)
     * @return isValid True if the address recovered from the provided signature matches the input signer address.
     */
    function isValidSignature(
        address _signerAddress,
        bytes32 _hash,
        bytes memory _data,
        bytes memory _sig
    ) public view returns (bool isValid) {
        require(_sig.length > 0, "SignatureValidator#isValidSignature: length greater than 0 required");

        require(_signerAddress != address(0x0), "SignatureValidator#isValidSignature: invalid signer");

        // Pop last byte off of signature byte array.
        uint8 signatureTypeRaw = uint8(_sig.popLastByte());

        // Ensure signature is supported
        require(signatureTypeRaw < uint8(SignatureType.NSignatureTypes), "SignatureValidator#isValidSignature: unsupported signature");

        // Extract signature type
        SignatureType signatureType = SignatureType(signatureTypeRaw);

        // Variables are not scoped in Solidity.
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

        // Always illegal signature.
        // This is always an implicit option since a signer can create a
        // signature array with invalid type or length. We may as well make
        // it an explicit option. This aids testing and analysis. It is
        // also the initialization value for the enum type.
        if (signatureType == SignatureType.Illegal) {
            revert("SignatureValidator#isValidSignature: illegal signature");

            // Signature using EIP712
        } else if (signatureType == SignatureType.EIP712) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ECDSA.recover(_hash, v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signed using web3.eth_sign() or Ethers wallet.signMessage()
        } else if (signatureType == SignatureType.EthSign) {
            require(_sig.length == 97, "SignatureValidator#isValidSignature: length 97 required");
            r = _sig.readBytes32(0);
            s = _sig.readBytes32(32);
            v = uint8(_sig[64]);
            recovered = ECDSA.recover(ECDSA.toEthSignedMessageHash(_hash), v, r, s);
            isValid = _signerAddress == recovered;
            return isValid;

            // Signature verified by wallet contract with data validation.
        } else if (signatureType == SignatureType.WalletBytes) {
            isValid = ERC1271_MAGICVALUE == IERC1271Wallet(_signerAddress).isValidSignature(_data, _sig);
            return isValid;

            // Signature verified by wallet contract without data validation.
        } else if (signatureType == SignatureType.WalletBytes32) {
            isValid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signerAddress).isValidSignature(_hash, _sig);
            return isValid;
        } else if (signatureType == SignatureType.Wallet) {
            isValid = _isValidWalletSignature(_hash, _signerAddress, _sig);
            return isValid;
        }

        // Anything else is illegal (We do not return false because
        // the signature may actually be valid, just not in a format
        // that we currently support. In this case returning false
        // may lead the caller to incorrectly believe that the
        // signature was invalid.)
        revert("SignatureValidator#isValidSignature: unsupported signature");
    }

    /// @dev Verifies signature using logic defined by Wallet contract.
    /// @param hash Any 32 byte hash.
    /// @param walletAddress Address that should have signed the given hash
    ///                      and defines its own signature verification method.
    /// @param signature Proof that the hash has been signed by signer.
    /// @return isValid True if signature is valid for given wallet..
    function _isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes memory signature
    ) internal view returns (bool isValid) {
        bytes memory _calldata = abi.encodeWithSelector(IWallet(walletAddress).isValidSignature.selector, hash, signature);
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(_calldata, 32)
            let success := staticcall(
                gas(), // forward all gas
                walletAddress, // address of Wallet contract
                cdStart, // pointer to start of input
                mload(_calldata), // length of input
                cdStart, // write output over input
                32 // output size is 32 bytes
            )

            if iszero(eq(returndatasize(), 32)) {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                // Revert with `Error("WALLET_ERROR")`
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                // Signature is valid if call did not revert and returned true
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

pragma solidity >=0.7.0;

interface IERC1271Wallet {
    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided data
     * @dev MUST return the correct magic value if the signature provided is valid for the provided data
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _data       Arbitrary length data signed on the behalf of address(this)
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     *
     */
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4 magicValue);

    /**
     * @notice Verifies whether the provided signature is valid with respect to the provided hash
     * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
     *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
     *   > This function MAY modify Ethereum's state
     * @param _hash       keccak256 hash that was signed
     * @param _signature  Signature byte array associated with _data
     * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
     */
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);
}

/*
  Copyright 2018 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
  http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
  This is a truncated version of the original LibBytes.sol library from ZeroEx.
*/

pragma solidity ^0.7.6;

library LibBytes {
    using LibBytes for bytes;

    /***********************************|
  |        Pop Bytes Functions        |
  |__________________________________*/

    /**
     * @dev Pops the last byte off of a byte array by modifying its length.
     * @param b Byte array that will be modified.
     * @return result The byte that was popped off.
     */
    function popLastByte(bytes memory b) internal pure returns (bytes1 result) {
        require(b.length > 0, "LibBytes#popLastByte: greater than zero length required");

        // Store last byte.
        result = b[b.length - 1];

        assembly {
            // Decrement length of byte array.
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

    /// @dev Reads an address from a position in a byte array.
    /// @param b Byte array containing an address.
    /// @param index Index in byte array of address.
    /// @return result address from byte array.
    function readAddress(bytes memory b, uint256 index) internal pure returns (address result) {
        require(
            b.length >= index + 20, // 20 is length of address
            "LibBytes#readAddress greater or equal to 20 length required"
        );

        // Add offset to index:
        // 1. Arrays are prefixed by 32-byte length parameter (add 32 to index)
        // 2. Account for size difference between address length and 32-byte storage word (subtract 12 from index)
        index += 20;

        // Read address from array memory
        assembly {
            // 1. Add index to address of bytes array
            // 2. Load 32-byte word from memory
            // 3. Apply 20-byte mask to obtain address
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

    /**
     * @dev Reads a bytes32 value from a position in a byte array.
     * @param b Byte array containing a bytes32 value.
     * @param index Index in byte array of bytes32 value.
     * @return result bytes32 value from byte array.
     */
    function readBytes32(bytes memory b, uint256 index) internal pure returns (bytes32 result) {
        require(b.length >= index + 32, "LibBytes#readBytes32 greater or equal to 32 length required");

        // Arrays are prefixed by a 256 bit length parameter
        index += 32;

        // Read the bytes32 from array memory
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

    /// @dev Reads an unpadded bytes4 value from a position in a byte array.
    /// @param b Byte array containing a bytes4 value.
    /// @param index Index in byte array of bytes4 value.
    /// @return result bytes4 value from byte array.
    function readBytes4(bytes memory b, uint256 index) internal pure returns (bytes4 result) {
        require(b.length >= index + 4, "LibBytes#readBytes4 greater or equal to 4 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(bytes memory b, uint256 index) internal pure returns (bytes2 result) {
        require(b.length >= index + 2, "LibBytes#readBytes2 greater or equal to 2 length required");

        // Arrays are prefixed by a 32 byte length field
        index += 32;

        // Read the bytes4 from array memory
        assembly {
            result := mload(add(b, index))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }
}