/**
 *Submitted for verification at Arbiscan on 2023-02-08
*/

// SPDX-License-Identifier: MIT-0
pragma solidity =0.8.0;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IZyberRouter {
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint[] memory amounts);
}

interface IZyberMasterchef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function harvestMany(uint256[] calldata _pids) external;
}

contract Zybervault {
    address private owner; // PRIVATED OWNER, DOESNT MATTER
    IERC20[] public Tokens = [
        IERC20(0x3B475F6f2f41853706afc9Fa6a6b8C5dF1a2724c), // ZYB
        IERC20(0xF942e32861Ee145963503DdB69fC3B0237F0888C), // USDT/USDC zLP PID 4
        IERC20(0x252cd7185dB7C3689a571096D5B57D45681aA080), // DAI/USDC zLP PID 5
        IERC20(0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8)  // USDC

    ];
    IZyberRouter private Router = IZyberRouter(0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad); // PRIVATED ROUTER BUT DOESNT MATTER
    IZyberMasterchef private Masterchef = IZyberMasterchef(0x9BA666165867E916Ee7Ed3a3aE6C19415C2fBDDD);
    uint256 constant TWENTY_MINUTES = 1200;
    uint256 private startTime;
    uint256 public compounds = 1;
    uint256 public harvestedTotal = 0; // THIS WOULD BE Tokens[0] the cumulative amount of farm tokens harvested over contract activity.


    constructor() {
        startTime = block.timestamp;
        owner = msg.sender;
        for (uint256 i = 1; i < Tokens.length - 1; i++) {
            Tokens[i].approve(address(Masterchef), 2 ** 256 - 1);
        }
        Tokens[0].approve(address(Router), 2 ** 256 -  1);
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    modifier compoundTimeGuard {
        require(canBuy(), "It hasn't been 20 minutes yet");
        compounds++;
        _;
    }

    function nextCompoundPoint() public view returns (uint256) {
        return (startTime + compounds * TWENTY_MINUTES);
    }
    
    function canBuy() public view returns (bool) {
        return (block.timestamp >= nextCompoundPoint());
    }

    function deposit() public onlyOwner {
        Masterchef.deposit(4, Tokens[1].balanceOf(address(this))); // USDT/USDC
        Masterchef.deposit(5, Tokens[2].balanceOf(address(this))); // DAI/USDC
    }

    function harvest() public {
        uint256[] memory pids = new uint256[](2);
        pids[0] = 4;
        pids[1] = 5;

        Masterchef.harvestMany(pids);
    }

    function emergencyWithdraw() external onlyOwner {
        Masterchef.emergencyWithdraw(4);
        Masterchef.emergencyWithdraw(5);
        Tokens[1].transfer(owner, Tokens[1].balanceOf(address(this)));
        Tokens[2].transfer(owner, Tokens[2].balanceOf(address(this)));
    }

    function emergencyWithdrawWithHarvest() external onlyOwner {
        harvest();
        Masterchef.emergencyWithdraw(4);
        Masterchef.emergencyWithdraw(5);
        Tokens[1].transfer(owner, Tokens[1].balanceOf(address(this)));
        Tokens[2].transfer(owner, Tokens[2].balanceOf(address(this)));
    }

    function withdraw(address _tokenContract) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(owner, tokenContract.balanceOf(address(this)));
    }

    function buy() external compoundTimeGuard {
        harvest();
        
        harvestedTotal += Tokens[0].balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = address(Tokens[0]); // ZYB
        path[1] = address(Tokens[3]); // USDC

        Router.swapExactTokensForTokens(
            Tokens[0].balanceOf(address(this)),
            1,
            path,
            address(this),
            (block.timestamp + TWENTY_MINUTES)
        );
    }


    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "External call failed");
        return result;
    }
}