// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8;

import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";
import {Math} from "./libraries/Math.sol";

contract RebasingERC20 {
    using SafeCastLib for uint256;

    uint256 internal constant MAX_INCREASE = 110_000_000;
    uint256 internal constant MAX_DECREASE = 90_000_000;
    uint256 internal constant CHANGE_PRECISION = 100_000_000;
    uint256 internal constant MIN_DURATION = 1 hours;
    
    string public name;
    string public symbol;
    uint8 public immutable decimals;

    struct Rebase {
        uint128 totalShares;
        uint128 totalSupply;
        uint32 change;
        uint32 startTime;
        uint32 endTime;
    }

    Rebase public rebase = Rebase({
        totalShares: 0,
        totalSupply: 0,
        change: uint32(CHANGE_PRECISION),
        startTime: 0,
        endTime: 0
    });

    /// @dev Instead of keeping track of user balances, we keep track of the user's share of the total supply.
    mapping(address => uint256) internal _shares;
    /// @dev Allowances are nominated in token amounts, not token shares.
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event SetRebase(uint32 change, uint32 startTime, uint32 endTime);

    error InvalidTimeFrame();
    error InvalidRebase();

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return rebase.totalSupply * rebaseProgress() / CHANGE_PRECISION;
    }

    function rebaseProgress() public view returns (uint256) {
        uint256 currentTime = block.timestamp;
        if (currentTime <= rebase.startTime) {
            return CHANGE_PRECISION;
        } else if (currentTime <= rebase.endTime) {
            return Math.interpolate(CHANGE_PRECISION, rebase.change, currentTime - rebase.startTime, rebase.endTime - rebase.startTime);
        } else {
            return rebase.change;
        }
    }

    function totalShares() public view returns (uint256) {
        return rebase.totalShares;
    }

    function getSharesForTokenAmount(uint256 amount) public view returns (uint256) {
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) return amount;
        return amount * totalShares() / _totalSupply;
    }

    function getTokenAmountForShares(uint256 shares) public view returns (uint256) {
        uint256 _totalShares = totalShares();
        if (_totalShares == 0) return shares;
        return shares * totalSupply() / _totalShares;
    }

    function balanceOf(address account) public view returns (uint256) {
        return getTokenAmountForShares(_shares[account]);
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferShares(address to, uint256 shares) public returns (bool) {
        _shares[msg.sender] -= shares;
        unchecked {
            _shares[to] += shares;
        }
        emit Transfer(msg.sender, to, getTokenAmountForShares(shares));
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _decreaseAllowance(from, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _decreaseAllowance(address from, uint256 amount) internal {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;
    }

    function _transfer(address from, address to, uint256 amount) internal virtual {
        uint256 shares = getSharesForTokenAmount(amount);
        _shares[from] -= shares;
        unchecked {
            _shares[to] += shares;
        }
        emit Transfer(from, to, amount);
    }

    function _setRebase(uint32 change, uint32 startTime, uint32 endTime) internal {
        if (startTime < block.timestamp || endTime - startTime < MIN_DURATION) {
            revert InvalidTimeFrame();
        }
        uint256 _totalSupply = totalSupply();
        if (change > MAX_INCREASE || change < MAX_DECREASE || _totalSupply * change / CHANGE_PRECISION > type(uint128).max) {
            revert InvalidRebase();
        }
        rebase.totalSupply = _totalSupply.safeCastTo128();
        rebase.change = change;
        rebase.startTime = startTime;
        rebase.endTime = endTime;
        emit SetRebase(change, startTime, endTime);
    }

    function _mint(address to, uint256 amount) internal {
        uint256 shares = getSharesForTokenAmount(amount);
        rebase.totalShares += shares.safeCastTo128();
        // We calculate what the change in rebase.totalSupply should be, so that totalSupply() returns the correct value.
        uint256 retrospectiveSupplyIncrease = amount * CHANGE_PRECISION / rebaseProgress();
        rebase.totalSupply += retrospectiveSupplyIncrease.safeCastTo128();
        unchecked {
            _shares[to] += shares;
        }
        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal {
        uint128 shares = getSharesForTokenAmount(amount).safeCastTo128();
        rebase.totalShares -= shares;
        uint256 retrospectiveSupplyDecrease = amount * CHANGE_PRECISION / rebaseProgress();
        rebase.totalSupply -= retrospectiveSupplyDecrease.safeCastTo128();
        _shares[from] -= shares;
        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

import {RebasingERC20} from "./RebasingERC20.sol";

contract RebasingERC20Permit is RebasingERC20 {
    error PermitExpired();
    error InvalidSigner();

    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) RebasingERC20(_name, _symbol, _decimals) {
        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.19;

import {RebasingERC20Permit} from "./RebasingERC20Permit.sol";
import {Whitelist} from "./Whitelist.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Token is RebasingERC20Permit, Owned {
    Whitelist public immutable whitelist;

    bool public paused = true;

    error Paused();
    error NotWhitelisted();

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    modifier isWhitelisted(address account) {
        if (!whitelist.isWhitelisted(account)) revert NotWhitelisted();
        _;
    }

    constructor(Whitelist _whitelist)
        RebasingERC20Permit("XYZ", "XYZ", 6)
        Owned(msg.sender)
    {
        whitelist = _whitelist;
    }

    // Owner actions.

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setRebase(uint32 change, uint32 startTime, uint32 endTime) external onlyOwner {
        _setRebase(change, startTime, endTime);
    }

    function mint(address to, uint256 amount) external onlyOwner isWhitelisted(to) {
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal override whenNotPaused isWhitelisted(to) {
        super._transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "solmate/auth/Owned.sol";
import "./libraries/MerkleVerifier.sol";

contract Whitelist is Owned {
    mapping(address => bool) public isWhitelisted;

    bytes32 public merkleRoot;

    event Whitelisted(address indexed account, bool whitelisted);

    error InvalidProof();
    error MisMatchArrayLength();

    constructor() Owned(msg.sender) {}

    function verify(bytes32[] memory proof, address user, uint256 index) public view returns (bool) {
        return MerkleVerifier.verify(proof, merkleRoot, keccak256(abi.encodePacked(user)), index);
    }

    function whitelistAddress(bytes32[] memory proof, address user, uint256 index) external {
        if (!verify(proof, user, index)) revert InvalidProof();
        isWhitelisted[user] = true;
        emit Whitelisted(user, true);
    }

    function setMerkleRoot(bytes32 newMerkleRoot) external onlyOwner {
        merkleRoot = newMerkleRoot;
    }

    function setDirectWhitelist(address account, bool whitelisted) external onlyOwner {
        isWhitelisted[account] = whitelisted;
        emit Whitelisted(account, whitelisted);
    }

    function setDirectWhitelistBatch(address[] calldata accounts, bool[] calldata whitelisted) external onlyOwner {
        if (accounts.length != whitelisted.length) revert MisMatchArrayLength();
        for (uint256 i = 0; i < accounts.length; i++) {
            isWhitelisted[accounts[i]] = whitelisted[i];
            emit Whitelisted(accounts[i], whitelisted[i]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

library Math {
    function diff(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : b - a;
    }

    function interpolate(uint256 firstValue, uint256 secondValue, uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
        uint256 difference = diff(firstValue, secondValue);
        difference = difference * numerator / denominator;
        return firstValue < secondValue ? firstValue + difference : firstValue - difference;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8;

library MerkleVerifier {
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf, uint256 index) internal pure returns (bool) {
        bytes32 node = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                node = keccak256(abi.encodePacked(node, proofElement));
            } else {
                node = keccak256(abi.encodePacked(proofElement, node));
            }

            index = index / 2;
        }

        return node == root;
    }
}