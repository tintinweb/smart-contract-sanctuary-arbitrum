// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./interfaces/IERC20.sol";
import "./interfaces/IDepositWallet.sol";
import "./libraries/TransferHelper.sol";

contract DepositWallet is IDepositWallet {
    address public treasury;

    constructor(address treasury_) {
        treasury = treasury_;
    }

    receive() external payable {
        TransferHelper.safeTransferETH(treasury, msg.value);
        emit EtherCollected(treasury, msg.value);
    }

    function collectETH() external override {
        uint256 balance = address(this).balance;
        TransferHelper.safeTransferETH(treasury, balance);
        emit EtherCollected(treasury, balance);
    }

    function collectTokens(address[] memory tokens) external override {
        uint256 balance_;
        for (uint256 i = 0; i < tokens.length; i++) {
            balance_ = IERC20(tokens[i]).balanceOf(address(this));
            if (balance_ > 0) {
                TransferHelper.safeTransfer(tokens[i], treasury, balance_);
                emit TokenCollected(treasury, tokens[i], balance_);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "./interfaces/IDepositWalletFactory.sol";
import "./DepositWallet.sol";

contract DepositWalletFactory is IDepositWalletFactory {
    address public treasury;
    mapping(bytes32 => address) public getWallet;

    constructor(address treasury_) {
        treasury = treasury_;
    }

    function predicteWallet(bytes32 salt) external view returns (address wallet) {
        wallet = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(DepositWallet).creationCode,
                abi.encode(treasury)
            ))
        )))));
    }

    // salt like 0x68656c6c6f000000000000000000000000000000000000000000000000000000
    function createWallet(bytes32 salt) external override returns (address wallet) {
        require(getWallet[salt] == address(0), "used salt");
        wallet = address(new DepositWallet{salt: salt}(treasury));
        getWallet[salt] = wallet;
        emit WalletCreated(salt, wallet);
    }

    function batchCreateWallets(bytes32[] memory salts) external override returns (address[] memory wallets) {
        wallets = new address[](salts.length);
        for (uint256 i = 0; i < salts.length; i++) {
            require(getWallet[salts[i]] == address(0), "used salt");
            wallets[i] = address(new DepositWallet{salt: salts[i]}(treasury));
            getWallet[salts[i]] = wallets[i];
        }
        emit BatchWalletsCreated(salts, wallets);
    }

    function batchCollectTokens(address[] memory wallets, address[] memory tokens) external override {
        for (uint256 i = 0; i < wallets.length; i++) {
            DepositWallet wallet = DepositWallet(payable(wallets[i]));
            wallet.collectTokens(tokens);
        }
    }

    function batchCollectETH(address[] memory wallets) external override {
        for (uint256 i = 0; i < wallets.length; i++) {
            DepositWallet wallet = DepositWallet(payable(wallets[i]));
            wallet.collectETH();
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IDepositWallet {
    event EtherCollected(address indexed treasury, uint256 amount);
    event TokenCollected(address indexed treasury, address indexed token, uint256 amount);

    function treasury() external view returns (address);

    function collectETH() external;

    function collectTokens(address[] memory tokens) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

interface IDepositWalletFactory {
    event WalletCreated(bytes32 indexed salt, address indexed wallet);
    event BatchWalletsCreated(bytes32[] salts, address[] wallets);

    function treasury() external returns (address);

    function getWallet(bytes32 salt) external returns (address);

    function createWallet(bytes32 salt) external returns (address wallet);

    function batchCreateWallets(bytes32[] memory salts) external returns (address[] memory wallets);

    function batchCollectTokens(address[] memory wallets, address[] memory tokens) external;

    function batchCollectETH(address[] memory wallets) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}