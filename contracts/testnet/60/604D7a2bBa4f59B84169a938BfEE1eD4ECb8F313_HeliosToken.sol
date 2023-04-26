// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./interfaces/IHeliosToken.sol";

contract HeliosToken is IHeliosToken {
    string public name;
    string public symbol;
    uint256 public totalSupply = 0;
    uint256 public cap = 1_000_000_000 * 10 ** 18;
    uint8 public constant decimals = 18;
    bool public paused = false;

    address public governance;
    address public minter;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 internal constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    modifier onlyGovernance() {
        require(msg.sender == governance, "Only governance");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Only minter");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(_name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );

        _upgradeGovernance(msg.sender);
        _setMinter(msg.sender);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool) {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            require(
                spenderAllowance >= value,
                "ERC20: transfer value exceeds allowance"
            );
            unchecked {
                _approve(from, spender, spenderAllowance - value);
            }
        }

        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "ERC2612: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "ERC2612: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    function mint(address to, uint256 value) external onlyMinter {
        require(value > 0, "ERC20Mintable: mint invalid value");
        _mint(to, value);
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) external {
        address spender = msg.sender;
        uint256 spenderAllowance = allowance[from][spender];

        if (spender != from && spenderAllowance != type(uint256).max) {
            require(
                spenderAllowance >= value,
                "ERC20Burnable: burn value exceeds allowance"
            );
            unchecked {
                _approve(from, spender, spenderAllowance - value);
            }
        }

        _burn(from, value);
    }

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }

    /**
     * @notice Upgrade governance
     */
    function upgradeGovernance(address _governance) external onlyGovernance {
        _upgradeGovernance(_governance);
    }

    function setMinter(address _minter) external onlyGovernance {
        _setMinter(_minter);
    }

    function _mint(address to, uint256 value) internal {
        require(totalSupply + value <= cap, "ERC20Capped: cap exceeded");
        require(to != address(0), "ERC20Mintable: mint to the zero address");

        _beforeTokenTransfer(address(0), to, value);

        totalSupply += value;
        balanceOf[to] += value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        require(
            from != address(0),
            "ERC20Burnable: burn from the zero address"
        );

        _beforeTokenTransfer(from, address(0), value);

        balanceOf[from] -= value;
        totalSupply -= value;
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, value);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _pause() private whenNotPaused {
        paused = true;
        emit Paused(msg.sender);
    }

    function _unpause() private whenPaused {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 value
    ) private whenNotPaused {}

    function _upgradeGovernance(address _governance) private {
        governance = _governance;
        emit UpgradeGovernance(_governance);
    }

    function _setMinter(address _minter) private {
        minter = _minter;
        emit SetMinter(_minter);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC20.sol";

interface IERC2612 is IERC20 {
    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./IERC2612.sol";

interface IHeliosToken is IERC2612 {
    event Paused(address account);
    event Unpaused(address account);
    event UpgradeGovernance(address governance);
    event SetMinter(address minter);

    function cap() external view returns (uint256);

    function governance() external view returns (address);

    function minter() external view returns (address);

    function mint(address to, uint256 value) external;

    function burn(uint256 value) external;

    function burnFrom(address from, uint256 value) external;

    function pause() external;

    function unpause() external;

    function upgradeGovernance(address _governance) external;

    function setMinter(address _minter) external;
}