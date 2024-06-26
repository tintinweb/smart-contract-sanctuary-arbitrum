/// SPDX-License-Identifier: AGPL-3.0-only

// Copyright (C) 2021 kevin and his friends
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.19;

contract Gem {
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8   public constant decimals = 18;

    mapping (address => uint)                      public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    mapping (address => uint)                      public nonces;
    mapping (address => bool)                      public wards;

    bytes32 constant DOMAIN_SUBHASH = keccak256(
        'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
    );
    bytes32 constant PERMIT_TYPEHASH = keccak256(
        'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
    );
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return keccak256(abi.encode( DOMAIN_SUBHASH,
            keccak256("GemPermit"), keccak256("0"),
            block.chainid, address(this))
        );
    }

    event Approval(address indexed src, address indexed usr, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Ward(address indexed setter, address indexed user, bool authed);

    error ErrPermitDeadline();
    error ErrPermitSignature();
    error ErrOverflow();
    error ErrUnderflow();
    error ErrZeroDst();
    error ErrWard();

    constructor(bytes32 name_, bytes32 symbol_)
      payable
    {
        name = name_;
        symbol = symbol_;

        wards[msg.sender] = true;
        emit Ward(msg.sender, msg.sender, true);
    }

    function ward(address usr, bool authed)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        wards[usr] = authed;
        emit Ward(msg.sender, usr, authed);
    }

    function mint(address usr, uint wad)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        unchecked {
            // only need to check totalSupply for overflow
            uint256 prev = totalSupply;
            if (prev + wad < prev) revert ErrOverflow();

            balanceOf[usr] += wad;
            totalSupply     = prev + wad;
            emit Transfer(address(0), usr, wad);

            if (usr == address(0)) revert ErrZeroDst();
        }
    }

    function burn(address usr, uint wad)
      payable external
    {
        if (!wards[msg.sender]) revert ErrWard();
        unchecked {
            // only need to check balanceOf[usr] for underflow
            uint256 prev = balanceOf[usr];
            balanceOf[usr] = prev - wad;
            totalSupply    -= wad;
            emit Transfer(usr, address(0), wad);

            if (prev < wad) revert ErrUnderflow();
        }
    }

    function transfer(address dst, uint wad)
      payable external returns (bool ok)
    {
        unchecked {
            ok = true;
            uint256 prev = balanceOf[msg.sender];
            balanceOf[msg.sender] = prev - wad;
            balanceOf[dst]       += wad;
            emit Transfer(msg.sender, dst, wad);

            if (prev < wad) revert ErrUnderflow();
            if (dst == address(0)) revert ErrZeroDst();
        }
    }

    function transferFrom(address src, address dst, uint wad)
      payable external returns (bool ok)
    {
        unchecked {
            ok              = true;
            uint256 prevB   = balanceOf[src];
            balanceOf[src]  = prevB - wad;
            balanceOf[dst] += wad;
            uint256 prevA   = allowance[src][msg.sender];

            if (prevA != type(uint256).max) {
                allowance[src][msg.sender] = prevA - wad;
                emit Approval(src, msg.sender, prevA - wad);

                if (prevA < wad) revert ErrUnderflow();
            }
            emit Transfer(src, dst, wad);

            if (prevB < wad) revert ErrUnderflow();
            if (dst == address(0)) revert ErrZeroDst();
        }
    }

    function approve(address usr, uint wad)
      payable external returns (bool ok)
    {
        ok = true;
        allowance[msg.sender][usr] = wad;
        emit Approval(msg.sender, usr, wad);
    }

    // EIP-2612
    function permit(address owner, address spender, uint256 value, uint256 deadline,
                    uint8 v, bytes32 r, bytes32 s)
      payable external
    {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);

        address signer;
        unchecked {
            signer = ecrecover(
                keccak256(abi.encodePacked( "\x19\x01",
                    keccak256(abi.encode( DOMAIN_SUBHASH,
                        keccak256("GemPermit"), keccak256("0"),
                        block.chainid, address(this))),
                    keccak256(abi.encode( PERMIT_TYPEHASH, owner, spender,
                        value, nonces[owner]++, deadline )))),
                v, r, s
            );
        }

        if (signer == address(0)) revert ErrPermitSignature();
        if (owner != signer) revert ErrPermitSignature();
        if (block.timestamp > deadline) revert ErrPermitDeadline();
    }
}

