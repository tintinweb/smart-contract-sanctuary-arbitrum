/**
 *Submitted for verification at arbiscan.io on 2022-02-06
*/

interface ControllerInterface {
    function enterMarkets(address[] calldata iTokens) external;
}

// Part: DForceETHInterface

interface DForceETHInterface {
    function mint(uint256 _mintAmount) external payable;

    function redeem(address _from, uint256 _redeemiToken) external;

    function borrow(uint256 _borrowAmount) external;

    function repay(uint256 _repayAmount) external payable;
}

// Part: DForceIncentivesInterface

interface DForceIncentivesInterface {
    function claimRewards(address[] memory _holders, address[] memory _suppliediTokens, address[] memory _borrowediTokens) external;
}

// Part: DForceInterface

interface DForceInterface {
    function mint(address _recipient, uint256 _mintAmount) external;

    function redeem(address _from, uint256 _redeemiToken) external;

    function borrow(uint256 _borrowAmount) external;

    function repay(uint256 _repayAmount) external;
}

// Part: TokenInterface

interface TokenInterface {
    function approve(address, uint256) external;
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}

// Part: DForceResolver

abstract contract DForceResolver {

    address constant internal ethAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant internal wethAddr = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    DForceETHInterface constant eth_interface = DForceETHInterface(0xEe338313f022caee84034253174FA562495dcC15);
    ControllerInterface constant controller_interface = ControllerInterface(0x8E7e9eA9023B81457Ae7E6D2a51b003D421E5408);
    DForceIncentivesInterface constant incentives_interface = DForceIncentivesInterface(0xF45e2ae152384D50d4e9b08b8A1f65F0d96786C3);
    TokenInterface constant weth_interface = TokenInterface(wethAddr);

    mapping (address => address) private itoken_address;

    constructor() public {
        // USDC
        itoken_address[0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8] = 0x8dc3312c68125a94916d62B97bb5D925f84d4aE0;
        // USDT
        itoken_address[0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9] = 0xf52f079Af080C9FB5AFCA57DDE0f8B83d49692a9;
        // WBTC
        itoken_address[0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f] = 0xD3204E4189BEcD9cD957046A8e4A643437eE0aCC;
    }

    function get_dforce_interface(address token)  internal view returns (DForceInterface) {
        if (token == ethAddr) {
            return DForceInterface(0xEe338313f022caee84034253174FA562495dcC15);
        }
        return DForceInterface(itoken_address[token]);
    }

    function convert_eth_to_weth(uint amount) internal {
        weth_interface.deposit{value : amount}();
    }
    
    function convert_weth_to_eth(uint amount) internal {
        weth_interface.withdraw(amount);
    }

    function deposit(
        address token,
        uint256 amount
    ) external payable {
        bool isEth = token == ethAddr;
        if (isEth) {
            convert_weth_to_eth(amount);
            eth_interface.mint{value : amount}(amount);
        } else {
            DForceInterface dforce = get_dforce_interface(token);
            dforce.mint(address(this), amount);
        }
    }

    function withdraw(
        address token,
        uint256 amount
    ) external payable {
        DForceInterface dforce = get_dforce_interface(token);
        dforce.redeem(address(this), amount);
        if (token == ethAddr) {
            convert_eth_to_weth(amount);
        }
    }

    function borrow(
        address token,
        uint256 amount
    ) external payable {
        DForceInterface dforce = get_dforce_interface(token);
        dforce.borrow(amount);
        if (token == ethAddr) {
            convert_eth_to_weth(amount);
        }
    }

    function payback(
        address token,
        uint256 amount
    ) external payable {
        bool isEth = token == ethAddr;
        if (isEth) {
            convert_weth_to_eth(amount);
            eth_interface.repay{value : amount}(amount);
        } else {
            DForceInterface dforce = get_dforce_interface(token);
            dforce.repay(amount);
        }

    }

    function enableCollateral(
        address[] calldata tokens
    ) external payable {
        controller_interface.enterMarkets(tokens);
    }
    
    function claim(
        address[] memory _holders, address[] memory _suppliediTokens, address[] memory _borrowediTokens
    ) external payable {
        incentives_interface.claimRewards(_holders, _suppliediTokens, _borrowediTokens);
    }
}

// File: dforce.sol

contract ConnDForce is DForceResolver {
    string constant public name = "ConnDForce";
}