/**
 *Submitted for verification at BscScan.com on 2023-09-08
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Basic interface for a BEP20 token on the Binance Smart Chain (BSC).
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event ExecutedTransaction(
        address indexed target,
        uint256 value,
        bytes data
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
}

// Library to safely conduct arithmetic operations.
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// Guard against reentrancy attacks.
contract ReentrancyGuard {
    uint256 private _guardCounter = 1;
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(
            localCounter == _guardCounter,
            "ReentrancyGuard: reentrant call"
        );
    }
}

// Agatech BEP20 token implementation on BSC.
contract Agatech is IERC20, ReentrancyGuard {
    using SafeMath for uint256;

    string public constant name = "Agatech";
    string public constant symbol = "AGATA";
    uint8 public constant decimals = 18;
    uint256 private _totalSupply = 10000000 * (10 ** uint256(decimals));
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address public AgatechMultisig;

    constructor() {
        // Initialize addresses for various wallets used for fund distribution based on tokenomics.
        // These wallets are presumably Gnosis multisig wallets for increased security and governance control.

        // The main multisig wallet address for Agatech.
        AgatechMultisig = 0xB21bB842f61A50dB973408becd78E597EfC4c910;
        // Address of the Deployer
        address deployerWallet = 0x6672134E8838468A10d10a1E4108a0F74D3a495E;
        // Address for the team's vesting wallet.
        address teamVestingWallet = 0xB633cc81E237ca386c1Ca192eFcdB00AB1AE75BB;
        // Address for the development fund wallet.
        address developmentFundWallet = 0x3d8f408991015cAbCC319c48CcfdD1Fe04e6c37e;
        // Address for platform and features development.
        address platformsFeaturesWallet = 0x6AB5bd5ba5E10EBd588b925B2a043A0b95Ed2895;
        // Address for strategic alliances wallet.
        address strategicAlliancesWallet = 0xc7D4Bb84ED88795cDA36fE1Fdd3814D4d54128c7;
        // Address for the treasury reserves wallet.
        address treasuryReservesWallet = 0xF78aA5c618b541927E91fF628C0dB74d230a694b;
        // Address for the AgaPaid initiative wallet.
        address agaPaidInitiativeWallet = 0x372788630a8fe0ee0aF4899359bCe1fc2D2CA4F6;

        // Safety checks to ensure that none of the provided addresses are the zero address.
        // Using the zero address could lead to irrecoverable tokens.
        require(
            AgatechMultisig != address(0),
            "AgatechMultisig: Zero address is not allowed"
        );
        require(
            deployerWallet != address(0),
            "deployerWallet: Zero address is not allowed"
        );
        require(
            teamVestingWallet != address(0),
            "TeamVestingWallet: Zero address is not allowed"
        );
        require(
            developmentFundWallet != address(0),
            "DevelopmentFundWallet: Zero address is not allowed"
        );
        require(
            platformsFeaturesWallet != address(0),
            "PlatformsFeaturesWallet: Zero address is not allowed"
        );
        require(
            strategicAlliancesWallet != address(0),
            "StrategicAlliancesWallet: Zero address is not allowed"
        );
        require(
            treasuryReservesWallet != address(0),
            "TreasuryReservesWallet: Zero address is not allowed"
        );
        require(
            agaPaidInitiativeWallet != address(0),
            "AgaPaidInitiativeWallet: Zero address is not allowed"
        );

        // Token distribution according to predefined tokenomics.
        // The token distribution percentages are multiplied and divided accordingly
        // to ensure the right amount of tokens are sent to each address.
        _balances[deployerWallet] = _totalSupply.mul(5).div(100); // 5% of the total supply goes to the deployer's address for liquidity purposes.
        _balances[AgatechMultisig] = _totalSupply.mul(40).div(100); // 40% for the AgatechMultisig.
        _balances[teamVestingWallet] = _totalSupply.mul(10).div(100); // 10% for team vesting.
        _balances[developmentFundWallet] = _totalSupply.mul(10).div(100); // 10% for development fund.
        _balances[platformsFeaturesWallet] = _totalSupply.mul(20).div(100); // 20% for platform and features.
        _balances[strategicAlliancesWallet] = _totalSupply.mul(5).div(100); // 5% for strategic alliances.
        _balances[treasuryReservesWallet] = _totalSupply.mul(5).div(100); // 5% for treasury reserves.
        _balances[agaPaidInitiativeWallet] = _totalSupply.mul(5).div(100); // 5% for the AgaPaid initiative.

        // Emitting transfer events for each distribution for transparency and ledger tracking.
        // Each Transfer event indicates that a certain amount of tokens
        // were minted and assigned to the respective address.
        emit Transfer(address(0), deployerWallet, _balances[deployerWallet]); // Transfer event for the deployer's address.
        emit Transfer(address(0), AgatechMultisig, _balances[AgatechMultisig]); // For AgatechMultisig.
        emit Transfer(
            address(0),
            teamVestingWallet,
            _balances[teamVestingWallet]
        ); // For team vesting.
        emit Transfer(
            address(0),
            developmentFundWallet,
            _balances[developmentFundWallet]
        ); // For development fund.
        emit Transfer(
            address(0),
            platformsFeaturesWallet,
            _balances[platformsFeaturesWallet]
        ); // For platforms and features.
        emit Transfer(
            address(0),
            strategicAlliancesWallet,
            _balances[strategicAlliancesWallet]
        ); // For strategic alliances.
        emit Transfer(
            address(0),
            treasuryReservesWallet,
            _balances[treasuryReservesWallet]
        ); // For treasury reserves.
        emit Transfer(
            address(0),
            agaPaidInitiativeWallet,
            _balances[agaPaidInitiativeWallet]
        ); // For AgaPaid initiative.
    }

    // Modifier to ensure that only the contract's owner can execute certain functions.
    // Ensure that the caller is the owner of the contract.
    // Continue with the function execution after the modifier.
    modifier onlyOwner() {
        require(msg.sender == AgatechMultisig, "Not the contract owner");
        _;
    }

    // Implementation of the standard BEP20 function to get the total supply of the token.
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    // Implementation of the standard BEP20 function to get the balance of a specific account.
    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return _balances[account];
    }

    // Implementation of the standard BEP20 function that allows the transfer of tokens between addresses.
    function transfer(
        address recipient,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Implementation of the standard BEP20 function to check the allowance set by an owner for a spender.
    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // Implementation of the standard BEP20 function that sets an allowance for a spender by the owner.
    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Implementation of the standard BEP20 function to transfer tokens on behalf of someone,
    // taking into account the allowance set by the owner for the msg.sender.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(
            currentAllowance >= amount,
            "Transfer amount exceeds allowance"
        );
        _approve(sender, msg.sender, currentAllowance.sub(amount));
        return true;
    }

    // Internal utility function for transferring tokens from one address to another.
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "Cannot transfer from the zero address");
        require(recipient != address(0), "Cannot transfer to the zero address");
        require(amount <= _balances[sender], "Transfer amount exceeds balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    // Internal utility function to set the allowance.
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}