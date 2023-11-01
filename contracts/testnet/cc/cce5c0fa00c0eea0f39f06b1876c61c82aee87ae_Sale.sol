//  /$$   /$$ /$$$$$$$$ /$$$$$$ /$$   /$$  /$$$$$$         /$$$$$$   /$$$$$$  /$$       /$$$$$$$$
// | $$  /$$/| $$_____/|_  $$_/| $$  /$$/ /$$__  $$       /$$__  $$ /$$__  $$| $$      | $$_____/
// | $$ /$$/ | $$        | $$  | $$ /$$/ | $$  \ $$      | $$  \__/| $$  \ $$| $$      | $$      
// | $$$$$/  | $$$$$     | $$  | $$$$$/  | $$  | $$      |  $$$$$$ | $$$$$$$$| $$      | $$$$$   
// | $$  $$  | $$__/     | $$  | $$  $$  | $$  | $$       \____  $$| $$__  $$| $$      | $$__/   
// | $$\  $$ | $$        | $$  | $$\  $$ | $$  | $$       /$$  \ $$| $$  | $$| $$      | $$      
// | $$ \  $$| $$$$$$$$ /$$$$$$| $$ \  $$|  $$$$$$/      |  $$$$$$/| $$  | $$| $$$$$$$$| $$$$$$$$
// |__/  \__/|________/|______/|__/  \__/ \______/        \______/ |__/  |__/|________/|________/

// Official contract for KEIKO public sale.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Owned} from "solmate/auth/Owned.sol";

contract Sale {
    bool public saleStarted;
    bool public salePaused;
    uint256 public saleDuration = 120; // 1 week - 604406
    uint256 public saleStartBlock;

    address private eUSD = 0xBB526C1F7a1e1730cEE790dBe1026137b54c6c55;
    address private DAI = 0x52410d0c2f01A9fa7b6Dab445215187d30F22D5F;
    address private USDC = 0x8Ee9775Ed9A87024953F7c0A15c6CA8a62D5114C;

    mapping(address => uint256) public userDepositedETH;
    mapping(address => uint256) public userDepositedDAI;
    mapping(address => uint256) public userDepositedEUSD;
    mapping(address => uint256) public userDepositedUSDC;

    mapping(address => bool) alreadyWithdrawETH;
    mapping(address => bool) alreadyWithdrawERC;

    uint256 public depositedEther;
    uint256 public depositedEUSD;
    uint256 public depositedDAI;
    uint256 public depositedUSDC;

    uint256 public saleETHSoftCap = 0.0001 ether; // 1000 ether
    uint256 public saleERCSoftCap = 250 * 1e21; // 250.000

    function depositETH() payable public {
        require(saleStarted == true, "Sale has not started yet");
        require(salePaused == false, "Sale has been halted");
        require(block.number < saleStartBlock + saleDuration, "Sell has ended");
        require(msg.value > 0, "amount must be greater than 0");
        require(msg.value > 0.00001 ether, "Minimum deposit: 0.1 ETH");

        userDepositedETH[msg.sender] += msg.value;
        depositedEther += msg.value;

    }

    function depositERC20(address _token, uint256 _amount) public {
        require(saleStarted == true, "Sale has not started yet");
        require(salePaused == false, "Sale has been halted");
        require(block.number < saleStartBlock + saleDuration, "Sell has ended");
        require(_amount > 250 * 1e18, "Minimum deposit: 250");

        if (_token == eUSD || _token == DAI || _token == USDC) {
            if (_token == eUSD) {
                ERC20(_token).transferFrom(msg.sender, address(this), _amount);
                userDepositedEUSD[msg.sender] += _amount;
                depositedEUSD += _amount;

            } else if (_token == DAI) {
                ERC20(_token).transferFrom(msg.sender, address(this), _amount);
                userDepositedDAI[msg.sender] += _amount;
                depositedDAI += _amount;

            } else {
                ERC20(_token).transferFrom(msg.sender, address(this), _amount);
                userDepositedUSDC[msg.sender] += _amount;
                depositedUSDC += _amount;
            }
        }
    }

    function withdrawExcessETH() public {
        require(saleStarted == true, "Sell has not started yet");
        require(block.timestamp > saleStartBlock + saleDuration, "Sale has not ended yet");
        require(depositedEther > saleETHSoftCap, "No excess ETH to withdraw");
        require(userDepositedETH[msg.sender] > 0, "No ETH to withdraw");
        require(alreadyWithdrawETH[msg.sender] == false, "Nothing left to withdraw");

        uint256 excessAmount = depositedEther - saleETHSoftCap;
        uint256 percentage = calculateDepositPercentage(msg.sender, userDepositedETH[msg.sender]);
        uint256 amount = calculateUserExcess(excessAmount, percentage);
    
        payable(msg.sender).transfer(amount);
        alreadyWithdrawETH[msg.sender] = true;
    }

    function withdrawExcessERC20() public {
        require(saleStarted == true, "Sell has not started yet");
        require(block.timestamp > saleStartBlock + saleDuration, "Sale has not ended yet");
        require(alreadyWithdrawERC[msg.sender] == false, "Nothing left to withdraw");

        if (userDepositedEUSD[msg.sender] > 0) {
            require(depositedEUSD > saleERCSoftCap, "No excess eUSD to withdraw");

            uint256 excessAmount = depositedEUSD - saleERCSoftCap;
            uint256 percentage = calculateDepositPercentage(msg.sender, userDepositedEUSD[msg.sender]);
            uint256 amount = calculateUserExcess(excessAmount, percentage);

            ERC20(eUSD).transfer(msg.sender, amount);
            alreadyWithdrawERC[msg.sender] = true;
        }

        if (userDepositedDAI[msg.sender] > 0) {
            require(depositedDAI > saleERCSoftCap, "No excess DAI to withdraw");

            uint256 excessAmount = depositedDAI - saleERCSoftCap;
            uint256 percentage = calculateDepositPercentage(msg.sender, userDepositedDAI[msg.sender]);
            uint256 amount = calculateUserExcess(excessAmount, percentage);

            ERC20(DAI).transfer(msg.sender, amount);
            alreadyWithdrawERC[msg.sender] = true;
        }

        if (userDepositedUSDC[msg.sender] > 0) {
            require(depositedUSDC > saleERCSoftCap, "No excess USDC to withdraw");

            uint256 excessAmount = depositedUSDC - saleERCSoftCap;
            uint256 percentage = calculateDepositPercentage(msg.sender, userDepositedUSDC[msg.sender]);
            uint256 amount = calculateUserExcess(excessAmount, percentage);

            ERC20(USDC).transfer(msg.sender, amount);
            alreadyWithdrawERC[msg.sender] = true;
        }
    }

    function startSale() public {
        if (saleStartBlock == 0) {
            saleStartBlock = block.timestamp;
            saleStarted = true;
        }
    }

    function pauseSale(bool _paused) public {
        salePaused = _paused;
    }

    function calculateUserExcess(uint256 _excessAmount, uint256 _percentage) private pure returns (uint256) {
        return (_excessAmount * _percentage) / 100;
    }

    function calculateDepositPercentage(address _user, uint256 _deposited) private view returns (uint256)  {
        uint256 percentage = (_deposited / depositedEther) * 100;
        return percentage;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

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

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}