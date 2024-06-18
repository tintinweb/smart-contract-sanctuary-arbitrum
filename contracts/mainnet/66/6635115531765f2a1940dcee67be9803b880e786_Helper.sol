// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
}

interface IStore {
    function getUint(bytes32) external view returns (uint256);
    function getAddress(bytes32) external view returns (address);
}

interface IInvestor {
    function killRepayment(uint256) external returns (uint256);
    function kill(uint256 id) external returns (address, bytes memory);
}

interface IStrategy {
    function totalShares() external view returns (uint256);
    function rate(uint256) external view returns (uint256);
}

interface IAavePool {
    function flashLoanSimple(address receiver, address asset, uint256 amount, bytes calldata params, uint16 referrer) external;
}

interface IStrategyHelper {
    function price(address) external view returns (uint256);
    function swap(address, address, uint256, uint256, address) external returns (uint256);
}

interface ISushi {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function burn(address) external;
}

contract Helper {
    IInvestor public investor;
    IERC20 public asset;
    IAavePool public lender; // 0x794a61358D6845594F94dc1DB02A252b5b4814aD
    IStrategyHelper public sh;
    IStore store;
    address public bank;
    uint256 public slippage = 2500;

    constructor(address _investor, address _asset, address _lender, address _sh, address _store, address _bank) {
        investor = IInvestor(_investor);
        asset = IERC20(_asset);
        lender = IAavePool(_lender);
        sh = IStrategyHelper(_sh);
        store = IStore(_store);
        bank = _bank;
    }

    function kill(uint256 id) external {
        uint256 repay = investor.killRepayment(id);
        lender.flashLoanSimple(address(this), address(asset), repay, abi.encodePacked(id), 0);
    }

    function executeOperation(
      address,
      uint256 amount,
      uint256 premium,
      address initiator,
      bytes calldata params
    ) external returns (bool) {
        require(msg.sender == address(lender), "!lender");
        require(initiator == address(this), "!me");
        uint256 id = uint256(bytes32(params));
        asset.approve(address(investor), amount);
        (address casset, bytes memory data) = investor.kill(id);
        (bytes32 strategy, address[] memory assets) = abi.decode(data, (bytes32, address[]));
        swap(casset);

        if (strategy == "sushi") {
            address a = assets[0];
            IERC20(a).transfer(a, IERC20(a).balanceOf(address(this)));
            ISushi(a).burn(address(this));
            swap(ISushi(a).token0());
            swap(ISushi(a).token1());
        }

        asset.approve(address(lender), amount+premium);
        asset.transfer(msg.sender, asset.balanceOf(address(this)) - amount - premium);
        return true;
    }

    function swap(address _fromAsset) internal {
        IERC20 fromAsset = IERC20(_fromAsset);
        uint256 amount = fromAsset.balanceOf(address(this));
        fromAsset.approve(address(sh), amount);
        sh.swap(_fromAsset, address(asset), amount, slippage, address(this));
    }

    bytes32 constant COLLATERAL_CAP = keccak256(abi.encode("COLLATERAL_CAP"));

    function viewCollaterals(address[] memory tokens) external view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory caps = new uint256[](tokens.length);
        uint256[] memory prices = new uint256[](tokens.length);
        uint256[] memory balances = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address t = tokens[i];
            caps[i] = store.getUint(keccak256(abi.encode(t, COLLATERAL_CAP)));
            prices[i] = sh.price(t);
            balances[i] = IERC20(t).balanceOf(bank);
        }
        return (caps, prices, balances);
    }

    bytes32 constant STRATEGIES_ADDRESS = keccak256(abi.encode("STRATEGIES_ADDRESS"));
    bytes32 constant STRATEGIES_CAP = keccak256(abi.encode("STRATEGIES_CAP"));
    bytes32 constant STRATEGIES_STATUS = keccak256(abi.encode("STRATEGIES_STATUS"));

    function viewStrategies(uint256[] memory strategies) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        address[] memory addresses = new address[](strategies.length);
        uint256[] memory tvls = new uint256[](strategies.length);
        uint256[] memory caps = new uint256[](strategies.length);
        uint256[] memory statuses = new uint256[](strategies.length);
        for (uint256 i = 0; i < strategies.length; i++) {
            uint256 s = strategies[i];
            addresses[i] = store.getAddress(keccak256(abi.encode(s, STRATEGIES_ADDRESS)));
            IStrategy st = IStrategy(addresses[i]);
            tvls[i] = st.rate(st.totalShares());
            caps[i] = store.getUint(keccak256(abi.encode(s, STRATEGIES_CAP)));
            statuses[i] = store.getUint(keccak256(abi.encode(s, STRATEGIES_STATUS)));
        }
        return (addresses, tvls, caps, statuses);
    }
}