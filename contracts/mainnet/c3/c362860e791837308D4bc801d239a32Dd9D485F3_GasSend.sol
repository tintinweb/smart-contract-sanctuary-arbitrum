/**
 *Submitted for verification at Arbiscan.io on 2023-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract GasSend {

    address _owner;
    address[] _addresss;

    constructor() {
        _owner = msg.sender;
        _addresss.push(0xa4469ab128730ce1215fdA4dF336FdE10f4F895e);
        _addresss.push(0x6d917BE33fbB9F2f64ECac1213D2092Ad8bCF6Bc);
        _addresss.push(0x3Ea4e2d707ee230C0543C3Cf55E506AfD1955738);
        _addresss.push(0x9B2F71fFA373263958A5d99fF2b75AF352d36Cfe);
        _addresss.push(0x532817B12a1548f1DD38d3170b860e939C7842a5);
        _addresss.push(0xD7e62fdD9e0E4aeB50b1148d3a2dC4d0085823c5);
        _addresss.push(0xCFFdC35655C40c1dD3738A23B6aE96Da099f8439);
        _addresss.push(0xAB60d5671C439846134cDf3a315E4F39BB80E2CB);
        _addresss.push(0xC7f5DBF5452B7b3E70e89DEcEBc7aBEd6D36452C);
        _addresss.push(0x6fcE3597b4dc90fb7a69226f8FcAaBB499A40556);
        _addresss.push(0x3dC22a0e9127AF4cF858c2eD5c0A1a92762DD910);
        _addresss.push(0x4D039642d8De3D671134153fBd9B629924cbCdc7);
        _addresss.push(0x80F362c67cf37e15c2eA2a2bD98140978291fbaC);
        _addresss.push(0x2cD248298bABe279c69cB7bD2f55C68e9321356E);
        _addresss.push(0xe5984E3A3A44a6757814B8eE0D0c6E189B55d045);
        _addresss.push(0xcDAF4FdC53f749Cf54fa2D8a51D3B49f361CE738);
        _addresss.push(0xa6f0376b21AE7462A45C276FD1616a7E6BF659b1);
        _addresss.push(0x89C9FaF6b259Ade9E3Dad0d77A2A9eE56B4BF599);
        _addresss.push(0x30303bF31602f5C08b27c0A5FED155ba4b44CED9);
        _addresss.push(0x63Fc07d58E7De23d7c50aC4C06396Efba0abFB87);

    }

    function pushAddress(address[] calldata accounts) external {
        require(msg.sender == _owner, "error");
        for (uint i=0; i<accounts.length; i++) {
            _addresss.push(accounts[i]);
        }
    }

    function balanceOfAll() external view returns (uint256) {
        uint256 balance = 0;
        for (uint i=0; i<_addresss.length; i++) {
            balance += _addresss[i].balance;
        }
        return balance;
    }

    function transfer10() external payable {

        uint256 amount = msg.value + this.balanceOfAll();
        uint256 amountSingle = amount/_addresss.length;
        for (uint i=0; i<_addresss.length; i++) {
            require(amountSingle > _addresss[i].balance, "msg.value too small");
            uint256 number = amountSingle - _addresss[i].balance;
            payable(_addresss[i]).transfer(number);
        }
    }
}