contract GemFab {
    mapping(address=>bool) public built;

    event Build(address indexed caller, address indexed gem);

    function build(bytes32 name, bytes32 symbol)
      payable external returns (Gem gem)
    {
        gem = new Gem(name, symbol);
        built[address(gem)] = true;
        emit Build(msg.sender, address(gem));
        gem.ward(msg.sender, true);
        gem.ward(address(this), false);
        return gem;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.25;

import { Math } from "./mixin/math.sol";
import { Flog } from "./mixin/flog.sol";
import { Palm } from "./mixin/palm.sol";
import { Gem }  from "../lib/gemfab/src/gem.sol";

contract Bank is Math, Flog, Palm {

    struct Urn {
        uint256 ink;   // [wad] Locked Collateral
        uint256 art;   // [wad] Normalised Debt
    }

    struct BankParams {
        address rico;
        address risk;

        uint256 par;
        uint256 fee;
        uint256 dust;
        uint256 chop;
        uint256 liqr;
        uint256 pep;
        uint256 pop;
        int256  pup;

        uint256 gif;
        uint256 pex;
        uint256 wel;
        uint256 dam;
        uint256 mop;
        uint256 lax;

        uint256 how;
        uint256 cap;
        uint256 way;
   }

    Gem immutable public rico; // stability primitive
    Gem immutable public risk; // buy-and-burn token

    // vat
    mapping (address => Urn) public urns; // CDPs
    uint256 public joy;   // [wad] System revenue
    uint256 public sin;   // [rad] Unbacked debt
    uint256 public rest;  // [rad] System revenue remainder
    uint256 public par;   // [ray] System Price (rico/ref)
    uint256 public tart;  // [wad] Total Normalised Debt
    uint256 public rack;  // [ray] Accumulated Rate
    uint256 public rho;   // [sec] Time of last drip
    uint256 immutable public fee;   // [ray] per-second compounding rate
    uint256 immutable public dust;  // [ray] Urn Ink Floor, as a fraction of totalSupply
    uint256 immutable public chop;  // [ray] Liquidation Penalty
    uint256 immutable public liqr;  // [ray] Liquidation Ratio
    uint256 immutable public pep;   // [num] discount exponent
    uint256 immutable public pop;   // [ray] discount offset
    int256  immutable public pup;   // [ray] signed discount shift
    uint256 constant  public FEE_MAX = 1000000072964521287979890107; // ~10x/yr

    // vow
    uint256 public bel;  // [sec] last flap timestamp
    uint256 public gif;  // [wad] RISK base mint rate
    uint256 public chi;  // [sec] last mine timestamp
    uint256 public wal;  // [wad] risk deposited + risk totalSupply
    uint256 immutable public pex; // [ray] start price
    uint256 immutable public wel; // [ray] fraction of joy/flap
    uint256 immutable public dam; // [ray] per-second flap discount
    uint256 immutable public mop; // [ray] per-second gif decay
    uint256 immutable public lax; // [ray] mint-rate shift up (fraction of totalSupply)
    uint256 constant  public LAX_MAX = 145929047899781146998; // ~100x/yr
    uint256 constant         SAFE = RAY;

    // vox
    uint256 public way; // [ray] Price Rate (system price growth rate)
    uint256 immutable public how; // [ray] Sensitivity Parameter (way growth rate)
    uint256 immutable public cap; // [ray] Price Rate Clamp (1/cap <= way <= cap)
    uint256 constant  public CAP_MAX = 1000000072964521287979890107; // ~10x/yr

    error ErrNotSafe();
    error ErrSafeBail();
    error ErrUrnDust();
    error ErrWrongUrn();

    constructor(BankParams memory p) {
        (rico, risk) = (Gem(p.rico), Gem(p.risk));

        (wel, dam, pex, mop, lax) = (p.wel, p.dam, p.pex, p.mop, p.lax);
        must(wel, 0, RAY);
        must(dam, 0, RAY);
        must(pex, 0, BLN);
        must(mop, 0, RAY);
        must(lax, 0, LAX_MAX);

        (how, cap) = (p.how, p.cap);
        must(how, RAY, type(uint).max);
        must(cap, RAY, CAP_MAX);

        (par, dust) = (p.par, p.dust);
        must(dust, 0, RAY);

        (pep, pop, pup) = (p.pep, p.pop, p.pup);

        (liqr, chop, fee) = (p.liqr, p.chop, p.fee);
        must(liqr, RAY, type(uint).max);
        must(chop, RAY, 10 * RAY);
        must(fee, RAY, FEE_MAX);

        (rack, rho, bel) = (RAY, block.timestamp, block.timestamp);

        (gif, chi, wal) = (p.gif, block.timestamp, risk.totalSupply());
        must(wal, 0, RAD);

        way = p.way;
        must(way, rinv(cap), cap);

        emit NewPalm0("par", bytes32(par));
        emit NewPalm0("rho", bytes32(rho));
        emit NewPalm0("bel", bytes32(bel));
        emit NewPalm0("gif", bytes32(gif));
        emit NewPalm0("chi", bytes32(chi));
        emit NewPalm0("wal", bytes32(wal));
        emit NewPalm0("way", bytes32(way));
    }

    function safe(address u) public view returns (uint deal, uint tot) {
        Urn storage urn = urns[u];
        uint ink = urn.ink;

        // par acts as a multiplier for collateral requirements
        // par increase has same effect on cut as fee accumulation through rack
        // par decrease acts like a negative fee
        uint tab = urn.art * rmul(par, rack);
        uint cut = rdiv(ink, liqr) * RAY;

        // min() used to prevent truncation hiding unsafe
        deal = tab > cut ? min(cut / (tab / RAY), SAFE - 1) : SAFE;
        tot  = ink * RAY;
    }

    // modify CDP
    function frob(int dink, int dart) external payable _flog_ {
        Urn storage urn = urns[msg.sender];

        // update rack
        uint _rack = drip();

        // modify normalized debt
        uint256 art = add(urn.art, dart);
        urn.art     = art;
        emit NewPalm1("art", bytes32(bytes20(msg.sender)), bytes32(art));

        tart = add(tart, dart);
        emit NewPalm0("tart", bytes32(tart));

        uint _rest;
        // rico mint/burn amount increases with rack
        int dtab = mul(_rack, dart);
        if (dtab > 0) {
            // borrow
            // dtab is a rad
            uint wad = uint(dtab) / RAY;

            // remainder is a ray
            _rest = rest += uint(dtab) % RAY;
            emit NewPalm0("rest", bytes32(_rest));

            rico.mint(msg.sender, wad);
        } else if (dtab < 0) {
            // paydown
            // dtab is a rad, so burn one extra to round in system's favor
            uint wad = (uint(-dtab) / RAY) + 1;

            // accrue excess from rounding to rest
            _rest = rest += add(wad * RAY, dtab);
            emit NewPalm0("rest", bytes32(_rest));

            rico.burn(msg.sender, wad);
        }

        // update balance before transferring tokens
        uint ink = add(urn.ink, dink);
        urn.ink  = ink;
        emit NewPalm1("ink", bytes32(bytes20(msg.sender)), bytes32(ink));

        if (dink > 0) {
            // pull tokens from sender
            risk.burn(msg.sender, uint(dink));
        } else if (dink < 0) {
            // return tokens to urn holder
            risk.mint(msg.sender, uint(-dink));
        }

        // urn is safer, or it is safe
        if (dink < 0 || dart > 0) {
            (uint deal,) = safe(msg.sender);
            if (deal < SAFE) revert ErrNotSafe();
        }

        // urn has no debt, or a non-dusty ink amount
        if (art != 0 && urn.ink < rmul(wal, dust)) revert ErrUrnDust();
    }

    // liquidate CDP
    function bail(address u) external payable _flog_ returns (uint sell) {
        uint _rack = drip();
        (uint deal, uint tot) = safe(u);
        if (deal == SAFE) revert ErrSafeBail();

        Urn storage urn = urns[u];
        uint art = urn.art;
        urn.art  = 0;
        emit NewPalm1("art", bytes32(bytes20(u)), 0);

        uint dtab  = art * _rack;
        tart      -= art;
        emit NewPalm0("tart", bytes32(tart));

        // record the bad debt for vow to heal
        sin += dtab;
        emit NewPalm0("sin", bytes32(sin));

        // ink auction
        uint mash = rmash(deal, pep, pop, pup);
        uint earn = rmul(tot / RAY, mash);

        // bill is the debt to attempt to cover when auctioning ink
        uint bill = rmul(chop, dtab / RAY);
        // clamp `sell` so bank only gets enough to underwrite urn.
        if (earn > bill) {
            sell = (urn.ink * bill) / earn;
            earn = bill;
        } else {
            sell = urn.ink;
        }

        // Rico paid for the liquidation is revenue
        uint _joy = joy += earn;
        emit NewPalm0("joy", bytes32(_joy));

        // update collateral balance
        unchecked {
            uint _ink = urn.ink -= sell;
            emit NewPalm1("ink", bytes32(bytes20(u)), bytes32(_ink));
        }

        // trade collateral with keeper for rico
        rico.burn(msg.sender, earn);
        risk.mint(msg.sender, sell);
    }

    function drip() internal returns (uint _rack) {
        // multiply rack by fee every second
        uint prev = rack;

        if (block.timestamp == rho) return rack;

        // multiply rack by fee every second
        _rack = grow(prev, fee, block.timestamp - rho);

        // difference between current and previous rack determines interest
        uint256 delt = _rack - prev;
        uint256 rad  = tart * delt;
        uint256 all  = rest + rad;

        rho  = block.timestamp;
        emit NewPalm0("rho", bytes32(block.timestamp));

        rack = _rack;
        emit NewPalm0("rack", bytes32(_rack));

        // tart * rack is a rad, interest is a wad, rest is the change
        rest = all % RAY;
        emit NewPalm0("rest", bytes32(rest));

        joy  = joy + (all / RAY);
        emit NewPalm0("joy", bytes32(joy));
    }

    // balance system revenue with bad debt, auction off surplus
    function keep() external payable _flog_ {
        drip();

        // use equal scales for sin and joy
        uint _joy = joy;
        uint _sin = sin / RAY;

        // in case of deficit max price should always lead to decrease in way
        uint price = type(uint256).max;
        uint dt    = block.timestamp - bel;

        if (_joy > _sin) {

            // pay down sin, then auction off surplus RICO for RISK
            if (_sin > 1) {
                // gas - don't zero sin
                _joy = heal(_sin - 1);
            }

            // price decreases with time
            price = rmul(par * pex, rpow(dam, dt));
            if (price < par / pex) price = 0;

            // buy-and-burn risk with remaining (`flap`) rico
            uint flap = rmul(_joy - 1, wel);
            uint earn = rmul(flap, price);
            _joy     -= flap;
            joy       = _joy;
            emit NewPalm0("joy", bytes32(_joy));

            // swap rico for RISK, pay protocol fee
            rico.mint(msg.sender, flap);
            risk.burn(msg.sender, earn);

            // burning RISK without putting it in a CDP - update wal
            wal -= earn;
            emit NewPalm0("wal", bytes32(wal));
        }

        // price is max uint in deficit, so poke always ticks down in deficit
        bel = block.timestamp;
        emit NewPalm0("bel", bytes32(block.timestamp));
        poke(price, dt);
    }

    // balance revenue and bad debt
    // can flap left over profit, or tick down to cover left over deficit
    function heal(uint wad) internal returns (uint _joy) {
        sin  = sin - (wad * RAY);
        emit NewPalm0("sin", bytes32(sin));

        joy  = (_joy = joy - wad);
        emit NewPalm0("joy", bytes32(_joy));
    }

    // give msg.sender some RISK
    function mine() external _flog_ {
        uint elapsed = block.timestamp - chi;

        // base mint rate uses right hand rule - decay it first
        gif = grow(gif, mop, elapsed);
        emit NewPalm0("gif", bytes32(gif));

        chi = block.timestamp;
        emit NewPalm0("chi", bytes32(block.timestamp));

        // inflation rate is base rate plus shift-up
        uint flate = (gif + rmul(wal, lax)) * elapsed;
        risk.mint(msg.sender, flate);

        // minted RISK wasn't sitting in a CDP before - update wal
        wal += flate;
        emit NewPalm0("wal", bytes32(wal));
    }

    // price rate controller
    // ensures that market price (mar) roughly tracks par
    // note that price rate (way) can be less than 1
    // this is how the system achieves negative effective borrowing rates
    // if quantity rate is 1%/yr (fee > RAY) but price rate is -2%/yr (way < RAY)
    // borrowers are rewarded about 1%/yr for borrowing and shorting rico

    // poke par and way
    function poke(uint mar, uint dt) internal {
        if (dt == 0) return;

        // use previous `way` to grow `par` to keep par updates predictable
        uint _par = par;
        uint _way = way;
        _par      = grow(_par, _way, dt);
        par       = _par;
        emit NewPalm0("par", bytes32(_par));

        // lower the price rate (way) when mar > par or system is in deficit
        // raise the price rate when mar < par
        // this is how mar tracks par and rcs pays down deficits
        if (mar < _par) {
            _way = min(cap, grow(_way, how, dt));
        } else if (mar > _par) {
            _way = max(rinv(cap), grow(_way, rinv(how), dt));
        }

        way = _way;
        emit NewPalm0("way", bytes32(_way));
    }

}

/// SPDX-License-Identifier: AGPL-3.0

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.25;

abstract contract Flog {
    event NewFlog(
        address indexed caller
      , bytes4 indexed sig
      , bytes data
    );

    // similar to ds-note - emits function call data
    // use at beginning of external state modifying functions
    modifier _flog_ {
        emit NewFlog(msg.sender, msg.sig, msg.data);
        _;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later

// Copyright (C) 2021-2024 halys
// Copyright (C) 2021 .
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
// Copyright (C) 2017, 2018, 2019 dbrock, rain, mrchico
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.8.25;

contract Math {
    // when a (uint, int) arithmetic operation over/underflows
    // Err{returnty}{Over|Under}
    // need these because solidity has no native (uint, int) 
    // overflow checks
    error ErrUintOver();
    error ErrUintUnder();
    error ErrIntUnder();
    error ErrIntOver();
    error ErrBound();

    uint256 internal constant BLN = 10 **  9;
    uint256 internal constant WAD = 10 ** 18;
    uint256 internal constant RAY = 10 ** 27;
    uint256 internal constant RAD = 10 ** 45;

    uint256 internal constant BANKYEAR = ((365 * 24) + 6) * 3600;

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x >= y ? x : y;
    }

    function add(uint x, int y) internal pure returns (uint z) {
        unchecked {
            z = x + uint(y);
            if (y > 0 && z <= x) revert ErrUintOver();
            if (y < 0 && z >= x) revert ErrUintUnder();
        }
    }

    function mul(uint x, int y) internal pure returns (int z) {
        unchecked {
            z = int(x) * y;
            if (int(x) < 0) revert ErrIntOver();
            if (y != 0 && z / y != int(x)) {
                if (y > 0) revert ErrIntOver();
                else revert ErrIntUnder();
            }
        }
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y / RAY;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * RAY / y;
    }
    function rinv(uint256 x) internal pure returns (uint256) {
        return rdiv(RAY, x);
    }

    function grow(uint256 amt, uint256 ray, uint256 dt) internal pure returns (uint256 z) {
        z = amt * rpow(ray, dt) / RAY;
    }

    // from dss src/abaci.sol:136
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        assembly {
            switch n case 0 { z := RAY }
            default {
                switch x case 0 { z := 0 }
                default {
                    switch mod(n, 2) case 0 { z := RAY } default { z := x }
                    let half := div(RAY, 2)  // for rounding.
                    for { n := div(n, 2) } n { n := div(n,2) } {
                        let xx := mul(x, x)
                        if shr(128, x) { revert(0,0) }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) { revert(0,0) }
                        x := div(xxRound, RAY)
                        if mod(n,2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) { revert(0,0) }
                            z := div(zxRound, RAY)
                        }
                    }
                }
            }
        }
    }

    function rmash(uint deal, uint pep, uint pop, int pup)
      internal pure returns (uint res) {
        res = rmul(pop, rpow(deal, pep));
        if (pup < 0 && uint(-pup) > res) return 0;
        res = add(res, pup);
    }

    function must(uint actual, uint lo, uint hi) internal pure {
        if (actual < lo || actual > hi) revert ErrBound();
    }

}

/// SPDX-License-Identifier: AGPL-3.0

// Copyright (C) 2021-2024 halys

pragma solidity ^0.8.25;

abstract contract Palm {
    event NewPalm0(
        bytes32 indexed key
      , bytes32 val
    );
    event NewPalm1(
        bytes32 indexed key
      , bytes32 indexed idx0
      , bytes32 val
    );
}