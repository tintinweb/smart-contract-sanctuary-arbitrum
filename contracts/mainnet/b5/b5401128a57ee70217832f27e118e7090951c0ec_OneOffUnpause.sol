// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPool {
    function getUpdatedIndex() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function borrow(uint256) external;
}

interface IERC20 {
    function transfer(address, uint256) external;
}

interface IInvestor {
    function kill(uint256, bytes calldata) external;
}

contract OneOffUnpause {
    function run() public {
        address multisig = 0xaB7d6293CE715F12879B9fa7CBaBbFCE3BAc0A5a;
        IPool pool = IPool(0x0032F5E1520a66C6E572e96A11fBF54aea26f9bE);
        IERC20 usdc = IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8);
        IInvestor investor = IInvestor(0x8accf43Dd31DfCd4919cc7d65912A475BfA60369);
        uint256 borrow = 401466518618 + 420583992324 + 458819317597 + 382349705467;
        uint256 index = pool.getUpdatedIndex();
        uint256 amount = borrow * index / 1e18;
        require(msg.sender == multisig, "unauthorized");
        pool.file("paused", 0);
        pool.borrow(1_000_000e6);
        usdc.transfer(address(pool), 1_000_000e6);
        pool.borrow(amount - 1_000_000e6);
        usdc.transfer(address(pool), amount - 1_000_000e6);
        investor.kill(3195, "");
        investor.kill(3196, "");
        pool.file("paused", 1);
        pool.file("exec", address(this));
    }
}