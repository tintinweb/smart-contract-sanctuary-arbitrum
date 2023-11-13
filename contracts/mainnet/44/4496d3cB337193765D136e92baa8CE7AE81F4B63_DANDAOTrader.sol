/**
 *Submitted for verification at Arbiscan.io on 2023-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;
struct ParamsCall {
    address _pool;
    address _router;
    bytes _bytes;
}
struct memberStruct {
    address user;
    uint256 times;
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract DANDAOTrader {
    string public name = "DANDAOTraderV2";
    address private owner;
    address private admin;
    address public ETH;
    uint256 public price = 0;
    mapping(address => uint256) private members;

    constructor(address _ETH) {
        owner = msg.sender;
        admin = msg.sender;
        ETH = _ETH;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    modifier onlyAdmin() {
        require(admin == msg.sender || owner == msg.sender);
        _;
    }

    function setAdmin(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid Address");
        admin = newAddress;
    }

    function transferOwnership(address newAddress) external onlyOwner {
        require(newAddress != address(0), "Invalid Address");
        owner = newAddress;
    }

    function setBaseData(uint256 _price) external onlyAdmin {
        price = _price;
    }

    function batchSetMember(memberStruct[] memory users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            memberStruct memory user = users[i];
            members[user.user] = user.times;
        }
    }

    function withdrawERC20(
        address _recipient,
        address erc20address
    ) external onlyOwner {
        IERC20 fountain = IERC20(erc20address);
        uint256 balance = fountain.balanceOf(address(this));
        fountain.transfer(_recipient, balance);
    }

    function withdrawETH(address _recipient) external onlyOwner {
        (bool rt, ) = payable(_recipient).call{value: address(this).balance}(
            ""
        );
        require(rt);
    }

    function FuckTuGouSell(
        address target,
        address router,
        uint256 amountIn,
        uint256 amountMinOut,
        bytes memory _bytes
    ) public payable {
        require(msg.value == price, "Price Error");
        require(
            IERC20(target).allowance(msg.sender, address(this)) >= amountIn,
            "Approve Error"
        );
        require(
            IERC20(target).balanceOf(msg.sender) >= amountIn,
            "Balance Too Low"
        );
        IERC20(target).transferFrom(msg.sender, address(this), amountIn);
        (uint256 preETHBalance, uint256 preWETHBalance) = checkETHBalance(
            msg.sender
        );
        if (IERC20(target).allowance(address(this), router) < amountIn) {
            IERC20(target).approve(router, IERC20(target).totalSupply());
        }
        (bool rt, ) = payable(router).call{value: 0}(_bytes);
        require(rt, "Swap Error");
        if (amountMinOut > 0) {
            (uint256 nextETHBalance, uint256 nextWETHBalance) = checkETHBalance(
                msg.sender
            );
            if (nextETHBalance > preETHBalance) {
                require(
                    nextETHBalance - preETHBalance >= amountMinOut,
                    "Receive Too Low"
                );
            }
            if (nextWETHBalance > preWETHBalance) {
                require(
                    nextWETHBalance - preWETHBalance >= amountMinOut,
                    "Receive Too Low"
                );
            }
        }
        if (members[msg.sender] > 0) {
            (bool rts, bytes memory resons) = payable(msg.sender).call{
                value: msg.value
            }("");
            require(rts, string(resons));
            members[msg.sender] = members[msg.sender] - 1;
        }
    }

    function checkETHBalance(
        address _sender
    ) public view returns (uint256 preETHBalance, uint256 preWETHBalance) {
        preETHBalance = address(_sender).balance;
        preWETHBalance = IERC20(ETH).balanceOf(_sender);
    }

    function FuckTuGouBuy(
        address target,
        uint256 amountMinOut,
        uint256 percent,
        ParamsCall[] memory params
    ) public payable {
        (uint256 index, uint256 userPreBalance) = checkPoolBalance(
            target,
            msg.sender,
            percent,
            params
        );
        uint256 amount;
        if (members[msg.sender] < 1) {
            amount = msg.value - price;
        } else {
            amount = msg.value;
            members[msg.sender] = members[msg.sender] - 1;
        }
        (bool rt, bytes memory reson) = payable(params[index]._router).call{
            value: amount
        }(params[index]._bytes);
        require(rt, string(reson));
        if (amountMinOut > 0) {
            uint256 userNextBalance = IERC20(target).balanceOf(msg.sender);
            uint256 userCurrentBalance = userNextBalance - userPreBalance;
            require(userCurrentBalance >= amountMinOut, "Receive Too Low");
        }
    }

    function checkPoolBalance(
        address target,
        address sender,
        uint256 percent,
        ParamsCall[] memory params
    ) internal view returns (uint256, uint256) {
        uint256 _coinBalance;
        uint256 _index;
        for (uint256 i = 0; i < params.length; i++) {
            uint256 poolBalance = IERC20(target).balanceOf(params[i]._pool);
            if (poolBalance > _coinBalance) {
                _index = i;
                _coinBalance = poolBalance;
            }
        }
        require(_coinBalance > 0, "Not Add Liquidity");
        if (percent > 0) {
            checkPoolPercent(target, _coinBalance, percent);
        }
        uint256 _userPreBalance = IERC20(target).balanceOf(sender);
        return (_index, _userPreBalance);
    }

    function checkPoolPercent(
        address target,
        uint256 _coinBalance,
        uint256 percent
    ) internal view {
        uint256 totalSupply = IERC20(target).totalSupply();
        uint256 poolpercent = (_coinBalance * 1000) / totalSupply;
        require(poolpercent > percent, "Pool Percent Low");
    }
}