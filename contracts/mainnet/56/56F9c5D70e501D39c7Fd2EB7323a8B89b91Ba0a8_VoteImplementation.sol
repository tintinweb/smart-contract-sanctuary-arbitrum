// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './token/IERC20.sol';
import './VoteStorage.sol';

contract VoteImplementation is VoteStorage {

    event NewVoteTopic(string topic, uint256 numOptions, uint256 deadline);

    event NewVote(address indexed voter, uint256 option);

    uint256 public constant cooldownTime = 900;

    function initializeVote(string memory topic_, uint256 numOptions_, uint256 deadline_) external _onlyAdmin_ {
        require(block.timestamp > deadline, 'VoteImplementation.initializeVote: still in vote');
        topic = topic_;
        numOptions = numOptions_;
        deadline = deadline_;
        delete voters;
        emit NewVoteTopic(topic_, numOptions_, deadline_);
    }

    function vote(uint256 option) external {
        require(block.timestamp < deadline, 'VoteImplementation.vote: vote ended');
        require(option >= 1 && option <= numOptions, 'VoteImplementation.vote: invalid vote option');
        voters.push(msg.sender);
        votes[msg.sender] = option;
        if (block.timestamp + cooldownTime >= deadline) {
            deadline += cooldownTime;
        }
        emit NewVote(msg.sender, option);
    }


    //================================================================================
    // Convenient query functions
    //================================================================================

    function getVoters() external view returns (address[] memory) {
        return voters;
    }

    function getVotes(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory options = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            options[i] = votes[accounts[i]];
        }
        return options;
    }

    function getVotePowerOnEthereum(address account) public view returns (uint256) {
        address deri = 0xA487bF43cF3b10dffc97A9A744cbB7036965d3b9;
        address uniswapV2Pair = 0xA3DfbF2933FF3d96177bde4928D0F5840eE55600; // DERI-USDT

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);
        // balance in uniswapV2Pair
        uint256 balance2 = IERC20(deri).balanceOf(uniswapV2Pair) * IERC20(uniswapV2Pair).balanceOf(account) / IERC20(uniswapV2Pair).totalSupply();

        return balance1 + balance2;
    }

    function getVotePowerOnBNB(address account) public view returns (uint256) {
        address deri = 0xe60eaf5A997DFAe83739e035b005A33AfdCc6df5;
        address pancakePair = 0xDc7188AC11e124B1fA650b73BA88Bf615Ef15256; // DERI-BUSD
        address poolV2 = 0x26bE73Bdf8C113F3630e4B766cfE6F0670Aa09cF; // DERI-based Inno Pool
        address lToken = 0xC246d0aD04a9029A82862BE2fbd16ab1445b1602; // DERI-based Inno Pool LP Token

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);
        // balance in pancakePair
        uint256 balance2 = IERC20(deri).balanceOf(pancakePair) * IERC20(pancakePair).balanceOf(account) / IERC20(pancakePair).totalSupply();
        // balance in inno pool
        (int256 liquidity, , ) = IPerpetualPool(poolV2).getPoolStateValues();
        uint256 balance3 = uint256(liquidity) * IERC20(lToken).balanceOf(account) / IERC20(lToken).totalSupply();

        return balance1 + balance2 + balance3;
    }

    function getVotePowerOnArbitrum(address account) public view returns (uint256) {
        address deri = 0x21E60EE73F17AC0A411ae5D690f908c3ED66Fe12;

        // balance in wallet
        uint256 balance1 = IERC20(deri).balanceOf(account);

        return balance1;
    }

    function getVotePowersOnEthereum(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnEthereum(accounts[i]);
        }
        return powers;
    }

    function getVotePowersOnBNB(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnBNB(accounts[i]);
        }
        return powers;
    }

    function getVotePowersOnArbitrum(address[] memory accounts) external view returns (uint256[] memory) {
        uint256[] memory powers = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            powers[i] = getVotePowerOnArbitrum(accounts[i]);
        }
        return powers;
    }

}

interface IPerpetualPool {
    function getPoolStateValues() external view returns (int256 liquidity, uint256 lastTimestamp, int256 protocolFeeAccrued);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './utils/Admin.sol';

abstract contract VoteStorage is Admin {

    address public implementation;

    string public topic;

    uint256 public numOptions;

    uint256 public deadline;

    // voters may contain duplicated address, if one submits more than one votes
    address[] public voters;

    // voter address => vote
    // vote starts from 1, 0 is reserved for no vote
    mapping (address => uint256) public votes;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}