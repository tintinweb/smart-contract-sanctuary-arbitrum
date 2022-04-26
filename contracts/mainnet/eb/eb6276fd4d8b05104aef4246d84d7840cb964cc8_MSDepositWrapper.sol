/**
 *Submitted for verification at Arbiscan on 2022-04-26
*/

pragma solidity ^0.5.16;


interface IERC20 {
    function balanceOf(address a) external returns(uint);
    function transfer(address to, uint amount) external returns(bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
    function approve(address _spender, uint256 _value) external returns(bool);
}

interface ICToken {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
}

interface IBAMM {
    function deposit(uint amount) external;
    function withdraw(uint share) external;
    function collateralCount() external view returns(uint);
    function collaterals(uint i) external view returns(address);
    function cBorrow() external view returns(address);
}

interface IMasterChef {
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function lpToken(uint pid) external returns(address);
}

contract MSDepositWrapper {
    address public fETH;
    address public bfETH;
    address public masterChef;
    uint    public pid;

    mapping(address => address) public proxies;

    constructor(address _masterChef, uint _pid) public {
        pid = _pid;
        masterChef = _masterChef;
        bfETH = IMasterChef(_masterChef).lpToken(_pid);
        fETH = IBAMM(bfETH).cBorrow();
    }

    function deposit() payable public {
        // 1. deposit to fuse
        ICToken(fETH).mint.value(msg.value)();

        // 2. give allowance to the bamm
        uint fETHAmount = IERC20(fETH).balanceOf(address(this));
        require(IERC20(fETH).approve(bfETH, fETHAmount), "deposit: fETH approve failed");

        // 3. deposit to the bamm
        IBAMM(bfETH).deposit(fETHAmount);

        // 4. give allowance to masterchef
        uint bfETHAmount = IERC20(bfETH).balanceOf(address(this));
        require(IERC20(bfETH).approve(masterChef, bfETHAmount), "deposit: bfETHAmount approve failed");

        // 5. get proxy address (create if needed)
        address proxy = proxies[msg.sender];
        if(proxy == address(0)) {
            proxy = address(new BAMMDepositProxy());
            proxies[msg.sender] = proxy;
        }

        // 6. deposit to masterchef and send to proxy
        IMasterChef(masterChef).deposit(pid, bfETHAmount, proxy);
    }

    function withdraw(uint shareAmount) public {
        // 1. get proxy address
        address proxy = proxies[msg.sender];
        require(proxy != address(0), "withddraw: user does not exist");

        // 2. harvest
        BAMMDepositProxy(proxy).harvest(masterChef, pid, msg.sender);

        // the call was only to harvest
        if(shareAmount == 0) return;

        // 3. call proxy: withdraw from masterchef and send bamm to contract
        BAMMDepositProxy(proxy).withdraw(masterChef, pid, shareAmount);

        // 4. withdraw from bamm
        uint bfETHBalance = IERC20(bfETH).balanceOf(address(this));
        IBAMM(bfETH).withdraw(bfETHBalance);

        // 5. send all collaterals to user
        uint collateralCount = IBAMM(bfETH).collateralCount();
        for(uint i = 0 ; i < collateralCount ; i++) {
            address collateral = IBAMM(bfETH).collaterals(i);
            uint collatBal = IERC20(collateral).balanceOf(address(this));
            if(collatBal > 0) {
                require(IERC20(collateral).transfer(msg.sender, collatBal), "withdraw: collateral transfer failed");
            }
        }

        // 6. withdraw ETH from fuse if possible and send to user
        uint fETHBalance = IERC20(fETH).balanceOf(address(this));
        if(ICToken(fETH).redeem(fETHBalance) == 0) {
            // send eth
            msg.sender.transfer(address(this).balance);
        }
        else {
            // send fETH
            require(IERC20(fETH).transfer(msg.sender, fETHBalance), "withdraw: fETH transfer failed");
        }        
    }

    function() external payable {

    }    
}

contract BAMMDepositProxy {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    function harvest(address masterChef, uint pid, address to) external {
        require(msg.sender == owner, "!owner");
        IMasterChef(masterChef).harvest(pid, to);
    }

    function withdraw(address masterChef, uint pid, uint shareAmount) external {
        require(msg.sender == owner, "!owner");
        IMasterChef(masterChef).withdraw(pid, shareAmount, msg.sender);
    }
}