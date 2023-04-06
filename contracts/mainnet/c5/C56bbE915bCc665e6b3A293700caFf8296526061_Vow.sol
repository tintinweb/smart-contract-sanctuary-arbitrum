// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

interface VatLike {
    function move(address, address, uint256) external;

    function zar(address) external view returns (uint256);

    function sin(address) external view returns (uint256);

    function heal(uint256) external;

    function hope(address) external;

    function nope(address) external;
}

contract Vow {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        require(live == 1, "Vow/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public vat; // CDP Engine

    mapping(uint256 => uint256) public sin; // debt queue
    uint256 public Sin; // queued debt          [rad]

    uint256 public wait; // Flop delay             [seconds]
    uint256 public sump; // Flop min size    [rad]

    uint256 public hump; // Surplus buffer         [rad]
    uint256 public bump; // flap fixed lot size    [rad]

    address public collector;

    uint256 public live; // Active Flag

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Heal(uint256 indexed rad);

    event Fess(uint256 tab);
    event Flog(uint256 era);
    event Flop(address usr, uint256 rad);
    event Flap(address usr, uint256 rad);

    event Cage();

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        live = 1;
    }

    // --- Math ---
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    // --- Administration ---

    function file(bytes32 what, uint256 data) external auth {
        if (what == "wait") wait = data;
        else if (what == "sump") sump = data;
        else if (what == "hump") hump = data;
        else if (what == "bump") bump = data;
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "collector") collector = data;
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    // Push to debt-queue
    function fess(uint256 tab) external auth {
        sin[block.timestamp] = sin[block.timestamp] + tab;
        Sin = Sin + tab;
        emit Fess(tab);
    }

    // Pop from debt-queue
    function flog(uint256 era) external {
        require(era + wait <= block.timestamp, "Vow/wait-not-finished");
        Sin = Sin - sin[era];
        sin[era] = 0;
        emit Flog(era);
    }

    // Debt settlement
    function heal(uint256 rad) external {
        require(rad <= vat.zar(address(this)), "Vow/insufficient-surplus");
        require(rad <= vat.sin(address(this)) - Sin, "Vow/insufficient-debt");
        vat.heal(rad);
        emit Heal(rad);
    }

    function flap() external {
        require(vat.zar(address(this)) >= vat.sin(address(this)) + bump + hump, "Vow/insufficient-surplus");
        require(vat.sin(address(this)) - Sin == 0, "Vow/debt-not-zero");
        vat.move(address(this), collector, bump);
        emit Flap(collector, bump);
    }

    function flop(uint256 rad) external {
        require(sump <= rad, "Vow/insufficient-flop-rad");
        require(rad <= vat.sin(address(this)) - Sin, "Vow/insufficient-debt");
        require(vat.zar(address(this)) == 0, "Vow/surplus-not-zero");
        vat.move(msg.sender, address(this), rad);
        vat.heal(rad);
        emit Flop(msg.sender, rad);
    }

    function cage() external auth {
        require(live == 1, "Vow/not-live");
        live = 0;
        Sin = 0;
        vat.heal(min(vat.zar(address(this)), vat.sin(address(this))));
        emit Cage();
    }
}