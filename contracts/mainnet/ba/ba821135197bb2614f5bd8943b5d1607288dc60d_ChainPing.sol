/**
 *Submitted for verification at Arbiscan on 2023-08-03
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

interface IStargateRouter {
    function sgReceive(
        uint16 _chainId, 
        bytes memory _srcAddress, 
        uint _nonce, 
        address _token, 
        uint amountLD, 
        bytes memory _payload
    ) external;
}

contract ChainPing is IStargateRouter {
    address public owner;
    address public stargateRouter;
    event ReceivedOnDestination(address token, uint256 amountLD, bool success);

    modifier onlyOwner {
        require(owner == msg.sender, "Invalid Owner");
        _;
    }

    constructor(address _stargateRouter) {
        owner = msg.sender;
        stargateRouter = _stargateRouter;
    }

    receive() external payable {}

    function balanceOf(address token) public view returns(uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function setRouter(address _stargateRouter) external onlyOwner {
        stargateRouter = _stargateRouter;
    }

    function rescueFunds(address token) public onlyOwner {
        if (token == address(0)) {
            payable(msg.sender).transfer(address(this).balance);
        } else {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    function approve(address token, uint256 amount) public onlyOwner {
        IERC20(token).approve(msg.sender, 0);
        IERC20(token).approve(msg.sender, amount);
    }

    /// @param _chainId The remote chainId sending the tokens
    /// @param _srcAddress The remote Bridge address
    /// @param _nonce The message ordering nonce
    /// @param _token The token contract on the local chain
    /// @param amountLD The qty of local _token contract tokens  
    /// @param _payload The bytes containing the toAddress
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint _nonce,
        address _token,
        uint amountLD,
        bytes memory _payload
    ) override external {
        require(
            msg.sender == address(stargateRouter) || msg.sender == owner, 
            "only stargate router and owner can call sgReceive!"
        );
        (
            uint256 nativeFee, 
            uint256 _amount, 
            address _to, 
            address _user, 
            bytes memory txData
        ) = abi.decode(_payload, (uint256, uint256, address, address, bytes));
        IERC20(_token).approve(_to, _amount);

        bool success;
        if (amountLD >= _amount) {
            if (nativeFee > 0) {
                (success, ) = _to.call{value: nativeFee}(txData);
            } else {
                (success, ) = _to.call(txData);
            }
        }

        uint256 anyDust;
        if (!success) {
            IERC20(_token).approve(_to, 0);
            anyDust = amountLD;
        } else if (amountLD > _amount) { 
            anyDust = amountLD - _amount;
        }
        
        if (anyDust > 0) IERC20(_token).transfer(_user, anyDust);
        emit ReceivedOnDestination(_token, amountLD, success);
    }
}