// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {iToken} from "./iToken.sol";

contract iTokenManager {
    iToken public cToken;
    iToken public dToken;

    ERC20 public underlying;

    uint256 public emFactor = 5; // 5%
    uint256 public emFactorWhenMoreThan80 = 70; // 70%

    uint256 public spread = 20; // 20%

    uint256 public lastUpdated;

    uint256 public totalCAssets;
    uint256 public totalDAssets;

    address public pool;

    uint256 public ltv;
    uint256 public liqThreshold;

    bytes32 public priceId;

    constructor(ERC20 _underlying, bytes32 _priceId) {
        cToken = new iToken(
            address(this),
            string.concat("c", _underlying.name()),
            string.concat("c", _underlying.symbol())
        );
        dToken = new iToken(
            address(this),
            string.concat("d", _underlying.name()),
            string.concat("d", _underlying.symbol())
        );
        priceId = _priceId;
        pool = msg.sender;
        underlying = _underlying;
        lastUpdated = block.timestamp;
    }

    modifier onlyPool() {
        require(msg.sender == pool);
        _;
    }

    function utilization() public view returns (uint256) {
        uint256 cSupply = cToken.totalSupply();
        uint256 dSupply = dToken.totalSupply();

        if (cSupply == 0 || dSupply == 0) return 0;
        return ((dSupply * 1e18) / cSupply);
    }

    function borrowAPR() public view returns (uint256) {
        uint256 util = utilization();
        if (util != 0) {
            return
                util < 80
                    ? (util * emFactor) / 100
                    : (util * emFactorWhenMoreThan80) / 100;
        } else return 0;
    }

    function supplyAPR() public view returns (uint256) {
        return ((100 - spread) * borrowAPR()) / 100;
    }

    function updateTotalAssets() public {
        uint256 bAPR = borrowAPR();
        uint256 timeElapsed = block.timestamp - lastUpdated;

        if (bAPR != 0 && timeElapsed != 0) {
            totalDAssets +=
                (totalDAssets * bAPR * timeElapsed) /
                (100 * 365 * 24 * 3600 * 1e18);

            totalCAssets +=
                (totalCAssets * (100 - spread) * bAPR * timeElapsed) /
                (100 * 100 * 365 * 24 * 3600 * 1e18);
        }

        lastUpdated = block.timestamp;
    }

    function underlyingToInterestToken(
        uint256 amount,
        bool debt
    ) public view returns (uint256) {
        if (debt == true) {
            uint256 dSupply = dToken.totalSupply();
            if (dSupply == 0 || totalDAssets == 0) return amount;
            return (amount * dSupply) / totalDAssets;
        } else {
            uint256 cSupply = cToken.totalSupply();
            if (cSupply == 0 || totalCAssets == 0) return amount;
            return (amount * cSupply) / totalCAssets;
        }
    }

    function interestToUnderlyingToken(
        uint256 amount,
        bool debt
    ) public view returns (uint256) {
        if (debt == true) {
            uint256 dSupply = dToken.totalSupply();
            if (dSupply == 0 || totalDAssets == 0) return amount;
            return (amount * totalDAssets) / dToken.totalSupply();
        } else {
            uint256 cSupply = cToken.totalSupply();
            if (cSupply == 0 || totalCAssets == 0) return amount;
            return (amount * totalCAssets) / cToken.totalSupply();
        }
    }

    function deposit(address user, uint256 _amount) public onlyPool {
        underlying.transferFrom(user, address(this), _amount);
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, false);
        totalCAssets += _amount;
        cToken.mint(user, shares);
    }

    function withdraw(address user, uint256 _amount) public onlyPool {
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, false);
        totalCAssets -= _amount;
        cToken.burn(user, shares);
        underlying.transfer(user, _amount);
    }

    function borrow(address user, uint256 _amount) public onlyPool {
        require(
            _amount <= underlying.balanceOf(address(this)),
            "not enough liquidity to borrow"
        );
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, true);
        totalDAssets += _amount;
        dToken.mint(user, shares);
        underlying.transfer(user, _amount);
    }

    function repay(address user, uint256 _amount) public onlyPool {
        underlying.transferFrom(user, address(this), _amount);
        updateTotalAssets();
        uint256 shares = underlyingToInterestToken(_amount, true);
        totalDAssets -= _amount;
        dToken.burn(user, shares);
    }

    function userBalanceInUnderlying(
        address user
    ) public view returns (uint256, uint256) {
        uint256 cSupply = cToken.totalSupply();
        uint256 cBalance = cToken.balanceOf(user);

        uint256 collateral = cSupply == 0 || cBalance == 0
            ? 0
            : (cBalance * totalCAssets) / cSupply;

        uint256 dSupply = dToken.totalSupply();
        uint256 dBalance = dToken.balanceOf(user);

        uint256 debt = dSupply == 0 || dBalance == 0
            ? 0
            : (dBalance * totalDAssets) / dSupply;
        return (collateral, debt);
    }

    function liquidate(
        address liquidator,
        address user,
        uint256 _amount
    ) public onlyPool {
        underlying.transferFrom(liquidator, address(this), _amount);
        updateTotalAssets();
        uint256 dShares = underlyingToInterestToken(_amount, true);
        totalDAssets -= _amount;
        dToken.burn(user, dShares);
        uint256 cShares = underlyingToInterestToken(_amount, false);
        totalCAssets -= _amount;
        cToken.burn(user, cShares);
        underlying.transfer(user, ((_amount * 100) / 95));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract iToken is ERC20 {
    bool transferrable = false;

    address public manager;

    uint256 lastUpdated;

    constructor(
        address _manager,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, 18) {
        manager = _manager;
    }

    modifier noTransfer() {
        require(transferrable);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override noTransfer returns (bool) {}

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override noTransfer returns (bool) {}

    function mint(address to, uint256 amt) public onlyManager {
        _mint(to, amt);
    }

    function burn(address from, uint256 amt) public onlyManager {
        _burn(from, amt);
    }
}