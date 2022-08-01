// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

abstract contract Strategy {
    error Paused();
    error NotInvestor();
    error UnknownFile();
    error Unauthorized();

    IERC20 public asset;
    uint256 public cap;
    bool public paused;
    address public investor;
    mapping(address => bool) public exec;

    uint256 public totalShares;

    event FileInt(bytes32 indexed what, uint256 data);
    event FileAddress(bytes32 indexed what, address data);
    event Mint(uint256 amt, uint256 sha);
    event Burn(uint256 sha, uint256 amt);

    constructor(address _asset, address _investor) {
        asset = IERC20(_asset);
        investor = _investor;
        exec[msg.sender] = true;
    }

    modifier auth() {
        if (!exec[msg.sender]) revert Unauthorized();
        _;
    }

    function file(bytes32 what, uint256 data) external auth {
        if (what == "cap") {
            cap = data;
        } else if (what == "paused") {
            paused = data == 1;
        } else {
            revert UnknownFile();
        }
        emit FileInt(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "exec") {
            exec[data] = !exec[data];
        } else if (what == "investor") {
            investor = data;
        } else {
            revert UnknownFile();
        }
        emit FileAddress(what, data);
    }

    function rate(uint256 sha) external view virtual returns (uint256) {
        // calculate vault / lp value in usdc terms (through swap if needed)
        return 0;
    }

    function mint(uint256 amt) external returns (uint256) {
        if (msg.sender != investor) revert NotInvestor();
        if (paused) revert Paused();
        asset.transferFrom(msg.sender, address(this), amt);
        uint256 sha = _mint(amt);
        totalShares += sha;
        emit Mint(amt, sha);
        return sha;
    }

    function burn(uint256 sha) external returns (uint256) {
        if (msg.sender != investor) revert NotInvestor();
        if (paused) revert Paused();
        uint256 amt = _burn(sha);
        totalShares -= sha;
        asset.transfer(msg.sender, amt);
        emit Burn(sha, amt);
        return amt;
    }

    function _mint(uint256 amt) internal virtual returns (uint256) { // pull in usdc from caller
            // convert usdc to needed assets
            // enter vault / lp
    }

    function _burn(uint256 sha) internal virtual returns (uint256) { // exit vault / lp
            // convert assets to usdc
            // return funds
    }
}

contract StrategyPonzi is Strategy {
    string public name = "Ponzi";

    constructor(address _asset, address _investor)
        Strategy(_asset, _investor)
    {}

    function rate(uint256 sha) external view override returns (uint256) {
        return sha * 120 / 100;
    }

    function _mint(uint256 amt) internal override returns (uint256) {
        return amt;
    }

    function _burn(uint256 sha) internal override returns (uint256) {
        return sha * 120 / 100;
    }
}

contract StrategyRug is Strategy {
    string public name = "Rug";

    constructor(address _asset, address _investor)
        Strategy(_asset, _investor)
    {}

    function rate(uint256 sha) external view override returns (uint256) {
        return sha / 2;
    }

    function _mint(uint256 amt) internal override returns (uint256) {
        return amt * 175 / 100;
    }

    function _burn(uint256 sha) internal override returns (uint256) {
        return sha / 2;
    }
}