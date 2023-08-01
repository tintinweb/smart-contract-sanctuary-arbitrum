/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

pragma solidity ^0.6.7;

import { UnsdJoinAbstract } from "./lib/UnsdJoinAbstract.sol";
import { UnsdAbstract } from "./lib/UnsdAbstract.sol";
import { VatAbstract } from "./lib/VatAbstract.sol";

interface AuthGemJoinAbstract {
    function dec() external view returns (uint256);
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function join(address, uint256, address) external;
    function exit(address, uint256) external;
}

// Peg Stability Module
// Allows anyone to go between Unsd and the Gem by pooling the liquidity
// An optional fee is charged for incoming and outgoing transfers

contract DssPsm2 {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }
    modifier auth { require(wards[msg.sender] == 1); _; }

    VatAbstract immutable public vat;
    AuthGemJoinAbstract immutable public gemJoin;
    UnsdAbstract immutable public unsd;
    UnsdJoinAbstract immutable public unsdJoin;
    bytes32 immutable public ilk;
    bytes32 immutable public vIlk;
    address public feeCollector;

    uint256 immutable internal to18ConversionFactor;

    uint256 public tin;         // toll in [wad]
    uint256 public tout;        // toll out [wad]

    uint256 public constant ONE_DAY = uint(86400);
    uint256 public hop = ONE_DAY;

    uint256 public today;
    uint256 public todayAmount;
    uint256 public limitBaseAmount;

    uint256 public updateBaseRate;
    uint256 public limitRate;

    // --- Events ---
    event Rely(address user);
    event Deny(address user);
    event File(bytes32 indexed what, uint256 data);
    event SellGem(address indexed owner, uint256 value, uint256 fee);
    event BuyGem(address indexed owner, uint256 value, uint256 fee);

    // --- Init ---
    constructor(address gemJoin_, address unsdJoin_, address feeCollector_, bytes32 vIlk_) public {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        AuthGemJoinAbstract gemJoin__ = gemJoin = AuthGemJoinAbstract(gemJoin_);
        UnsdJoinAbstract unsdJoin__ = unsdJoin = UnsdJoinAbstract(unsdJoin_);
        VatAbstract vat__ = vat = VatAbstract(address(gemJoin__.vat()));
        UnsdAbstract unsd__ = unsd = UnsdAbstract(address(unsdJoin__.unsd()));
        ilk = gemJoin__.ilk();
        vIlk = vIlk_;
        feeCollector = feeCollector_;
        to18ConversionFactor = 10 ** (18 - gemJoin__.dec());
        unsd__.approve(unsdJoin_, uint256(-1));
        vat__.hope(unsdJoin_);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what == "tin") tin = data;
        else if (what == "tout") tout = data;
        else if (what == "updateBaseRate")  updateBaseRate = data;
        else if (what == "limitRate")  limitRate = data;
        else revert("DssPsm/file-unrecognized-param");

        emit File(what, data);
    }
    function file(bytes32 what, address data) external auth {
        if (what == "feeCollector") feeCollector = data;
        else revert("DssPsm/file-unrecognized-param");
    }
    function hope(address usr) external auth {
        vat.hope(usr);
    }
    function nope(address usr) external auth {
        vat.nope(usr);
    }

    function era() internal view returns (uint) {
        return block.timestamp;
    }

    function prev(uint ts) internal view returns (uint) {
        require(hop != 0, "UsdtSwap/hop-is-zero");
        return uint(ts - (ts % hop));
    }

    function newDay() public view returns (bool ok) {
        return era() >= add(today, hop);
    }

    // --- Primary Functions ---
    function joinSellGemAndDraw(address usr, uint256 gemAmt) external {
        gemJoin.join(address(this), gemAmt, msg.sender);
        sellGemAndDraw(usr, gemAmt);
    }

    function joinSellGem(address usr, uint256 gemAmt) external {
        gemJoin.join(address(this), gemAmt, msg.sender);
        sellGem(usr, gemAmt);
    }

    function sellGemAndDraw(address usr, uint256 gemAmt) public returns (uint256 unsdAmt) {
        uint256 gemAmt18 = mul(gemAmt, to18ConversionFactor);
        uint256 fee = mul(gemAmt18, tin) / WAD;
        unsdAmt = sub(gemAmt18, fee);
        vat.frob(ilk, address(this), address(this), address(this), int256(gemAmt18), int256(gemAmt18));
        vat.move(address(this), feeCollector, mul(fee, RAY));
        uint256 unsdAmtRay = mul(unsdAmt, RAY);
        vat.slip(vIlk, usr, int(unsdAmtRay));
        unsdJoin.exit(usr, unsdAmt);

        emit SellGem(usr, gemAmt, fee);
    }

    function sellGem(address usr, uint256 gemAmt) public returns (uint256 unsdAmt) {
        uint256 gemAmt18 = mul(gemAmt, to18ConversionFactor);
        uint256 fee = mul(gemAmt18, tin) / WAD;
        unsdAmt = sub(gemAmt18, fee);
        vat.frob(ilk, address(this), address(this), address(this), int256(gemAmt18), int256(gemAmt18));
        vat.move(address(this), feeCollector, mul(fee, RAY));
        uint256 unsdAmtRay = mul(unsdAmt, RAY);
        vat.move(address(this), usr, unsdAmtRay);
        vat.slip(vIlk, usr, int(unsdAmtRay));

        emit SellGem(usr, gemAmt, fee);
    }

    function joinBuyGemAndDraw(address usr, uint256 gemAmt, uint256 vAmt) external {
        uint256 gemAmt18 = mul(gemAmt, to18ConversionFactor);
        (uint256 curBalance,) = vat.urns(ilk, address(this));
        if (newDay()) {
            today = prev(era());
            todayAmount = 0;
            limitBaseAmount = curBalance;
        } else {
            if (mul(limitBaseAmount, updateBaseRate) / WAD <= curBalance) {
                limitBaseAmount = curBalance;
            }
        }

        todayAmount = add(todayAmount, gemAmt18);
        if (limitRate > 0) {
            uint256 limitAmount = mul(limitBaseAmount, limitRate) / WAD;
            require(todayAmount <= limitAmount, "UsdtSwap/Over-the-limit");
        }

        uint256 calcFeeAmt18 = gemAmt18;
        if (vAmt > 0) {
            if (vAmt < gemAmt18) {
                calcFeeAmt18 = sub(gemAmt18, vAmt);
            } else {
                calcFeeAmt18 = 0;
                vAmt = calcFeeAmt18;
            }
        }
        
        uint256 fee = mul(calcFeeAmt18, tout) / WAD;
        uint256 unsdAmt = add(gemAmt18, fee);
        require(unsd.transferFrom(msg.sender, address(this), unsdAmt), "DssPsm/failed-transfer");
        unsdJoin.join(address(this), unsdAmt);
        vat.frob(ilk, address(this), address(this), address(this), -int256(gemAmt18), -int256(gemAmt18));
        gemJoin.exit(usr, gemAmt);
        vat.move(address(this), feeCollector, mul(fee, RAY));
        uint256 vAmtRay = mul(vAmt, RAY);
        vat.slip(vIlk, usr, -int(vAmtRay));

        emit BuyGem(usr, gemAmt, fee);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface UnsdJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function unsd() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface UnsdAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.12;

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function unsd(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}